module renderer.imagedata2d;

import renderer.opengl;
import renderer.sdl.image;
import renderer.sdl.main;

import core.stdc.stdlib;
import thBase.string;
import thBase.format;
import thBase.conv;
import thBase.dds;
import thBase.allocator;


import std.c.string;

/**
 * all aviable image formats
 */
enum ImageFormat : gl.GLenum {
	LUMINANCE8 = gl.LUMINANCE, ///1byte per pixel RGBA all the same
	LUMINANCE32F = gl.LUMINANCE32F_ARB,///1 float for RGBA
	LUMINANCE_ALPHA8 = gl.LUMINANCE_ALPHA,///1byte for RGB, 1 byte for alpha
	R16F = gl.R16F,///16 bit float for red channel
	R32F = gl.R32F,///32 bit float for red channel
	RGB8 = gl.RGB8,///ubyte for R, G and B channel
	RGB16 = gl.RGB16,///ushort for R, G and B channel
	RGB16F = gl.RGB16F,///16bit float for R, G and B channel
	RGB32F = gl.RGB32F,///32bit float for R, G and B channel
	RGBA8 = gl.RGBA8,///ubyte for R, G, B and Alpha channel
	RGBA16 = gl.RGBA16,///ushort for R, G, B and Alpha channel
	RGBA16F = gl.RGBA16F,///16 bit float for R, G, B and Alpha channel
	RGBA32F = gl.RGBA32F,///32 bit float for R, G, B and Alpha channel
	DEPTH16 = gl.DEPTH_COMPONENT16,///16 bit uint depth channel
	DEPTH24 = gl.DEPTH_COMPONENT24,///24 bit uint depth channel
	DEPTH32 = gl.DEPTH_COMPONENT32,///32 bit uint depth channel
	DEPTH24STENCIL = gl.DEPTH24_STENCIL8,///24 bit uint depth channel, ubyte stencil
	COMPRESSED_ALPHA = gl.COMPRESSED_ALPHA_ARB,            
	COMPRESSED_LUMINANCE = gl.COMPRESSED_LUMINANCE_ARB,    
	COMPRESSED_LUMINANCE_ALPHA = gl.COMPRESSED_LUMINANCE_ALPHA_ARB,  
	COMPRESSED_INTENSITY = gl.COMPRESSED_INTENSITY_ARB,        
	COMPRESSED_RGB = gl.COMPRESSED_RGB_ARB,              
	COMPRESSED_RGBA = gl.COMPRESSED_RGBA_ARB,
	COMPRESSED_RGB_DXT1 = gl.COMPRESSED_RGB_S3TC_DXT1_EXT,
	COMPRESSED_RGBA_DXT1 = gl.COMPRESSED_RGBA_S3TC_DXT1_EXT,
	COMPRESSED_RGBA_DXT3 = gl.COMPRESSED_RGBA_S3TC_DXT3_EXT,
	COMPRESSED_RGBA_DXT5 = gl.COMPRESSED_RGBA_S3TC_DXT5_EXT   
};

/**
 * Base image formats
 */
enum ImageBaseFormat : gl.GLenum {
	LUMINANCE = gl.LUMINANCE, ///1 channel mapped to RGBA
	LUMINANCE_ALPHA = gl.LUMINANCE_ALPHA,///1 channel mapped to RGB, 1 channel for Alpha
	R = gl.R,///1 channel R
	RGB = gl.RGB,///3 channel RGB
	RGBA = gl.RGBA,///4 channel RGBA
	DEPTH = gl.DEPTH_COMPONENT,///1 channel depth
	DEPTH_STENCIL = gl.DEPTH_STENCIL,///1 channel depth, 1 channel stencil
};

/**
 * Compression options
 */
enum ImageCompression : uint {
	NONE,
	AUTO,
  PRECOMPRESSED
}

/**
 * Image data storage formats
 */
enum ImageComponent : gl.GLenum {
	UNSIGNED_BYTE		= gl.UNSIGNED_BYTE, ///8 bit unsigned int
	UNSIGNED_SHORT		= gl.UNSIGNED_SHORT,///16 bit unsigned int
	UNSIGNED_INT		= gl.UNSIGNED_INT,///32 bit unsigned int
	UNSIGNED_INT_24_8	= gl.UNSIGNED_INT_24_8, ///32 bit unsigned int split into 24 bit unsigned int and 8 bit unsigned int
	FLOAT				= gl.FLOAT ///32 bit float
};

/**
 * Wrapper class for holding image data of any format
 */
class ImageData2D {
  alias RCArray!(ubyte, IAllocator) mipmap_data_t;
  alias RCArray!(mipmap_data_t, IAllocator) image_data_t;
private:
	size_t 			m_Width = 0,m_Height = 0;
	ImageFormat 	m_Format;
	ImageBaseFormat	m_BaseFormat;
	ImageComponent 	m_Component;
  image_data_t     m_Data;
  IAllocator  m_allocator = null;
	size_t			m_SizeOfComponent = 0;
	size_t			m_NumComponents = 0;
  bool m_isCompressed = false;
	
	void GetComponentSizes(ImageCompression compression){
		switch(m_Format){
			case ImageFormat.LUMINANCE8:
			  m_SizeOfComponent = 1;
			  m_NumComponents = 1;
			  m_Component = ImageComponent.UNSIGNED_BYTE;
			  m_BaseFormat = ImageBaseFormat.LUMINANCE;
			  if(compression == ImageCompression.AUTO 
				 && gl.isSupported(gl.Extensions.GL_ARB_texture_compression) ){
				  m_Format = ImageFormat.COMPRESSED_LUMINANCE;
			  }
        m_isCompressed = false;
			  break;
			case ImageFormat.LUMINANCE32F:
			  m_SizeOfComponent = 4;
			  m_NumComponents = 1;
			  m_Component = ImageComponent.FLOAT;
			  m_BaseFormat = ImageBaseFormat.LUMINANCE;
        m_isCompressed = false;
			  break;
			case ImageFormat.LUMINANCE_ALPHA8:
			  m_SizeOfComponent = 1;
			  m_NumComponents = 2;
			  m_Component = ImageComponent.UNSIGNED_BYTE;
			  m_BaseFormat = ImageBaseFormat.LUMINANCE_ALPHA;
			  if(compression == ImageCompression.AUTO 
				 && gl.isSupported(gl.Extensions.GL_ARB_texture_compression) ){
				  m_Format = ImageFormat.COMPRESSED_LUMINANCE_ALPHA;
			  }
        m_isCompressed = false;
			  break;
			case ImageFormat.R16F:
			case ImageFormat.R32F:
			  m_SizeOfComponent = 4;
			  m_NumComponents = 1;
			  m_Component =	ImageComponent.FLOAT;
			  m_BaseFormat = ImageBaseFormat.R;
        m_isCompressed = false;
			  break;
			case ImageFormat.RGB8:
			  m_SizeOfComponent = 1;
			  m_NumComponents = 3;
			  m_Component = ImageComponent.UNSIGNED_BYTE;
			  m_BaseFormat = ImageBaseFormat.RGB;
			  if(compression == ImageCompression.AUTO) {
				  if( gl.isSupported(gl.Extensions.GL_EXT_texture_compression_s3tc) ){
					  m_Format = ImageFormat.COMPRESSED_RGB_DXT1;
				  }
				  else if ( gl.isSupported(gl.Extensions.GL_ARB_texture_compression) ){
					  m_Format = ImageFormat.COMPRESSED_RGB;
				  }
			  }
        m_isCompressed = false;
			  break;
			case ImageFormat.RGB16:
			  m_SizeOfComponent = 2;
			  m_NumComponents = 3;
			  m_Component = ImageComponent.UNSIGNED_SHORT;
			  m_BaseFormat = ImageBaseFormat.RGB;
        m_isCompressed = false;
			  break;
			case ImageFormat.RGB16F:
			case ImageFormat.RGB32F:
			  m_SizeOfComponent = 4;
			  m_NumComponents = 3;
			  m_Component = ImageComponent.FLOAT;
			  m_BaseFormat = ImageBaseFormat.RGB;
        m_isCompressed = false;
			  break;
			case ImageFormat.RGBA8:
			  m_SizeOfComponent = 1;
			  m_NumComponents = 4;
			  m_Component = ImageComponent.UNSIGNED_BYTE;
			  m_BaseFormat = ImageBaseFormat.RGBA;
			  if(compression == ImageCompression.AUTO) {
				  if( gl.isSupported(gl.Extensions.GL_EXT_texture_compression_s3tc) ){
					  m_Format = ImageFormat.COMPRESSED_RGBA_DXT5;
				  }
				  else if ( gl.isSupported(gl.Extensions.GL_ARB_texture_compression) ){
					  m_Format = ImageFormat.COMPRESSED_RGBA;
				  }
			  }
        m_isCompressed = false;
			  break;
			case ImageFormat.RGBA16:
			  m_SizeOfComponent = 2;
			  m_NumComponents = 4;
			  m_Component = ImageComponent.UNSIGNED_SHORT;
			  m_BaseFormat = ImageBaseFormat.RGBA;
        m_isCompressed = false;
			  break;
			case ImageFormat.RGBA16F:
			case ImageFormat.RGBA32F:
			  m_SizeOfComponent = 4;
			  m_NumComponents = 4;
			  m_Component = ImageComponent.FLOAT;
			  m_BaseFormat = ImageBaseFormat.RGBA;
        m_isCompressed = false;
			  break;
			case ImageFormat.DEPTH16:
			  m_SizeOfComponent = 2;
			  m_NumComponents = 1;
			  m_Component = ImageComponent.UNSIGNED_SHORT;
			  m_BaseFormat = ImageBaseFormat.DEPTH;
        m_isCompressed = false;
			  break;
			case ImageFormat.DEPTH24:
			case ImageFormat.DEPTH32:
			  m_SizeOfComponent = 4;
			  m_NumComponents = 1;
			  m_Component = ImageComponent.UNSIGNED_INT;
			  m_BaseFormat = ImageBaseFormat.DEPTH;
        m_isCompressed = false;
			  break;
			case ImageFormat.DEPTH24STENCIL:
			  m_SizeOfComponent = 4;
			  m_NumComponents = 1;
			  m_Component = ImageComponent.UNSIGNED_INT_24_8;
			  m_BaseFormat = ImageBaseFormat.DEPTH_STENCIL;
        m_isCompressed = false;
			  break;
      case ImageFormat.COMPRESSED_RGBA_DXT1:
      case ImageFormat.COMPRESSED_RGBA_DXT3:
      case ImageFormat.COMPRESSED_RGBA_DXT5:
        m_SizeOfComponent = 1;
        m_NumComponents = 4;
        m_Component = ImageComponent.UNSIGNED_BYTE;
        m_BaseFormat = ImageBaseFormat.RGBA;
        m_isCompressed = true;
        break;
			default:
			  throw New!RCException(format("Invalid Format for '%s' ImageData2D", EnumToString(m_Format))); //,"renderer::ImageData2D::GetComponentSizes");
		}
	}
	
public:

  this(IAllocator allocator)
  {
    m_allocator = allocator;
  }

	~this(){
		if(m_Data.ptr !is null){
      assert(m_allocator !is null);
      m_allocator = null;
		}
	}
	
	/**
	 * Function to set data
	 * Params:
	 * 		pData = data to set, may not be null
	 * 		pWidth = width of the image data to set, hast to be > 0
	 * 	 	pHeight = height of the image data to set, hast to be > 0 
	 *		pFormat	= format of the image data to set 
	 */
	void SetData(IAllocator allocator, image_data_t pData, size_t pWidth, size_t pHeight, ImageFormat pFormat, ImageCompression compression)
	in
	{
		assert(pWidth > 0,"pWidth is 0");
		assert(pHeight > 0,"pHeight is 0");
	}
	body
	{
		m_Format = pFormat;
		GetComponentSizes(compression);
		m_Width = pWidth;
		m_Height = pHeight;
    m_allocator = allocator;
    m_Data = pData;
	}
	
	/**
	 * Creates empty image data
	 * Params:
	 *		pWidth = width of the data
	 *		pHeight = height of the data
	 *		pFormat = format of the data
	 */
	void CreateEmpty(size_t pWidth, size_t pHeight, ImageFormat pFormat, ImageCompression compression, IAllocator allocator = null)
	in 
	{
		assert(pWidth > 0, "pWidth is 0");
		assert(pHeight > 0, "pHeight is 0");
	}
	body
	{
    if(allocator is null)
      allocator = StdAllocator.globalInstance;
    m_allocator = allocator;
		m_Format = pFormat;
		GetComponentSizes(compression);
		m_Width = pWidth;
		m_Height = pHeight;
		size_t imageSize = m_Width * m_Height * m_NumComponents * m_SizeOfComponent;
    m_Data = image_data_t(1, m_allocator);
    m_Data[0] = mipmap_data_t(imageSize, m_allocator);
	}
	
	/**
	 * Inserts a image into this one
	 * Params:
	 *		pSrc = image to insert
	 *		pX = point to insert x coordinate
	 * 		pY = point to insert y coordinate
	 */ 
	void Insert(const(ImageData2D) pSrc, size_t pX, size_t pY, size_t mipmap = 0)
	in
	{
		assert(pSrc.m_Format == m_Format,"Can only insert image data of the same format");
		assert(pX + pSrc.m_Width <= m_Width,"Insert out of bounds on x axis");
		assert(pY + pSrc.m_Height <= m_Height,"Insert out of bounds on y axis");
		assert(m_Data.length > 0,"Image data to insert in has no data");
	}
	body 
	{
		size_t sizeOfPixel = m_NumComponents * m_SizeOfComponent;
		size_t sizeOfRow = m_Width * sizeOfPixel;

    auto dstData = m_Data[mipmap][];
		
		const(ubyte[]) srcData = pSrc.GetData()[mipmap][];
		size_t sizeOfSrcRow = pSrc.m_Width * sizeOfPixel;
		for(size_t y=0;y<pSrc.m_Height;y++){
			size_t dstIndex = (pY + y) * sizeOfRow + pX * sizeOfPixel;
			size_t srcIndex = y * sizeOfSrcRow;
			dstData[dstIndex..(dstIndex + sizeOfSrcRow)] = srcData[srcIndex..(srcIndex + sizeOfSrcRow)];
		}
	}
	
	/**
	 * Releases the internal data
	 */
	void Free()
	in
	{
    assert(m_allocator !is null);
	}
	body
	{
		m_Data = image_data_t();
		/*m_Width = 0;
		m_Height = 0;
		m_SizeOfComponent = 0;
		m_NumComponents = 0;*/		
	}
	
	/**
	 * Loads a image from a file
	 * Params:
	 *		pFilename = the file to load
	 */
	void LoadFromFile(rcstring pFilename, ImageCompression compression)
  in
  {
    assert(m_allocator !is null);
  }
	body {
    version(NO_OPENGL)
    {
      size_t size = 4 * 4;
      ubyte[] newData = (cast(ubyte*)(StdAllocator.globalInstance.AllocateMemory(ubyte.sizeof * size).ptr))[0..size];
      SetData(StdAllocator.globalInstance, newData, 2, 2, ImageFormat.RGBA8, compression);
    }
    else
    {
		  version(linux){
			  pFilename = pFilename.replace("\\","/");
		  }
      if(endsWith(pFilename, ".dds", CaseSensitive.no))
      {
        auto loader = AllocatorNew!DDSLoader(ThreadLocalStackAllocator.globalInstance, StdAllocator.globalInstance);
        scope(exit) AllocatorDelete(ThreadLocalStackAllocator.globalInstance, loader);

        loader.LoadFile(pFilename);
        if(loader.isCubemap)
        {
          throw New!RCException(format("Trying to load file '%s' which is a cubemap as 2d texture", pFilename[]));
        }

        if(loader.images.length > 1)
        {
          throw New!RCException(format("Trying to loader file '%s' which is a texture array of size %d as 2d texture", pFilename[], loader.images.length));
        }

        ImageFormat imgformat;
        
        switch(loader.dataFormat)
        {
          case DDSLoader.D3DFORMAT.DXT1:
            imgformat = ImageFormat.COMPRESSED_RGBA_DXT1;
            assert(compression != ImageCompression.NONE, "can not uncompress compressed dxt1 texture");
            break;
          case DDSLoader.D3DFORMAT.DXT3:
            imgformat = ImageFormat.COMPRESSED_RGBA_DXT3;
            assert(compression != ImageCompression.NONE, "can not uncompress compressed dxt3 texture");
            break;
          case DDSLoader.D3DFORMAT.DXT5:
            imgformat = ImageFormat.COMPRESSED_RGBA_DXT5;
            assert(compression != ImageCompression.NONE, "can not uncompress compressed dxt5 texture");
            break;
          default:
            throw New!RCException(format("Trying to load file %s which has unsupported format %s", pFilename[], EnumToString(loader.dataFormat)));
        }

        SetData(m_allocator, loader.images[0], loader.width, loader.height, imgformat, ImageCompression.PRECOMPRESSED);
      }
      else
      {
		    auto img = SDLImage.Load(toCString(pFilename));
		    if( img is null ){
			    char* error = SDL.GetError();
			    rcstring message = format("Couldn't load image from file '%s'", pFilename[]);
			    if(error !is null){
				    message ~= ": " ~ error[0..strlen(error)];
			    }
			    throw New!RCException(message);
		    }
		    if( img.format is null){
			    throw New!RCException(format("Loaded image '%s' does not have a pixel format", pFilename[]));
		    }
		    if( /*img.format.BitsPerPixel != 8 ||*/ (img.format.BytesPerPixel != 1 && img.format.BytesPerPixel != 3 && img.format.BytesPerPixel != 4)){
			    throw New!RCException(format("Loaded image '%s' does have a unsupported image format. BitsPerPixel '%d' BytesPerPixel '%d'", pFilename[], img.format.BitsPerPixel, img.format.BytesPerPixel));
		    }
		    size_t size = img.format.BytesPerPixel * img.width * img.height;
		    ubyte* oldData = cast(ubyte*)img.pixels;

        auto newImage = image_data_t(1, m_allocator);
        newImage[0] = mipmap_data_t(size, m_allocator);

		    ubyte[] newData = newImage[0][];
		    newData[0..size] = oldData[0..size];
		    if(img.format.Rshift > 0){ //dealing with BGR texture here
			    for(size_t i=0;i<size;i+=3){
				    auto temp = newData[i];
				    newData[i] = newData[i+2];
				    newData[i+2] = temp;
			    }
		    }
		    if(img.format.BytesPerPixel == 1){
			    SetData(m_allocator, newImage, img.width, img.height, ImageFormat.LUMINANCE8, compression);
		    }
		    else if(img.format.BytesPerPixel == 3){
			    SetData(m_allocator, newImage, img.width, img.height, ImageFormat.RGB8, compression);
		    }
		    else{
			    SetData(m_allocator, newImage, img.width, img.height, ImageFormat.RGBA8, compression);
		    }
      }
    }
	}
	
	const(image_data_t) GetData() const { return m_Data; } ///get internal data
	image_data_t GetData() { return m_Data; } ///get internal data 
	size_t GetWidth() const { return m_Width; } ///get width
	size_t GetHeight() const { return m_Height; } ///get height
	ImageFormat GetFormat() const { return m_Format; } ///get format
	ImageBaseFormat GetBaseFormat() const { return m_BaseFormat; } ///get base format
	ImageComponent GetComponent() const { return m_Component; } ///get component
	size_t GetSizeOfComponent() const { return m_SizeOfComponent; } ///get size of component
	size_t GetNumberOfComponents() const { return m_NumComponents; } ///get number of components (channels)
  @property final bool isCompressed() const { return m_isCompressed; }
	
	/**
	 * Checks if internal data is present or not
	 * Returns: true if there is no internal data, false otherwise
	 */ 
	bool empty() const { return (m_Data.length == 0); }
};
