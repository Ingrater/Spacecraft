module renderer.vertexbuffer;

import thBase.container.vector;
import thBase.math3d.vecs;
import renderer.opengl;

import thBase.logging;
import thBase.casts;
import core.stdc.stdlib;
import base.all;
import renderer.internal;

/**
 * class to wrap vertex buffer internals
 */
final class VertexBuffer {
public:
	/**
	 * possible data channels a attribute can have
	 */ 
	enum DataChannels : uint {
		POSITION = 0, /**< position */
		POSITION_2, /**< 2d position */
		COLOR, /**< vertex color */
		NORMAL, /**< normal */
		BINORMAL, /**< binormal */
		TANGENT, /**< tangent */
		TEXCOORD0, /**< texturecoordinate channel 0 */
		TEXCOORD0_3, /**< texturecoordinate channel 0 3d */
		TEXCOORD1, /**< texturecoordinate channel 1 */
		TEXCOORD1_3, /**< texturecoordinate channel 1 3d */
		TEXCOORD2, /**< texturecoordinate channel 2 */
		TEXCOORD2_3, /**< texturecoordinate channel 2 3d */
		TEXCOORD3, /**< texturecoordinate channel 3 */
		TEXCOORD3_3, /**< texturecoordinate channel 3 3d */
		UNFOLDING, /**< unfolding for particels */
		BONEIDS, /**< bone ids for animation */
		BONEWEIGHTS, /**< bone weights for animation */
		UNDEFDATA0, /**< undefined data 0 */
		UNDEFDATA0_1, /**<undefined data 0 size 1 */
		UNDEFDATA1, /**< undefined data 1 */
		UNDEFDATA2, /**< undefined data 2 */
		UNDEFDATA3, /**< undefined data 3 */
	};
	
	static uint DataChannelSize(DataChannels pChannel){
		final switch(pChannel){
			case DataChannels.BINORMAL:
				return 3;
			case DataChannels.BONEIDS:
				return 4; //TODO
			case DataChannels.BONEWEIGHTS:
				return 4; //TODO
			case DataChannels.COLOR:
				return 4;
			case DataChannels.NORMAL:
				return 3;
			case DataChannels.POSITION:
				return 3;
			case DataChannels.POSITION_2:
				return 2;
			case DataChannels.TANGENT:
				return 3;
			case DataChannels.TEXCOORD0:
				return 2;
			case DataChannels.TEXCOORD0_3:
				return 3;
			case DataChannels.TEXCOORD1:
				return 2;
			case DataChannels.TEXCOORD1_3:
				return 3;
			case DataChannels.TEXCOORD2:
				return 2;
			case DataChannels.TEXCOORD2_3:
				return 3;
			case DataChannels.TEXCOORD3:
				return 2;
			case DataChannels.TEXCOORD3_3:
				return 3;
			case DataChannels.UNDEFDATA0:
				return 4;
			case DataChannels.UNDEFDATA0_1:
				return 1;
			case DataChannels.UNDEFDATA1:
				return 4;
			case DataChannels.UNDEFDATA2:
				return 4;
			case DataChannels.UNDEFDATA3:
				return 4;
			case DataChannels.UNFOLDING:
				return 2;
		}
		assert(0,"This should never be reached");
	}
	
	static uint DataChannelLocation(DataChannels pChannel){
		final switch(pChannel){
			case DataChannels.POSITION:
			case DataChannels.POSITION_2:
				return 0;
			case DataChannels.COLOR:
				return 1;
			case DataChannels.NORMAL:
				return 2;
			case DataChannels.BINORMAL:
				return 3;
			case DataChannels.TANGENT:
				return 4;
			case DataChannels.TEXCOORD0:
			case DataChannels.TEXCOORD0_3:
				return 5;
			case DataChannels.TEXCOORD1:
			case DataChannels.TEXCOORD1_3:
				return 6;
			case DataChannels.TEXCOORD2:
			case DataChannels.TEXCOORD2_3:
				return 7;
			case DataChannels.TEXCOORD3:
			case DataChannels.TEXCOORD3_3:
				return 8;
			case DataChannels.UNFOLDING:
				return 9;
			case DataChannels.BONEIDS:
				return 10; 
			case DataChannels.BONEWEIGHTS:
				return 11; 
			case DataChannels.UNDEFDATA0:
			case DataChannels.UNDEFDATA0_1:
				return 12;
			case DataChannels.UNDEFDATA1:
				return 13;
			case DataChannels.UNDEFDATA2:
				return 14;
			case DataChannels.UNDEFDATA3:
				return 15;
		}
		assert(0,"This should never be reached");
	}
	
	/**
	 * possible primitives that can be stored inside a vertexbuffer
	 */ 
	enum Primitive : uint {
		POINTS = gl.POINTS,
		QUADS = gl.QUADS,
		LINES = gl.LINES,
		TRIANGLES = gl.TRIANGLES,
		TRIANGLE_STRIP = gl.TRIANGLE_STRIP
	};
	
	/**
	 * possible values for the index buffer size
	 */ 
	enum IndexBufferSize : uint {
		INDEX16 = gl.UNSIGNED_SHORT,
		INDEX32 = gl.UNSIGNED_INT
	};
	
	/**
	 * Structure to init a vertexbuffer attribute
	 */
	struct AttributeInit {
		DataChannels type = DataChannels.POSITION; ///Type of the channel used
		size_t size = 0; /// size of the attribute has to be > 0
	};
	
private:
	struct Attribute {
		DataChannels type;
		int location;
		uint size;
		void *dataStart;
	};
	
	struct IndexBufferInfo {
		uint size;
		ubyte *dataStart;
		Vector!(uint) data = null;
	};
	
	union Data {
		float f;
		int i;
		ubyte[4] b;
	};
	
	Vector!(Attribute) m_Attributes = null;
	
	Vector!(IndexBufferInfo) m_IndexBuffers = null;
	
	uint m_VertexBufferId = 0; ///opengl-id of the vertex buffer
	uint m_IndexBufferId = 0; ///opengl-id of the index buffer
	Primitive m_Primitive; ///type of the primitive stored
	bool m_Dynamic; ///if the vertexbuffer changes its size dynamicly or not
	IRendererInternal m_Renderer;
	
	Vector!(Data) m_Data = null;
	
	bool m_Indexed = false; ///if it uses a index buffer
	bool m_MultiIndexed = false; ///if it uses multiple index buffers
	IndexBufferSize m_IndexType; ///the indexing type used (16 or 32 bit) 
	
	static VertexBuffer m_ActiveVertexBuffer = null;	
	
	int m_UploadedDataSize = 0;
	int m_UploadedIndexDataSize = 0;
	uint m_BytesPerVertex = 0;
	uint m_NumberOfVertices = 0;
	
public:
	/**
	 * constructor
	 * Params:
	 *		pAttributes 	= attributes the vertexbuffer should have
	 *		pPrimitive		= the primitive the vertexbuffer should use
	 *		pIndexBufferSize = the used index buffer size (limits number of vertices)
	 *		pDynamic		= if the vertexbuffer should change its size dynamically or not
	 */
	this(IRendererInternal pRenderer, DataChannels[] pAttributes, Primitive pPrimitive, IndexBufferSize pIndexBufferSize, bool pDynamic = false)
	in {
		assert(pAttributes.length > 0,"A vertexbuffer must have at least 1 attribute");
	}
	body
	{
		m_Renderer = pRenderer;
		m_Primitive = pPrimitive;
		m_IndexType = pIndexBufferSize;
		m_Dynamic = pDynamic;
		
		m_Attributes = New!(Vector!Attribute)();
		m_Data = New!(Vector!Data)();
		m_IndexBuffers = New!(Vector!IndexBufferInfo)();
		
		uint offset = 0;
		foreach(ref init;pAttributes){
			Attribute temp;
			temp.type = init;
			temp.location = DataChannelLocation(init);
			temp.size = DataChannelSize(init);
			temp.dataStart = (cast(void*)0) + offset * float.sizeof;
			m_Attributes.push_back(temp);
			offset += temp.size;
		}
		
		m_BytesPerVertex = offset * cast(uint)float.sizeof;
	}
	
	~this(){
    foreach(ref info; m_IndexBuffers)
    {
      Delete(info.data);
    }
    Delete(m_IndexBuffers);
    Delete(m_Attributes);
    Delete(m_Data);

		m_Renderer.addVertexBufferMemoryAmount(-m_UploadedDataSize);
		m_Renderer.addVertexBufferMemoryAmount(-m_UploadedIndexDataSize);
		if(m_IndexBufferId != 0)
			gl.DeleteBuffers(1,&m_IndexBufferId);
		if(m_VertexBufferId != 0)
			gl.DeleteBuffers(1,&m_VertexBufferId);
	}
	
	/**
	 * adds vertex data to the buffer
	 * Params: 
	 * 		pData = array of data to add
	 */ 
	void AddVertexData(const(float)[] pData){
		size_t start = m_Data.size();
		m_Data.resize(start + pData.length);
    memcpy(&m_Data[start],pData.ptr,pData.length * float.sizeof);
		/*for(size_t i=start;i<m_Data.size();i++){
			m_Data[i].f = pData[i-start];
		}*/
	}
	
	/**
	 * adds vertex data to the buffer
	 * Params:
	 *		pVec = vector data to add
	 */
	void AddVertexData(vec4 pVec){
		AddVertexData(pVec.f[0..4]);
	}
	
	/**
	 * adds vertex data to the buffer
	 * Params:
	 * 		pVec = vector data to add 
	 */ 
	void AddVertexData(vec3 pVec){
		AddVertexData(pVec.f[0..3]);
	}
	
	/**
	 * adds vertex data to the buffer
	 * Params:
	 * 		pVec = vector data to add 
	 */ 
	void AddVertexData(vec2 pVec){
		AddVertexData(pVec.f[0..2]);
	}
	
	/**
	 * Adds one more index buffer
	 */
	void AddIndexBuffer(){
		m_IndexBuffers.resize(m_IndexBuffers.size() + 1);
		m_IndexBuffers[m_IndexBuffers.size() - 1].data = New!(Vector!uint)();
		m_IndexBuffers[m_IndexBuffers.size() - 1].size = 0;
		m_IndexBuffers[m_IndexBuffers.size() - 1].dataStart = null;
	}
	
	/**
	 * Adds index data to a existing index buffer
	 * Params:
	 *		pNum = index of the index buffer to add data to
	 *		pData = data to add
	 */ 
	void AddIndexData(size_t pNum, uint pData)
	in {
		assert(m_IndexBuffers.size() > pNum,"Index buffer does not exist");
		if(m_IndexType == IndexBufferSize.INDEX16)
			assert(pData < 65536,"Index is to large for 16-bit indexing");
	}
	body
	{
		m_IndexBuffers[pNum].data.push_back(pData);
	}
	
	/**
	 * Adds index data to a existing index buffer	 * 
	 * Params:
	 * 		pNum = index of the index buffer to add data to 
	 *		pData = data to add
	 */
	void AddIndexData(size_t pNum,uint[] pData)
	in {
		assert(m_IndexBuffers.size() > pNum,"Index buffer does not exist");
		if(m_IndexType == IndexBufferSize.INDEX16){
			foreach(e;pData){
				assert(e < 65536,"Index is to large");
			}
		}
	}
	body {
		m_IndexBuffers[pNum].data.push_back(pData);
	}
	
	/**
	 * Gets the number of indicies in a index buffer
	 * Params:
	 *		pBuffer = index of the buffer to get from
	 * Returns: number of indicies in the given index buffer
	 */
	size_t GetNumberOfIndicies(size_t pBuffer)
	in {
		assert(m_IndexBuffers.size() > pBuffer,"Index buffer does not exist");
	}
	body {
		return m_IndexBuffers[pBuffer].data.size();
	}
	
	/**
	 * Uploads empty data to the gpu
	 * Params:
	 *		pNumElements = number of empty elements to upload (a element is a group of all existing attributes)
	 * Returns: true if successfull, false otherwise
	 */ 
	bool UploadEmptyData(uint pNumElements){
		//Index buffer löschen falls vorhanden
		m_IndexBuffers.resize(0);
		if(m_IndexBufferId != 0){
			gl.DeleteBuffers(1,&m_IndexBufferId);
			m_IndexBufferId = 0;
		}
		
		//Vertexbuffer vorhanden und nicht dynamisch -> löschen
		if(m_VertexBufferId != 0 && !m_Dynamic){
			gl.DeleteBuffers(1,&m_VertexBufferId);
			m_VertexBufferId = 0;
		}
		
		m_Indexed = false;
		
		if(!m_Dynamic){
			gl.GenBuffers(1,&m_VertexBufferId);
		}
		gl.BindBuffer(gl.ARRAY_BUFFER,m_VertexBufferId);
		m_UploadedDataSize = pNumElements * m_BytesPerVertex;
		m_Renderer.addVertexBufferMemoryAmount(m_UploadedDataSize);
		if(!m_Dynamic)
			gl.BufferData(gl.ARRAY_BUFFER,m_UploadedDataSize,null,gl.STATIC_DRAW);
		else
			gl.BufferData(gl.ARRAY_BUFFER,m_UploadedDataSize,null,gl.DYNAMIC_DRAW);
		
		return true;
	}
	
	/**
	 * This function checks if the vertexbuffer data is valid and can be uploaded
	 * Returns: true if valid, false otherwise
	 */
	bool Check(){
		if(m_Data.size() == 0){
			return false;
		}
		if(m_Data.size() % (m_BytesPerVertex / float.sizeof) != 0){
			return false;
		}
		/*if(m_Data.size() > 131072*4){
			logWarning("Warning: VertexBuffer is really huge %s",m_Data.size());
		}*/
		return true;
	}
	
	/**
	 * Uploads the local data to the gpu
	 * Returns: true if successfull, false otherwise
	 */
	bool UploadData(){
		if(!Check())
			return false;
		
		if(m_IndexBufferId != 0){
			m_Renderer.addVertexBufferMemoryAmount(-m_UploadedIndexDataSize);
			gl.DeleteBuffers(1,&m_IndexBufferId);
			m_IndexBufferId = 0;
		}
		
		if(m_VertexBufferId != 0 && !m_Dynamic){
			gl.DeleteBuffers(1,&m_VertexBufferId);
			m_VertexBufferId = 0;
		}
		
		if(m_IndexBuffers.size() == 0){
			m_Indexed = false;
		}
		else {
			m_Indexed = true;
			//Multiple index buffers?
			m_MultiIndexed = (m_IndexBuffers.size() > 1);
			
			size_t BufferSize = 0;
			foreach(ref e;m_IndexBuffers.GetRange()){
				e.size = cast(uint)e.data.size();
				BufferSize += e.size;
			}
			
			if(m_IndexType == IndexBufferSize.INDEX16)
				BufferSize *= 2;
			else
				BufferSize *= 4;
			
			ubyte[] Buffer = AllocatorNewArray!ubyte(ThreadLocalStackAllocator.globalInstance, BufferSize);
      scope(exit) AllocatorDelete(ThreadLocalStackAllocator.globalInstance, Buffer);
			ubyte *gpuPointer = null;
			if(m_IndexType == IndexBufferSize.INDEX16){
				ushort *dataPointer = cast(ushort*)Buffer.ptr;
				foreach(ref e;m_IndexBuffers.GetRange()){
					e.dataStart = gpuPointer;
					foreach(i;e.data.GetRange()){
						*dataPointer = cast(ushort)i;
						dataPointer++;
						gpuPointer += ushort.sizeof;
					}
				}
			}
			else {
				uint *dataPointer = cast(uint*)Buffer.ptr;
				foreach(ref e;m_IndexBuffers.GetRange()){
					e.dataStart = gpuPointer;
					foreach(i;e.data.GetRange()){
						*dataPointer = i;
						dataPointer++;
						gpuPointer += uint.sizeof;
					}
				}
			}
			
			m_UploadedIndexDataSize = int_cast!int(BufferSize);
			m_Renderer.addVertexBufferMemoryAmount(m_UploadedIndexDataSize);
			
			//Create index buffer
			gl.GenBuffers(1,&m_IndexBufferId);
			//Upload data
			gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, m_IndexBufferId);
			gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, BufferSize, Buffer.ptr, gl.STATIC_DRAW);
			
			gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER,0);
		}
		
		m_NumberOfVertices = cast(uint)m_Data.size() / (m_BytesPerVertex / cast(uint)float.sizeof);
		uint BufferSize = m_BytesPerVertex * m_NumberOfVertices;
		
		//Create Vertexbuffer
		if(m_Dynamic){
			if(BufferSize > m_UploadedDataSize || m_VertexBufferId == 0){
        logInfo("Increasing vertex buffer size to %d", BufferSize);
				m_Renderer.addVertexBufferMemoryAmount(BufferSize - m_UploadedDataSize);
				if(m_VertexBufferId == 0){
					gl.GenBuffers(1, &m_VertexBufferId);
				}
				gl.BindBuffer(gl.ARRAY_BUFFER, m_VertexBufferId);
				gl.BufferData(gl.ARRAY_BUFFER, BufferSize, m_Data.ptr(),gl.DYNAMIC_DRAW);
				m_UploadedDataSize = BufferSize;
				gl.BindBuffer(gl.ARRAY_BUFFER,0);
			}
			else {
				gl.BindBuffer(gl.ARRAY_BUFFER,m_VertexBufferId);
				
				//discard the previous data (avoids wait)
				//gl.BufferData(gl.ARRAY_BUFFER, m_UploadedDataSize, null,gl.DYNAMIC_DRAW);
				
				//uplaod new data
				void *data = gl.MapBuffer(gl.ARRAY_BUFFER,gl.WRITE_ONLY);
				if(data !is null){
					memcpy(data,m_Data.ptr(),BufferSize);
					gl.UnmapBuffer(gl.ARRAY_BUFFER);
				}
				
				//gl.BufferSubData(gl.ARRAY_BUFFER,0,BufferSize,m_Data.ptr());
				gl.BindBuffer(gl.ARRAY_BUFFER,0);
			}
		}
		else {
			gl.GenBuffers(1,&m_VertexBufferId);
			gl.BindBuffer(gl.ARRAY_BUFFER,m_VertexBufferId);
			gl.BufferData(gl.ARRAY_BUFFER,BufferSize,m_Data.ptr(),gl.STATIC_DRAW);
			m_UploadedDataSize = BufferSize;
			gl.BindBuffer(gl.ARRAY_BUFFER,0);
			m_Renderer.addVertexBufferMemoryAmount(m_UploadedDataSize);
		}
		
		return true;
	}
	
	/**
	 * Reserves fixed number of data inside the vertexbuffer local storage
	 * Params:
	 * 		pNum = number of vertices to be reserved
	 */
	void ReserveVertexData(size_t pNum){
		m_Data.reserve(pNum * (m_BytesPerVertex / float.sizeof));
	}
	
	/**
	 * Reserves additional data inside the vertexbuffer local storage
	 * Params:
	 * 		pNum = number of vertices to be reserved
	 */
	void ReserveAdditionalVertexData(size_t pNum){
		m_Data.reserve(m_Data.size() + pNum * (m_BytesPerVertex / float.sizeof));
	}
	
	/**
	 * Ends the usage of the current vertexbuffer
	 */
	void End(){
		m_ActiveVertexBuffer = null;
		foreach(e;m_Attributes.GetRange()){
			if(e.location >= 0){
				gl.DisableVertexAttribArray(e.location);
			}
		}
	}
	
	/**
	 * Draws the vertexbuffer
	 */
	void Draw()
	in {
		assert(m_VertexBufferId != 0,"Vertexbuffer data not yet uploaded!");
		if(m_Indexed){
			assert(m_IndexBufferId != 0,"Index buffer not yet uploaded");
		}
	}
	body
	{
		if(this != m_ActiveVertexBuffer){
			gl.BindBuffer(gl.ARRAY_BUFFER,m_VertexBufferId);
			m_ActiveVertexBuffer = this;
		
			//Attributes
			foreach(atr;m_Attributes.GetRange()){
				if(atr.location >= 0){
					gl.EnableVertexAttribArray(atr.location);
					gl.VertexAttribPointer(atr.location,atr.size,gl.FLOAT,false,m_BytesPerVertex,atr.dataStart);
				}
			}
		}
		
		if(m_Indexed && m_IndexBufferId != 0){
			gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, m_IndexBufferId);
			if(m_MultiIndexed){
				assert(0,"Multi indexed vertexbuffers not implemeted yet");
				//gl.MultiDrawElements(m_Primitive,&m_IndexBufferSizes[0],m_IndexType, &m_IndexBufferPoints[0],m_IndexBuffers.size());
			}
			else {
				gl.DrawElements(cast(gl.GLenum)m_Primitive, m_IndexBuffers[0].size, cast(gl.GLenum)m_IndexType, null);
			}
			gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER,0);
		}
		else {
			gl.DrawArrays(cast(gl.GLenum)m_Primitive, 0, m_NumberOfVertices);
		}
		
	}
	
	/**
	 * This call draws a part of the vertexbuffer
	 * Params:
	 * 		pStart = starting vertex to draw from
	 *		pSize = number of vertices to draw
	 */
	void DrawRange(uint pStart, uint pSize)
	in
	{
		assert(pStart + pSize <= m_UploadedDataSize / (m_BytesPerVertex / 4),"Draw call would go out of range!");
		assert(m_VertexBufferId != 0, "Data not yet uploaded");
		if(m_Indexed)
			assert(m_IndexBufferId != 0, "Indices not yet uploaded");
	}
	body {
		if(this != m_ActiveVertexBuffer){
			gl.BindBuffer(gl.ARRAY_BUFFER,m_VertexBufferId);
			m_ActiveVertexBuffer = this;
			
			foreach(atr;m_Attributes.GetRange()){
				if(atr.location >= 0){
					gl.EnableVertexAttribArray(atr.location);
					gl.VertexAttribPointer(atr.location,atr.size,gl.FLOAT,false,m_BytesPerVertex,atr.dataStart);
				}
			}
		}
		
		if(m_Indexed){
			gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER,m_IndexBufferId);
			if(m_MultiIndexed){
				assert(0,"Multi indexed draw range is not possible");
			}
			else {
				uint indexSize = (m_IndexType == IndexBufferSize.INDEX16) ? 2 : 4;
				gl.DrawElements(cast(gl.GLenum)m_Primitive,pSize, cast(gl.GLenum)m_IndexType, (cast(void*)0) + (indexSize * pStart));
				//gl.DrawRangeElements(cast(gl.GLenum)m_Primitive, pStart, pStart+pSize, pSize, cast(gl.GLenum)m_IndexType, null);
			}
			gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER,0);
		}
		else {
			gl.DrawArrays(cast(gl.GLenum)m_Primitive,pStart,pSize);
		}
	}
	
	/**
	 * Frees the local data held
	 */
	void FreeLocalData(){
    foreach(ref info; m_IndexBuffers)
    {
      Delete(info.data);
    }
		m_IndexBuffers.resize(0);
		m_Data.resize(0);
	}
	
	/**
	 * Gets the size of the current uploaded data
	 */
	size_t GetDataSize(){
		size_t size = 0;
		if(m_VertexBufferId == 0)
			return 0;
		size += m_BytesPerVertex * m_NumberOfVertices;
		foreach(index;m_IndexBuffers.GetRange()){
			if(m_IndexType == IndexBufferSize.INDEX16)
				size += 2 * index.size;
			else if(m_IndexType == IndexBufferSize.INDEX32)
				size += 4 * index.size;
		}
		return size;
	}
	
	/**
	 * Gets the current number of vertices in the local storage
	 */
	size_t GetVerticesInBuffer(){
		return m_Data.size() / (m_BytesPerVertex / 4);
	}
	
	/**
	 * Gets the bytes per vertex
	 */
	size_t GetBytesPerVertex() const 
	{
		return m_BytesPerVertex;
	}
	
	/**
	 * Gets a bounding box for the vertices inside the buffer
	 * Params:
	 * 		pMin = result minimum coordinates
	 *		pMax = result maximum coordinates
	 */
	void GetMinMax(ref vec4 pMin, ref vec4 pMax){
		uint stride = m_BytesPerVertex / float.sizeof;
		float[] position = new float[3];
		pMin.f[0..3] = (cast(const(float[]))m_Data[0..3])[];
		pMax.f[0..3] = (cast(const(float[]))m_Data[0..3])[];
		for(size_t i=1;i<m_NumberOfVertices;i++){
			position[0..3] = (cast(const(float[]))m_Data[(i*stride)..(i*stride+3)])[];
			pMin.x = (position[0] < pMin.x) ? position[0] : pMin.x;
			pMin.y = (position[1] < pMin.y) ? position[1] : pMin.y;
			pMin.z = (position[2] < pMin.z) ? position[2] : pMin.z;
			
			pMax.x = (position[0] > pMax.x) ? position[0] : pMax.x;
			pMax.y = (position[1] > pMax.y) ? position[1] : pMax.y;
			pMax.z = (position[2] > pMax.z) ? position[2] : pMax.z;
		}
	}
	
	/**
	 * Gets a array of the stored data channels
	 * Returns: the array
	 */
	DataChannels[] GetDataChannels(){
		DataChannels[] d = new DataChannels[m_Attributes.size()];
		
		foreach(i, ref e;d){
			e = m_Attributes[i].type;
		}
		
		return d;
	}

  /**
   * Compares this vertex buffer to another one
   */
  bool Equals(VertexBuffer rh)
  {
    return (this is rh);
  }
	
	static VertexBuffer GetActiveVertexBuffer(){
		return m_ActiveVertexBuffer;
	}
};
