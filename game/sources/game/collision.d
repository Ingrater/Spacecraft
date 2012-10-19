module game.collision;

import thBase.math3d.all;
import base.renderer;
import thBase.string;
import core.refcounted;
import core.allocator;
import thBase.scoped;
import base.modelloader;
import thBase.enumbitfield;

class CollisionHull {
private
	Triangle[] m_Faces;
	
public:
	/**
	 * Builds a new collison hull from the model in pFilename.
	 */
	this(rcstring pFilename){
		Load(pFilename);
	}

  ~this()
  {
    Delete(m_Faces);
  }
	
	/**
	 * Loads a collision mesh from a model file, the model file may only contain one single mesh
	 * Params:
	 *  pFilename = the file to load
	 */
	void Load(rcstring pFilename){
		auto loader = scopedRef!(ModelLoader, ThreadLocalStackAllocator)(AllocatorNew!ModelLoader(ThreadLocalStackAllocator.globalInstance));
    loader.LoadFile(pFilename, EnumBitfield!(ModelLoader.Load)(ModelLoader.Load.Meshes, ModelLoader.Load.Nodes));
		
		if(loader.modelData.meshes.length > 1){
			throw New!RCException(format("The collision mesh '%s' does contain more that 1 mesh", pFilename[]));
		}
		
		auto mesh = loader.modelData.meshes[0];
    if(m_Faces)
    {
      Delete(m_Faces);
    }
		m_Faces = NewArray!Triangle(mesh.faces.length);
    auto vertices = AllocatorNewArray!vec3(ThreadLocalStackAllocator.globalInstance, mesh.vertices.length);
    scope(exit) AllocatorDelete(ThreadLocalStackAllocator.globalInstance, vertices);
    
    const(ModelLoader.NodeDrawData*) findLeaf(const(ModelLoader.NodeDrawData*) node)
    {
      if(node.meshes.length > 0)
      {
        return node;
      }
      foreach(child; node.children)
      {
        auto result = findLeaf(child);
        if(result !is null)
        {
          return result;
        }
      }
      return null;
    }

    const(ModelLoader.NodeDrawData)* curNode = findLeaf(loader.modelData.rootNode);
    assert(curNode !is null, "no node with mesh found");
    mat4 transform = loader.modelData.rootNode.transform;
    while(curNode !is null && curNode != loader.modelData.rootNode)
    {
      transform = curNode.transform * transform;
      curNode = curNode.data.parent;
    }

    foreach(size_t i, ref vertex; vertices)
    {
      vertex = transform * mesh.vertices[i];
    }
		
		foreach(size_t i,ref face;m_Faces){			
      for(size_t j=0; j<3; j++)
      {
			  face.v[j] = vertices[mesh.faces[i].indices[j]];
			}
      face.plane = Plane(face.v[0], face.v[1], face.v[2]);
		}
	}

	/**
     * Detectes wether this collision hull does intersect with a other collision hull
     * Params:
	 *  other = the other collision hull to intersect with
	 *  lhTrans = the transformation of this collision hull
	 *  rhTrans = the transformation of the other collision hull
	 */
	bool intersects(CollisionHull other,mat4 lhTrans, mat4 rhTrans){
		uint testcount = 0;
		
		auto transformed_other = new Triangle[](other.m_Faces.length);
		foreach(i, ref f2; other.m_Faces)
			transformed_other[i] = f2.transform(rhTrans);
		
		foreach(ref f1;m_Faces){
			Triangle lhTri = f1.transform(lhTrans);
			
      Ray dummy;
			foreach(ref f2; transformed_other){
				testcount++;
				if(lhTri.intersects(f2, dummy)){
					//base.logger.info("col: %d tests (hit)", testcount);
					return true;
				}
			}
		}
		
		//base.logger.info("col: %d tests (no hit)", testcount);
		return false;
	}
	
	/**
	 * Tests for a intersection with a already correctly transformed ray and this collision hull
	 * Params:
	 *  ray = the ray to test with
	 *  lhTrans = the transformation to apply to this collision hull
	 *  rayPos = the position on the ray where it did intersect
	 */
	bool intersects(Ray ray,mat4 lhTrans,ref float rayPos, ref vec3 normal){
		bool result = false;
		rayPos = float.max;
		foreach(ref f; m_Faces){
			Triangle lhTri = f.transform(lhTrans);
			float pos;
			if( lhTri.intersects(ray,pos) ){
				result = true;
				if(pos < rayPos){
					rayPos = pos;
					normal = lhTri.normal;
				}
			}
		}
		return result;
	}
	
	/**
	 * Draws a transformed version of the collision mesh
	 * Pararms:
	 *  transformation = the transformation to use
	 *  renderer = the renderer to use for drawing
	 *  color = the color to use (optional)
	 */
	void debugDraw(mat4 transformation, shared(IRenderer) renderer, vec4 color = vec4(1.0f,1.0f,1.0f,1.0f)){
		foreach(ref f;m_Faces){
			Triangle curFace = f.transform(transformation);
			
			renderer.drawLine(Position(curFace.v[0]),Position(curFace.v[1]),color);
			renderer.drawLine(Position(curFace.v[0]),Position(curFace.v[2]),color);
			renderer.drawLine(Position(curFace.v[1]),Position(curFace.v[2]),color);
		}
	}
	
	/**
	 * Computes the bounding box for this collision mesh
	 * Returns: A axis aligned bounding box
	 */
	AlignedBox boundingBox(){
		vec3 min = vec3(float.max);
		vec3 max = vec3(-float.max);
		foreach(ref f;m_Faces){
			foreach(ref v;f.v){
				if(v.x < min.x) min.x = v.x;
				if(v.y < min.y) min.y = v.y;
				if(v.z < min.z) min.z = v.z;
				
				if(v.x > max.x) max.x = v.x;
				if(v.y > max.y) max.y = v.y;
				if(v.z > max.z) max.z = v.z;
			}
		}
		return AlignedBox(min,max);
	}
}
