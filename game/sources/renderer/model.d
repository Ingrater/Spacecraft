module renderer.model;

import base.renderer;
import renderer.uniformtype;
import renderer.texture2d;
import renderer.shaderconstants;
import renderer.shader;
import renderer.vertexbuffer;
import renderer.stateobject;
import thBase.math3d.all;
import renderer.vertexbuffermanager;
import renderer.rendergroup;
import renderer.rendercall;

import renderer.exceptions;
import thBase.container.vector;
import thBase.container.hashmap;
import thBase.policies.hashing;

import renderer.internal;
import thBase.math;
import thBase.string;
import thBase.algorithm;
import thBase.chunkfile;
import thBase.policies.locking;
import modeltypes;

/**
 * a Material for a subpart of a model
 */
class Material {
private:
	Hashmap!(int, Texture2D) m_Textures;
	Shader m_Shader = null;
  Hashmap!(ShaderConstant, Overwrite, ReferenceHashPolicy) m_Overwrites;
public:	

  this()
  {
    m_Textures = New!(typeof(m_Textures))();
    m_Overwrites = New!(typeof(m_Overwrites))();
  }

  ~this()
  {
    Delete(m_Textures);
    Delete(m_Overwrites);
  }

	/**
	 * Sets the shader of a material
	 * Params:
	 * 		pShader = the shader to use
	 */ 
	void SetShader(Shader pShader){
		m_Shader = pShader;
	}
	
	/**
	 * Gets the shader of a material
	 * Returns: the current shader in use by this material
	 */
	Shader GetShader(){
		return m_Shader;
	}
	
	/**
	 * Get textures
	 * Returns: A TreeMap of the current textures in use
	 */
	auto GetTextures(){
		return m_Textures;
	}
	
	/**
	 * Get overwrites
	 * Returns: A TreeMap of the current overwrites in use
	 */
	auto GetOverwrites(){
		return m_Overwrites;
	}
	
	/**
	 * Sets the texture of a material used
	 * Params:
	 *		pTexture = the texture
	 * 		pBinding = the texture channel to use
	 */
	void SetTexture(Texture2D pTexture, int pBinding){
		m_Textures[pBinding] = pTexture;
	}
	
	/**
	 * Removes all Textures from a Material
	 */
	void ResetTextures(){
		m_Textures.clear();
	}
	
	/**
	* Overwrites the given shaderconstant for this material
	* Params:
	*		pConst = the constant to overwrite
	*		pValue = the value to overwrite with
	*/
	void OverwriteConstant(T)(ShaderConstant pConst, T pValue)
	in {
		assert(pConst.GetType() == TypeToUniformType!T,"Trying to overwrite ShaderConstant with wrong type");
	}
	body {
		Overwrite temp;
		temp.Set(pValue);
		m_Overwrites[pConst] = temp;
	}
}

interface IDrawModel {
	void Draw(ref const(mat4) modelMatrix, RenderGroup pGroup, StateObject pState, int pMaterialSet = 0);
}

/**
 * a model loaded from a file
 */
class Model : IModel, IDrawModel {
public:
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
    MaterialData* material;
    uint numFaces;
    FaceData[] faces;
    vec3[] vertices;
    vec3[] normals;
    vec3[] tangents;
    vec3[] bitangents;
    vec2[4][] texcoords;
  }

  static struct NodeData
  {
    mat4 transform;
    NodeData* father;
    NodeData*[] children;
    MeshData*[] meshes;
  }

  static struct TextureReference
  {
    TextureType semantic;
    string texture;
  }
  
  static struct ModelData
  {
    string[] textures;
    MaterialData[] materials;
    MeshData[] meshes;
    NodeData* rootNode;
  }

	/**
	 * Information about a texture needed by the model
	 */
	struct ModelTextureInfo {
		rcstring name; /// texture type as string
		rcstring file; /// texture file path
		TextureType type; /// texture type
		int index; /// used texture channel
	}
	
	/**
	 * Information about a material needed by the model
	 */
	struct MaterialInfo {
		Vector!ModelTextureInfo textures; /// array of textures
    Hashmap!(rcstring, Overwrite) properties; /// array of properties, key is the property name

    void init()
    {
      textures = New!(typeof(textures))();
      properties = New!(typeof(properties))();
    }

    ~this()
    {
      Delete(properties);
      Delete(textures);
    }
	};
	
	class SubModel : ISubModel, IDrawModel {
		private:
			Node m_SubRootNode;
			int m_Depth;
			size_t[] m_Path;
		public:
			this(Node rootNode, int depth,size_t[] path){
				m_SubRootNode = rootNode;
				m_Depth = depth;
				m_Path = path;
			}
		
			override void Draw(ref const(mat4) modelMatrix, RenderGroup pGroup, StateObject pState, int pMaterialSet = 0){
				mat4 trans = modelMatrix * m_RootNode.m_Transformation;
				Node curNode = m_RootNode;
				foreach(index;m_Path){
					curNode = curNode.m_Children[index];
					if(curNode == m_SubRootNode)
						break;
					trans = trans * curNode.m_Transformation;
				}
				DrawHelper(pGroup,pState,trans,m_SubRootNode,pMaterialSet,m_Depth);
			}
			
			override void FindMinMax(ref vec3 min, ref vec3 max){
				mat4 trans = m_RootNode.m_Transformation;
				Node curNode = m_RootNode;
				foreach(index;m_Path){
					curNode = curNode.m_Children[index];
					if(curNode == m_SubRootNode)
						break;
					trans = trans * curNode.m_Transformation;
				}
				DoFindMinMax(trans,m_SubRootNode,min,max);
			}
			
			override void FindMinMax(ref vec3 min, ref vec3 max) shared {
				(cast(SubModel)this).FindMinMax(min,max);
			}
	}
	
private:

  void[] m_meshDataMemory;
  FixedBlockAllocator!(NoLockPolicy) m_meshDataAllocator;
  ModelData m_modelData;
	
	static class Mesh {
		rcstring m_Name;
		VertexBuffer m_VertexBuffer = null;
		size_t m_Start,m_Size,m_Material;
		vec4 m_Min,m_Max;

    ~this()
    {
      Delete(m_VertexBuffer);
    }
	}
	
	static class Node {
		rcstring m_Name;
		Node m_Father;
		Node[] m_Children;
		Mesh[] m_Meshes;
		mat4 m_Transformation;

    ~this()
    {
      Delete(m_Meshes); m_Meshes = null;
      
      foreach(child; m_Children)
      {
        Delete(child);
      }
      Delete(m_Children); m_Children = null;
    }
	}
	
	rcstring m_Filename;
	Vector!(Mesh) m_Meshes;
	Vector!(Vector!(Material)) m_Materials;
	MaterialInfo[] m_MaterialInfo;
	Node m_RootNode = null;
	IVertexBufferManager m_Manager;
	IRendererInternal m_Renderer;
	
	Hashmap!(rcstring, Node) m_NodeLookup;
	bool m_NeedsNodeLookup = false;
	
	static ShaderConstant m_ModelMatrixConstant;
	static ShaderConstant m_BonesConstant;
	
	void ProgressNode(ref const(aiNode) pAiNode, Node pNode, Node pFather){
		assert(pNode.m_Meshes.length == 0 && pNode.m_Meshes.ptr is null);
		/*if(pFather is null){
			mat4 inv;
			inv.f[ 0]= 1.00; inv.f[ 1]= 0.00; inv.f[ 2]= 0.00; inv.f[ 3]= 0.00;
			inv.f[ 4]= 0.00; inv.f[ 5]= 0.00; inv.f[ 6]= 1.00; inv.f[ 7]= 0.00;
			inv.f[ 8]= 0.00; inv.f[ 9]=-1.00; inv.f[10]= 0.00; inv.f[11]= 0.00;
			inv.f[12]= 0.00; inv.f[13]= 0.00; inv.f[14]= 0.00; inv.f[15]= 1.00;
			pNode.m_Transformation = Convert(pAiNode.mTransformation) * inv;
		}
		else {*/
			pNode.m_Transformation = Convert(pAiNode.mTransformation);
		//}
		
		/*writef("\nNode Transformation:");
		foreach(int i,f;pNode.m_Transformation.f){
			if(i%4 == 0)
				writef("\n");
			writef("%s ",f);
		}
		writef("\n");*/
		
		pNode.m_Name = rcstring(pAiNode.mName.data[0..pAiNode.mName.length]);
		
		pNode.m_Father = pFather;
		
		if(m_NeedsNodeLookup){
			auto nodeName = rcstring(pAiNode.mName.data[0..(pAiNode.mName.length-1)]);
			if(!m_NodeLookup.exists(nodeName))
				m_NodeLookup[nodeName] = pNode;
		}
		
		//Progress Meshes
		if(pAiNode.mNumMeshes > 0){
			pNode.m_Meshes = NewArray!Mesh(pAiNode.mNumMeshes);
			for(size_t i=0;i<pAiNode.mNumMeshes;i++){
				pNode.m_Meshes[i] = m_Meshes[pAiNode.mMeshes[i]];
				m_Meshes[pAiNode.mMeshes[i]].m_Name = rcstring(pAiNode.mName.data[0..(pAiNode.mName.length-1)]);
				
			}
		}
		
		//Progress Children
		if(pAiNode.mNumChildren > 0){
			pNode.m_Children = NewArray!Node(pAiNode.mNumChildren);
			for(size_t i=0;i<pAiNode.mNumChildren;i++){
				pNode.m_Children[i] = New!Node();
				ProgressNode(*(pAiNode.mChildren[i]),pNode.m_Children[i],pNode);
			}
		}
	}
	
	void DrawHelper(RenderGroup pGroup, StateObject pState, mat4 pTransformation, Node pNode, int pMaterialSet, int depth = -1)
	in {
		assert(pNode !is null,"pNode may not be null");
	}
	body {
		pTransformation = pNode.m_Transformation * pTransformation;	
		
		/*writef("\nDraw Transformation:");
		foreach(int i,f;pTransformation.f){
			if(i%4 == 0)
				writef("\n");
			writef("%s ",f);
		}
		writef("\n");*/
		
		//Draw meshes
		foreach(mesh;pNode.m_Meshes){
			assert(mesh.m_VertexBuffer !is null);
			Material material = m_Materials[pMaterialSet][mesh.m_Material];
			RenderCall DrawCall = pGroup.AddRenderCall();
			DrawCall.SetVertexBuffer(mesh.m_VertexBuffer);
			DrawCall.SetShader(material.GetShader());
			DrawCall.SetStateObject(pState);
			DrawCall.Overwrite(m_ModelMatrixConstant,pTransformation);
			
			//Bind textures
			auto textures = material.GetTextures();
			foreach(k, ref v; textures){
				DrawCall.AddTexture(v,k);
			}
			
			//do overwrites
			auto overwrites = material.GetOverwrites();
			foreach(k, ref v; overwrites){
				DrawCall.Overwrite(k,v);
			}
		}
		
		//Follow the tree
		if(depth > 0 || depth < 0){
			foreach(c;pNode.m_Children){
				DrawHelper(pGroup,pState,pTransformation,c,pMaterialSet,depth-1);
			}
		}
	}
	
	void DoFindMinMax(mat4 pTransformation, Node pNode, ref vec3 pMin, ref vec3 pMax)
	in {
		assert(pNode !is null, "pNode may not be null");
	}
	body
	{
		pTransformation = pNode.m_Transformation * pTransformation;
		//writefln("pNode = %x",cast(void*)pNode);
		//Search min-max for all meshes inside
		foreach(mesh; pNode.m_Meshes){
			//writefln("mesh = %x",cast(void*)mesh);
			if(mesh !is null && mesh.m_VertexBuffer !is null){
				vec4 min = pTransformation * mesh.m_Min;
				vec4 max = pTransformation * mesh.m_Max;

				//The transformation may swapped a axis, fix if neccsary
				if(min.x > max.x) swap(min.x,max.x);
				if(min.y > max.y) swap(min.y,max.y);
				if(min.z > max.z) swap(min.z,max.z);

				if(min.x < pMin.x) pMin.x = min.x;
				if(min.y < pMin.y) pMin.y = min.y;
				if(min.z < pMin.z) pMin.z = min.z;
				
				if(max.x > pMax.x) pMax.x = max.x;
				if(max.y > pMax.y) pMax.y = max.y;
				if(max.z > pMax.z) pMax.z = max.z;
			}
		}
		
		//Follow tree
		foreach(c;pNode.m_Children){
			DoFindMinMax(pTransformation,c,pMin,pMax);
		}
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
	
	vec4 Convert(ref const(aiVector3D) pData){
		vec4 result;
		with(result){
			x = pData.x; y = pData.y; z = pData.z; w = 1.0f;
		}
		return result;
	}
	
public:
	
	/**
	* consructor
	* Params:
	*		pManager = the vertex buffer manage to use by this model
	*/
	this(IVertexBufferManager pManager, IRendererInternal pRenderer)
	in {
		assert(pManager !is null,"pManager may not be null");
	}
	body {
		m_Renderer = pRenderer;
		m_Manager = pManager;
		
		m_Materials = New!(Vector!(Vector!(Material)))();
		m_Meshes = New!(Vector!Mesh)();
	}

  ~this()
  {
    foreach(set; m_Materials[])
    {
      Delete(set);
    }
    Delete(m_Materials);

    foreach(mesh; m_Meshes)
    {
      Delete(mesh);
    }
    Delete(m_Meshes);

    Delete(m_MaterialInfo);

    Delete(m_NodeLookup);

    Delete(m_RootNode);
  }
	
	/**
	 * Draws the model 
	 * Params:
	 *		modelMatrix = the model matrix
	 *		pGroup = RenderGroup to use as draw call container
	 *		pState = state to use for drawing
	 *		pMaterialSet = material set to use
	 */
	void Draw(ref const(mat4) modelMatrix, RenderGroup pGroup, StateObject pState, int pMaterialSet = 0)
 	in {
 		assert(m_RootNode !is null,"GenerateMeshes has not been called on this model");
 		assert(pMaterialSet >= 0 && pMaterialSet < m_Materials.size(),"There is no material set with the number " ~ to!string(pMaterialSet));
 	}
 	body {
 		DrawHelper(pGroup,pState,modelMatrix,m_RootNode,pMaterialSet);
	}
	
	/**
	 * Load the model from a file
	 * Params:
	 *		pFilename = filename of the file to load
	 */
	void LoadFile(rcstring pFilename)
	in {
		assert(m_RootNode is null,"LoadFile can only be called once");
	}
	body {
		m_Filename = pFilename;
		
    if(!thBase.file.exists(pFilename))
    {
      throw New!FileException(format("File '%s' does not exist", pFilename[]));
    }

    auto file = scopedRef!(ChunkFile)(New!ChunkFile(pFilename, Chunkfile.Operation.Read));

    if(file.startReading("model") != thResult.SUCCESS)
    {
      throw New!RCException(format("File '%s' is not a model format", pFilename[]));
    }

    if(file.fileVersion != ModelFormatVersion.Version1)
    {
      throw New!RCException(format("Model '%s' does have old format, please reexport", pFilename[]));
    }

    //Read the size info
    {
      file.startReadChunk();
      if(file.currentChunkName != "sizeinfo")
      {
        throw New!RCException(format("Expected sizeinfo chunk, got '%s' chunk in file '%s'", file.currentChunkName, pFilename[]));
      }

      size_t meshDataSize;

      uint numTextures;
      file.read(numTextures);
      meshDataSize += string.sizeof * numTextures;
      
      uint texturePathMemory;
      file.read(texturePathMemory);
      meshDataSize += texturePathMemory;

      uint numMeshes;
      file.read(numMeshes);
      meshDataSize += MeshData.sizeof * numMeshes;
      for(uint i=0; i<numMeshes; i++)
      {
        uint numVertices, PerVertexFlags, numComponents, numTexcoords;
        file.read(numVertices);
        file.read(PerVertexFlags);

        if(PerVertexFlags & PerVertexData.Position)
          numComponents++;
        if(PerVertexFlags & PerVertexData.Tangent)
          numComponents++;
        if(PerVertexFlags & PerVertexData.Bitangent)
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

        for(uint j=0; j<numTexcoords; j++)
        {
          ubyte numUVComponents;
          file.read(numUVComponents);
          meshDataSize += numVertices * numUVComponents * float.sizeof;
        }

        uint numFaces;
        file.read(numFaces);
        meshDataSize += numFaces * FaceData.sizeof;

        uint numMaterials;
        file.read(numMaterials);
        meshDataSize += numMaterials * MaterialData.sizeof;
      }

      uint numNodes,numNodeReferences,numMeshReferences,numTextureReferences;
      file.read(numNodes);
      file.read(numNodeReferences);
      file.read(numMeshReferences);
      file.read(numTextureReferences);
      
      meshDataSize += numNodes * NodeData.sizeof;
      meshDataSize += numNodeReferences * (NodeData*).sizeof;
      meshDataSize += numMeshReferences * (MeshData*).sizeof;
      meshDataSize += numTextureReferences * TextureReference.sizeof;

      file.endReadChunk();

      m_meshDataMemory = StdAllocator.globalInstance.AllocateMemory(meshDataSize);
      m_meshDataAllocator = New!(typeof(m_meshDataAllocator))(m_meshDataMemory);
    }

    m_modelData = AllocatorNew!ModelData(m_meshDataAllocator);
    
    // Load textures
    {
      file.startReadChunk();
      if(file.currentChunkName != "textures")
      {
        throw New!RCException("Expected 'textures' chunk but got '%s' chunk", file.currentChunkName);
      }

      uint numTextures;
      file.read(numTextures);

      if(numTextures > 0)
      {
        m_modelData.textures = AllocatorNewArray!string(m_meshDataAllocator, numTextures);
        foreach(ref texture; m_modelData.textures)
        {
          uint length;
          file.read(length);
          auto data = AllocatorNewArray!char(m_meshDataAllocator, length);
          file.read(data);
          texture = cast(string)data;
        }
      }

      file.endReadChunk();
    }

    // Read Materials
    {
      file.startReadChunk();
      if(file.currentChunkName != "materials")
      {
        throw New!RCException(format("Expected 'materials' chunk but go '%s'", file.currentChunkName));
      }

      uint numMaterials;
      file.read(numMaterials);

      if(numMaterials > 0)
      {
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
          material.textures = AllocatorNewArray!TextureReference(m_meshDataAllocator, numTextures);
          foreach(ref texture; material.textures)
          {
            uint textureIndex;
            file.read(textureIndex);
            texture.texture = m_modelData.texures[textureIndex];
            file.read(texture.semantic);
          }

          file.endReadChunk();
        }
      }

      file.endReadChunk();
    }


    // Read Meshes
    {
      file.startReadChunk();
      if(file.currentChunkName != "meshes")
      {
        throw New!RCException(format("Expected 'meshes' chunk but got '%s'", file.currentChunkName));
      }

      uint numMeshes;
      file.read(numMeshes);
      m_modelData.meshes = AllocatorNewArray!MeshData(m_meshDataAllocator, numMeshes);

      foreach(ref mesh; m_modelData.meshes)
      {
        file.startReadChunk();
        if(file.currentChunkName != "mesh")
        {
          throw New!RCException(format("Expected 'mesh' chunk but got '%s'", file.currentChunkName));
        }

        uint materialIndex;
        file.read(materialIndex);
        mesh.material = m_modelData.materials[materialIndex];

        uint numVertices;
        file.read(numVertices);

        mesh.vertices = AllocatorNewArray!(m_meshDataAllocator, numVertices, InitializeMemoryWith.NOTHING);
        file.read(mesh.vertices);

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
            mesh.normals = AllocatorNewArray!(m_meshDataAllocator, numVertices, InitializeMemoryWith.NOTHING);
            foreach(ref normal; mesh.normals)
            {
              normal.x = UncompressFloat();
              normal.y = UncompressFloat();
              normal.z = UncompressFloat();
            }
            file.endReadChunk();
            file.startReadChunk();
          }
          if(file.currentChunkName == "tangents")
          {
            mesh.tangents = AllocatorNewArray!(m_meshDataAllocator, numVertices, InitMemoryWith.NOTHING);
            foreach(ref tangent; mesh.tangents)
            {
              tangent.x = UncompressFloat();
              tangent.y = UncompressFloat();
              tangent.z = UncompressFloat();
            }
            file.endReadChunk();
            file.startReadChunk();
          }
          if(file.currentChunkName == "bitangents")
          {
            mesh.bitangents = AllocatorNewArray!(m_meshDataAllocator, numVertices, InitMemoryWith.NOTHING);
            foreach(ref bitangent; mesh.bitangents)
            {
              tangent.x = UncompressFloat();
              tangent.y = UncompressFloat();
              tangent.z = UncompressFloat();
            }
            file.endReadChunk();
            file.startReadChunk();
          }
          if(file.currentChunkName == "texcoords")
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
              mesh.texcoords[j] = AllocatorNewArray!vec2(m_meshDataAllocator, numVertices, InitMemoryWith.NOTHING);
              file.read((cast(float*)mesh.texcoords[j].ptr)[0..numVertices*2]);
            }
            file.endReadChunk();
            file.startReadChunk();
          }
          if(file.currentChunkName == "faces")
          {
            uint numFaces;
            file.read(numFaces);
            mesh.faces = AllocatorNewArray!FaceData(m_meshDataAllocator, numFaces, InitMemoryWith.NOTHING);
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
		
		m_Scene = scene;
		
		m_Materials.push_back(New!(Vector!Material)());
		m_Materials[0].resize(m_Scene.mNumMaterials);
		
		//auto f = File("mats.txt", "w");
		if(m_Scene.mMaterials !is null){
			m_MaterialInfo = NewArray!MaterialInfo(m_Scene.mNumMaterials);
      foreach(ref info; m_MaterialInfo)
      {
        info.init();
      }

			for(int i=0;i<m_Scene.mNumMaterials;i++){
				//f.writefln("Material %d",i);
				const(aiMaterial*) mat = m_Scene.mMaterials[i];
					for(int j=0;j<mat.mNumProperties;j++){
						const(aiMaterialProperty*) prop = mat.mProperties[j];
							//texturen
							//f.writefln("property '%s'",prop.mKey.data[0..prop.mKey.length]);
							if(prop.mKey.data[0..prop.mKey.length] == "$tex.file"){
								ModelTextureInfo temp;
								//temp.name = to!string(prop.mKey.data[5..(prop.mKey.length)]);
								temp.file = rcstring(prop.mData[4..prop.mDataLength-1]);
								if(temp.file != "$texture.png"){
									switch(prop.mSemantic){
										case aiTextureType.DIFFUSE:
											temp.name = "diffuse";
											temp.type = TextureType.DIFFUSE;
											break;
										case aiTextureType.AMBIENT:
											temp.name = "ambient";
											temp.type = TextureType.AMBIENT;
											break;
										case aiTextureType.DISPLACEMENT:
											temp.name = "displacement";
											temp.type = TextureType.DISPLACEMENT;
											break;
										case aiTextureType.EMISSIVE:
											temp.name = "emissive";
											temp.type = TextureType.EMISSIVE;
											break;
										case aiTextureType.HEIGHT:
											temp.name = "height";
											temp.type = TextureType.HEIGHT;
											break;
										case aiTextureType.LIGHTMAP:
											temp.name = "lightmap";
											temp.type = TextureType.LIGHTMAP;
											break;
										case aiTextureType.NONE:
											temp.name = "none";
											temp.type = TextureType.NONE;
											break;
										case aiTextureType.NORMALS:
											temp.name = "normals";
											temp.type = TextureType.NORMALS;
											break;
										case aiTextureType.OPACITY:
											temp.name = "opacity";
											temp.type = TextureType.OPACITY;
											break;
										case aiTextureType.REFLECTION:
											temp.name = "reflection";
											temp.type = TextureType.REFLECTION;
											break;
										case aiTextureType.SPECULAR:
											temp.name = "specular";
											temp.type = TextureType.SPECULAR;
											break;
										default:
											temp.name = "unknown";
											temp.type = TextureType.UNKOWN;
											break;
									}
									m_MaterialInfo[i].textures.push_back(temp);
								}
							}
							else {
								Overwrite temp;
								bool interpreted = true;
								switch(prop.mType){
									case aiPropertyTypeInfo.Float:
										{
											int size = prop.mDataLength / float.sizeof;
											switch(size){
												case 1:
													temp.Set(*cast(float*)prop.mData);
													break;
												case 2:
													temp.Set(vec2((cast(float*)(prop.mData))[0],(cast(float*)(prop.mData))[1]));
													break;
												case 3:
													temp.Set(vec3((cast(float*)(prop.mData))[0],(cast(float*)(prop.mData))[1],(cast(float*)(prop.mData))[2]));
													break;
												case 4:
													temp.Set(vec4((cast(float*)(prop.mData))[0],(cast(float*)(prop.mData))[1],(cast(float*)(prop.mData))[2],(cast(float*)(prop.mData))[3]));
													break;
												/*case 5:
													{
														mat2 data = mat2((cast(float*)prop.mData)[1..5]);
														data.Transpose();
														temp.Set(data);
														foreach(c,w;data.f){
															f.writef("%f ",w);
															if(c%2==1)
																f.writefln("");
														}
													}
													break;*/
												case 9:
													{
														mat3 data = mat3((cast(float*)(prop.mData))[0..9]);
														data.Transpose();
														temp.Set(data);
														//foreach(c,w;data.f){
															//f.writef("%f ",w);
															//if(c%3==2)
																//f.writefln("");
														//}
													}
													break;
												case 16:
													{
														mat4 data = mat4((cast(float*)(prop.mData))[0..16]);
														data.Transpose();
														temp.Set(data);
														/*foreach(c,w;data.f){
															f.writef("%f ",w);
															if(c%4==3)
																f.writefln("");
														}*/
													}
													break;
												default:
													base.logger.warn("Warning: Property '%s' of Material '%d' has unhandeld size '%d' of floats and was therefor ignored", prop.mKey.data[0..(prop.mKey.length-1)], i, size);
													break;
											}
										}
										break;
									case aiPropertyTypeInfo.Integer:
										{
											int size = prop.mDataLength / int.sizeof;
											switch(size){
												case 1:
													temp.Set(*cast(int*)prop.mData);
													//f.writefln("%d",*cast(int*)prop.mData);
													break;
												default:
													base.logger.warn("Warning: Property '%s' of Material '%d' has unhandeld size '%d' of ints and was therefor ignored", prop.mKey.data[0..(prop.mKey.length-1)], i, size);
													break;
											}
										}
										break;
									default:
										interpreted = false;
										break;
								}
								if(interpreted){
                  auto propertyName = rcstring(prop.mKey.data[0..(prop.mKey.length-1)]);
									m_MaterialInfo[i].properties[propertyName] = temp;
								}
							}
					}
			}
		}
		//f.flush();
		//f.close();
	}
	
	/**
	 * Generates the meshes
	 */
	void GenerateMeshes()
	in {
		assert(m_RootNode is null,"Generate meshes can only be called once");
		assert(m_Scene !is null,"No file has been loaded yet");
		int j=0;
		foreach(ref set;m_Materials.GetRange()){
			//writefln("set %d",j);
			int i=0;
			foreach(ref mat;set.GetRange()){
				//writefln("material %d = %x",i,cast(void*)mat);
        debug
        {
          if(mat is null)
          {
            auto msg = format("Material %d inside set %d is null", i, j);
				    assert(0, msg[]);
          }
          if(mat.GetShader() is null)
          {
            auto msg = format("No shader has been set for material %d set %d", i, j)[];
            assert(0, msg[]);
          }
        }
				
				i++;
			}
			j++;
		}
	}
	body {
		//Progress Nodes
		m_Meshes.resize(m_Scene.mNumMeshes);
		foreach(ref m;m_Meshes.GetRange()){
			m = New!Mesh();
		}
		m_RootNode = New!Node();
		ProgressNode(*m_Scene.mRootNode,m_RootNode,null);
		
		//writefln("finished generating nodes");
		
		//Generate Meshes
		int i=0;
		foreach(ref mesh;m_Meshes.GetRange()){
			const(aiMesh)* aimesh = m_Scene.mMeshes[i];
			//writefln("aimesh=%x",aimesh);
			
			//Generate a array of attributes we need
      VertexBuffer.DataChannels DataChannelBuffer[16];
      VertexBuffer.DataChannels DataChannelBuffer2[16];
			auto NeededChannels = m_Materials[0][aimesh.mMaterialIndex].GetShader().GetNeededDataChannels(DataChannelBuffer);
			foreach(mat;m_Materials.GetRange()){
				foreach(channel;mat[aimesh.mMaterialIndex].GetShader().GetNeededDataChannels(DataChannelBuffer2)){
					bool found=false;
					foreach(c;NeededChannels){
						if(c == channel){
							found = true;
							break;
						}
					}
					if(!found){
            DataChannelBuffer[NeededChannels.length] = channel;
						NeededChannels = DataChannelBuffer[0..(NeededChannels.length+1)];
					}
				}
			}
			
			insertionSort(NeededChannels);
			
			//Lets check if the mesh that we are loading has all the requested datachannels
			int VertexSize = 0;
			foreach(channel;NeededChannels){
				switch(channel){
					case VertexBuffer.DataChannels.NORMAL:
						if(aimesh.mNormals is null){
							throw New!ModelException(format("Error loading file '%s' normal requested but not in mesh no %d", m_Filename[], i));
						}
						break;
					case VertexBuffer.DataChannels.BINORMAL:
					case VertexBuffer.DataChannels.TANGENT:
						if(aimesh.mTangents is null || aimesh.mBitangents is null){
							throw New!ModelException(format("Error loading file '%s' tangent and binormal requested but not in mesh no %d", m_Filename[], i));
						}
						break;
					case VertexBuffer.DataChannels.TEXCOORD0:
					case VertexBuffer.DataChannels.TEXCOORD1:
					case VertexBuffer.DataChannels.TEXCOORD2:
					case VertexBuffer.DataChannels.TEXCOORD3:
						if(aimesh.mTextureCoords[channel - (VertexBuffer.DataChannels.TEXCOORD0)] is null){
							throw New!ModelException(format("Error loading file '%s' texcoord %d requested but not found in mesh no %d", m_Filename[], channel - (VertexBuffer.DataChannels.TEXCOORD0), i));
						}
						break;
					case VertexBuffer.DataChannels.POSITION:
						if(aimesh.mVertices is null){
							throw New!ModelException(format("Error loading file '%s' position requested but not in mesh no %d", m_Filename[], i));
						}
						break;
					case VertexBuffer.DataChannels.BONEIDS:
						//TODO
						break;
					case VertexBuffer.DataChannels.BONEWEIGHTS:
						//TODO
						break;
					default:
						throw New!ModelException(format("Error loading '%s' request of not supported data channel", m_Filename[]));
				}
			}
			
			//Insert the data into the vertex buffer
			VertexBuffer.IndexBufferSize IndexBufferSize = VertexBuffer.IndexBufferSize.INDEX16;
			if(aimesh.mNumVertices > 65536){ //32-bit Index Buffer?
				IndexBufferSize = VertexBuffer.IndexBufferSize.INDEX32;
			}
			
			VertexBuffer vb = null; /*m_Manager.Search(NeededChannels,
			                                  VertexBuffer.Primitive.TRIANGELS,
			                                  IndexBufferSize,
			                                  aimesh.mNumVertices,
			                                  aimesh.mNumFaces);*/
			
			if(vb is null){
				vb = New!VertexBuffer(m_Renderer,NeededChannels,VertexBuffer.Primitive.TRIANGLES,IndexBufferSize,false);
				m_Manager.Add(vb,NeededChannels,VertexBuffer.Primitive.TRIANGLES,IndexBufferSize);
				vb.AddIndexBuffer();
			}
			
			mesh.m_VertexBuffer = vb;
			mesh.m_Start = vb.GetNumberOfIndicies(0);
			mesh.m_Size = aimesh.mNumFaces * 3;
			mesh.m_Min = vec4(float.max,float.max,float.max,1.0f);
			mesh.m_Max = vec4(-float.max,-float.max,-float.max,1.0f);
			mesh.m_Material = aimesh.mMaterialIndex;
			size_t IndexOffset = vb.GetVerticesInBuffer();
			
			for(size_t j=0;j<aimesh.mNumVertices;j++){
				
				if(aimesh.mVertices[j].x < mesh.m_Min.x) mesh.m_Min.x = aimesh.mVertices[j].x;
				if(aimesh.mVertices[j].y < mesh.m_Min.y) mesh.m_Min.y = aimesh.mVertices[j].y;
				if(aimesh.mVertices[j].z < mesh.m_Min.z) mesh.m_Min.z = aimesh.mVertices[j].z;
				
				if(aimesh.mVertices[j].x > mesh.m_Max.x) mesh.m_Max.x = aimesh.mVertices[j].x;
				if(aimesh.mVertices[j].y > mesh.m_Max.y) mesh.m_Max.y = aimesh.mVertices[j].y;
				if(aimesh.mVertices[j].z > mesh.m_Max.z) mesh.m_Max.z = aimesh.mVertices[j].z;
				
				foreach(channel;NeededChannels){
					switch(channel){
						case VertexBuffer.DataChannels.POSITION:
							assert(VertexBuffer.DataChannelSize(channel) <= 3 && VertexBuffer.DataChannelSize(channel) > 0);
							vb.AddVertexData((&aimesh.mVertices[j].x)[0..VertexBuffer.DataChannelSize(channel)]);
							break;
						case VertexBuffer.DataChannels.NORMAL:
							assert(VertexBuffer.DataChannelSize(channel) <= 3 && VertexBuffer.DataChannelSize(channel) > 0);
							vb.AddVertexData((&aimesh.mNormals[j].x)[0..VertexBuffer.DataChannelSize(channel)]);
							break;
						case VertexBuffer.DataChannels.BINORMAL:
							assert(VertexBuffer.DataChannelSize(channel) <= 3 && VertexBuffer.DataChannelSize(channel) > 0);
							vb.AddVertexData((&aimesh.mBitangents[j].x)[0..VertexBuffer.DataChannelSize(channel)]);
							break;
						case VertexBuffer.DataChannels.TANGENT:
							assert(VertexBuffer.DataChannelSize(channel) <= 3 && VertexBuffer.DataChannelSize(channel) > 0);
							vb.AddVertexData((&aimesh.mTangents[j].x)[0..VertexBuffer.DataChannelSize(channel)]);
							break;
						case VertexBuffer.DataChannels.TEXCOORD0:
						case VertexBuffer.DataChannels.TEXCOORD1:
						case VertexBuffer.DataChannels.TEXCOORD2:
						case VertexBuffer.DataChannels.TEXCOORD3:
							{
								int index = channel - VertexBuffer.DataChannels.TEXCOORD0;
								assert(index >= 0 && index < 4);
								assert(VertexBuffer.DataChannelSize(channel) <= aimesh.mNumUVComponents[index] && VertexBuffer.DataChannelSize(channel) > 0);
								assert(aimesh.mTextureCoords[index] !is null);
								vb.AddVertexData((&aimesh.mTextureCoords[index][j].x)[0..VertexBuffer.DataChannelSize(channel)]);
							}
							break;
						case VertexBuffer.DataChannels.BONEIDS:
							assert(0,"TODO");
						case VertexBuffer.DataChannels.BONEWEIGHTS:
							assert(0,"TODO");						
						default:
							assert(0,"Trying to add unsupported data type to vertex buffer");
					}
				}
			}
			
			for(size_t f=0;f<aimesh.mNumFaces;f++){
				if(aimesh.mFaces[f].mNumIndices != 3){
					throw New!ModelException(_T("Trying to load a non triangle model"));
				}
				
				uint[3] Indices;
				for(int c=0;c<3;c++)
					Indices[c] = aimesh.mFaces[f].mIndices[c] + IndexOffset;
				vb.AddIndexData(0,Indices);
			}
			vb.Check();
			m_Manager.AddVertexBufferToUpdate(vb);
			
			i++;
		}
		
		//Clean up
		Assimp.ReleaseImport(cast(aiScene*)m_Scene); //We can cast away const here because its going to C
		m_Scene = null;
		
		//writefln("finished generating meshes");
	}
	
	/**
	 * gets the number of materials used
	 */
	size_t GetNumMaterials(){
		return m_Materials[0].size();
	}
	
	/**
	 * sets the number of material sets
	 * Params:
	 *		pNumMaterialSets = number of material sets to reserve
	 */
	void SetNumMaterialSets(size_t pNumMaterialSets)
	in {
		assert(pNumMaterialSets >= 1,"There has to be at least 1 material set");
	}
	body {
		m_Materials.resize(pNumMaterialSets);
		for(size_t i=0;i<pNumMaterialSets;i++){
			if(m_Materials[i] is null){
				m_Materials[i] = New!(Vector!Material)();
			}
			if(m_Materials[0].size() != m_Materials[i].size()){
				m_Materials[i].resize(m_Materials[0].size());
			}
		}
	}
	
	/**
	 * sets a material
	 * Params:
	 *		pSet = the set to use
	 *		pNum = the number of the material
	 *		pMaterial = the material
	 */
	void SetMaterial(int pSet, int pNum, Material pMaterial)
	in {
		assert(pSet >= 0 && pSet < m_Materials.size(),"pSet is out of range");
		assert(pNum >= 0 && pNum < m_Materials[0].size(),"pNum ist out of range");
		assert(pMaterial !is null,"pMaterial may not be null");
	}
	body {
		m_Materials[pSet][pNum] = pMaterial;
	}
	
	/**
	 * gets a material
	 * Params:
	 *		pSet = the set to use
	 *		pNum = the number of the material
	 * Returns: the material
	 */
	Material GetMaterial(int pSet, int pNum)
	in {
		assert(pSet >= 0 && pSet < m_Materials.size(),"pSet is out of range");
		assert(pNum >= 0 && pNum < m_Materials[0].size(),"pNum ist out of range");
	}
	body {
		return m_Materials[pSet][pNum];
	}
	
	/**
	 * Gets the info about the materiales used in the loaded model file
	 * Has to be called after the model file has been loaded
	 * Returns: A array of MaterialInfo structs
	 */ 
	MaterialInfo[] GetMaterialInfo(){
		return m_MaterialInfo;
	}
	
	/**
	 * Sets the bone and ModelMatrix constants to be used by the model implementation
	 * Params:
	 *		pModelMatrixConstant = the model matrix constant to use
	 *		pBonesConstant = the bones constant to use
	 */
	static void SetConstants(ShaderConstant pModelMatrixConstant, ShaderConstant pBonesConstant)
	in {
		assert(pModelMatrixConstant !is null,"pModelMatrixConstant may not be null");
		//assert(pBonesConstant !is null,"pBoneConstant may not be null");
	}
	body {
		m_ModelMatrixConstant = pModelMatrixConstant;
		m_BonesConstant = pBonesConstant;
	}
	
	/**
	 * Searches for the minimum and maximum coordinates of the model
	 * Params:
	 *		pMin = result minimum
	 *		pMax = result maximum
	 *		pApplyModelMatrix = if the model matrix should be applied to the result or not
	 */
	void FindMinMax(ref vec3 pMin, ref vec3 pMax){
		mat4 m = mat4.Identity();
		pMin = vec3(float.max);
		pMax = vec3(-float.max);
		DoFindMinMax(m,m_RootNode,pMin,pMax);
	}
	
	void FindMinMax(ref vec3 pMin, ref vec3 pMax) shared {
		(cast(Model)this).FindMinMax(pMin,pMax);
	}
	
	private void DoPrintNodes(Node node, int depth = 0){
		auto res = node.m_Name;
		for(int i=0;i<depth;i++)
			res = "  " ~ res;
		base.logger.info(res[]);
		foreach(child;node.m_Children)
			DoPrintNodes(child,depth+1);
	}
	
	override void PrintNodes() {
		DoPrintNodes(m_RootNode);
	}
	
	override void PrintNodes() shared {
		(cast(Model)this).PrintNodes();
	}
	
	override ISubModel GetSubModel(int depth, string[] path)
	in {
		assert(path.length >= 1,"no path given");
		assert(depth == -1 || depth >= 0,"invalid depth value");
	}
	body {
		size_t[] indexPath = new size_t[path.length-1];
		string curPath=path[0];
		Node curNode = m_RootNode;
		if(m_RootNode.m_Name != path[0]){
			throw New!RCException(format("The node %s does not exist", curPath));
		}
		for(int i=1;i<path.length;i++){
			curPath ~= "." ~ path[i];
			Node nextNode = null;
			foreach(size_t j,child;curNode.m_Children){
				if(child.m_Name == path[i]){
					nextNode = child;
					indexPath[i-1] = j;
				}
			}
			if(nextNode is null){
				throw New!RCException(format("The node '%s' does not exist", curPath));
			}
			curNode = nextNode;
		}
		return new SubModel(curNode,depth,indexPath);
	}
	
	override shared(ISubModel) GetSubModel(int depth, string[] path) shared {
		//whohoo shared casts
		return cast(shared(ISubModel))((cast(Model)this).GetSubModel(depth,path));
	}
	
	rcstring fileName(){
		return m_Filename;
	}
}
