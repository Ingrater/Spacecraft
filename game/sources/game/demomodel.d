module game.demomodel;

import base.all, base.gameobject, base.net, base.game;
import thBase.logging;


/**
 * Client only game object for the model viewer. It's not network aware and just
 * shows a render proxy at a given position.
 */
class DemoModel : IGameObject {
	
	private {
		EntityId m_EntityId;
		Position m_Position;
		Quaternion m_Rotation;
		AlignedBox m_BoundingBox;
		SmartPtr!IRenderProxy m_RenderProxy;
	}
	
	/**
	 * Constructs the demo model and creates an internal render proxy for it.
	 * 
	 * NOTE: Default argument values for `pos` and `rot` did not work (the model
	 * was not drawn). So do not do that again.
	 */
	this(EntityId entityId, shared(ISubModel) model, Position pos, Quaternion rot){
		m_EntityId = entityId;
		m_Position = pos;
		m_Rotation = rot;
		
		vec3 minBounds, maxBounds;
		model.FindMinMax(minBounds, maxBounds);
		logInfo("min bounds %f %f %f\nmax bounds %f %f %f\nsize %f %f %f",
						 minBounds.x,minBounds.y,minBounds.z,
						 maxBounds.x,maxBounds.y,maxBounds.z,
						 maxBounds.x-minBounds.x,maxBounds.y-minBounds.y,maxBounds.z-minBounds.z);
		m_BoundingBox = AlignedBox(minBounds, maxBounds);
		m_RenderProxy = g_Env.renderer.CreateRenderProxy(model);
	}
	
	override bool syncOverNetwork() const {
		return false;
	}
	
	override EntityId entityId() const {
		return m_EntityId;
	}
	
	override Position position() const {
		return m_Position;
	}
	
	override void position(Position pos){
	}
	
	override Quaternion rotation() const {
		return m_Rotation;
	}
	
	override mat4 transformation(Position origin) const {
		return TranslationMatrix(m_Position - origin);
	}
	
	override IGameObject father() const {
		return null;
	}
	
	bool hasMoved() {
		return false;
	}
	
	AlignedBox boundingBox() const {
		return m_BoundingBox;
	}
	
	IRenderProxy renderProxy() {
		return m_RenderProxy;
	}
	
	override IEvent constructEvent(EventId id, IAllocator allocator){
		return null;
	}
	
	void update(float timeDiff){ }
	void postSpawn(){ }
	void onDeleteRequest(){ }
	void toggleCollMode(){ }
	void serialize(ISerializer ser, bool fullSerialization){ }
	void resetChangedFlags(){ }
	
	override rcstring inspect(){
		return format("<%s id: %d pos: (cell: %s, pos: %s), rot: (axis: %s, %s, %s, angle: %s)>",
			this.classinfo.name, m_EntityId, m_Position.cell.f, m_Position.relPos.f,
			m_Rotation.x, m_Rotation.y, m_Rotation.z, m_Rotation.angle);
	}
	
	override void debugDraw(shared(IRenderer) renderer){
		// Nothing to do right now
	}
}
