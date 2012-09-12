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
import thBase.math;
import thBase.math3d.mats;
import assimp.assimp;
import modeltypes;

rcstring g_workDir;

static ~this()
{
  g_workDir = rcstring();
}

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

short CompressFloat(float f)
{
  if(f < -1.0f || f > 1.0f)
    Error("out of range compression");
  return cast(short)(cast(float)short.max * f);
}

mat4 Convert(ref const(aiMatrix4x4) pData){
  mat4 result;
  with(result){
    f[ 0] = pData.a1; f[ 1] = pData.a2; f[ 2] = pData.a3; f[ 3] = pData.a4;
    f[ 4] = pData.b1; f[ 5] = pData.b2; f[ 6] = pData.b3; f[ 7] = pData.b4;
    f[ 8] = pData.c1; f[ 9] = pData.c2; f[10] = pData.c3; f[11] = pData.c4;
    f[12] = pData.d1; f[13] = pData.d2; f[14] = pData.d3; f[15] = pData.d4;
  }
  result = result.Transpose();
  return result;
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
      scope(exit){
        size_t size = outFile.endWriteChunk();
        writefln("textures %d kb", size/1024);
      }

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
              rcstring texturePath;
              if(textureFilename[0..2] == ".\\" || textureFilename[0..2] == "./")
                texturePath = textureFilename[2..$];
              else
                texturePath = textureFilename;
              texturePath = g_workDir ~ texturePath;
              if(textureFilename != "$texture.png")
              {
                if(!thBase.file.exists(texturePath[]))
                {
                  Warning("Couldn't find file '%s' at '%s' ignoring...", textureFilename, texturePath[]);
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

    //Size information
    {
      outFile.startWriteChunk("sizeinfo");
      scope(exit) outFile.endWriteChunk();

      outFile.write(scene.mNumMeshes);
      for(size_t i=0; i<scene.mNumMeshes; i++)
      {
        const(aiMesh*) aimesh = scene.mMeshes[i];
        outFile.write(aimesh.mNumVertices);
        uint PerVertexFlags = PerVertexData.Position;
        if(aimesh.mNormals !is null)
          PerVertexFlags |= PerVertexData.Normal;
        if(aimesh.mTangents !is null)
          PerVertexFlags |= PerVertexData.Tangent;
        if(aimesh.mTangents !is null)
          PerVertexFlags |= PerVertexData.Bitangent;
        if(aimesh.mTextureCoords[0] !is null)
          PerVertexFlags |= PerVertexData.TexCoord0;
        if(aimesh.mTextureCoords[1] !is null)
          PerVertexFlags |= PerVertexData.TexCoord1;
        if(aimesh.mTextureCoords[2] !is null)
          PerVertexFlags |= PerVertexData.TexCoord2;
        if(aimesh.mTextureCoords[3] !is null)
          PerVertexFlags |= PerVertexData.TexCoord3;
        outFile.write(PerVertexFlags);
        for(int j=0; j<4; j++)
        {
          if(aimesh.mTextureCoords[i] !is null)
          {
            ubyte numUVComponents = cast(ubyte)aimesh.mNumUVComponents[j];
            if(numUVComponents == 0)
              numUVComponents = 2;
            outFile.write(numUVComponents);
          }
        }
        outFile.write(aimesh.mNumFaces);
      }
    }


    //Materials
    {
      outFile.startWriteChunk("materials");
      scope(exit) {
        size_t size = outFile.endWriteChunk();
        writefln("materials %d kb", size/1024);
      }

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
      scope(exit){
        size_t size = outFile.endWriteChunk();
        writefln("meshes %d kb", size/1024);
      }

      for(size_t i=0; i<scene.mNumMeshes; i++)
      {
        outFile.startWriteChunk("mesh");
        scope(exit) 
        {
          size_t size = outFile.endWriteChunk();
          writefln("mesh %d size %d kb", i, size / 1024);
        }

        const(aiMesh*) aimesh = scene.mMeshes[i];

        //Material index
        outFile.write(cast(uint)aimesh.mMaterialIndex);

        //Num vertices
        writefln("%d vertices", aimesh.mNumVertices);
        outFile.write(cast(uint)aimesh.mNumVertices);

        //vertices
        outFile.startWriteChunk("vertices");
        outFile.write((cast(const(float*))aimesh.mVertices)[0..aimesh.mNumVertices * 3]);
        writefln("mesh %d vertices %d kb", i, outFile.endWriteChunk()/1024);

        if(aimesh.mNormals !is null && (aimesh.mTangents is null || aimesh.mBitangents is null))
        {
          Error("Mesh does have normals but no tangents or bitangents");
        }

        //normals
        if(aimesh.mNormals !is null)
        {
          outFile.startWriteChunk("normals");
          for(size_t j=0; j<aimesh.mNumVertices; j++)
          {
            auto data = (cast(const(float*))(aimesh.mNormals + j))[0..3];
            outFile.write(CompressFloat(data[0]));
            outFile.write(CompressFloat(data[1]));
            outFile.write(CompressFloat(data[2]));
          }
          writefln("mesh %d normals %d kb", i, outFile.endWriteChunk()/1024);
        }

        //tangents
        if(aimesh.mTangents !is null)
        {
          outFile.startWriteChunk("tangents");
          for(size_t j=0; j<aimesh.mNumVertices; j++)
          {
            auto data = (cast(const(float*))(aimesh.mTangents + j))[0..3];
            outFile.write(CompressFloat(data[0]));
            outFile.write(CompressFloat(data[1]));
            outFile.write(CompressFloat(data[2]));
          }
          writefln("mesh %d tangents %d kb", i, outFile.endWriteChunk()/1024);
        }

        //bitangents
        if(aimesh.mBitangents !is null)
        {
          outFile.startWriteChunk("bitangents");
          for(size_t j=0; j<aimesh.mNumVertices; j++)
          {
            auto data = (cast(const(float*))(aimesh.mBitangents + j))[0..3];
            outFile.write(CompressFloat(data[0]));
            outFile.write(CompressFloat(data[1]));
            outFile.write(CompressFloat(data[2]));
          }
          writefln("mesh %d bitangents %d kb", i, outFile.endWriteChunk()/1024);
        }

        //Texture coordinates
        {
          outFile.startWriteChunk("texcoords");
          scope(exit) 
          {
            size_t size = outFile.endWriteChunk();
            writefln("mesh %d texcoords %d kb", i, size/1024);
          }

          ubyte numTexCoords = 0;
          static assert(AI_MAX_NUMBER_OF_TEXTURECOORDS >= 4);
          while(numTexCoords < 4 && aimesh.mTextureCoords[numTexCoords] !is null)
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
          if(aimesh.mNumFaces > ushort.max)
          {
            for(size_t j=0; j<aimesh.mNumFaces; j++)
            {
              if(aimesh.mFaces[j].mNumIndices != 3)
                Error("Non triangle face in mesh");
              outFile.write(aimesh.mFaces[j].mIndices[0..3]);
            }
          }
          else
          {
            for(size_t j=0; j<aimesh.mNumFaces; j++)
            {
              if(aimesh.mFaces[j].mNumIndices != 3)
                Error("Non triangle face in mesh");
              outFile.write(cast(ushort)aimesh.mFaces[j].mIndices[0]);
              outFile.write(cast(ushort)aimesh.mFaces[j].mIndices[1]);
              outFile.write(cast(ushort)aimesh.mFaces[j].mIndices[2]);
            }
          }
          writefln("mesh %d faces %d kb", i, outFile.endWriteChunk()/1024);
        }
      }
    }

    //Nodes
    {
      outFile.startWriteChunk("nodes");
      scope(exit) {
        size_t size = outFile.endWriteChunk();
        writefln("nodes %d kb",size/1024);
      }

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
        auto transform = Convert(node.mTransformation);
        outFile.write(transform.f[]);
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
  Assimp.Load("assimp.dll","");
  auto models = scopedRef!(Stack!string)(New!(Stack!string)());
  for(size_t i=1; i<args.length; i++)
  {
    if(args[i] == "-workdir")
    {
      if(i + 1 > args.length)
      {
        writefln("Error: Missing argument after -workdir");
        return -1;
      }
      g_workDir = args[++i];
      if(g_workDir[g_workDir.length-1] != '\\' && g_workDir[g_workDir.length-1] != '/')
        g_workDir ~= '\\';
    }
    else if(args[i].endsWith(".dae", CaseSensitive.no))
    {
      if(thBase.file.exists(args[i]))
        models.push(args[i]);
      else
      {
        writefln("File: %s does not exist", args[i]);
      }
    }
    else
    {
      writefln("Error: Unkown command line option %s", args[i]);
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