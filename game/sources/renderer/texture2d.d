module renderer.texture2d;

import renderer.texture;
import renderer.opengl;
import renderer.imagedata2d;
import renderer.openglex;
import core.stdc.stdlib;
import base.all;
import renderer.internal;
import thBase.math;
import thBase.casts;

/**
 * Wrapper class for grahpics api 2D textures
 */
class Texture2D : ITextureInternal {
public:
	/**
	 * various options for texture operations
	 */
	enum Options : ushort {
		LINEAR			= 0x001, ///use linear filtering
		NEAREST 		= 0x002, ///use nearest filtering
		CLAMP_S			= 0x004, ///clamp s coordinates
		CLAMP_T			= 0x008, ///clamp t coordinates
		MIPMAPS 		= 0x010, ///generate mipmaps
		NO_LOCAL_DATA 	= 0x020, ///do not hold data in ram
		NO_VRAM_DATA 	= 0x040, ///do not hold data in vram
		MIRROR_S		= 0x080, ///mirror s coordinates
		MIRROR_T		= 0x100, ///mirror t coordinates
	};
private:
	rcstring 			m_Name;
	ImageData2D 	m_Data;
	uint 			m_TextureId = 0;
	IRendererInternal m_Renderer;
	int				m_UploadedMemorySize = 0;
	ImageCompression m_Compression;
	
	void SetTextureOptions(ushort pOptions) const {
		if(pOptions & Options.MIPMAPS){
      if(m_Data.GetData().length == 1)
			  gl.TexParameteri(gl.TEXTURE_2D, gl.GENERATE_MIPMAP, gl.TRUE);
      else
        gl.TexParameteri(gl.TEXTURE_2D, gl.GENERATE_MIPMAP, gl.FALSE);
			if(pOptions & Options.LINEAR){
				gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
				gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
			}
			else{
				gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST_MIPMAP_NEAREST);	// Linear Filtered
				gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);	// Linear Filtered
			}
		}
		else{
			if(pOptions & Options.LINEAR){
				gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
				gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
			}
			else{
				gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);	// Linear Filtered
				gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);	// Linear Filtered
			}
		}
		
		if(pOptions & Options.CLAMP_S)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
		else if(pOptions & Options.MIRROR_S)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.MIRRORED_REPEAT);
		else
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
		
		if(pOptions & Options.CLAMP_T)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
		else if(pOptions & Options.MIRROR_T)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.MIRRORED_REPEAT);
		else
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
	}

public:
	/**
	 * Constructor
	 * Params:
	 *		pName = name of the newly created texture for debugging
	 */
	this(rcstring pName, IRendererInternal pRenderer, ImageCompression compression){
		m_Name = pName;
		m_Data = New!ImageData2D(StdAllocator.globalInstance);
		m_Renderer = pRenderer;
		m_Compression = compression;
	}
	
	~this(){
    Delete(m_Data);
		m_Renderer.addTextureMemoryAmount(-m_UploadedMemorySize);
    gl.DeleteTextures(1, &m_TextureId);
	}
	
	/**
	 * Upload stored image data to the graphics card
	 * Params:
	 *		pOptions = options logical or'd 
	 */
	void UploadImageData(ushort pOptions)
	in
	{
		assert(!m_Data.empty(),"No data to upload");
	}
	body 
	{
		int maxTexSize; 
		gl.GetIntegerv(gl.MAX_TEXTURE_SIZE, &maxTexSize);
		if(m_Data.GetWidth() > maxTexSize || m_Data.GetHeight() > maxTexSize){
			throw New!OpenGLException(format("Texture %s is to big for the graphics card", m_Name[]), false);
		}
		
		gl.GenTextures(1, &m_TextureId);
		gl.BindTexture(gl.TEXTURE_2D, m_TextureId);
		
		SetTextureOptions(pOptions);

    if(m_Data.isCompressed)
    {
      if(!gl.isSupported(gl.Extensions.GL_ARB_texture_compression) ||
         !gl.isSupported(gl.Extensions.GL_EXT_texture_compression_s3tc))
      {
        throw New!RCException(format("Can not load compressed texture '%s' because extensions are not supported", m_Name[]));
      }
      assert(m_Compression != ImageCompression.NONE, "can't uncompress compressed data");
      size_t divisor = 1;
      m_UploadedMemorySize = 0;
      foreach(size_t level, ref mipmap; m_Data.GetData())
      {
        gl.CompressedTexImage2D(gl.TEXTURE_2D, int_cast!int(level), m_Data.GetFormat(), max(1, m_Data.GetWidth() / divisor), max(1, m_Data.GetHeight() / divisor), 0, mipmap.length, mipmap.ptr);

        debug{
          gl.ErrorCode error = gl.GetError();
          if(error != gl.ErrorCode.NO_ERROR)
          {
            auto msg = format("Error uploading mipmap %d of texture '%s': %s", level, m_Name[], gl.TranslateError(error));
            assert(0, msg[]);
          }
        }

        m_UploadedMemorySize += mipmap.length;
        divisor *= 2;
      }
    }
    else
    {
      size_t divisor = 1;
      foreach(size_t level, ref mipmap; m_Data.GetData())
      {
		    gl.TexImage2D(gl.TEXTURE_2D, int_cast!int(level), m_Data.GetFormat(), max(1, m_Data.GetWidth() / divisor), max(1, m_Data.GetHeight() / divisor), 0, m_Data.GetBaseFormat(), m_Data.GetComponent(), mipmap.ptr);

        debug{
          gl.ErrorCode error = gl.GetError();
          if(error != gl.ErrorCode.NO_ERROR)
          {
            auto msg = format("Error uploading mipmap %d of texture '%s': %s", level, m_Name[], gl.TranslateError(error));
            assert(0, msg[]);
          }
        }

        divisor *= 2;
      }
		}



    if(m_Data.isCompressed)
    {
    }
		else if(m_Compression == ImageCompression.AUTO 
		   && gl.isSupported(gl.Extensions.GL_ARB_texture_compression) )
		{
			int compressed = 0;
			gl.GetTexLevelParameteriv(gl.TEXTURE_2D, 0, gl.TEXTURE_COMPRESSED_ARB, &compressed);
			if(compressed > 0){
				int size;
				gl.GetTexLevelParameteriv(gl.TEXTURE_2D, 0, gl.TEXTURE_COMPRESSED_IMAGE_SIZE_ARB, &size);
				m_UploadedMemorySize = size;
			}
			else {
				m_UploadedMemorySize =  int_cast!int(m_Data.GetData().length);
			}
		}
		else {
			m_UploadedMemorySize = int_cast!int(m_Data.GetData().length);
		}

		m_Renderer.addTextureMemoryAmount(m_UploadedMemorySize);
		if(pOptions & Options.NO_LOCAL_DATA)
			m_Data.Free();
	}
	
	/**
	 * Creates a empty texture
	 * Params:
	 *		pWidth = width
	 *		pHeight = height
	 *		pFormat	= format
	 *		pOptions = or'd options from Options enum
	 **/
	void CreateEmpty(size_t pWidth, size_t pHeight, ImageFormat pFormat, ushort pOptions)
	in
	{
		assert(pWidth != 0,"Width may not be 0");
		assert(pHeight != 0,"Height may not be 0");
	}
	body
	{
		if(!(pOptions & Options.NO_LOCAL_DATA)){
			m_Data.CreateEmpty(pWidth, pHeight, pFormat, m_Compression);
		}
		else {
			m_Data.SetData(null, ImageData2D.image_data_t(), pWidth, pHeight, pFormat, m_Compression);
		}
		
		if(!(pOptions & Options.NO_VRAM_DATA)){
			gl.GenTextures(1,&m_TextureId);
			gl.BindTexture(gl.TEXTURE_2D,m_TextureId);
			
			SetTextureOptions(pOptions);

      void* data = null;
      if(m_Data.GetData().length > 0)
      {
        // BUG 11311
        // data = m_Data.GetData[0].ptr;
        auto temp = m_Data.GetData();
        data = temp[0].ptr;
      }
			
			gl.TexImage2D(gl.TEXTURE_2D, 0, m_Data.GetFormat(), m_Data.GetWidth(), m_Data.GetHeight(), 0, m_Data.GetBaseFormat(), m_Data.GetComponent(), data);
		}
		
		if(m_Compression == ImageCompression.AUTO 
		   && gl.isSupported(gl.Extensions.GL_ARB_texture_compression) )
		{
			int compressed = 0;
			gl.GetTexLevelParameteriv(gl.TEXTURE_2D,0,gl.TEXTURE_COMPRESSED_ARB,&compressed);
			if(compressed > 0){
				int size;
				gl.GetTexLevelParameteriv(gl.TEXTURE_2D,0,gl.TEXTURE_COMPRESSED_IMAGE_SIZE_ARB,&size);
				m_UploadedMemorySize = size;
			}
			else {
				m_UploadedMemorySize = int_cast!int(m_Data.GetSizeOfComponent() * m_Data.GetNumberOfComponents() * m_Data.GetWidth() * m_Data.GetHeight());
			}
		}
		else {
			m_UploadedMemorySize = int_cast!int(m_Data.GetSizeOfComponent() * m_Data.GetNumberOfComponents() * m_Data.GetWidth() * m_Data.GetHeight());
		}
		m_Renderer.addTextureMemoryAmount(m_UploadedMemorySize);
	}
	
	/**
	 * Reuploads the local data to the gpu
	 */ 
	void Reupload()
	in
	{
		assert(m_Data !is null,"No local data to upload");
	}
	body {
		gl.BindTexture(gl.TEXTURE_2D, m_TextureId);
    if(m_Data.isCompressed)
    {
      size_t divisor = 1;
      foreach(size_t level, ref mipmap; m_Data.GetData())
      {
        gl.CompressedTexImage2D(gl.TEXTURE_2D, int_cast!int(level), m_Data.GetFormat(), max(1, m_Data.GetWidth() / divisor), max(1, m_Data.GetHeight() / divisor), 0, mipmap.length, mipmap.ptr);

        debug{
          gl.ErrorCode error = gl.GetError();
          if(error != gl.ErrorCode.NO_ERROR)
          {
            auto msg = format("Error re-uploading mipmap %d of texture '%s': %s", level, m_Name[], gl.TranslateError(error));
            assert(0, msg[]);
          }
        }

        divisor *= 2;
      }
    }
    else
    {
      size_t divisor = 1;
      foreach(size_t level, ref mipmap; m_Data.GetData())
      {
		    gl.TexImage2D(gl.TEXTURE_2D, int_cast!int(level), m_Data.GetFormat(), m_Data.GetWidth() / divisor, m_Data.GetHeight() / divisor, 0, m_Data.GetBaseFormat(), m_Data.GetComponent(), mipmap.ptr);

        debug{
          gl.ErrorCode error = gl.GetError();
          if(error != gl.ErrorCode.NO_ERROR)
          {
            auto msg = format("Error re-uploading mipmap %d of texture '%s': %s", level, m_Name[], gl.TranslateError(error));
            assert(0, msg[]);
          }
        }

        divisor *= 2;
      }
		}
	}
	
	/**
	 * Binds the texture to a gpu texture channel
	 * Params:
	 * 		pChannel = number of the channel to bind to, has to be 0 <= pChannel < 16 
	 */
	override void BindToChannel(int pChannel)
	in 
	{
		assert(pChannel >= 0 && pChannel < 16, "pChannel is out of range");
		assert(m_TextureId > 0,"texture not uploaded yet");
	}
	body
	{
		gl.ActiveTexture(cast(gl.GLenum)(gl.TEXTURE0 + pChannel));
		gl.BindTexture(gl.TEXTURE_2D, m_TextureId);
	}
	
	/**
	 * Downloads the texture from the gpu
	 */
	void DownloadImageData()
	in 
	{
		assert(m_TextureId != 0,"texture does not exist on gpu");
		assert(m_Data.GetData().length > 0,"no local storage to download to");
    assert(!m_Data.isCompressed, "can not download into compressed image data");
	}
	body {
		gl.BindTexture(gl.TEXTURE_2D, m_TextureId);
		gl.GetTexImage(gl.TEXTURE_2D, 0, m_Data.GetBaseFormat(), m_Data.GetComponent(), m_Data.GetData()[0].ptr);
	}
	
	size_t GetWidth() const { return m_Data.GetWidth(); } ///gets texture width
	size_t GetHeight() const { return m_Data.GetHeight(); } ///gets texture height
	rcstring GetName() { return m_Name; } ///gets the name of the texture
	ImageData2D GetImageData() { return m_Data; } ///gets the image data of the texture
	uint GetTextureId() const { return m_TextureId; } ///Gets the OpenGL texture id
	
};