module renderer.sprite;

import base.renderer;
import renderer.texture2d;
import thBase.logging;

class SpriteAtlas : ISpriteAtlas {
private:
	uint m_Id;
	Texture2D m_Texture;
	
public:
	this(uint id, Texture2D texture){
		m_Id = id;
		m_Texture = texture;
	}

	Sprite GetSprite(int x, int y, int width, int height){
		auto img = m_Texture.GetImageData();
		vec2 halfPixelSize = vec2(0.5f / img.GetWidth(), 0.5f / img.GetHeight());

		Sprite result;
		result.offset = vec2(cast(float)x / cast(float)img.GetWidth() + halfPixelSize.x,
							 cast(float)y / cast(float)img.GetHeight() + halfPixelSize.y);
		result.size = vec2(cast(float)(width-1) / cast(float)img.GetWidth(),
						   cast(float)(height-1) / cast(float)img.GetHeight());
		logInfo("sprite %s %s",result.offset.f,result.size.f);
		result.atlas = m_Id;
		return result;
	}
	
	Sprite GetSprite(int x, int y, int width, int height) shared {
		return (cast(SpriteAtlas)this).GetSprite(x,y,width,height);
	}
	
	@property uint id(){
		return m_Id;
	}
	
	@property Texture2D texture(){
		return m_Texture;
	}
}