module game.effects.dirtcloud;

import std.random;

import base.all;
import base.gameobject, base.renderproxy, base.renderer;
import thBase.container.vector;
import thBase.serialize.xmldeserializer;
import thBase.serialize.xmlserializer;

class DirtCloud : RenderProxyRenderable!(ObjectInfoSprite), IRenderable {
private:
	struct Particle {
		Position position;
		Sprite sprite;
		float size;
	}
	
	Vector!(Particle) m_Particles;
	Vector!(Particle).Range m_CurParticle;
	
	struct Params {
		struct SpriteParams {
			int x,y,width,height;
		}
		
		XmlValue!int count;
		XmlValue!float size;
		XmlValue!float sizeVariation;
		XmlValue!float maxDistance;
		SpriteParams[] sprites;
		vec4 color;
	}
	
	Params m_Params;
	Sprite[] m_Sprites;
	IGameObject m_Father;
	Random gen;
	
public:
	this(IGameObject father){
		m_Father = father;
		loadXml();
	}

  ~this()
  {
    Delete(m_Sprites);
    Delete(m_Particles);
  }

	override void initInfo(ref ObjectInfoSprite info){
		auto particle = m_CurParticle.front;
		
		float dist = (particle.position - m_Father.position).length;
		float maxDistance = m_Params.maxDistance.value;
		dist -= maxDistance * 0.95f;
		if(dist < 0.0f)
			dist = 0.0f;
		dist = 1.0f - (dist / (maxDistance * 0.05));
		
		info.color = m_Params.color;
		info.color.w *= dist;
		info.position = (particle.position - extractor.origin);
		info.size = vec2(particle.size,particle.size);
		info.rotation = 0.0f;
		info.sprite = particle.sprite;
		info.blending = ObjectInfoSprite.Blending.ALPHA;
	}
	
	override void extractImpl(){
		auto profile = base.profiler.Profile("dirtcloud");
		{
			auto profile2 = base.profiler.Profile("sort");
			m_Particles.insertionSort(
				(ref const(Particle) lh, ref const(Particle) rh){
					vec3 dist1 = (lh.position - extractor.origin);
					vec3 dist2 = (rh.position - extractor.origin);
					return (dist1.dot(dist1) < dist2.dot(dist2));
				}
			);
		}
		m_CurParticle = m_Particles.GetRange();
		uint alive = m_Particles.length;
		float maxDistance = m_Params.maxDistance.value;
		{
			auto profile2 = base.profiler.Profile("respawn");
			for(uint i=0;i<alive;i++){
				vec3 dist = m_CurParticle.front.position - m_Father.position;
				bool changed = false;
				foreach(ref f;dist.f){
					if(f > maxDistance) {
						f = maxDistance * -2.0f;
						changed = true;
					}
					else if(f < -maxDistance) {
						f = maxDistance * 2.0f;
						changed = true;
					}
					else {
						f = 0.0f;
					}
				}
				if(changed){
					m_CurParticle.front.position = m_CurParticle.front.position + dist;
				}
				produce!ObjectInfoSprite();
				m_CurParticle.popFront();
			}
		}
	}

	void loadXml(){
		FromXmlFile(m_Params,_T("gfx/xml/dirtcloud.xml"));
    scope(exit) Delete(m_Params.sprites);
		auto spriteAtlas = g_Env.renderer.assetLoader.LoadSpriteAtlas(_T("gfx/sprite_atlas.png"));
		
    if(m_Sprites !is null)
    {
      Delete(m_Sprites);
    }
		m_Sprites = NewArray!Sprite(m_Params.sprites.length);
		foreach(uint i,ref param;m_Params.sprites){
			m_Sprites[i] = spriteAtlas.GetSprite(param.x,param.y,param.width,param.height);
		}
		
    if(m_Particles !is null)
      Delete(m_Particles);
		m_Particles = New!(Vector!(Particle))();
		m_Particles.resize(m_Params.count.value);
		foreach(ref particle;m_Particles[]){
			auto offset = vec3(uniform(-1.0f,1.0f,gen) * m_Params.maxDistance.value,
							   uniform(-1.0f,1.0f,gen) * m_Params.maxDistance.value,
							   uniform(-1.0f,1.0f,gen) * m_Params.maxDistance.value);
			particle.position = m_Father.position + offset;
			particle.sprite = m_Sprites[uniform(0,m_Sprites.length,gen)];
			particle.size = m_Params.size.value + uniform(-1.0f,1.0f,gen) * m_Params.sizeVariation.value;
		}
	}
	
	override IRenderProxy renderProxy() {
		return this;
	}
}

/*unittest {
	auto p = DirtCloud.Params();
	p.sprites = [DirtCloud.Params.SpriteParams(),DirtCloud.Params.SpriteParams(),DirtCloud.Params.SpriteParams(),DirtCloud.Params.SpriteParams()];
	ToXmlFile(p,"gfx/xml/dirtcloud.xml");
}*/