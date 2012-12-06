module renderer.rendergroup;

import renderer.rendercall;
import renderer.uniformtype;
import renderer.shaderconstants;
import thBase.container.vector;
import renderer.renderer;
import renderer.rendertarget;
import renderer.exceptions;

/**
 * Represents a group of render calls which share the same rendertarget
 * If no rendertarget is specified the main rendertarget is used
 * to create this type use the factory method inside RenderSlice
 */ 
class RenderGroup {
private:
	static struct RendertargetBinding {
		int m_TargetNum;
		int m_BindingLocation;
	}

	static struct OverwriteData {
		Overwrite m_Data;
		ShaderConstant m_Constant;
		
		this(ShaderConstant pConstant, ref const(Overwrite) pData){
			m_Constant = pConstant;
			m_Data = pData;
		}
	}

	Vector!(RenderCall) m_RenderCalls;
	Vector!(RendertargetBinding) m_RendertargetBindings;
	IRendererInternal m_Renderer;
	Rendertarget m_Rendertarget;
	bool m_Sort, m_PostProcessing, m_DataHolding, m_ClearColor, m_ClearDepth, m_ClearStencil;
	Vector!(OverwriteData) m_Overwrites;
	
	void delegate() Init;
	void InitPostProcessing(){
		Rendertarget DataHoldingRendertarget = m_Renderer.GetDataHoldingRendertarget();
		m_Rendertarget = m_Renderer.GetPostProcessingRendertarget();
		
		if(m_Rendertarget !is Rendertarget.GetCurrentRendertarget()){
			if(m_Rendertarget !is null){
				m_Renderer.UseDefaultState();
				m_Rendertarget.Use();
			}
			else
				Rendertarget.GetCurrentRendertarget().Unuse();
		}
		
		if(m_RendertargetBindings.size() > 0 && DataHoldingRendertarget is null){
			throw New!RendererException(_T("Can not bind rendertarget textres because DataHoldingRendertarget is null"));
		}
		
		foreach(ref binding;m_RendertargetBindings.GetRange()){
			if(binding.m_TargetNum == -1)
				DataHoldingRendertarget.GetDepthTexture().BindToChannel(binding.m_BindingLocation);
			else
				DataHoldingRendertarget.GetColorTexture(binding.m_TargetNum).BindToChannel(binding.m_BindingLocation);
		}
		
	}
	void InitLastPostProcessing(){
		m_Rendertarget = null;
		Rendertarget DataHoldingRendertarget = m_Renderer.GetDataHoldingRendertarget();
		
		if(m_Rendertarget !is Rendertarget.GetCurrentRendertarget()){
			Rendertarget.GetCurrentRendertarget().Unuse();
		}
		
		if(m_RendertargetBindings.size() > 0 && DataHoldingRendertarget is null){
			throw New!RendererException(_T("Can not bind rendertarget textures because DataHoldingRendertarget is null"));
		}

		foreach(ref binding;m_RendertargetBindings.GetRange()){
			if(binding.m_TargetNum == -1)
				DataHoldingRendertarget.GetDepthTexture().BindToChannel(binding.m_BindingLocation);
			else
				DataHoldingRendertarget.GetColorTexture(binding.m_TargetNum).BindToChannel(binding.m_BindingLocation);
		}		
	}
	void InitMainRendertarget(){
		m_Rendertarget = m_Renderer.GetMainRendertarget();
		if(m_Rendertarget !is Rendertarget.GetCurrentRendertarget()){
			if(m_Rendertarget !is null){
				m_Renderer.UseDefaultState();
				m_Rendertarget.Use();
			}
			else
				Rendertarget.GetCurrentRendertarget().Unuse();
		}
		
		if(m_DataHolding){
			m_Renderer.SetDataHoldingRendertarget(m_Rendertarget);
		}
	}
	
	void InitGivenRendertarget(){
		if(m_Rendertarget !is Rendertarget.GetCurrentRendertarget()){
			if(m_Rendertarget !is null){
				m_Renderer.UseDefaultState();
				m_Rendertarget.Use();
			}
			else
				Rendertarget.GetCurrentRendertarget().Unuse();
		}
		
		Rendertarget DataHoldingRendertarget = m_Renderer.GetDataHoldingRendertarget();
		if(m_RendertargetBindings.size() > 0 && DataHoldingRendertarget is null){
			throw New!RendererException(_T("Can not bind rendertarget textures because DataHoldingRendertarget is null"));
		}
		foreach(ref binding;m_RendertargetBindings.GetRange()){
			if(binding.m_TargetNum == -1)
				DataHoldingRendertarget.GetDepthTexture().BindToChannel(binding.m_BindingLocation);
			else
				DataHoldingRendertarget.GetColorTexture(binding.m_TargetNum).BindToChannel(binding.m_BindingLocation);
		}
		
		if(m_DataHolding)
			m_Renderer.SetDataHoldingRendertarget(m_Rendertarget);
	}
	
public:
	
	this(IRendererInternal pRenderer){
		m_Renderer = pRenderer;
		m_RenderCalls = New!(Vector!RenderCall)();
		m_RendertargetBindings = New!(Vector!RendertargetBinding)();
		m_Overwrites = New!(Vector!OverwriteData)();
		Init = &InitMainRendertarget;
	}

  ~this()
  {
    foreach(rendercall; m_RenderCalls[])
    {
      AllocatorDelete(m_Renderer.frameAllocator, rendercall);
    }
    Delete(m_RenderCalls);
    Delete(m_RendertargetBindings);
    Delete(m_Overwrites);
  }
	
	void Use(){
		Init();
		
		if(m_ClearDepth || m_ClearColor || m_ClearStencil)
			m_Renderer.Clear(m_ClearDepth,m_ClearColor,m_ClearStencil);
		
		if(m_RenderCalls.size() == 0)
			return;
		
		foreach(ref overwrite;m_Overwrites.GetRange()){
			assert(overwrite.m_Constant !is null,"m_Constant is null");
			overwrite.m_Constant.Overwrite(overwrite.m_Data);
		}
		
		foreach(ref rendercall;m_RenderCalls.GetRange()){
			rendercall.Use();
		}
		
		foreach(ref overwrite;m_Overwrites.GetRange()){
			overwrite.m_Constant.SetOverwrite(false);
		}
	}
	
	void Reset(){
		Init = &InitMainRendertarget;
		m_Rendertarget = null;
		m_Sort = true;
		m_PostProcessing = false;
		m_RendertargetBindings.resize(0);
		m_Overwrites.resize(0);
		m_DataHolding = false;
		m_ClearDepth = false;
		m_ClearColor = false;
		m_ClearStencil = false;		

    foreach(rendercall; m_RenderCalls[])
    {
      AllocatorDelete(m_Renderer.frameAllocator, rendercall);
    }
		m_RenderCalls.resize(0);
	}
	
	/**
	 * Sets a rendertarget to use
	 * Params:
	 *		pRendertarget = the rendertarget to use
	 */
	void SetRendertarget(Rendertarget pRendertarget)
	in {
		assert(pRendertarget !is null,"pRendertarget may not be null");
	}
	body {
		m_Rendertarget = pRendertarget;
		Init = &InitGivenRendertarget;
	}
	
	/**
	 * when called the rendergroup will use the next post processing rendertarget in line as rendertarget
	 */
	void SetPostProcessingRendertarget(){
		Init = &InitPostProcessing;
		m_PostProcessing = true;
	}
	
	void SetLastPostProcessingRendertarget(){
		Init = &InitLastPostProcessing;
	}
	
	/**
	 * Adds a render call to the group
	 * Returns: a reference to the new RenderCall object
	 */
	RenderCall AddRenderCall()
	out(result){
		assert(result !is null,"result of AddRenderCall may not be null");
	}
	body {
		RenderCall temp = AllocatorNew!RenderCall(m_Renderer.frameAllocator, m_Renderer);
		m_RenderCalls.push_back(temp);
		return temp;
	}
	
	/**
	 * Returns: the number of render calls in this group
	 */
	size_t numberOfRenderCalls(){
		return m_RenderCalls.length;
	}

	
	/**
	 * Binds a part of the mainrendertarget to a texture unit
	 * Params:
	 *		pTargetNum = numer of the part to use
	 *		pTargetBinding = number of the texture unit to bind to
	 */
	void AddRendertargetBinding(int pTargetNum, int pTargetBinding)
	in {
		assert(pTargetNum >= -1,"pTargetNum has to be >= -1");
		assert(pTargetBinding >= 0,"pTargetBinding has to be >= 0");
	}
	body {
		size_t num = m_RendertargetBindings.size();
		m_RendertargetBindings.resize(num+1);
		m_RendertargetBindings[num].m_TargetNum = pTargetNum;
		m_RendertargetBindings[num].m_BindingLocation = pTargetBinding;
	}
	
	/**
	 * sets if the render calls in this group should be sorted
	 * Params:
	 *		pValue = true if yes, false otherwise
	 */
	void SetSort(bool pValue){
		m_Sort = pValue;
	}
	
	bool GetPostProcessing() const {
		return (m_PostProcessing || m_DataHolding);
	}
	
	/**
	 * Sets the current rendertarget to data holding
	 * sets the rendertarget of this render group to the data holding rendertarget
	 * Params:
	 *		pValue = true if yes, false otherwise
	 */
	void SetDataHolding(bool pValue){
		m_DataHolding = pValue;
	}
	
	/**
	 * sets which buffers to clear
	 * Params:
	 * 		pClearDepth = if true depth buffer is cleared
	 * 		pClearColor = if true color buffer is cleared
	 * 		pClearStencil = if true stencil buffer is cleared
	 */
	void SetClear(bool pClearDepth, bool pClearColor = false, bool pClearStencil = false){
		m_ClearDepth = pClearDepth;
		m_ClearColor = pClearColor;
		m_ClearStencil = pClearStencil;
	}
	
	/**
	 * Overwrites the given shader constant with the given value
	 * Params:
	 *		pConstant = the constant to overwrite
	 *		pValue = the value to use
	 */ 
	void AddOverwrite(T)(ShaderConstant pConstant, T pValue)
	in{
		assert(pConstant !is null,"pConstant may not be null");
	}
	body {
		static if(is(T == Overwrite)){
			m_Overwrites.push_back(OverwriteData(pConstant,pValue));
		}
		else {
			OverwriteData temp;
			temp.m_Constant = pConstant;
			temp.m_Data.Set(pValue);
			m_Overwrites.push_back(temp);
			assert(m_Overwrites[m_Overwrites.size()-1].m_Constant !is null,"reference has not been copied");
		}
	}
	
	
}