import thBase.io;
import thBase.string;
import thBase.container.stack;
import thBase.container.hashmap;
import thBase.container.vector;
import thBase.policies.hashing;
import thBase.scoped;
import thBase.file;
import thBase.chunkfile;
import thBase.format;
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
  formatDo!StdOutPutPolicy(put, "Warning: ", [], null);
  formatDo(put, fmt, _arguments, _argptr);
  put.put('\r');
  put.put('\n');
  put.flush();
}

void Error(string fmt, ...)
{
  auto dummy = NothingPutPolicy!char();
  size_t needed = formatDo(dummy,fmt,_arguments,_argptr);
  auto result = rcstring(needed);
  auto put = BufferPutPolicy!char(cast(char[])result[]);
  formatDo(put,fmt,_arguments,_argptr);
  throw New!RCException(result);
}

TextureType MapTextureType(aiTextureType type)
{
  switch(type)
  {
    case aiTextureType.NONE:
      return TextureType.UNKNOWN;
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
		const(aiScene)* scene = Assimp.ImportFile(toCString(path), 
                                              aiPostProcessSteps.CalcTangentSpace |
                                              aiPostProcessSteps.Triangulate |
                                              aiPostProcessSteps.JoinIdenticalVertices |
                                              aiPostProcessSteps.FlipUVs);// |
    //aiPostProcessSteps.MakeLeftHanded); // |
    //aiPostProcessSteps.PreTransformVertices );
		if(scene is null){
			Error("Couldn't load model from file '%s'", path);
		}

    scope(exit)
    {
      Assimp.ReleaseImport(cast(aiScene*)scene);
      scene = null;
    }

    rcstring outputFilename = path[0..$-3];
    outputFilename ~= ".thModel";

    auto outFile = scopedRef!Chunkfile(New!Chunkfile(outputFilename, Chunkfile.Operation.Write));

    outFile.startWriting("thModel", ModelFormatVersion.max);
    scope(exit) outFile.endWriting();

    auto textureFiles = scopedRef!(Hashmap!(const(char)[], uint, StringHashPolicy))(New!(Hashmap!(const(char)[], uint, StringHashPolicy))());
    auto materialTextures = scopedRef!(Vector!MaterialTextureInfo)(New!(Vector!MaterialTextureInfo)());

    // Textures
    {
      outFile.startWriteChunk("textures");
      scope(exit) outFile.endWriteChunk();

      auto textures = scopedRef!(Vector!(const(char)[]))(New!(Vector!(const(char)[]))());
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
              const(char)[] textureFilename = prop.mData[4..prop.mDataLength-1];
              if(textureFilename != "$texture.png")
              {
                if(!textureFiles.exists(textureFilename))
                {
                  Warning("Couldn't find file '%s' ignoring...", textureFilename);
                }
                else if(MapTextureType(cast(aiTextureType)prop.mSemantic) == TextureType.UNKNOWN)
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
        foreach(const(char)[] filename; textures)
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
        outFile.write(cast(uint)scene.mNumMaterials);
        for(size_t i=0; i<scene.mNumMaterials; i++)
        {
          materialTextures.resize(0);
          outFile.startWriteChunk("mat");
          scope(exit) outFile.endWriteChunk();

          const(aiMaterial*) mat = scene.mMaterials[i];
          for(size_t j=0; j<mat.mNumProperties; j++)
          {
            const(aiMaterialProperty*) prop = mat.mProperties[j];
            if(prop.mKey.data[0..prop.mKey.length] == "$tex.file")
            {
              const(char)[] textureFilename = prop.mData[4..prop.mDataLength-1];
              if(textureFiles.exists(textureFilename))
              {
                MaterialTextureInfo info;
                info.id = textureFiles[textureFilename];
                info.semantic = MapTextureType(cast(aiTextureType)prop.mSemantic);
                materialTextures ~= info;
              }
            }
          }

          //Texture files
          {
            outFile.startWriteChunk("textures");
            scope(exit) outFile.endWriteChunk();

            outFile.write(cast(uint)materialTextures.length);
            foreach(ref MaterialTextureInfo info; materialTextures)
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
        outFile.write(cast(uint)aimesh.mMaterialIndex);

        //Num vertices
        outFile.write(cast(uint)aimesh.mNumVertices);

        //vertices
        outFile.startWriteChunk("vertices");
        outFile.write((cast(const(float*))aimesh.mVertices)[0..aimesh.mNumVertices * 3]);
        outFile.endWriteChunk();

        if(aimesh.mNormals !is null && (aimesh.mTangents is null || aimesh.mBitangents is null))
        {
          Error("Mesh does have normals but no tangents or bitangents");
        }

        //normals
        if(aimesh.mNormals !is null)
        {
          outFile.startWriteChunk("normals");
          outFile.write((cast(const(float*))aimesh.mNormals)[0..aimesh.mNumVertices * 3]);
          outFile.endWriteChunk();
        }

        //tangents
        if(aimesh.mTangents !is null)
        {
          outFile.startWriteChunk("tangents");
          outFile.write((cast(const(float*))aimesh.mTangents)[0..aimesh.mNumVertices * 3]);
          outFile.endWriteChunk();
        }

        //bitangents
        if(aimesh.mBitangents !is null)
        {
          outFile.startWriteChunk("bitangents");
          outFile.write((cast(const(float*))aimesh.mBitangents)[0..aimesh.mNumVertices * 3]);
          outFile.endWriteChunk();
        }

        //Texture coordinates
        {
          outFile.startWriteChunk("texcoords");
          scope(exit)outFile.endWriteChunk();

          ubyte numTexCoords = 0;
          while(numTexCoords < AI_MAX_NUMBER_OF_TEXTURECOORDS && aimesh.mTextureCoords[numTexCoords] !is null)
            numTexCoords++;

          outFile.write(numTexCoords);
          for(ubyte j=0; j<numTexCoords; j++)
          {
            ubyte numUVComponents = cast(ubyte)aimesh.mNumUVComponents[j];
            if(numUVComponents == 0)
              numUVComponents = 2;
            outFile.write(numUVComponents);
            if(numUVComponents == 3)
            {
              outFile.write((cast(const(float*))aimesh.mTextureCoords[j])[0..aimesh.mNumVertices]);
            }
            else
            {
              for(size_t k=0; k<aimesh.mNumVertices; k++)
              {
                outFile.write((cast(const(float*))&aimesh.mTextureCoords[j][k].x)[0..numUVComponents]);
              }
            }
          }
        }

        //Faces
        {
          outFile.startWriteChunk("faces");
          outFile.write(cast(uint)aimesh.mNumFaces);
          for(size_t j=0; j<aimesh.mNumFaces; j++)
          {
            if(aimesh.mFaces[j].mNumIndices != 3)
              Error("Non triangle face in mesh");
            outFile.write(aimesh.mFaces[j].mIndices[0..3]);
          }
          outFile.endWriteChunk();
        }
      }
    }

    //Nodes
    {
      outFile.startWriteChunk("nodes");
      scope(exit) outFile.endWriteChunk();

      auto nodeLookup = scopedRef!(Hashmap!(void*, uint))(New!(Hashmap!(void*, uint))());
      uint nextNodeId = 0;

      uint countNodes(const(aiNode*) node)
      {
        if(node is null)
          return 0;

        nodeLookup[cast(void*)node] = nextNodeId++; 

        if(node.mNumChildren == 0)
          return 0;

        uint count = node.mNumChildren;
        foreach(child; node.mChildren[0..node.mNumChildren])
        {
          count += countNodes(child);
        }
        return count;
      }

      uint numNodes = countNodes(scene.mRootNode) + 1;
      outFile.write(numNodes);

      void writeNode(const(aiNode*) node)
      {
        if(node is null)
          return;

        outFile.writeArray(node.mName.data[0..node.mName.length]);
        outFile.write((cast(const(float*))&node.mTransformation)[0..16]);
        if(node.mParent is null)
          outFile.write(uint.max);
        else
          outFile.write(nodeLookup[cast(void*)node.mParent]);
        outFile.write(node.mNumChildren);
        for(uint i=0; i<node.mNumChildren; i++)
        {
          outFile.write(nodeLookup[cast(void*)node.mChildren[i]]);
        }

        outFile.writeArray(node.mMeshes[0..node.mNumMeshes]);

        foreach(child; node.mChildren[0..node.mNumChildren])
        {
          writeNode(child);
        }
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
  catch(Throwable ex)
  {
    writefln("Fatal error: %s", ex.toString()[]);
    Delete(ex);
    return -1;
  }

  return 0;
}