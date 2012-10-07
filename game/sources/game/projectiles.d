module game.projectiles;

import game.gameobject, base.all, game.objectfactory, base.renderproxy, game.player;
import game.effects.shieldimpact, game.effects.smallexplosion;
import game.effects.bigshieldimpact, game.effects.smallexplosion2, game.effects.flakexplosion;
import thBase.serialize.xmldeserializer;
import game.rules.base, game.turret;
import std.math, std.random;
import thBase.container.vector;
import game.game;
import thBase.container.hashmap;

class MgProjectileProxy : RenderProxyGameObject!(ObjectInfoSprite) {
private:
	Sprite m_Sprite;
	vec4 m_Color;
	float m_Size;
	float m_SpawnSize;
	vec3 m_Pos;
public:
	this(Sprite sprite, vec4 color, float size){
		m_Sprite = sprite;
		m_Size = size;
		m_Color = color;
	}

	override void initInfo(ref ObjectInfoSprite info){
		info.color = m_Color;
		info.position = m_Pos;
		info.size = vec2(m_SpawnSize,m_SpawnSize);
		info.rotation = 0.0f;
		info.sprite = m_Sprite;
		info.blending = ObjectInfoSprite.Blending.ADDITIVE;
	}
	
	override void extractImpl(){
		m_Pos = (object.position - extractor.origin);
		m_SpawnSize = m_Size;
		auto obj = cast(GameObject)object;
		vec3 dir = obj.velocity.normalize() * -0.5;
		for(int i=0;i<12;i++){
			produce!ObjectInfoSprite();
			m_Pos = m_Pos + dir * m_SpawnSize;
			m_SpawnSize = m_SpawnSize * 0.95;
		}
	}
}

class MgProjectile : GameObject, ISerializeable {
	
	// Stuff for network integration
	mixin DummyMessageCode;
	
	version(prediction){
		/**
		 * Overwrite default serialize method
		 * this causes the projectile to only be serialized when needed
		 */
		private bool m_SerializeNext = true;
		override void serialize(ISerializer ser, bool fullSerialization){
			if(m_SerializeNext || !m_OnServer){
				ser.serialize(0,m_Position.value);
				ser.serialize(1,m_Velocity.value);
				ser.serialize(2,m_Acceleration.value);
			}
		}	
		
		override void resetChangedFlags(){
			m_SerializeNext = false;
		}
	}
	else {
		mixin MakeSerializeable;
	}
	
	//
	// Server side game object code
	//
	
	private {
		// Livetime of mg projectiles in seconds
		float m_TimeToLive;
		IGameObject m_Owner;
		float m_Damage;
	}
	
	
	/**
	 * Server side constructor
	 */
	this(IGameObject owner, IGameObject target, float damage, float timeToLife, EntityId entityId, GameSimulation game, Position pos, Quaternion rot, vec3 vel){
		super(entityId, game, pos, rot, null);
		m_Owner = owner;
		m_Velocity = vel;
		m_TimeToLive = timeToLife;
		m_Damage = damage;
		
		auto speed = vel.length();
		auto boxSize = ceil(speed / g_Env.serverFps);
		m_OriginalBoundingBox = AlignedBox(Position(vec3(-boxSize, -boxSize, -boxSize)), Position(vec3(boxSize, boxSize, boxSize)));
	}
	
	override void updateOnServer(float timeDiff){
		auto dt_sec = timeDiff / 1_000;
		auto proj_ray = Ray(this.position.toVec3(), this.velocity * dt_sec);
		auto candidates = m_Game.octree.getObjectsInBox(this.boundingBox);
		foreach(candidate; candidates){
			//base.logger.info("game: octree collision with %s", hit.inspect);
			if (candidate !is this && candidate !is m_Owner){
				auto other = cast(GameObject) candidate;
				
				if (other !is null && other.collisionHull !is null){
					//base.logger.info("game: projectile collision with a collision hull");
					mat4 other_transform = other.transformation(Position(vec3(0, 0, 0)));
					float hit_pos;
					vec3 hit_normal;
					if ( other.collisionHull.intersects(proj_ray, other_transform, hit_pos, hit_normal) ){
						//base.logger.info("col: hit_pos: %s", hit_pos);
						if (hit_pos >= -0.1 && hit_pos < 1.1){
							bool impacted = false;
							
							auto receiver = cast(IHitable) other;
							if (receiver !is null && !receiver.isDead) {
								impacted = receiver.hit(m_Damage, this);
								
								if (impacted)
									m_TimeToLive = 0;
								
								onImpact(impacted, proj_ray, hit_pos, hit_normal);
							}
							
							if (!impacted){
								m_Velocity = reflect(m_Velocity, hit_normal);
								version(prediction) m_SerializeNext = true;
							}
							
							break;
						}
					}
				}
			}
		}
		
		super.updateOnServer(timeDiff);
		
		m_TimeToLive -= dt_sec;
		if (m_TimeToLive < 0){
			onEndOfLife();
			auto factory = m_Game.factory;
			factory.removeGameObject(this);
		}
	}
	
	protected void onImpact(bool impacted, Ray projRay, float hitPos, vec3 hitNormal){
		if (impacted) {
			Position impactPos = this.position + (projRay.m_Dir * hitPos + hitNormal * 5.0f);
			auto impactEffect = new SmallExplosion(m_Game.factory.nextEntityId(), m_Game, impactPos);
			(cast(GameObjectFactory)m_Game.factory).SpawnGameObject(impactEffect);
		} else {
			Position impactPos = this.position + projRay.m_Dir * hitPos;
			auto impactEffect = new ShieldImpact(m_Game.factory.nextEntityId(), m_Game, impactPos, hitNormal);
			(cast(GameObjectFactory)m_Game.factory).SpawnGameObject(impactEffect);
		}
	}
	
	protected void onEndOfLife(){
	}
	
	IGameObject owner(){
		return m_Owner;
	}
	
	
	//
	// Client side game object code
	//
	
	// Stuff that is reused between all game objects of this kind on the client
	protected static {
		shared(ISpriteAtlas) m_SpriteAtlas;
		Hashmap!(ubyte, SmartPtr!IRenderProxy) m_ReuseableRenderProxy;
	}
	
	private {
		ISoundSource m_sound;
    float m_remainingSoundPlayTime;
    static Vector!ISoundSource m_SoundCache;
	}
	
	struct ParticleParams {
		struct Color {
			float r,g,b,a;
		}
		
		XmlValue!int x,y,width,height;
		Color color;
		XmlValue!float size;
	}
	
	/**
	 * Client side constructor. Called when the game object factory creates this
	 * game object as requested by the server. This takes place before the data
	 * for this game object arives. Therefore you can only set attributes but the
	 * netvars will not be set to their proper server values yet.
	 */
	this(EntityId entityId, GameSimulation game){
		loadRenderProxy(_T("./gfx/xml/mgprojectile.xml"), 0);
		auto boudingBox = AlignedBox(Position(vec3(-2,-2,-2)), Position(vec3(2,2,2)));
		super(entityId, game, boudingBox, null);
    if(m_SoundCache is null)
    {
      m_SoundCache = New!(Vector!(ISoundSource))();
      for(int i=0; i<32; i++)
      {
        m_SoundCache.push_back(m_Game.soundSystem.LoadOggSound(_T("sfx/mg_fire.ogg")));
      }
    }
	}

  ~this()
  {
    if(m_sound !is null)
    {
      Delete(m_sound);
    }
  }

  static ~this()
  {
    Delete(m_ReuseableRenderProxy);
    if(m_SoundCache !is null)
    {
      foreach(sound; m_SoundCache)
      {
        Delete(sound);
      }
      Delete(m_SoundCache); m_SoundCache = null;
    }
  }
	
	protected void loadRenderProxy(rcstring file, ubyte index){
		if (m_SpriteAtlas is null)
			m_SpriteAtlas = g_Env.renderer.assetLoader.LoadSpriteAtlas(_T("gfx/sprite_atlas.dds"));
    if(m_ReuseableRenderProxy is null)
      m_ReuseableRenderProxy = New!(typeof(m_ReuseableRenderProxy))();
		
		if (m_RenderProxy is null){
			if (m_ReuseableRenderProxy.exists(index))
      {
				m_RenderProxy = m_ReuseableRenderProxy[index];
			} 
      else 
      {
				ParticleParams params;
				FromXmlFile(params, file);
				SmartPtr!IRenderProxy proxy = New!MgProjectileProxy(m_SpriteAtlas.GetSprite(params.x.value,params.y.value,params.width.value,params.height.value),
																vec4(params.color.r,params.color.g,params.color.b,params.color.a),
																params.size.value).ptr;
				m_ReuseableRenderProxy[index] = proxy;
				m_RenderProxy = proxy;
			}
		}
	}
	
	override void postSpawn(){
		super.postSpawn();
		
		// Calculate the sound position based on the camera position and roation.
		auto cam_pos = m_Game.camera.position.toVec3();
		auto cam_rot = m_Game.camera.rotation.toMat4();
		auto sound_pos = cam_rot * vec4(this.position.toVec3() - cam_pos);
		
		//sound = m_Game.soundSystem.LoadOggSound("sfx/mg_fire.ogg");
    //only spawn sound if there is one in the cache and we are not too far away from the spawn location
    if(m_SoundCache.size() > 0 && (this.position.toVec3() - cam_pos).length() < 100.0f)
    {
      m_sound = m_SoundCache[0];
      m_SoundCache.remove(m_sound);
      m_remainingSoundPlayTime = 1000.0f; //1 second
      m_sound.Rewind();
		  // Put up the volume and make the projectiles sound more near (is this
		  // really a good idea?) No, because it was to loud...
		  //sound.SetVolume(1);
		  m_sound.SetPosition(sound_pos * 0.5);
		
		  /+ Both sounds very strange, therefore taken out again +/
		  vec4 vel = cam_rot * vec4(this.velocity);
		  m_sound.SetVelocity( vec3(vel.f[0..3]) );
		
		  auto axis = this.orientation();
		  vec4 dir = cam_rot * vec4(axis[2]);
		  m_sound.SetDirection( vec3(dir.f[0..3]) );
		
		  m_sound.Play();
    }
	}
	
	
		/**
		 * simulate the projeciles on the client
		 */
		override void updateOnClient(float timeDiff) {
      version(prediction){
			  auto dt_sec = timeDiff / 1_000;
			  m_Velocity = m_Velocity + m_Acceleration * dt_sec;
			  if (m_Velocity.length > float.epsilon)
				  this.position = m_Position.value + m_Velocity * dt_sec;
      }

      if(m_sound !is null)
      { 
        m_remainingSoundPlayTime -= timeDiff;
        if(!m_sound.IsPlaying() || m_remainingSoundPlayTime <= 0.0f)
        {
          m_sound.Stop();
          m_SoundCache.push_back(m_sound);
          m_sound = null;
        }
      }
			
			super.updateOnClient(timeDiff);
	}
	
	/**
	 * The projectile does not need a rotated bounding box. Therefore just apply
	 * the position but do not do something expensive here.
	 */
	override protected void updateBoundingBox(bool force = false){
		assert(m_OriginalBoundingBox.isValid(), "game: the client constructor have to initialize a valid original bounding box");
		if (m_Position.changed || force){
			m_BoundingBox = AlignedBox(
				m_OriginalBoundingBox.min + m_Position,
				m_OriginalBoundingBox.max + m_Position
			);
		}
	}
	
	override bool hasMoved(){
		return true;
	}
}

class HeavyProjectile : MgProjectile {
	
	this(IGameObject owner, IGameObject target, float damage, float timeToLife, EntityId entityId, GameSimulation game, Position pos, Quaternion rot, vec3 vel){
		super(owner, target, damage, timeToLife, entityId, game, pos, rot, vel);
	}
	
	protected override void onImpact(bool impacted, Ray projRay, float hitPos, vec3 hitNormal){
		if (impacted) {
			Position impactPos = this.position + (projRay.m_Dir * hitPos + hitNormal * 5.0f);
			auto impactEffect = new SmallExplosion2(m_Game.factory.nextEntityId(), m_Game, impactPos);
			(cast(GameObjectFactory)m_Game.factory).SpawnGameObject(impactEffect);
		} else {
			Position impactPos = this.position + projRay.m_Dir * hitPos;
			auto impactEffect = new BigShieldImpact(m_Game.factory.nextEntityId(), m_Game, impactPos, hitNormal);
			(cast(GameObjectFactory)m_Game.factory).SpawnGameObject(impactEffect);
		}
		
		// These projectiles don't bounce
		m_TimeToLive = 0;
	}
	
	this(EntityId entityId, GameSimulation game){
		loadRenderProxy(_T("./gfx/xml/heavy_projectile.xml"), 1);
		super(entityId, game);
	}
}

class FlakProjectile : MgProjectile {
	
	static private {
		// Radius affected by the explosion of the flak shell (in meters)
		float m_DamageRadius = 100;
		// When the time to life is calculated a random value in this range is
		// applied. Value is in seconds (added to time to life).
		float m_MinTimeSpread = -1;
		float m_MaxTimeSpread = 0;
		// Velocity applied to a target that is very close to the explosion. The
		// direction is always away from the explosion.
		float m_HitVel = 60;
	}
	
	this(IGameObject owner, IGameObject target, float damage, float timeToLife, EntityId entityId, GameSimulation game, Position pos, Quaternion rot, vec3 vel){
		if (target){
			auto targetPos = target.position;
			auto ownerPos = owner.position;
			auto dist = (targetPos - owner.position).length;
			auto speed = vel.length;
			
			if (dist > 0 &&  speed > 0){
				auto timeToImpact = dist / speed;
				if (auto entity = cast(HitableGameObject) target){
					auto predictedPos = targetPos + entity.velocity() * timeToImpact;
					auto predictedDist = (predictedPos - owner.position).length;
					timeToImpact = predictedDist / speed;
				}
				
				timeToLife = timeToImpact + uniform(m_MinTimeSpread, m_MaxTimeSpread);
				if (timeToLife < 0)
					timeToLife = dist / speed;
			}
		}
		super(owner, target, damage, timeToLife, entityId, game, pos, rot, vel);
	}
	
	protected override void onEndOfLife(){
		auto pos = this.position;
		auto affectedArea = AlignedBox(
			pos + vec3(-m_DamageRadius, -m_DamageRadius, -m_DamageRadius),
			pos + vec3(m_DamageRadius, m_DamageRadius, m_DamageRadius)
		);
		auto candidates = m_Game.octree.getObjectsInBox(affectedArea);
		foreach(candidate; candidates){
			auto cpos = candidate.position;
			auto dir = cpos - pos;
			auto dist = dir.length;
			if (dist < m_DamageRadius && dist > 0){
				float ratio = dist / m_DamageRadius;
				auto receiver = cast(Player) candidate;
				if (receiver && !receiver.isDead) {
					receiver.hit(m_Damage * ratio, this);
					auto toProjectileDir = dir.normalize;
					receiver.velocity = receiver.velocity + toProjectileDir * m_HitVel * ratio;
				}
			}
		}
		
		// Spawn explosion
		auto explosionEffect = new FlakExplosion(m_Game.factory.nextEntityId(), m_Game, this.position);
		(cast(GameObjectFactory)m_Game.factory).SpawnGameObject(explosionEffect);
	}
	
	this(EntityId entityId, GameSimulation game){
		loadRenderProxy(_T("./gfx/xml/flak_projectile.xml"), 2);
		super(entityId, game);
	}
}
