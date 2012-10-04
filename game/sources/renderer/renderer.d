module renderer.renderer;

import core.thread;
import core.sync.semaphore;
import core.vararg;

import thBase.allocator;
import thBase.serialize.xmldeserializer;
import thBase.math3d.all;
import thBase.timer;
import thBase.container.queue;
import thBase.container.hashmap;
import thBase.container.vector;

import std.traits;

import base.eventlistener;
import base.renderer;
import base.messages;
static import base.logger, base.profiler;

import renderer.rendertarget;
import renderer.xmlshader;
import renderer.font;
import renderer.vertexbuffer;
import renderer.shaderconstants;
import renderer.vertexbuffermanager;
import renderer.stateobject;
import renderer.model;
import renderer.renderslice;
import renderer.rendergroup;
import renderer.rendercall;
import renderer.texture2d;
import renderer.shader;
import renderer.globalvariables;
import renderer.opengl;
import renderer.sdl.main;
import renderer.extractor;
import renderer.objectinfos;
import renderer.messages;
import renderer.assetloader;
import renderer.renderproxys;
import renderer.camera;
import renderer.frustrum;
import renderer.cvars;
import renderer.cubetexture;
import renderer.sprite;
import renderer.imagedata2d;
public import renderer.internal;

/**
 * Renderer implementation
 * See: IRenderer for public methods
 */
class Renderer : IRenderer, 
				 IRendererInternal,
				 IRendererExtractorAccess
{
private:
	Zeitpunkt m_CurrentTime;
	Zeitpunkt m_LastFrameCount;
	Zeitpunkt m_LastTime;
	
	uint m_Frame = 0;
	float m_FramesPerSecond = 0.0f;
	float m_SimulationsPerSecond = 0.0f;
	int m_Height,m_Width;
	int m_ObjectsDrawn = 0;
	size_t m_NumberOfRenderCalls = 0;
	size_t m_NumberOfSprites = 0;
	size_t m_NumberOfSpriteDrawCalls = 0;
	size_t m_NumberOfShapeDrawCalls = 0;
	int m_VertexBufferMemoryAmount = 0;
	int m_TextureMemoryAmount = 0;
	
	bool m_PostProcessingSwitch = false;
	bool m_PostProcessing = false;
	
	Rendertarget m_MainRendertarget;
	Rendertarget m_DataHoldingRendertarget;
	Rendertarget m_PostProcessing1;
	Rendertarget m_PostProcessing2;
	Rendertarget m_HudRendertarget;
	Rendertarget m_ShadowMap;
	
	VertexBufferManager m_VertexBufferManager;
	AssetLoader m_AssetLoader;
	
	bool m_IsVisible = true;
	
	ShaderConstantLibImpl m_ShaderConstants = null;
	
	GlobalVariableBasicType!(mat4) m_ProjectionMatrix,m_ViewMatrix,m_ModelMatrix,m_ModelViewMatrix,m_InverseViewMatrix,m_InverseProjectionMatrix;
	GlobalVariableBasicType!(mat3) m_NormalMatrix,m_ModelMatrixInverseTransposed;
	GlobalVariableBasicType!(vec4) m_FontColor;
	
	ShaderConstantMat4 m_ProjectionMatrixConstant,m_ViewMatrixConstant,m_ModelMatrixConstant;
	ShaderConstantMat4ChildMul m_ModelViewMatrixConstant;
	ShaderConstantMat4ChildNormal m_NormalMatrixConstant,m_ModelMatrixInverseTransposedConstant;
	ShaderConstantMat4ChildInverse m_InverseViewMatrixConstant,m_InverseProjectionMatrixConstant;
	ShaderConstantSimpleType!(float) m_HeightConstant, m_WidthConstant;
	ShaderConstantSimpleType!(vec2) m_TextPos; //position of text for font shader
	ShaderConstantRef!(vec4) m_FontColorConstant;
	ShaderConstantSimpleType!(vec2) m_ShadowOffsetConstant;
	ShaderConstantSimpleType!float m_ShadowMaxDistanceConstant;
	ShaderConstantSimpleType!mat4 m_LightMatrixConstant;
	
	Timer m_Timer;
	
	Font m_EngineFont;
  Font m_SmallEngineFont;
	StateObject m_FontState;
	VertexBuffer m_FontBuffer;
  RenderGroup m_Group2D;
	RenderGroup m_FontGroup;
	bool m_UpdateFontBuffer = false;
	
	RenderGroup m_DebugGroup;
	StateObject m_DebugState;
	VertexBuffer m_DebugBuffer;
	bool m_UpdateDebugBuffer = false;
	
	StateObject m_SpriteState;
	VertexBuffer m_SpriteBuffer;
	bool m_UpdateSpriteBuffer = false;
	uint m_LastSpriteAtlas = 0;
	uint m_LastSpriteVertex = 0;
	
	StateObject m_AlphaSpriteState;
	VertexBuffer m_AlphaSpriteBuffer;
	bool m_UpdateAlphaSpriteBuffer = false;
	uint m_LastAlphaSpriteAtlas = 0;
	uint m_LastAlphaSpriteVertex = 0;
	
	VertexBuffer m_ScreenQuad;
	
	XmlShader m_FontShader;
	XmlShader m_ScreenFillShader;
	XmlShader m_LinesShader;
	XmlShader m_SpriteShader;
	XmlShader m_Hud3dShader;
  XmlShader m_TextureShader;

  Material m_HudMaterial;
	
	XmlShader m_ShapeShader;
	VertexBuffer m_ShapeBuffer;
	StateObject m_HudState;
	bool m_UpdateShapeBuffer = false;
	
	StateObject m_DefaultState;
	StateObject m_GeometryState;

	Vector!(RenderSlice) m_RenderSlices;
	Vector!(Texture2D) m_DownloadTextures;
	Hashmap!(uint, SpriteAtlas) m_SpriteAtlases;
	
	RendererExtractor m_Extractor;
	IGameObject m_Camera;
	Position m_FrameOrigin;
	
	vec3 m_LightDir;
	ShaderConstantSimpleType!vec3 m_LightPosConstant,m_LightDirConstant;
	ShaderConstantSimpleType!vec4 m_AmbientColorConstant,m_LightColorConstant;
	ShaderConstantSimpleType!float m_SpecularPowerConstant;
	
	CVars m_CVars;
	
  MessageQueue_t m_MessageQueue;
  MessageQueue_t m_PreExtractMessageQueue;
  MessageQueue_t m_LoadingMessageQueue;

  ReturnType!GetNewTemporaryAllocator m_FrameAllocator;
	
	version(direct_draw){
		// variables for synchronizing direct draw batch commands
		static int m_ThreadId = -1; //TLS
		__gshared int m_ThreadCount = 0;
		__gshared Mutex m_BatchStartMutex;
		
		struct BatchThread {
			Semaphore full;
			Semaphore empty;
			Mutex producingMutex;
			bool isProducing = false;
		}
		
		struct MultipleLock {
			BatchThread[] m_Batches;
			bool[] lockMade;
			this(BatchThread[] batches){
				m_Batches = batches;
				lockMade = new bool[m_Batches.length];
				foreach(i,ref b;batches){
					if(b.full !is null){
						if(!b.full.wait( dur!("msecs")(5) )){
							base.logger.warn("game did not produce direct draw calls");
							lockMade[i] = false;
						}
						else {
							lockMade[i] = true;
						}
          }
				}
			}
			
			~this(){
				foreach(i,ref b;m_Batches){
					if(b.full !is null && lockMade[i])
						b.empty.notify();
				}
			}
		}
		
		__gshared BatchThread[4] m_BatchThreads;
		
		bool isDirectDrawBatchWorking() shared {
			assert(m_ThreadId >= 0);
			return (m_BatchThreads[m_ThreadId].isProducing);
		}
		
		Mutex producingMutex() shared {
			return m_BatchThreads[m_ThreadId].producingMutex;
		}
	}

protected:
	version(direct_draw){
		override void startDirectDrawBatch() shared {
			if(m_ThreadId == -1){
				synchronized(m_BatchStartMutex){
					m_ThreadId = m_ThreadCount++;
					assert(m_ThreadId < m_BatchThreads.length);
					m_BatchThreads[m_ThreadId].full = new Semaphore(0);
					m_BatchThreads[m_ThreadId].empty = new Semaphore(1);
					m_BatchThreads[m_ThreadId].producingMutex = new Mutex;
				}
			}
			if(m_BatchThreads[m_ThreadId].empty.tryWait()){
				synchronized(producingMutex){
					m_BatchThreads[m_ThreadId].isProducing = true;
				}
			}
		}
		
		override void stopDirectDrawBatch() shared {
			assert(m_ThreadId >= 0);
			synchronized(producingMutex){
				if(m_BatchThreads[m_ThreadId].isProducing){
					m_BatchThreads[m_ThreadId].isProducing = false;
					m_BatchThreads[m_ThreadId].full.notify();
				}
			}
		}
	}
	
	
public:
	this(){
		m_ShaderConstants = New!ShaderConstantLibImpl();
		m_Timer = New!Timer();
		m_DefaultState = New!StateObject();
		m_GeometryState = New!StateObject();
		m_RenderSlices = New!(Vector!(RenderSlice))();
		m_DownloadTextures = New!(Vector!(Texture2D))();
    m_SpriteAtlases = New!(typeof(m_SpriteAtlases))();
		m_VertexBufferManager = New!VertexBufferManager();
    m_Extractor = New!RendererExtractor(this);
		
		m_FrameOrigin = Position(vec3(0,0,0));
    m_MessageQueue = New!(typeof(m_MessageQueue))(16 * 1024); //Main message queue 16 kb
    m_PreExtractMessageQueue = New!(typeof(m_PreExtractMessageQueue))(1024); //Pre extract message queue 1 kb
    m_LoadingMessageQueue = New!(typeof(m_LoadingMessageQueue))(2 * 1024); //Loading message queue 2kb
	}

  ~this()
  {
    Delete(m_LoadingMessageQueue);
    Delete(m_PreExtractMessageQueue);
    Delete(m_MessageQueue);
    Delete(m_Extractor);
    Delete(m_VertexBufferManager);
    Delete(m_DownloadTextures);
    Delete(m_SpriteAtlases);
    Delete(m_RenderSlices);
    Delete(m_GeometryState);
    Delete(m_DefaultState);
    Delete(m_Timer);
    Delete(m_ShaderConstants);
  }

	version(direct_draw){
		shared static this(){
			m_BatchStartMutex = new Mutex;
		}
	}
	
	//---------------------------------------------------------------------------
	// start IRendererInternal
	
	void UseDefaultState(){
		if(StateObject.GetCurrentStateObject() !is null)
			m_DefaultState.copy(StateObject.GetCurrentStateObject());
		m_DefaultState.SetColorWrite(true);
		m_DefaultState.SetDepthWrite(true);
		m_DefaultState.SetStencilMask(0xFFFFFFFF);
		m_DefaultState.Use();
	}
	
	Rendertarget GetDataHoldingRendertarget(){
		return m_DataHoldingRendertarget;
	}
	
	void SetDataHoldingRendertarget(Rendertarget pRendertarget)
	in {
		assert(pRendertarget !is null,"pRendertarget may not be null");
	}
	body {
		m_DataHoldingRendertarget = pRendertarget;
	}
	
	Rendertarget GetMainRendertarget(){
		return m_MainRendertarget;
	}
	
	Rendertarget GetPostProcessingRendertarget(){
		m_PostProcessingSwitch = !m_PostProcessingSwitch;
		if(m_PostProcessingSwitch){
			m_DataHoldingRendertarget = m_PostProcessing1;
			return m_PostProcessing1;
		}
		else {
			m_DataHoldingRendertarget = m_PostProcessing2;
			return m_PostProcessing2;
		}
	}
	
	void Clear(bool pClearDepth, bool pClearColor, bool pClearStencil){
		if(StateObject.GetCurrentStateObject() !is null)
			m_DefaultState.copy(StateObject.GetCurrentStateObject());
		m_DefaultState.SetColorWrite(true);
		m_DefaultState.SetDepthWrite(true);
		m_DefaultState.SetStencilMask(0xFFFFFFFF);
		m_DefaultState.Use();
		gl.GLenum options = 0;
		if(pClearDepth)
			options |= gl.DEPTH_BUFFER_BIT;
		if(pClearColor)
			options |= gl.COLOR_BUFFER_BIT;
		if(pClearStencil)
			options |= gl.DEPTH_BUFFER_BIT;
		if(options != 0)
			gl.Clear(options);
	}
	
	// end IRendererInternal
	//---------------------------------------------------------------------------
	
	//---------------------------------------------------------------------------
	// start IRenderer
	
	shared override int GetWidth() const {
		return m_Width;
	}
	
	int GetWidth() const {
		return m_Width;
	}
	
	shared override int GetHeight() const {
		return m_Height;
	}
	
	int GetHeight() const {
		return m_Height;
	}
	
	override shared(IAssetLoader) assetLoader() shared {
		return m_AssetLoader;
	}
	
	const(Font) GetEngineFont() const 
	out(result){
		assert(result !is null,"result may not be null");
	}
	body {
		return m_EngineFont;
	}

  @property MessageQueue_t messageQueue()
  {
    return m_MessageQueue;
  }

  @property shared(MessageQueue_t) messageQueue() shared
  {
    return m_MessageQueue;
  }

  @property MessageQueue_t loadingQueue()
  {
    return m_LoadingMessageQueue;
  }

  @property shared(MessageQueue_t) loadingQueue() shared
  {
    return m_LoadingMessageQueue;
  }

	
	Shader GetFontShader()
	out(result){
		assert(result !is null,"Result may not be null");
	}
	body {
		return m_FontShader.GetShader();
	}
	
	void AddVertexBufferToUpdate(VertexBuffer pVertexBuffer){
		m_VertexBufferManager.AddVertexBufferToUpdate(pVertexBuffer);
	}
	
	void SetRenderSliceNum(size_t pNum)
	in {
		assert(pNum > 0,"pNum may not be 0");
	}
	body {
		auto old = m_RenderSlices.size();
		m_RenderSlices.resize(pNum);
		if(pNum > old){
			for(size_t i=old;i<pNum;i++){
				m_RenderSlices[i] = new RenderSlice(this);
			}
		}
	}
	
	VertexBuffer GetScreenQuad()
	out(result){
		assert(result !is null,"result may not be null");
	}
	body {
		return m_ScreenQuad;
	}
	
	Shader GetScreenFillShader()
	out(result){
		assert(result !is null,"result may not be null");
	}
	body {
		return m_ScreenFillShader.GetShader();
	}
	
	GlobalVariableBasicType!(mat4) GetProjectionMatrix()
	out(result){
		assert(result !is null,"result may not be null");
	}
	body {
		return m_ProjectionMatrix;
	}
	
	ShaderConstant GetProjectionMatrixConstant()
	out(result){
		assert(result !is null,"result may not be null");
	}
	body {
		return m_ProjectionMatrixConstant;	
	}
	
	GlobalVariableBasicType!(mat4) GetViewMatrix()
	out(result){
		assert(result !is null,"result may not be null");
	}
	body {
		return m_ViewMatrix;
	}
	
	ShaderConstant GetViewMatrixConstant()
	out(result){
		assert(result !is null,"result may not be null");
	}
	body {
		return m_ViewMatrixConstant;
	}
	
	GlobalVariableBasicType!(mat4) GetModelMatrix()
	out(result){
		assert(result !is null,"result may not be null");
	}
	body {
		return m_ModelMatrix;
	}
	
	ShaderConstant GetModelMatrixConstant()
	out(result){
		assert(result !is null,"result may not be null");
	}
	body {
		return m_ModelMatrixConstant;
	}
	
	RenderSlice GetRenderSlice(int pId)
	in {
		assert(pId >= 0 && pId < m_RenderSlices.size(),"pId out of range");
	}
	out(result){
		assert(result !is null,"result may not be null");
	}
	body {
		return m_RenderSlices[pId];
	}
	
	private void DrawText(Font pFont, vec2 pPos, vec4 pColor, RenderGroup pGroup, VertexBuffer pVertexBuffer, const char[] pText)
	in {
		assert(pGroup !is null,"pGroup may not be null");
		assert(pVertexBuffer !is null,"pVertexBuffer may not be null");
	}
	body {	    
		if(pText.length == 0)
			return;
		if(pVertexBuffer is m_FontBuffer){
			m_UpdateFontBuffer = true;
		}
		
	    size_t start = pVertexBuffer.GetVerticesInBuffer();
	    pFont.Print(pVertexBuffer, pText);
	    size_t stop = pVertexBuffer.GetVerticesInBuffer();
		  assert(start != stop);
	    
	    RenderCall call = pGroup.AddRenderCall();
	    call.SetVertexBuffer(pVertexBuffer);
	    call.SetShader(m_FontShader.GetShader());
	    call.SetStateObject(m_FontState);
	    call.AddTexture(pFont.GetFontTexture(),0);
	    call.Overwrite(m_FontColorConstant,pColor);
		  call.Overwrite(m_TextPos,pPos);
	    call.SetRange(cast(uint)start,cast(uint)(stop-start));
	}

	private void DrawFormatText(Font pFont, vec2 pPos, vec4 pColor, RenderGroup pGroup, VertexBuffer pVertexBuffer, string fmt, ...)
	in {
		assert(pGroup !is null,"pGroup may not be null");
		assert(pVertexBuffer !is null,"pVertexBuffer may not be null");
	}
	body {	    

		char[2048] buffer;
    char[] text;

    size_t len = formatDoStatic(buffer, fmt, _arguments, _argptr);
    if(len > buffer.length)
    {
      text = AllocatorNewArray!char(ThreadLocalStackAllocator.globalInstance, len);
      formatDoStatic(text, fmt, _arguments, _argptr);
    }
    else
    {
      text = buffer[0..len];
    }
    scope(exit)
    {
      if( text.ptr != buffer.ptr )
        AllocatorDelete(ThreadLocalStackAllocator.globalInstance, text);
    }

		if(text.length == 0)
			return;
		if(pVertexBuffer is m_FontBuffer){
			m_UpdateFontBuffer = true;
		}

    size_t start = pVertexBuffer.GetVerticesInBuffer();
    pFont.Print(pVertexBuffer, text);
    size_t stop = pVertexBuffer.GetVerticesInBuffer();
    assert(start != stop);

    RenderCall call = pGroup.AddRenderCall();
    call.SetVertexBuffer(pVertexBuffer);
    call.SetShader(m_FontShader.GetShader());
    call.SetStateObject(m_FontState);
    call.AddTexture(pFont.GetFontTexture(),0);
    call.Overwrite(m_FontColorConstant,pColor);
    call.Overwrite(m_TextPos,pPos);
    call.SetRange(cast(uint)start,cast(uint)(stop-start));
	}
	
	private void DrawText(uint pFont, vec2 pPos, vec4 pColor, string fmt, TypeInfo[] arguments, va_list argptr) shared {
	    version(direct_draw){
			synchronized(producingMutex()){
			if(!isDirectDrawBatchWorking())
				return;
			
			char[] fmt;
		
			void putc(dchar c)
			{
	    		std.utf.encode(fmt, c);
			}
			std.format.doFormat(&putc, arguments, argptr);

			//writefln("sending MsgDrawText");
			send(GetTid(), MsgDrawText(pFont,pPos,pColor,to!string(fmt)) );	
			}
		}
	}
	
	override void DrawText(uint pFont, vec2 pPos, vec4 pColor, const(char)[] fmt, ...) shared {
		this.DrawText(pFont, pPos, pColor, fmt, _arguments, _argptr);
	}
	
	override void DrawText(uint pFont, vec2 pPos, const(char)[] fmt, ...) shared {
		this.DrawText(pFont, pPos, vec4(1.0f, 1.0f, 1.0f, 1.0f), fmt, _arguments, _argptr);
	}
	
	private void DrawText(uint pFont, vec2 pPos, vec4 pColor, const(char)[] fmt, TypeInfo[] arguments, va_list argptr) {
		char[2048] buffer;
    char[] text;

    size_t len = formatDoStatic(buffer, fmt, arguments, argptr);
    if(len > buffer.length)
    {
      text = AllocatorNewArray!char(ThreadLocalStackAllocator.globalInstance, len);
      formatDoStatic(text, fmt, arguments, argptr);
    }
    else
    {
      text = buffer[0..len];
    }
    scope(exit)
    {
      if( text.ptr != buffer.ptr )
        AllocatorDelete(ThreadLocalStackAllocator.globalInstance, text);
    }

		this.DrawText(Font.GetFont(pFont), pPos, pColor, m_FontGroup, m_FontBuffer, text);	
	}
	
	override void DrawText(uint pFont, vec2 pPos, vec4 pColor, const(char)[] fmt, ...) {
		this.DrawText(pFont, pPos, pColor, fmt, _arguments, _argptr);
	}
	
	override void DrawText(uint pFont, vec2 pPos, const(char)[] fmt, ...) {
		this.DrawText(pFont, pPos, vec4(1.0f,1.0f,1.0f,1.0f), fmt, _arguments, _argptr);
	}

  override void DrawRect(vec2 pos, float width, float height, vec4 color)
  {
    size_t start = m_ShapeBuffer.GetVerticesInBuffer();
    m_ShapeBuffer.AddVertexData(pos);
    m_ShapeBuffer.AddVertexData(color);
    m_ShapeBuffer.AddVertexData(pos + vec2(0.0f, height));
    m_ShapeBuffer.AddVertexData(color);
    m_ShapeBuffer.AddVertexData(pos + vec2(width, 0.0f));
    m_ShapeBuffer.AddVertexData(color);
    m_ShapeBuffer.AddVertexData(pos + vec2(width, height));
    m_ShapeBuffer.AddVertexData(color);
    size_t end = m_ShapeBuffer.GetVerticesInBuffer();
    if(end - start >= 3){
      int swap = 0;
      uint indexStart = m_ShapeBuffer.GetNumberOfIndicies(0);
      for(size_t i=0;i< end - start - 2;i++){
        m_ShapeBuffer.AddIndexData(0,i + start);
        m_ShapeBuffer.AddIndexData(0,i+1 + swap + start);
        m_ShapeBuffer.AddIndexData(0,i+2 - swap + start);
        swap = (swap + 1) % 2;
      }
      uint indexEnd = m_ShapeBuffer.GetNumberOfIndicies(0);

      m_UpdateShapeBuffer = true;

      auto call = m_Group2D.AddRenderCall();
      call.SetVertexBuffer(m_ShapeBuffer);
      call.SetShader(m_ShapeShader.GetShader());
      call.SetStateObject(m_HudState);
      call.SetRange(indexStart, indexEnd-indexStart);
      m_NumberOfShapeDrawCalls++;
    }
  }
	
	
	
	final XmlShader CreateXmlShader()
	out(result){
		assert(result !is null,"result may not be null");
	}
	body {
		return New!XmlShader(m_ShaderConstants);
	}

  final void DeleteXmlShader(XmlShader shader)
  {
    Delete(shader);
  }
	
	Model CreateModel()
	out(result){
		assert(result !is null,"result may not be null");
	}
	body {
		return new Model(m_VertexBufferManager,this);
	}
	
	SpriteAtlas CreateSpriteAtlas(Texture2D texture){
		static int nextAtlasId = 0;
		auto result = new SpriteAtlas(nextAtlasId,texture);
		m_SpriteAtlases[nextAtlasId] = result;
		nextAtlasId++;
		return result;
	}
	
	void RegisterShaderConstant(rcstring pName, ShaderConstant pConstant)
	in {
		assert(pConstant !is null,"pConstant may not be null");
		assert(pName.length > 0,"pName may not be empty");
	}
	body {
		m_ShaderConstants.RegisterShaderConstant(pName, pConstant);
	}
	
	override void camera(IGameObject obj){
		//base.logger.info("renderer: setting camera to %s", obj.inspect());
		m_Camera = obj;
	}
	
	override void camera(IGameObject obj) shared {
    m_PreExtractMessageQueue.enqueue(MsgCamera(obj));
	}		
	
	// end IRenderer
	//---------------------------------------------------------------------------
	
	//---------------------------------------------------------------------------
	// start IEventListener
	
	void OnFocus(bool hasFocus, ubyte state){
		//TODO set m_isVisible here
	}
	
	void OnResize(int width, int height){
		synchronized(this){
			m_Width = width;
			m_Height = height;
			Renderer sthis = cast(Renderer)this;
			if(sthis.m_WidthConstant !is null)
				sthis.m_WidthConstant.Set(cast(float)m_Width);
			if(sthis.m_HeightConstant !is null)
				sthis.m_HeightConstant.Set(cast(float)m_Height);
		}
	}
	
	void OnQuit(){
	}
	
	// end IEventListener
	//---------------------------------------------------------------------------
	// start IRendererExtractorAccess
	
	override Position origin(){
		if(m_CameraFreezed){
			return m_FreezedCamPos;
		}
		m_Camera.position.validate();
		Position pos = m_Camera.position;
		pos.relPos = vec3(0.0f,0.0f,0.0f);
		assert(pos.isValid());
		return pos;
	}
	
	bool m_CameraFreezed = false;
	Position m_FreezedCamPos;
	AlignedBox m_FreezedQueryBox;
	
	override void freezeCamera() {
		synchronized(this){
			if(!m_CameraFreezed){
				m_FreezedCamPos = m_Camera.position;
				m_FreezedQueryBox = queryBox;
			}
			m_CameraFreezed = !m_CameraFreezed;
		}
	}
	
	override AlignedBox queryBox()
	out (box){
		assert(box.isValid);
	}
	body {
		if(m_CameraFreezed){
			return m_FreezedQueryBox;
		}
		CameraProxy proxy = cast(CameraProxy)m_Camera.renderProxy;
		mat4 clip = m_Camera.rotation.toMat4().Inverse() * proxy.camera.GetProjectionMatrix();
		Frustrum frust = Frustrum(clip);
		vec3[] points = frust.corners();
		vec3 minimum,maximum;
		foreach(ref p;points){
			minimum = min(minimum,p);
			maximum = max(maximum,p);
		}
		return AlignedBox(m_Camera.position - maximum, m_Camera.position - minimum);
	}
	
	override bool queryNeeded() {
		return (m_Camera !is null);
	}
	
	override IGameObject camera() {
		return m_Camera;
	}
	
	// end IRendererExtractor Access
	//---------------------------------------------------------------------------
	
	void Init(shared(IGame) game)
	in {
		assert(game !is null);
	}
	body {
		gl.ClearColor(0.0f,0.0f,0.0f,0.0f);
		gl.ClearDepth(1.0f);
		gl.ClearStencil(0);
		gl.DepthFunc(gl.LESS);
		
		gl.MatrixMode(gl.PROJECTION);
		gl.LoadIdentity();
		gl.MatrixMode(gl.MODELVIEW);
		gl.LoadIdentity();
		
		gl.PointSize(1.0f);
		gl.Disable(gl.POINT_SMOOTH);
		
		m_DefaultState.SetDepthTest(true);
		m_DefaultState.SetDepthWrite(true);
		m_DefaultState.SetColorWrite(true);
		
		//Setup default variables
		m_FontColor = New!(GlobalVariableBasicType!vec4)();
		m_FontColor.Set(vec4(1.0f,1.0f,1.0f,1.0f));
		
		//Setup matrices
		m_ProjectionMatrix = New!(GlobalVariableBasicType!mat4)();
		m_ProjectionMatrix.Set(mat4.ProjectionMatrix(45.0f,cast(float)m_Height / cast(float)m_Width,1,1000));
		
		m_ViewMatrix = New!(GlobalVariableBasicType!mat4)();
		m_ViewMatrix.Set(mat4.Identity());
		
		m_InverseViewMatrix = New!(GlobalVariableBasicType!mat4)();
		m_InverseViewMatrix.Set(mat4.Identity());
		
		m_InverseProjectionMatrix = New!(GlobalVariableBasicType!mat4)();
		m_InverseProjectionMatrix.Set(mat4.Identity());
		
		m_ModelMatrix = New!(GlobalVariableBasicType!mat4)();
		m_ModelMatrix.Set(mat4.Identity());
		
		m_ModelViewMatrix = New!(GlobalVariableBasicType!mat4)();
		m_ModelViewMatrix.Set(mat4.Identity());
		
		m_NormalMatrix = New!(GlobalVariableBasicType!mat3)();
		m_NormalMatrix.Set(mat3.Identity());
		
		m_ModelMatrixInverseTransposed = New!(GlobalVariableBasicType!mat3)();
		m_ModelMatrixInverseTransposed.Set(mat3.Identity());
		
		//Setup shader constants		
		m_ProjectionMatrixConstant = New!ShaderConstantMat4(m_ProjectionMatrix);
		m_ShaderConstants.RegisterShaderConstant(_T("ProjectionMatrix"),m_ProjectionMatrixConstant);
		
		m_ModelMatrixConstant = New!ShaderConstantMat4(m_ModelMatrix);
		m_ShaderConstants.RegisterShaderConstant(_T("ModelMatrix"),m_ModelMatrixConstant);
		
		m_ViewMatrixConstant = New!ShaderConstantMat4(m_ViewMatrix);
		m_ShaderConstants.RegisterShaderConstant(_T("ViewMatrix"),m_ViewMatrixConstant);
		
		m_ModelViewMatrixConstant = New!ShaderConstantMat4ChildMul(m_ModelViewMatrix);
		m_ModelViewMatrixConstant.SetFather2(m_ViewMatrixConstant);
		m_ModelViewMatrixConstant.SetFather1(m_ModelMatrixConstant);
		m_ShaderConstants.RegisterShaderConstant(_T("ModelViewMatrix"),m_ModelViewMatrixConstant);
		
		m_NormalMatrixConstant = New!ShaderConstantMat4ChildNormal(m_NormalMatrix);
		m_NormalMatrixConstant.SetFather(m_ModelViewMatrixConstant);
		m_ShaderConstants.RegisterShaderConstant(_T("NormalMatrix"),m_NormalMatrixConstant);
		
		m_ModelMatrixInverseTransposedConstant = New!ShaderConstantMat4ChildNormal(m_ModelMatrixInverseTransposed);
		m_ModelMatrixInverseTransposedConstant.SetFather(m_ModelMatrixConstant);
		m_ShaderConstants.RegisterShaderConstant(_T("ModelMatrixInverseTransposed"),m_ModelMatrixInverseTransposedConstant);
		
		m_InverseViewMatrixConstant = New!ShaderConstantMat4ChildInverse(m_InverseViewMatrix);
		m_InverseViewMatrixConstant.SetFather(m_ViewMatrixConstant);
		m_ShaderConstants.RegisterShaderConstant(_T("InverseViewMatrix"),m_InverseViewMatrixConstant);
		
		m_InverseProjectionMatrixConstant = New!ShaderConstantMat4ChildInverse(m_InverseProjectionMatrix);
		m_InverseProjectionMatrixConstant.SetFather(m_ProjectionMatrixConstant);
		m_ShaderConstants.RegisterShaderConstant(_T("InverseProjectionMatrix"),m_InverseProjectionMatrixConstant);
		
		m_HeightConstant = New!(ShaderConstantSimpleType!float)();
		m_HeightConstant.Set(cast(float)m_Height);
		m_ShaderConstants.RegisterShaderConstant(_T("Height"),m_HeightConstant);
		
		m_WidthConstant = New!(ShaderConstantSimpleType!float)();
		m_WidthConstant.Set(cast(float)m_Width);
		m_ShaderConstants.RegisterShaderConstant(_T("Width"),m_WidthConstant);
		
		m_FontColorConstant = New!(ShaderConstantRef!vec4)(m_FontColor);
		m_ShaderConstants.RegisterShaderConstant(_T("FontColor"),m_FontColorConstant);
		
		m_TextPos = New!(ShaderConstantSimpleType!vec2)();
		m_TextPos.Set(vec2(0.0f,0.0f));
		m_ShaderConstants.RegisterShaderConstant(_T("TextPos"),m_TextPos);

		InitShaderConstants();
		
		StateObject.SetViewMatrix(m_ViewMatrixConstant);
		Model.SetConstants(m_ModelMatrixConstant,null);
		
		//Load default font
		m_EngineFont = New!Font(_T("DejaVuSans12"), this);
		m_EngineFont.Load("gfx/dejavusans.ttf", 12);
    m_SmallEngineFont = New!Font(_T("DejaVuSans9"), this);
    m_SmallEngineFont.Load("gfx/dejavusans.ttf", 9);
		
		//Setup other font stuff
		m_FontState = New!StateObject();
		m_FontState.SetDepthTest(false);
		m_FontState.SetBlending(true);
		m_FontState.SetBlendFunc(StateObject.Blending.SRC_ALPHA,StateObject.Blending.ONE_MINUS_SRC_ALPHA);
		
		VertexBuffer.DataChannels[2] FontChannels; 
			FontChannels[0] = VertexBuffer.DataChannels.POSITION_2;
			FontChannels[1] = VertexBuffer.DataChannels.TEXCOORD0;
		m_FontBuffer = New!VertexBuffer(this,
										                FontChannels,
		                                VertexBuffer.Primitive.QUADS,
		                                VertexBuffer.IndexBufferSize.INDEX16,
		                                true);										 
		
		//Load default shader
		m_FontShader = New!XmlShader(m_ShaderConstants);
		m_FontShader.Load(_T("shader/font.xml"));
		m_FontShader.Upload();
		
		m_ScreenFillShader = New!XmlShader(m_ShaderConstants);
		m_ScreenFillShader.Load(_T("shader/screenfill.xml"));
		m_ScreenFillShader.Upload();
		
		m_LinesShader = New!XmlShader(m_ShaderConstants);
		m_LinesShader.Load(_T("shader/debuglines.xml"));
		m_LinesShader.Upload();
		
		m_SpriteShader = New!XmlShader(m_ShaderConstants);
		m_SpriteShader.Load(_T("shader/sprite.xml"));
		m_SpriteShader.Upload();
		
		m_Hud3dShader = New!XmlShader(m_ShaderConstants);
		m_Hud3dShader.Load(_T("shader/hud3d.xml"));
		m_Hud3dShader.Upload();

    m_TextureShader = CreateXmlShader();
		m_TextureShader.AddSource("#define DIFFUSE_MAP\n#define NO_SHADOW",Shader.ShaderType.FRAGMENT_SHADER);
		m_TextureShader.Load(_T("shader/textures.xml"));
		m_TextureShader.SetName(_T("diffuse texture shader"));
		m_TextureShader.Upload();
		
		//Create Screen Quad
		VertexBuffer.DataChannels[1] Channels;
    Channels[0] = VertexBuffer.DataChannels.POSITION;
		m_ScreenQuad = New!VertexBuffer(this,Channels,VertexBuffer.Primitive.QUADS,VertexBuffer.IndexBufferSize.INDEX16,false);
		m_ScreenQuad.AddVertexData(vec3(-1.0f,-1.0f,0.5f));
		m_ScreenQuad.AddVertexData(vec3( 1.0f,-1.0f,0.5f));
		m_ScreenQuad.AddVertexData(vec3( 1.0f, 1.0f,0.5f));
		m_ScreenQuad.AddVertexData(vec3(-1.0f, 1.0f,0.5f));
		m_ScreenQuad.UploadData();
		
		m_LastTime = Zeitpunkt(cast(shared(Timer))m_Timer);
		m_CurrentTime = m_LastTime;
		m_LastFrameCount = m_LastTime;
		
		m_GeometryState.SetDepthTest(true);
		
		//architecture setup
		SetRenderSliceNum(2);
		
		m_DebugState = New!StateObject();
		m_DebugState.SetDepthTest(true);
		
    VertexBuffer.DataChannels[2] DebugBufferDataChannels;
    DebugBufferDataChannels[0] = VertexBuffer.DataChannels.POSITION;
    DebugBufferDataChannels[1] = VertexBuffer.DataChannels.COLOR;
		m_DebugBuffer = New!VertexBuffer(this,
										 DebugBufferDataChannels,
										 VertexBuffer.Primitive.LINES,
										 VertexBuffer.IndexBufferSize.INDEX16,
										 true);
		
		m_SpriteState = New!StateObject();
		m_SpriteState.SetDepthTest(true);
		m_SpriteState.SetDepthWrite(false);
		m_SpriteState.SetBlending(true);
		m_SpriteState.SetBlendFunc(StateObject.Blending.ONE,StateObject.Blending.ONE);
		m_SpriteState.SetCullFace(StateObject.Cull.NONE);
		
    VertexBuffer.DataChannels[4] SpriteBufferDataChannels;
    SpriteBufferDataChannels[0] = VertexBuffer.DataChannels.POSITION;
    SpriteBufferDataChannels[1] = VertexBuffer.DataChannels.COLOR;
    SpriteBufferDataChannels[2] = VertexBuffer.DataChannels.TEXCOORD0;
    SpriteBufferDataChannels[3] = VertexBuffer.DataChannels.UNFOLDING;
		m_SpriteBuffer = New!VertexBuffer(this,
										  SpriteBufferDataChannels,
										  VertexBuffer.Primitive.QUADS,
										  VertexBuffer.IndexBufferSize.INDEX16,
										  true);
		
		m_AlphaSpriteState = New!StateObject();
		m_AlphaSpriteState.SetDepthTest(true);
		m_AlphaSpriteState.SetDepthWrite(false);
		m_AlphaSpriteState.SetBlending(true);
		m_AlphaSpriteState.SetCullFace(StateObject.Cull.NONE);
		m_AlphaSpriteState.SetBlendFunc(StateObject.Blending.SRC_ALPHA,StateObject.Blending.ONE_MINUS_SRC_ALPHA);
		
    VertexBuffer.DataChannels[4] AlphaSpriteBufferDataChannels;
    AlphaSpriteBufferDataChannels[0] = VertexBuffer.DataChannels.POSITION;
    AlphaSpriteBufferDataChannels[1] = VertexBuffer.DataChannels.COLOR;
    AlphaSpriteBufferDataChannels[2] = VertexBuffer.DataChannels.TEXCOORD0;
    AlphaSpriteBufferDataChannels[3] = VertexBuffer.DataChannels.UNFOLDING;
		m_AlphaSpriteBuffer = New!VertexBuffer(this,
											  AlphaSpriteBufferDataChannels,
												VertexBuffer.Primitive.QUADS,
												VertexBuffer.IndexBufferSize.INDEX16,
												true);
		
		m_AssetLoader = New!AssetLoader(this);
		
		//initialize hud stuff
    VertexBuffer.DataChannels[2] ShapeBufferDataChannels;
    ShapeBufferDataChannels[0] = VertexBuffer.DataChannels.POSITION_2;
    ShapeBufferDataChannels[1] = VertexBuffer.DataChannels.COLOR;
		m_ShapeBuffer = New!VertexBuffer(this,
										 ShapeBufferDataChannels,
										 VertexBuffer.Primitive.TRIANGLES,
										 VertexBuffer.IndexBufferSize.INDEX16,
										 true);
		m_ShapeBuffer.AddIndexBuffer();
		
		m_ShapeShader = New!XmlShader(m_ShaderConstants);
		m_ShapeShader.Load(_T("shader/shape.xml"));
		m_ShapeShader.Upload();
		
		m_HudState = New!StateObject();
		m_HudState.SetDepthTest(false);
		m_HudState.SetBlending(true);
		m_HudState.SetBlendFunc(StateObject.Blending.SRC_ALPHA, StateObject.Blending.ONE_MINUS_SRC_ALPHA);
		m_HudState.SetCullFace(StateObject.Cull.NONE);
		
    {
      Rendertarget.TargetPart[1] Parts;
      Parts[0] = Rendertarget.TargetPart(Rendertarget.Name.COLOR_BUFFER, ImageFormat.RGBA8);
		  m_HudRendertarget =  New!Rendertarget(this, this.GetWidth(), this.GetHeight(), Parts);
		  if(m_HudRendertarget.Error().length > 0){
			  throw New!RCException(m_HudRendertarget.Error());
		  }
    }
		
    {
      Rendertarget.TargetPart[1] Parts;
      Parts[0] = Rendertarget.TargetPart(Rendertarget.Name.DEPTH_BUFFER_TEXTURE, ImageFormat.DEPTH24);
		  m_ShadowMap = New!Rendertarget(this, 4096, 4096, Parts);
		  if(m_ShadowMap.Error().length > 0){
			  throw New!RCException(m_ShadowMap.Error());
		  }
    }

    m_HudMaterial = New!Material();
		m_HudMaterial.SetShader(m_Hud3dShader.GetShader());
		m_HudMaterial.SetTexture(m_HudRendertarget.GetColorTexture(0),0);
		
		base.profiler.Init("Renderer");
	}
	
	override void Deinit(){
    Delete(m_ShadowMap); m_ShadowMap = null;
    Delete(m_HudRendertarget); m_HudRendertarget = null;
    Delete(m_HudState); m_HudState = null;
    Delete(m_ShapeShader); m_ShapeShader = null;
    Delete(m_ShapeBuffer); m_ShapeBuffer = null;
    Delete(m_AssetLoader); m_AssetLoader = null;
    Delete(m_AlphaSpriteBuffer); m_AlphaSpriteBuffer = null;
    Delete(m_AlphaSpriteState); m_AlphaSpriteState = null;
    Delete(m_SpriteBuffer); m_SpriteBuffer = null;
    Delete(m_SpriteState); m_SpriteState = null;
    Delete(m_DebugBuffer); m_DebugBuffer = null;
    Delete(m_DebugState); m_DebugState = null;
    Delete(m_ScreenQuad); m_ScreenQuad = null;
    Delete(m_Hud3dShader); m_Hud3dShader = null;
    Delete(m_SpriteShader); m_SpriteShader = null;
    Delete(m_LinesShader); m_LinesShader = null;
    Delete(m_ScreenFillShader); m_ScreenFillShader = null;
    Delete(m_FontShader); m_FontShader = null;
    Delete(m_FontBuffer); m_FontBuffer = null;
    Delete(m_FontState); m_FontState = null;
    Delete(m_EngineFont); m_EngineFont = null;
    Delete(m_DefaultState); m_DefaultState = null;

    Delete(m_FontColor);
    Delete(m_ProjectionMatrix); m_ProjectionMatrix = null;
    Delete(m_ViewMatrix); m_ViewMatrix = null;
    Delete(m_InverseViewMatrix); m_InverseViewMatrix = null;
    Delete(m_InverseProjectionMatrix); m_InverseProjectionMatrix = null;
    Delete(m_ModelMatrix); m_ModelMatrix = null;
    Delete(m_ModelViewMatrix); m_ModelViewMatrix = null;
    Delete(m_NormalMatrix); m_NormalMatrix = null;
    Delete(m_ModelMatrixInverseTransposed); m_ModelMatrixInverseTransposed = null;
    Delete(m_TextureShader); m_TextureShader = null;
    Delete(m_HudMaterial); m_HudMaterial = null;

    foreach(slice; m_RenderSlices[])
    {
      Delete(slice);
    }
    m_RenderSlices.resize(0);

    foreach(tex; m_DownloadTextures[])
    {
      Delete(tex);
    }
    m_DownloadTextures.resize(0);

    Font.DeleteFonts();
	}

  override IRendererExtractor GetExtractor() shared
  {
    //TODO make shared correct
    return cast(IRendererExtractor)m_Extractor;
  }
	
	override void Work(){
		auto rootProfile = base.profiler.ProfileRoot(base.profiler.GetProfiler());
		synchronized(this){
      m_FrameAllocator = GetNewTemporaryAllocator();
      scope(exit)
      {
        Delete(m_FrameAllocator);
        m_FrameAllocator = null;
      }
			m_CurrentTime = Zeitpunkt(cast(shared(Timer))m_Timer);
			if(m_CurrentTime - m_LastFrameCount > 500.0f){
				m_FramesPerSecond = cast(float)m_Frame * (1000.0f / (m_CurrentTime - m_LastFrameCount));
				m_Frame = 0;
				m_LastFrameCount = m_CurrentTime;
			}
			m_ObjectsDrawn = 0;
			m_NumberOfRenderCalls = 0;
			m_NumberOfSprites = 0;
			m_NumberOfSpriteDrawCalls = 0;
			m_NumberOfShapeDrawCalls = 0;
			
			RenderSlice normalSlice = GetRenderSlice(0);
			m_DebugGroup = normalSlice.AddRenderGroup();
			
			RenderSlice overlaySlice = GetRenderSlice(1);
      m_Group2D = overlaySlice.AddRenderGroup();
			m_FontGroup = overlaySlice.AddRenderGroup();
			
			{
				//this stops other threads from sending new direct draw calls
				version(direct_draw){
					auto directDrawLock = MultipleLock(m_BatchThreads);
				}
				{
					auto profile = base.profiler.Profile("pre extract messages");
					ProgressLoadingMessages();
					ProgressMessagesPreExtract();
				}
				
				{
					auto profile = base.profiler.Profile("extraction");
					ReadExtractedData();
				}
				
				{
					auto profile = base.profiler.Profile("post extract messages");
					ProgressMessagesPostExtract();
				}
			}
			
			{ 
				auto profile = base.profiler.Profile("opengl");
				
				{
					auto profile2 = base.profiler.Profile("debug text");
					if(m_CVars.r_info > 0.0){
						DrawFormatText(m_EngineFont, vec2(m_Width - 80.0f,0.0f),vec4(1.0f,1.0f,1.0f,1.0f),
								 m_FontGroup,m_FontBuffer,
								 "FPS: %.1f\nSPS: %.1f",
								 m_FramesPerSecond, 
								 m_SimulationsPerSecond);
					}
					
					if(m_CVars.recordFrames > 0.0)
          {
            base.profiler.StartRecording(cast(size_t)m_CVars.recordFrames);
            m_CVars.recordFrames = 0.0;
          }
					if(m_CVars.profile > 0.0 && m_CVars.profile < 2.0){
						base.profiler.Print(this);
					}
          else if(m_CVars.profile >= 2.0)
          {
            base.profiler.DrawRecorded(this);
          }
					
					if(queryNeeded && m_CVars.r_info > 1.0){
						AlignedBox box = queryBox;
						vec3 boxMin = queryBox.min - Position(vec3(0,0,0));
						vec3 boxMax = queryBox.max - Position(vec3(0,0,0));
						vec3 org = m_FrameOrigin - Position(vec3(0,0,0));
						vec3 pos = m_Camera.position - Position(vec3(0,0,0));
						DrawFormatText(m_EngineFont, vec2(20.0f,0.0f),vec4(1.0f,1.0f,1.0f,1.0f),
								 m_FontGroup,m_FontBuffer,
								 "Query min: %f %f %f\nQuery max: %f %f %f\nPosition: %f %f %f\nOrigin: %f %f %f\nObjects drawn: %d\nDraw Calls: %d\nSprites: %d\nSprite Draw Calls: %d\n Shape Draw Calls: %d\nVertex Buffer Memory %s kb\nTexture Memory %s kb",
									boxMin.x,boxMin.y,boxMin.z,
									boxMax.x,boxMax.y,boxMax.z,
									pos.x,pos.y,pos.z,
									org.x,org.y,org.z,
									m_ObjectsDrawn,
									m_NumberOfRenderCalls,
									m_NumberOfSprites,
									m_NumberOfSpriteDrawCalls,
									m_NumberOfShapeDrawCalls,
									m_VertexBufferMemoryAmount / 1024,
									m_TextureMemoryAmount / 1024 );
					}
				}
				
				if(m_CameraFreezed){
					vec4 color = vec4(0.0f,1.0f,1.0f,1.0f);
					this.drawBox(m_FreezedQueryBox,color);
				}
				
				if(m_UpdateDebugBuffer){
					RenderCall call = m_DebugGroup.AddRenderCall();
					call.SetVertexBuffer(m_DebugBuffer);
					call.SetShader(m_LinesShader.GetShader());
					call.SetStateObject(m_DebugState);
				}
				
				RenderSlice LastPostProcessing = null;
				m_PostProcessingSwitch = false;
				m_DataHoldingRendertarget = m_MainRendertarget;
				foreach(slice;m_RenderSlices.GetRange()){
					if(slice.GetPostProcessing() && slice.GetActive())
						LastPostProcessing = slice;
				}
				if(LastPostProcessing !is null){
					LastPostProcessing.SetLastPostProcessing();
					m_PostProcessing = true;
				}
				else
					m_PostProcessing = false;
				
				//Clear Framebuffer
				Clear(true,true,true);
				Rendertarget.ClearAll();
				
				//Add the font buffer to be updated
				if(m_UpdateFontBuffer){
					m_VertexBufferManager.AddVertexBufferToUpdate(m_FontBuffer);
					m_UpdateFontBuffer = false;
				}
				if(m_UpdateDebugBuffer){
					m_VertexBufferManager.AddVertexBufferToUpdate(m_DebugBuffer);
					m_UpdateDebugBuffer = false;
				}
				if(m_UpdateShapeBuffer){
					m_VertexBufferManager.AddVertexBufferToUpdate(m_ShapeBuffer);
					m_UpdateShapeBuffer = false;
				}
				if(m_UpdateSpriteBuffer){
					m_VertexBufferManager.AddVertexBufferToUpdate(m_SpriteBuffer);
					m_UpdateSpriteBuffer = false;
				}
				if(m_UpdateAlphaSpriteBuffer){
					m_VertexBufferManager.AddVertexBufferToUpdate(m_AlphaSpriteBuffer);
					m_UpdateAlphaSpriteBuffer = false;
				}
				
				
				//Upload new data
				{
					auto profile2 = base.profiler.Profile("vb update");
					m_VertexBufferManager.UpdateVertexBuffers();
				}
				
				gl.ActiveTexture(gl.TEXTURE0);
				gl.BindTexture(gl.TEXTURE_2D,0);
				gl.ActiveTexture(gl.TEXTURE1);
				gl.BindTexture(gl.TEXTURE_2D,0);
				
				if(m_IsVisible){
					auto profile2 = base.profiler.Profile("draw calls");
					foreach(slice;m_RenderSlices.GetRange()){
						slice.Use();
					}
				}
				else {
					double TimeDiff = m_CurrentTime - m_LastTime;
					//Aim for 30Fps while minimized
					int wait = cast(int)(1000.0 / 30.0 - TimeDiff);
					if(wait > 0)
						Thread.getThis().sleep(dur!("msecs")(wait));
				}
				
				//Download Textures
				foreach(texture;m_DownloadTextures.GetRange()){
					texture.DownloadImageData();
				}
				m_DownloadTextures.resize(0);
				
				//Reset Stuff
				{
					auto profile2 = base.profiler.Profile("reset");
					{
						auto profile3 = base.profiler.Profile("slices");
						foreach(slice;m_RenderSlices.GetRange()){
							slice.Reset();
						}
					}
					
					if(VertexBuffer.GetActiveVertexBuffer() !is null){
						auto profile3 = base.profiler.Profile("vb");
						VertexBuffer.GetActiveVertexBuffer().End();
					}
					//RenderCall.FreeInstances();
					{
						auto profile3 = base.profiler.Profile("shader");
						Shader.UnloadCurrentShader();
					}
					
					//writefln("%d %d",m_FontBuffer.GetDataSize(),m_DebugBuffer.GetDataSize());
					
					//Reset font buffer
					{
						auto profile3 = base.profiler.Profile("reset vbs");
						m_FontBuffer.FreeLocalData();
						m_DebugBuffer.FreeLocalData();
						m_ShapeBuffer.FreeLocalData();
						m_ShapeBuffer.AddIndexBuffer();
						m_SpriteBuffer.FreeLocalData();
						m_AlphaSpriteBuffer.FreeLocalData();
					}
				}
			}
			
			{
				auto profile = base.profiler.Profile("swap buffers");
			
				//Swap the buffers
				SDL.GL.SwapBuffers();
				//Clean up opengl errors
				debug {
					gl.GetError();
				}
				m_Frame++;
			}
			
			{
				auto profile = base.profiler.Profile("GC");
				core.memory.GC.collect();
			}
			
			m_LastTime = m_CurrentTime;
		}
	}
	
	private struct Params {
		vec3 lightDir;
		vec4 ambientColor;
		vec4 lightColor;
		XmlValue!float specularPower;
		vec2 shadowOffset;
		XmlValue!float shadowMaxDistance;
	}
	
	void InitShaderConstants(){		
		// Shader constant for light position
		m_LightPosConstant = new ShaderConstantSimpleType!vec3();
		RegisterShaderConstant(_T("LightPos"),m_LightPosConstant);
		m_LightPosConstant.Set(vec3(1000,1000,1000));
		
		// Shader constant for light direction
		m_LightDirConstant = new ShaderConstantSimpleType!vec3();
		RegisterShaderConstant(_T("LightDir"),m_LightDirConstant);
		m_LightDir = vec3(2,1,4).normalize();
		m_LightDirConstant.Set(m_LightDir);
		
		// shader constant for ambient color
		m_AmbientColorConstant = new ShaderConstantSimpleType!vec4();
		RegisterShaderConstant(_T("AmbientColor"),m_AmbientColorConstant);
		m_AmbientColorConstant.Set(vec4(0.3f,0.3f,0.3f,0.0f));
		
		// shader constant for light color
		m_LightColorConstant = new ShaderConstantSimpleType!vec4();
		RegisterShaderConstant(_T("LightColor"),m_LightColorConstant);
		m_LightColorConstant.Set(vec4(1.0f,1.0f,1.0f,1.0f));
		
		// shader constant for light specular power
		m_SpecularPowerConstant = new ShaderConstantSimpleType!float();
		RegisterShaderConstant(_T("SpecularPower"),m_SpecularPowerConstant);
		m_SpecularPowerConstant.Set(16.0f);
		
		// shader constant for shadow map offset
		m_ShadowOffsetConstant = new ShaderConstantSimpleType!vec2();
		RegisterShaderConstant(_T("ShadowOffset"),m_ShadowOffsetConstant);
		m_ShadowOffsetConstant.Set(vec2(0.0001,0.0001));
		
		// Shader constant for matrix used to reverse the light world transformation
		m_LightMatrixConstant = new ShaderConstantSimpleType!mat4();
		RegisterShaderConstant(_T("LightMatrix"),m_LightMatrixConstant);
		
		// Shader constant for maximum shadow display distance
		m_ShadowMaxDistanceConstant = new ShaderConstantSimpleType!float();
		RegisterShaderConstant(_T("ShadowMaxDistance"),m_ShadowMaxDistanceConstant);
		m_ShadowMaxDistanceConstant.Set(1500.0f);
		
		// create main camera
		Camera cam = New!CameraProjection(cast(float)this.GetWidth(),cast(float)this.GetHeight(),1.0f,1000.0f,45.0f);
    scope(exit) Delete(cam);
		cam.SetFrom(vec4(100,100,100,1));
		cam.SetTo(0,0,0);
		cam.Recalc();
		mat4 camMatrix = cam.GetCameraMatrix();
		m_ViewMatrix.Set(TranslationMatrix(0,0,-100));
		mat4 projMatrix = cam.GetProjectionMatrix();
		m_ProjectionMatrix.Set(projMatrix);
	}
	
	override void loadAmbientSettings(rcstring path) shared {
		m_LoadingMessageQueue.enqueue(MsgLoadAmbientSettings(path));
	}
	
	private void doLoadAmbientSettings(rcstring path){
		Params params;
		FromXmlFile(params, path);
		
		m_LightDir = params.lightDir.normalize();
		m_LightDirConstant.Set(m_LightDir);
		
		m_AmbientColorConstant.Set(params.ambientColor);
		
		m_LightColorConstant.Set(params.lightColor);
		
		m_SpecularPowerConstant.Set(params.specularPower.value);
		
		m_ShadowOffsetConstant.Set(params.shadowOffset);
		
		m_ShadowMaxDistanceConstant.Set(params.shadowMaxDistance.value);
	}
	
	private uint ProgressLoadingMessages(){
		uint numMessages = 0;
    while(true)
    {
      BaseMessage* bmsg = m_LoadingMessageQueue.tryGet!BaseMessage();
      if(bmsg is null)
        break;
      if(bmsg.type == typeid(MsgLoadModel))
      {
        auto msg = m_LoadingMessageQueue.tryGet!MsgLoadModel();
        assert(msg !is null);
        scope(exit) m_LoadingMessageQueue.skip!MsgLoadModel();
        debug base.logger.info("Loading model '%s'", msg.path[]);
        try {
          IModel model = m_AssetLoader.DoLoadModel(msg.path);
          msg.answerQueue.enqueue(MsgLoadingModelDone(model));
        }
        catch(Throwable e){
          msg.answerQueue.enqueue(MsgLoadingModelDone(null));
          throw e;
        }
      }
      else if(bmsg.type == typeid(MsgLoadCubeMap))
      {
        auto msg = m_LoadingMessageQueue.tryGet!MsgLoadCubeMap();
        assert(msg !is null);
        scope(exit) m_LoadingMessageQueue.skip!MsgLoadCubeMap();
        debug base.logger.info("loading cube map '%s'", msg.path[]);
        try {
          ITexture texture = 
            m_AssetLoader.DoLoadCubeMap(msg.path);
          msg.answerQueue.enqueue(MsgLoadingCubeMapDone(texture));
        }
        catch(Throwable e){
          msg.answerQueue.enqueue(MsgLoadingCubeMapDone(null));
          throw e;
        }
      }
      else if(bmsg.type == typeid(MsgLoadSpriteAtlas))
      {
        auto msg = m_LoadingMessageQueue.tryGet!MsgLoadSpriteAtlas();
        assert(msg !is null);
        scope(exit) m_LoadingMessageQueue.skip!MsgLoadSpriteAtlas();
        debug base.logger.info("Loading sprite atlas '%s'", msg.path[]);
        try {
          ISpriteAtlas atlas =
            m_AssetLoader.DoLoadSpriteAtlas(msg.path);
          msg.answerQueue.enqueue(MsgLoadingSpriteAtlasDone(atlas));
        }
        catch(Throwable e){
          msg.answerQueue.enqueue(MsgLoadingSpriteAtlasDone(null));
          throw e;
        }
      }
      else if(bmsg.type == typeid(MsgLoadAmbientSettings))
      {
        auto amsg = m_LoadingMessageQueue.tryGet!MsgLoadAmbientSettings();
        assert(amsg !is null && (cast(void*)amsg == cast(void*)bmsg));
        scope(exit) m_LoadingMessageQueue.skip!MsgLoadAmbientSettings();
        debug base.logger.info("Loading ambient settings '%s'", amsg.path[]);
        doLoadAmbientSettings(amsg.path);
      }
      else if(bmsg.type == typeid(MsgSetup3DHudGeom))
      {
        auto msg = m_LoadingMessageQueue.tryGet!MsgSetup3DHudGeom();
        assert(msg !is null);
        scope(exit) m_LoadingMessageQueue.skip!MsgSetup3DHudGeom();
        debug base.logger.info("Creating render proxy %x", msg.model);
        try {
          doCreateRenderProxy3DHud(msg.model);
          msg.answerQueue.enqueue(MsgSetup3DHudGeomDone(true));
        }
        catch(Throwable e){
          msg.answerQueue.enqueue(MsgSetup3DHudGeomDone(false));
          throw e;
        }
      }
      else
      {
        assert(0, "non loading message found");
      }
      numMessages++;
    }
    return numMessages;
	}
	
	private void ProgressMessagesPreExtract(){
		int numMessages = 0;
    while(true)
    {
      BaseMessage* bmsg = m_PreExtractMessageQueue.tryGet!BaseMessage();
      if(bmsg is null)
        break;
      if(bmsg.type == typeid(MsgCamera))
      {
        auto msg = m_PreExtractMessageQueue.tryGet!MsgCamera();
        assert(msg !is null);
        scope(exit) m_PreExtractMessageQueue.skip!MsgCamera();
        this.camera(cast(IGameObject)msg.obj);
      }
      else if(bmsg.type == typeid(MsgSetSPS))
      {
        auto msg = m_PreExtractMessageQueue.tryGet!MsgSetSPS();
        assert(msg !is null);
        scope(exit) m_PreExtractMessageQueue.skip!MsgSetSPS();
        m_SimulationsPerSecond = msg.sps;
      }
      else
      {
        assert(0, "Non pre extract message");
      }
      numMessages++;
    }
		//writefln("recieved %d pre messages",numMessages);
	}
	
	private void ProgressMessagesPostExtract(){
		int numMessages = 0;
		int unkownMessages = 0;
    while(true)
    {
      BaseMessage* bmsg = m_MessageQueue.tryGet!BaseMessage();
      if(bmsg is null)
        break;
      if(bmsg.type == typeid(Msg_t!(Renderer, "drawBox")))
      {
        auto msg = m_MessageQueue.tryGet!(Msg_t!(Renderer, "drawBox"))();
        assert(msg !is null);
        scope(exit) m_MessageQueue.skip!(Msg_t!(Renderer, "drawBox"))();
        msg.call(this);
      }
      else if(bmsg.type == typeid(Msg_t!(Renderer, "drawLine")))
      {
        auto msg = m_MessageQueue.tryGet!(Msg_t!(Renderer, "drawLine"))();
        assert(msg !is null);
        scope(exit) m_MessageQueue.skip!(Msg_t!(Renderer, "drawLine"))();
        msg.call(this);
      }
      else
      {
        assert(0, "unkown post extract message");
      }
      numMessages++;
    }				
	}
	
	private void CreateSpriteDrawCall(RenderGroup spriteGroup){
		auto call = spriteGroup.AddRenderCall();
		call.SetVertexBuffer(m_SpriteBuffer);
		call.SetRange(m_LastSpriteVertex,m_SpriteBuffer.GetVerticesInBuffer()-m_LastSpriteVertex);
		call.SetShader(m_SpriteShader.GetShader());
		call.SetStateObject(m_SpriteState);
		call.AddTexture(m_SpriteAtlases[m_LastSpriteAtlas].texture, 0);
		m_NumberOfSpriteDrawCalls++;
	}
	
	private void CreateAlphaSpriteDrawCall(RenderGroup spriteGroup){
		auto call = spriteGroup.AddRenderCall();
		call.SetVertexBuffer(m_AlphaSpriteBuffer);
		call.SetRange(m_LastAlphaSpriteVertex,m_AlphaSpriteBuffer.GetVerticesInBuffer()-m_LastAlphaSpriteVertex);
		call.SetShader(m_SpriteShader.GetShader());
		call.SetStateObject(m_AlphaSpriteState);
		call.AddTexture(m_SpriteAtlases[m_LastAlphaSpriteAtlas].texture, 0);
		m_NumberOfSpriteDrawCalls++;
	}
	
	private void ReadExtractedData(){
		while(true){
			auto buffer = GetExtractorBuffer!(RendererExtractor)(m_Extractor);
			
			//if we did not get any extracted data, we might have a deadlock
			//because of the game waiting for a resource to be loaded
			if(!buffer.success){
        if(!m_Extractor.isRunning)
          break;
				ProgressLoadingMessages();
				continue;
			}
			
			ObjectInfo* data = buffer.buffer;
			vec3 shadowMin = vec3(float.max);
			vec3 shadowMax = vec3(-float.max);
			vec3 camPos;
			
			auto slice0 = GetRenderSlice(0);
			auto shadowGroup = slice0.AddRenderGroup();
			shadowGroup.SetRendertarget(m_ShadowMap);
			auto mainGroup = slice0.AddRenderGroup();
			auto alphaSpriteGroup = slice0.AddRenderGroup();
			auto spriteGroup = slice0.AddRenderGroup();
			auto hud3dGeomGroup = slice0.AddRenderGroup();
			auto hud3dGroup = slice0.AddRenderGroup();
			hud3dGroup.SetRendertarget(m_HudRendertarget);
			auto hudGroup = slice0.AddRenderGroup();
			
			for(ObjectInfo* cur = data;cur !is null; cur = cur.next){
				final switch(cast(ExtractType)cur.type){
					case ExtractType.INVALID:
						assert(0,"invalid extraction information");
					case ExtractType.MODEL:
						{
							ObjectInfoModel* info = cast(ObjectInfoModel*)cur;
							info.model.Draw(info.transformation,shadowGroup,m_GeometryState,0);
							info.model.Draw(info.transformation,mainGroup,m_GeometryState,1);
							m_ObjectsDrawn++;
							/*vec3 pos = vec3(info.transformation.f[12],
											info.transformation.f[13],
											info.transformation.f[14]);
							shadowMin = min(shadowMin,pos);
							shadowMax = max(shadowMax,pos);*/
						}
						break;
					case ExtractType.HUD3D_MODEL:
						{
							ObjectInfo3DHud* hudinfo = cast(ObjectInfo3DHud*)cur;
							hudinfo.model.Draw(hudinfo.transformation,hud3dGeomGroup,m_AlphaSpriteState,1);
							hudinfo.model.Draw(hudinfo.transformation,hud3dGeomGroup,m_SpriteState,2);
						}
						break;
					case ExtractType.PARTICLE_SYSTEM:
						assert(0,"not implemented yet");
					case ExtractType.CAMERA:
						{
							//writefln("extracting camera");
							ObjectInfoCamera* info = cast(ObjectInfoCamera*)cur;
							m_ViewMatrix.Set(info.viewMatrix);
							mat4 invView = info.viewMatrix.Inverse();
							camPos = vec3(invView.f[12],
										  invView.f[13],
										  invView.f[14]);
							m_ProjectionMatrix.Set(info.projMatrix);
							m_FrameOrigin = info.origin;
							vec4 lightDir = info.viewMatrix * vec4(m_LightDir,0.0f);
							m_LightDirConstant.Set(vec3(lightDir));
						}
						break;
					case ExtractType.TEXT:
						{
							ObjectInfoText* info = cast(ObjectInfoText*)cur;
							auto group = (info.target == HudTarget.SCREEN) ? hudGroup : hud3dGroup;
							DrawText(Font.GetFont(info.font), info.pos, info.color, group, m_FontBuffer, info.text[]);
              //TODO fix as soon as sturct.init does not allocate
              rcstring init;
              info.text = init;
						}
						break;
					case ExtractType.SHAPE:
						{
							ObjectInfoShape* info = cast(ObjectInfoShape*)cur;
							
							size_t start = m_ShapeBuffer.GetVerticesInBuffer();
							foreach(vert;info.vertices){
								m_ShapeBuffer.AddVertexData(vert);
								m_ShapeBuffer.AddVertexData(info.color);
							}
							size_t end = m_ShapeBuffer.GetVerticesInBuffer();
							if(end - start >= 3){
								int swap = 0;
								uint indexStart = m_ShapeBuffer.GetNumberOfIndicies(0);
								for(size_t i=0;i< end - start - 2;i++){
									m_ShapeBuffer.AddIndexData(0,i + start);
									m_ShapeBuffer.AddIndexData(0,i+1 + swap + start);
									m_ShapeBuffer.AddIndexData(0,i+2 - swap + start);
									swap = (swap + 1) % 2;
								}
								uint indexEnd = m_ShapeBuffer.GetNumberOfIndicies(0);
								
								m_UpdateShapeBuffer = true;
								
								auto group = (info.target == HudTarget.SCREEN) ? hudGroup : hud3dGroup;
								auto call = group.AddRenderCall();
								call.SetVertexBuffer(m_ShapeBuffer);
								call.SetShader(m_ShapeShader.GetShader());
								call.SetStateObject(m_HudState);
								call.SetRange(indexStart,indexEnd-indexStart);
								m_NumberOfShapeDrawCalls++;
							}
						}
						break;
					case ExtractType.TEXTURED_SHAPE:
						assert(0,"not implemented");
					case ExtractType.SKYBOX:
						{
							ObjectInfoSkyBox* info = cast(ObjectInfoSkyBox*)cur;
							auto call = mainGroup.AddRenderCall();
							call.SetVertexBuffer(m_ScreenQuad);
							call.SetShader(m_AssetLoader.m_SkyBoxShader.GetShader());
							call.SetStateObject(m_GeometryState);
						}
						break;
					case ExtractType.SPRITE:
						{
							m_NumberOfSprites++;
							ObjectInfoSprite* spriteInfo = cast(ObjectInfoSprite*)cur;
							if(spriteInfo.blending == ObjectInfoSprite.Blending.ADDITIVE){
								if(!m_UpdateSpriteBuffer){
									m_LastSpriteAtlas = spriteInfo.sprite.atlas;
									m_LastSpriteVertex = 0;
									m_UpdateSpriteBuffer = true;
								}
								if(spriteInfo.sprite.atlas != m_LastSpriteAtlas){
									CreateSpriteDrawCall(spriteGroup);
									
									m_LastSpriteVertex = m_SpriteBuffer.GetVerticesInBuffer();
									m_LastSpriteAtlas = spriteInfo.sprite.atlas;
								}
								
								vec2 size = spriteInfo.size / 2.0f;
								
								m_SpriteBuffer.AddVertexData(spriteInfo.position);
								m_SpriteBuffer.AddVertexData(spriteInfo.color);
								m_SpriteBuffer.AddVertexData(spriteInfo.sprite.offset);
								m_SpriteBuffer.AddVertexData(vec2(-size.x,-size.y));
								
								m_SpriteBuffer.AddVertexData(spriteInfo.position);
								m_SpriteBuffer.AddVertexData(spriteInfo.color);
								m_SpriteBuffer.AddVertexData(spriteInfo.sprite.offset + vec2(spriteInfo.sprite.size.x,0));
								m_SpriteBuffer.AddVertexData(vec2(size.x,-size.y));
								
								m_SpriteBuffer.AddVertexData(spriteInfo.position);
								m_SpriteBuffer.AddVertexData(spriteInfo.color);
								m_SpriteBuffer.AddVertexData(spriteInfo.sprite.offset + spriteInfo.sprite.size);
								m_SpriteBuffer.AddVertexData(vec2(size.x,size.y));
								
								m_SpriteBuffer.AddVertexData(spriteInfo.position);
								m_SpriteBuffer.AddVertexData(spriteInfo.color);
								m_SpriteBuffer.AddVertexData(spriteInfo.sprite.offset + vec2(0,spriteInfo.sprite.size.y));
								m_SpriteBuffer.AddVertexData(vec2(-size.x,size.y));
							}
							else {
								if(!m_UpdateAlphaSpriteBuffer){
									m_LastAlphaSpriteAtlas = spriteInfo.sprite.atlas;
									m_LastAlphaSpriteVertex = 0;
									m_UpdateAlphaSpriteBuffer = true;
								}
								if(spriteInfo.sprite.atlas != m_LastAlphaSpriteAtlas){
									CreateAlphaSpriteDrawCall(alphaSpriteGroup);
									
									m_LastAlphaSpriteVertex = m_SpriteBuffer.GetVerticesInBuffer();
									m_LastAlphaSpriteAtlas = spriteInfo.sprite.atlas;
								}
								
								vec2 size = spriteInfo.size / 2.0f;
								
								m_AlphaSpriteBuffer.AddVertexData(spriteInfo.position);
								m_AlphaSpriteBuffer.AddVertexData(spriteInfo.color);
								m_AlphaSpriteBuffer.AddVertexData(spriteInfo.sprite.offset);
								m_AlphaSpriteBuffer.AddVertexData(vec2(-size.x,-size.y));
								
								m_AlphaSpriteBuffer.AddVertexData(spriteInfo.position);
								m_AlphaSpriteBuffer.AddVertexData(spriteInfo.color);
								m_AlphaSpriteBuffer.AddVertexData(spriteInfo.sprite.offset + vec2(spriteInfo.sprite.size.x,0));
								m_AlphaSpriteBuffer.AddVertexData(vec2(size.x,-size.y));
								
								m_AlphaSpriteBuffer.AddVertexData(spriteInfo.position);
								m_AlphaSpriteBuffer.AddVertexData(spriteInfo.color);
								m_AlphaSpriteBuffer.AddVertexData(spriteInfo.sprite.offset + spriteInfo.sprite.size);
								m_AlphaSpriteBuffer.AddVertexData(vec2(size.x,size.y));
								
								m_AlphaSpriteBuffer.AddVertexData(spriteInfo.position);
								m_AlphaSpriteBuffer.AddVertexData(spriteInfo.color);
								m_AlphaSpriteBuffer.AddVertexData(spriteInfo.sprite.offset + vec2(0,spriteInfo.sprite.size.y));
								m_AlphaSpriteBuffer.AddVertexData(vec2(-size.x,size.y));
							}
							
							
						}
						break;
					case ExtractType.ORIENTED_SPRITE:
						{
							ObjectInfoOrientedSprite *ospriteInfo = cast(ObjectInfoOrientedSprite*)cur;
							if(ospriteInfo.blending == ObjectInfoOrientedSprite.Blending.ADDITIVE){
								if(!m_UpdateSpriteBuffer){
									m_LastSpriteAtlas = ospriteInfo.sprite.atlas;
									m_LastSpriteVertex = 0;
									m_UpdateSpriteBuffer = true;
								}
								if(ospriteInfo.sprite.atlas != m_LastSpriteAtlas){
									CreateSpriteDrawCall(spriteGroup);
									
									m_LastSpriteVertex = m_SpriteBuffer.GetVerticesInBuffer();
									m_LastSpriteAtlas = ospriteInfo.sprite.atlas;
								}
								
								vec2 size = ospriteInfo.size / 2.0f;
								vec3 up = vec3(0.0f,0.0f,1.0f);
								if(up.dot(ospriteInfo.orientation) > 0.99){
									up = vec3(0.0f,1.0f,0.0f);
								}
								vec3 x = up.cross(ospriteInfo.orientation).normalize();
								vec3 y = x.cross(ospriteInfo.orientation).normalize();								
								
								m_SpriteBuffer.AddVertexData(ospriteInfo.position + (x * -size.x + y * -size.y));
								m_SpriteBuffer.AddVertexData(ospriteInfo.color);
								m_SpriteBuffer.AddVertexData(ospriteInfo.sprite.offset);
								m_SpriteBuffer.AddVertexData(vec2(0.0f,0.0f));
								
								m_SpriteBuffer.AddVertexData(ospriteInfo.position + (x * size.x + y * -size.y));
								m_SpriteBuffer.AddVertexData(ospriteInfo.color);
								m_SpriteBuffer.AddVertexData(ospriteInfo.sprite.offset + vec2(ospriteInfo.sprite.size.x,0));
								m_SpriteBuffer.AddVertexData(vec2(0.0f,0.0f));
								
								m_SpriteBuffer.AddVertexData(ospriteInfo.position + (x * size.x + y * size.y));
								m_SpriteBuffer.AddVertexData(ospriteInfo.color);
								m_SpriteBuffer.AddVertexData(ospriteInfo.sprite.offset + ospriteInfo.sprite.size);
								m_SpriteBuffer.AddVertexData(vec2(0.0f,0.0f));
								
								m_SpriteBuffer.AddVertexData(ospriteInfo.position + (x * -size.x + y * size.y));
								m_SpriteBuffer.AddVertexData(ospriteInfo.color);
								m_SpriteBuffer.AddVertexData(ospriteInfo.sprite.offset + vec2(0,ospriteInfo.sprite.size.y));
								m_SpriteBuffer.AddVertexData(vec2(0.0f,0.0f));
							}
							else {
								if(!m_UpdateAlphaSpriteBuffer){
									m_LastAlphaSpriteAtlas = ospriteInfo.sprite.atlas;
									m_LastAlphaSpriteVertex = 0;
									m_UpdateAlphaSpriteBuffer = true;
								}
								if(ospriteInfo.sprite.atlas != m_LastAlphaSpriteAtlas){
									CreateAlphaSpriteDrawCall(alphaSpriteGroup);
									
									m_LastAlphaSpriteVertex = m_SpriteBuffer.GetVerticesInBuffer();
									m_LastAlphaSpriteAtlas = ospriteInfo.sprite.atlas;
								}
								
								vec2 size = ospriteInfo.size / 2.0f;
								vec3 up = vec3(0.0f,0.0f,1.0f);
								if(up.dot(ospriteInfo.orientation) > 0.99){
									up = vec3(0.0f,1.0f,0.0f);
								}
								vec3 x = up.cross(ospriteInfo.orientation).normalize();
								vec3 y = x.cross(ospriteInfo.orientation).normalize();								
								
								m_AlphaSpriteBuffer.AddVertexData(ospriteInfo.position + (x * -size.x + y * -size.y));
								m_AlphaSpriteBuffer.AddVertexData(ospriteInfo.color);
								m_AlphaSpriteBuffer.AddVertexData(ospriteInfo.sprite.offset);
								m_AlphaSpriteBuffer.AddVertexData(vec2(0.0f,0.0f));
								
								m_AlphaSpriteBuffer.AddVertexData(ospriteInfo.position + (x * size.x + y * -size.y));
								m_AlphaSpriteBuffer.AddVertexData(ospriteInfo.color);
								m_AlphaSpriteBuffer.AddVertexData(ospriteInfo.sprite.offset + vec2(ospriteInfo.sprite.size.x,0));
								m_AlphaSpriteBuffer.AddVertexData(vec2(0.0f,0.0f));
								
								m_AlphaSpriteBuffer.AddVertexData(ospriteInfo.position + (x * size.x + y * size.y));
								m_AlphaSpriteBuffer.AddVertexData(ospriteInfo.color);
								m_AlphaSpriteBuffer.AddVertexData(ospriteInfo.sprite.offset + ospriteInfo.sprite.size);
								m_AlphaSpriteBuffer.AddVertexData(vec2(0.0f,0.0f));
								
								m_AlphaSpriteBuffer.AddVertexData(ospriteInfo.position + (x * -size.x + y * size.y));
								m_AlphaSpriteBuffer.AddVertexData(ospriteInfo.color);
								m_AlphaSpriteBuffer.AddVertexData(ospriteInfo.sprite.offset + vec2(0,ospriteInfo.sprite.size.y));
								m_AlphaSpriteBuffer.AddVertexData(vec2(0.0f,0.0f));
							}
						}
						break;
					case ExtractType.FIXED_SPRITE:
						{
							VertexBuffer vb = null;
							ObjectInfoFixedSprite *fspriteInfo = cast(ObjectInfoFixedSprite*)cur;
							if(fspriteInfo.blending == ObjectInfoFixedSprite.Blending.ADDITIVE){
								vb = m_SpriteBuffer;
								if(!m_UpdateSpriteBuffer){
									m_LastSpriteAtlas = fspriteInfo.sprite.atlas;
									m_LastSpriteVertex = 0;
									m_UpdateSpriteBuffer = true;
								}
								if(fspriteInfo.sprite.atlas != m_LastSpriteAtlas){
									CreateSpriteDrawCall(spriteGroup);
									
									m_LastSpriteVertex = m_SpriteBuffer.GetVerticesInBuffer();
									m_LastSpriteAtlas = fspriteInfo.sprite.atlas;
								}
							}
							else {
								vb = m_AlphaSpriteBuffer;
								if(!m_UpdateAlphaSpriteBuffer){
									m_LastAlphaSpriteAtlas = fspriteInfo.sprite.atlas;
									m_LastAlphaSpriteVertex = 0;
									m_UpdateAlphaSpriteBuffer = true;
								}
								if(fspriteInfo.sprite.atlas != m_LastAlphaSpriteAtlas){
									CreateAlphaSpriteDrawCall(alphaSpriteGroup);
									
									m_LastAlphaSpriteVertex = m_SpriteBuffer.GetVerticesInBuffer();
									m_LastAlphaSpriteAtlas = fspriteInfo.sprite.atlas;
								}
							}							
							
							vb.AddVertexData(fspriteInfo.vertices[0]);
							vb.AddVertexData(fspriteInfo.color);
							vb.AddVertexData(fspriteInfo.sprite.offset);
							vb.AddVertexData(vec2(0.0f,0.0f));
							
							vb.AddVertexData(fspriteInfo.vertices[1]);
							vb.AddVertexData(fspriteInfo.color);
							vb.AddVertexData(fspriteInfo.sprite.offset + vec2(fspriteInfo.sprite.size.x,0));
							vb.AddVertexData(vec2(0.0f,0.0f));
							
							vb.AddVertexData(fspriteInfo.vertices[2]);
							vb.AddVertexData(fspriteInfo.color);
							vb.AddVertexData(fspriteInfo.sprite.offset + fspriteInfo.sprite.size);
							vb.AddVertexData(vec2(0.0f,0.0f));
							
							vb.AddVertexData(fspriteInfo.vertices[3]);
							vb.AddVertexData(fspriteInfo.color);
							vb.AddVertexData(fspriteInfo.sprite.offset + vec2(0,fspriteInfo.sprite.size.y));
							vb.AddVertexData(vec2(0.0f,0.0f));
							
						}
						break;
				}
			}
			
			//Create draw call for remaining sprites
			if(m_UpdateSpriteBuffer){
				CreateSpriteDrawCall(spriteGroup);
			}
			if(m_UpdateAlphaSpriteBuffer){
				CreateAlphaSpriteDrawCall(alphaSpriteGroup);
			}
			
			//shadowMin = shadowMin - vec3(50,50,50);
			//shadowMax = shadowMax + vec3(50,50,50);
			camPos = floor(camPos / 50.0f) * 50.0f;
			//base.logger.info("%s",camPos.f);
			float shadowSize = m_ShadowMaxDistanceConstant.Get() + 50.0f;
			shadowMin = vec3(-shadowSize,-shadowSize,-shadowSize);
			shadowMax = vec3(shadowSize,shadowSize,shadowSize);
			//drawBoxIntern(shadowMin + camPos,shadowMax + camPos,vec4(1.0f,0.0f,0.0f,1.0f));
			
			//Calculate Shadow mapping projection
			mat4 LightProjection = mat4.Ortho(shadowMin.x,shadowMax.x,
											  shadowMin.y,shadowMax.y,
											  shadowMin.z,shadowMax.z);
			mat4 LightView = mat4.LookAtMatrix(vec4(camPos + m_LightDir),vec4(camPos),vec4(0.0f,1.0f,0.0f,0.0f));
			shadowGroup.AddOverwrite(m_ViewMatrixConstant,LightView);
			shadowGroup.AddOverwrite(m_ProjectionMatrixConstant,LightProjection);
			
			//Calculate light matrix for shadowmapping
			mat4 LightMatrix = ScaleMatrix(0.5f,0.5f,0.5f) * TranslationMatrix(0.5f,0.5f,0.5f);
			LightMatrix = LightProjection * LightMatrix;
			LightMatrix = LightView * LightMatrix;
			LightMatrix = (m_ViewMatrix.Get().Inverse()) * LightMatrix;
			mainGroup.AddOverwrite(m_LightMatrixConstant,LightMatrix);
			
			m_NumberOfRenderCalls += mainGroup.numberOfRenderCalls;
			return;
		}
	}
	
	void AddTextureToDownload(Texture2D pTexture)
	in {
		assert(pTexture !is null,"pTexture may not be null");
	}
	body {
		m_DownloadTextures.push_back(pTexture);
	}
	
	override IRenderProxy CreateRenderProxy(shared(ISubModel) subModel) shared {
		return New!ModelProxy(cast(IDrawModel)subModel).ptr;
	}
	
	override IRenderProxy CreateRenderProxy() shared {
		return New!CameraProxy(New!CameraProjection(m_Width,m_Height,1.0f,10000.0f,45.0f)).ptr;
	}
	
	override IRenderProxy CreateRenderProxySkyBox(shared(ITexture) texture) shared {
		CubeTexture cube = cast(CubeTexture)texture;
		if(cube is null){
			throw New!Exception("texture needs to be a cube texture");
		}
		return New!SkyMapProxy(cube).ptr;
	}
	
	override IRenderProxy CreateRenderProxy3DHud(shared(IModel) model) shared {
		Model m = cast(Model)model;
    auto answerQueue = New!MessageQueue_t(1024);
    scope(exit) Delete(answerQueue);

    m_LoadingMessageQueue.enqueue(MsgSetup3DHudGeom(model, cast(shared(MessageQueue_t))answerQueue));

    BaseMessage *bmsg;
    while( (bmsg = answerQueue.tryGet!BaseMessage()) is null)
    {
      Thread.sleep(dur!("nsecs")(1));
    }
    assert(bmsg !is null);
    assert(bmsg.type == typeid(MsgSetup3DHudGeomDone));
    auto msg = cast(MsgSetup3DHudGeomDone*)bmsg;
    
	  if(!msg.success) 
      throw New!Exception("Creating 3d hud render proxy failed");
		
		return New!Hud3DProxy(m).ptr;
	}
	
	private void doCreateRenderProxy3DHud(shared(IModel) model){
		Model m = cast(Model)model;
		if(m.GetNumMaterials() > 1){
			throw New!RCException(format("3D Hud geometry '%s' should only have 1 material",m.fileName[]));
		}
		m.SetNumMaterialSets(3);
		Renderer self = cast(Renderer)this;
		m.SetMaterial(2, 0, m_HudMaterial);
		
		auto orgMat = m.GetMaterial(1,0);
		orgMat.SetShader(m_TextureShader.GetShader());
	}
	
	override void setSPS(float sps) shared {
		m_PreExtractMessageQueue.enqueue(MsgSetSPS(sps));
	}
	
	override void drawBox(ref const(AlignedBox) box, ref const(vec4) color) {
		m_UpdateDebugBuffer = true;
		vec3 min = box.min - m_FrameOrigin;
		vec3 max = box.max - m_FrameOrigin;
		vec3 size = max - min;
		
		m_DebugBuffer.AddVertexData(min); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(size.x,  0.0f, 0.0f)); m_DebugBuffer.AddVertexData(color); 
									
		m_DebugBuffer.AddVertexData(min + vec3(size.x,  0.0f, 0.0f)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(size.x,size.y, 0.0f)); m_DebugBuffer.AddVertexData(color);
		
		m_DebugBuffer.AddVertexData(min + vec3(size.x,size.y, 0.0f)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(  0.0f,size.y, 0.0f)); m_DebugBuffer.AddVertexData(color);
		
		m_DebugBuffer.AddVertexData(min + vec3(  0.0f,size.y, 0.0f)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min); m_DebugBuffer.AddVertexData(color);
		
		
		m_DebugBuffer.AddVertexData(min + vec3(  0.0f,  0.0f,size.z)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(size.x,  0.0f,size.z)); m_DebugBuffer.AddVertexData(color);
									
		m_DebugBuffer.AddVertexData(min + vec3(size.x,  0.0f,size.z)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(size.x,size.y,size.z)); m_DebugBuffer.AddVertexData(color);
		
		m_DebugBuffer.AddVertexData(min + vec3(size.x,size.y,size.z)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(  0.0f,size.y,size.z)); m_DebugBuffer.AddVertexData(color);
		
		m_DebugBuffer.AddVertexData(min + vec3(  0.0f,size.y,size.z)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(  0.0f,  0.0f,size.z)); m_DebugBuffer.AddVertexData(color);
		
		
		m_DebugBuffer.AddVertexData(min + vec3(  0.0f,  0.0f,  0.0f)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(  0.0f,  0.0f,size.z)); m_DebugBuffer.AddVertexData(color);
		
		m_DebugBuffer.AddVertexData(min + vec3(size.x,  0.0f,  0.0f)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(size.x,  0.0f,size.z)); m_DebugBuffer.AddVertexData(color);
		
		m_DebugBuffer.AddVertexData(min + vec3(size.x,size.y,  0.0f)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(size.x,size.y,size.z)); m_DebugBuffer.AddVertexData(color);
		
		m_DebugBuffer.AddVertexData(min + vec3(  0.0f,size.y,  0.0f)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(  0.0f,size.y,size.z)); m_DebugBuffer.AddVertexData(color);
	
	}
	
	void drawBoxIntern(vec3 min, vec3 max, ref const(vec4) color) {
		m_UpdateDebugBuffer = true;
		vec3 size = max - min;
		
		m_DebugBuffer.AddVertexData(min); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(size.x,  0.0f, 0.0f)); m_DebugBuffer.AddVertexData(color); 
									
		m_DebugBuffer.AddVertexData(min + vec3(size.x,  0.0f, 0.0f)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(size.x,size.y, 0.0f)); m_DebugBuffer.AddVertexData(color);
		
		m_DebugBuffer.AddVertexData(min + vec3(size.x,size.y, 0.0f)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(  0.0f,size.y, 0.0f)); m_DebugBuffer.AddVertexData(color);
		
		m_DebugBuffer.AddVertexData(min + vec3(  0.0f,size.y, 0.0f)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min); m_DebugBuffer.AddVertexData(color);
		
		
		m_DebugBuffer.AddVertexData(min + vec3(  0.0f,  0.0f,size.z)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(size.x,  0.0f,size.z)); m_DebugBuffer.AddVertexData(color);
									
		m_DebugBuffer.AddVertexData(min + vec3(size.x,  0.0f,size.z)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(size.x,size.y,size.z)); m_DebugBuffer.AddVertexData(color);
		
		m_DebugBuffer.AddVertexData(min + vec3(size.x,size.y,size.z)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(  0.0f,size.y,size.z)); m_DebugBuffer.AddVertexData(color);
		
		m_DebugBuffer.AddVertexData(min + vec3(  0.0f,size.y,size.z)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(  0.0f,  0.0f,size.z)); m_DebugBuffer.AddVertexData(color);
		
		
		m_DebugBuffer.AddVertexData(min + vec3(  0.0f,  0.0f,  0.0f)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(  0.0f,  0.0f,size.z)); m_DebugBuffer.AddVertexData(color);
		
		m_DebugBuffer.AddVertexData(min + vec3(size.x,  0.0f,  0.0f)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(size.x,  0.0f,size.z)); m_DebugBuffer.AddVertexData(color);
		
		m_DebugBuffer.AddVertexData(min + vec3(size.x,size.y,  0.0f)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(size.x,size.y,size.z)); m_DebugBuffer.AddVertexData(color);
		
		m_DebugBuffer.AddVertexData(min + vec3(  0.0f,size.y,  0.0f)); m_DebugBuffer.AddVertexData(color);
		m_DebugBuffer.AddVertexData(min + vec3(  0.0f,size.y,size.z)); m_DebugBuffer.AddVertexData(color);
	
	}
	
	override void drawBox(AlignedBox box, vec4 color) shared {
		version(direct_draw){
			synchronized(producingMutex()){
				if( isDirectDrawBatchWorking() ){
					send(GetTid(),makeMsg!(Renderer,"drawBox")(box,color));
				}
			}
		}
	}
	
	override void drawLine(ref const Position start, ref const Position end, ref const vec4 color){
		m_UpdateDebugBuffer = true;
		
		m_DebugBuffer.AddVertexData(start - m_FrameOrigin);
		m_DebugBuffer.AddVertexData(color);
		
		m_DebugBuffer.AddVertexData(end - m_FrameOrigin);
		m_DebugBuffer.AddVertexData(color);
	}
	
	override void drawLine(Position start, Position end, vec4 color) shared {
		version(direct_draw){
			synchronized( producingMutex ){
				if( isDirectDrawBatchWorking() ){
					send(GetTid(),makeMsg!(Renderer,"drawLine")(start,end,color));
				}
			}
		}
	}
	
	override void RegisterCVars(ConfigVarsBinding* CVarStorage) shared {
		auto self = cast(Renderer)this;
		foreach(m;__traits(allMembers,typeof(m_CVars))){
			CVarStorage.registerVariable(m,mixin("self.m_CVars." ~ m));
		}
	}
	
	override vec2 GetTextSize(uint font, const(char)[] text) shared {
		int width,height;
		Font.GetFont(font).GetTextSize(width, height, text);
		return vec2(width,height);
	}
	
	override vec2 GetTextSize(uint font, const(char)[] text) {
		int width,height;
		Font.GetFont(font).GetTextSize(height, width, text);
		return vec2(width,height);
	}
	
	override int GetFontHeight(uint font) shared {
		return Font.GetFont(font).GetMaxFontHeight();
	}
	
	auto shadowMap(){
		return m_ShadowMap.GetDepthTexture();
	}
	
	override void addTextureMemoryAmount(int amount){
		m_TextureMemoryAmount += amount;
	}
	
	override void addVertexBufferMemoryAmount(int amount){
		m_VertexBufferMemoryAmount += amount;
	}
	
	override Texture2D CreateTexture2D(rcstring name, ImageCompression compression){
		return New!Texture2D(name, this, compression);
	}

  override void DeleteTexture2D(Texture2D texture)
  {
    Delete(texture);
  }

  @property final override ReturnType!GetNewTemporaryAllocator frameAllocator()
  {
    return m_FrameAllocator;
  }
}
