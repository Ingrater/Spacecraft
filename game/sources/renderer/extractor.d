module renderer.extractor;

import core.thread;
import core.sync.semaphore;
import std.c.stdlib;
import std.traits;

import core.memory;
import core.stdc.string;

public import base.renderproxy;
import base.all;
static import base.logger;
import base.game;
import thBase.container.linkedlist;
import thBase.math3d.position;
import thBase.math3d.box;




struct GetExtractorBuffer(T) {
private:
	alias ReturnType!(__traits(getMember,T,"GetBufferStart")) U;
	U m_Buffer;
	T m_Extractor;
	bool m_Success;
public:
	this(T extractor){
		m_Extractor = extractor;
		m_Buffer = m_Extractor.GetBufferStart(m_Success);
	}

	~this(){
		if(m_Success)
			m_Extractor.GetBufferEnd();
	}
	
	U buffer(){
		return m_Buffer;
	}
	
	bool success(){
		return m_Success;
	}
}

interface IRendererExtractorAccess {
	Position origin();
	AlignedBox queryBox();
	bool queryNeeded();
	IGameObject camera();
  void ExtractDebugGeometry(IRendererExtractor extractor);
}

class RendererExtractor : IRendererExtractor {
private:
	struct Buffer {
		byte* buffer;
		byte* cur;
		ObjectInfo* first;
		ObjectInfo* last;
	}
	
	Buffer m_Buffers[2];
	int m_NextToConsume = 0;
	int m_NextToProduce = 0;
	size_t m_MaxMemoryUsed = 0;
	IRendererExtractorAccess m_Renderer;
	bool m_IsProducing = false;
	Position m_Origin;
	bool m_Stop = false;
	Semaphore m_EmptySemaphore;
	Semaphore m_FullSemaphore;
	
	private ObjectInfo* GetBufferStart(ref bool success){
		Buffer *cur = &m_Buffers[m_NextToConsume];
		if( !m_FullSemaphore.wait( dur!("msecs")(20) ) ){
			//debug base.logger.warn("waiting because not procued %d",m_NextToConsume);
			//Avoid deadlocks
			success = false;
			return null;
		}
		success = true;
		return cur.first;
	}
	
	private void GetBufferEnd(){
		Buffer *cur = &m_Buffers[m_NextToConsume];
		m_NextToConsume = (m_NextToConsume + 1) % 2;
		m_EmptySemaphore.notify();
	}
	
public:
	enum size_t BUFFER_SIZE = 8*1024*1024; //8mb
	
	this(IRendererExtractorAccess renderer)
  {
		m_Renderer = renderer;
		foreach(ref buf;m_Buffers){
			buf.buffer = cast(byte*)(StdAllocator.globalInstance.AllocateMemory(BUFFER_SIZE).ptr);
			memset(buf.buffer, 0, BUFFER_SIZE);
			buf.cur = buf.buffer;
		}
		m_FullSemaphore = New!Semaphore(0);
		m_EmptySemaphore = New!Semaphore(2);
	}

	~this(){
    Delete(m_FullSemaphore);
    Delete(m_EmptySemaphore);
		foreach(ref buf;m_Buffers){
			StdAllocator.globalInstance.FreeMemory(buf.buffer);
		}
	}
	
	override void WaitForBuffer()
  {
		Zeitpunkt start = Zeitpunkt(g_Env.mainTimer);
		Buffer *cur = &m_Buffers[m_NextToProduce];
		{
			auto profile = base.profiler.Profile("waiting");
			//start
			while( !m_EmptySemaphore.wait( dur!("msecs")(10) ) && !m_Stop ){
				//debug base.logger.info("waiting for renderer");
			}
		}
		Zeitpunkt waitEnd = Zeitpunkt(g_Env.mainTimer);
		m_IsProducing = true;
		
		if(cur.cur - cur.buffer > m_MaxMemoryUsed){
			m_MaxMemoryUsed = cur.cur - cur.buffer;
		}

    cur.first = null;
    cur.last = null;
    memset(cur.buffer,0,cur.cur-cur.buffer);
    cur.cur = cur.buffer;
  }

  override void extractObjects(IGame game)
  {		
    assert(m_IsProducing, "not producing, make sure to call WaitForBuffer() first");
		{
			auto profile = base.profiler.Profile("producing");
			Octree oct = game.octree;
			if(m_Renderer.queryNeeded){
				m_Origin = m_Renderer.origin;
				
				m_Renderer.camera.renderProxy.extractDo(m_Renderer.camera,this);
				
				//Extract all game objects from the octree
				{
					auto profile2 = base.profiler.Profile("game objects");
					for(auto r = oct.getObjectsInBox(m_Renderer.queryBox); !r.empty(); r.popFront()){
						auto proxy = r.front.renderProxy;
						if(proxy !is null)
            {
							proxy.extractDo(r.front,this);
            }
					}
				}
				
				//Extract all global game objects
				{
					auto profile2 = base.profiler.Profile("global game objects");
					for(auto r = oct.globalObjects(); !r.empty(); r.popFront()){
						auto proxy = r.front.renderProxy;
						if(proxy !is null)
            {
							proxy.extractDo(r.front,this);
            }
					}	
				}
			}

      //Debug geometry and text
      {
        auto profile2 = base.profiler.Profile("debug geom");
        m_Renderer.ExtractDebugGeometry(this);
      }
			
			//Extract all global renderables
			{
				auto profile2 = base.profiler.Profile("renderables");
        auto renderables = oct.globalRenderables();
        foreach(r; renderables)
        {
					auto proxy = r.renderProxy;
					if(proxy !is null)
          {
						proxy.extractDo(r,this);
          }
				}
			}
		}
		
		//end
		m_IsProducing = false;
		m_NextToProduce = (m_NextToProduce+1)%2;
		m_FullSemaphore.notify();
	}

	protected override ObjectInfo* CreateObjectInfo(size_t size)
	body {
    assert(m_IsProducing, "not producing");
		//make shure we do 8 byte alignment (standard alignment on 32 bit platforms)
		if(size % 8 != 0)
			size += 8 - (size % 8);
		Buffer *buf = &m_Buffers[m_NextToProduce];
		ObjectInfo *cur = cast(ObjectInfo*)buf.cur;
		buf.cur += size;
		assert(buf.cur < buf.buffer + BUFFER_SIZE,"not enough memory for renderer extractor");
		*cur = ObjectInfo.init;
		return cur;
	}
	
	public override void[] AllocateMemory(size_t size)
	in {
		assert(m_IsProducing, "not producing");
	}
	body {
		Buffer *buf = &m_Buffers[m_NextToProduce];
		void[] mem = buf.cur[0..size];
		//make shure we do 8 byte alignment (standard alignment on 32 bit platforms)
		if(size % 8 != 0)
			size += 8 - (size % 8);
		buf.cur += size;
		assert(buf.cur < buf.buffer + BUFFER_SIZE,"not enough memory for renderer extractor");
		return mem;
	}

  public override bool IsInBuffer(const(void*) ptr)
  in {
    assert(m_IsProducing, "not producing");
  }
  body
  {
    Buffer *buf = &m_Buffers[m_NextToProduce];
    return (ptr >= buf.buffer) && (ptr < buf.cur);
  }
	
	protected override void addObjectInfo(ObjectInfo* info)
	in {
		assert(info !is null,"info may not be null");
		assert(info.type != 0,"invalid object info");
	}
	body {
		Buffer *cur = &m_Buffers[m_NextToProduce];
		if(cur.first is null)
			cur.first = info;
		if(cur.last !is null)
			cur.last.next = info;
		cur.last = info;		
	}
	
	override Position origin(){
		return m_Origin;
	}
	
	void stop(){
		m_Stop = true;
	}

  @property bool isRunning() const
  {
    return !m_Stop;
  }
}