module game.console;

import base.all;
import base.renderproxy;
import thBase.container.vector;
import base.script;
import thBase.conv;
import thBase.string;
import thBase.casts;




import thBase.logging;

class ConsoleRenderProxy : RenderProxyRenderable!(ObjectInfoRCText, ObjectInfoShape){
private:
	Console m_Console;
	Zeitpunkt m_Last;
	double m_BlinkTime = 0.0;
	bool m_Blink = true;
	size_t m_Count = 0;
	int m_LineHeight = 0;

  enum Mode
  {
    Console,
    Autocomplete
  }
  Mode m_mode;
	
protected:		
	override void initInfo(ref ObjectInfoRCText info){
    if(m_mode == Mode.Console)
    {
		  if(m_Count == 0){
			  Zeitpunkt now = Zeitpunkt(g_Env.mainTimer);
			  m_BlinkTime += now - m_Last;
			  m_Last = now;
			  while(m_BlinkTime > 300.0){
				  m_BlinkTime -= 300.0;
				  m_Blink = !m_Blink;
			  }
			
			  info.pos = vec2(10,m_Console.m_Height-m_LineHeight);
			  info.text = formatBufferAllocator(extractor, "%s%c", m_Console.m_InputBuffer.toArray(), (m_Blink) ? '_' : ' ');
			  info.color = vec4(1.0f,1.0f,1.0f,1.0f);
			  info.font = 0;
		  }
		  else {
			  info.pos = vec2(10,m_Console.m_Height - m_LineHeight * (m_Count+1));
			  info.text = m_Console.m_History[m_Console.m_History.length - (m_Count + m_Console.m_ScrollPos)][];
			  info.color = vec4(1.0f,1.0f,1.0f,1.0f);
			  info.font = 0;
		  }
    }
    else
    {
      info.pos = vec2(15, m_Console.m_Height + 7.0f + m_LineHeight * m_Count);
      info.text = m_Console.m_autocompleteBuffer[m_Count][];
      info.color = vec4(1.0f, 1.0f, 1.0f, 1.0f);
      info.font = 0;
    }
	}	

	override void initInfo(ref ObjectInfoShape info){
    info.color = vec4(1.0f,0.55f,0.0f,0.8f);
    info.vertices = allocArray!vec2(4);
    info.target = HudTarget.SCREEN;
    if(m_mode == Mode.Console)
    {
      info.vertices[0] = vec2(0.0f,0.0f);
      info.vertices[1] = vec2(0.0f,m_Console.m_Height+5.0f);
      info.vertices[2] = vec2(m_Console.m_Width,0.0f);
      info.vertices[3] = vec2(m_Console.m_Width,m_Console.m_Height+5.0f);
    }
    else
    {
      if(m_Count == 0)
      {
        info.vertices[0] = vec2(5.0f, m_Console.m_Height + 2.0f);
        info.vertices[1] = vec2(5.0f, m_Console.m_Height + 12.0f + m_LineHeight * m_Console.m_numAutocompletes);
        info.vertices[2] = vec2(m_Console.m_Width - 100.0f, m_Console.m_Height + 2.0f);
        info.vertices[3] = vec2(m_Console.m_Width - 100.0f, m_Console.m_Height + 12.0f + m_LineHeight * m_Console.m_numAutocompletes);
      }
      else
      {
        info.color = vec4(1.0f,0.75f,0.0f,0.8f);
        info.vertices[0] = vec2(7.0f, m_Console.m_Height + 4.0f + m_LineHeight * m_Console.m_selectedAutocomplete);
        info.vertices[1] = vec2(7.0f, m_Console.m_Height + 6.0f + m_LineHeight * (m_Console.m_selectedAutocomplete + 1));
        info.vertices[2] = vec2(m_Console.m_Width - 102.0f, m_Console.m_Height + 4.0f + m_LineHeight * m_Console.m_selectedAutocomplete);
        info.vertices[3] = vec2(m_Console.m_Width - 102.0f, m_Console.m_Height + 6.0f + m_LineHeight * (m_Console.m_selectedAutocomplete + 1));
      }
    }
	}

	override void extractImpl()
	{
		if(!m_Console.visible)
			return;

		m_Count = 0;
    m_mode = Mode.Console;
    produce!(ObjectInfoShape)();
		produce!(ObjectInfoRCText)(); //input line
		for(m_Count=1;m_Count < m_Console.m_Height / m_LineHeight && m_Count <= m_Console.m_History.length - m_Console.m_ScrollPos;m_Count++){
			produce!(ObjectInfoRCText)();
		}

    if(m_Console.m_numAutocompletes > 0)
    {
      m_mode = Mode.Autocomplete;
      for(m_Count=0; m_Count < 2; m_Count++)
        produce!(ObjectInfoShape)();
      for(m_Count=0; m_Count < m_Console.m_numAutocompletes; m_Count++)
      {
        produce!(ObjectInfoRCText)();
      }
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
  enum size_t MAX_COMMAND_HISTORY_LENGTH = 10;
	
	Vector!(rcstring) m_History;
  Vector!(rcstring) m_CommandHistory;
  sizediff_t m_selectedLastCommand;
  rcstring[] m_autocompleteBuffer;
  size_t m_numAutocompletes;
  size_t m_selectedAutocomplete = 0;
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

  void appendToCommandHistory(ref rcstring line)
  {
    foreach(ref cmd; m_CommandHistory)
    {
      if(cmd[] == line[])
        return;
    }
    m_CommandHistory ~= line;
    if(m_CommandHistory.length > MAX_COMMAND_HISTORY_LENGTH){
      for(size_t i=0;i<MAX_COMMAND_HISTORY_LENGTH;i++){
        m_CommandHistory[i] = m_CommandHistory[i+1];
      }
      m_CommandHistory.resize(MAX_COMMAND_HISTORY_LENGTH);
    }
    m_selectedLastCommand = m_CommandHistory.length - 1;
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
    m_autocompleteBuffer = NewArray!rcstring(10);
    m_CommandHistory = New!(typeof(m_CommandHistory))();
		
		//auto self = cast(shared(Console))this;
		RegisterLogHandler(&this.log);
	}

  ~this()
  {
    UnregisterLogHandler(&this.log);
    Delete(m_CommandHistory);
    Delete(m_autocompleteBuffer);
    Delete(m_History);
    Delete(m_InputBuffer);
    Delete(m_HistoryMutex);
  }

	override IRenderProxy renderProxy(){
		return m_RenderProxy;
	}

	void charIn(dchar c){
		m_InputBuffer ~= c;
    if(m_numAutocompletes != 0)
      autocomplete();
    else if(c == '.')
    {
      autocomplete();
    }
	}
	
	void delLast(){
		if(m_InputBuffer.length > 0){
			m_InputBuffer.resize(m_InputBuffer.length - 1);
		}
    if(m_numAutocompletes != 0)
    {
      autocomplete();
    }
	}
	
	void execute(){
    if(m_numAutocompletes != 0)
    {
      useAutocompleteSuggestion();
    }
    else
    {
		  auto command = to!rcstring(m_InputBuffer.toArray());
		  appendToHistory(command);
      appendToCommandHistory(command);
      m_selectedLastCommand = m_CommandHistory.length-1;
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
	}
	
	void show(bool value){
		visible = value;
	}
	
	void log(LogLevel level, ulong subsystem, scope string str){
		foreach(line; splitLines(rcstring(str))){
			this.appendToHistory(line);
		}
	}
	
	void scrollUp(){
		m_ScrollPos++;
		if(m_ScrollPos >= m_History.length){
			m_ScrollPos = int_cast!uint(m_History.length - 1);
			if(m_ScrollPos < 0)
				m_ScrollPos = 0;
		}
	}
	
	void scrollDown(){
		m_ScrollPos--;
		if(m_ScrollPos < 0)
			m_ScrollPos = 0;
	}

  void prevCommand()
  {
    if(m_numAutocompletes > 0)
    {
      m_selectedAutocomplete--;
      if(m_selectedAutocomplete >= m_numAutocompletes)
        m_selectedAutocomplete = m_numAutocompletes - 1;
    }
    else
    {
      if(m_CommandHistory.length == 0)
        return;
      m_selectedLastCommand--;
      if(m_selectedLastCommand >= m_CommandHistory.length)
        m_selectedLastCommand = m_CommandHistory.length - 1;
      if(m_selectedLastCommand < 0)
        m_selectedLastCommand = 0;
      m_InputBuffer.resize(0);
      foreach(char c; m_CommandHistory[m_selectedLastCommand][])
      {
        m_InputBuffer ~= cast(dchar)c;
      }
    }
  }

  void nextCommand()
  {
    if(m_numAutocompletes > 0)
    {
      m_selectedAutocomplete++;
      if(m_selectedAutocomplete >= m_numAutocompletes)
        m_selectedAutocomplete = 0;
    }
    else
    {
      if(m_CommandHistory.length == 0)
        return;
      if(m_selectedLastCommand == m_CommandHistory.length - 1)
        return;
      m_selectedLastCommand++;
      if(m_selectedLastCommand < 0)
        m_selectedLastCommand = 0;
      if(m_selectedLastCommand >= m_CommandHistory.length)
        m_selectedLastCommand = m_CommandHistory.length - 1;
      m_InputBuffer.resize(0);
      foreach(char c; m_CommandHistory[m_selectedLastCommand][])
      {
        m_InputBuffer ~= cast(dchar)c;
      }
    }
  }

  void autocomplete()
  {
    auto command = to!rcstring(m_InputBuffer.toArray());
    m_numAutocompletes = m_ScriptSystem.autocomplete(command[], m_autocompleteBuffer);
    m_selectedAutocomplete = 0;
  }

  void abort()
  {
    m_numAutocompletes = 0;
  }

  void useAutocompleteSuggestion()
  {
    if(m_numAutocompletes > 0)
    {
      m_InputBuffer.resize(0);
      foreach(char c; m_autocompleteBuffer[m_selectedAutocomplete][])
      {
        m_InputBuffer ~= cast(dchar)c;
      }
      m_numAutocompletes = 0;
    }
  }
}