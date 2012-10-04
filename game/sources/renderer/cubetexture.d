module renderer.cubetexture;

import renderer.texture;
import renderer.imagedata2d;
import renderer.opengl;
import base.all;
import core.stdc.stdlib;
import renderer.internal;
import thBase.math;

class CubeTexture : ITextureInternal {
public:
	enum Options : short {
		LINEAR			= 0x001, ///use linear filtering
		NEAREST 		= 0x002, ///use nearest filtering
		MIPMAPS 		= 0x004, ///generate mipmaps
		NO_LOCAL_DATA 	= 0x008 ///do not hold data in ram
	}
	
private:
	rcstring 				m_Name;
	ImageData2D[6] 		m_Data;
	uint 				m_TextureId = 0;
	IRendererInternal	m_Renderer;
	ImageCompression	m_Compression;
	int					m_UploadedDataSize = 0;
	__gshared immutable(gl.GLenum)[] CUBE_FACE = [gl.TEXTURE_CUBE_MAP_POSITIVE_X,
							                                  gl.TEXTURE_CUBE_MAP_NEGATIVE_X,
							                                  gl.TEXTURE_CUBE_MAP_POSITIVE_Y,
							                                  gl.TEXTURE_CUBE_MAP_NEGATIVE_Y,
						                                    gl.TEXTURE_CUBE_MAP_POSITIVE_Z,
							                                  gl.TEXTURE_CUBE_MAP_NEGATIVE_Z];
	
	void SetTextureOptions(ushort pOptions) const {
		if(pOptions & Options.MIPMAPS){
			gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.GENERATE_MIPMAP, gl.TRUE);
			if(pOptions & Options.LINEAR){
				gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
				gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
			}
			else{
				gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.NEAREST_MIPMAP_NEAREST);	// Linear Filtered
				gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.NEAREST);	// Linear Filtered
			}
		}
		else{
			if(pOptions & Options.LINEAR){
				gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
				gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
			}
			else{
				gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.NEAREST);	// Linear Filtered
				gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.NEAREST);	// Linear Filtered
			}
		}
		
		gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
		gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
		gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_EDGE);
	}
	
	static class FreeResources {
		uint m_TextureId;
		
		this(uint textureId){
			m_TextureId = textureId;
		}
		
		new(size_t sz){
			return malloc(sz);
		}
		
		void destroy(){
			
			free(cast(void*)this);
		}
	}
	
public:
	this(rcstring pName, IRendererInternal pRenderer, ImageCompression compression){
		m_Renderer = pRenderer;
		m_Name = pName;
		foreach(ref data;m_Data){
			data = New!ImageData2D(StdAllocator.globalInstance);
		}
	}
	
	~this(){
    foreach(data; m_Data)
    {
      Delete(data);
    }
		m_Renderer.addTextureMemoryAmount(-m_UploadedDataSize);
    gl.DeleteTextures(1,&m_TextureId);
	}
	
	/**
	 * Upload stored image data to the graphics card
	 * Params:
	 *		pOptions = options logical or'd 
	 */
	void UploadImageData(ushort pOptions)
	in
	{
    debug {
		  foreach(i,data;m_Data){
        if(data.empty())
        {
          auto err = format("Cube face %d has no data",i);
          assert(0, err[]);
        }
		  }
    }
	}
	body 
	{
		gl.GenTextures(1, &m_TextureId);
		gl.BindTexture(gl.TEXTURE_CUBE_MAP, m_TextureId);
		
		SetTextureOptions(pOptions);
	
    m_UploadedDataSize = 0;
		foreach(i, data;m_Data){
      if(data.isCompressed)
      {
        size_t divisor = 1;
        foreach(size_t level, ref mipmap; data.GetData())
        {
          gl.CompressedTexImage2D(CUBE_FACE[i], level, data.GetFormat(), max(1, data.GetWidth() / divisor), max(1, data.GetHeight() / divisor), 0, mipmap.length, mipmap.ptr);

          debug{
            gl.ErrorCode error = gl.GetError();
            if(error != gl.ErrorCode.NO_ERROR)
            {
              auto msg = format("Error uploading face %d mipmap %d of texture '%s': %s", i, level, m_Name[], gl.TranslateError(error));
              assert(0, msg[]);
            }
          }

          m_UploadedDataSize += mipmap.length;
          divisor *= 2;
        }
      }
      else
      {
        size_t divisor = 1;
        foreach(size_t level, ref mipmap; data.GetData())
        {
          gl.TexImage2D(CUBE_FACE[i], level, data.GetFormat(), max(1, data.GetWidth() / divisor), max(1, data.GetHeight() / divisor), 0, data.GetBaseFormat(), data.GetComponent(), mipmap.ptr);

          debug{
            gl.ErrorCode error = gl.GetError();
            if(error != gl.ErrorCode.NO_ERROR)
            {
              auto msg = format("Error uploading face %d mipmap %d of texture '%s': %s", i, level, m_Name[], gl.TranslateError(error));
              assert(0, msg[]);
            }
          }

          divisor *= 2;
        }

			  if(m_Compression == ImageCompression.AUTO 
			     && gl.isSupported(gl.Extensions.GL_ARB_texture_compression) )
			  {
				  int compressed = 0;
				  gl.GetTexLevelParameteriv(CUBE_FACE[i],0,gl.TEXTURE_COMPRESSED_ARB,&compressed);
				  if(compressed > 0){
					  int size;
					  gl.GetTexLevelParameteriv(CUBE_FACE[i],0,gl.TEXTURE_COMPRESSED_IMAGE_SIZE_ARB,&size);
					  m_UploadedDataSize += size;
				  }
				  else {
					  m_UploadedDataSize += data.GetData().length;
				  }
			  }
			  else {
				  m_UploadedDataSize += data.GetData().length;
			  }
      }
		}
		m_Renderer.addTextureMemoryAmount(m_UploadedDataSize);
		if(pOptions & Options.NO_LOCAL_DATA){
			foreach(data; m_Data){
				data.Free();
			}
		}
		if(pOptions & Options.MIPMAPS && m_Data[0].GetData().length == 1)
			gl.GenerateMipmap(gl.TEXTURE_CUBE_MAP);
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
		gl.BindTexture(gl.TEXTURE_CUBE_MAP, m_TextureId);
	}
	
	rcstring GetName() { return m_Name; } ///gets the name of the texture
	uint GetTextureId() const { return m_TextureId; } ///Gets the OpenGL texture id
	
	ImageData2D[] GetData(){return m_Data;}
}