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
  rcstring[6] paths;
  shared(MessageQueue_t) answerQueue;
	
	this(rcstring positive_x_path, rcstring negative_x_path,
		 rcstring positive_y_path, rcstring negative_y_path,
		 rcstring positive_z_path, rcstring negative_z_path,
     shared(MessageQueue_t) answerQueue)
	{
    bm.type = typeid(typeof(this));
		paths[0] = positive_x_path;
		paths[1] = negative_x_path;
		paths[2] = positive_y_path;
		paths[3] = negative_y_path;
		paths[4] = positive_z_path;
		paths[5] = negative_z_path;
    this.answerQueue = answerQueue;
	}
	
	this(ref MsgLoadCubeMap rh){
    this.bm = rh.bm;
		this.paths[0] = rh.paths[0];
		this.paths[1] = rh.paths[1];
		this.paths[2] = rh.paths[2];
		this.paths[3] = rh.paths[3];
		this.paths[4] = rh.paths[4];
		this.paths[5] = rh.paths[5];
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