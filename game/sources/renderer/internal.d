module renderer.internal;

import renderer.rendertarget;
import renderer.texture2d;
public import renderer.imagedata2d;
import thBase.allocator;
import std.traits;

/**
 * for renderer internal usage only
 */
interface IRendererInternal {
	
	void UseDefaultState();
	Rendertarget GetDataHoldingRendertarget();
	void SetDataHoldingRendertarget(Rendertarget pRendertarget);
	Rendertarget GetMainRendertarget();
	Rendertarget GetPostProcessingRendertarget();
	void Clear(bool pClearDepth, bool pClearColor, bool pClearStencil);
	void addTextureMemoryAmount(int amount);
	void addVertexBufferMemoryAmount(int amount);
	Texture2D CreateTexture2D(rcstring name, ImageCompression compression);
  void DeleteTexture2D(Texture2D texture);
  @property ReturnType!GetNewTemporaryAllocator frameAllocator();
}