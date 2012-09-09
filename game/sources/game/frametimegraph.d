module game.frametimegraph;

import base.renderproxy, base.all;
import core.sync.mutex;

class ProgressBar : RenderProxyRenderable!(ObjectInfoText,ObjectInfoShape), IRenderable {
private:	
	vec4 m_Color;
	vec2[] m_Vertices;
	
public:
	override IRenderProxy renderProxy(){
		return this;
	}
	
	override void extractImpl(){
		
	}
	
	override void initInfo(ref ObjectInfoText info){
		/*info.pos = vec2(20, g_Env.renderer.GetHeight()/2+35);
		info.text = copyArray(m_Status);
		info.color = vec4(1.0f,1.0f,1.0f,1.0f);
		info.font = 0;*/
	}	

	override void initInfo(ref ObjectInfoShape info){
		info.color = m_Color;
		info.vertices = m_Vertices.dup;
		info.target = HudTarget.SCREEN;
	}
}
