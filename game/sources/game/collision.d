module game.collision;

import thBase.math3d.all;
import base.assimp.assimp;
import base.renderer;
import thBase.string;
import core.refcounted;
import core.allocator;


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
		const(aiScene)* scene = Assimp.ImportFile(toCString(pFilename), 
		                                   aiPostProcessSteps.CalcTangentSpace |
		                                   aiPostProcessSteps.Triangulate |
		                                   aiPostProcessSteps.JoinIdenticalVertices |
		                                   aiPostProcessSteps.FlipUVs |
										   aiPostProcessSteps.PreTransformVertices );
		if(scene is null){
			throw New!RCException(format("Couldn't load collision mesh from file '%s'", pFilename[]));
		}
		
		if(scene.mNumMeshes > 1){
			throw New!RCException(format("The collision mesh '%s' does contain more that 1 mesh", pFilename[]));
		}
		
		const(aiMesh)* aimesh = scene.mMeshes[0];
    if(m_Faces)
    {
      Delete(m_Faces);
    }
		m_Faces = NewArray!Triangle(aimesh.mNumFaces);
		
		/*mat4 inv;
		inv.f[ 0]= 1.00; inv.f[ 1]= 0.00; inv.f[ 2]= 0.00; inv.f[ 3]= 0.00;
		inv.f[ 4]= 0.00; inv.f[ 5]= 0.00; inv.f[ 6]= 1.00; inv.f[ 7]= 0.00;
		inv.f[ 8]= 0.00; inv.f[ 9]=-1.00; inv.f[10]= 0.00; inv.f[11]= 0.00;
		inv.f[12]= 0.00; inv.f[13]= 0.00; inv.f[14]= 0.00; inv.f[15]= 1.00;*/
		
		foreach(size_t i,ref face;m_Faces){
			if(aimesh.mFaces[i].mNumIndices != 3){
				throw new Exception("Trying to load a non triangle model");
			}
			
			face.v[0] = vec3(/*inv */ vec4((&aimesh.mVertices[aimesh.mFaces[i].mIndices[0]].x)[0..3]));
			face.v[1] = vec3(/*inv */ vec4((&aimesh.mVertices[aimesh.mFaces[i].mIndices[1]].x)[0..3]));
			face.v[2] = vec3(/*inv */ vec4((&aimesh.mVertices[aimesh.mFaces[i].mIndices[2]].x)[0..3]));
			face.plane = Plane(face.v[0],face.v[1],face.v[2]);
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
			
			foreach(ref f2; transformed_other){
				testcount++;
				if(lhTri.intersects(f2)){
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
