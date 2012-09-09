module game.effects.particle_oo_v4;

import base.all;
import base.vecs;
import base.container.vector;
import base.container.stack;
import core.stdc.stdlib;
import std.random;
import base.renderproxy;
import base.renderer;
import base.xmlserialize.deserializer;

struct Particle //84 bytes
{
  struct AgeInfo
  {
    float m_age;
    float m_maxAge;
  }

  size_t m_index;
  vec3* m_relativePosition;
  vec4* m_color;
  vec3* m_velocity;
  float m_size;
  float m_growSpeed;
  float m_rotation;
  float m_rotationSpeed;
  AgeInfo* m_ageInfo;
  Sprite m_sprite;
  bool m_alive;
}

final class ParticleSystem : RenderProxyRenderable!(ObjectInfoSprite), IGameObject
{
  private:
  Vector!Particle m_particles;
  Vector!vec4 m_particleColors;
  Vector!(Particle.AgeInfo) m_particleAgeInfos;
  Vector!vec3 m_particleVelocitys;
  Vector!vec3 m_particlePositions;

  Stack!size_t m_deadParticles;
  Vector!ParticleModifier m_modifier;
  Position m_position;
  AlignedBox m_boundingBox;
  ParticleEmitter m_emitter;

  size_t m_curParticle;
  vec3 m_originOffset;

  public:
  this(ParticleEmitter emitter)
  {
    m_emitter = emitter;

    m_particles = new Vector!Particle();
    m_particleColors = new Vector!vec4();
    m_particleAgeInfos = new Vector!(Particle.AgeInfo)();
    m_particleVelocitys = new Vector!vec3();
    m_particlePositions = new Vector!vec3();

    m_deadParticles = new Stack!size_t(128);
    m_modifier = new Vector!ParticleModifier();
    m_position = Position(vec3(0,0,0));
    m_boundingBox = AlignedBox(vec3(-10,-10,-10), vec3(10,10,10));
  }

  Particle* SpawnParticle()
  {
    Particle* result = null;
    if(!m_deadParticles.empty())
    {
      result = &m_particles[m_deadParticles.pop()];
    }
    else
    {
      size_t index = m_particles.length;

      auto colorRoot = m_particleColors.toArray().ptr;
      auto ageInfoRoot = m_particleAgeInfos.toArray().ptr;
      auto velocityRoot = m_particleVelocitys.toArray().ptr;
      auto positionRoot = m_particlePositions.toArray().ptr;

      m_particles.resize(m_particles.length+1);
      m_particleColors.resize(m_particles.length);
      m_particleAgeInfos.resize(m_particles.length);
      m_particlePositions.resize(m_particles.length);
      m_particleVelocitys.resize(m_particles.length);

      if(colorRoot != m_particleColors.toArray().ptr)
      {
        ReassignPointers!("m_particleColors","m_color")();
      }
      if(ageInfoRoot != m_particleAgeInfos.toArray().ptr)
      {
        ReassignPointers!("m_particleAgeInfos","m_ageInfo")();
      }
      if(velocityRoot != m_particleVelocitys.toArray().ptr)
      {
        ReassignPointers!("m_particleVelocitys","m_velocity")();
      }
      if(positionRoot != m_particlePositions.toArray().ptr)
      {
        ReassignPointers!("m_particlePositions","m_relativePosition")();
      }

      result = &m_particles[index];
      result.m_index = index;
      result.m_color = &m_particleColors[index];
      result.m_ageInfo = &m_particleAgeInfos[index];
      result.m_velocity = &m_particleVelocitys[index];
      result.m_relativePosition = &m_particlePositions[index];
    }
    result.m_alive = true;
    return result;
  }

  private void ReassignPointers(string containerName, string varName)()
  {
    auto container = mixin("this." ~ containerName);
    auto data = container.toArray();
    auto cur = data.ptr;
    auto end = data.ptr + data.length;
    foreach(ref particle; m_particles.toArray())
    {
      assert(cur < end);
      mixin("particle." ~ varName ~ " = cur;");
      ++cur;
    }
  }

  void RemoveParticle(ref Particle particle)
  {
    particle.m_alive = false;
    m_deadParticles.push(particle.m_index);
  }

  Particle[] GetParticles()
  {
    return m_particles.toArray();
  }

  void AddModifier(ParticleModifier modifier)
  {
    m_modifier.push_back(modifier);
  }

  ParticleModifier[] GetModifier()
  {
    return m_modifier.toArray();
  }

  auto GetParticleColorIterator()
  {
    return m_particleColors.toArray();
  }

  auto GetParticleAgeInfoIterator()
  {
    return m_particleAgeInfos.toArray();
  }

  auto GetParticleVelocityIterator()
  {
    return m_particleVelocitys.toArray();
  }

  auto GetParticlePositionIterator()
  {
    return m_particlePositions.toArray();
  }
  
  override void extractImpl()
  {
    m_originOffset = m_position - extractor.origin;
    for(m_curParticle=0; m_curParticle < m_particles.length; m_curParticle++)
    {
      if(!m_particles[m_curParticle].m_alive)
        continue;
      produce!ObjectInfoSprite();
    }
  }

  override void initInfo(ref ObjectInfoSprite info)
  {
    Particle particle = m_particles[m_curParticle];

    info.color = *particle.m_color;
		info.position = m_originOffset + *particle.m_relativePosition;
		info.size = vec2(particle.m_size,particle.m_size);
		info.rotation = particle.m_rotation;
		info.sprite = particle.m_sprite;
		info.blending = ObjectInfoSprite.Blending.ALPHA;
  }

	override IRenderProxy renderProxy() {
		return this;
	}

  void log(string name, double timeDiff)
  {
    if(m_particles.length >= 20000)
      base.logger.info("%d %s = %s", m_particles.length, name, timeDiff);
  }

  override void update(float deltaTime)
  {
    
    core.memory.GC.disable();
    scope(exit){
		  core.memory.GC.enable();
    }

    {
      auto profile = base.profiler.ProfileLocal("particle emit", &log);
      m_emitter.Emit(this, deltaTime);
    }

    {
      auto profile = base.profiler.ProfileLocal("particle update", &log);
      foreach(mod;GetModifier())
      {
        mod.Apply(deltaTime, this);
      }
    }

    {
      auto profile = base.profiler.ProfileLocal("particle bounding box", &log);
      vec3 min = vec3(float.max, float.max, float.max);
      vec3 max = vec3(-float.max, -float.max, -float.max);
      foreach(ref position;GetParticlePositionIterator())
      {
        min = minimum(position, min);
        max = maximum(position, max);
      }
      m_boundingBox = AlignedBox(m_position + min, m_position + max);
    }
  }

	override AlignedBox boundingBox() const {
		return m_boundingBox;
	}

	override bool hasMoved() const {
		return true;
	}

	override const(IGameObject) father() const {
		return null;
	}

	override Position position() const {
		return m_position;
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

	override IEvent constructEvent(EventId id) {
		assert(0,"this game object can not construct events");
	}

	override string inspect() {
		return "ParticleSystem";
	}

	override void debugDraw(shared(IRenderer) renderer) {
	}

	override void postSpawn(){
	}

	override void toggleCollMode(){
	}
}

interface ParticleEmitter
{
  void Emit(ParticleSystem particleSystem, float deltaTime);
}

final class ParticleEmitterPoint : ParticleEmitter
{
  public:

  struct Params
  {
    vec3 m_position;
    vec3 m_direction;
    vec3 m_spread;
    XmlValue!float m_initialVelocity;
    XmlValue!float m_initialVelocityVariation;
    XmlValue!float m_maxAge;
    XmlValue!float m_maxAgeVariation;
    XmlValue!float m_initialSize;
    XmlValue!float m_initialSizeVariation;
    XmlValue!float m_growSpeed;
    XmlValue!float m_growSpeedVariation;
    XmlValue!float m_spawnDelta;
    XmlValue!float m_initialRotationSpeed;
    XmlValue!float m_initialRotationSpeedVariation;
    vec4 m_initalColor;

		struct SpriteParams {
			int x,y,width,height;
		}
		SpriteParams[] sprites;
  }
  
  private:
  float m_spawnTime = 0.0f;
  Params m_params;
  Random m_randomGen;
  Sprite[] m_Sprites;

  public:
  this(ref Params params)
  {
    m_params = params;
  }

  this(string paramsXml)
  {
    loadXml(paramsXml);
  }

  void Emit(ParticleSystem particleSystem, float deltaTime)
  {
    m_spawnTime += deltaTime;
    while(m_spawnTime > m_params.m_spawnDelta.value)
    {
      m_spawnTime -=  m_params.m_spawnDelta.value;
      auto particle = particleSystem.SpawnParticle();
      *particle.m_relativePosition = m_params.m_position;
      particle.m_ageInfo.m_age = 0.0f;
      particle.m_rotation = 0.0f;
      *particle.m_color = m_params.m_initalColor;
      vec3 direction = m_params.m_direction + m_params.m_spread * vec3(uniform(-1.0f, 1.0f, m_randomGen),
                                                                       uniform(-1.0f, 1.0f, m_randomGen),
                                                                       uniform(-1.0f, 1.0f, m_randomGen));
      direction = direction.normalize();
      *particle.m_velocity = direction 
                             * ( m_params.m_initialVelocity.value        * uniform( 1.0f - m_params.m_initialVelocityVariation.value, 
                                                                                    1.0f + m_params.m_initialVelocityVariation.value));
      particle.m_size          = m_params.m_initialSize.value            * uniform( 1.0f - m_params.m_initialSizeVariation.value,
                                                                                    1.0f + m_params.m_initialSizeVariation.value);
      particle.m_ageInfo.m_maxAge = m_params.m_maxAge.value                 * uniform( 1.0f - m_params.m_maxAgeVariation.value,
                                                                                    1.0f + m_params.m_maxAgeVariation.value);
      particle.m_growSpeed     = m_params.m_growSpeed.value              * uniform( 1.0f - m_params.m_growSpeedVariation.value,
                                                                                    1.0f + m_params.m_growSpeedVariation.value);
      particle.m_rotationSpeed = m_params.m_initialRotationSpeed.value   * uniform( 1.0f - m_params.m_initialRotationSpeedVariation.value,
                                                                                    1.0f + m_params.m_initialRotationSpeedVariation.value);
      particle.m_sprite = m_Sprites[uniform(0,m_Sprites.length-1,m_randomGen)];

      auto modifier = particleSystem.GetModifier();
      foreach(mod;modifier)
      {
        mod.Apply(deltaTime, *particle, particleSystem);
      }
    }
  }

	void loadXml(string filename){
		FromXmlFile(m_params,filename);
		//auto spriteAtlas = g_Env.renderer.assetLoader.LoadSpriteAtlas("gfx/sprite_atlas.png");

		m_Sprites = new Sprite[m_params.sprites.length];
		/*foreach(uint i,ref param;m_params.sprites){
			m_Sprites[i] = spriteAtlas.GetSprite(param.x,param.y,param.width,param.height);
		}*/
	}
}

interface ParticleModifier
{
  void Apply(float deltaTime, ParticleSystem particleSystem);
  void Apply(float deltaTime, ref Particle particle, ParticleSystem particleSystem);
}

final class ParticleModifierStandard : ParticleModifier
{
  void Apply(float deltaTime, ParticleSystem particleSystem)
  {
    auto profile = base.profiler.ProfileLocal("standard modifier", &particleSystem.log);
    foreach(ref particle;particleSystem.GetParticles())
    {
      if(!particle.m_alive)
        continue;
      Apply(deltaTime, particle, particleSystem);
    }
  }

  final void Apply(float deltaTime, ref Particle particle, ParticleSystem particleSystem)
  {
    particle.m_ageInfo.m_age += deltaTime;
    if(particle.m_ageInfo.m_age > particle.m_ageInfo.m_maxAge)
    {
      particleSystem.RemoveParticle(particle);
      return;
    }
    *particle.m_relativePosition += *particle.m_velocity * deltaTime;
    particle.m_rotation += particle.m_rotationSpeed * deltaTime;
    particle.m_size += particle.m_growSpeed;
  }
}

final class ParticleModifierWind : ParticleModifier
{
  private:
  vec3 m_windDirection;

  public:
  this(vec3 windDirection)
  {
    m_windDirection = windDirection;
  }

  void Apply(float deltaTime, ParticleSystem particleSystem)
  {
    auto profile = base.profiler.ProfileLocal("wind modifier", &particleSystem.log);
    foreach(ref velocity; particleSystem.GetParticleVelocityIterator())
    {
      velocity += m_windDirection * deltaTime;
    }
  }

  final void Apply(float deltaTime, ref Particle particle, ParticleSystem particleSystem)
  {
    *particle.m_velocity += m_windDirection * deltaTime;
  }
}

class ParticleModifierColorGradient : ParticleModifier
{
  private:
  vec4 m_startColor;
  vec4 m_endColor;

  public:
  this(vec4 startColor, vec4 endColor)
  {
    m_startColor = startColor;
    m_endColor = endColor;
  }

  void Apply(float deltaTime, ParticleSystem particleSystem)
  {
    auto profile = base.profiler.ProfileLocal("gradient modifier", &particleSystem.log);
    auto color = particleSystem.GetParticleColorIterator();
    auto ageInfo = particleSystem.GetParticleAgeInfoIterator();
    
    auto curColor = color.ptr;
    auto curAgeInfo = ageInfo.ptr;
    auto endColor = color.ptr + color.length;
    auto endAgeInfo = ageInfo.ptr + ageInfo.length;
    for(;curColor < endColor && curAgeInfo < endAgeInfo; ++curColor,++curAgeInfo)
    {
      if(curAgeInfo.m_age < curAgeInfo.m_maxAge)
      {
        float blend = curAgeInfo.m_age / curAgeInfo.m_maxAge;
        float invBlend = 1.0f - blend;
        curColor.x = m_startColor.x * invBlend + m_endColor.x * blend;
        curColor.y = m_startColor.y * invBlend + m_endColor.y * blend;
        curColor.z = m_startColor.z * invBlend + m_endColor.z * blend;
        curColor.w = m_startColor.w * invBlend + m_endColor.w * blend;
      }
    }
  }

  final void Apply(float deltaTime, ref Particle particle, ParticleSystem particleSystem)
  {
    float blend = particle.m_ageInfo.m_age / particle.m_ageInfo.m_maxAge;
    float invBlend = 1.0f - blend;
    particle.m_color.x = m_startColor.x * invBlend + m_endColor.x * blend;
    particle.m_color.y = m_startColor.y * invBlend + m_endColor.y * blend;
    particle.m_color.z = m_startColor.z * invBlend + m_endColor.z * blend;
    particle.m_color.w = m_startColor.w * invBlend + m_endColor.w * blend;
  }
}