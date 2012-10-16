module game.scheibe;

import base.all, game.gameobject;



class Scheibe : IGameObject {
	
	private {
		IGameObject m_Target;
		SmartPtr!IRenderProxy m_RenderProxy;
		bool m_Enabled = true;
	}
	
	this(IGameObject target){
		m_Target = target;
		m_RenderProxy = g_Env.renderer.CreateRenderProxy3DHud(client.resources.model(_T("cockpit_glass")).model);
	}
	
	void attachTo(IGameObject target) {
		m_Target = target;
	}
	
	IRenderProxy renderProxy() {
		if(m_Enabled)
			return m_RenderProxy;
		else
			return null;
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
	
	void enabled(bool value){
		m_Enabled = value;
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

  override Object physicsComponent()
  {
    return null;
  }
	
	
	//
	// Pass though stuff to mimic the attached object (we want to see the world
	// though its perspective, don't we?).
	//
	
	EntityId entityId() const {
		return m_Target.entityId();
	}
	
	Position position() const {
		return m_Target.position();
	}
	
	Quaternion rotation() const {
		return m_Target.rotation();
	}
	
	override mat4 transformation(Position origin) const {
		return m_Target.transformation(origin);
	}
	
	AlignedBox boundingBox() const {
		return m_Target.boundingBox();
	}
	
	//
	// Object is client only (not networked) so just do nothing stuff
	//
	void serialize(ISerializer ser, bool fullSerialization) {}
	void resetChangedFlags() {}
	
	void postSpawn() {}
	void onDeleteRequest() {}
	override void toggleCollMode() {}
	override IEvent constructEvent(EventId id, IAllocator allocator) { return null; }
}
