module game.effects.bigshieldimpact;

import base.gameobject, base.renderproxy, base.renderer;
import thBase.serialize.xmldeserializer;
import game.gameobject;
import base.net;
import core.refcounted;
import game.game;

class BigShieldImpact : GameObject, ISerializeable {
private:
	struct Params {
		struct SpriteParams {
			int x,y,width,height;
		}
		SpriteParams sprite;
		vec4 color;
		XmlValue!int count;
		XmlValue!float timeToLive;
		XmlValue!float size;
		XmlValue!float sizeChange;
		XmlValue!float startOffset;
		XmlValue!float offset;
	}
	
	static class Proxy : RenderProxyGameObject!(ObjectInfoOrientedSprite) {
		private:
      int i;
      BigShieldImpact m_outer;

    public:
      this(BigShieldImpact outer)
      {
        m_outer = outer;
      }
		
		override void initInfo(ref ObjectInfoOrientedSprite info){
			info.color = m_Params.color * (m_outer.m_TimeToLive / m_Params.timeToLive.value);
			info.position = (m_outer.m_Position.value - extractor.origin) + (m_outer.m_Normal * (m_outer.m_Params.startOffset.value + i * m_outer.m_Params.offset.value));
			float size = m_outer.m_Params.size.value + m_outer.m_Params.sizeChange.value * i;
			info.size = vec2(size,size);
			info.sprite = m_outer.m_Sprite;
			info.orientation = m_outer.m_Normal;
			info.blending = ObjectInfoOrientedSprite.Blending.ADDITIVE;
		}
		
		override void extractImpl(){
			for(i=0;i<m_Params.count.value;i++)
				produce!ObjectInfoOrientedSprite();
		}
	}
	
	__gshared bool m_Loaded = false;
	__gshared Params m_Params;
	__gshared Sprite m_Sprite;
	
	netvar!vec3 m_Normal;
	float m_TimeToLive;
public:
	/**
	 * server side constructor
	 */
	this(EntityId entityId, GameSimulation game, Position pos,vec3 normal){
		m_OnServer = true;
		if(!m_Loaded)
			loadXml();
		m_EntityId = entityId;
		m_Game = game;
		m_Position = pos;
		float halfSize = m_Params.size.value / 2.0f;
		m_BoundingBox = AlignedBox(pos + vec3(-halfSize,-halfSize,-halfSize),
								   pos + vec3(halfSize,halfSize,halfSize));
		m_Normal = normal;
		m_TimeToLive = m_Params.timeToLive.value;
	}

	/**
     * client side constructor
     */
	this(EntityId entityId, GameSimulation game){
		m_EntityId = entityId;
		m_Game = game;
		if(!m_Loaded)
			loadXml();
		m_Normal.value = vec3(0.0f,0.0f,1.0f);
		m_RenderProxy = New!Proxy(this);
		m_TimeToLive = m_Params.timeToLive.value;
	}
	
	static void loadXml(){
		m_Loaded = true;
		FromXmlFile(m_Params, _T("gfx/xml/bigshieldimpact.xml"));
		if(!g_Env.isServer){
			auto spriteAtlas = g_Env.renderer.assetLoader.LoadSpriteAtlas(_T("gfx/sprite_atlas.dds"));
			m_Sprite = spriteAtlas.GetSprite(m_Params.sprite.x,m_Params.sprite.y,m_Params.sprite.width,m_Params.sprite.height);
		}
	}
	
	override void update(float timeDiff){
		m_TimeToLive -= timeDiff;
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