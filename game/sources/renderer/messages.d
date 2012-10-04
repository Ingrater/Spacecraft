module renderer.messages;

import base.renderer;
public import base.messages;

struct MsgLoadModel {
  BaseMessage bm;
	rcstring path;
  shared(MessageQueue_t) answerQueue;
	
	this(rcstring path, shared(MessageQueue_t) answerQueue){
    bm.type = typeid(typeof(this));
		this.path = path;
    this.answerQueue = answerQueue;
	}
}

struct MsgLoadingModelDone {
  BaseMessage bm;
	shared(IModel) model;
	
	this(IModel model){
    bm.type = typeid(typeof(this));
		this.model = cast(shared(IModel))model;
	}
}

struct MsgLoadCubeMap {
  BaseMessage bm;
  rcstring path;
  shared(MessageQueue_t) answerQueue;
	
	this(rcstring path, shared(MessageQueue_t) answerQueue)
	{
    bm.type = typeid(typeof(this));
		this.path = path;
    this.answerQueue = answerQueue;
	}
	
	this(ref MsgLoadCubeMap rh){
    this.bm = rh.bm;
    this.path = rh.path;
    this.answerQueue = rh.answerQueue;
	}
}

struct MsgLoadingCubeMapDone {
  BaseMessage bm;
	shared(ITexture) texture;
	
	this(ITexture texture){
    bm.type = typeid(typeof(this));
		this.texture = cast(shared(ITexture))texture;
	}
}

struct MsgLoadSpriteAtlas {
  BaseMessage bm;
	rcstring path;
  shared(MessageQueue_t) answerQueue;
	
	this(rcstring path, shared(MessageQueue_t) answerQueue){
    bm.type = typeid(typeof(this));
		this.path = path;
    this.answerQueue = answerQueue;
	}
}

struct MsgLoadingSpriteAtlasDone {
  BaseMessage bm;
	shared(ISpriteAtlas) atlas;
	
	this(ISpriteAtlas atlas){
    bm.type = typeid(typeof(this));
		this.atlas = cast(shared(ISpriteAtlas))atlas;
	}
}

struct MsgSetup3DHudGeom {
  BaseMessage bm;
	shared(IModel) model;
  shared(MessageQueue_t) answerQueue;
	
	this(shared(IModel) model, shared(MessageQueue_t) answerQueue){
    bm.type = typeid(typeof(this));
		this.model = model;
    this.answerQueue = answerQueue;
	}
}

struct MsgSetup3DHudGeomDone {
  BaseMessage bm;
	bool success;

  this( bool success)
  {
    bm.type = typeid(typeof(this));
    this.success = success;
  }
}

struct MsgCamera {
  BaseMessage bm;
	shared(IGameObject) obj;
	this(IGameObject obj){
    bm.type = typeid(typeof(this));
		this.obj = cast(shared(IGameObject))obj;
	}
}

struct MsgDrawText {
  BaseMessage bm;
	uint font;
	vec2 pos;
	vec4 color;
	string text;
	
	this(uint font, vec2 pos, vec4 color, string text){
    bm.type = typeid(typeof(this));
		this.font = font;
		this.pos = pos;
		this.color = color;
		this.text = text;
	}
	
	this(MsgDrawText rh){
    this.bm = rh.bm;
		this.font = rh.font;
		this.pos = rh.pos;
		this.color = rh.color;
		this.text = rh.text;
	}
}

struct MsgSetSPS {
  BaseMessage bm;
	float sps;

	this(float sps){
    bm.type = typeid(typeof(this));
		this.sps = sps;
	}
}

struct MsgDrawBox {
  BaseMessage bm;
	AlignedBox box;
	this(AlignedBox box){
    bm.type = typeid(typeof(this));
		this.box = box;
	}
}

struct MsgDrawLine {
  BaseMessage bm;
	Position start;
	Position end;
	this(ref const Position start, ref const Position end){
    bm.type = typeid(typeof(this));
		this.start = start;
		this.end = end;
	}
}

struct MsgLoadAmbientSettings {
  BaseMessage bm;
	rcstring path;
	
	this(rcstring path){
    bm.type = typeid(typeof(this));
		this.path = path;
	}
}