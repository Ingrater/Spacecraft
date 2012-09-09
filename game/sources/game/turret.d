module game.turret;

import thBase.serialize.xmldeserializer;
import game.gameobject, game.objectfactory;
import std.random;
import game.projectiles;


class Turret(ProjectileClass) {
	
	private {
		struct params {
			// Cooldown of the turret in ms
			XmlValue!float cooldown;
			// Spread radius of the MG in degree
			XmlValue!float spreadRadius;
			// Velocity of a bullet in meters per second
			XmlValue!float bulletVelocity;
			// Damage of one bullet
			XmlValue!float damage;
			// Lifetime of a bullet
			XmlValue!float timeToLife;
			// Rotation of the barrels relative to the orientation of the parrent
			Quaternion barrelDirection;
			// Barrel offsets to the turret position
			vec3[] barrels;
			// Size of the muzzle flash of the turret
			vec2 muzzleFlashSize;
		}
		
		params m_Params;
		
		// Status of the turret (if true new projectiles will be spawned)
		bool m_Fireing = false;
		// Usage tracker for the turret. Will be increased by the cooldown on each
		// shot and decreases with time. Necessary to establish a proper fireing
		// rate.
		float m_Usage = 0;
		float m_InitialUsageFactor = 0;
		size_t m_BarrelIndex = 0;
		mat4 m_BarrelRotation;
		vec3 m_LastFiredBarrel;
		IGameObject m_Target;
		
		GameObject m_Parent;
	}
	
	this(GameObject parent, rcstring settings, float initialUsageFactor = 0.0){
		FromXmlFile(m_Params, settings);
		m_BarrelRotation = m_Params.barrelDirection.toMat4();
		m_Parent = parent;
		m_InitialUsageFactor = initialUsageFactor;
		m_LastFiredBarrel = vec3(0, 0, 0);
	}

  ~this()
  {
    Delete(m_Params.barrels);
  }
	
	/**
	 * Updates the turres and spawns projectiles if the turret usage is low
	 * enough and firing is allowed. Returns the number of fired projectiles.
	 */
	uint update(float timeDiff, bool allowFire = true){
		uint firedProjectiles = 0;
		
		if (m_Fireing && allowFire){
			auto rotationMatrix = ( m_BarrelRotation * m_Parent.transformation(Position(vec3(0, 0, 0))) ).f;
			vec3 axis[3];
			axis[0] = vec3(rotationMatrix[0], rotationMatrix[1], rotationMatrix[2]);
			axis[1] = vec3(rotationMatrix[4], rotationMatrix[5], rotationMatrix[6]);
			axis[2] = vec3(rotationMatrix[8], rotationMatrix[9], rotationMatrix[10]);
			
			//auto axis = m_Parent.orientation;
			auto factory = cast(GameObjectFactory) m_Parent.game.factory;
			
			while(m_Usage <= 0){
				auto offset = m_Params.barrels[m_BarrelIndex];
				m_LastFiredBarrel = offset;
				/+
				vec3 offset = axis[0] * barrel.x;
				offset += axis[1] * barrel.y;
				offset += axis[2] * barrel.z;
				+/
				m_BarrelIndex = (m_BarrelIndex + 1) % m_Params.barrels.length;
				
				// Find two angles that are within the spread radius of the MG and build
				// a rotation for it.
				float rot_x, rot_y;
				float distance_square = float.max, spreadRadius = m_Params.spreadRadius.value;
				while(distance_square > spreadRadius * spreadRadius){
					rot_x = uniform(-spreadRadius, spreadRadius);
					rot_y = uniform(-spreadRadius, spreadRadius);
					distance_square = rot_x * rot_x + rot_y * rot_y;
				}
				auto spread_rot = Quaternion(axis[0], rot_x) * Quaternion(axis[1], rot_y);
				
				// Calculate the velocity of the new projectile
				auto vel_to_view_proj = m_Parent.velocity.normalize.dot(axis[2].normalize);
				auto vel = axis[2] * (m_Params.bulletVelocity.value + vel_to_view_proj * m_Parent.velocity.length);
				vel = spread_rot.toMat4() * vel;
				
				// Spawn it and give the target hell
				auto toWorldTrans = m_Parent.transformation( Position(vec3(0, 0, 0)) );
				auto projectile = new ProjectileClass(m_Parent, m_Target, m_Params.damage.value, m_Params.timeToLife.value, factory.nextEntityId(), m_Parent.game,
					Position(toWorldTrans * offset), m_Parent.rotation * spread_rot, vel);
				factory.SpawnGameObject(projectile);
				
				m_Usage += m_Params.cooldown.value;
				firedProjectiles++;
			}
		}
		
		if (m_Usage > 0)
			m_Usage -= timeDiff;
		else if (m_Usage < 0)
			m_Usage = 0;
		
		return firedProjectiles;
	}
	
	void fire(bool activate, IGameObject target = null){
		// If the turret starts fireing apply the initial usage factor
		if (m_Fireing == false && activate)
			m_Usage = m_Params.cooldown.value * m_InitialUsageFactor;
		m_Fireing = activate;
		m_Target = target;
	}
	
	void increaseUsage(float usage){
		m_Usage += usage;
	}
	
	float bulletVelocity() const {
		return m_Params.bulletVelocity.value;
	}
	
	vec3 lastFiredBarrel() const {
		return m_LastFiredBarrel;
	}
	
	vec2 muzzleFlashSize() const {
		return m_Params.muzzleFlashSize;
	}
}
