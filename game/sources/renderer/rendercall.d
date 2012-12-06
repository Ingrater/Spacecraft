module renderer.rendercall;

import renderer.texture;
import renderer.vertexbuffer;
import renderer.uniformtype;
import renderer.shader;
import renderer.stateobject;
import renderer.shaderconstants;
import renderer.renderer;
import thBase.container.vector;

/**
 * Represents a render call
 * RenderCall class. Contains all necessary information to do a render call.
 * Needs at least a vertex buffer and a shader to be complete
 * If no state object is defined the current state is used
 * If no textures are defined the current textuers are used
 * To create this type, use the factory method inside RenderGroup
 */ 
class RenderCall {
	//mixin GrowingPool!(RenderCall);
	
private:	
	struct OverwriteData {
		ShaderConstant m_ShaderConstant;
		renderer.uniformtype.Overwrite m_Data;
		
		this(ShaderConstant pShaderConstant, ref const(renderer.uniformtype.Overwrite) pData){
			m_Data = pData;
			m_ShaderConstant = pShaderConstant;
		}
	}
	
	struct TextureInfo {
		ITextureInternal m_Texture;
		uint m_Binding;
		
		this(ITextureInternal pTexture, uint pBinding){
			m_Texture = pTexture;
			m_Binding = pBinding;
		}
	}
	
	Vector!(OverwriteData, typeof(m_Renderer.frameAllocator)) m_Overwrites;
	VertexBuffer m_VertexBuffer;
	Shader m_Shader;
	StateObject m_StateObject;
	Vector!(TextureInfo, typeof(m_Renderer.frameAllocator)) m_Textures;
	bool m_DrawRange = false;
	uint m_RangeStart,m_RangeSize;
  IRendererInternal m_Renderer;
	
public:
	
	this(IRendererInternal renderer){
    m_Renderer = renderer;
		m_Overwrites = AllocatorNew!(typeof(m_Overwrites))(m_Renderer.frameAllocator, m_Renderer.frameAllocator);
		m_Textures = AllocatorNew!(typeof(m_Textures))(m_Renderer.frameAllocator, m_Renderer.frameAllocator);
	}

  ~this()
  {
    AllocatorDelete(m_Renderer.frameAllocator, m_Overwrites);
    AllocatorDelete(m_Renderer.frameAllocator, m_Textures);
  }
	
	/**
	 * Sets the vertex buffer to use
	 * Params:
	 * 		pVeretxBuffer = the vertex buffer
	 */
	void SetVertexBuffer(VertexBuffer pVertexBuffer)
	in {
		assert(pVertexBuffer !is null,"pVertexBuffer may not be null");
	}
	body {
		m_VertexBuffer = pVertexBuffer;
	}
	
	/**
	 * Sets the shader to use
	 * Params:
	 *		pShader = the shader to use
	 */
	void SetShader(Shader pShader)
	in {
		assert(pShader !is null,"PShader may not be null");
	}
	body {
		m_Shader = pShader;
	}
	
	/**
	 * Sets the state object to use
	 * Params:
	 *		pStateObject = the state object to use
	 */
	void SetStateObject(StateObject pStateObject)
	in {
		assert(pStateObject !is null,"pStateObject may not be null");
	}
	body {
		m_StateObject = pStateObject;
	}
	
	/**
	 * Overwrite a given shader constant
	 * Params:
	 *		pConstant = the constant to overwrite
	 *		pValue = the value to overwrite with
	 */ 
	void Overwrite(T)(ShaderConstant pConstant, T pValue)
	in {
		assert(pConstant !is null,"pConstant may not be null");
	}
	body {
		static if(is(T == renderer.uniformtype.Overwrite)){
			m_Overwrites.push_back(OverwriteData(pConstant,pValue));
		}
		else {
			OverwriteData temp;
			temp.m_ShaderConstant = pConstant;
			temp.m_Data.Set(pValue);
			m_Overwrites.push_back(temp);
		}
	}
	
	/**
	 * Add a texture to be used in this rendercall
	 * Params:
	 *		pTexture = the texture
	 *		pChannel = the texture channel to bind the texture to
	 */ 
	void AddTexture(ITextureInternal pTexture, uint pChannel)
	in {
		assert(pTexture !is null,"pTexture may not be null");
	}
	body {
		m_Textures.push_back(TextureInfo(pTexture,pChannel));
	}
	
	/**
	 * Sets a range to draw
	 * Params:
	 *		pStart = start of the range
	 *		pLength = length of the range
	 */
	void SetRange(uint pStart, uint pLength){
		m_DrawRange = true;
		m_RangeStart = pStart;
		m_RangeSize = pLength;
	}
	
	void Reset(){
		m_Textures = null;
		m_Overwrites = null;
		m_VertexBuffer = null;
		m_Shader = null;
		m_StateObject = null;
		m_DrawRange = false;
	}
	
	void Use()
	in {
		assert(m_VertexBuffer !is null,"RenderCall without VertexBuffer!");
		assert(m_Shader !is null,"RenderCall without Shader");
	}
	body {
		foreach(overwrite;m_Overwrites.GetRange()){
			overwrite.m_ShaderConstant.Overwrite(overwrite.m_Data);
		}
		
		if(m_StateObject !is null)
			m_StateObject.Use();
		
		foreach(texture;m_Textures.GetRange()){
			texture.m_Texture.BindToChannel(texture.m_Binding);
		}
		
		m_Shader.Use();
		if(!m_DrawRange)
			m_VertexBuffer.Draw();
		else
			m_VertexBuffer.DrawRange(m_RangeStart,m_RangeSize);
		
		foreach(overwrite;m_Overwrites.GetRange()){
			overwrite.m_ShaderConstant.SetOverwrite(false);
		}
	}
}