module game.skybox;

import base.renderproxy;

class SkyBox : IRenderable {
private:
	SmartPtr!IRenderProxy m_RenderProxy;

public:
	this(IRenderProxy cubeMapProxy){
		this.m_RenderProxy = cubeMapProxy;
	}
	
	override IRenderProxy renderProxy(){
		return m_RenderProxy;
	}	
}

