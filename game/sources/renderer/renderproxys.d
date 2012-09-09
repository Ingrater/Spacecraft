module renderer.renderproxys;

import base.renderproxy;
import renderer.model;
import renderer.objectinfos;
import renderer.camera;
import renderer.cubetexture;

class ModelProxy : RenderProxyGameObject!(ObjectInfoModel) {
private:
	IDrawModel m_Model;
protected:	
	override void initInfo(ref ObjectInfoModel info){
		info.transformation = object.transformation(extractor.origin);
		info.model = m_Model;
	}

	override void extractImpl(){
		produce!(ObjectInfoModel)();
	}
public:
	this(IDrawModel model){
		m_Model = model;
	}
}

class Hud3DProxy : RenderProxyGameObject!(ObjectInfo3DHud){
private:
	IDrawModel m_Model;
protected:	
	override void initInfo(ref ObjectInfo3DHud info){
		info.transformation = object.transformation(extractor.origin);
		info.model = m_Model;
	}

	override void extractImpl(){
		produce!(ObjectInfo3DHud)();
	}
public:
	this(IDrawModel model){
		m_Model = model;
	}	
}

class ParticleSystemProxy : RenderProxyGameObject!(ObjectInfoParticleSystem) {
private:
	
protected:
	override void initInfo(ref ObjectInfoParticleSystem info){
	}
	
	override void extractImpl(){
	}
}

class CameraProxy : RenderProxyGameObject!(ObjectInfoCamera), ICameraRenderProxy {
private:
	
protected:
	override void initInfo(ref ObjectInfoCamera info){
		mat4 view = object.transformation(extractor.origin);
		info.viewMatrix = view.Inverse();
		info.projMatrix = camera.GetProjectionMatrix();
		info.origin = extractor.origin();
	}	
	
	override void extractImpl(){
		produce!(ObjectInfoCamera)();
	}
	
public:	
	Camera camera;
	
	this(Camera camera){
		this.camera = camera;
	}

  ~this()
  {
    Delete(camera);
  }
	
	override mat4 projection(){
		return camera.GetProjectionMatrix();
	}
	
	override mat4 view(Position origin){
		mat4 view = object.transformation(extractor.origin);
		return view.Inverse();
	}
}

class SkyMapProxy : RenderProxyRenderable!(ObjectInfoSkyBox) {
private:
	CubeTexture texture;
	
protected:
	override void initInfo(ref ObjectInfoSkyBox info){
		info.texture = this.texture;
	}

	override void extractImpl(){
		produce!(ObjectInfoSkyBox)();
	}

public:
	this(CubeTexture texture){
		this.texture = texture;
	}
}
