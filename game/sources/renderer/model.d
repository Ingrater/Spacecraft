module renderer.model;

import base.renderer;
import base.modelloader;
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
import thBase.constref;
import thBase.enumbitfield;
import thBase.logging;

import renderer.exceptions;
import thBase.container.vector;
import thBase.container.hashmap;
import thBase.policies.hashing;

import renderer.internal;
import thBase.math;
import thBase.string;
import thBase.algorithm;
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

	/**
	 * Information about a texture needed by the model
	 */
	struct ModelTextureInfo {
		rcstring name; /// texture type as string
		rcstring file; /// texture file path
		TextureType type; /// texture type
		int index; /// used texture channel
	}
	
	class SubModel : ISubModel, IDrawModel {
		private:
			const(ModelLoader.NodeDrawData*) m_SubRootNode;
			int m_Depth;
			size_t[] m_Path;
		public:
			this(const(ModelLoader.NodeDrawData*) rootNode, int depth, size_t[] path){
				m_SubRootNode = rootNode;
				m_Depth = depth;
				m_Path = path;
			}
		
			override void Draw(ref const(mat4) modelMatrix, RenderGroup pGroup, StateObject pState, int pMaterialSet = 0){
				mat4 trans = modelMatrix * m_modelLoader.modelData.rootNode.transform;
				ConstPtr!(ModelLoader.NodeDrawData) curNode = m_modelLoader.modelData.rootNode;
				foreach(index;m_Path){
					curNode = curNode.children[index];
					if(curNode == m_SubRootNode)
						break;
					trans = trans * curNode.transform;
				}
				DrawHelper(pGroup,pState,trans,m_SubRootNode,pMaterialSet,m_Depth);
			}
			
			override void FindMinMax(ref vec3 min, ref vec3 max){
				mat4 trans = m_modelLoader.modelData.rootNode.transform;
				ConstPtr!(ModelLoader.NodeDrawData) curNode = m_modelLoader.modelData.rootNode;
				foreach(index;m_Path){
					curNode = curNode.children[index];
					if(curNode == m_SubRootNode)
						break;
					trans = trans * curNode.transform;
				}
				DoFindMinMax(trans,m_SubRootNode,min,max);
			}
			
			override void FindMinMax(ref vec3 min, ref vec3 max) shared {
				(cast(SubModel)this).FindMinMax(min,max);
			}
	}
	
private:

  static struct MeshDrawData
  {
    VertexBuffer vertexBuffer;
    size_t startIndex, numIndices, materialIndex;

    ~this()
    {
      Delete(vertexBuffer);
    }
  }

	Vector!(Vector!(Material)) m_Materials;
	IVertexBufferManager m_Manager;
	IRendererInternal m_Renderer;
  composite!ModelLoader m_modelLoader;
  composite!(Vector!MeshDrawData) m_meshDrawData;
	
	Hashmap!(string, ModelLoader.NodeDrawData*, StringHashPolicy) m_NodeLookup;
	bool m_NeedsNodeLookup = false;
	
	static ShaderConstant m_ModelMatrixConstant;
	static ShaderConstant m_BonesConstant;
	
	void DrawHelper(RenderGroup pGroup, StateObject pState, mat4 pTransformation, const(ModelLoader.NodeDrawData*) pNode, int pMaterialSet, int depth = -1)
	in {
		assert(pNode !is null,"pNode may not be null");
	}
	body {
		pTransformation = pNode.transform * pTransformation;	
		
		/*writef("\nDraw Transformation:");
		foreach(int i,f;pTransformation.f){
			if(i%4 == 0)
				writef("\n");
			writef("%s ",f);
		}
		writef("\n");*/
		
		//Draw meshes
		foreach(meshIndex; pNode.meshes){
			MeshDrawData* drawData = &m_meshDrawData[meshIndex];
			Material material = m_Materials[pMaterialSet][drawData.materialIndex];
			RenderCall DrawCall = pGroup.AddRenderCall();
			DrawCall.SetVertexBuffer(drawData.vertexBuffer);
			DrawCall.SetShader(material.GetShader());
			DrawCall.SetStateObject(pState);
			DrawCall.Overwrite(m_ModelMatrixConstant, pTransformation);
			
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
			foreach(c; pNode.children){
				DrawHelper(pGroup, pState, pTransformation, c, pMaterialSet, depth-1);
			}
		}
	}
	
	void DoFindMinMax(mat4 pTransformation, const(ModelLoader.NodeDrawData*) pNode, ref vec3 pMin, ref vec3 pMax)
	in {
		assert(pNode !is null, "pNode may not be null");
	}
	body
	{
		pTransformation = pNode.transform * pTransformation;
		//writefln("pNode = %x",cast(void*)pNode);
		//Search min-max for all meshes inside
		foreach(meshIndex; pNode.meshes){
			const(ModelLoader.MeshData*) meshData = &m_modelLoader.modelData.meshes[meshIndex];
			vec4 min = pTransformation * meshData.bbox.min;
			vec4 max = pTransformation * meshData.bbox.max;

			//The transformation may swapped a axis, fix if neccesary
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
		
		//Follow tree
		foreach(c;pNode.children){
			DoFindMinMax(pTransformation,c,pMin,pMax);
		}
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
    m_modelLoader = composite!ModelLoader(DefaultCtor());
    m_modelLoader.construct();
    m_meshDrawData = typeof(m_meshDrawData)(DefaultCtor());
    m_meshDrawData.construct();
	}

  ~this()
  {
    foreach(set; m_Materials[])
    {
      Delete(set);
    }
    Delete(m_Materials);

    Delete(m_NodeLookup);
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
 		DrawHelper(pGroup, pState, modelMatrix, m_modelLoader.modelData.rootNode, pMaterialSet);
	}

  /**
   * Loads the model from a file
   */
  void LoadFile(rcstring filename)
  {
    m_modelLoader.LoadFile(filename, Flags(ModelLoader.Load.Everything));
  }
	
	/**
	 * Generates the meshes
	 */
	void GenerateMeshes()
	in {
		assert(m_modelLoader.modelData.hasData, "No file has been loaded yet");
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
		//Generate Meshes
    m_meshDrawData.resize(m_modelLoader.modelData.meshes.length);
		foreach(size_t i, ref mesh;m_modelLoader.modelData.meshes){
			
			//Generate a array of attributes we need
      VertexBuffer.DataChannels DataChannelBuffer[16];
      VertexBuffer.DataChannels DataChannelBuffer2[16];
			auto NeededChannels = m_Materials[0][mesh.materialIndex].GetShader().GetNeededDataChannels(DataChannelBuffer);
			foreach(mat;m_Materials.GetRange()){
				foreach(channel;mat[mesh.materialIndex].GetShader().GetNeededDataChannels(DataChannelBuffer2)){
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
						if(mesh.normals.length == 0){
							throw New!ModelException(format("Error loading file '%s' normal requested but not in mesh no %d", m_modelLoader.filename[], i));
						}
						break;
					case VertexBuffer.DataChannels.BINORMAL:
					case VertexBuffer.DataChannels.TANGENT:
						if(mesh.tangents.length == 0 || mesh.bitangents.length == 0){
							throw New!ModelException(format("Error loading file '%s' tangent and binormal requested but not in mesh no %d", m_modelLoader.filename[], i));
						}
						break;
					case VertexBuffer.DataChannels.TEXCOORD0:
					case VertexBuffer.DataChannels.TEXCOORD1:
					case VertexBuffer.DataChannels.TEXCOORD2:
					case VertexBuffer.DataChannels.TEXCOORD3:
						if(mesh.texcoords[channel - (VertexBuffer.DataChannels.TEXCOORD0)].length == 0){
							throw New!ModelException(format("Error loading file '%s' texcoord %d requested but not found in mesh no %d", m_modelLoader.filename[], channel - (VertexBuffer.DataChannels.TEXCOORD0), i));
						}
						break;
					case VertexBuffer.DataChannels.POSITION:
						if(mesh.vertices.length == 0){
							throw New!ModelException(format("Error loading file '%s' position requested but not in mesh no %d", m_modelLoader.filename[], i));
						}
						break;
					case VertexBuffer.DataChannels.BONEIDS:
						//TODO
						break;
					case VertexBuffer.DataChannels.BONEWEIGHTS:
						//TODO
						break;
					default:
						throw New!ModelException(format("Error loading '%s' request of not supported data channel", m_modelLoader.filename[]));
				}
			}
			
			//Insert the data into the vertex buffer
			VertexBuffer.IndexBufferSize IndexBufferSize = VertexBuffer.IndexBufferSize.INDEX16;
			if(mesh.vertices.length > ushort.max){ //32-bit Index Buffer?
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
			
			m_meshDrawData[i].vertexBuffer = vb;
		  m_meshDrawData[i].startIndex = vb.GetNumberOfIndicies(0);
			m_meshDrawData[i].numIndices = mesh.faces.length * 3;

			size_t IndexOffset = vb.GetVerticesInBuffer();
			
			for(size_t j=0;j<mesh.vertices.length;j++){				
				foreach(channel;NeededChannels){
					switch(channel){
						case VertexBuffer.DataChannels.POSITION:
							assert(VertexBuffer.DataChannelSize(channel) <= 3 && VertexBuffer.DataChannelSize(channel) > 0);
							vb.AddVertexData(mesh.vertices[j].f[0..VertexBuffer.DataChannelSize(channel)]);
							break;
						case VertexBuffer.DataChannels.NORMAL:
							assert(VertexBuffer.DataChannelSize(channel) <= 3 && VertexBuffer.DataChannelSize(channel) > 0);
							vb.AddVertexData(mesh.normals[j].f[0..VertexBuffer.DataChannelSize(channel)]);
							break;
						case VertexBuffer.DataChannels.BINORMAL:
							assert(VertexBuffer.DataChannelSize(channel) <= 3 && VertexBuffer.DataChannelSize(channel) > 0);
							vb.AddVertexData(mesh.bitangents[j].f[0..VertexBuffer.DataChannelSize(channel)]);
							break;
						case VertexBuffer.DataChannels.TANGENT:
							assert(VertexBuffer.DataChannelSize(channel) <= 3 && VertexBuffer.DataChannelSize(channel) > 0);
							vb.AddVertexData(mesh.tangents[j].f[0..VertexBuffer.DataChannelSize(channel)]);
							break;
						case VertexBuffer.DataChannels.TEXCOORD0:
						case VertexBuffer.DataChannels.TEXCOORD1:
						case VertexBuffer.DataChannels.TEXCOORD2:
						case VertexBuffer.DataChannels.TEXCOORD3:
							{
								int index = channel - VertexBuffer.DataChannels.TEXCOORD0;
								assert(index >= 0 && index < 4);
								assert(VertexBuffer.DataChannelSize(channel) == 2); //currently only 2 component uv channels supported
								assert(mesh.texcoords[index].length > 0);
								vb.AddVertexData(mesh.texcoords[index][j].f[0..VertexBuffer.DataChannelSize(channel)]);
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
			
			foreach(ref face; mesh.faces){
				uint[3] Indices;
				for(int c=0;c<3;c++)
					Indices[c] = face.indices[c] + IndexOffset;
				vb.AddIndexData(0, Indices);
			}
			vb.Check();
			m_Manager.AddVertexBufferToUpdate(vb);
		}
	}
	
	/**
	 * gets the number of materials used
	 */
	size_t GetNumMaterials(){
		return m_modelLoader.modelData.materials.length;
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
		  m_Materials[i].resize(GetNumMaterials());
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
	const(ModelLoader.MaterialData)[] GetMaterialInfo(){
		return m_modelLoader.modelData.materials;
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
	 */
	void FindMinMax(ref vec3 pMin, ref vec3 pMax){
		mat4 m = mat4.Identity();
		pMin = vec3(float.max);
		pMax = vec3(-float.max);
		DoFindMinMax(m, m_modelLoader.modelData.rootNode, pMin, pMax);
	}
	
	void FindMinMax(ref vec3 pMin, ref vec3 pMax) shared {
		(cast(Model)this).FindMinMax(pMin,pMax);
	}
	
	private void DoPrintNodes(const(ModelLoader.NodeDrawData*) node, int depth = 0){
    static string empty = "                                    ";
		logInfo("%s%s", empty[0..depth], node.data.name);
		foreach(child; node.children)
			DoPrintNodes(child, depth+1);
	}
	
	override void PrintNodes() {
		DoPrintNodes(m_modelLoader.modelData.rootNode);
	}
	
	override void PrintNodes() shared {
		(cast(Model)this).PrintNodes();
	}
	
	override ISubModel GetSubModel(int depth, scope string[] path)
	in {
		assert(path.length >= 1,"no path given");
		assert(depth == -1 || depth >= 0,"invalid depth value");
	}
	body {
		size_t[] indexPath = NewArray!size_t(path.length-1);
    scope(failure) Delete(indexPath);
		string curPath=path[0];
		ConstPtr!(ModelLoader.NodeDrawData) curNode = m_modelLoader.modelData.rootNode;
		if(curNode.data.name != path[0]){
			throw New!RCException(format("The node %s does not exist", curPath));
		}
		for(int i=1;i<path.length;i++){
			curPath ~= "." ~ path[i];
			ConstPtr!(ModelLoader.NodeDrawData) nextNode = null;
			foreach(size_t j,child;curNode.children){
				if(child.data.name == path[i]){
					nextNode = child;
					indexPath[i-1] = j;
				}
			}
			if(nextNode is null){
				throw New!RCException(format("The node '%s' does not exist", curPath));
			}
			curNode = nextNode;
		}
		return new SubModel(curNode, depth, indexPath);
	}
	
	override shared(ISubModel) GetSubModel(int depth, string[] path) shared {
		//whohoo shared casts
		return cast(shared(ISubModel))((cast(Model)this).GetSubModel(depth,path));
	}
	
	rcstring fileName(){
		return m_modelLoader.filename;
	}
}
