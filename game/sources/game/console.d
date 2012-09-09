module game.console;

import base.all;
import base.renderproxy;
import thBase.container.vector;
import base.script;
import thBase.conv;
import thBase.string;




static import base.logger;

class ConsoleRenderProxy : RenderProxyRenderable!(ObjectInfoText,ObjectInfoShape){
private:
	Console m_Console;
	Zeitpunkt m_Last;
	double m_BlinkTime = 0.0;
	bool m_Blink = true;
	size_t m_Count = 0;
	int m_LineHeight = 0;
	
protected:		
	override void initInfo(ref ObjectInfoText info){
		if(m_Count == 0){
			Zeitpunkt now = Zeitpunkt(g_Env.mainTimer);
			m_BlinkTime += now - m_Last;
			m_Last = now;
			while(m_BlinkTime > 300.0){
				m_BlinkTime -= 300.0;
				m_Blink = !m_Blink;
			}
			
			info.pos = vec2(10,m_Console.m_Height-m_LineHeight);
			if(m_Blink)
				m_Console.charIn('_');
			info.text = format("%s", m_Console.m_InputBuffer.toArray());
			if(m_Blink)
				m_Console.delLast();
			info.color = vec4(1.0f,1.0f,1.0f,1.0f);
			info.font = 0;
		}
		else {
			info.pos = vec2(10,m_Console.m_Height - m_LineHeight * (m_Count+1));
			info.text = m_Console.m_History[m_Console.m_History.length - (m_Count + m_Console.m_ScrollPos)];
			info.color = vec4(1.0f,1.0f,1.0f,1.0f);
			info.font = 0;
		}
	}	

	override void initInfo(ref ObjectInfoShape info){
		info.color = vec4(1.0f,0.55f,0.0f,0.8f);
    info.vertices = allocArray!vec2(4);
    info.vertices[0] = vec2(0.0f,0.0f);
    info.vertices[1] = vec2(0.0f,m_Console.m_Height+5.0f);
    info.vertices[2] = vec2(m_Console.m_Width,0.0f);
    info.vertices[3] = vec2(m_Console.m_Width,m_Console.m_Height+5.0f);
		info.target = HudTarget.SCREEN;
	}

	override void extractImpl()
	{
		if(!m_Console.visible)
			return;
		produce!(ObjectInfoShape)();
		
		m_Count = 0;
		produce!(ObjectInfoText)(); //input line
		for(m_Count=1;m_Count < m_Console.m_Height / m_LineHeight && m_Count <= m_Console.m_History.length - m_Console.m_ScrollPos;m_Count++){
			produce!(ObjectInfoText)();
		}
	}
	
public:
	
	this(Console console)
	in {
		assert(console !is null);
	}
	body {
		m_Console = console;
		m_Last = Zeitpunkt(g_Env.mainTimer);
		m_LineHeight = cast(int)(g_Env.renderer.GetFontHeight(0) * 1.2);
	}	
}

class Console : IRenderable {
private:
	enum size_t MAX_HISTORY_LENGTH = 500;
	
	Vector!(rcstring) m_History;
	Vector!(dchar) m_InputBuffer;
	IScriptSystem m_ScriptSystem;
	int m_Width,m_Height;
	int m_ScrollPos = 0;
	string m_Pipe = "|";
	bool visible = false;
	Mutex m_HistoryMutex;
	
	SmartPtr!ConsoleRenderProxy m_RenderProxy;
	
	void appendToHistory(rcstring line){
		assert(m_HistoryMutex !is null);
		synchronized(m_HistoryMutex){
			m_History ~= line;
			if(m_History.length > MAX_HISTORY_LENGTH){
				for(size_t i=0;i<MAX_HISTORY_LENGTH;i++){
					m_History[i] = m_History[i+1];
				}
				m_History.resize(MAX_HISTORY_LENGTH);
			}
		}
	}
	
public:
	
	this(IScriptSystem scriptSystem,int width, int height){
		m_ScriptSystem = scriptSystem;
		m_Width = width;
		m_Height = height;
		m_History = New!(typeof(m_History))();
		m_InputBuffer = New!(typeof(m_InputBuffer))();
		m_RenderProxy = New!ConsoleRenderProxy(this);
		m_HistoryMutex = New!Mutex;
		
		//auto self = cast(shared(Console))this;
		base.logger.hook(&this.log);
	}

  ~this()
  {
    base.logger.unhook(&this.log);
    Delete(m_History);
    Delete(m_InputBuffer);
    Delete(m_HistoryMutex);
  }

	override IRenderProxy renderProxy(){
		return m_RenderProxy;
	}

	void charIn(dchar c){
		m_InputBuffer ~= c;
	}
	
	void delLast(){
		if(m_InputBuffer.length > 0){
			m_InputBuffer.resize(m_InputBuffer.length - 1);
		}
	}
	
	void execute(){
		auto command = to!rcstring(m_InputBuffer.toArray());
		appendToHistory(command);
		try {
			m_ScriptSystem.execute(command[]);
		}
		catch(ScriptError er){
			foreach(line;splitLines(er.toString())){
				this.appendToHistory(line);
			}
      Delete(er);
		}
		m_InputBuffer.resize(0);
	}
	
	void show(bool value){
		visible = value;
	}
	
	void log(string str){
		foreach(line; splitLines(rcstring(str))){
			this.appendToHistory(line);
		}
	}
	
	void scrollUp(){
		m_ScrollPos++;
		if(m_ScrollPos >= m_History.length){
			m_ScrollPos = m_History.length - 1;
			if(m_ScrollPos < 0)
				m_ScrollPos = 0;
		}
	}
	
	void scrollDown(){
		m_ScrollPos--;
		if(m_ScrollPos < 0)
			m_ScrollPos = 0;
	}
}