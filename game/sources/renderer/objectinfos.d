module renderer.objectinfos;

import base.renderproxy;
import thBase.math3d.all;
import renderer.vertexbuffer;
import renderer.model;
import renderer.cubetexture;

enum ExtractType : uint {
	INVALID = 0,
	MODEL = 1,
	PARTICLE_SYSTEM = 2,
	CAMERA = 3,
	TEXT = 4,
	SHAPE = 5,
	TEXTURED_SHAPE = 6,
	SKYBOX = 7,
	SPRITE = 8,
	ORIENTED_SPRITE = 9,
	HUD3D_MODEL = 10,
	FIXED_SPRITE = 11,
  RCTEXT = 12,
  DEBUG_LINE = 13
}

struct ObjectInfoModel {
	enum ExtractType TYPE = ExtractType.MODEL;
	ObjectInfo info;
	mat4 transformation;
	IDrawModel model;
}

struct ObjectInfoParticleSystem {
	enum ExtractType TYPE = ExtractType.PARTICLE_SYSTEM;
	ObjectInfo info;
}

struct ObjectInfoCamera {
	enum ExtractType TYPE = ExtractType.CAMERA;
	ObjectInfo info;
	mat4 viewMatrix;
	mat4 projMatrix;
	Position origin;
}

struct ObjectInfoSkyBox {
	enum ExtractType TYPE = ExtractType.SKYBOX;
	ObjectInfo info;
	CubeTexture texture;
}

struct ObjectInfo3DHud {
	enum ExtractType TYPE = ExtractType.HUD3D_MODEL;
	ObjectInfo info;
	mat4 transformation;
	IDrawModel model;
}