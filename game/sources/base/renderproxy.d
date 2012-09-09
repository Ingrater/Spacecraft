module base.renderproxy;

public import base.gameobject;
import thBase.metatools;
import base.renderer;
import core.stdc.string;
import core.refcounted;

interface IRenderable {
	/**
	 * getter for the render proxy of the object
	 */
	IRenderProxy renderProxy();
}

struct ObjectInfo {
	uint type = 0;
	ObjectInfo *next;
}

interface IRendererExtractor {
	protected ObjectInfo* CreateObjectInfo(size_t size)
		out(obj){
			assert(obj !is null);
		}
	
	protected void addObjectInfo(ObjectInfo* info);
	
	Position origin();
	
	/**
	 * allocate size_t bytes in the extractor pool (the allocated memory only lives until the next extraction is performed)
	 */
	void[] alloc(size_t size);

  /**
   * waits for a buffer to write the extracted data to
   */
  void WaitForBuffer();

  /**
   * starts object extraction
   */
  void extractObjects(IGame game);

  /**
   * Tells the extractor to stop
   */
  void stop();
}

abstract class IRenderProxy : RefCounted {
	void extractDo(IGameObject object, IRendererExtractor extractor);
	void extractDo(IRenderable object, IRendererExtractor extractor);
}

interface ICameraRenderProxy {
	mat4 projection();
	mat4 view(Position origin);
}

abstract class RenderProxyGameObjectHelper(T,R...) : RenderProxyGameObjectHelper!(R) {
	static assert(is(T == struct) && __traits(hasMember,T,"info"),T.stringof ~ " has to be a struct, and needs a info member");
	static assert(T.info.offsetof == 0,T.stringof ~ ": info member has to be the first member");	

protected:
	alias RenderProxyGameObjectHelper!(R).produceImpl produceImpl;
	final void produceImpl(Type2Type!(T)){
		T* obj = cast(T*)extractor.CreateObjectInfo(T.sizeof);
    T initHelper;
		*obj = initHelper;
		obj.info.type = T.TYPE;
		initInfo(*obj);
		extractor.addObjectInfo(&(*obj).info);
	}

  final T[] produceMultipleImpl(Type2Type!(T), size_t count)
  {
    T[] objs = (cast(T*)extractor.alloc(T.sizeof * count))[0..count];
    T initHelper;
    foreach(ref obj;objs)
    {
      obj = initHelper;
      obj.info.type = T.TYPE;
      extractor.addObjectInfo(&obj.info);
    }
    return objs;
  }

	abstract void initInfo(ref T info);  
}

abstract class RenderProxyGameObjectHelper(T) : IRenderProxy {
	static assert(is(T == struct) && __traits(hasMember,T,"info"),T.stringof ~ " has to be a struct, and needs a info member");
	static assert(T.info.offsetof == 0,T.stringof ~ ": info member has to be the first member");

protected:
	IGameObject object;
	IRendererExtractor extractor;
	
	final void produceImpl(Type2Type!(T)){
		T* obj = cast(T*)extractor.CreateObjectInfo(T.sizeof);
    T initHelper;
		*obj = initHelper;
		obj.info.type = T.TYPE;
		initInfo(*obj);
		extractor.addObjectInfo(&(*obj).info);
	}

  final T[] produceMultipleImpl(Type2Type!(T), size_t count)
  {
    T[] objs = (cast(T*)extractor.alloc(T.sizeof * count))[0..count];
    T initHelper;
    foreach(ref obj;objs)
    {
      obj = initHelper;
      obj.info.type = T.TYPE;
      extractor.addObjectInfo(&obj.info);
    }
    return objs;
  }
	
	final T copyArray(T : U[], U)(T ar){
		void[] mem = extractor.alloc(U.sizeof * ar.length);
		U[] result = (cast(U*)mem.ptr)[0..ar.length];
		memcpy(cast(void*)result.ptr,ar.ptr,U.sizeof * ar.length);
		return result;
	}
	
	final T[] allocArray(T)(size_t length){
		void[] mem = extractor.alloc(T.sizeof * length);
		T[] result = (cast(T*)mem.ptr)[0..length];
		return result;
	}

	abstract void initInfo(ref T info);	
	abstract void extractImpl();

public:	
	final override void extractDo(IGameObject object, IRendererExtractor extractor){
		this.object = object;
		this.extractor = extractor;
		extractImpl();
	}	
	
	final override void extractDo(IRenderable object, IRendererExtractor extractor){
		assert(0,"RenderProxyGameObject called with renderable");
	}
}

abstract class RenderProxyGameObject(T...) : RenderProxyGameObjectHelper!(T) {
protected:
	final void produce(F)(){
		produceImpl(Type2Type!(F)());
	}

  final F[] produceMultiple(F)(size_t count){
    Type2Type!(F) t;
    return produceMultipleImpl(t, count);
  }
}


abstract class RenderProxyRenderableHelper(T,R...) : RenderProxyRenderableHelper!(R) {
	static assert(is(T == struct) && __traits(hasMember,T,"info"),T.stringof ~ " has to be a struct, and needs a info member");
	static assert(T.info.offsetof == 0,T.stringof ~ ": info member has to be the first member");	

protected:
	alias RenderProxyRenderableHelper!(R).produceImpl produceImpl;
	final void produceImpl(Type2Type!(T)){
		T* obj = cast(T*)extractor.CreateObjectInfo(T.sizeof);
    T initHelper;
		*obj = initHelper;
		obj.info.type = T.TYPE;
		initInfo(*obj);
		extractor.addObjectInfo(&(*obj).info);
	}

  final T[] produceMultipleImpl(Type2Type!(T), size_t count)
  {
    T[] objs = (cast(T*)extractor.alloc(T.sizeof * count))[0..count];
    T initHelper;
    foreach(ref obj;objs)
    {
      obj = initHelper;
      obj.info.type = T.TYPE;
      extractor.addObjectInfo(&obj.info);
    }
    return objs;
  }

	abstract void initInfo(ref T info);
}

abstract class RenderProxyRenderableHelper(T) : IRenderProxy {
	static assert(is(T == struct) && __traits(hasMember,T,"info"),T.stringof ~ " has to be a struct, and needs a info member");
	static assert(T.info.offsetof == 0,T.stringof ~ ": info member has to be the first member");

protected:
	IRenderable object;
	IRendererExtractor extractor;
	
	final void produceImpl(Type2Type!(T)){
		T* obj = cast(T*)extractor.CreateObjectInfo(T.sizeof);
    T initHelper;
		*obj = initHelper;
		obj.info.type = T.TYPE;
		initInfo(*obj);
		extractor.addObjectInfo(&(*obj).info);
	}

  final T[] produceMultipleImpl(Type2Type!(T), size_t count)
  {
    T[] objs = (cast(T*)extractor.alloc(T.sizeof * count))[0..count];
    T initHelper;
    foreach(ref obj;objs)
    {
      obj = initHelper;
      obj.info.type = T.TYPE;
      extractor.addObjectInfo(&obj.info);
    }
    return objs;
  }
	
	final U[] copyArray(T : U[], U)(T ar){
		void[] mem = extractor.alloc(U.sizeof * ar.length);
		U[] result = (cast(U*)mem.ptr)[0..ar.length];
		memcpy(cast(void*)result.ptr,ar.ptr,U.sizeof * ar.length);
		return result;
	}
	
	final T[] allocArray(T)(size_t length){
		void[] mem = extractor.alloc(T.sizeof * length);
		T[] result = (cast(T*)mem.ptr)[0..length];
		return result;
	}

	abstract void initInfo(ref T info);	
	abstract void extractImpl();

public:	
	final override void extractDo(IGameObject object, IRendererExtractor extractor){
		extractDo(cast(IRenderable)object,extractor);
	}	
	
	final override void extractDo(IRenderable object, IRendererExtractor extractor){
		this.object = object;
		this.extractor = extractor;
		extractImpl();
	}
}

abstract class RenderProxyRenderable(T...) : RenderProxyRenderableHelper!(T){
protected:
	final void produce(F)(){
		produceImpl(Type2Type!(F)());
	}

  final F[] produceMultiple(F)(size_t count){
    Type2Type!(F) t;
    return produceMultipleImpl(t, count);
  }
}

enum ExtractTypePublic : uint {
	TEXT = 4,
	SHAPE = 5,
	TEXTURED_SHAPE = 6,
	SPRITE = 8,
	ORIENTED_SPRITE = 9,
	FIXED_SPRITE = 11
}

enum HudTarget : uint {
	SCREEN,
	RENDERTARGET
}

struct ObjectInfoText {
	enum ExtractTypePublic TYPE = ExtractTypePublic.TEXT;
	ObjectInfo info;
	uint font;
	vec4 color;
	vec2 pos;
	rcstring text;
	HudTarget target;
}

struct ObjectInfoShape {
	enum ExtractTypePublic TYPE = ExtractTypePublic.SHAPE;
	ObjectInfo info;
	vec4 color;
	vec2[] vertices; //interpreted as triangle strip
	HudTarget target;
}

struct ObjectInfoTexturedShape {
	enum ExtractTypePublic TYPE = ExtractTypePublic.TEXTURED_SHAPE;
	ObjectInfo info;
	vec4 color;
	vec2[] vertices; //interpreted as triangle strip
	vec2[] texcoords; //has to be same size as vertices
}

struct ObjectInfoSprite {
	enum Blending : uint {
		ADDITIVE,
		ALPHA
	}
	
	enum ExtractTypePublic TYPE = ExtractTypePublic.SPRITE;
	ObjectInfo info;
	vec4 color;
	vec3 position;
	vec2 size;
	float rotation;
	Sprite sprite;
	Blending blending;
}

struct ObjectInfoOrientedSprite {
	enum Blending : uint {
		ADDITIVE,
		ALPHA
	}
	
	enum ExtractTypePublic TYPE = ExtractTypePublic.ORIENTED_SPRITE;
	ObjectInfo info;
	vec4 color;
	vec3 position;
	vec3 orientation;
	vec2 size;
	Sprite sprite;
	Blending blending;
}

struct ObjectInfoFixedSprite {
	enum Blending : uint {
		ADDITIVE,
		ALPHA
	}
	
	enum ExtractTypePublic TYPE = ExtractTypePublic.FIXED_SPRITE;
	ObjectInfo info;
	vec4 color;
	vec3[4] vertices;
	Sprite sprite;
	Blending blending;
}