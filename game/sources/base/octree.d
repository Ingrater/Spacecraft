module base.octree;

import thBase.math3d.all;
import base.gameobject;
import thBase.container.linkedlist;
import thBase.container.stack;
import thBase.container.vector;
import base.memory;
import base.renderer;
import core.allocator;
import core.hashmap;
import thBase.policies.hashing;
import thBase.allocator;
import thBase.logging;

/**
 * Octree 
 * $(BR) child layout is:
 * $(BR) 0 = (0,0,0)
 * $(BR) 1 = (1,0,0)
 * $(BR) 2 = (0,1,0)
 * $(BR) 3 = (1,1,0)
 * $(BR) 4 = (0,0,1)
 * $(BR) 5 = (1,0,1)
 * $(BR) 6 = (0,1,1)
 * $(BR) 7 = (1,1,1)
 */
class Octree {
private:	
  enum ExtendDirection : ubyte {
    NEGATIVE,
      POSITIVE
  }

	class Node {
		//mixin SameSizePool!(Node,1000);
		private:
			bool m_HasChilds = false;
			Node[8] m_Childs;
			Node[6] m_Neighbours;
			Position m_Center;
			float m_RealSize;
			AlignedBox m_BoundingBox;
			DoubleLinkedList!(IGameObject) m_Objects;
			enum float SIZE_FACTOR = 2.0f;
			
		public:
			/**
			 * default constructor
			 * Params:
			 *  center = the center of the node
			 *  size = the size of the node
			 */
			this(Position center, float size){
				m_Center = center;
				m_RealSize = size;
				//loose octree, this actually makes the bounding box twice as big to generate 
				//some overlapping areas
				float offset = size / 2.0f * SIZE_FACTOR;
				m_BoundingBox = AlignedBox(m_Center - vec3(offset,offset,offset),
										   m_Center + vec3(offset,offset,offset));
        m_Objects = New!(typeof(m_Objects))(StdAllocator.globalInstance);
			}
		
			/**
		     * special constructor used to extend the overall size of the octree
		     * Param:
		     *  child = the current root node of the octree (now a child)
		     *  extendDirection = false for positive extension, true for negative
		     */
			this(Node child, ExtendDirection extendDirection){
        m_Objects = New!(typeof(m_Objects))(StdAllocator.globalInstance);
				m_HasChilds = true;
				m_RealSize = child.m_RealSize*2.0f;					   
				float shift = child.m_RealSize;
				Position center = child.m_Center;
				if(extendDirection == ExtendDirection.NEGATIVE)
					shift *= -1.0f;
				m_Center = child.m_Center + vec3(shift/2.0f,shift/2.0f,shift/2.0f);
				
				float newSize = m_RealSize / 2.0f * SIZE_FACTOR;
				m_BoundingBox = AlignedBox(m_Center - vec3(newSize,newSize,newSize),
										   m_Center + vec3(newSize,newSize,newSize));
				
				if(extendDirection == ExtendDirection.NEGATIVE){
					m_Childs[0] = new Node(center + vec3(shift,shift,shift),child.m_RealSize);
					m_Childs[1] = new Node(center + vec3( 0.0f,shift,shift),child.m_RealSize);
					m_Childs[2] = new Node(center + vec3(shift, 0.0f,shift),child.m_RealSize);
					m_Childs[3] = new Node(center + vec3( 0.0f, 0.0f,shift),child.m_RealSize);
					m_Childs[4] = new Node(center + vec3(shift,shift, 0.0f),child.m_RealSize);
					m_Childs[5] = new Node(center + vec3( 0.0f,shift, 0.0f),child.m_RealSize);
					m_Childs[6] = new Node(center + vec3(shift, 0.0f, 0.0f),child.m_RealSize);
					m_Childs[7] = child;
				}
				else {
					m_Childs[0] = child;
					m_Childs[1] = new Node(center + vec3(shift, 0.0f, 0.0f),child.m_RealSize);
					m_Childs[2] = new Node(center + vec3( 0.0f,shift, 0.0f),child.m_RealSize);
					m_Childs[3] = new Node(center + vec3(shift,shift, 0.0f),child.m_RealSize);
					m_Childs[4] = new Node(center + vec3( 0.0f, 0.0f,shift),child.m_RealSize);
					m_Childs[5] = new Node(center + vec3(shift, 0.0f,shift),child.m_RealSize);
					m_Childs[6] = new Node(center + vec3( 0.0f,shift,shift),child.m_RealSize);
					m_Childs[7] = new Node(center + vec3(shift,shift,shift),child.m_RealSize);
				}
			}

      ~this()
      {
        Delete(m_Objects);
        foreach(child; m_Childs)
        {
          Delete(child);
        }
      }
		
			///subdivides this node
			void subdivide()
			in {
				assert(m_HasChilds == false);
				assert(m_Objects.size() >= 8);
			}
			out {
				assert(m_HasChilds == true);
				/*int sum = 0;
				foreach(ref child;m_Childs){
					assert(child !is null);
					sum += child.m_Objects.size();
				}
				assert(sum > 0);
				sum += m_Objects.size();
				assert(sum == 8);*/
			}
			body {
				//logInfo("subdividing");
				m_HasChilds = true;
				float shift = m_RealSize / 4.0f;
				float newsize = m_RealSize / 2.0f;
				m_Childs[0] = new Node(m_Center + vec3(-shift,-shift,-shift),newsize);
				m_Childs[1] = new Node(m_Center + vec3( shift,-shift,-shift),newsize);
				m_Childs[2] = new Node(m_Center + vec3(-shift, shift,-shift),newsize);
				m_Childs[3] = new Node(m_Center + vec3( shift, shift,-shift),newsize);
				m_Childs[4] = new Node(m_Center + vec3(-shift,-shift, shift),newsize);
				m_Childs[5] = new Node(m_Center + vec3( shift,-shift, shift),newsize);
				m_Childs[6] = new Node(m_Center + vec3(-shift, shift, shift),newsize);
				m_Childs[7] = new Node(m_Center + vec3( shift, shift, shift),newsize);
				
				auto r = m_Objects[];
				while(!r.empty){
					IGameObject obj = r.front();
					bool moved = false;
					//Try to move the objects into the childs, if they fit
					auto box = obj.boundingBox;
					foreach(node;m_Childs){
						if(box in node.m_BoundingBox){
							node.m_Objects.moveHereBack(r);
							assert(node.m_Objects.back().front() is obj);
							changeObjectLocation(node,node.m_Objects.back());
							moved = true;
							break;
						}
					}
					//object did not fit into any of the childs
					if(!moved){
						//assert(0,"object was to big");
						r.popFront();
					}
				}
				
				foreach(child;m_Childs){
					if(!child.m_HasChilds && child.m_Objects.size() >= 8 && child.m_RealSize > m_MinSize){
						child.subdivide();
					}
				}
				//TODO notifiy neighbours about change
			}
			
			///optimizes this node
			void optimize(){
				if(m_HasChilds){
					size_t numObjects = m_Objects.size();
					bool doOptimization = true;
					foreach(child;m_Childs){
						child.optimize();
						if(child.m_HasChilds)
							doOptimization = false;
						numObjects += child.m_Objects.size();
					}
					if(numObjects < 8 && doOptimization){
						foreach(child;m_Childs){
							//TODO notify neighbours
							for(auto r = child.m_Objects[];!r.empty();){
								m_Objects.moveHereBack(r);
								changeObjectLocation(this,m_Objects.back());
							}
							assert(child.m_Objects.empty());
              debug {
                //Check if there is still a refrence to this node in any of the ObjectInfo objects
                foreach(ref ObjectInfo info; m_ObjectInNode.values)
                {
                  assert(info.node !is child);
                }
              }
							Delete(child);
						}
						m_Childs[0..8] = null;
						m_HasChilds = false;
					}
				}
			}
			
			/**
			 * inserts a element into this node
			 * Params:
			 *  obj = the game object to insert
			 * Returns: true if the insert was sucessfull, false otherwise
			 */
			bool insert(IGameObject obj){
				auto box = obj.boundingBox;
				if(m_HasChilds){
					foreach(ref child;m_Childs){
						if(child.insert(obj))
							return true;
					}
				}
				if(obj.boundingBox in m_BoundingBox){
					m_Objects.insertBack(obj);
					changeObjectLocation(this,m_Objects.back());
					if(!m_HasChilds && m_Objects.size() >= 8 && m_RealSize > m_MinSize){
						subdivide();
					}
					return true;
				}
				return false;
			}
			
			void debugDraw(shared(IRenderer) renderer){
				renderer.drawBox(m_BoundingBox,vec4(1.0f,0.0f,0.0f,1.0f));
				if(m_HasChilds){
					foreach(ref child;m_Childs){
						renderer.drawLine(m_Center,child.m_Center,vec4(1.0f,1.0f,0.0f,1.0f));
						child.debugDraw(renderer);
					}
				}
				foreach(ref object;m_Objects[]){
					renderer.drawBox(object.boundingBox,vec4(0.0f,1.0f,0.0f,1.0f));
				}
			}
			
			void dumpToConsole(string pre){
				logInfo("%s m_RealSize=%s",pre,m_RealSize);
				vec3 min = m_BoundingBox.min.toVec3();
				vec3 max = m_BoundingBox.max.toVec3();
				logInfo("%s m_BoundingBox min=%s (cell:%s rel:%s)",pre,min.f,m_BoundingBox.min.cell.f,m_BoundingBox.min.relPos.f);
				logInfo("%s m_BoundingBox max=%s (cell:%s rel:%s)",pre,max.f,m_BoundingBox.max.cell.f,m_BoundingBox.max.relPos.f);
				foreach(ref object;m_Objects[]){
					logInfo("%s Object %s",pre,object.inspect()[]);
					min = object.boundingBox.min.toVec3();
					max = object.boundingBox.max.toVec3();
					logInfo("%s        boundingBox min=%s (cell:%s rel:%s)",pre,min.f,object.boundingBox.min.cell.f,object.boundingBox.min.relPos.f);
					logInfo("%s        boundingBox max=%s (cell:%s rel:%s)",pre,max.f,object.boundingBox.max.cell.f,object.boundingBox.max.relPos.f);
				}
				if(m_HasChilds){
					foreach(ref child;m_Childs){
						logInfo("%s-+",pre);
						child.dumpToConsole(pre ~ " |");
						logInfo(pre);
					}
				}
			}
	}
	
  static struct ObjectInfo {
    Node node;
    DoubleLinkedList!(IGameObject).Range at;

    this(Node node, DoubleLinkedList!(IGameObject).Range at){
      this.node = node;
      this.at = at;
    }
  }

	Node m_Root;	
  Hashmap!(IGameObject, ObjectInfo, ReferenceHashPolicy) m_ObjectInNode;
	Vector!(IGameObject) m_GlobalObjects;
	Vector!(IRenderable) m_GlobalRenderables;
	ExtendDirection m_ExtendDirection = ExtendDirection.NEGATIVE;
	float m_MinSize;
	
	void changeObjectLocation(Node node, DoubleLinkedList!(IGameObject).Range r){
		m_ObjectInNode[r.front()] = ObjectInfo(node,r);
	}
	
public:
	
	struct QueryRange {
		private:

      static struct NodeInfo {
        Node node;
        bool completelyIn;

        this(Node node, bool completelyIn){
          this.node = node;
          this.completelyIn = completelyIn;
        }
      }
			
			Stack!(NodeInfo) m_NodeList;
			AlignedBox m_Box;
			IGameObject m_CurrentObject;
			Node m_CurrentNode;
			DoubleLinkedList!(IGameObject).Range m_CurPos;
			
			void add(NodeInfo info){
				bool completelyIn = info.completelyIn || (info.node.m_BoundingBox in m_Box);
				if(info.node.m_HasChilds){
					foreach(child;info.node.m_Childs){
						if(completelyIn || child.m_BoundingBox.intersects(m_Box))
							m_NodeList.push(NodeInfo(child,completelyIn));
					}
				}
				if(info.node.m_Objects.empty){
					if(m_NodeList.empty){
						m_CurrentNode = null;
						return;
					}
					add(m_NodeList.pop());
					return;
				}
				m_CurrentNode = info.node;
				m_CurPos = info.node.m_Objects[];
			}
		public:
      @disable this();

			this(Octree tree, AlignedBox box)
			{
				m_Box = box;
				m_NodeList = New!(Stack!(NodeInfo))(1024);
				if(tree.m_Root.m_BoundingBox.intersects(m_Box))
					m_NodeList.push( NodeInfo( tree.m_Root, (tree.m_Root.m_BoundingBox in m_Box) ) );
				popFront();
			}

      this(this)
      {
        m_NodeList = New!(Stack!(NodeInfo))(m_NodeList);
      }

      ~this()
      {
        Delete(m_NodeList);
      }
		
			@property bool empty(){
				return (m_CurrentObject is null);
			}
			
			@property IGameObject front(){
				return m_CurrentObject;
			}
			
			void popFront(){
				while(true){
					if(m_CurrentNode is null){
						while( !m_NodeList.empty && (m_CurrentNode is null) ){
							add(m_NodeList.pop());
						}
						if(m_NodeList.empty && m_CurrentNode is null){
							m_CurrentObject = null;
							return;
						}
						assert(!m_CurPos.empty());
					}
					
					while(!m_CurPos.empty()){
						IGameObject cur = m_CurPos.front;
						auto objBox = cur.boundingBox;
						assert(objBox.isValid());
						if(objBox.intersects(m_Box)){
							m_CurrentObject = cur;
							m_CurPos.popFront();
							return;
						}
						m_CurPos.popFront();
					}
					if(m_CurPos.empty()){
						m_CurrentNode = null;
						m_CurrentObject = null;
					}
				}
			}
	}
	
	/**
	 * constructor
	 * Params:
	 *  startSize = the start size of the octree
     *  minSize = the minimum size of a octree node
	 */
	this(float startSize, float minSize){
		m_Root = new Node(Position(vec3(0,0,0)),startSize);
		m_MinSize = minSize;
		m_GlobalObjects = new Vector!(IGameObject)();
		m_GlobalRenderables = new Vector!(IRenderable)();
    m_ObjectInNode = New!(typeof(m_ObjectInNode))();
	}

  ~this()
  {
    deleteAllRemainingObjects();
    Delete(m_GlobalRenderables);
    Delete(m_GlobalObjects);
    Delete(m_ObjectInNode);
    Delete(m_Root);
  }
  
  /**
   * deletes all objects remaining in the octree
   */
  void deleteAllRemainingObjects()
  {
    m_ObjectInNode.removeWhere((ref IGameObject obj, ref ObjectInfo info){
      info.node.m_Objects.removeSingle(info.at);
      Delete(obj);
      return true;
    });
    m_GlobalRenderables.resize(0);
    foreach(object; m_GlobalObjects)
    {
      Delete(object);
    }
    m_GlobalObjects.resize(0);
  }

	/**
     * inserts a object into the octree
     */
	void insert(IGameObject obj){
		//object is outside of our octree
		while( !(obj.boundingBox in m_Root.m_BoundingBox) ){
			debug printf("extending octree");
			m_Root = new Node(m_Root,m_ExtendDirection);
      m_ExtendDirection = (m_ExtendDirection == ExtendDirection.NEGATIVE) ? ExtendDirection.POSITIVE : ExtendDirection.NEGATIVE;
		}
		m_Root.insert(obj);
	}
		
	/**
	 * removes a object from the octree
	 */
	bool remove(IGameObject obj){
		//if((obj in m_ObjectInNode) !is null){
    if(m_ObjectInNode.exists(obj)){
			auto info = m_ObjectInNode[obj];
			info.node.m_Objects.removeSingle(info.at);
      m_ObjectInNode.remove(obj);
      return true;
		}
    return false;
	}
	
	/**
	 * updates the octree
	 */
	void update(){
    IGameObject[] objs = AllocatorNewArray!IGameObject(ThreadLocalStackAllocator.globalInstance, m_ObjectInNode.count);
    scope(exit) AllocatorDelete(ThreadLocalStackAllocator.globalInstance, objs);

    size_t i=0;
    foreach(obj, ref info; m_ObjectInNode)
    {
      objs[i++] = obj;
    }

		foreach(obj; objs){
			if(obj.hasMoved()){
				auto info = m_ObjectInNode[obj];
				if(info.node.m_HasChilds || !(obj.boundingBox in info.node.m_BoundingBox)){
					remove(obj);
					insert(obj);
				}
			}
		}
	}
	
	/**
	 * optimizes the octree
	 */
	void optimize(){
		m_Root.optimize();
	}
	
	/**
	 * returns a range to iterate over all elements inside a aligend box
	 */
	QueryRange getObjectsInBox(AlignedBox box)
	in {
		assert(box.isValid);
	}
	body {
		return QueryRange(this,box);
	}
	
	/**
	 * Returns: an iterator to iterate over all objects in the tree
	 */
	auto allObjects(){
		return m_ObjectInNode.keys;
	}

	/**
	 * draws debugging information about the octree
	 * Params
	 *  renderer = the renderer to use for drawing
	 */
	void debugDraw(shared(IRenderer) renderer){
		m_Root.debugDraw(renderer);
	}
	
	/**
	 * adds a new global game object (this object is not added to the octree, but kept in a separate table)
	 * Params:
	 *  obj = the object to add
	 */
	void addGlobalObject(IGameObject obj){
		m_GlobalObjects ~= obj;
	}
	
	/**
	 * removes a global game object
	 * Params:
	 *  obj = the object to remove
	 * Returns: true on success, false otherwise
	 */
	bool removeGlobalObject(IGameObject obj){
		return m_GlobalObjects.remove(obj);
	}
	
	/** 
	 * Returns: a range to iterate over all global objects
	 */
	auto globalObjects(){
		return m_GlobalObjects.GetRange();
	}
	
	/**
	 * adds a new global renderable 
	 *  obj = the renderable to add
	 */
	void addGlobalRenderable(IRenderable obj){
		m_GlobalRenderables ~= obj;
	}
	
	/**
	 * removes a global renderable
	 * Params:
	 *  obj = the object to remove
	 * Returns: true on success, false otherwise
	 */
	bool removeGlobalRenderable(IRenderable obj){
		return m_GlobalRenderables.remove(obj);
	}
	
	/**
	 * Returns: a range to iterate the global renderables
	 */
	auto globalRenderables(){
		return m_GlobalRenderables[];
	}
	
	/**
	 * dumps the octree contents to the logfile
	 */
	void dumpToConsole(){
		m_Root.dumpToConsole("");
	}
}

unittest {
	class TestObject : IGameObject {
	private:
		Position m_Position;
	public:
		this(Position position){
			m_Position = position;
		}
	
		override IRenderProxy renderProxy() {
			return null;
		}
		
		override bool syncOverNetwork() const {
			return false;
		}
		
		override EntityId entityId() const {
			return cast(EntityId)0;
		}
		
		override Position position() const {
			return m_Position;
		}
		
		override void position(Position pos){
			m_Position = pos;
		}
		
		override Quaternion rotation() const {
			//TODO implement
			return Quaternion(vec3(1.0f,0.0f,0.0f),0.0f);
		}
		
		override mat4 transformation(Position origin) const {
			//TODO implement
			return mat4.Identity();
		}
		
		override IGameObject father() const {
			return null;
		}
		
		override AlignedBox boundingBox() const {
			return AlignedBox(vec3(-5,-5,-5),vec3(5,5,5)) + m_Position;
		}
		
		override bool hasMoved() const {
			//TODO implement
			return false;
		}
		
		override void update(float timeDiff) {
			//do nothing (yet)
		}
		
		override void postSpawn(){ }
		override void onDeleteRequest(){ }
		override IEvent constructEvent(EventId id){
			assert(0);
		}
		
		override void serialize(ISerializer ser, bool fullSerialization){ }
		override void resetChangedFlags(){ }
		
		override rcstring inspect(){
			return _T("");
		}
		
		override void debugDraw(shared(IRenderer) renderer){ }
		override void toggleCollMode(){ }
	}
	
	TestObject[] objects;
	objects ~= new TestObject(Position(vec3(-500,-500,-500)));
	objects ~= new TestObject(Position(vec3( 500,-500,-500)));
	objects ~= new TestObject(Position(vec3( 500, 500,-500)));
	objects ~= new TestObject(Position(vec3(-500, 500,-500)));
	objects ~= new TestObject(Position(vec3(-500,-500, 500)));
	objects ~= new TestObject(Position(vec3( 500,-500, 500)));
	objects ~= new TestObject(Position(vec3( 500, 500, 500)));
	objects ~= new TestObject(Position(vec3(-500, 500, 500)));
	
	Octree oct = new Octree(750.0f,100.0f);
	Octree oct2 = new Octree(100.0f,50.0f);
	foreach(o;objects){
		oct.insert(o);
		oct2.insert(o);
	}
	
	assert(oct.m_Root.m_HasChilds == true);
	
	AlignedBox queryBox1 = AlignedBox(vec3(-500,-500,0),vec3(500,500,500));
	
	IGameObject[] res1;
	for(auto query = oct.getObjectsInBox(queryBox1);!query.empty();query.popFront()){
		res1 ~= query.front();
	}
	
	IGameObject[] res2;
	for(auto query = oct.getObjectsInBox(queryBox1);!query.empty();query.popFront()){
		res2 ~= query.front();
	}
	
	bool isIn(IGameObject[] ar, IGameObject obj){
		foreach(o;ar){
			if(o is obj)
				return true;
		}
		return false;
	}
	
	assert(res1.length == 4);
	assert(isIn(res1,objects[4]));
	assert(isIn(res1,objects[5]));
	assert(isIn(res1,objects[6]));
	assert(isIn(res1,objects[7]));
	
	assert(res2.length == 4);
	assert(isIn(res2,objects[4]));
	assert(isIn(res2,objects[5]));
	assert(isIn(res2,objects[6]));
	assert(isIn(res2,objects[7]));
}
