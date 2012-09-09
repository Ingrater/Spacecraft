module renderer.rendertarget;

import renderer.texture2d;
import renderer.imagedata2d;
import renderer.opengl;
import renderer.openglex;

import thBase.container.vector;
import core.stdc.stdlib;
import base.all;
import renderer.internal;

class Renderbuffer {
private:
	uint m_Id;
	
public:
	this(){
		gl.GenRenderbuffers(1,&m_Id);
	}
	
	~this(){
    gl.DeleteRenderbuffers(1,&m_Id);
	}
	
	uint GetId(){
		return m_Id;
	}
}

/**
 * a rendertarget to render to
 * can contain more then one texture to render to
 */
class Rendertarget {
	enum Name {
		DEPTH_BUFFER,
		STENCIL_BUFFER,
		COLOR_BUFFER,
		DEPTH_BUFFER_TEXTURE
	}
	
	string TargetName(ImageFormat pType)(int num){
		return pType.stringof ~ to!string(num);
	}
	
public:
	/**
	 * helper struct for rendertarget creation
	 */
	struct TargetPart {
		Name m_Name; ///name of the rendertarget part
		ImageFormat m_Type; ///type of the rendertarget part
		Texture2D m_SharedTexture = null; ///use a existing texture if given

		this(Name pName, ImageFormat pType, Texture2D pSharedTexture = null){
			m_Name = pName;
			m_Type = pType;
			m_SharedTexture = pSharedTexture;
		}
	}
	
private:
	uint m_Fbo = 0;
	Renderbuffer m_DepthBuffer = null;
	bool m_HasDepthBufferTexture = false;
	bool m_ClearDepth = true;
	bool m_ClearColor = true;
	bool m_ClearStencil = true;
	bool m_StencilBuffer = false;
	Texture2D m_DepthBufferTexture;
  Texture2D m_ColorBuffersData[8];
	Texture2D[] m_ColorBuffers;
	gl.GLenum m_Result;
	rcstring m_ErrorMessage;
	int m_Width;
	int m_Height;
	int m_MaxBuffers;
	bool m_IsToClear;
	IRendererInternal m_Renderer;
	
	__gshared static Rendertarget m_CurrentRendertarget = null;
	__gshared static Vector!(Rendertarget) m_RendertargetPool;		
	
public:	
	shared static this(){
		m_RendertargetPool = New!(Vector!(Rendertarget))();
	}

  shared static ~this()
  {
    Delete(m_RendertargetPool);
  }
	
	/**
	 * constructor
	 * Params:
	 *		pWidth = width of the rendertarget
	 *		pHeight = height of the rendertarget
	 *		pTargetParts = a list of the parts of the rendertarget can be 1 or more
	 *		pShareDepthBuffer = optional, share the depth buffer with an other rendertarget
	 */
	this(IRendererInternal pRenderer, int pWidth, int pHeight, TargetPart[] pTargetParts, Rendertarget pShareDepthBuffer = null){
		m_Renderer = pRenderer;
		gl.GetIntegerv(gl.MAX_DRAW_BUFFERS,&m_MaxBuffers);
		m_Width = pWidth;
		m_Height = pHeight;
		
		int MaxColorBuffers;
		gl.GetIntegerv(gl.MAX_COLOR_ATTACHMENTS,&MaxColorBuffers);
		int NumColorBuffers = 0;
		foreach(t;pTargetParts){
			if(t.m_Name == Name.COLOR_BUFFER)
				NumColorBuffers++;
		}
		
		if(MaxColorBuffers < NumColorBuffers){
			m_ErrorMessage = format("Your OpenGL implementation supports only %d color buffers but %d are needed", MaxColorBuffers, NumColorBuffers);
			return;
		}
		
		//Create Frame Buffer Object
		gl.GenFramebuffers(1,&m_Fbo);
		gl.BindFramebuffer(gl.FRAMEBUFFER,m_Fbo);
		scope(exit){
			gl.BindFramebuffer(gl.FRAMEBUFFER,0);
		}
		
		foreach(int i,t;pTargetParts){
			final switch(t.m_Name){
				case Name.DEPTH_BUFFER:
					{
						if(m_DepthBuffer.GetId() != 0){
							m_ErrorMessage = _T("Creating 2 or more depth buffers is not possible!");
							return;
						}
						if(m_HasDepthBufferTexture){
							m_ErrorMessage = _T("A depth buffer texture has already been created, can not create another depth texture");
							return;
						}
						m_DepthBuffer = new Renderbuffer();
						gl.BindRenderbuffer(gl.RENDERBUFFER,m_DepthBuffer.GetId());
						gl.GLenum BufferType = ImageBaseFormat.DEPTH;
						if(m_StencilBuffer)
							BufferType = ImageBaseFormat.DEPTH_STENCIL;
						gl.RenderbufferStorage(gl.RENDERBUFFER, BufferType, m_Width, m_Height);
						gl.FramebufferRenderbuffer(gl.FRAMEBUFFER,gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, m_DepthBuffer.GetId());
						if(m_StencilBuffer){
							gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.STENCIL_ATTACHMENT, gl.RENDERBUFFER, m_DepthBuffer.GetId());
						}
					}
					break;
				case Name.STENCIL_BUFFER:
					{
						if(m_DepthBuffer.GetId() != 0 || m_HasDepthBufferTexture){
							m_ErrorMessage = _T("Stencil buffer has to be defined before a depth buffer");
							return;
						}
						m_StencilBuffer = true;
					}
					break;
				case Name.COLOR_BUFFER:
					{
						if(t.m_SharedTexture !is null){
							Texture2D SharedTexture = t.m_SharedTexture;
							if(IsDepthType(SharedTexture.GetImageData().GetFormat())){
								m_ErrorMessage = _T("shared color attachment can not be of an depth-type");
								return;
							}
							if(SharedTexture.GetWidth() != m_Width || SharedTexture.GetHeight() != m_Height){
								m_ErrorMessage = format("shared color texture '%d' has to be of the same size as the rendertarget", i);
								return;
							}
              m_ColorBuffersData[m_ColorBuffers.length] = SharedTexture;
							m_ColorBuffers = m_ColorBuffersData[0..(m_ColorBuffers.length+1)];
							gl.FramebufferTexture2D(gl.FRAMEBUFFER,cast(gl.GLenum)(gl.COLOR_ATTACHMENT0 + (m_ColorBuffers.length-1)), gl.TEXTURE_2D, SharedTexture.GetTextureId(), 0);
						}
						else {
							if(IsDepthType(t.m_Type)){
								m_ErrorMessage = _T("A color attachment can not be of an depth-type");
								return;
							}
							auto TextureName = format("Rendertarget %d - ColorBuffer %d", m_Fbo, m_ColorBuffers.length);
							Texture2D TempTexture2D = m_Renderer.CreateTexture2D(TextureName,ImageCompression.NONE);
              m_ColorBuffersData[m_ColorBuffers.length] = TempTexture2D;
							m_ColorBuffers = m_ColorBuffersData[0..(m_ColorBuffers.length+1)];
							TempTexture2D.CreateEmpty(m_Width,m_Height,t.m_Type,
							                          Texture2D.Options.LINEAR | Texture2D.Options.CLAMP_T 
							                          | Texture2D.Options.CLAMP_S | Texture2D.Options.NO_LOCAL_DATA);
							gl.FramebufferTexture2D(gl.FRAMEBUFFER, cast(gl.GLenum)(gl.COLOR_ATTACHMENT0 + (m_ColorBuffers.length-1)), gl.TEXTURE_2D, TempTexture2D.GetTextureId(), 0);
						}
					}
					break;
				case Name.DEPTH_BUFFER_TEXTURE:
					{
						if(m_DepthBuffer !is null){
							m_ErrorMessage = "A depth texture has already been created";
							return;
						}
						if(t.m_SharedTexture !is null){
							Texture2D SharedTexture = t.m_SharedTexture;
							if(!IsDepthType(t.m_Type)){
								m_ErrorMessage = "shared depth buffer texture has to be of an DEPTHxx type";
								return;
							}
							if(SharedTexture.GetImageData().GetFormat() != ImageFormat.DEPTH24STENCIL && m_StencilBuffer){
								m_ErrorMessage = "shared depth buffer texture is not of type DEPTH24STENCIL which is the only supported depth stencil type yet";
								return;
							}
							m_DepthBufferTexture = SharedTexture;
							if(m_StencilBuffer)
								gl.FramebufferTexture2D(gl.FRAMEBUFFER,gl.STENCIL_ATTACHMENT,gl.TEXTURE_2D, m_DepthBufferTexture.GetTextureId(),0);
							gl.FramebufferTexture2D(gl.FRAMEBUFFER,gl.DEPTH_ATTACHMENT,gl.TEXTURE_2D, m_DepthBufferTexture.GetTextureId(),0);
							m_HasDepthBufferTexture = true;
						}
						else {
							if(!IsDepthType(t.m_Type)){
								m_ErrorMessage = "A depth buffer attachment has to be of an DEPTHxx type";
								return;
							}
							if(m_StencilBuffer && t.m_Type != ImageFormat.DEPTH24){
								m_ErrorMessage = "only a depth buffer of type DEPTH24 is supported together with a stencil buffer";
								return;	
							}
							if(m_StencilBuffer){
								t.m_Type = ImageFormat.DEPTH24STENCIL;
							}
							auto TextureName = format("Rendertarget %d - DepthBufferTexture", m_Fbo);
							m_DepthBufferTexture = m_Renderer.CreateTexture2D(TextureName,ImageCompression.NONE);
							m_DepthBufferTexture.CreateEmpty(m_Width,m_Height,t.m_Type,
							                                 Texture2D.Options.LINEAR | Texture2D.Options.CLAMP_T
							                                 | Texture2D.Options.CLAMP_S | Texture2D.Options.NO_LOCAL_DATA);
							m_HasDepthBufferTexture = true;
							gl.FramebufferTexture2D(gl.FRAMEBUFFER,gl.DEPTH_ATTACHMENT,gl.TEXTURE_2D,m_DepthBufferTexture.GetTextureId(),0);
							if(m_StencilBuffer){
								gl.FramebufferTexture2D(gl.FRAMEBUFFER,gl.STENCIL_ATTACHMENT,gl.TEXTURE_2D,m_DepthBufferTexture.GetTextureId(),0);
							}
						}
					}
					break;
			}
		}
		if(pShareDepthBuffer !is null){
			if(m_DepthBuffer.GetId() != 0){
				m_ErrorMessage = _T("Can not share depth buffer. Rendertarget already has a depth buffer");
				return;
			}
			if(m_HasDepthBufferTexture){
				m_ErrorMessage = _T("Can not share depth buffer. Rendertargert already has a depth buffer texture");
				return;
			}
			if(pShareDepthBuffer.m_Width != m_Width || pShareDepthBuffer.m_Height != m_Height){
				m_ErrorMessage = _T("Width and/or Height of depth buffer to share do not match!");
				return;
			}
			if(pShareDepthBuffer.m_DepthBuffer.GetId() == 0){
				m_ErrorMessage = _T("Given rendertarget has no depth buffer to share");
				return;
			}
			m_DepthBuffer = pShareDepthBuffer.m_DepthBuffer;
			gl.FramebufferRenderbuffer(gl.FRAMEBUFFER,gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, m_DepthBuffer.GetId());
		}
		
		//Depth buffer only
		if(NumColorBuffers <= 0){
			gl.DrawBuffer( gl.NONE);
			gl.ReadBuffer( gl.NONE);
		}
		
		m_Result = gl.CheckFramebufferStatus(gl.FRAMEBUFFER);
		if(m_Result != gl.FRAMEBUFFER_COMPLETE){
			switch(m_Result){
				case gl.FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
					m_ErrorMessage = "Error: incomplete attachment";
					break;
				case gl.FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
					m_ErrorMessage = "Error: missing attachment";
					break;
				case gl.FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
					m_ErrorMessage = "Error: dimensions of rendertarget errorness";
					break;
				case gl.FRAMEBUFFER_INCOMPLETE_FORMATS:
					m_ErrorMessage = "Error: errorness format";
					break;
				case gl.FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER:
					m_ErrorMessage = "Error: missing draw buffer";
					break;
				case gl.FRAMEBUFFER_INCOMPLETE_READ_BUFFER:
					m_ErrorMessage = "Error: missing read buffer";
					break;
				case gl.FRAMEBUFFER_UNSUPPORTED:
					m_ErrorMessage = "Error: rendertarget not supported";
					break;
				default:
					m_ErrorMessage = "Error: unkown error";
					break;
			}
		}
		
		m_RendertargetPool.push_back(this);
	}
	
	~this(){
    foreach(texture; m_ColorBuffers)
    {
      m_Renderer.DeleteTexture2D(texture);
    }
    m_Renderer.DeleteTexture2D(m_DepthBufferTexture);
    gl.DeleteFramebuffers(1,&m_Fbo);
	}
	
	/**
	 * uses the rendertarget
	 */
	void Use(){
		gl.BindFramebuffer(gl.FRAMEBUFFER,m_Fbo);
		if(m_CurrentRendertarget is null)
			gl.PushAttrib(gl.VIEWPORT_BIT);
		gl.Viewport(0,0,m_Width,m_Height);
		m_CurrentRendertarget = this;
		if(m_IsToClear){
			uint options = 0;
			if(m_ClearDepth)
				options |= gl.DEPTH_BUFFER_BIT;
			if(m_ColorBuffers.length > 0 && m_ClearColor)
				options |= gl.COLOR_BUFFER_BIT;
			if(m_StencilBuffer && m_ClearStencil)
				options |= gl.STENCIL_BUFFER_BIT;
			gl.Clear(options);
			m_IsToClear = false;
		}
	}
	
	/**
	 * ends usage of the rendertarget
	 */
	void Unuse(){
		m_CurrentRendertarget = null;
		gl.PopAttrib();
		gl.BindFramebuffer(gl.FRAMEBUFFER, 0);		
	}
	
	/**
	 * set rendering to one color buffer of this rendertarget
	 * Params:
	 *		pNum = the color buffer to render to
	 */
	void SetTarget(size_t pNum){
		m_CurrentRendertarget = null;
		gl.PopAttrib();
		gl.BindFramebuffer(gl.FRAMEBUFFER,0);
	}
	
	/**
	 * set rendering to multiple color buffer of this rendertarget
	 * Params:
	 *		pTargets = an array of the color buffers to set
	 */
	void SetMultipleTargets(size_t[] pTargets)
	in {
		assert(m_CurrentRendertarget == this,"Can only set target if rendertarget is in use");
		assert(pTargets.length <= m_MaxBuffers,"To many buffers to use");
	}
	body {
		scope Buffers = new gl.GLenum[pTargets.length];
		foreach(int i,t;pTargets){
			Buffers[i] = cast(gl.GLenum)(gl.COLOR_ATTACHMENT0 + t);
		}
		gl.DrawBuffers(cast(int)Buffers.length,Buffers.ptr);
	}
	
	/**
	 * sets for which color targets the blending should be enabled
	 * Params:
	 *		pTargets = an array of bools
	 */
	/*void SetBlending(bool[] pTargets)
	in {
		assert(m_CurrentRendertarget == this,"Can only set target if rendertarget is in use");
		assert(pTargets.length == m_ColorBuffers.length,"To many/less elements in pTargets array");
	}
	body {		
		foreach(int i,t;pTargets){
			if(t){
				gl.EnableIndexed(gl.BLEND,i);
			}
			else {
				gl.DisableIndexed(gl.BLEND,i);
			}
		}
	}*/
	
	/**
	 * Get a color texture of the rendertarget
	 * Params:
	 *		pNum = number of the color texture to get
	 * Returns:  the texture
	 */
	Texture2D GetColorTexture(size_t pNum)
	body {
		return m_ColorBuffers[pNum];
	}
	
	/**
	 * Gets the depth texture of the rendertarget
	 */
	Texture2D GetDepthTexture()
	in {
		assert(m_HasDepthBufferTexture,"Rendertarget has no depth texture");
	}
	body {
		return m_DepthBufferTexture;
	}
	
	/**
	 * get the rendertarget which is currently in use
	 */
	static Rendertarget GetCurrentRendertarget(){return m_CurrentRendertarget;}
	
	/**
	 * query if an error happend during rendertarget creation
	 * Returns: empty string if no error, the error string otherwise
	 */
	rcstring Error(){
		return m_ErrorMessage;
	}
	
	/**
	 * sets if the rendertarget needs to be cleared
	 * Params
	 * 		pValue = if the rendertarget is to be cleared or not
	 */
	void SetIsToClear(bool pValue){m_IsToClear = pValue;}
	
	/**
	 * Clears all exisiting rendertargets
	 */
	static void ClearAll(){
		foreach(e;m_RendertargetPool[]){
			e.SetIsToClear(true);
		}
	}
	
	/**
	 * sets if the depth of the rendertarget is to be cleared
	 * Params:
	 *		pValue = true if to clear, flase otherwise
	 */
	void SetClearDepth(bool pValue){m_ClearDepth = pValue;}
	
	/**
	 * sets if the color of the rendertarget is to be cleared
	 * Params:
	 *		pValue = true if to clear, false otherwise
	 */
	void SetClearColor(bool pValue){m_ClearColor = pValue;}
	
	/**
	 * sets if the stencil buffer of the rendertarget is to be cleared
	 * Params:
	 *		pValue = true if to clear, false otherwise
	 */
	void SetClearStencil(bool pValue){m_ClearStencil = pValue;}
	
	/**
	 * gets tests if the given type enum value is a depth type
	 * Params:
	 *  	pType = the type to test
	 * Returns: true if it is a depth type, false otherwise
	 */
	static bool IsDepthType(ImageFormat pType){
		switch(pType){
			case ImageFormat.DEPTH16:
			case ImageFormat.DEPTH24:
			case ImageFormat.DEPTH24STENCIL:
			case ImageFormat.DEPTH32:
				return true;
			default:
				return false;
		}
		assert(0,"not reachable");
	}
}
