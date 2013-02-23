module game.effects.smallexplosion2;

import base.gameobject, base.renderproxy, base.renderer;
import thBase.serialize.xmldeserializer;
import thBase.casts;
import game.gameobject;
import base.net;
import core.refcounted;
import game.game;

class SmallExplosion2 : GameObject, ISerializeable {
private:
	struct Params {
		struct SpriteParams {
			int x,y,width,height;
		}
		SpriteParams[] sprites;
		vec4 color;
		XmlValue!float size;
		XmlValue!float playbackSpeed;
	}
	
	static class Proxy : RenderProxyGameObject!(ObjectInfoSprite) {
    private SmallExplosion2 m_outer;

    this(SmallExplosion2 outer)
    {
      m_outer = outer;
    }

		override void initInfo(ref ObjectInfoSprite info){
			info.color = m_outer.m_Params.color;
			info.position = (m_outer.m_Position.value - extractor.origin);
			info.size = vec2(m_outer.m_Params.size.value, m_outer.m_Params.size.value);
			uint spriteId = cast(uint)(m_outer.m_Age / m_outer.m_Params.playbackSpeed.value);
			if(spriteId >= m_outer.m_Sprites.length)
				spriteId = int_cast!uint(m_outer.m_Sprites.length-1);
			info.sprite = m_outer.m_Sprites[spriteId];
			info.blending = ObjectInfoSprite.Blending.ADDITIVE;
		}
		
		override void extractImpl(){
			produce!ObjectInfoSprite();
		}
	}
	
	__gshared bool m_Loaded = false;
	__gshared Params m_Params;
	__gshared Sprite[] m_Sprites;
	
	float m_TimeToLive;
	float m_Age = 0.0f;
public:
	/**
	 * server side constructor
	 */
	this(EntityId entityId, GameSimulation game, Position pos){
		m_OnServer = true;
		if(!m_Loaded)
			loadXml();
		m_EntityId = entityId;
		m_Game = game;
		m_Position = pos;
		float halfSize = m_Params.size.value / 2.0f;
		m_BoundingBox = AlignedBox(pos + vec3(-halfSize,-halfSize,-halfSize),
								   pos + vec3(halfSize,halfSize,halfSize));
		m_TimeToLive = m_Params.playbackSpeed.value * m_Params.sprites.length;
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
		m_TimeToLive = m_Params.playbackSpeed.value * m_Params.sprites.length;
	}
	
	static void loadXml(){
		m_Loaded = true;
		FromXmlFile(m_Params, _T("gfx/xml/smallexplosion2.xml"));
		if(!g_Env.isServer){
			auto spriteAtlas = g_Env.renderer.assetLoader.LoadSpriteAtlas(_T("gfx/sprite_atlas.dds"));
			m_Sprites = NewArray!Sprite(m_Params.sprites.length);
			foreach(uint i,ref param;m_Params.sprites){
				m_Sprites[i] = spriteAtlas.GetSprite(param.x,param.y,param.width,param.height);
			}
		}
	}

  shared static ~this()
  {
    Delete(m_Params.sprites);
    Delete(m_Sprites);
  }
	
	override void update(float timeDiff){
		m_TimeToLive -= timeDiff;
		m_Age += timeDiff;
		if(m_OnServer && m_TimeToLive < 0){
			m_Game.factory.removeGameObject(this);
		}
	}
	
	override void postSpawn(){
		float halfSize = m_Params.size.value / 2.0f;
		m_BoundingBox = AlignedBox(m_Position.value + vec3(-halfSize,-halfSize,-halfSize),
								   m_Position.value + vec3(halfSize,halfSize,halfSize));
		m_FreshlySpawned = true;
	}
	
	// Stuff for network integration (message passing mixin added later because of
	// forward reference compiler bugs)
	mixin MakeSerializeable;
	mixin DummyMessageCode;
}