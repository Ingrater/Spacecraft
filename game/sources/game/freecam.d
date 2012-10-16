module game.freecam;

import game.gameobject, game.game;
import std.math;

class FreeCam : IGameObject, IControllable {
private:
	SmartPtr!IRenderProxy m_RenderProxy;
	Position m_Position;
	Quaternion m_Rotation;
	mat4 m_ViewMatrix;
	vec3 m_Velocity;
	float m_Rotate;
	float m_RotateAroundCenter = 0.0f;
	float m_RotateAroundCenterSpeed = 3.0f;
	float m_RotateAroundCenterPos = 0.0f;
	float m_RotateAroundCenterOffset = 20.0f;
	
	
	// TODO: Fix units for speeds
	// Rotation speed in degree per second
	float m_RotationSpeed = 0.05;
	// Movement speed in meters per second
	float m_MovementSpeed = 0.01;
	// Factor by which the booster increases the normal velocity (increased by
	// the booster() function)
	float m_BoostFactor = 1.0;
	
	mixin DummyMessageCode;
	
public:
	this(IRenderProxy renderProxy){
		m_RenderProxy = renderProxy;
		m_Position = Position(vec3(0,-0.001f,20));
		m_Rotation = Quaternion(vec3(1,0,0),15.0f);
		m_Velocity = vec3(0.0f,0.0f,0.0f);
		m_Rotate = 0.0f;
	}

  ~this()
  {
  }

	override bool syncOverNetwork() const {
		return false;
	}

	override IRenderProxy renderProxy() {
		return m_RenderProxy;
	}

  override Object physicsComponent()
  {
    return null;
  }
	
	override EntityId entityId() const {
		return cast(EntityId)1;
	}
	
	override Position position() const {
		return m_Position;
	}
	
	override void position(Position pos){
		m_Position = pos;
	}
	
	override Quaternion rotation() const {
		return m_Rotation;
	}
	
	override mat4 transformation(Position origin) const {
		if(m_RotateAroundCenter <= 0.0f)
			return m_Rotation.toMat4() * TranslationMatrix(m_Position - origin);
		else
			return m_ViewMatrix.Inverse() * TranslationMatrix(m_Position - origin);
	}
	
	override IGameObject father() const {
		return null;
	}
	
	override AlignedBox boundingBox() const {
		return AlignedBox(Position(vec3(-1,-1,-1)),Position(vec3(1,1,1)));
	}
	
	override bool hasMoved() const {
		return true;
	}
	
	override void update(float timeDiff){
		if(m_RotateAroundCenter <= 0.0f){
			vec4 dir = vec4(1.0f,0.0f,0.0f,1.0f);
			dir = m_Rotation.toMat4() * dir;
			if(m_Velocity.x != 0.0f)
				m_Position = m_Position + vec3(dir * m_Velocity.x * timeDiff) * m_BoostFactor;
			
			dir = vec4(0.0f,0.0f,1.0f,1.0f);
			dir = m_Rotation.toMat4() * dir;
			if(m_Velocity.y != 0.0f)
				m_Position = m_Position + vec3(dir * m_Velocity.y * timeDiff) * m_BoostFactor;
			
			if(m_Rotate != 0.0f){
				m_Rotation = Quaternion(vec3(0.0f,0.0f,1.0f),m_Rotate * timeDiff) * m_Rotation;
			}
		}
		else {
			m_RotateAroundCenterPos += m_RotateAroundCenterSpeed * timeDiff;
			vec3 pos = vec3(sin(m_RotateAroundCenterPos) * m_RotateAroundCenter,
							m_RotateAroundCenterOffset,
							cos(m_RotateAroundCenterPos) * m_RotateAroundCenter);
			m_Position = Position(pos);
			m_ViewMatrix = mat4.LookDirMatrix(vec4(-pos),vec4(0,1,0,1));
		}
	}
	
	void rotateAroundCenter(float radius, float speed, float offset){
		m_RotateAroundCenter = radius;
		m_RotateAroundCenterSpeed = speed;
		m_RotateAroundCenterOffset = offset;
	}
	
	//
	// Controller stuff
	//
	
	void look(float screenDeltaX, float screenDeltaY){
		auto qy = Quaternion(vec3(1, 0, 0), screenDeltaY);
		auto qx = Quaternion(vec3(0, 1, 0), screenDeltaX);
		m_Rotation = qy * m_Rotation;
		m_Rotation = qx * m_Rotation;
	}
	
	void moveForward(bool pressed){
		auto dir = vec3(0, -1, 0) * m_MovementSpeed;
		m_Velocity += (pressed) ? dir : -dir;
	}
	void moveBackward(bool pressed){
		auto dir = vec3(0, 1, 0) * m_MovementSpeed;
		m_Velocity += (pressed) ? dir : -dir;
	}
	void moveLeft(bool pressed){
		auto dir = vec3(-1, 0, 0) * m_MovementSpeed;
		m_Velocity += (pressed) ? dir : -dir;
	}
	void moveRight(bool pressed){
		auto dir = vec3(1, 0, 0) * m_MovementSpeed;
		m_Velocity += (pressed) ? dir : -dir;
	}
	void moveUp(bool pressed){
		auto dir = vec3(0, 0, 1) * m_MovementSpeed;
		m_Velocity += (pressed) ? dir : -dir;
	}
	void moveDown(bool pressed){
		auto dir = vec3(0, 0, -1) * m_MovementSpeed;
		m_Velocity += (pressed) ? dir : -dir;
	}
	
	void rotateLeft(bool pressed){
		m_Rotate -= (pressed) ? m_RotationSpeed : -m_RotationSpeed;
	}
	void rotateRight(bool pressed){
		m_Rotate += (pressed) ? m_RotationSpeed : -m_RotationSpeed;
	}
	
	void booster(bool pressed){
		if (pressed)
			m_BoostFactor += 20;
		else
			m_BoostFactor -= 20;
	}
	
	void fire(ubyte weapon, bool pressed){
		// Nothing to do right now
	}
	void scoreBoard(bool pressed){
		// Nothing to do right now
	}
	void select(){
		// Nothing to do right now
	}
	
	override rcstring inspect(){
		return format("<%s id: %d pos: (cell: %s, pos: %s) vel: %s, rot: (axis: %s, %s, %s, angle: %s)>",
			this.classinfo.name, this.entityId, m_Position.cell.f, m_Position.relPos.f, m_Velocity.f,
			m_Rotation.x, m_Rotation.y, m_Rotation.z, m_Rotation.angle);
	}
	
	override void debugDraw(shared(IRenderer) renderer){
		// Nothing to do right now
	}
	
	
	//
	// Do nothing stuff
	// TODO: The camera should not be a game object. It should be attached to the
	// player (still todo, too).
	//
	
	override void postSpawn(){ }
	override void onDeleteRequest(){ }
	override void toggleCollMode(){ }
	override void serialize(ISerializer ser, bool fullSerialization){ }
	override void resetChangedFlags(){ }
}

class FreeCamUp : IGameObject, IControllable {
private:
	SmartPtr!IRenderProxy m_RenderProxy;
	Position m_Position;
	mat4 m_ViewMatrix;
	vec3 m_Velocity;
  vec4 m_Up;
  vec4 m_lookDir;


	// TODO: Fix units for speeds
	// Movement speed in meters per second
	float m_MovementSpeed = 0.01;
	// Factor by which the booster increases the normal velocity (increased by
	// the booster() function)
	float m_BoostFactor = 1.0;

	mixin DummyMessageCode;

public:
	this(IRenderProxy renderProxy, vec3 upVector){
		m_RenderProxy = renderProxy;
		m_Position = Position(vec3(0,-0.001f,20));
		m_Velocity = vec3(0.0f,0.0f,0.0f);
    m_Up = vec4(upVector, 1.0f);
    m_ViewMatrix = mat4.Identity();
    m_lookDir = vec4(1.0f, 0.0f, 0.0f, 1.0f);
	}

  ~this()
  {
  }

	override bool syncOverNetwork() const {
		return false;
	}

	override IRenderProxy renderProxy() {
		return m_RenderProxy;
	}

	override EntityId entityId() const {
		return cast(EntityId)1;
	}

	override Position position() const {
		return m_Position;
	}

  override Object physicsComponent()
  {
    return null;
  }

	override void position(Position pos){
		m_Position = pos;
	}

	override Quaternion rotation() const {
		return Quaternion(m_ViewMatrix.rotationPart);
	}

	override mat4 transformation(Position origin) const {
	  return m_ViewMatrix * TranslationMatrix(m_Position - origin);
	}

	override IGameObject father() const {
		return null;
	}

	override AlignedBox boundingBox() const {
		return AlignedBox(Position(vec3(-1,-1,-1)),Position(vec3(1,1,1)));
	}

	override bool hasMoved() const {
		return true;
	}

	override void update(float timeDiff){
		vec4 dir = m_lookDir;

    vec4 from = vec4(0,0,0,1);
    m_ViewMatrix = mat4.LookAtMatrix(from, dir, m_Up);
    //remove the translation part
    m_ViewMatrix.f[12] = m_ViewMatrix.f[13] = m_ViewMatrix.f[14] = 0.0f;
    m_ViewMatrix = m_ViewMatrix.Inverse();

    dir = vec4(1.0f,0.0f,0.0f,1.0f);
		dir = m_ViewMatrix * dir;
		if(m_Velocity.x != 0.0f)
			m_Position = m_Position + vec3(dir * m_Velocity.x * timeDiff) * m_BoostFactor;

		dir = vec4(0.0f,0.0f,1.0f,1.0f);
		dir = m_ViewMatrix * dir;
		if(m_Velocity.y != 0.0f)
			m_Position = m_Position + vec3(dir * -m_Velocity.y * timeDiff) * m_BoostFactor;
	}

	//
	// Controller stuff
	//

	void look(float screenDeltaX, float screenDeltaY){
    vec4 left = m_Up.cross(m_lookDir);
		auto qy = Quaternion(vec3(left), screenDeltaY);
		auto qx = Quaternion(vec3(0, 1, 0), screenDeltaX);
		m_lookDir = ((qy * qx).toMat4() * m_lookDir).normalize();
	}

	void moveForward(bool pressed){
		auto dir = vec3(0, 1, 0) * m_MovementSpeed;
		m_Velocity += (pressed) ? dir : -dir;
	}
	void moveBackward(bool pressed){
		auto dir = vec3(0, -1, 0) * m_MovementSpeed;
		m_Velocity += (pressed) ? dir : -dir;
	}
	void moveLeft(bool pressed){
		auto dir = vec3(-1, 0, 0) * m_MovementSpeed;
		m_Velocity += (pressed) ? dir : -dir;
	}
	void moveRight(bool pressed){
		auto dir = vec3(1, 0, 0) * m_MovementSpeed;
		m_Velocity += (pressed) ? dir : -dir;
	}
	void moveUp(bool pressed){
		auto dir = vec3(0, 0, 1) * m_MovementSpeed;
		m_Velocity += (pressed) ? dir : -dir;
	}
	void moveDown(bool pressed){
		auto dir = vec3(0, 0, -1) * m_MovementSpeed;
		m_Velocity += (pressed) ? dir : -dir;
	}

	void rotateLeft(bool pressed){
	}
	void rotateRight(bool pressed){
	}

	void booster(bool pressed){
		if (pressed)
			m_BoostFactor += 20;
		else
			m_BoostFactor -= 20;
	}

	void fire(ubyte weapon, bool pressed){
		// Nothing to do right now
	}
	void scoreBoard(bool pressed){
		// Nothing to do right now
	}
	void select(){
		// Nothing to do right now
	}

	override rcstring inspect(){
		return _T("FreeCamUp");
	}

	override void debugDraw(shared(IRenderer) renderer){
		// Nothing to do right now
	}


	//
	// Do nothing stuff
	// TODO: The camera should not be a game object. It should be attached to the
	// player (still todo, too).
	//

	override void postSpawn(){ }
	override void onDeleteRequest(){ }
	override void toggleCollMode(){ }
	override void serialize(ISerializer ser, bool fullSerialization){ }
	override void resetChangedFlags(){ }
}