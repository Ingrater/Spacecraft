module game.effects.muzzleflash;

import base.all;
import base.gameobject, base.renderproxy, base.renderer;
import thBase.serialize.xmldeserializer;
import std.math;

class MuzzleFlash : RenderProxyGameObject!(ObjectInfoFixedSprite), IGameObject {
private:	
	struct Params {
		struct SpriteParams {
			int x,y,width,height;
		}
		SpriteParams sprite;
		vec4 color;
		XmlValue!float timeToLive;
	}
	
	__gshared bool m_Loaded = false;
	__gshared Sprite m_Sprite;
	__gshared Params m_Params;
	
	vec3 m_Offset;
	IGameObject m_Gun;
	mat4 trans;
	IGame m_Game;
	float m_TimeToLive;
	vec2 m_Size;
	
public:
	this(IGameObject gun, vec3 offset, IGame game, vec2 size){
		assert(!g_Env.isServer,"MuzzleFlash is a client only game object");
		if(!m_Loaded)
			loadXml();
		
		m_Gun = gun;
		m_Offset = offset;
		m_TimeToLive = m_Params.timeToLive.value;
		m_Game = game;
		m_Size = size;
	}

	override void initInfo(ref ObjectInfoFixedSprite info){
		info.color = m_Params.color;
		info.sprite = m_Sprite;
		info.blending = ObjectInfoFixedSprite.Blending.ADDITIVE;
		info.vertices[0] = vec3(trans * vec4(0.0f,-m_Size.y, m_Size.x, 1.0f));
		info.vertices[1] = vec3(trans * vec4(0.0f,-m_Size.y,-m_Size.x, 1.0f));
		info.vertices[2] = vec3(trans * vec4(0.0f, m_Size.y,-m_Size.x, 1.0f));
		info.vertices[3] = vec3(trans * vec4(0.0f, m_Size.y, m_Size.x, 1.0f));
	}
	
	override void extractImpl(){
		mat4 offset = TranslationMatrix(m_Offset) * m_Gun.transformation(extractor.origin);
		trans = offset;
		produce!ObjectInfoFixedSprite();
		trans = RotationMatrixXYZ(0.0f,0.0f,45.0f) * offset;
		produce!ObjectInfoFixedSprite();
		trans = RotationMatrixXYZ(0.0f,0.0f,90.0f) * offset;
		produce!ObjectInfoFixedSprite();
		trans = RotationMatrixXYZ(0.0f,0.0f,135.0f) * offset;
		produce!ObjectInfoFixedSprite();
	}
	
	override void update(float timeDiff){
		m_TimeToLive -= timeDiff;
		if(m_TimeToLive < 0.0f){
			m_Game.factory.removeClientGameObject(this);
		}
	}
	
	static void loadXml(){
		m_Loaded = true;
		/*auto ser = new XmlSerializer!Params(Params());
		ser.ToFile("gfx/xml/enginetrail.xml");*/
		FromXmlFile(m_Params,_T("gfx/xml/muzzleflash.xml"));
		auto atlas = g_Env.renderer.assetLoader.LoadSpriteAtlas(_T("gfx/sprite_atlas.dds"));
		m_Sprite = atlas.GetSprite(m_Params.sprite.x,m_Params.sprite.y,m_Params.sprite.width,m_Params.sprite.height);
	}
	
	override AlignedBox boundingBox() const {
		return m_Gun.boundingBox();
	}
	
	override bool hasMoved() const {
		return true;
	}
	
	override const(IGameObject) father() const {
		return m_Gun;
	}
	
	override Position position() const {
		return m_Gun.position;
	}
	
	override void position(Position pos){
		assert(0,"Position can not be set");
	}
	
	override Quaternion rotation() const {
		return m_Gun.rotation();
	}
	
	override mat4 transformation(Position origin) const {
		return m_Gun.transformation(origin);
	}
	
	override bool syncOverNetwork() const {
		return false;
	}

  override Object physicsComponent()
  {
    return null;
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
		return _T("MuzzleFlash");
	}
	
	override void debugDraw(shared(IRenderer) renderer) {
	}
	
	override void postSpawn(){
	}
	
	override void toggleCollMode(){
	}
}
