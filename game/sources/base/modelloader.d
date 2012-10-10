module base.modelloader;

import thBase.format;
import thBase.chunkfile;
import thBase.policies.locking;
import thBase.enumbitfield;
import thBase.math3d.vecs;
import thBase.math3d.mats;
import thBase.math3d.box;
import thBase.allocator;
import thBase.scoped;
import thBase.types;
import modeltypes;

extern(C) int D10modeltypes12__ModuleInfoZ;

class ModelLoader
{
public:
  enum Load
  {
    Materials  = 0x0001,
    Meshes     = 0x0002,
    Normals    = 0x0004,
    Tangents   = 0x0008,
    Bitangents = 0x0010,
    TexCoords0 = 0x0020,
    TexCoords1 = 0x0040,
    TexCoords2 = 0x0080,
    TexCoords3 = 0x0100,
    Nodes      = 0x0200,
    Everything = 0xFFFF
  }

  static struct FaceData
  {
    uint[3] indices;
  }

  static struct MaterialData
  {
    TextureReference[] textures;
  }

  static struct MeshData
  {
    uint materialIndex;
    AlignedBoxLocal bbox;
    uint numFaces;
    FaceData[] faces;
    vec3[] vertices;
    vec3[] normals;
    vec3[] tangents;
    vec3[] bitangents;
    vec2[][4] texcoords;
  }

  static struct NodeDrawData
  {
    mat4 transform;
    NodeDrawData*[] children;
    uint[] meshes;
    NodeData* data;
  }

  static struct NodeData
  {
    string name;
    NodeDrawData* parent;
    MeshData*[] meshData;
  }

  static struct TextureReference
  {
    TextureType semantic;
    string file;
  }

  static struct ModelData
  {
    string[] textures;
    MaterialData[] materials;
    MeshData[] meshes;
    NodeDrawData* rootNode;
    bool hasData;
  }

  private FixedStackAllocator!(NoLockPolicy, StdAllocator) m_meshDataAllocator;
  private ModelData m_modelData;
  rcstring  filename;

  private uint allocationSize(T)(uint num)
  {
    uint size = T.sizeof * num;
    if(size % m_meshDataAllocator.alignment != 0)
    {
      size += m_meshDataAllocator.alignment - (size & m_meshDataAllocator.alignment);
    }
    return size;
  }

  /**
   * provides read only access for the loaded data
   */
  @property ref const(ModelData) modelData() const
  {
    assert(m_modelData.hasData, "no data has been loaded yet");
    return m_modelData;
  }

  ~this()
  {
    if(m_meshDataAllocator !is null)
    {
      m_meshDataAllocator.FreeAllMemory();
      Delete(m_meshDataAllocator);
    }
  }

	/**
  * Load the model from a file
  * Params:
  *		pFilename = filename of the file to load
  */
	void LoadFile(rcstring pFilename, EnumBitfield!Load loadWhat)
	in {
		assert(!m_modelData.hasData,"LoadFile can only be called once");
	}
	body {
		filename = pFilename;

    if(!thBase.file.exists(pFilename[]))
    {
      throw New!RCException(format("File '%s' does not exist", pFilename[]));
    }

    auto file = scopedRef!(Chunkfile)(New!Chunkfile(pFilename, Chunkfile.Operation.Read));

    if(file.startReading("thModel") != thResult.SUCCESS)
    {
      throw New!RCException(format("File '%s' is not a thModel format", pFilename[]));
    }

    if(file.fileVersion != ModelFormatVersion.Version1)
    {
      throw New!RCException(format("Model '%s' does have old format, please reexport", pFilename[]));
    }

    static struct MemoryPool
    {
      uint size;
      uint cur;

      this(size_t size)
      {
        assert(size <= uint.max);
        this.size = cast(uint)size;
      }

      void opOpAssign(string op, T)(T val)
      {
        this.cur += cast(uint)val;
        assert(this.cur <= this.size, "Memory pool overflow");
      }
    }

    static struct MemoryStatistics
    {
      MemoryPool materialData;
      MemoryPool nodeNameMemory;
      MemoryPool texturePathMemory;
      MemoryPool texturePathReferencesMemory;
      MemoryPool meshDataArray;
      MemoryPool vertexData;
      MemoryPool faceDataArray;
      MemoryPool nodeData;
      MemoryPool meshReferenceMemory;
      MemoryPool nodeReferenceMemory;
      MemoryPool textureReferenceMemory;
    }

    MemoryStatistics memstat;

    uint nodeNameMemory;

    Load[4] loadTexCoords;
    loadTexCoords[0] = Load.TexCoords0;
    loadTexCoords[1] = Load.TexCoords1;
    loadTexCoords[2] = Load.TexCoords2;
    loadTexCoords[3] = Load.TexCoords3;

    uint texturePathMemory;
    //Read the size info
    {
      enum size_t alignmentOverhead = m_meshDataAllocator.alignment - 1;
      file.startReadChunk();
      if(file.currentChunkName != "sizeinfo")
      {
        throw New!RCException(format("Expected sizeinfo chunk, got '%s' chunk in file '%s'", file.currentChunkName, pFilename[]));
      }

      size_t meshDataSize;

      uint numTextures;
      file.read(numTextures);
      if(loadWhat.IsSet(Load.Materials))
      {
        meshDataSize += string.sizeof * numTextures;
        memstat.texturePathReferencesMemory = MemoryPool(string.sizeof * numTextures);
      }

      file.read(texturePathMemory);
      if(texturePathMemory % m_meshDataAllocator.alignment != 0)
        texturePathMemory += m_meshDataAllocator.alignment - (texturePathMemory % m_meshDataAllocator.alignment);
      if(loadWhat.IsSet(Load.Materials))
      {
        meshDataSize += texturePathMemory;
        memstat.texturePathMemory = MemoryPool(texturePathMemory);
      }

      uint numMaterials;
      file.read(numMaterials);
      if(loadWhat.IsSet(Load.Materials))
      {
        memstat.materialData = MemoryPool(numMaterials * MaterialData.sizeof);
        meshDataSize += memstat.materialData.size;
      }

      uint numMeshes;
      file.read(numMeshes);
      if(loadWhat.IsSet(Load.Meshes))
      {
        meshDataSize += MeshData.sizeof * numMeshes;
        memstat.meshDataArray = MemoryPool(MeshData.sizeof * numMeshes);
      }
      for(uint i=0; i<numMeshes; i++)
      {
        uint numVertices, PerVertexFlags, numComponents, numTexcoords;
        file.read(numVertices);
        file.read(PerVertexFlags);

        if(PerVertexFlags & PerVertexData.Position)
          numComponents++;
        if((PerVertexFlags & PerVertexData.Normal) && loadWhat.IsSet(Load.Normals))
          numComponents++;
        if((PerVertexFlags & PerVertexData.Tangent) && loadWhat.IsSet(Load.Tangents))
          numComponents++;
        if((PerVertexFlags & PerVertexData.Bitangent) && loadWhat.IsSet(Load.Bitangents))
          numComponents++;
        if(PerVertexFlags & PerVertexData.TexCoord0)
          numTexcoords++;
        if(PerVertexFlags & PerVertexData.TexCoord1)
          numTexcoords++;
        if(PerVertexFlags & PerVertexData.TexCoord2)
          numTexcoords++;
        if(PerVertexFlags & PerVertexData.TexCoord3)
          numTexcoords++;

        meshDataSize += numVertices * numComponents * 3 * float.sizeof;
        memstat.vertexData.size += numVertices * numComponents * 3 * float.sizeof;

        for(uint j=0; j<numTexcoords; j++)
        {
          ubyte numUVComponents;
          file.read(numUVComponents);
          if(loadWhat.IsSet(loadTexCoords[j]))
          {
            meshDataSize += numVertices * numUVComponents * float.sizeof;
            memstat.vertexData.size += numVertices * numUVComponents * float.sizeof;
          }
        }

        uint numFaces;
        file.read(numFaces);
        if(loadWhat.IsSet(Load.Meshes))
        {
          meshDataSize += numFaces * FaceData.sizeof;
          memstat.faceDataArray.size += numFaces * FaceData.sizeof;
        }
      }

      uint numNodes,numNodeReferences,numMeshReferences,numTextureReferences;
      file.read(numNodes);
      file.read(numNodeReferences);
      file.read(nodeNameMemory);
      file.read(numMeshReferences);
      file.read(numTextureReferences);

      if(nodeNameMemory % m_meshDataAllocator.alignment != 0)
        nodeNameMemory += m_meshDataAllocator.alignment - (nodeNameMemory % m_meshDataAllocator.alignment);

      if(loadWhat.IsSet(Load.Nodes))
      {
        meshDataSize += numNodes * NodeData.sizeof;
        meshDataSize += numNodes * NodeDrawData.sizeof;
        memstat.nodeData = MemoryPool(numNodes * NodeData.sizeof + numNodes * NodeDrawData.sizeof);

        meshDataSize += numMeshReferences * uint.sizeof;
        memstat.meshReferenceMemory = MemoryPool(numMeshReferences * uint.sizeof);

        meshDataSize += numNodeReferences * (NodeData*).sizeof;
        memstat.nodeReferenceMemory = MemoryPool(numNodeReferences * (NodeDrawData*).sizeof);

        meshDataSize += nodeNameMemory;
        memstat.nodeNameMemory = MemoryPool(nodeNameMemory);
      }
      if(loadWhat.IsSet(Load.Materials))
      {
        meshDataSize += numTextureReferences * TextureReference.sizeof;
        memstat.textureReferenceMemory = MemoryPool(numTextureReferences * TextureReference.sizeof);
      }

      file.endReadChunk();

      debug 
      {
        meshDataSize += 512 * size_t.sizeof; //room for size tracking inside allocator in debug
      }

      m_meshDataAllocator = New!(typeof(m_meshDataAllocator))(meshDataSize, StdAllocator.globalInstance);
    }

    // Load textures
    {
      file.startReadChunk();
      if(file.currentChunkName != "textures")
      {
        throw New!RCException(format("Expected 'textures' chunk but got '%s' chunk", file.currentChunkName));
      }
      if(loadWhat.IsSet(Load.Materials))
      {
        uint numTextures;
        file.read(numTextures);

        if(numTextures > 0)
        {
          memstat.texturePathReferencesMemory += allocationSize!string(numTextures);
          m_modelData.textures = AllocatorNewArray!string(m_meshDataAllocator, numTextures);

          memstat.texturePathMemory += allocationSize!char(texturePathMemory);
          char[] textureNames = AllocatorNewArray!char(m_meshDataAllocator, texturePathMemory);
          size_t curNamePos = 0;
          foreach(ref texture; m_modelData.textures)
          {
            uint len;
            file.read(len);
            auto data = textureNames[curNamePos..(curNamePos+len)];
            curNamePos += len;
            file.read(data);
            texture = cast(string)data;
          }
        }

        file.endReadChunk();
      }
      else
      {
        file.skipCurrentChunk();
      }
    }

    // Read Materials
    {
      file.startReadChunk();
      if(file.currentChunkName != "materials")
      {
        throw New!RCException(format("Expected 'materials' chunk but go '%s'", file.currentChunkName));
      }

      if(loadWhat.IsSet(Load.Materials))
      {
        uint numMaterials;
        file.read(numMaterials);

        if(numMaterials > 0)
        {
          memstat.materialData += allocationSize!MaterialData(numMaterials);
          m_modelData.materials = AllocatorNewArray!MaterialData(m_meshDataAllocator, numMaterials);
          foreach(ref material; m_modelData.materials)
          {
            file.startReadChunk();
            if(file.currentChunkName != "mat")
            {
              throw New!RCException(format("Expected 'mat' chunk but go '%s'", file.currentChunkName));
            }

            uint numTextures;
            file.read(numTextures);
            memstat.textureReferenceMemory += allocationSize!TextureReference(numTextures);
            material.textures = AllocatorNewArray!TextureReference(m_meshDataAllocator, numTextures);
            foreach(ref texture; material.textures)
            {
              uint textureIndex;
              file.read(textureIndex);
              texture.file = m_modelData.textures[textureIndex];
              file.read(texture.semantic);
            }

            file.endReadChunk();
          }
        }

        file.endReadChunk();
      }
      else
      {
        file.skipCurrentChunk();
      }
    }


    // Read Meshes
    {
      file.startReadChunk();
      if(file.currentChunkName != "meshes")
      {
        throw New!RCException(format("Expected 'meshes' chunk but got '%s'", file.currentChunkName));
      }

      if(loadWhat.IsSet(Load.Meshes))
      {
        uint numMeshes;
        file.read(numMeshes);
        memstat.meshDataArray += allocationSize!MeshData(numMeshes);
        m_modelData.meshes = AllocatorNewArray!MeshData(m_meshDataAllocator, numMeshes);

        foreach(ref mesh; m_modelData.meshes)
        {
          file.startReadChunk();
          if(file.currentChunkName != "mesh")
          {
            throw New!RCException(format("Expected 'mesh' chunk but got '%s'", file.currentChunkName));
          }

          uint materialIndex;
          file.read(mesh.materialIndex);

          vec3 minBounds,maxBounds;
          file.read(minBounds.f[]);
          file.read(maxBounds.f[]);
          mesh.bbox = AlignedBoxLocal(minBounds, maxBounds);

          uint numVertices;
          file.read(numVertices);

          file.startReadChunk();
          if(file.currentChunkName != "vertices")
          {
            throw New!RCException(format("Expected 'vertices' chunk but got '%s'", file.currentChunkName));
          }
          memstat.vertexData += allocationSize!vec3(numVertices);
          mesh.vertices = AllocatorNewArray!vec3(m_meshDataAllocator, numVertices, InitializeMemoryWith.NOTHING);
          file.read(mesh.vertices[0].f.ptr[0..numVertices * 3]);
          file.endReadChunk();

          float UncompressFloat()
          {
            short data;
            file.read(data);
            return cast(float)data / cast(float)short.max;
          }

          {
            file.startReadChunk();
            if(file.currentChunkName == "normals")
            {
              if(loadWhat.IsSet(Load.Normals))
              {
                memstat.vertexData += allocationSize!vec3(numVertices);
                mesh.normals = AllocatorNewArray!vec3(m_meshDataAllocator, numVertices, InitializeMemoryWith.NOTHING);
                foreach(ref normal; mesh.normals)
                {
                  normal.x = UncompressFloat();
                  normal.y = UncompressFloat();
                  normal.z = UncompressFloat();
                }
                file.endReadChunk();
              }
              else
              {
                file.skipCurrentChunk();
              }
              file.startReadChunk();
            }
            if(file.currentChunkName == "tangents")
            {
              if(loadWhat.IsSet(Load.Tangents))
              {
                memstat.vertexData += allocationSize!vec3(numVertices);
                mesh.tangents = AllocatorNewArray!vec3(m_meshDataAllocator, numVertices, InitializeMemoryWith.NOTHING);
                foreach(ref tangent; mesh.tangents)
                {
                  tangent.x = UncompressFloat();
                  tangent.y = UncompressFloat();
                  tangent.z = UncompressFloat();
                }
                file.endReadChunk();
              }
              else
              {
                file.skipCurrentChunk();
              }
              file.startReadChunk();
            }
            if(file.currentChunkName == "bitangents")
            {
              if(loadWhat.IsSet(Load.Bitangents))
              {
                memstat.vertexData += allocationSize!vec3(numVertices);
                mesh.bitangents = AllocatorNewArray!vec3(m_meshDataAllocator, numVertices, InitializeMemoryWith.NOTHING);
                foreach(ref bitangent; mesh.bitangents)
                {
                  bitangent.x = UncompressFloat();
                  bitangent.y = UncompressFloat();
                  bitangent.z = UncompressFloat();
                }
                file.endReadChunk();
              }
              else
              {
                file.skipCurrentChunk();
              }
              file.startReadChunk();
            }
            if(file.currentChunkName == "texcoords")
            {
              if(loadWhat.IsSet(Load.TexCoords0) || loadWhat.IsSet(Load.TexCoords1) ||
                 loadWhat.IsSet(Load.TexCoords2) || loadWhat.IsSet(Load.TexCoords3))
              {
                ubyte numTexCoords;
                file.read(numTexCoords);
                for(ubyte i=0; i<numTexCoords; i++)
                {
                  ubyte numUVComponents;
                  file.read(numUVComponents);
                  if(numUVComponents != 2)
                  {
                    throw New!RCException(format("Currently only 2 component texture coordinates are supported got %d", numUVComponents));
                  }
                  if(loadWhat.IsSet(loadTexCoords[i]))
                  {
                    memstat.vertexData += allocationSize!vec2(numVertices);
                    mesh.texcoords[i] = AllocatorNewArray!vec2(m_meshDataAllocator, numVertices, InitializeMemoryWith.NOTHING);
                    file.read((cast(float*)mesh.texcoords[i].ptr)[0..numVertices*numUVComponents]);
                  }
                  else
                  {
                    //skip the texcoord data
                    file.skipRead(float.sizeof * numUVComponents * numVertices);
                  }
                }
                file.endReadChunk();
              }
              else
              {
                file.skipCurrentChunk();
              }
              file.startReadChunk();
            }
            if(file.currentChunkName == "faces")
            {
              uint numFaces;
              file.read(numFaces);
              memstat.faceDataArray += allocationSize!FaceData(numFaces);
              mesh.faces = AllocatorNewArray!FaceData(m_meshDataAllocator, numFaces, InitializeMemoryWith.NOTHING);
              if(numVertices > ushort.max)
              {
                file.read((cast(uint*)mesh.faces.ptr)[0..numFaces*3]);
              }
              else
              {
                ushort data;
                foreach(ref face; mesh.faces)
                {
                  file.read(data); face.indices[0] = cast(uint)data;
                  file.read(data); face.indices[1] = cast(uint)data;
                  file.read(data); face.indices[2] = cast(uint)data;
                }
              }
            }
            else
            {
              throw New!RCException(format("Unexpected chunk '%s'", file.currentChunkName));
            }
            file.endReadChunk();
          }

          file.endReadChunk();
        }

        file.endReadChunk();
      }
      else
      {
        file.skipCurrentChunk();
      }
    }

    // Read Nodes
    {
      file.startReadChunk();
      if(loadWhat.IsSet(Load.Nodes))
      {
        if(file.currentChunkName != "nodes")
        {
          throw New!RCException(format("Expected 'nodes' chunk but got '%s'", file.currentChunkName));
        }
        uint numNodes;
        file.read(numNodes);

        memstat.nodeNameMemory += allocationSize!char(nodeNameMemory);
        auto nodeNames = AllocatorNewArray!char(m_meshDataAllocator, nodeNameMemory);

        size_t curNodeNamePos = 0;
        
        memstat.nodeData += allocationSize!NodeData(numNodes);
        auto nodesData = AllocatorNewArray!NodeData(m_meshDataAllocator, numNodes);

        memstat.nodeData += allocationSize!NodeDrawData(numNodes);
        auto nodes = AllocatorNewArray!NodeDrawData(m_meshDataAllocator, numNodes);

        foreach(size_t i, ref node; nodes)
        {
          node.data = &nodesData[i];
          uint nameLength;
          file.read(nameLength);
          auto name = nodeNames[curNodeNamePos..(curNodeNamePos+nameLength)];
          file.read(name);
          node.data.name = cast(string)name;
          file.read(node.transform.f[]);
          uint nodeParentIndex;
          file.read(nodeParentIndex);
          if(nodeParentIndex == uint.max)
            node.data.parent = null;
          else
            node.data.parent = &nodes[nodeParentIndex];

          
          node.meshes = file.readAndAllocateArray!(uint, uint, typeof(m_meshDataAllocator))(m_meshDataAllocator);
          memstat.meshReferenceMemory += allocationSize!uint(node.meshes.length);
          uint numChildren;
          file.read(numChildren);
          if(numChildren > 0)
          {
            memstat.nodeReferenceMemory += allocationSize!(NodeDrawData*)(numChildren);
            node.children = AllocatorNewArray!(NodeDrawData*)(m_meshDataAllocator, numChildren);
            foreach(ref child; node.children)
            {
              uint childIndex;
              file.read(childIndex);
              child = &nodes[childIndex];
            }
          }

        }
        m_modelData.rootNode = &nodes[0];

        file.endReadChunk();
      }
      else
      {
        file.skipCurrentChunk();
      }
    }

    file.endReading();
    m_modelData.hasData = true;
	}
}