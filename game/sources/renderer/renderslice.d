module renderer.renderslice;

import thBase.container.vector;
import renderer.rendergroup;
import renderer.renderer;

/**
 * A RenderSlice
 * Groups together multiple RenderGroups
 * has to be queried from renderer
 */
class RenderSlice {
private:
	Vector!(RenderGroup) m_RenderGroups;
	IRendererInternal m_Renderer;
	bool m_PostProcessing;
	bool m_Active = true;
	size_t m_NumRenderGroups = 0;
	
public:
	this(IRendererInternal pRenderer){
		m_Renderer = pRenderer;
		m_RenderGroups = New!(Vector!(RenderGroup))();
	}

  ~this()
  {
    foreach(group; m_RenderGroups[])
    {
      Delete(group);
    }
    Delete(m_RenderGroups);
  }
	
	void Use(){
		if(m_NumRenderGroups == 0 || !m_Active)
			return;
		
		for(size_t i=0;i<m_NumRenderGroups;i++){
			m_RenderGroups[i].Use();
		}
	}
	
	void Reset(){
		for(size_t i=0;i<m_NumRenderGroups;i++){
			m_RenderGroups[i].Reset();
		}
		m_NumRenderGroups = 0;
	}
	
	void SetLastPostProcessing(){
		RenderGroup LastPostProcessing = null;
		foreach(group;m_RenderGroups.GetRange()){
			if(group.GetPostProcessing())
				LastPostProcessing = group;
		}
		if(LastPostProcessing !is null)
			LastPostProcessing.SetLastPostProcessingRendertarget();
	}
	
	/**
	 * Adds a render group to the slice
	 * Returns: the new render group object
	 */
	RenderGroup AddRenderGroup()
	out(result){
		assert(result !is null,"result may not be null");
	}
	body {
		if(m_NumRenderGroups < m_RenderGroups.size()){
			return m_RenderGroups[m_NumRenderGroups++];
		}
		else{
			auto temp = New!RenderGroup(m_Renderer);
			m_RenderGroups.push_back(temp);
			m_NumRenderGroups = m_RenderGroups.size();
			return temp;
		}
		assert(0,"not reachable");
	}
	
	bool GetPostProcessing() const {
		if(m_Active)
			return m_PostProcessing;
		return false;
	}
	
	/**
	 * Sets if this slice is a post processing step or not
	 */
	void SetPostProcessing(bool pValue){
		m_PostProcessing = pValue;
	}
	
	/**
	 * sets if this slice is active and should be invoked by the renderer or not
	 */
	void SetActive(bool pValue){
		m_Active = pValue;
	}
	
	bool GetActive() const {
		return m_Active;
	}
}