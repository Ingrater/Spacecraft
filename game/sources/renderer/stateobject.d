module renderer.stateobject;

import renderer.opengl;
import thBase.math3d.all;
import renderer.shaderconstants;
import base.utilsD2;
import thBase.container.vector;

/**
 * Wrapper class for needed OpenGL states
 */
class StateObject {
public:
	enum Comparing : uint {
		NEVER = gl.NEVER,
		ALWAYS = gl.ALWAYS,
		LESS = gl.LESS,
		LEQUAL = gl.LEQUAL,
		EQUAL = gl.EQUAL,
		GEQUAL = gl.GEQUAL,
		GREATER = gl.GREATER,
		NOTEQUAL = gl.NOTEQUAL
	}
	
	enum StencilOps : uint {
		KEEP = gl.KEEP,
		ZERO = gl.ZERO,
		REPLACE = gl.REPLACE,
		INCR = gl.INCR,
		DECR = gl.DECR,
		INVERT = gl.INVERT,
		INCR_WRAP = gl.INCR_WRAP,
		DECR_WRAP = gl.DECR_WRAP
	}
	
	enum Blending : uint {
		ONE = gl.ONE,
		SRC_ALPHA = gl.SRC_ALPHA,
		DST_ALPHA = gl.DST_ALPHA,
		ONE_MINUS_SRC_ALPHA = gl.ONE_MINUS_SRC_ALPHA,
		ONE_MINUS_DST_ALPHA = gl.ONE_MINUS_DST_ALPHA
	}
	
	enum Cull : uint {
		FRONT = gl.FRONT,
		BACK = gl.BACK,
		NONE = gl.NONE
	}
private:
	bool m_DepthTest = false;
	bool m_DepthWrite = true;
	Comparing m_DepthFunc = Comparing.LESS;
	bool m_ColorWrite = true;
	
	bool m_StencilTest = false;
	Comparing m_StencilFunc = Comparing.ALWAYS;
	int m_StencilRef = 0;
	uint m_StencilValueMask = cast(uint)0xFFFFFFFF;
	uint m_StencilMask = cast(uint)0xFFFFFFFF;
	
	StencilOps m_StencilFail = StencilOps.KEEP;
	StencilOps m_StencilDepthFail = StencilOps.KEEP;
	StencilOps m_StencilDepthPass = StencilOps.KEEP;
	
	bool m_Blending = false;
	Blending m_BlendingSrc = Blending.ONE;
	Blending m_BlendingDst = Blending.ONE;
	
	bool m_Multisampling = true;
	
	Cull m_CullFace = Cull.BACK;
	
	composite!(Vector!vec4) m_ClippingPlanes;
	
	bool m_WireFrame = false;
	
	bool m_ClampFloat = true;
	
	__gshared static ConstRef!(const(StateObject)) m_CurrentStateObject;
	__gshared static ConstRef!(const(ShaderConstantMat4)) m_ViewMatrix;
public:
	shared static this(){
		m_CurrentStateObject = null;
		m_ViewMatrix = null;
	}

  this()
  {
    m_ClippingPlanes = typeof(m_ClippingPlanes)(DefaultCtor());
    m_ClippingPlanes.construct();
  }

  ~this()
  {
  }
	
	void copy(const(StateObject) o){
		this.m_Blending = o.m_Blending;
		this.m_BlendingDst = o.m_BlendingDst;
		this.m_BlendingSrc = o.m_BlendingSrc;
		this.m_ClippingPlanes.CopyFrom(o.m_ClippingPlanes._instance);
		this.m_ColorWrite = o.m_ColorWrite;
		this.m_CullFace = o.m_CullFace;
		this.m_DepthFunc = o.m_DepthFunc;
		this.m_DepthTest = o.m_DepthTest;
		this.m_DepthWrite = o.m_DepthWrite;
		this.m_Multisampling = o.m_Multisampling;
		this.m_StencilDepthFail = o.m_StencilDepthFail;
		this.m_StencilDepthPass = o.m_StencilDepthPass;
		this.m_StencilFunc = o.m_StencilFunc;
		this.m_StencilFail = o.m_StencilFail;
		this.m_StencilMask = o.m_StencilMask;
		this.m_StencilRef = o.m_StencilRef;
		this.m_StencilTest = o.m_StencilTest;
		this.m_StencilValueMask = o.m_StencilValueMask;
		this.m_WireFrame = o.m_WireFrame;
		this.m_ClampFloat = o.m_ClampFloat;
	}
	
	/**
	 * uses the state object
	 * changes only the difference to the current state object
	 */
	void Use()
	in {
		assert(m_ViewMatrix.get !is null,"ViewMatrix has to be set for state objects");
	}
	body {
		if(m_CurrentStateObject.get is null){
			if(m_DepthTest)
				gl.Enable(gl.DEPTH_TEST);
			else
				gl.Disable(gl.DEPTH_TEST);
			gl.DepthFunc(cast(gl.GLenum)m_DepthFunc);
			
			if(m_DepthWrite)
				gl.DepthMask(cast(ubyte)gl.TRUE);
			else
				gl.DepthMask(cast(ubyte)gl.FALSE);
			
			if(m_StencilTest)
				gl.Enable(gl.STENCIL_TEST);
			else
				gl.Disable(gl.STENCIL_TEST);
			
			gl.StencilFunc(cast(gl.GLenum)m_StencilFunc,m_StencilRef,m_StencilValueMask);
			gl.StencilOp(cast(gl.GLenum)m_StencilFail,cast(gl.GLenum)m_StencilDepthFail,cast(gl.GLenum)m_StencilDepthPass);
			gl.StencilMask(m_StencilMask);
			
			if(m_ColorWrite)
				gl.ColorMask(cast(ubyte)gl.TRUE,cast(ubyte)gl.TRUE,cast(ubyte)gl.TRUE,cast(ubyte)gl.TRUE);
			else
				gl.ColorMask(cast(ubyte)gl.FALSE,cast(ubyte)gl.FALSE,cast(ubyte)gl.FALSE,cast(ubyte)gl.FALSE);
			
			if(m_Blending)
				gl.Enable(gl.BLEND);
			else
				gl.Disable(gl.BLEND);
			gl.BlendFunc(cast(gl.GLenum)m_BlendingSrc,cast(gl.GLenum)m_BlendingDst);
			
			if(m_CullFace){
				gl.Enable(gl.CULL_FACE);
				gl.CullFace(cast(gl.GLenum)m_CullFace);
			}
			else {
				gl.Disable(gl.CULL_FACE);
			}
			
			if(m_ClippingPlanes.length > 0){
				mat4 InvViewMatrix = m_ViewMatrix.GetData().Inverse().Transpose();
				size_t i=0;
        foreach(ref e; m_ClippingPlanes)
        {
					gl.Enable(cast(gl.GLenum)(gl.CLIP_PLANE0+i));
					vec4 temp = InvViewMatrix * e;
					double[4] eq;
					for(int j=0;j<4;j++)
						eq[j] = temp.f[j];
					gl.ClipPlane(cast(gl.GLenum)(gl.CLIP_PLANE0+i),eq.ptr);
          i++;
				}
			}
			
			if(m_Multisampling)
				gl.Enable(gl.MULTISAMPLE);
			else
				gl.Disable(gl.MULTISAMPLE);
			
			if(m_WireFrame)
				gl.PolygonMode(gl.FRONT_AND_BACK,gl.LINE);
			else
				gl.PolygonMode(gl.FRONT_AND_BACK,gl.FILL);
			
			if(m_ClampFloat){
				gl.ClampColorARB(gl.CLAMP_VERTEX_COLOR_ARB,gl.TRUE);
				gl.ClampColorARB(gl.CLAMP_FRAGMENT_COLOR_ARB,gl.TRUE);
				gl.ClampColorARB(gl.CLAMP_READ_COLOR_ARB,gl.TRUE);
			}
			else {
				gl.ClampColorARB(gl.CLAMP_VERTEX_COLOR_ARB,gl.FALSE);
				gl.ClampColorARB(gl.CLAMP_FRAGMENT_COLOR_ARB,gl.FALSE);
				gl.ClampColorARB(gl.CLAMP_READ_COLOR_ARB,gl.FALSE);
			}
			
			m_CurrentStateObject = this;
		}
		else {
			if(m_DepthTest != m_CurrentStateObject.m_DepthTest){
				if(m_DepthTest)
					gl.Enable(gl.DEPTH_TEST);
				else
					gl.Disable(gl.DEPTH_TEST);
			}
			if(m_CurrentStateObject.m_DepthFunc != m_DepthFunc)
				gl.DepthFunc(cast(gl.GLenum)m_DepthFunc);
			if(m_CurrentStateObject.m_DepthWrite != m_DepthWrite){
				if(m_DepthWrite)
					gl.DepthMask(cast(ubyte)gl.TRUE);
				else
					gl.DepthMask(cast(ubyte)gl.FALSE);
			}
			
			if(m_ColorWrite != m_CurrentStateObject.m_ColorWrite){
				if(m_ColorWrite)
					gl.ColorMask(cast(ubyte)gl.TRUE,cast(ubyte)gl.TRUE,cast(ubyte)gl.TRUE,cast(ubyte)gl.TRUE);
				else
					gl.ColorMask(cast(ubyte)gl.TRUE,cast(ubyte)gl.TRUE,cast(ubyte)gl.TRUE,cast(ubyte)gl.TRUE);
			}
			
			if(m_StencilTest != m_CurrentStateObject.m_StencilTest){
				if(m_StencilTest)
					gl.Enable(gl.STENCIL_TEST);
				else
					gl.Disable(gl.STENCIL_TEST);
			}
			
			if(m_StencilFunc != m_CurrentStateObject.m_StencilFunc ||
			   m_StencilRef != m_CurrentStateObject.m_StencilRef ||
			   m_StencilValueMask != m_CurrentStateObject.m_StencilValueMask)
				gl.StencilFunc(cast(gl.GLenum)m_StencilFunc,m_StencilRef,m_StencilValueMask);
			if(m_StencilFail != m_CurrentStateObject.m_StencilFail ||
			   m_StencilDepthFail != m_CurrentStateObject.m_StencilDepthFail ||
			   m_StencilDepthPass != m_CurrentStateObject.m_StencilDepthPass)
				gl.StencilOp(cast(gl.GLenum)m_StencilFail,cast(gl.GLenum)m_StencilDepthFail,cast(gl.GLenum)m_StencilDepthPass);
			if(m_StencilMask != m_CurrentStateObject.m_StencilMask)
				gl.StencilMask(m_StencilMask);
			
			if(m_Blending != m_CurrentStateObject.m_Blending){
				if(m_Blending)
					gl.Enable(gl.BLEND);
				else
					gl.Disable(gl.BLEND);
      }
				
			if(m_BlendingSrc != m_CurrentStateObject.m_BlendingSrc ||
			   m_BlendingDst != m_CurrentStateObject.m_BlendingDst)
				gl.BlendFunc(cast(gl.GLenum)m_BlendingSrc,cast(gl.GLenum)m_BlendingDst);
			
			if(m_CullFace != m_CurrentStateObject.m_CullFace){
				if(m_CullFace != Cull.NONE){
					gl.Enable(gl.CULL_FACE);
					gl.CullFace(cast(gl.GLenum)m_CullFace);
				}
				else
					gl.Disable(gl.CULL_FACE);
			}
			
			size_t this_size = 0;
			size_t other_size = 0;
			if(m_ClippingPlanes !is null)
				this_size = m_ClippingPlanes.length;
			if(m_CurrentStateObject.m_ClippingPlanes !is null)
				other_size = m_CurrentStateObject.m_ClippingPlanes.length;
			
			if(other_size > this_size){
				for(size_t i=other_size-1;i>=this_size;i--)
					gl.Disable(cast(gl.GLenum)(gl.CLIP_PLANE0+i));
			}
			else {
				for(size_t i=other_size;i<this_size;i++)
					gl.Enable(cast(gl.GLenum)(gl.CLIP_PLANE0+i));
			}
			if(this_size > 0){
				mat4 InvViewMatrix = m_ViewMatrix.GetData().Inverse().Transpose();
        size_t i=0;
				foreach(ref e;m_ClippingPlanes[]){
					vec4 temp = InvViewMatrix * e;
					double[4] eq;
					for(int j=0;j<4;j++)
						eq[j] = temp.f[j];
					gl.ClipPlane(cast(gl.GLenum)(gl.CLIP_PLANE0+i),eq.ptr);
          i++;
				}
			}
			
			if(m_CurrentStateObject.m_Multisampling != m_Multisampling){
				if(m_Multisampling)
					gl.Enable(gl.MULTISAMPLE);
				else
					gl.Disable(gl.MULTISAMPLE);
			}
			
			if(m_CurrentStateObject.m_WireFrame != m_WireFrame){
				if(m_WireFrame)
					gl.PolygonMode(gl.FRONT_AND_BACK,gl.LINE);
				else
					gl.PolygonMode(gl.FRONT_AND_BACK,gl.FILL);
			}
			
			if(m_CurrentStateObject.m_ClampFloat != m_ClampFloat){
				if(m_ClampFloat){
					gl.ClampColorARB(gl.CLAMP_VERTEX_COLOR_ARB,gl.TRUE);
					gl.ClampColorARB(gl.CLAMP_FRAGMENT_COLOR_ARB,gl.TRUE);
					gl.ClampColorARB(gl.CLAMP_READ_COLOR_ARB,gl.TRUE);
				}
				else {
					gl.ClampColorARB(gl.CLAMP_VERTEX_COLOR_ARB,gl.FALSE);
					gl.ClampColorARB(gl.CLAMP_FRAGMENT_COLOR_ARB,gl.FALSE);
					gl.ClampColorARB(gl.CLAMP_READ_COLOR_ARB,gl.FALSE);
				}
			}		
			
			m_CurrentStateObject = this;
		}
	}
	
	/**
	 * sets the depth test state
	 * Params:
	 *		pValue = true for on, false for off
	 */
	void SetDepthTest(bool pValue){
		m_DepthTest = pValue;
	}
	
	/**
	 * sets the depth write state
	 * Params:
	 *		pValue = true for on, flase for off
	 */
	void SetDepthWrite(bool pValue){
		m_DepthWrite = pValue;
	}
	
	/**
	 * sets the depth func state
	 * Params:
	 *		pDepthFunc = the depth func to use
	 */
	void SetDepthFunc(Comparing pDepthFunc){
		m_DepthFunc = pDepthFunc;
	}
 	
	/**
	 * sets the color write state
	 * Params:
	 *		pValue = true for on, false for off 
	 */
	void SetColorWrite(bool pValue){
		m_ColorWrite = pValue;
	}
	
	/**
	 * Sets the blending state
	 * Params:
	 * 		pValue = true for on, false for off
	 */
	void SetBlending(bool pValue){
		m_Blending = pValue;
	}
	
	/**
	 * sets the blend function state
	 * Params:
	 * 		pSrc = source blending function
	 *		pDst = destination blending function
	 */
	void SetBlendFunc(Blending pSrc, Blending pDst){
		m_BlendingSrc = pSrc;
		m_BlendingDst = pDst;
	}
	
	/**
	 * sets the stencil test state
	 * Params:
	 *		pValue = true for on, false for off
	 */
	void SetStencilTest(bool pValue){
		m_StencilTest = pValue;
	}
	
	/**
	 * sets the stencil function state
	 * Params:
	 *		pFunc = the stencil function to use
	 *		pRef = the reference value for the function
	 *		pValueMask = the bit mask to apply to the reference value
	 */
	void SetStencilFunc(Comparing pFunc, int pRef, uint pValueMask){
		m_StencilFunc = pFunc;
		m_StencilRef = pRef;
		m_StencilValueMask = pValueMask;
	}
	
	/**
	 * sets the stencil mask
	 * Params:
	 *		pMask = the stencil bit mask to use
	 */
	void SetStencilMask(uint pMask){m_StencilMask = pMask;}
	
	/**
	 * sets the stencil operation
	 * Params:
	 * 		pSfail = operation on stencil test fail
	 *		pDfail = operation on depth test fail
	 *		pDpass = operation on depth test pass
	 */ 
	void SetStencilOp(StencilOps pSfail, StencilOps pDfail, StencilOps pDpass){
		m_StencilFail = pSfail;
		m_StencilDepthFail = pDfail;
		m_StencilDepthPass = pDpass;
	}
	
	/**
	 * sets the face culling state
	 * Params:
	 *		pCullFace = the culling state
	 */
	void SetCullFace(Cull pCullFace){
		m_CullFace = pCullFace;
	}
	
	/**
	 * sets a clipping plane
	 * Params:
	 *		pNum = the number of the clipping plane to set
	 *		pPlane = the plane data
	 */
	void SetClippingPlane(size_t pNum, ref const(vec4) pPlane){
    if(m_ClippingPlanes.length <= pNum){
			m_ClippingPlanes.resize(pNum+1);
		}
		m_ClippingPlanes[pNum] = pPlane;
	}
	
	/**
	 * sets the multisample state
	 * Params:
	 *		pMultisample = true for on, false for off
	 */
	void SetMultisampling(bool pMultisampling){
		m_Multisampling = pMultisampling;
	}
	
	/**
	 *  sets the wireframe state
	 * Params:
	 *		pWireframe = true for on, false for off
	 */
	void SetWireframe(bool pWireframe){
		m_WireFrame = pWireframe;
	}
	
	/**
	 * sets if floats in textures and rendertargets should be clamped or not
	 */
	void SetClampFloat(bool value){
		m_ClampFloat = value;
	}
	
	/**
	 * Gets the state object currently in use
	 */
	static const(StateObject) GetCurrentStateObject(){
		return m_CurrentStateObject.get;
	}
	
	/**
	 * sets the view matrix to be used for plane transformation
	 * Params:
	 * 	 	pViewMatrix = the view matrix
	 */
	static void SetViewMatrix(const(ShaderConstantMat4) pViewMatrix){
		m_ViewMatrix = pViewMatrix;
	}
}
