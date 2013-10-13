module game.attachedcam;

import base.all, game.gameobject;



class AttachedCamera : IGameObject {
	
	private {
		IGameObject m_Target;
		SmartPtr!IRenderProxy m_RenderProxy;
		vec3 m_Offset;
	}
	
	this(IGameObject target,vec3 offset){
		m_Target = target;
		m_RenderProxy = g_Env.renderer.CreateRenderProxy();
		m_Offset = offset;
	}
	
	void attachTo(IGameObject target) {
		m_Target = target;
	}
	
	IRenderProxy renderProxy() {
		return m_RenderProxy.ptr; //BUG in 2.063.2
	}
	
	IGameObject father() const {
		return null;
	}
	
	/**
	 * The position of the attached camera can not be set. The position of the
	 * attached object is used.
	 */
	void position(Position pos){
		// nothing to do
	}
	
	/**
	 * This camera is client only and is not in the octree. Therefore no movement
	 * notification necessary... I hope.
	 */
	override bool hasMoved() {
		return false;
	}
	
	override void update(float timeDiff) {
		// Nothing to do yet
	}
	
	override rcstring inspect() {
		return format("<%s target: %s>", this.classinfo.name, m_Target);
	}
	
	override void debugDraw(shared(IRenderer) renderer) {
		// Nothing to do yet
	}
	
	override bool syncOverNetwork() const {
		return false;
	}
	
	
	//
	// Pass though stuff to mimic the attached object (we want to see the world
	// though its perspective, don't we?).
	//
	
	EntityId entityId() const {
		return m_Target.entityId();
	}
	
	Position position() const {
		vec4 offset = m_Target.rotation.toMat4() * vec4(m_Offset);
		return m_Target.position() + vec3(offset);
	}
	
	Quaternion rotation() const {
		return m_Target.rotation();
	}
	
	override mat4 transformation(Position origin) const {
		return TranslationMatrix(m_Offset) * m_Target.rotation.toMat4() * TranslationMatrix(m_Target.position - origin);
	}
	
	AlignedBox boundingBox() const {
		return m_Target.boundingBox();
	}
	
	void offset(vec3 offset){
		m_Offset = offset;
	}
	
	//
	// Object is client only (not networked) so just do nothing stuff
	//
	void serialize(ISerializer ser, bool fullSerialization) {}
	void resetChangedFlags() {}
	
	void postSpawn() {}
	void onDeleteRequest() {}
	void toggleCollMode() {}
	override IEvent constructEvent(EventId id, IAllocator allocator) { return null; }
}
