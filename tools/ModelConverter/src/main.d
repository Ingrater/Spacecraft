import thBase.io;
import thBase.string;
import thBase.container.stack;
import thBase.container.hashmap;
import thBase.container.vector;
import thBase.policies.hashing;
import thBase.scoped;
import thBase.file;
import thBase.chunkfile;
import assimp.assimp;
import modeltypes;

struct MaterialTextureInfo
{
  uint id;
  TextureType semantic;
}

void Warning(string fmt, ...)
{
  StdOutPutPolicy put;
  formatDo(put, "Warning: ", [], null);
  formatDo(put, fmt, _arguments, _argptr);
  put.put('\r');
  put.put('\n');
  put.flush();
}

TextureType MapTextureType(aiTextureType type)
{
  final switch(type)
  {
    case aiTextureType.NONE:
      return TextureType.UNKOWN;
    case aiTextureType.DIFFUSE:
      return TextureType.DIFFUSE;
    case aiTextureType.SPECULAR:
      return TextureType.SPECULAR;
    case aiTextureType.EMISSIVE:
      return TextureType.EMISSIVE;
    case aiTextureType.HEIGHT:
      return TextureType.HEIGHT;
    case aiTextureType.NORMALS:
      return TextureType.NORMALS;
    case aiTextureType.LIGHTMAP:
      return TextureType.LIGHTMAP;
    case aiTextureType.REFLECTION:
      return TextureType.REFLECTION;
    default:
      return TextureType.UNKNOWN;
  }
}



void ProgressModel(string path)
{
  try
  {
		const(aiScene)* scene = Assimp.ImportFile(toCString(pFilename), 
                                              aiPostProcessSteps.CalcTangentSpace |
                                              aiPostProcessSteps.Triangulate |
                                              aiPostProcessSteps.JoinIdenticalVertices |
                                              aiPostProcessSteps.FlipUVs);// |
    //aiPostProcessSteps.MakeLeftHanded); // |
    //aiPostProcessSteps.PreTransformVertices );
		if(scene is null){
			throw New!FileException(format("Couldn't load model from file '%s'", pFilename[]));
		}

    scope(exit)
    {
      Assimp.ReleaseImport(scene);
      scene = null;
    }

    rcstring outputFilename = path[0..$-3];
    outputFilename ~= ".thModel";

    auto outFile = scopedRef!Chunkfile(New!Chunkfile(ouputFilename, Chunkfile.Operation.Write));

    outFile.startWriting("thModel", ModelFormatVersion.max);
    scope(exit) outFile.endWriting();

    auto textureFiles = scopedRef!(Hashmap!(string, uint, StringHashPolicy))(New!(Hashmap!(string, TextureInfo, StringHashPolicy))());
    auto materialTextures = scopedRef!(Vector!MaterialTextureInfo)(New!(Vector!MaterialTextureInfo)());

    // Textures
    {
      outFile.startWriteChunk("textures");
      scope(exit) outFile.endWriteChunk();

      auto textures = scopedRef!(Vector!string)(New!(Vector!string)());
      uint nextTextureId = 0;

      if(scene.mMaterials !is null)
      {

        //collect all textures from all materials
        for(size_t i=0; i<scene.mNumMaterials; i++)
        {
          const(aiMaterial*) mat = scene.mMaterials[i];
          for(int j=0; j < mat.mNumProperties; j++)
          {
            const(aiMaterialProperty*) prop = mat.mProperties[j];
            if(prop.mKey.data[0..prop.mKey.length] == "$tex.file")
            {
              string textureFilename = prop.mData[4..prop.mDataLength-1];
              if(textureFilename != "$texture.png")
              {
                if(!textureFiles.exists(textureFilename))
                {
                  Warning("Couldn't find file '%s' ignoring...", textureFilename);
                }
                else if(MapTextureType(prop.mSemantic) == TextureType.UNKOWN)
                {
                  Warning("Texture '%s' has non supported semantic, ignoring...", textureFilename);
                }
                else {
                  uint index = cast(uint)textures.length;
                  textureFiles[textureFilename] = index;
                  textures ~= textureFilename;
                }
              }
            }
          }
        }

        //Write the collected results to the chunkfile
        outFile.write(cast(uint)textures.length);
        foreach(string filename; textures)
        {
          outFile.writeArray(filename);
        }
      }
    }


    //Materials
    {
      outFile.startWriteChunk("materials");
      scope(exit) outFile.endWriteChunk();

      if(scene.mMaterials !is null)
      {
        outFile.write!uint(scene.mNumMaterials);
        for(size_t i=0; i<scene.mNumMaterials; i++)
        {
          materialTextures.resize(0);
          outFile.startWriteChunk("mat");
          scope(exit) outFile.endWriteChunk();

          const(aiMaterial*) mat = scene.mMaterials[i];
          for(size_t j=0; j<mat.mNumProperites; j++)
          {
            const(aiMaterialProperty*) prop = scene.mProperties[j];
            if(prop.mKey.data[0..prop.mKey.length] == "$tex.file")
            {
              string textureFilename = prop.mData[4..prop.mDataLength-1];
              if(textureFiles.exists(textureFilename))
              {
                MaterialTextureInfo info;
                info.id = textureFiles[textureFilename];
                info.semantic = MapTextureType(prop.mSemantic);
                materialTextures ~= info;
              }
            }
          }

          //Texture files
          {
            outFile.startWriteChunk("textures");
            scope(exit) outFile.endWriteChunk();

            outFile.write(cast(uint)materialTextures.length);
            foreach(ref MaterialTextureInfo info, materialTextures)
            {
              outFile.write(info.id);
              outFile.write(info.semantic);
            }
          }
        }
      }
    }

    //Meshes
    {
      outFile.startWriteChunk("meshes");
      scope(exit) outFile.endWriteChunk();

      for(size_t i=0; i<scene.mNumMeshes; i++)
      {
        outFile.startWriteChunk("mesh");
        scope(exit) outFile.endWriteChunk();

        const(aiMesh*) aimesh = scene.mMeshes[i];

        //Material index
        outFile.write!uint(aimesh.mMaterialIndex);

        //Num vertices
        outFile.write!uint(aimesh.mNumVertices);

        //vertices
        outFile.startWriteChunk("vertices");
        outFile.write((cast(const(float*))aimesh.mVertices)[0..aimesh.mNumVertices * 3]);
        outFile.endWriteChunk();

        //normals
        if(aimesh.mNormals is null)
        {
          outFile.startWriteChunk("normals");
          outFile.write((cast(const(float*))aimesh.mNormals)[0..aimesh.mNumVertices * 3]);
          outFile.endWriteChunk();
        }

        //tangents
        if(aimesh.
      }
    }

  }
  catch(Exception ex)
  {
    writefln("Error progressing model '%s': %s", path, ex.toString()[]);
    Delete(ex);
  }
}

int main(string[] args)
{
  auto models = scopedRef!(Stack!string)(New!(Stack!string)());
  foreach(arg; args)
  {
    if(arg.endsWith(".dae", CaseSensitive.no))
    {
      if(thBase.file.exists(arg))
        models.push(arg);
      else
      {
        writefln("File: %s does not exist", arg);
      }
    }
  }
  if(models.size == 0)
  {
    writefln("No model specified");
    return 1;
  }

  try {
    while(models.size > 0)
    {
      ProgressModel(models.pop());
    }
  }
  catch(IThrowable ex)
  {
    writefln("Fatal error: %s", ex.toString()[]);
    Delete(ex);
    return -1;
  }

  return 0;
}