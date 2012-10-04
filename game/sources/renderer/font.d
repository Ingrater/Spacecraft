module renderer.font;

import renderer.freetype.ft;
import renderer.texture2d;
import renderer.imagedata2d;
import renderer.vertexbuffer;
import thBase.container.vector;
import thBase.file;
import renderer.exceptions;
import thBase.format;
import thBase.string;
import thBase.container.hashmap;


import core.vararg;
import renderer.internal;

/**
 * represents a certain font with a certain font size
 */
class Font {
public:
	struct FontGlyph {		
		int m_Width;
		int m_Height;
		int m_Top;
		int m_Left;
		int m_Right;
		float m_MinTexX,m_MaxTexX;
		float m_MinTexY,m_MaxTexY;
		float m_fWidth,m_RealWidth;
		ImageData2D m_Data = null;
	};
	
private:
	__gshared Hashmap!(rcstring, Font) m_Fonts;
	__gshared Hashmap!(uint, Font) m_FontsById;
	static uint m_NextFontId = 0;
	static const(dchar)[] m_CharsToLoad;
	
	uint m_Id;
	dchar m_StartIndex;
	dchar m_EndIndex;
	size_t m_AnzChars;
	Vector!(FontGlyph) m_Glyphs;
	Texture2D m_FontTexture = null;
	rcstring m_Name;
	int m_MaxHeight;
	size_t[] m_CharAsignment;
	bool m_Printable = false;
	const(dchar)[] m_LoadedChars;
	rcstring m_Filename;
	int m_Size;
	IRendererInternal m_Renderer;
	
	void BuildTexture(){
		int MaxWidth,MinY,MaxY,MaxHeight;
		MaxWidth = m_Glyphs[0].m_Width;
		MaxY = m_Glyphs[0].m_Top;
		MinY = m_Glyphs[0].m_Height - m_Glyphs[0].m_Top;
		foreach(g;m_Glyphs.GetRange()){
			MaxWidth = (g.m_Width > MaxWidth) ? g.m_Width : MaxWidth;
			MaxY = (g.m_Top > MaxY) ? g.m_Top : MaxY;
			MinY = (g.m_Top - g.m_Height< MinY) ? g.m_Top - g.m_Height: MinY;
		}
		MaxHeight = MaxY - MinY;
		m_MaxHeight = MaxHeight;
		
		int size=64;
		int x,y;
		while(size < 2048){
			x=y=0;
			foreach(g;m_Glyphs.GetRange()){
			  	if((x + g.m_Width + 1) > size){
			    	y+=MaxHeight;
			    	x=0;
			  	}	
			  	x+=g.m_Width + 1;
			}
			if(y > size)
				size*=2;
			else
				break;
		}
		if(size == 2048){
			throw New!FontException(_T("Font texture is to large"));
		}
		
		m_FontTexture = m_Renderer.CreateTexture2D(m_Name ~ " - font texture", ImageCompression.AUTO);
		m_FontTexture.CreateEmpty(size,size,ImageFormat.LUMINANCE_ALPHA8,Texture2D.Options.NEAREST | Texture2D.Options.CLAMP_S | Texture2D.Options.CLAMP_T);
		ImageData2D ImageData = m_FontTexture.GetImageData();
		
		x=y=0;
		foreach(ref g;m_Glyphs.GetRange()){
			if((x + g.m_Width + 1) > size){
			 	y+=MaxHeight;
			  	x=0;
			}
			if(g.m_Data !is null){
				ImageData.Insert(g.m_Data,x,y + MaxHeight - g.m_Top + MinY);
        Delete(g.m_Data);
        g.m_Data = null;
			}
			float fStep = 1.0f / cast(float)size;
			g.m_MinTexY = cast(float)y * fStep;// + fStep / 2.0f;
			g.m_MinTexX = cast(float)(x) * fStep;// + fStep / 2.0f;
			x+=g.m_Width;
			g.m_MaxTexY = cast(float)(y+MaxHeight) * fStep;// + fStep / 2.0f;
			g.m_MaxTexX = cast(float)(x) * fStep;// + fStep / 2.0f;
			x++;
			g.m_fWidth = cast(float)(g.m_Width + g.m_Right);
			g.m_RealWidth = cast(float)g.m_Width;
		}
		
		m_FontTexture.Reupload();	
	}
	
	void BuildChar(ref FT_Face pFace, dchar pZeichen, size_t pNum){
		//Glyph laden
		if(ft.Load_Glyph( pFace, ft.Get_Char_Index( pFace, pZeichen ), FT_LOAD_DEFAULT ) != 0){
			throw New!FontException(format("Error loading the character '%x'", pNum));
		}
		
		FT_Glyph glyph;
		ft.Get_Glyph( pFace.glyph, &glyph);
		
		//In bitmap convertieren
		ft.Glyph_To_Bitmap( &glyph, FT_Render_Mode.FT_RENDER_MODE_NORMAL, null, 1 );
		FT_BitmapGlyph bitmap_glyph = cast(FT_BitmapGlyph)glyph;
		FT_Bitmap* bitmap = &bitmap_glyph.bitmap;
		
		//We need to do this for space
		ImageData2D.image_data_t buffer;
		if(bitmap.width > 0 || bitmap.rows > 0) {
      buffer = ImageData2D.image_data_t(1, StdAllocator.globalInstance);
      buffer[0] = ImageData2D.mipmap_data_t(2 * bitmap.rows * bitmap.width, StdAllocator.globalInstance);
      auto mipmap = buffer[0];
			for(int i=0;i<bitmap.rows * bitmap.width;i++){
				mipmap[i*2] = cast(ubyte)255;
				mipmap[i*2+1] = bitmap.buffer[i];
			}
		}
		
		with(m_Glyphs[pNum]){
			if(bitmap.width > 0 || bitmap.rows > 0) {
				m_Data = New!ImageData2D(StdAllocator.globalInstance);
				m_Data.SetData(StdAllocator.globalInstance, buffer, bitmap.width, bitmap.rows, ImageFormat.LUMINANCE_ALPHA8, ImageCompression.AUTO);
			}
			m_Width = bitmap.width;
			m_Height = bitmap.rows;
			m_Top = bitmap_glyph.top;
			m_Left = bitmap_glyph.left;
			m_Right = (pFace.glyph.advance.x >> 6) - bitmap_glyph.left - bitmap.width;
		}
	}
	
public:
	static this(){
		m_CharsToLoad = "? 1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜabcdefghijklmnopqrstuvwxyzäüöß+*/\\#,.:;_-()[]{}\"'<>|@=!"d;
	}

  shared static this()
  {
    m_Fonts = New!(typeof(m_Fonts))();
    m_FontsById = New!(typeof(m_FontsById))();
  }

  shared static ~this()
  {
    Delete(m_Fonts);
    Delete(m_FontsById);
  }

  static void DeleteFonts()
  {
    if(m_Fonts !is null && m_Fonts.count > 0)
    {
      auto fonts = NewArray!Font(m_Fonts.count);
      scope(exit) Delete(fonts);   
      size_t i=0;
      foreach(font; m_Fonts.values)
      {
        fonts[i++] = font;
      }
      foreach(font; fonts)
      {
        Delete(font);
      }
    }

    Delete(m_Fonts); m_Fonts = null;
    Delete(m_FontsById); m_FontsById = null;
  }
	
	/**
	 * constructor
	 * Params:
	 *		pName = name of the font has to be unique
	 */
 	this(rcstring pName, IRendererInternal pRenderer){
		m_Renderer = pRenderer;
		m_Name = pName;
		m_Fonts[pName] = this;
		m_Id = m_NextFontId++;
		m_FontsById[m_Id] = this;
		m_Glyphs = New!(Vector!FontGlyph)();
	}

  ~this()
  {
    m_Renderer.DeleteTexture2D(m_FontTexture);
    m_Fonts.remove(m_Name);
    m_FontsById.remove(m_Id);
    Delete(m_Glyphs);
    Delete(m_CharAsignment);
  }
	
	/**
	 * prints text into a vertexbuffer
	 * the vertexbuffer has to have 2 component position
	 * and a 2 component texture coordinate
	 * Params:
	 *		pFontBuffer = the vertex buffer to add the data to
	 *		pFmt the text to print
	 */
	void Print(VertexBuffer pFontBuffer, const(char)[] text) const
	in {
		assert(m_Printable,"Font was not correctly loaded. Print not possible");
	}
	body {		
		float[16] TempBuffer;
		float MaxHeight = cast(float)m_MaxHeight;
		float OffsetX=0.0f, OffsetY = 0.0f;
		foreach(dchar c;text){
			size_t index = 0;
			if(c == '\n'){
				OffsetY += MaxHeight * 1.5;
				OffsetX = 0.0;
				continue;
			}
			if(c >= m_StartIndex && c <= m_EndIndex)
				index = m_CharAsignment[c - m_StartIndex];
			
			//Print the glyph
			auto Glyph = m_Glyphs[index];
			
			TempBuffer[0] = OffsetX; TempBuffer[1] = OffsetY;
			TempBuffer[2] = Glyph.m_MinTexX; TempBuffer[3] = Glyph.m_MinTexY;
			
			TempBuffer[4] = OffsetX; TempBuffer[5] = MaxHeight+OffsetY;
			TempBuffer[6] = Glyph.m_MinTexX; TempBuffer[7] = Glyph.m_MaxTexY;
			
			TempBuffer[8] = Glyph.m_RealWidth+OffsetX; TempBuffer[9] = MaxHeight+OffsetY;
			TempBuffer[10] = Glyph.m_MaxTexX; TempBuffer[11] = Glyph.m_MaxTexY;
			
			TempBuffer[12] = Glyph.m_RealWidth+OffsetX; TempBuffer[13] = OffsetY;
			TempBuffer[14] = Glyph.m_MaxTexX; TempBuffer[15] = Glyph.m_MinTexY;
			
			pFontBuffer.AddVertexData(TempBuffer);
			OffsetX += Glyph.m_fWidth;
		}
	}
	
	/**
	 * gets the size of a text in pixels
	 * Params:
	 *		pWidth = width output
	 *		pHeight = height output
	 *		fmt = the text
	 * Returns: the formated string
	 */
	void GetTextSize(out int pHeight, out int pWidth, const(char)[] fmt) const {	  
		int Width=0;
		size_t index = 0;
		
		if(fmt[0] > m_StartIndex && fmt[0] <= m_EndIndex)
			index = m_CharAsignment[fmt[0] - m_StartIndex];
		
		int MaxY = m_Glyphs[index].m_Top;
		int MinY = m_Glyphs[index].m_Height - m_Glyphs[index].m_Top;
		foreach(dchar c;fmt){
			index = 0;
			if(c >= m_StartIndex && c <= m_EndIndex)
				index = m_CharAsignment[c - m_StartIndex];
			
			with(m_Glyphs[index]){
				Width += m_Width + m_Left + m_Right;
				MaxY = (m_Top > MaxY) ? m_Top : MaxY;
				MinY = (m_Top - m_Height< MinY) ? m_Top - m_Height: MinY;
			}
		}
		pHeight = MaxY - MinY;
		pWidth = Width;
	}
	
	/**
	 * gets the index of the char at a certain width
	 * usefull to determinate when to make a line break
	 * Params:
	 *		pWidth = the maximum width
	 *		pText = the text to check
	 */
	size_t GetCharAtWidth(int pWidth, wstring pText) const {
		int width = 0;
		foreach(size_t i,wchar c;pText){
			size_t index = 0;
			if(c == '\n')
				width = 0;
			if(c >= m_StartIndex && c <= m_EndIndex)
				index = m_CharAsignment[c - m_StartIndex];
			with(m_Glyphs[index]){
				width += m_Width + m_Left + m_Right;
			}
			if(width > pWidth)
				return i;
		}
		return -1;
	}
	
	/**
	 * loads a font from a ttf file
	 * Params:
	 *		pFilename = the filename of the font
	 *		pSize = the font size to load
	 *		pCharsToLoad = chars to load. If empty standard is loaded
	 */
	void Load(string pFilename, int pSize, const(dchar)[] pCharsToLoad = ""d){
		m_Filename = pFilename;
		m_Size = pSize;
		
		if(pCharsToLoad.length == 0)
			pCharsToLoad = m_CharsToLoad;
		
		FT_Library library;
		if( ft.Init_FreeType( &library )){
			throw New!FontException(_T("Couldn't init freetype library"));
		}
		scope(exit){
			ft.Done_FreeType(library);
		}

		
		FT_Face face;
		if(ft.New_Face( library, toCString(pFilename), 0, &face )){
			throw New!FontException(format("Couldn't load font '%s' from file '%s'", m_Name[], pFilename[]));
		}
		scope(exit) {
			ft.Done_Face(face);
		}
		
		ft.Set_Char_Size( face, pSize * 64, pSize * 64, 72, 72 );
		
		m_Glyphs.resize(pCharsToLoad.length);
		
		//Search for starting character
		dchar sc = pCharsToLoad[0];
		dchar ec = pCharsToLoad[0];
		foreach(dchar c;pCharsToLoad){
			if(c < sc)
				sc = c;
			if(c > ec)
				ec = c;
		}
		m_StartIndex = sc;
		m_EndIndex = ec;
		m_AnzChars = cast(int)m_Glyphs.size();
		m_LoadedChars = pCharsToLoad;
		
		size_t CharAnz = cast(size_t)(ec - sc) + 1;
		m_CharAsignment = NewArray!size_t(CharAnz);
		foreach(ref c;m_CharAsignment)
			c = 0;
		
		//Building the chars
		foreach(size_t i,dchar c;pCharsToLoad){
			BuildChar(face,c,i);
			m_CharAsignment[c - m_StartIndex] = i;
		}
		
		BuildTexture();
		
		//Habe fertig: alles freigeben
		m_Printable = true;
	}
	
	/**
	 * loads additional chars from the previously given font file
	 * Params:
	 *		pAdditionalChars = additional chars to load
	 */
	void AddChars(wchar[] pAdditionalChars)
	in {
		assert(m_Printable,"Can not add chars to non printable font");
	}
	body {
		wchar[] CharsToAdd;
		foreach(c1;pAdditionalChars){
			bool found = false;
			foreach(c2;m_LoadedChars){
				if(c1 == c2){
					found = true;
					break;
				}
			}
			if(!found){
				CharsToAdd ~= c1;
			}
		}
		if(CharsToAdd.length == 0)
			return;
		
		FT_Library library;
		if( ft.Init_FreeType( &library )){
			throw New!FontException(_T("Couldn't init freetype library"));
		}
		scope(exit){
			ft.Done_FreeType(library);
		}

		
		FT_Face face;
		if(ft.New_Face( library, toCString(m_Filename), 0, &face )){
			throw New!FontException(format("Couldn't load font '%s' from file '%s'", m_Name[], m_Filename[]));
		}
		scope(exit) {
			ft.Done_Face(face);
		}
		
		ft.Set_Char_Size( face, m_Size * 64, m_Size * 64, 72, 72 );
		
		m_LoadedChars ~= CharsToAdd;
		
		m_Glyphs.resize(m_LoadedChars.length);
		
		//Search for starting character
		dchar sc = m_LoadedChars[0];
		dchar ec = m_LoadedChars[0];
		foreach(dchar c;m_LoadedChars){
			if(c < sc)
				sc = c;
			if(c > ec)
				ec = c;
		}
		m_StartIndex = sc;
		m_EndIndex = ec;
		m_AnzChars = cast(int)m_Glyphs.size();

		//Recreating char asignment
		size_t CharAnz = cast(size_t)(ec - sc) + 1;
		m_CharAsignment = new size_t[CharAnz];
		foreach(ref c;m_CharAsignment)
			c = 0;		
		
		//Rebuilding the chars
		foreach(int i,wchar c;m_LoadedChars){
			BuildChar(face,c,i);
			m_CharAsignment[c - m_StartIndex] = cast(wchar)i;
		}
		
		//Font Textur neu bauen
		BuildTexture();
	}
	
	/**
	 * gets a font by its unique name
	 * Params:
	 * 		pName = the name of the font to get
	 * Returns: the font, throws exception if not found
	 */ 
	static Font GetFont(rcstring pName){
		if(!m_Fonts.exists(pName)){
			throw New!RCException(format("There is no font '%s'", pName[]));
		}
		return m_Fonts[pName];
	}
	
	///ditto
	static Font GetFont(uint id){
		auto temp = m_FontsById;
		if(!m_FontsById.exists(id)){
			throw New!RCException(format("There is no font with the id '%d'", id));
		}
		return m_FontsById[id];
	}
	
	/**
	 * test if a font with a unique name does exist
	 * Params:
	 *		pName = the name to search for
	 * Returns: true if existing, false otherwise
	 */
	bool DoesFontExist(rcstring pName){
		return m_Fonts.exists(pName);
	}
	
	///ditto
	bool DoesFontExist(uint id){
		return m_FontsById.exists(id);
	}
	
	/**
	 * loads the standard charset from a file
	 */
	static void LoadCharsToLoad(string pFilename){
		auto f = new RawFile(pFilename,"rb");
		if(!f.isOpen()){
			throw New!FileException(format("Couldn't open file '%s' for reading", pFilename));
		}
		wchar buf;
		f.read(buf);
		while(f.read(buf) == 1){
			m_CharsToLoad ~= buf;
		}
		f.close();
	}
	
	/**
	 * loads additional characters into all existing fonts
	 */
	static void AddCharsToAllFonts(wchar[] pAdditionalChars){
		foreach(e;m_Fonts){
			e.AddChars(pAdditionalChars);
		}
	}
	
	/**
	 * gets the maximum height of the font
	 */
	int GetMaxFontHeight() const { return m_MaxHeight; }
	
	/**
	 * gets the font texture
	 */
	Texture2D GetFontTexture(){
		return m_FontTexture;
	}
	
}
