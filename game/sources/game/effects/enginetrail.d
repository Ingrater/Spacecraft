module game.effects.enginetrail;

import std.random;

import base.all;
import base.gameobject, base.renderproxy, base.renderer;
import thBase.container.vector, thBase.container.stack;
import thBase.serialize.xmldeserializer;
import thBase.serialize.xmlserializer;
import game.gameobject;
import thBase.format;
import thBase.casts;

class EngineTrail : RenderProxyGameObject!(ObjectInfoSprite), IGameObject {
private:
	struct FireParticle {
		float age;
		float maxAge;
		vec3 offset;
		bool alive = false;
		Position position;
		
		bool update(float timeDiff){
			if(alive){
				age += timeDiff;
				if(age > maxAge){
					alive = false;
					return false;
				}
			}
			return true;
		}
	}
	struct Particle {
		Sprite sprite;
		float size;
		float sizeChange;
		Position position;
		vec3 velocity;
		float age,maxAge;
		bool alive = false;
		vec4 color;
		
		bool update(float timeDiff){
			if(alive){
				age += timeDiff;
				if(age > maxAge){
					alive = false;
					return false;
				}
				position = position + (timeDiff * velocity);
				size += (timeDiff * sizeChange);
				if(size < 0.0f){
					size = 0.0f;
				}
			}
			return true;
		}
	}
	
	struct Params {
		struct SubParams {
			struct SpriteParams {
				int x,y,width,height;
			}
			
			SpriteParams sprite;
			vec3 offset;
			vec3 randomOffset;
			vec4 color;
			float velocity;
			float spawnInterval;
			float size;
			float sizeChange;
			float maxAge;
			float influence;
		}
		XmlValue!int maxCount;
		vec3 emitDir;
		vec3 leftDir;
		vec3 upDir;
		SubParams fire;
		
	}
	
	__gshared bool m_Loaded;
	__gshared Params m_Params;
	__gshared Sprite m_FireSprite,m_SmokeSprite;
	Vector!(FireParticle) m_Particles;
	Vector!(FireParticle).Range m_CurParticle;
	Stack!(uint) m_DeadParticles;
	Random gen;
	//Position m_LastPos;
	//float m_TimeSinceLastPos = 0.0f;
	
	GameObject m_Father;
	float m_FireSpawnPool = 0;
	AlignedBox m_BoundingBox;
	Position m_Position;
	
	Position m_SpawnPos;
	vec3 m_SpawnDir;
	vec3 m_LeftDir;
	vec3 m_UpDir;
	bool m_On = true;

public:
	this(GameObject father){
		if(!m_Loaded)
			loadXml();
		m_Particles = New!(typeof(m_Particles))();
		m_DeadParticles = New!(typeof(m_DeadParticles))(m_Params.maxCount.value);
		for(int i=0;i<m_Params.maxCount.value;i++)
			m_DeadParticles.push(i);
		m_Particles.resize(m_Params.maxCount.value);
		m_Father = father;
		m_Position = Position(vec3(0,0,0));
		m_BoundingBox = AlignedBox(vec3(-1,-1,-1),vec3(1,1,1));
		//m_LastPos = father.position;
	}

  ~this()
  {
    Delete(m_Particles);
    Delete(m_DeadParticles);
  }

	override void initInfo(ref ObjectInfoSprite info){
		auto particle = m_CurParticle.front;
		info.color = m_Params.fire.color;
		particle.position = m_SpawnPos + (m_SpawnDir * (particle.age + particle.offset.z)
			                                       + m_LeftDir * particle.offset.x
												   + m_UpDir * particle.offset.y);
		info.position = (particle.position - extractor.origin);
		float size = m_Params.fire.size + m_Params.fire.sizeChange * particle.age;
		if(size < 0.0f)
		   size  = 0.0f;
		info.size = vec2(size,size);
		info.rotation = 0.0f;
		info.sprite = m_FireSprite;
		info.blending = ObjectInfoSprite.Blending.ADDITIVE;
	}
	
	override void extractImpl(){
		if(!m_On)
			return;
		mat4 rotation = m_Father.rotation.toMat4();
		m_SpawnPos = m_Father.position + vec3(rotation * vec4(m_Params.fire.offset,1.0f));
		m_SpawnDir = vec3(rotation * vec4(m_Params.emitDir,0.0f)).normalize() * m_Params.fire.velocity;
		m_SpawnDir = m_SpawnDir - m_Father.velocity * m_Params.fire.influence;
		m_LeftDir = vec3(rotation * vec4(m_Params.leftDir,0.0f)).normalize();
		m_UpDir = vec3(rotation * vec4(m_Params.upDir,0.0f)).normalize();
		
		m_CurParticle = m_Particles.GetRange();
		uint alive = int_cast!uint(m_Particles.length - m_DeadParticles.size());
		for(uint i=0;i<alive;i++){
			while(!m_CurParticle.front.alive)
				m_CurParticle.popFront();
			produce!ObjectInfoSprite();
			m_CurParticle.popFront();
		}
	}
	
	override void update(float timeDiff){
		m_FireSpawnPool += timeDiff;
		while(m_FireSpawnPool > m_Params.fire.spawnInterval){
			m_FireSpawnPool -= m_Params.fire.spawnInterval;
			if(m_DeadParticles.size() > 0){
				uint index = m_DeadParticles.pop();
				auto particle = &m_Particles[index];
				particle.offset = vec3(uniform(-1.0f,1.0f,gen),
									   uniform(-1.0f,1.0f,gen),
									   uniform(-1.0f,1.0f,gen));
				particle.age = 0.0f;
				particle.alive = true;
				particle.maxAge = m_Params.fire.maxAge;
				particle.position = m_Father.position;
				if(m_FireSpawnPool > timeDiff)
					if(!particle.update(m_FireSpawnPool - timeDiff))
						m_DeadParticles.push(index);
			}
		}
		
		Position min,max;
		vec3 emin,emax;
		bool first = true;
		
		uint i=0;
		foreach(ref particle;m_Particles[]){
			if(!particle.update(timeDiff)){
				m_DeadParticles.push(i);
			}
			else if(particle.alive) {
				if(first){
					min = particle.position;
					max = particle.position;
					emin = min.toVec3();
					emax = max.toVec3();
					first = false;
				}
				else {
					auto cur = particle.position.toVec3();
					for(int j=0;j<3;j++){
						if(cur.f[j] < emin.f[j]){
							min.cell.f[j] = particle.position.cell.f[j];
							min.relPos.f[j] = particle.position.relPos.f[j];
							emin = min.toVec3();
						}
						if(cur.f[j] > emax.f[j]){
							max.cell.f[j] = particle.position.cell.f[j];
							max.relPos.f[j] = particle.position.relPos.f[j];
							emax = max.toVec3();
						}
					}
				}
			}
			i++;
		}
		
		if(!first){
			m_BoundingBox = AlignedBox(min,max);
			m_Position = min + ((max - min) * 0.5f);
		}
	}
	
	static void loadXml(){
		m_Loaded = true;
		/*auto ser = new XmlSerializer!Params(Params());
		ser.ToFile("gfx/xml/enginetrail.xml");*/
		FromXmlFile(m_Params, _T("gfx/xml/enginetrail.xml"));
		auto spriteAtlas = g_Env.renderer.assetLoader.LoadSpriteAtlas(_T("gfx/sprite_atlas.dds"));
		m_FireSprite = spriteAtlas.GetSprite(m_Params.fire.sprite.x,m_Params.fire.sprite.y,m_Params.fire.sprite.width,m_Params.fire.sprite.height);
	}
	
	override AlignedBox boundingBox() const {
		return m_BoundingBox;
	}
	
	override bool hasMoved() const {
		return true;
	}
	
	override const(IGameObject) father() const {
		return m_Father;
	}
	
	override Position position() const {
		return m_Position;
	}
	
	override void position(Position pos){
		assert(0,"Position can not be set");
	}
	
	override Quaternion rotation() const {
		return Quaternion(vec3(1.0f,0.0f,0.0f),0.0f);
	}
	
	override mat4 transformation(Position origin) const {
		return mat4.Identity();
	}
	
	override bool syncOverNetwork() const {
		return false;
	}
	
	override IRenderProxy renderProxy() {
		return this;
	}
	
	override void serialize(ISerializer ser, bool fullSerialization){
		assert(0,"this object is not serializeable");
	}
	
	override void resetChangedFlags(){
		assert(0,"this object should not be touched by the net code");
	}
	
	override EntityId entityId() const {
		assert(0,"this object does not have a entity id");
	}
	
	override void onDeleteRequest() {
	}
	
	override IEvent constructEvent(EventId id, IAllocator allocator) {
		assert(0,"this game object can not construct events");
	}
	
	override rcstring inspect() {
		return format("EngineTrail %d of %d Particles",m_Particles.length - m_DeadParticles.size,m_Particles.length);
	}
	
	override void debugDraw(shared(IRenderer) renderer) {
	}
	
	override void postSpawn(){
	}
	
	override void toggleCollMode(){
	}
	
	void on(bool value){
		m_On = value;
	}
}
