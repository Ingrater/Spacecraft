module game.effects.bigexplosion;

import base.gameobject, base.renderproxy, base.renderer;
import thBase.serialize.xmldeserializer;
import game.gameobject;
import base.net;
import std.math, std.random;
import thBase.container.vector;
import thBase.casts;
import core.refcounted;
import core.allocator;
import game.game;

class BigExplosion : GameObject, ISerializeable {
private:
	struct Params {
		struct SpriteParams {
			int x,y,width,height;
		}
		
		struct RingParams {
			SpriteParams sprite;
			vec4 color;
			float size;
			float sizeChange;
			float timeToLive;
			float startFading;
		}
		
		struct ExplosionParams {
			SpriteParams[] sprites;
			vec4 color;
			float playbackSpeed;
			float randomOffset;
			float spawnInterval;
			int count;
			float size,sizeVariation;
		}
		
		RingParams ring;
		ExplosionParams explosion;
	}
	
	static class Proxy : RenderProxyGameObject!(ObjectInfoOrientedSprite,ObjectInfoSprite) {
		private:
			int i;
      BigExplosion m_outer;
		
    public:
    this(BigExplosion outer)
    {
      m_outer = outer;
    }
		
		override void initInfo(ref ObjectInfoOrientedSprite info){
			float blend = (m_outer.m_Age - m_outer.m_Params.ring.startFading) / (m_outer.m_Params.ring.timeToLive - m_outer.m_Params.ring.startFading);
			if(blend < 0.0f) blend = 0.0f;
			info.color = m_outer.m_Params.ring.color * (1.0f - blend);
			info.position = (m_outer.m_Position.value - extractor.origin);
			float size = m_outer.m_Params.ring.size * m_outer.m_Scale + m_outer.m_Params.ring.sizeChange * m_outer.m_Age * m_outer.m_Scale;
			info.size = vec2(size,size);
			info.sprite = m_outer.m_RingSprite;
			info.blending = ObjectInfoOrientedSprite.Blending.ADDITIVE;
			info.orientation = m_outer.m_Normal;
		}
		
		override void initInfo(ref ObjectInfoSprite info){
			info.color = m_outer.m_Params.explosion.color;
			info.position = (m_outer.m_Position.value - extractor.origin) + m_outer.m_Explosions[i].offset;
			uint spriteId = cast(uint)floor(m_outer.m_Explosions[i].age / m_outer.m_Params.explosion.playbackSpeed);
			if(spriteId >= m_outer.m_ExplosionSprites.length)
				spriteId = int_cast!uint(m_outer.m_ExplosionSprites.length-1);
			info.sprite = m_outer.m_ExplosionSprites[spriteId];
			info.size = vec2(m_outer.m_Explosions[i].size,m_outer.m_Explosions[i].size);
			info.blending = ObjectInfoSprite.Blending.ADDITIVE;
		}
		
		override void extractImpl(){
			produce!ObjectInfoOrientedSprite();
			
			i=0;
			foreach(ref expl;m_outer.m_Explosions[]){
				if(expl.age > 0.0f && expl.age < m_Params.explosion.playbackSpeed * m_Params.explosion.sprites.length){
					produce!ObjectInfoSprite();
				}
				i++;
			}
		}
	}
	
	struct Explosion {
		vec3 offset;
		float age = 0.0f;
		float size = 1.0f;
	}
	
	__gshared bool m_Loaded = false;
	__gshared Params m_Params;
	__gshared Sprite m_RingSprite;
	__gshared Sprite[] m_ExplosionSprites;
	
	float m_TimeToLive;
	float m_Age = 0.0f;
	float m_LastExplosionSpawn = 0.0f;
	int m_ExplosionsAlive = 0;
	netvar!vec3 m_Normal;
	netvar!float m_Scale;
	Vector!(Explosion) m_Explosions;
	Random gen;
public:
	/**
	 * server side constructor
	 */
	this(EntityId entityId, GameSimulation game, Position pos, vec3 normal, float scale){
		m_OnServer = true;
		if(!m_Loaded)
			loadXml();
		m_EntityId = entityId;
		m_Game = game;
		m_Position = pos;
		float halfSize = m_Params.ring.size / 2.0f;
		m_BoundingBox = AlignedBox(pos + vec3(-halfSize,-halfSize,-halfSize),
								   pos + vec3(halfSize,halfSize,halfSize));
		m_TimeToLive = m_Params.ring.timeToLive;
		m_Normal = normal;
		m_Scale = scale;
	}

	/**
     * client side constructor
     */
	this(EntityId entityId, GameSimulation game){
		m_EntityId = entityId;
		m_Game = game;
		if(!m_Loaded)
			loadXml();
		m_RenderProxy = New!Proxy(this);
		m_TimeToLive =  m_Params.ring.timeToLive;
		m_Explosions = New!(Vector!Explosion)();
		m_Explosions.resize(m_Params.explosion.count);
	}

  ~this()
  {
    Delete(m_Params.explosion.sprites);
    Delete(m_Explosions);
  }
	
	static void loadXml(){
		m_Loaded = true;
		FromXmlFile(m_Params, _T("gfx/xml/bigexplosion.xml"));
		if(!g_Env.isServer){
			auto spriteAtlas = g_Env.renderer.assetLoader.LoadSpriteAtlas(_T("gfx/sprite_atlas.dds"));
			m_RingSprite = spriteAtlas.GetSprite(m_Params.ring.sprite.x,
												 m_Params.ring.sprite.y,
												 m_Params.ring.sprite.width,
												 m_Params.ring.sprite.height);
			m_ExplosionSprites = NewArray!Sprite(m_Params.explosion.sprites.length);
			foreach(uint i,ref param;m_Params.explosion.sprites){
				m_ExplosionSprites[i] = spriteAtlas.GetSprite(param.x,param.y,
															  param.width,param.height);
			}
		}
	}

  shared static ~this()
  {
    Delete(m_ExplosionSprites);
  }
	
	override void update(float timeDiff){
		m_TimeToLive -= timeDiff;
		m_Age += timeDiff;
		if(m_OnServer && m_TimeToLive < 0){
			m_Game.factory.removeGameObject(this);
		}
		if(!m_OnServer){
			foreach(ref expl;m_Explosions[]){
				expl.age += timeDiff;
			}
		}
	}
	
	override void postSpawn(){
		float halfSize = m_Params.ring.size / 2.0f;
		m_BoundingBox = AlignedBox(m_Position.value + vec3(-halfSize,-halfSize,-halfSize),
								   m_Position.value + vec3(halfSize,halfSize,halfSize));
		m_FreshlySpawned = true;
		if(!m_OnServer){
			for(int i=0;i<m_Explosions.length;i++){
				m_Explosions[i].offset = vec3(uniform(-1.0f,1.0f,gen),
										   uniform(-1.0f,1.0f,gen),
										   uniform(-1.0f,1.0f,gen)).normalize() 
										 * uniform(0.0f,m_Params.explosion.randomOffset * m_Scale,gen);
				m_Explosions[i].age = 0.0f - m_Params.explosion.spawnInterval * i;
				m_Explosions[i].size = m_Params.explosion.size * m_Scale + uniform(-1.0f,1.0f,gen) * m_Params.explosion.sizeVariation * m_Scale;
			}
		}
	}
	
	// Stuff for network integration (message passing mixin added later because of
	// forward reference compiler bugs)
	mixin MakeSerializeable;
	mixin DummyMessageCode;
}