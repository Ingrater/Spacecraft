module game.gameobject;

public import base.gameobject, base.game, base.net, base.renderer;
public import game.collision, game.hitable;
import game.game;
import base.physics;


import base.all: g_Env;


/**
 * Base class for all regular game objects
 */
abstract class GameObject : IGameObject {
	
	//
	// Common stuff for server and client
	//
	
	protected {
		GameSimulation m_Game;
		EntityId m_EntityId;
		bool m_OnServer;
		
		// m_HasMoved needs serialization so the client octrees get updated when the
		// server moves the entity.
		netvar!Position m_Position;
		netvar!bool m_HasMoved;
		netvar!vec3 m_Velocity;
		netvar!vec3 m_Acceleration;
		
		netvar!Quaternion m_Rotation;
		netvar!vec3 m_RotVelocity;
		
		netvar!vec3 m_Scale;
		
		AlignedBox m_OriginalBoundingBox, m_BoundingBox;
	}
	
	override bool syncOverNetwork() const {
		return true;
	}
	
	override EntityId entityId() const {
		return m_EntityId;
	}
	
	override Position position() const {
		return m_Position;
	}
	
	override void position(Position pos){
		if (pos != m_Position.value){
			m_HasMoved = true;
			m_Position = pos;
		}
	}
	
	vec3 velocity() const {
		return m_Velocity.value;
	}
	
	void velocity(vec3 vel){
		m_Velocity = vel;
	}
	
	vec3 acceleration() const {
		return m_Acceleration.value;
	}
	
	void acceleration(vec3 acl){
		m_Acceleration = acl;
	}
	
	override Quaternion rotation() const {
		return m_Rotation;
	}
	
	vec3 scale(){
		return m_Scale;
	}
	
	GameSimulation game() {
		return m_Game;
	}
	
	/**
	 * Returns the orientation vectors of the object:
	 * - Vector to the right
	 * - Vector to the top (up vector)
	 * - Vector to the front (the direction into the object is looking)
	 * 
	 * Implementation note: The vectors are extracted out of the rotation matrix.
	 * Please note that the front vector is the negative Z axis of the rotation
	 * matrix (Z faces towards the user in OpenGL, not towards the scene).
	 */
	vec3[3] orientation() {
		auto rotationMatrix = transformation(Position(vec3(0, 0, 0))).f;
    vec3[3] result;
		result[0] = vec3(rotationMatrix[0], rotationMatrix[1], rotationMatrix[2]);
		result[1] = vec3(rotationMatrix[4], rotationMatrix[5], rotationMatrix[6]);
		result[2] = vec3(rotationMatrix[8], rotationMatrix[9], rotationMatrix[10]);
    return result;
	}
	
	/**
	 * Rotate `degree` degrees around the specified axis.
	 */
	void rotate(vec3 axis, float degree){
		m_Rotation = m_Rotation.value * Quaternion(axis, degree);
	}
	
	/**
	 * Returns the transformation to the object space of this game object
	 * (includes all parent transformations as well).
	 */
	override mat4 transformation(Position origin) const {
		if (this.father is null)
			return ScaleMatrix(m_Scale) * rotation.toMat4() * TranslationMatrix(m_Position - origin);
		else
			return ScaleMatrix(m_Scale) * rotation.toMat4() * TranslationMatrix(m_Position.toVec3()) * this.father.transformation(origin);
	}
	
	override const(IGameObject) father() const {
		return null;
	}

  override Object physicsComponent()
  {
    return null;
  }
	
	/**
	 * Returns `true` every time the object has moved. The underlying variable
	 * gets synced so the client objects are automatically moved if the server
	 * moves. The only problem occurs when a player joins the game. Then the
	 * server regards most objects as not moved but the client needs to move them
	 * once so they get properly inserted into the client octree. Therefore we use
	 * the `m_FreshlySpawned` to override the moved state once only for game
	 * objects that are new to the client.
	 */
	bool hasMoved() {
		if (m_HasMoved || m_FreshlySpawned){
			m_HasMoved = false;
			m_FreshlySpawned = false;
			return true;
		}
		return false;
	}
	
	AlignedBox boundingBox() const
		out(result) { assert(result.isValid()); }
	body {
		return m_BoundingBox;
	}
	
	IRenderProxy renderProxy() {
		return m_RenderProxy;
	}
	
	void update(float timeDiff){
		if(g_Env.viewModel){
			updateOnServer(timeDiff);
			updateOnClient(timeDiff);
		}
		else {
			if (m_OnServer)
				updateOnServer(timeDiff);
			else
				updateOnClient(timeDiff);
		}
	}
	
	override rcstring inspect(){
		return buildInspect("");
	}
	
	protected rcstring buildInspect(string additionalData){
    //TODO bounding box leaking
    //auto bbox = m_BoundingBox.toString();
		return format("<%s id: %d pos: %s (cell: %s, pos: %s) vel: %s, acl: %s, rot: (axis: %s, %s, %s, angle: %s) %s>",
			this.classinfo.name, m_EntityId.id, m_Position.toVec3().f, m_Position.cell.f, m_Position.relPos.f, m_Velocity.f, m_Acceleration.f,
			m_Rotation.x, m_Rotation.y, m_Rotation.z, m_Rotation.angle, additionalData);
	}
	
	/**
	 * Calculates the real bounding box based on the orginal bounding box, the
	 * current position and rotation. The update is only performed if the position
	 * or rotation changed.
	 */
	protected void updateBoundingBox(bool force = false){
		assert(m_OriginalBoundingBox.isValid(), "game: the client constructor have to initialize a valid original bounding box");
		if (m_Position.changed || m_Rotation.changed || force){
			float[3] min = float.max, max = -float.max;
			mat4 trans = this.transformation(Position(vec3(0, 0, 0)));
			
			foreach(vertex; m_OriginalBoundingBox.vertices){
				vec4 transformed_vertex = trans * vec4(vertex.toVec3());
				
				for(ubyte i = 0; i < min.length; i++){
					if (transformed_vertex.f[i] < min[i])
						min[i] = transformed_vertex.f[i];
					if (transformed_vertex.f[i] > max[i])
						max[i] = transformed_vertex.f[i];
				}
			}
			
			m_BoundingBox = AlignedBox(
				Position(vec3(min)),
				Position(vec3(max))
			);
		}
	}
	
	
	//
	// Server side game object code
	//
	
	protected {
		CollisionHull m_CollisionHull;
	}
	
	CollisionHull collisionHull(){
		return m_CollisionHull;
	}
	
	/**
	 * do nothing constructor
	 */
	this(){}
	
	/**
	 * Server side constructor
	 */
	this(EntityId entityId, GameSimulation game, Position pos, Quaternion rot, CollisionHull col, vec3 scale = vec3(1, 1, 1)){
		m_EntityId = entityId;
		m_Game = game;
		m_OnServer = true;
		m_Position = pos;
		m_Scale = scale;
		m_Velocity = vec3(0, 0, 0);
		m_Acceleration = vec3(0, 0, 0);
		m_Rotation = rot;
		m_RotVelocity = vec3(0, 0, 0);
		
		m_CollisionHull = col;
		if (col !is null)
			m_OriginalBoundingBox = col.boundingBox;
		else
			m_OriginalBoundingBox = AlignedBox(Position(vec3(-5, -5, -5)), Position(vec3(5, 5, 5)));
		
		updateBoundingBox();
	}
	
	/**
	 * Game logic update code. Called once per cycle and each changed netvar will
	 * be broadcasted to all clients and overwrite their state.
	 */
	void updateOnServer(float timeDiff){
		auto dt_sec = timeDiff / 1_000;
		m_Velocity = m_Velocity + m_Acceleration * dt_sec;
		if (m_Velocity.length > float.epsilon)
			this.position = m_Position.value + m_Velocity * dt_sec;
		
		// Rotate around each axis: x (right), y (top) and negative z (view vector)
		vec3[3] axis = orientation();
		rotate(axis[0], m_RotVelocity.x * dt_sec);
		rotate(axis[1], m_RotVelocity.y * dt_sec);
		rotate(axis[2], m_RotVelocity.z * dt_sec);
		
		updateBoundingBox();
	}
	
	
	//
	// Client side game object code
	//
	
	protected {
		SmartPtr!IRenderProxy m_RenderProxy;
		bool m_FreshlySpawned;
	}
	
	/**
	 * Client side constructor. Called when the game object factory creates this
	 * game object as requested by the server. This takes place before the data
	 * for this game object arives. Therefore you can only set attributes but the
	 * netvars will not be set to their proper server values yet.
	 * 
	 * The client constructor needs to initialize all relevant data to fail save
	 * values. Otherwise the renderer might extract invalid data (e.g. NANs) and
	 * crashes on the checks.
	 * 
	 * The collision hull `col` is only for debugging purposes. It is not used for
	 * colision but drawn by the debug output of the game object.
	 */
	this(EntityId entityId, GameSimulation game, AlignedBox boundingBox, CollisionHull col){
		m_Game = game;
		m_EntityId = entityId;
		m_OnServer = false;
		
		// All netvars are set by incomming sync data after this constructor:
		// m_Position, m_HasMoved, m_Velocity, m_Acceleration, m_Rotation
		
		// Set all relevant data to valid fail saves so the renderer does not crash
		m_Position = Position(vec3(0, 0, 0));
		m_Velocity = vec3(0, 0, 0);
		m_Acceleration = vec3(0, 0, 0);
		m_Rotation = Quaternion(vec3(1, 0, 0), 0);
		m_RotVelocity = vec3(0, 0, 0);
		m_Scale = vec3(1, 1, 1);
		
		m_CollisionHull = col;
		m_OriginalBoundingBox = boundingBox;
		updateBoundingBox();
	}
	
	/**
	 * Called by the game object factory after the netvars for the new game object
	 * have been received from the server. It is safe to use the netvars now.
	 */
	void postSpawn(){
		m_FreshlySpawned = true;
		updateBoundingBox(true);
	}
	
	/**
	 * Client side game object update. Remember the netvar values are overwritten
	 * with the server side state each time data arrives. The client side update
	 * is a good place for interpolation, etc.
	 * 
	 * Right now we only update the client side bounding box here.
	 */
	void updateOnClient(float timeDiff){
		updateBoundingBox();
	}
	
	/**
	 * Called on the client on each cycle to give game objects a change to draw
	 * some useful information.
	 */
	void debugDraw(shared(IRenderer) renderer){
		assert(!m_OnServer, "game: debugDraw of GameObjects does only work on the client!");
		vec3[3] axis = orientation();
		renderer.drawLine(position, position + axis[0] * 50, vec4(1, 0, 0, 1));
		renderer.drawLine(position, position + axis[1] * 50, vec4(0, 1, 0, 1));
		renderer.drawLine(position, position + axis[2] * 50, vec4(0, 0, 1, 1));
		
		if (m_CollisionHull)
    {
			m_CollisionHull.debugDraw(this.position, this.rotation, renderer);
		}
	}
	
	/**
	 * Called directly before the game object is removed from the world. This
	 * callback is triggered by the removeGameObject() message of the game object
	 * factory.
	 */
	void onDeleteRequest(){
		// Nothing to do right now
	}
	
	override void toggleCollMode(){
		// Do nothing by default
	}
	
	
	//
	// DMD bug fixing code
	//
	
	/**
	 * If this implementation isn't here the compiler throws an error that the
	 * method is not implemented or does not override something. Strange because
	 * the child class uses the mixin MessageCode which generates this method.
	 * 
	 * Looks like a compiler bug. Maybe the compiler uses the wrong implementation
	 * but we will see...
	 */
	override IEvent constructEvent(EventId id, IAllocator allocator){
		return null;
	}
}

