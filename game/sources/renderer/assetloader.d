module renderer.assetloader;

import base.renderer;
import renderer.renderer;
import renderer.texture2d;
import renderer.cubetexture;
import renderer.xmlshader;
import renderer.shader;
import renderer.model;
import renderer.messages;
import renderer.sprite;
import thBase.container.hashmap;
import thBase.container.queue;
import thBase.container.vector;
import core.thread;
import modeltypes;


class AssetLoader : IAssetLoader {
private:
	Renderer m_Renderer;
	Hashmap!(rcstring, Texture2D) m_modelTextures;
	XmlShader m_DepthShader;
	XmlShader m_GrayShader;
	XmlShader m_TextureShader;
	XmlShader m_TextureSpecShader;
	XmlShader m_TextureNormalSpecShader;
	XmlShader m_TextureNormalShader;
	XmlShader m_TextureIlluShader;
	XmlShader m_TextureSpecIlluShader;
	XmlShader m_TextureNormalIlluShader;
	XmlShader m_TextureNormalSpecIlluShader;
	
  Hashmap!(rcstring, SpriteAtlas) m_SpriteAtlases;
  Vector!(Model) m_Models;
  Vector!(CubeTexture) m_CubeMaps;
  ThreadSafeRingBuffer!() m_MessageQueue;
	
	Material m_ShadowMaterial;
	
public:
	XmlShader m_SkyBoxShader;
	
	this(Renderer renderer){
    m_MessageQueue = New!(typeof(m_MessageQueue))(1024);
    m_SpriteAtlases = New!(typeof(m_SpriteAtlases))();
    m_modelTextures = New!(typeof(m_modelTextures))();
    m_Models = New!(typeof(m_Models))();
    m_CubeMaps = New!(typeof(m_CubeMaps))();
		m_Renderer = renderer;
		
		m_DepthShader = renderer.CreateXmlShader();
		m_DepthShader.Load(_T("shader/depth.xml"));
		m_DepthShader.Upload();
		
		m_ShadowMaterial = New!Material();
		m_ShadowMaterial.SetShader(m_DepthShader.GetShader());
		
		m_GrayShader = renderer.CreateXmlShader();
		m_GrayShader.Load(_T("shader/textures.xml"));
		m_GrayShader.SetName(_T("no texture shader"));
		m_GrayShader.Upload();
		
		
		m_TextureShader = renderer.CreateXmlShader();
		m_TextureShader.AddSource("#define DIFFUSE_MAP",Shader.ShaderType.FRAGMENT_SHADER);
		m_TextureShader.Load(_T("shader/textures.xml"));
		m_TextureShader.SetName(_T("diffuse texture shader"));
		m_TextureShader.Upload();
		
		
		m_TextureSpecShader = renderer.CreateXmlShader();
		m_TextureSpecShader.AddSource("#define DIFFUSE_MAP\n#define SPECULAR_MAP",Shader.ShaderType.FRAGMENT_SHADER);
		m_TextureSpecShader.Load(_T("shader/textures.xml"));
		m_TextureSpecShader.SetName(_T("diffuse sepcular texture shader"));
		m_TextureSpecShader.Upload();
		
		
		m_TextureNormalSpecShader = renderer.CreateXmlShader();
		m_TextureNormalSpecShader.AddSource("#define DIFFUSE_MAP\n#define NORMAL_MAP\n#define SPECULAR_MAP",
											Shader.ShaderType.FRAGMENT_SHADER);
		m_TextureNormalSpecShader.Load(_T("shader/textures.xml"));
		m_TextureNormalSpecShader.SetName(_T("diffuse normal specular texture shader"));
		m_TextureNormalSpecShader.Upload();
		
		
		m_TextureNormalShader = renderer.CreateXmlShader();
		m_TextureNormalShader.AddSource("#define DIFFUSE_MAP\n#define NORMAL_MAP",
										Shader.ShaderType.FRAGMENT_SHADER);
		m_TextureNormalShader.Load(_T("shader/textures.xml"));
		m_TextureNormalShader.SetName(_T("diffuse normal texture shader"));
		m_TextureNormalShader.Upload();
		
		
		m_TextureIlluShader = renderer.CreateXmlShader();
		m_TextureIlluShader.AddSource("#define DIFFUSE_MAP\n#define SELF_ILLU_MAP",
									  Shader.ShaderType.FRAGMENT_SHADER);
		m_TextureIlluShader.Load(_T("shader/textures.xml"));
		m_TextureIlluShader.SetName(_T("diffuse selfillu texture shader"));
		m_TextureIlluShader.Upload();
		
		
		m_TextureSpecIlluShader = renderer.CreateXmlShader();
		m_TextureSpecIlluShader.AddSource("#define DIFFUSE_MAP\n#define SELF_ILLU_MAP\n#define SPECULAR_MAP",
									  Shader.ShaderType.FRAGMENT_SHADER);
		m_TextureSpecIlluShader.Load(_T("shader/textures.xml"));
		m_TextureSpecIlluShader.SetName(_T("diffuse specular selfillu texture shader"));
		m_TextureSpecIlluShader.Upload();
		
		
		m_TextureNormalIlluShader = renderer.CreateXmlShader();
		m_TextureNormalIlluShader.AddSource("#define DIFFUSE_MAP\n#define SELF_ILLU_MAP\n#define NORMAL_MAP",
									  Shader.ShaderType.FRAGMENT_SHADER);
		m_TextureNormalIlluShader.Load(_T("shader/textures.xml"));
		m_TextureNormalIlluShader.SetName(_T("diffuse normal selfillu texture shader"));
		m_TextureNormalIlluShader.Upload();
		

		m_TextureNormalSpecIlluShader = renderer.CreateXmlShader();
		m_TextureNormalSpecIlluShader.AddSource("#define DIFFUSE_MAP\n#define SELF_ILLU_MAP\n#define NORMAL_MAP\n#define SPECULAR_MAP",
									  Shader.ShaderType.FRAGMENT_SHADER);
		m_TextureNormalSpecIlluShader.Load(_T("shader/textures.xml"));
		m_TextureNormalSpecIlluShader.SetName(_T("diffuse normal specular selfillu texture shader"));
		m_TextureNormalSpecIlluShader.Upload();
		
		m_SkyBoxShader = renderer.CreateXmlShader();
		m_SkyBoxShader.Load(_T("shader/skybox.xml"));
		m_SkyBoxShader.Upload();
	}

  ~this()
  {
    m_Renderer.DeleteXmlShader(m_SkyBoxShader);
    m_Renderer.DeleteXmlShader(m_TextureNormalIlluShader);
    m_Renderer.DeleteXmlShader(m_TextureNormalSpecIlluShader);
    m_Renderer.DeleteXmlShader(m_TextureSpecIlluShader);
    m_Renderer.DeleteXmlShader(m_TextureIlluShader);
    m_Renderer.DeleteXmlShader(m_TextureNormalShader);
    m_Renderer.DeleteXmlShader(m_TextureNormalSpecShader);
    m_Renderer.DeleteXmlShader(m_TextureSpecShader);
    m_Renderer.DeleteXmlShader(m_TextureShader);
    m_Renderer.DeleteXmlShader(m_GrayShader);
    Delete(m_ShadowMaterial);
    m_Renderer.DeleteXmlShader(m_DepthShader);
    Delete(m_MessageQueue);

    foreach(texture; m_modelTextures.values)
    {
      m_Renderer.DeleteTexture2D(texture);
    }
    Delete(m_modelTextures);

    foreach(atlas; m_SpriteAtlases.values)
    {
      m_Renderer.DeleteTexture2D(atlas.texture);
      Delete(atlas);
    }
    Delete(m_SpriteAtlases);

    foreach(model; m_Models)
    {
      for(int i=0;i<model.GetNumMaterials();i++){	
        auto mat = model.GetMaterial(1, i);
        Delete(mat);
      }
      Delete(model);
    }
    Delete(m_Models);

    foreach(cubeMap; m_CubeMaps)
    {
      Delete(cubeMap);
    }
    Delete(m_CubeMaps);
  }
	
	override shared(IModel) LoadModel(rcstring path) shared {
    m_Renderer.loadingQueue.enqueue(MsgLoadModel(path, m_MessageQueue));
		
    BaseMessage *msg;
    while( (msg = m_MessageQueue.tryGet!BaseMessage()) is null)
    {
      Thread.sleep(dur!("msecs")(1));
    }
    debug 
    {
      if(msg.type !is typeid(MsgLoadingModelDone))
      {
        auto err = format("recieved invalid message of type %s", msg.type.toString()[]);
        assert(0, err[]);
      }
    }
    
    auto result = (cast(MsgLoadingModelDone*)msg).model;
    m_MessageQueue.skip!MsgLoadingModelDone();

		if(result is null){
			throw New!RCException(format("Error loading model %s", path[]));
		}
		return result;
	}
	
	IModel DoLoadModel(rcstring path) {
		//Load the model from the file
		Model model = m_Renderer.CreateModel();
    scope(failure) Delete(model);
		model.LoadFile(path);
		model.SetNumMaterialSets(2);
		
		// load textures and create materials for the model
		foreach(size_t i, matInfo; model.GetMaterialInfo())
    {
			model.SetMaterial(0,i,m_ShadowMaterial);
			
			auto mat = New!Material();
			mat.SetShader(m_GrayShader.GetShader());
			mat.SetTexture(m_Renderer.shadowMap, 4);
			model.SetMaterial(1, i, mat);
			
			foreach(ref t; matInfo.textures){
        auto filename = rcstring(t.file);
				if(t.semantic == TextureType.DIFFUSE){
					debug base.logger.info("Adding diffuse map %s", t.file);
					if(!m_modelTextures.exists(filename)){
						auto texture = m_Renderer.CreateTexture2D(filename, ImageCompression.AUTO);
						texture.GetImageData().LoadFromFile(filename, ImageCompression.AUTO);
						texture.UploadImageData(Texture2D.Options.LINEAR | Texture2D.Options.MIPMAPS | Texture2D.Options.NO_LOCAL_DATA);
						m_modelTextures[filename] = texture;
					}
					mat.SetTexture(m_modelTextures[filename], 0);
					if(mat.GetShader() is m_GrayShader.GetShader())
						mat.SetShader(m_TextureShader.GetShader());
				}
				
				if(t.semantic == TextureType.HEIGHT){
					debug base.logger.info("Adding bump map %s", t.file);
					if(!m_modelTextures.exists(filename)){
						auto texture = m_Renderer.CreateTexture2D(filename, ImageCompression.AUTO);
						texture.GetImageData().LoadFromFile(filename, ImageCompression.AUTO);
						texture.UploadImageData(Texture2D.Options.LINEAR | Texture2D.Options.MIPMAPS | Texture2D.Options.NO_LOCAL_DATA);
						m_modelTextures[filename] = texture;
					}
					mat.SetTexture(m_modelTextures[filename], 1);
					if(mat.GetShader() is m_TextureSpecShader.GetShader())
						mat.SetShader(m_TextureNormalSpecShader.GetShader());
					else if(mat.GetShader() is m_TextureIlluShader.GetShader())
						mat.SetShader(m_TextureNormalIlluShader.GetShader());
					else if(mat.GetShader() is m_TextureSpecIlluShader.GetShader())
						mat.SetShader(m_TextureNormalSpecIlluShader.GetShader());
					else
						mat.SetShader(m_TextureNormalShader.GetShader());
				}
				
				if(t.semantic == TextureType.SPECULAR){
					debug base.logger.info("Adding specular map %s", t.file);
					if(!m_modelTextures.exists(filename)){
						auto texture = m_Renderer.CreateTexture2D(filename, ImageCompression.AUTO);
						texture.GetImageData().LoadFromFile(filename, ImageCompression.AUTO);
						texture.UploadImageData(Texture2D.Options.LINEAR | Texture2D.Options.MIPMAPS | Texture2D.Options.NO_LOCAL_DATA);
						m_modelTextures[filename] = texture;
					}
					mat.SetTexture(m_modelTextures[filename], 2);
					if(mat.GetShader() is m_TextureNormalShader.GetShader())
						mat.SetShader(m_TextureNormalSpecShader.GetShader());
					else if(mat.GetShader() is m_TextureIlluShader.GetShader())
						mat.SetShader(m_TextureSpecIlluShader.GetShader());
					else
						mat.SetShader(m_TextureSpecShader.GetShader());
				}
				
				if(t.semantic == TextureType.EMISSIVE){
					debug base.logger.info("Adding self illu map %s", t.file);
					if(!m_modelTextures.exists(filename)){
						auto texture = m_Renderer.CreateTexture2D(filename, ImageCompression.AUTO);
						texture.GetImageData().LoadFromFile(filename, ImageCompression.AUTO);
						texture.UploadImageData(Texture2D.Options.LINEAR | Texture2D.Options.MIPMAPS | Texture2D.Options.NO_LOCAL_DATA);
						m_modelTextures[filename] = texture;
					}
					mat.SetTexture(m_modelTextures[filename],3);
					if(mat.GetShader() is m_TextureShader.GetShader())
						mat.SetShader(m_TextureIlluShader.GetShader());
					else if(mat.GetShader() is m_TextureSpecShader.GetShader())
						mat.SetShader(m_TextureSpecIlluShader.GetShader());
					else if(mat.GetShader() is m_TextureNormalSpecShader.GetShader())
						mat.SetShader(m_TextureNormalSpecIlluShader.GetShader());
					else if(mat.GetShader() is m_TextureNormalShader.GetShader())
						mat.SetShader(m_TextureNormalIlluShader.GetShader());
					else
						mat.SetShader(m_TextureIlluShader.GetShader());
				}
			}
			debug base.logger.info("final shader %s", mat.GetShader().GetName()[]);
		}
		model.GenerateMeshes();
    m_Models.push_back(model);
		return model;
	}
	
	override shared(ITexture) LoadCubeMap(rcstring positive_x_path, rcstring negative_x_path,
										  rcstring positive_y_path, rcstring negative_y_path,
										  rcstring positive_z_path, rcstring negative_z_path) shared
	{
    m_Renderer.loadingQueue.enqueue(MsgLoadCubeMap(positive_x_path,negative_x_path,
                                                   positive_y_path,negative_y_path,
                                                   positive_z_path,negative_z_path,
                                                   m_MessageQueue));

    BaseMessage *msg;
    while( (msg = m_MessageQueue.tryGet!BaseMessage()) is null)
    {
      Thread.sleep(dur!("msecs")(1));
    }
		
    debug {
      if(msg.type !is typeid(MsgLoadingCubeMapDone))
      {
        auto err = format("recieved inavlid message of type %s", msg.type.toString()[]);
        assert(0, err[]);
      }
    }

		shared(ITexture) result = (cast(MsgLoadingCubeMapDone*)msg).texture;
    m_MessageQueue.skip!MsgLoadingCubeMapDone();

		if(result is null){
			throw New!RCException(_T("Error loading CubeMap"));
		}
		return result;		
	}
	
	ITexture DoLoadCubeMap(ref rcstring[6] paths)
	{
		CubeTexture texture = New!CubeTexture(paths[0],m_Renderer,ImageCompression.AUTO);
    m_CubeMaps.push_back(texture);
		foreach(i,data;texture.GetData()){
			data.LoadFromFile(paths[i],ImageCompression.AUTO);
		}
		texture.UploadImageData(CubeTexture.Options.LINEAR | 
								CubeTexture.Options.MIPMAPS |
								CubeTexture.Options.NO_LOCAL_DATA);
		return texture;
	}
	
	override shared(ISpriteAtlas) LoadSpriteAtlas(rcstring path) shared {
    m_Renderer.loadingQueue.enqueue(MsgLoadSpriteAtlas(path, m_MessageQueue));

    BaseMessage *msg;
    while( (msg = m_MessageQueue.tryGet!BaseMessage()) is null)
    {
      Thread.sleep(dur!("msecs")(1));
    }

    debug {
      if(msg.type !is typeid(MsgLoadingSpriteAtlasDone))
      {
        auto err = format("invalid message of type %s", msg.type.toString()[]);
        assert(0, err[]);
      }
    }
		
		shared(ISpriteAtlas) result = (cast(MsgLoadingSpriteAtlasDone*)msg).atlas;
    m_MessageQueue.skip!MsgLoadingSpriteAtlasDone();

		if(result is null){
			throw New!RCException(_T("Error loading sprite atlas"));
		}
		return result;
	}
	
	ISpriteAtlas DoLoadSpriteAtlas(rcstring path){
		if(m_SpriteAtlases.exists(path)){
			return m_SpriteAtlases[path];
		}
		auto texture = m_Renderer.CreateTexture2D(path,ImageCompression.AUTO);
		texture.GetImageData().LoadFromFile(path,ImageCompression.AUTO);
		texture.UploadImageData(Texture2D.Options.LINEAR | Texture2D.Options.MIPMAPS | Texture2D.Options.NO_LOCAL_DATA |
								Texture2D.Options.CLAMP_S | Texture2D.Options.CLAMP_T);
		
		auto result = m_Renderer.CreateSpriteAtlas(texture);
		m_SpriteAtlases[path] = result;
		return result;
	}
}
