module game.progressbar;

import base.renderproxy, base.all, game.player;
import core.sync.mutex;
import core.allocator;

class ProgressBar : RenderProxyRenderable!(ObjectInfoText,ObjectInfoShape), IRenderable {
private:	
	vec4 m_Color;
	vec2[4] m_Vertices;
	float m_Progress = 0.0f;
	rcstring m_Status;
	Mutex m_Mutex;
	
public:
	this(){
		m_Mutex = New!Mutex();
		m_Status = _T("Loading...");
	}

  ~this()
  {
    Delete(m_Mutex);
  }
	
	override IRenderProxy renderProxy(){
		return this;
	}
	
	override void extractImpl(){
		synchronized(m_Mutex){
			vec2 min = vec2(20,g_Env.renderer.GetHeight()/2-20);
			vec2 max = vec2(g_Env.renderer.GetWidth()-20,g_Env.renderer.GetHeight()/2+20);
			m_Color = vec4(1.0f,1.0f,1.0f,1.0f);
			m_Vertices[0] = vec2(max.x,min.y);
      m_Vertices[1] = min;
			m_Vertices[2] = max;
			m_Vertices[3] = vec2(min.x,max.y);
			produce!ObjectInfoShape();
			
			if (m_Progress > 0){
				min.x += 5; min.y += 5;
				max.x -= 5; max.y -= 5;
				max.x = (max.x - min.x) * m_Progress;
				m_Color = vec4(0.5f,0.5f,0.5f,1.0f);
			
				m_Vertices[0] = vec2(max.x,min.y);
				m_Vertices[1] = min;
				m_Vertices[2] = max;
				m_Vertices[3] = vec2(min.x,max.y);
				produce!ObjectInfoShape();
			}
			produce!ObjectInfoText();
		}
	}
	
	void progress(float value){
		m_Progress = value;
	}
	
	@property void status(rcstring value){
		synchronized(m_Mutex){
			m_Status = value;
		}
	}
	
	override void initInfo(ref ObjectInfoText info){
		info.pos = vec2(20, g_Env.renderer.GetHeight()/2+35);
		info.text = copyArray(m_Status[]);
		info.color = vec4(1.0f,1.0f,1.0f,1.0f);
		info.font = 0;
	}	

	override void initInfo(ref ObjectInfoShape info){
		info.color = m_Color;
		info.vertices = copyArray(m_Vertices);
		info.target = HudTarget.SCREEN;
	}
}
