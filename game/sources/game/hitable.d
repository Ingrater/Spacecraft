module game.hitable;

import game.gameobject, game.rules.base, game.projectiles, game.game;
public import game.rules.base;

abstract class HitableGameObject : GameObject, IHitable {
	
	//
	// Stuff important on both, client and server
	//
	
	protected {
		netvar!float m_FullHitpoints;
		netvar!float m_FullShieldStrength;
		netvar!float m_ShieldRechargeRate; // charge regenerated per second
		
		netvar!float m_Hitpoints;
		netvar!float m_ShieldStrength;
		netvar!bool m_Dead;
		netvar!byte m_Team;
	}
	
	override EntityId entityId() const {
		return super.entityId();
	}
	
	override mat4 transformation(Position origin) const {
		return super.transformation(origin);
	}
	
	override bool isDead() {
		return m_Dead;
	}
	
	override byte team(){
		return m_Team;
	}
	
	void team(byte newTeam){
		m_Team = newTeam;
	}
	
	override byte threatLevel(){
		return 1;
	}
	
	
	//
	// Server side stuff
	//
	
	protected {
		HitableGameObject m_LastHitBy;
	}
	
	/**
	 * Server side constructor
	 */
	this(EntityId entityId, GameSimulation game, Position pos, Quaternion rot, CollisionHull col, vec3 scale, float hitpoints, float shieldStrength, float shieldRecharge, byte team){
		m_FullHitpoints = hitpoints;
		m_FullShieldStrength = shieldStrength;
		m_ShieldRechargeRate = shieldRecharge;
		
		m_Hitpoints = m_FullHitpoints;
		m_ShieldStrength = m_FullShieldStrength;
		m_Dead = false;
		m_Team = team;
		
		super(entityId, game, pos, rot, col, scale);
	}
	
	override void updateOnServer(float timeDiff){
		super.updateOnServer(timeDiff);
		updateHitable(timeDiff);
	}
	
	protected void updateHitable(float timeDiff){
		if (hitpoints <= 0 && !m_Dead) {
			// If the object died trigger the corresponding callbacks
			this.killedBy(m_LastHitBy);
			if (m_LastHitBy)
				m_LastHitBy.killedOne(this);
			m_Dead = true;
		} else if(!m_Dead) {
			// Otherwise slowly recharge the shield until it is full
			if (m_ShieldStrength.value < m_FullShieldStrength.value){
				float dt_sec = timeDiff / 1_000;
				m_ShieldStrength = m_ShieldStrength + m_ShieldRechargeRate * dt_sec;
				if (m_ShieldStrength.value > m_FullShieldStrength.value)
					m_ShieldStrength = m_FullShieldStrength;
			}
		}
	}
	
	override bool hit(float damage, IGameObject other = null){
		auto projectile = cast(MgProjectile) other;
		if (projectile){
			auto hitable = cast(HitableGameObject) projectile.owner;
			// 0 is free for all team
			if (hitable && hitable.team == this.team && hitable.team != 0)
				return false;
			else
				m_LastHitBy = hitable;
		}
		
		if (m_ShieldStrength.value >= damage) {
			m_ShieldStrength = m_ShieldStrength - damage;
			return false;
		}
		
		auto impactDamage = damage - m_ShieldStrength;
		m_ShieldStrength = 0;
		m_Hitpoints = m_Hitpoints - impactDamage;
		return true;
	}
	
	override float hitpoints()          { return m_Hitpoints; }
	override float fullHitpoints()      { return m_FullHitpoints; }
	override float shieldStrength()     { return m_ShieldStrength; }
	override float fullShieldStrength() { return m_FullShieldStrength; }
	override float temperature()        { return 0; }
	override float fullTemperature()    { return 100; }
	
	void killedBy(HitableGameObject killer){
	}
	void killedOne(HitableGameObject other){
	}
	
	
	//
	// Client side game object code
	//
	
	this(EntityId entityId, GameSimulation game, AlignedBox boundingBox, CollisionHull col){
		super(entityId, game, boundingBox, col);
	}
	
	AlignedBox originalBoundingBox(){
		return m_OriginalBoundingBox;
	}
}
