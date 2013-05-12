module base.profiler;

import base.all;
import thBase.container.stack;
import core.sync.mutex;
import base.memory;
import thBase.container.hashmap;
import thBase.container.vector;
import thBase.format;
import thBase.allocator;
import thBase.policies.locking;


private Profiler ThreadProfiler; //TLS
private __gshared Vector!(Profiler) ProfilerList; //list of all profilers
private __gshared Mutex CreationMutex;

private __gshared vec4[] BlockColors;

shared static this(){
	CreationMutex = New!Mutex();
	ProfilerList = New!(Vector!(Profiler))();
  BlockColors = 
  [
    vec4(0.8f, 0.0f, 0.0f, 1.0f),
    vec4(0.0f, 0.8f, 0.0f, 1.0f),
    vec4(0.0f, 0.0f, 0.8f, 1.0f),
    vec4(0.8f, 0.8f, 0.0f, 1.0f),
    vec4(0.8f, 0.0f, 0.8f, 1.0f),
    vec4(0.0f, 0.8f, 0.8f, 1.0f),
    vec4(0.8f, 0.5f, 0.0f, 1.0f),
    vec4(0.8f, 0.0f, 0.5f, 1.0f),
    vec4(0.5f, 0.8f, 0.0f, 1.0f),
    vec4(0.0f, 0.8f, 0.5f, 1.0f),
    vec4(0.5f, 0.0f, 0.8f, 1.0f),
    vec4(0.0f, 0.5f, 0.8f, 1.0f)
  ];
}

shared static ~this()
{
  Delete(CreationMutex);
  Delete(ProfilerList);
  Delete(BlockColors);
}

static ~this()
{
  if(ThreadProfiler !is null)
  {
    ProfilerList.remove(ThreadProfiler);
    Delete(ThreadProfiler);
    ThreadProfiler = null;
  }
}

void Init(string name){
	assert(ThreadProfiler is null,"this thread already has a profiler");
	synchronized(CreationMutex){
		ThreadProfiler = new Profiler(name); //BUG can't use New! here
		ProfilerList ~= ThreadProfiler;
	}
}

Profiler GetProfiler(){
	assert(ThreadProfiler !is null,"this thread has no profiler yet");
	return ThreadProfiler;
}

void Print(IRenderer renderer){
	assert(CreationMutex !is null);
	synchronized(CreationMutex){
		vec2 pos = vec2(20.0f, 200.0f);
		auto list = ProfilerList;
		foreach(Profiler p;list){
			pos = p.print(renderer, pos);
			pos.y = 200.0f;
			pos.x += 20.0f;
		}
	}	
}

void StartRecording(size_t numFrames)
{
  assert(CreationMutex !is null);
  synchronized(CreationMutex)
  {
    auto list = ProfilerList;
    foreach(Profiler p; list)
    {
      p.startRecording(numFrames);
    }
  }
}

void DrawRecorded(IRenderer renderer)
{
  assert(CreationMutex !is null);
  synchronized(CreationMutex)
  {
    auto list = ProfilerList;
    foreach(Profiler p; list)
    {
      if(p.m_Recorded is null || p.m_nextToRecord < p.m_Recorded.length)
        return;
    }
    Zeitpunkt start = list[0].m_Recorded[0].start;
    foreach(Profiler p; list)
    {
      if(p.m_Recorded[0].start < start)
        start = p.m_Recorded[0].start;
    }
    double recordedLength = 0.0;
    foreach(Profiler p; list)
    {
      foreach(record; p.m_Recorded)
      {
        double length = (record.start - start) + record.time;
        if(length > recordedLength)
          recordedLength = length;
      }
    }
    vec2 pos = vec2(20.0f, 200.0f);
    int width = g_Env.renderer.GetWidth() - 40;
		foreach(Profiler p;list){
			pos = p.drawRecorded(renderer, pos, width, start, recordedLength);
			pos.x = 20.0f;
			pos.y += 20.0f;
		}
  }
}

class Profiler {
private:
  enum size_t CHART_LENGTH = 60 * 3;

	struct Block {
		Block* next = null;
		Block* childs = null;
    Block* lastChild = null;
		
		string name;
		double time;
    Zeitpunkt start;
		
		this(string name){
			this.name = name;
		}
		
		this(string name, Block* next){
			this.name = name;
			this.next = next;
		}
	}
	
	struct Info {
		Zeitpunkt zeitpunkt;
		Block* block;
	}
	
	Stack!(Info) m_Infos;
	
	string m_Name;
	Block *m_Root = null;
	Block *m_LastRoot = null;
  Block*[] m_Recorded;
  size_t m_nextToRecord;
	Mutex m_Mutex;
  ChunkAllocator!(NoLockPolicy) m_blockAllocator;
  Hashmap!(rcstring, Vector!double) m_charts;
	
	void freeBlock(Block* block){
		if(block !is null){
			freeBlock(block.childs);
			freeBlock(block.next);
			AllocatorDelete(m_blockAllocator, block);
		}
	}
	
	void startFrame(){
		m_Root = AllocatorNew!Block(m_blockAllocator, m_Name);
		m_Infos.push(Info(Zeitpunkt(g_Env.mainTimer), m_Root));
	}
	
	void endFrame(){
		endBlock(); //End Root Block
		assert(m_Infos.empty(),"there are still open profile blocks");
		assert(m_Mutex !is null);
		synchronized(m_Mutex){
      if(m_LastRoot !is null)
      {
        if(m_nextToRecord < m_Recorded.length)
        {
          m_Recorded[m_nextToRecord++] = m_LastRoot;
        }
			  else {
				  freeBlock(m_LastRoot);
			  }
      }
			m_LastRoot = m_Root;
			m_Root = null;
      
		}
	}
	
	void startBlock(string name){
		auto block = AllocatorNew!Block(m_blockAllocator, name, null);
    auto topBlock = m_Infos.top().block;
    if(topBlock.lastChild is null)
    {
      topBlock.childs = block;
      topBlock.lastChild = block;
    }
    else
    {
      topBlock.lastChild.next = block;
      topBlock.lastChild = block;
    }
		m_Infos.push(Info(Zeitpunkt(g_Env.mainTimer),block));
	}
	
	double endBlock(){
		auto info = m_Infos.pop();
		info.block.time = Zeitpunkt(g_Env.mainTimer) - info.zeitpunkt;
    info.block.start = info.zeitpunkt;
    assert(info.block.start.isValid());
    synchronized(m_Mutex)
    {
      m_charts.ifExists(_T(info.block.name), (ref values){
        if(values.length >= CHART_LENGTH)
          values.removeAtIndex(0);
        values ~= info.block.time;
      });
    }
    return info.block.time;
	}

  void endManualBlock(double time)
  {
    auto info = m_Infos.pop();
    info.block.time = time;
    info.block.start = info.zeitpunkt;
  }

  void addChart(rcstring blockName)
  {
    synchronized(m_Mutex)
    {
      if(!m_charts.exists(blockName))
      {
        auto values = New!(Vector!double)();
        values.reserve(CHART_LENGTH);
        m_charts[blockName] = values;
      }
    }
  }

  void removeChart(string blockName)
  {
    synchronized(m_Mutex)
    {
      m_charts.ifExists(_T(blockName), (ref values){ 
        Delete(values); 
        m_charts.remove(_T(blockName)); 
      });
    }
  }

  void startRecording(size_t numFrames)
  {
    synchronized(m_Mutex)
    {
      if(m_Recorded.length > 0)
      {
        foreach(block; m_Recorded)
        {
          freeBlock(block);
        }
        Delete(m_Recorded);
        m_Recorded = [];
      }
      m_Recorded = NewArray!(Block*)(numFrames);
      m_nextToRecord = 0;
    }
  }
	
	float printNameHelper(IRenderer renderer, ref const(vec2) pos, Block* block, float indent, ref float y, ref float maxLength){
		if(block is null){
			return indent;
		}
		
		vec2 textSize = renderer.GetTextSize(0,block.name);
		if(textSize.x > maxLength)
			maxLength = textSize.x;
		renderer.DrawText(0, vec2(pos.x + indent, pos.y + y), "%s", block.name);
		y += 15.0f;
		
		float i2 = printNameHelper(renderer,pos,block.childs,indent+10.0f,y,maxLength);
		float i1 = printNameHelper(renderer,pos,block.next,indent,y,maxLength);
		
		if(i1 > indent)
			indent = i1;
		if(i2 > indent)
			indent = i2;
		return indent;
	}
	
	void printValuesHelper(IRenderer renderer, ref const(vec2) pos, Block* block, ref float y, Block *root){
		if(block !is null){
			char[32] buf;
      size_t len = formatStatic(buf, "%.3f", block.time);
      auto text = buf[0..len];
			vec2 textSize = renderer.GetTextSize(0,text);
			renderer.DrawText(0,vec2(pos.x + 35.0f - textSize.x, pos.y + y), text);
			
			formatStatic(buf, "%.1f", block.time / root.time * 100.0);
			textSize = renderer.GetTextSize(0,text);
			renderer.DrawText(0,vec2(pos.x + 85.0f - textSize.x, pos.y + y), text);
			
			y += 15.0f;
			
			printValuesHelper(renderer,pos,block.childs,y,root);
			printValuesHelper(renderer,pos,block.next,y,root);
			
		}
	}
	
	this(string name){
		m_Name = name;
		m_Mutex = New!Mutex();
		m_Infos = New!(Stack!(Info))(8);
    size_t blockSize = Block.sizeof;
    size_t alignOffset = (Block.sizeof % Block.alignof == 0) ? 0 : Block.alignof - (Block.sizeof - Block.alignof);
    m_blockAllocator = New!(ChunkAllocator!(NoLockPolicy))(blockSize + alignOffset, 128, Block.alignof);
    m_charts = New!(typeof(m_charts))();
	}

  ~this()
  {
    if(m_Root !is null)
    {
      freeBlock(m_Root);
      m_Root = null;
    }
    if(m_LastRoot !is null)
    {
      freeBlock(m_LastRoot);
      m_LastRoot = null;
    }
    if(m_Recorded.length > 0)
    {
      foreach(block; m_Recorded)
      {
        freeBlock(block);
      }
      Delete(m_Recorded);
      m_Recorded = [];
    }
    Delete(m_Mutex);
    Delete(m_Infos);
    Delete(m_blockAllocator);
    Delete(m_charts);
  }
	
	vec2 print(IRenderer renderer, vec2 pos){
		assert(m_Mutex !is null);
		float maxY = 0.0f, maxLength = 0.0f;
		float maxIndent = 0.0f;
		assert(m_Mutex !is null);
		synchronized(m_Mutex){
			if(m_LastRoot !is null){
				maxIndent = printNameHelper(renderer,pos,m_LastRoot,0.0f,maxY,maxLength);
				vec2 newPos = vec2(pos.x + maxIndent + maxLength - 10.0f, pos.y);
				maxY = 0.0f;
				printValuesHelper(renderer,newPos,m_LastRoot,maxY,m_LastRoot);
			}
		}
		return vec2(pos.x + maxIndent + maxLength + 65.0f, pos.y + maxY);
	}

  void drawRecordedHelper(IRenderer renderer, vec2 rootPos, float rootWidth, ref Zeitpunkt start, double recordedLength, ref float yOffset, Block* block, ref size_t colorIndex)
  {
    if(block is null)
      return;
    auto pos = vec2((block.start - start) / recordedLength * rootWidth, yOffset) + rootPos;
    float width = block.time / recordedLength * rootWidth;
    float height = 11.0f;
    renderer.DrawRect(pos, width, height, BlockColors[colorIndex % $]);
    renderer.DrawText(1, pos + vec2(1.0f, 1.0f), "%s = %.3f", block.name, block.time);
    colorIndex++;
    yOffset += height;

    drawRecordedHelper(renderer, rootPos, rootWidth, start, recordedLength, yOffset, block.childs, colorIndex);
    drawRecordedHelper(renderer, rootPos, rootWidth, start, recordedLength, yOffset, block.next, colorIndex);
  }

  vec2 drawRecorded(IRenderer renderer, vec2 pos, int width, ref Zeitpunkt start, double recordedLength)
  {
    float maxYOffset = 0.0f;
		assert(m_Mutex !is null);
		synchronized(m_Mutex){
      foreach(record; m_Recorded)
      {
        float yOffset = 0.0f;
        size_t colorIndex = 0;
        drawRecordedHelper(renderer, pos, cast(float)width, start, recordedLength, yOffset, record, colorIndex);
        maxYOffset = yOffset > maxYOffset ? yOffset : maxYOffset;
      }
    }
    return vec2(pos.x, pos.y + maxYOffset);
  }

  float drawCharts(IRenderer renderer, vec2 pos, float width, float chartHeight)
  {
    synchronized(m_Mutex)
    {
      float num = 0.0f;
      float step = width / CHART_LENGTH;
      foreach(ref blockName, ref values; m_charts)
      {
        renderer.DrawText(1, pos + vec2(0, num * chartHeight), "%s", blockName[]);
        float textHeight = 11.0f;
        float borderBottom = 3.0f;
        vec2 bottomLeft = pos + vec2(0.0f, chartHeight - textHeight - borderBottom);
        double maxTime = 1.0f;
        foreach(value; values)
        {
          if(value > maxTime)
            maxTime = value;
        }
        float heightScale = (chartHeight - textHeight - borderBottom) / maxTime;
        for(double d = 1.0f; d <= maxTime; d+=1.0)
        {
          renderer.drawLine(bottomLeft + vec2(d * heightScale, 0.0f), bottomLeft + vec2(d * heightScale, width), vec4(0.5f, 0.5f, 0.5f, 0.5f));
        }
        renderer.drawLine(bottomLeft, pos + vec2(0.0f, textHeight));
        renderer.drawLine(bottomLeft, bottomLeft + vec2(0.0f, width));
        for(size_t i=0; i<values.length-1; i++)
        {
          auto from = vec2(i * step, values[i] * heightScale);
          auto to = vec2((i+1) * step, values[i] * heightScale);
          renderer.drawLine(from, to, vec4(0.0f, 1.0f, 0.0f, 1.0f));
        }

        num += 1.0f;
      }
      return num * chartHeight;
    }
  }
}

struct ProfileLocal
{
  alias void delegate(string name, double timeDiff) callbackFunc;
  callbackFunc callback;
  string name;
  Zeitpunkt start;

  @disable this();

  this(string name, callbackFunc callback)
  {
    start = Zeitpunkt(g_Env.mainTimer);
    this.name = name;
    this.callback = callback;
  }

  ~this()
  {
    auto diff = Zeitpunkt(g_Env.mainTimer) - start;
    callback(name, diff);
  }
}

struct Profile {
  alias void delegate(string name, double timeDiff) callbackFunc;
  callbackFunc callback;
  string name;

  @disable this();

	this(string name){
		assert(ThreadProfiler !is null, "No profiler for this thread");
		ThreadProfiler.startBlock(name);
	}

  this(string name, callbackFunc callback)
  {
		assert(ThreadProfiler !is null, "No profiler for this thread");
    this.name = name;
    this.callback = callback;
		ThreadProfiler.startBlock(name);
  }
	
	~this(){
		double timeDiff = ThreadProfiler.endBlock();
    if(callback !is null)
    {
      callback(name,timeDiff);
    }
	}
}

struct ProfileManual
{
  string name;
  double time;

  @disable this();

	this(string name, double time){
		assert(ThreadProfiler !is null, "No profiler for this thread");
    this.time = time;
		ThreadProfiler.startBlock(name);
	}

	~this(){
		ThreadProfiler.endManualBlock(time);
	}
}

struct ProfileRoot {
private:
	Profiler p;
public:
	this(Profiler p)
	in {
		assert(p !is null);
	}
	body {
		this.p = p;
		p.startFrame();
	}
	
	~this(){
	  p.endFrame();
	}
}