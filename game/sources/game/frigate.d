module game.frigate;

import game.gameobject, game.rules.base, base.all, base.renderer;
import game.effects.bigexplosion, game.objectfactory, game.turret;
import game.effects.muzzleflash;
static import client.resources, server.resources;
import std.math;
import thBase.container.vector;
import game.game;

class Frigate : HitableGameObject, ISerializeable {
	
	private {
		float m_MovementSpeed = 1;
		float m_RotationSpeed = 15;
	}
	
	// Stuff for network integration
	mixin MakeSerializeable;
	
	//
	// Server side game object code
	//
	
	private {
		// This flag is checked by all children of the frigate (its turrets). If the
		// frigate is dead the children should die as well.
		bool m_Dead = false;
	}
	
	/**
	 * Server side constructor
	 */
	this(EntityId entityId, GameSimulation game, byte team, Position pos, Quaternion rot, vec3 scale = vec3(2, 2, 2)){
		super(entityId, game, pos, rot, server.resources.col(_T("frigate")), scale, 10_000, 10_000, 250, team);
		InitMessaging();
		m_Game.rules.registerHitable(this);
	}
	
	private class ServerMsgs {
	}
	
	override void updateOnServer(float timeDiff){
		super.updateOnServer(timeDiff);
		if (m_Hitpoints.value <= 0){
			m_Game.factory.removeGameObject(this);
			m_Dead = true;
		}
	}
	
	/**
	 * This makes the frigate more dangerous than the figters. So the heavy
	 * turrets will attack other frigates first.
	 */
	override byte threatLevel(){
		return 2;
	}
	
	
	//
	// Client side game object code
	//
	
	private {
		bool m_CollMode = false;
	}
	
	/**
	 * Client side constructor. Called when the game object factory creates this
	 * game object as requested by the server. This takes place before the data
	 * for this game object arives. Therefore you can only set attributes but the
	 * netvars will not be set to their proper server values yet.
	 */
	this(EntityId entityId, GameSimulation game){
		auto res = client.resources.model(_T("frigate"));
		m_RenderProxy = res.proxy;
		super(entityId, game, res.boundingBox, null);
		InitMessaging();
	}

  ~this()
  {
  }
	
	override void postSpawn(){
		super.postSpawn();
		m_Game.rules.registerHitable(this);
	}
	
	override void onDeleteRequest(){
		m_Game.rules.removeHitable(this);
		super.onDeleteRequest();
	}
	
	private class ClientMsgs {
		// Nothing needed right now
	}
	
	rcstring name(){
		return _T("Frigate");
	}
	
	override void toggleCollMode(){
		m_CollMode = !m_CollMode;
		m_RenderProxy = client.resources.model( m_CollMode ? _T("frigate_coll") : _T("frigate") ).proxy;
	}
	
	override void killedBy(HitableGameObject killer){
		auto bigExplosion = new BigExplosion(m_Game.factory.nextEntityId(),m_Game,this.position,this.orientation[1],3.0f);
		(cast(GameObjectFactory)m_Game.factory()).SpawnGameObject(bigExplosion);
	}
	
	mixin MessageCode;
}


class TurretBase(ProjectileClass) : HitableGameObject, ISerializeable {
	
	// Stuff for network integration
	mixin MakeSerializeable;
	mixin DummyMessageCode;
	
	private {
		netvar!EntityId m_FrigateId;
		Frigate m_Frigate;
	
		netvar!rcstring m_Resource;
		netvar!rcstring m_Name;
	
		float m_TargetMinDist = 20;
		float m_TargetMaxDist = 2_000;
		float m_TargetMaxCannonAngle = PI; //PI / 2;
		// Rotation velocities of turrets in degree per second
		float m_TurretBaseRotVelocity = 10;
		float m_TurretCannonRotVelocity = 15;
		// Treshold at which turrets start to fire (in degree)
		float m_TurretFiringThreshold = 5;
		
		float m_ExplosionScale = 1;
		// The threat level of preferred enimies
		byte m_PreferredThreatLevel = 0;
		
		Vector!(TurretCannon!ProjectileClass) m_Cannons;
		vec3 m_MountCenter;
		// The cannons use this variable to pick up their rotation
		netvar!float m_CannonAngleDeg;
	}

	override const(IGameObject) father() const {
		return m_Frigate;
	}

	override Position position() const {
		// m_Frigate is null between the client constructor and the call to the
		// post spawn method. Need to work in that state too in case the extractor
		// tries to render the stuff.
		if (m_Frigate) {
			auto toGlobalTrans = m_Frigate.transformation(Position(vec3(0, 0, 0)));
			return Position(toGlobalTrans * m_Position.toVec3());
		} else {
			return m_Position.value;
		}
	}

	override Quaternion rotation() const {
		return (m_Frigate is null) ? m_Rotation.value : m_Frigate.m_Rotation.value * m_Rotation.value;
	}

	void addCannon(TurretCannon!ProjectileClass cannon){
		m_Cannons ~= cannon;
		m_MountCenter = vec3(0, 0, 0);
		foreach(c; m_Cannons)
    {
			m_MountCenter = m_MountCenter + c.m_Position.toVec3() / m_Cannons.length;
    }
	}


	//
	// Server side game object code
	//

	private {
		bool m_Dead = false;
	}

	/**
	 * Server side constructor
	 */
	this(Frigate ship, Position pos, Quaternion rot, rcstring name, rcstring resourceName,
		float maxCannonAngle, float explosionScale, byte preferredThreatLevel, float range,
		float hitpoints, float shieldStrength, float shieldRecharge)
	{
    m_Cannons = New!(typeof(m_Cannons))();
		m_Frigate = ship;
		m_FrigateId = ship.entityId;
	
		m_Resource = resourceName;
		m_Name = name;
		m_CannonAngleDeg = 0;
		m_TargetMaxCannonAngle = maxCannonAngle;
		m_ExplosionScale = explosionScale;
		m_PreferredThreatLevel = preferredThreatLevel;
		m_TargetMaxDist = range;
		
		super(ship.m_Game.factory.nextEntityId(), ship.m_Game, pos, rot, server.resources.col(resourceName),
			vec3(1, 1, 1), hitpoints, shieldStrength, shieldRecharge, ship.team);
		m_Game.rules.registerHitable(this);
	}

  ~this()
  {
    Delete(m_Cannons);
  }

	override void updateOnServer(float timeDiff){
		super.updateOnServer(timeDiff);
	
		if (m_Hitpoints.value <= 0 || m_Frigate.m_Dead){
			m_Dead = true;
			m_Game.factory.removeGameObject(this);
		}
		
		updateAiming(timeDiff);
	}

	private void updateAiming(float timeDiff){
		auto toParentTrans = this.transformation(Position(vec3(0,0,0)));
		auto toLocalTrans = toParentTrans.Inverse();
		
		// First look in all hitables for the closest target within the target min
		// and max distance and within the base and cannon angle contraints.
		float selectedDistance = float.max, selectedPlaneAngle = float.nan, selectedCannonAngle = float.nan;
		IGameObject selectedEntity;
		vec3 selectedTargetVector;
		byte selectedThreadLevel = byte.min;
		
		foreach(hitable; m_Game.rules.hitables){
			// Only attack hitables from other teams. If this object is in a NPC team
			// (team < 0) then only attack other NPC teams.
			if (hitable !is this && hitable.team != this.team && (this.team >= 0 || hitable.team < 0)){
				auto mountToTarget4 = toLocalTrans * vec4(hitable.position.toVec3()) - vec4(m_MountCenter);
				vec3 mountToTarget = vec3(mountToTarget4.f[0..3]);
				
				float planeAngle = atan2(mountToTarget.x, -mountToTarget.z);
				float planeDist = vec2(mountToTarget.x, mountToTarget.z).length;
				float cannonAngle = atan2(mountToTarget.y, planeDist);
				// If we are over the center of the turret and therefore behind it use
				// the angle from the negative X axis (the plane behind the turret) to
				// calculate the aiming. This avoids the turret to lose targets behind
				// it and avoids funny orientations of the cannons.
				if (cannonAngle > PI_2){
					cannonAngle = PI - cannonAngle;
					//logInfo("turret: cannon angle fixed to %s", cannonAngle);
				}
				
				if (mountToTarget.y > 0 && cannonAngle < m_TargetMaxCannonAngle){
					//logInfo("turret %s: to target %s: %9s, plane angle: %.2f PI, cannonAngle: %.2f PI",
					//	this.entityId, hitable.entityId, mountToTarget.f, planeAngle / PI, cannonAngle / PI);
					auto distance = mountToTarget.length;
					bool betterTarget = false;
					
					if (distance >= m_TargetMinDist && distance <= m_TargetMaxDist){
						// Target is in range
						if (hitable.threatLevel == m_PreferredThreatLevel) {
							// We found a preferred target
							if (selectedThreadLevel == m_PreferredThreatLevel) {
								// We already had a preferred target selected so take the
								// nearest of the two
								betterTarget = (distance < selectedDistance);
							} else {
								// The previous target was not preferred so take this regardless
								// of the distance
								betterTarget = true;
							}
						} else {
							// We found a normal target
							if (selectedThreadLevel == m_PreferredThreatLevel) {
								// We already have a preferred selected so don't take the new one
								betterTarget = false;
							} else {
								// We have no selected target or a normal one. Take the nearest.
								betterTarget = (distance < selectedDistance);
							}
						}
					}
					
					if (betterTarget){
						selectedDistance = distance;
						selectedEntity = hitable;
						selectedTargetVector = mountToTarget;
						selectedPlaneAngle = planeAngle;
						selectedCannonAngle = cannonAngle;
						selectedThreadLevel = hitable.threatLevel;
					}
				}
			}
		}
	
		if (selectedEntity){
			// If the turret found a target, get it!
			//logInfo("turret %s: to target %s: %9s, plane angle: %.2f PI, cannonAngle: %.2f PI",
			//	this.entityId, selectedEntity.entityId, selectedTargetVector.f, selectedPlaneAngle / PI, selectedCannonAngle / PI);
		
			bool fire = rotateTo(selectedPlaneAngle, selectedCannonAngle, timeDiff);
			foreach(c; m_Cannons)
				c.fire(fire, selectedEntity);
		} else {
			foreach(c; m_Cannons)
				c.fire(false);
		}
	}

	/**
	 * Does a rotation step to the specified angles. Returns true if the cannons
	 * are within the firing threshold, false otherwise.
	 */
	bool rotateTo(float baseAngle, float cannonAngle, float timeDiff){
		float dt_sec = timeDiff / 1_000;
		float angle, baseRest, cannonRest;
	
		baseAngle = baseAngle  / PI * 180;
		cannonAngle = cannonAngle / PI * 180;
	
		if (abs(baseAngle) < m_TurretBaseRotVelocity) {
			angle = baseAngle;
			baseRest = 0;
		} else {
			angle = copysign(m_TurretBaseRotVelocity, baseAngle);
			baseRest = abs(baseAngle) - m_TurretBaseRotVelocity;
		}
		
		// Workaround because the orientation method does not respect the rotation
		// of the frigate. No idea why.
		auto toGlobalTrans = (m_Frigate.m_Rotation * this.m_Rotation).toMat4();
		auto upVector = toGlobalTrans * vec3(0, 1, 0);
		//auto axis = orientation();
		rotate(upVector, angle * dt_sec);
	
		float angleDiff = cannonAngle - m_CannonAngleDeg.value;
		if (abs(angleDiff) < m_TurretCannonRotVelocity) {
			angle = angleDiff;
			cannonRest = 0;
		} else {
			angle = copysign(m_TurretCannonRotVelocity, angleDiff);
			cannonRest = abs(angleDiff) - m_TurretCannonRotVelocity;
		}
		m_CannonAngleDeg = m_CannonAngleDeg.value + angle * dt_sec;
	
		return (baseRest*baseRest + cannonRest*cannonRest < m_TurretFiringThreshold*m_TurretFiringThreshold);
	}


	//
	// Client side game object code
	//

	private {
		bool m_CollMode = false;
	}

	/**
	 * Client side constructor. Called when the game object factory creates this
	 * game object as requested by the server. This takes place before the data
	 * for this game object arives. Therefore you can only set attributes but the
	 * netvars will not be set to their proper server values yet.
	 */
	this(EntityId entityId, GameSimulation game){
    m_Cannons = New!(typeof(m_Cannons))();
		auto res = client.resources.model(_T("nothing"));
		m_RenderProxy = res.proxy;
		super(entityId, game, res.boundingBox, null);
	}

	override void postSpawn(){
		m_Frigate = cast(Frigate) m_Game.factory.getGameObject(m_FrigateId);
		assert(m_Frigate !is null, "game: Received a turret base that was attached to something else then a frigate!");
	
		auto res = client.resources.model(m_Resource);
		m_RenderProxy = res.proxy;
		m_OriginalBoundingBox = res.boundingBox;
		super.postSpawn();
	
		m_Game.rules.registerHitable(this);
	}

	override void onDeleteRequest(){
		m_Game.rules.removeHitable(this);
		super.onDeleteRequest();
	}

	rcstring name(){
		return m_Name;
	}

	override void toggleCollMode(){
		m_CollMode = !m_CollMode;
		m_RenderProxy = client.resources.model( m_CollMode ? m_Resource.value ~ "_coll" : m_Resource.value ).proxy;
	}

	float cannonAngleDeg() const {
		return m_CannonAngleDeg;
	}

	override void killedBy(HitableGameObject killer){
		Position pos = vec3(this.transformation(Position(vec3(0,0,0))) * vec4(0.0f,0.0f,0.0f,1.0f));
		vec3 offset = vec3(m_Frigate.rotation().toMat4() * this.rotation.toMat4() * vec4(0.0f,30.0f,0.0f,1.0f));
		pos = pos + offset;
		auto bigExplosion = new BigExplosion(m_Game.factory.nextEntityId(), m_Game, pos, this.orientation[1], m_ExplosionScale);
		(cast(GameObjectFactory)m_Game.factory()).SpawnGameObject(bigExplosion);
	}

}


class TurretCannon(ProjectileClass) : GameObject, ISerializeable, IHitable {

	// Stuff for network integration
	mixin MakeSerializeable;

	private {
		netvar!EntityId m_BaseId;
		TurretBase!ProjectileClass m_Base;
		Turret!ProjectileClass m_Turret;
		
		netvar!rcstring m_Resource;
	}

	override EntityId entityId() const {
		return super.entityId();
	}

	override const(IGameObject) father() const {
		return m_Base;
	}

	override bool isDead() {
		return m_Base.isDead();
	}
	
	override byte team() {
		return m_Base.team;
	}

	override Position position() const {
		// m_Frigate is null between the client constructor and the call to the
		// post spawn method. Need to work anyway in case the extractor tries to
		// render the stuff.
		return (m_Base is null) ? m_Position.value : m_Base.position + m_Position;
	}

	override Quaternion rotation() const {
		//logInfo("cannon angle: %s", m_Base.m_CannonAngleDeg.value);
		if (m_Base)
			return m_Rotation.value * Quaternion(vec3(1, 0, 0), -m_Base.cannonAngleDeg());
		else
			return m_Rotation.value;
	}

	override mat4 transformation(Position origin) const {
		return super.transformation(origin);
	}


	//
	// Server side game object code
	//
	
	class ServerMsgs {
	}
	
	/**
	 * Server side constructor
	 */
	this(TurretBase!ProjectileClass base, Position pos, Quaternion rot, rcstring resourceName, rcstring turretConfig, float initUsageFactor){
		m_Base = base;
		m_BaseId = base.entityId();
		m_Turret = New!(Turret!ProjectileClass)(this, turretConfig, initUsageFactor);
		
		m_Resource = resourceName;
		super(base.m_Game.factory.nextEntityId(), base.m_Game, pos, rot, server.resources.col(resourceName));
		
		m_Base.addCannon(this);
		InitMessaging();
	}

  ~this()
  {
    Delete(m_Turret);
  }

	override bool hit(float damage, IGameObject other = null){
		return m_Base.hit(damage, other);
	}

	override float hitpoints()          { return m_Base.hitpoints; }
	override float fullHitpoints()      { return m_Base.fullHitpoints; }
	override float shieldStrength()     { return m_Base.shieldStrength; }
	override float fullShieldStrength() { return m_Base.fullShieldStrength; }
	override float temperature()        { return 0; }
	override float fullTemperature()    { return 100; }

	override void updateOnServer(float timeDiff){
		super.updateOnServer(timeDiff);
		if(m_Turret.update(timeDiff) > 0){ //did the turret fire?
			toClient.onFire(m_Turret.lastFiredBarrel, m_Turret.muzzleFlashSize, EventType.postSync);
		}
		if (m_Base.m_Dead || m_Base.m_Frigate.m_Dead)
			m_Game.factory.removeGameObject(this);
	}
	
	override byte threatLevel(){
		return 1;
	}
	
	
	//
	// Client side game object code
	//

	private {
		bool m_CollMode = false;
	}
	
	class ClientMsgs {
		void onFire(vec3 offset, vec2 muzzleFlashSize){
			auto muzzleFlash = New!MuzzleFlash(this.outer, offset, m_Game, muzzleFlashSize).ptr;
			m_Game.octree.insert(muzzleFlash);
		}
	}

	/**
	 * Client side constructor. Called when the game object factory creates this
	 * game object as requested by the server. This takes place before the data
	 * for this game object arives. Therefore you can only set attributes but the
	 * netvars will not be set to their proper server values yet.
	 */
	this(EntityId entityId, GameSimulation game){
		auto res = client.resources.model(_T("nothing"));
		m_RenderProxy = res.proxy;
		super(entityId, game, res.boundingBox, null);
		InitMessaging();
	}

	override void postSpawn(){
		m_Base = cast(TurretBase!ProjectileClass) m_Game.factory.getGameObject(m_BaseId);
		assert(m_Base !is null, "game: Received a heavy turret cannon that was attached to something else then a base!");
	
		auto res = client.resources.model(m_Resource);
		m_RenderProxy = res.proxy;
		m_OriginalBoundingBox = res.boundingBox;
		super.postSpawn();
	}

	rcstring name(){
		return m_Base.name;
	}

	AlignedBox originalBoundingBox(){
		return m_Base.originalBoundingBox();
	}

	override void toggleCollMode(){
		m_CollMode = !m_CollMode;
		m_RenderProxy = client.resources.model( m_CollMode ? m_Resource.value ~ "_coll" : m_Resource.value ).proxy;
	}
	
	void fire(bool enable, IGameObject target = null){
		m_Turret.fire(enable, target);
	}
	
	mixin MessageCode;
}
