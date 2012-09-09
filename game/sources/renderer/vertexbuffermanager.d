module renderer.vertexbuffermanager;

import renderer.vertexbuffer;
import thBase.container.vector;
import thBase.container.hashmap;
import thBase.policies.hashing;

import thBase.algorithm;

/**
 * interface for vertex buffer manager
 */
interface IVertexBufferManager {
	/**
	 * Adds a Vertexbuffer that should be updated in this frame
	 * Params:
	 *		pVertexBuffer = the vertexbuffer to update
	 */
	void AddVertexBufferToUpdate(VertexBuffer pVertexBuffer);
	
	/**
	 * Searches for a vertex buffer with the given specs
	 * Params:
	 *		pChannels = a list of the requested data channels
	 *		pPrimitive = the requested primitive
	 *		pIndexBufferSize = the requested index buffer size
	 *		pNumIndicies = number of the needed indicies
	 *		pNumPrimitives = number of primitives
	 * Returns: a VertexBuffer if a matching one is found, null otherwise
	 */
	VertexBuffer Search(VertexBuffer.DataChannels[] pChannels,
						VertexBuffer.Primitive pPrimitive,
						VertexBuffer.IndexBufferSize pIndexBufferSize,
						size_t pNumVertices,
						size_t pNumPrimitives);
	
	/**
	 * Adds a vertex buffer to the pool
	 * Params:
	 *		pVertexBuffer = the vertex buffer to add
	 *		pChannels = the data channels of the vertex buffer
	 *		pPrimitive = the primitive type of the vertex buffer
	 *		pIndexBufferSize = the index buffer size of the vertex buffer
	 */
	void Add(VertexBuffer pVertexBuffer,
	         VertexBuffer.DataChannels[] pChannels,
			 VertexBuffer.Primitive pPrimitive,
			 VertexBuffer.IndexBufferSize pIndexBufferSize);
	
	/** Removes a vertex buffer from the pool
	 * Params:
	 *		pVertexBuffer = the vertex buffer to remove
	 */
	void Remove(VertexBuffer pVertexBuffer);
						
}

/**
 * vertex buffer manager implementation
 */
class VertexBufferManager : IVertexBufferManager {
private:
	enum : uint {
		MAX_VERTEX_BUFFER_SIZE = 4194304 //4 MB
	}
	
	struct VertexBufferSpecs {
		VertexBuffer.DataChannels[] m_Channels;
		VertexBuffer.Primitive m_Primitive;
		VertexBuffer.IndexBufferSize m_IndexBufferSize;
		
		this(VertexBuffer.DataChannels[] pChannels,
		     VertexBuffer.Primitive pPrimitive,
		     VertexBuffer.IndexBufferSize pIndexBufferSize)
		{
			m_Channels = pChannels;
			m_Primitive = pPrimitive;
			m_IndexBufferSize = pIndexBufferSize;
		}
	}
	
	
	Hashmap!(VertexBuffer, VertexBufferSpecs, ReferenceHashPolicy) m_VertexBuffers;
	Vector!(VertexBuffer) m_BuffersToUpdate;	
	
public:
	
	this(){
		m_BuffersToUpdate = New!(Vector!VertexBuffer)();	
    m_VertexBuffers = New!(typeof(m_VertexBuffers))();
	}

  ~this()
  {
    Delete(m_BuffersToUpdate);
    Delete(m_VertexBuffers);
  }
	
	void AddVertexBufferToUpdate(VertexBuffer pVertexBuffer)
	in {
		assert(pVertexBuffer !is null,"pVertexBuffer may not be null");
	}
	body {
		m_BuffersToUpdate.push_back(pVertexBuffer);
	}
	
	VertexBuffer Search(VertexBuffer.DataChannels[] pChannels,
	                    VertexBuffer.Primitive pPrimitive,
	                    VertexBuffer.IndexBufferSize pIndexBufferSize,
	                    size_t pNumVertices,
	                    size_t pNumPrimitives)
	in {
		assert(pChannels.length > 0,"There has to be at least 1 given channel");
		assert(pNumVertices > 0,"pNumVertices can not be 0");
		assert(pNumPrimitives > 0,"pNumPrimitives can not be 0");
	}
	body {
		foreach(vb, ref spec;m_VertexBuffers){
			if(spec.m_Primitive != pPrimitive)
				continue;
			if(spec.m_IndexBufferSize != pIndexBufferSize)
				continue;
			uint MaxSize = 0;
			final switch(pIndexBufferSize){
				case VertexBuffer.IndexBufferSize.INDEX16:
					MaxSize = 2^16;
					break;
				case VertexBuffer.IndexBufferSize.INDEX32:
					MaxSize = 2^32;
					break;
			}
			if(vb.GetVerticesInBuffer() + pNumVertices > MaxSize)
				continue;
			
			bool skip = false;
			foreach(channel;pChannels){
				if( find(spec.m_Channels,channel) == -1 ){
					skip = true;
					break;
				}
			}
			if(skip)
				continue;
			
			size_t size = pNumVertices * vb.GetBytesPerVertex();
			uint index = 2;
			if(pIndexBufferSize == VertexBuffer.IndexBufferSize.INDEX32)
				index = 4;
			uint primitive = 0;
			final switch(pPrimitive){
				case VertexBuffer.Primitive.LINES:
					index = 2;
					break;
				case VertexBuffer.Primitive.POINTS:
					index = 1;
					break;
				case VertexBuffer.Primitive.QUADS:
					index = 4;
					break;
				case VertexBuffer.Primitive.TRIANGLES:
					index = 3;
					break;
				case VertexBuffer.Primitive.TRIANGLE_STRIP:
					index = 3;
					break;
			}
			size += index * primitive * pNumPrimitives;
			if(vb.GetDataSize() + size > MAX_VERTEX_BUFFER_SIZE)
				continue; //skip if to large
			return vb;
		}
		return null;
	}
	
	void Add(VertexBuffer pVertexBuffer,
	         VertexBuffer.DataChannels[] pChannels,
			 VertexBuffer.Primitive pPrimitive,
			 VertexBuffer.IndexBufferSize pIndexBufferSize)
	in {
		assert(pVertexBuffer !is null,"pVertexBuffer may not be null");
		assert(pChannels.length > 0,"There has to be at least 1 data channel given");
	}
	body {
		m_VertexBuffers[pVertexBuffer] = VertexBufferSpecs(pChannels,pPrimitive,pIndexBufferSize);
	}
	
	void Remove(VertexBuffer pVertexBuffer)
	in {
		assert(pVertexBuffer !is null,"pVertexBuffer may not be null");
	}
	body {
		if(m_VertexBuffers.exists(pVertexBuffer))
			m_VertexBuffers.remove(pVertexBuffer);
	}
	
	void UpdateVertexBuffers(){
		foreach(buffer;m_BuffersToUpdate.GetRange()){
			if(!buffer.UploadData()){
				throw New!Exception("Updating a vertex buffer failed");
			}
		}
		m_BuffersToUpdate.resize(0);
	}
}
