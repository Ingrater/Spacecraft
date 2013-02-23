module base.gameobject;

public import base.renderproxy;
public import thBase.math3d.all;
import base.events, base.net, base.renderer;

struct EntityId
{
  uint id;

  alias id this;

  this(uint id)
  {
    this.id = id;
  }

  uint Hash()
  {
    return id;
  }

  string toString()()
  {
    static assert(0, "not convertible");
  }
}

interface IControllable {
	void look(float screenDeltaX, float screenDeltaY);
	void moveForward(bool pressed);
	void moveBackward(bool pressed);
	void moveLeft(bool pressed);
	void moveRight(bool pressed);
	void moveUp(bool pressed);
	void moveDown(bool pressed);
	void rotateLeft(bool pressed);
	void rotateRight(bool pressed);
	void booster(bool pressed);
	void fire(ubyte weapon, bool pressed);
	void scoreBoard(bool pressed);
	void select();
}

interface IGameObject : IRenderable, ISerializeable {	
	/**
	 * getter for the entityId of the object
	 */
	EntityId entityId() const;
	
	/**
	 * getter for the position of the object
	 */
	Position position() const;
	/**
	 * setter for the position of the object
	 */
	void position(Position pos);
	
	/**
	 * getter for the rotation of the object
	 */
	Quaternion rotation() const;
	
	/**
	 * if the object is not a root object, this should return the transformation to the root object
	 */
	mat4 transformation(Position origin) const;
	
	
	/**
	 * Returns: the father of this game object
	 */
	const(IGameObject) father() const;
	
	/**
	 * returns the already correctly transformed bounding box of this object
	 */
	AlignedBox boundingBox() const;
	
	/**
	 * Returns: true if the object moved since this function was called the last time, false otherwise
	 */
	bool hasMoved();
	
	/**
	 * updates the game object
	 * Params:
	 *  timeDiff = time that passed since the last frame
	 */
	void update(float timeDiff);
	
	/**
	 * initializes the game object after spawning
	 */
	void postSpawn();
	
	/**
	 * Called directly before the game object is removed from the world. This
	 * callback is triggered by the removeGameObject() message of the GameFactory.
	 */
	void onDeleteRequest();
	
	/**
	 * Constructs an event class of the specified event type
	 */
	IEvent constructEvent(EventId id, IAllocator allocator);
	
	/**
	 * Inspection method for debugging. Returns a string that should give an idea
	 * what the game objet is and what stat it is in.
	 */
	rcstring inspect();
	
	/**
	 * Called on the client on each cycle to give game objects a change to draw
	 * some useful information.
	 */
	void debugDraw(shared(IRenderer) renderer);
	
	/**
	 * Returns: true if the object should be synchronized over the network, false it not
	 */
	bool syncOverNetwork() const;
	
	/**
	 * Request that the game object switches its display mesh to the colision mesh.
	 */
	void toggleCollMode();
	
	/**
	 * neccssary function to allow storing inside a hash table
	 */
	final bool Equals(IGameObject rh)
  {
    return (this is rh);
  }
}
