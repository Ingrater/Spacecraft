module game.player;

import game.gameobject, game.game, base.all, base.renderer, game.multiproxy;
import game.projectiles, game.objectfactory;
import game.effects.enginetrail, game.effects.dirtcloud, game.effects.bigexplosion;
import game.scheibe, game.turret;
static import base.logger, client.resources, server.resources;
import std.math, std.random;

/**
 * Object for the player ship.
 * 
 * Special considerations:
 * - acceleration vector is not in world space but in object space (to simulate
 *   thrusters attached to the ship).
 */
class Player : HitableGameObject, ISerializeable, IControllable {	
	
	//
	// Stuff important on both, client and server
	//
	
	private {
		netvar!uint m_ClientId;
		netvar!rcstring m_Name;
		netvar!uint m_Kills, m_Deaths;
		
		/+
		// Up vector of the artifical horizon. The horizon is used for the
		// horizontal mouse rotation.
		netvar!vec3 m_HorizonUp;
		+/
		
		netvar!vec3 m_RotAcceleration;
		
		netvar!float m_Temperature;
		const float m_TemperatureCost = 1.5;
		const float m_TemperatureMax = 100;
		const float m_TemperatureCooldown = 15;
		// Timeout applied to the MG usage when the MG overheats (timeout in ms)
		const float m_TemperatureUsageOverheat = 2 * 1_000;
	}
	
	uint clientId() const {
		return m_ClientId;
	}
	
	override rcstring inspect(){
    auto thisInfo = format("clientId: %d", clientId());
		return buildInspect(thisInfo[]);
	}
	
	override vec3 velocity() const {
		return m_Velocity.value * m_BoostFactor.value;
	}
	
	override 	void velocity(vec3 vel){
		m_Velocity = vel;
	}
	
	
	//
	// Server side game object code
	//
	
	// Stuff only kept on the server
	private {
		// Rotation accleration in degree per second sqare
		const float m_RotationThrust = 15;
		// Factor by which the rotation velocity is reduced in percent per second
		// (1 is 100%)
		const float m_RotationDampening = 4.00;
		// Movement aceleration in meters per second sqare
		const float m_MovementAcl = 30;
		// If the player is not accelerating he will slowly break with this
		// deceleration (meter per second sqare)
		const float m_BreakAcl = 10;
		
		// The amount of drift velocity that is removed on each cycle. Drift
		// velocity is the velocity not aiming into the acceleration direction.
		const float m_DriftDampening = 0.5;
		
		Turret!(MgProjectile) m_Turret;
		// Used by the HUD to calculate the aiming help
		netvar!float m_WeaponVelocity;
		
		netvar!float m_BoostFactor;
		const float m_BoostFull = 4.0;
		// Linear dropoff in units per second
		const float m_BoostDropoff = 0.5;
		
		netvar!float m_BoostUsage;
		const float m_BoostCooldown = 20 * 1_000;
	}
	
	/**
	 * Server side constructor
	 */
	this(EntityId entityId, GameSimulation game, uint clientId, byte team, Position pos, Quaternion rot){
		/+m_HorizonUp = vec3(0, 1, 0);+/
		m_RotAcceleration = vec3(0, 0, 0);
		
		m_ClientId = clientId;
		m_Kills = 0;
		m_Deaths = 0;
		m_Name = _T("Nobody");
		m_Temperature = 0;
		m_BoostFactor = 1.0;
		m_BoostUsage = 0;
		m_Turret = new Turret!MgProjectile(this, _T("models/fighter_turret.xml"));
		m_WeaponVelocity = m_Turret.bulletVelocity;
		
		super(entityId, game, pos, rot, server.resources.col(_T("fighter")), vec3(0.5, 0.5, 0.5), 100, 100, 15, team);
		InitMessaging();
		
		m_Game.rules.registerHitable(this);
		m_Game.rules.onPlayerJoin(this);
	}
	
	private class ServerMsgs {
		void look(float screenDeltaX, float screenDeltaY){
			/+
			vec3[3] axis = orientation();
			
			// Project the view vector onto the horizon view vector to figure out if
			// the player flipped (did a looping)
			vec3 horizonRight = axis[0];
			vec3 horizonLook = m_HorizonUp.cross(horizonRight);
			float proj = axis[2].dot(horizonLook);
			
			// If the player is not flipped handle horizontal movement normally,
			// otherwise invert it (moving the mouse left will move left then).
			if (proj >= 0)
				m_RotVelocity.y += screenDeltaX;
			else
				m_RotVelocity.y -= screenDeltaX;
			m_RotVelocity.x += screenDeltaY;
			
			// Rotate the horizon if the player manually rotates the ship
			auto rotated_mouse_up = Quaternion(axis[0], -screenDeltaY).toMat4() * vec4(m_HorizonUp);
			m_HorizonUp = vec3(rotated_mouse_up.f[0..3]);
			+/
			
			m_RotVelocity.y += screenDeltaX;
			m_RotVelocity.x += screenDeltaY;
			
			//rotate(axis[0], screenDeltaY);
			//rotate(m_HorizonUp, screenDeltaX);
		}
		
		void moveForward(bool pressed){
			auto dir = vec3(0, 0, -1) * m_MovementAcl;
			m_Acceleration += (pressed) ? dir : -dir;
		}
		void moveBackward(bool pressed){
			auto dir = vec3(0, 0, 1) * m_MovementAcl;
			m_Acceleration += (pressed) ? dir : -dir;
		}
		void moveRight(bool pressed){
			auto dir = vec3(1, 0, 0) * m_MovementAcl;
			m_Acceleration += (pressed) ? dir : -dir;
		}
		void moveLeft(bool pressed){
			auto dir = vec3(-1, 0, 0) * m_MovementAcl;
			m_Acceleration += (pressed) ? dir : -dir;
		}
		void moveUp(bool pressed){
			auto dir = vec3(0, 1, 0) * m_MovementAcl;
			m_Acceleration += (pressed) ? dir : -dir;
		}
		void moveDown(bool pressed){
			auto dir = vec3(0, -1, 0) * m_MovementAcl;
			m_Acceleration += (pressed) ? dir : -dir;
		}
		
		void rotateRight(bool pressed){
			m_RotAcceleration.z -= (pressed) ? m_RotationThrust : -m_RotationThrust;
		}
		void rotateLeft(bool pressed){
			m_RotAcceleration.z += (pressed) ? m_RotationThrust : -m_RotationThrust;
		}
		
		void fire(ubyte weapon, bool pressed){
			m_Turret.fire(pressed);
		}
		
		void booster(bool pressed){
			if (pressed && m_BoostUsage.value <= 0){
				m_BoostFactor = m_BoostFull;
				m_BoostUsage = m_BoostCooldown;
			}
		}
		
		void setName(rcstring name){
			m_Name = name;
		}
	}
	
	/**
	 * Acceleration vector is in object space to simulate typical space
	 * thrusters which are attached to a ship. If the ship rotates the
	 * acceleration of the thrusters also change direction.
	 */
	override void updateOnServer(float timeDiff){
		auto dt_sec = timeDiff / 1_000;
		
		//auto start = Zeitpunkt(g_Env.mainTimer);
		mat4 own_transform = this.transformation(Position(vec3(0, 0, 0)));
		
		foreach(hit; m_Game.octree.getObjectsInBox(this.boundingBox)){
			auto other = cast(GameObject) hit;
			//base.logger.info("game: player collision via octree with %s", other.inspect());
			if (other !is null && other !is this && other.collisionHull !is null){
				auto hitable = cast(IHitable)other;
				if(hitable is null || (hitable !is null && !hitable.isDead)){
					mat4 other_transform = other.transformation(Position(vec3(0, 0, 0)));
					//auto intersect_start = Zeitpunkt(g_Env.mainTimer);
					if ( this.m_CollisionHull.intersects(other.collisionHull, own_transform, other_transform) ){
						//base.logger.info("game: player collision with %s", other.inspect());
						// Impact, push the player back and hurt him depending on the speed
						// difference between him and the object. We need to reset the player
						// position to the value before the intersection occured. Otherwise we
						// might get locked into a permanent collision when the new velocity
						// is not enough to pull the player out of the intersection.
						m_Position = m_Position - this.velocity * dt_sec;
						m_Velocity = -this.velocity * 0.5;
						m_Hitpoints = m_Hitpoints - (other.velocity - this.velocity).length * 0.5;
					}
					//auto intersect_duration = Zeitpunkt(g_Env.mainTimer) - intersect_start;
					//base.logger.info("> intersection took %s", intersect_duration);
				}
			}
		}
		
		//auto duration = Zeitpunkt(g_Env.mainTimer) - start;
		//base.logger.info("game: player collision took %s for %d entities", duration, hitcount);
		
		// Current orientation axis of the player: x (right), y (top) and negative z
		// (view vector)
		vec3[3] axis = orientation();
		
		updatePosition(axis, timeDiff);
		
		// Update the bounding box because the position changed
		updateBoundingBox();
		
		// Spawn new projectiles if the MG is currently fireing and the not in
		// cooldown
		auto firedProjectiles = m_Turret.update(timeDiff);
		m_Temperature = m_Temperature + m_TemperatureCost * firedProjectiles;
		if (m_Temperature.value >= m_TemperatureMax)
			m_Turret.increaseUsage(m_TemperatureUsageOverheat);
		
		if (m_Temperature.value > 0){
			m_Temperature = m_Temperature - m_TemperatureCooldown * dt_sec;
			if (m_Temperature.value < 0)
				m_Temperature = 0;
		}
		
		// If the player died notify the game and let it respawn the player
		if (this.hitpoints <= 0 && !m_Dead)
			m_Game.rules.onPlayerDeath(this);
		
		// Let the hitable class handle the trigering of the killed methods and
		// shield recharging.
		updateHitable(timeDiff);
	}
	
	private void updatePosition(vec3[3] axis, float timeDiff){
		if(!m_Dead){
			float dt_sec = timeDiff / 1_000;
			
			// Move forward with acceleration, velocity and position
			if (acceleration.length > float.epsilon) {
				vec3 acl_world = axis[0] * acceleration.x + axis[1] * acceleration.y + axis[2] * acceleration.z;
				auto vel_acl_projection = acl_world.normalize.dot(m_Velocity.normalize);
				auto drift_vel = m_Velocity - acl_world * vel_acl_projection;
				m_Velocity = m_Velocity + acl_world * dt_sec - drift_vel * dt_sec * m_DriftDampening;
			} else {
				float decreasedSpeed = m_Velocity.length - m_BreakAcl * dt_sec;
				if (decreasedSpeed > 0)
					m_Velocity = m_Velocity.normalize() * decreasedSpeed;
				else
					m_Velocity = vec3(0, 0, 0);
			}
			auto boostedVel = m_Velocity * m_BoostFactor;
			// this.velocity applies the boost factor to m_Velocity
			position = position + this.velocity * dt_sec;
			
			// Apply the rotation acceleration. This is used to simulate the rotation
			// thrusters and is important for the rotation keys as well as the joystick
			// controls.
			m_RotVelocity += m_RotAcceleration;
			
			// Rotate around each axis, but use the horizon instead of the real
			// orientation up vector (Y axis).
			rotate(axis[0], m_RotVelocity.x * dt_sec);
			/+rotate(m_HorizonUp, m_RotVelocity.y * dt_sec);+/
			rotate(axis[1], m_RotVelocity.y * dt_sec);
			rotate(axis[2], m_RotVelocity.z * dt_sec);
			
			/+
			// Rotate the horizon if the player manually rotates the ship
			auto rotated_mouse_up = Quaternion(axis[2], m_RotVelocity.z * dt_sec).toMat4() * vec4(m_HorizonUp);
			m_HorizonUp = vec3(rotated_mouse_up.f[0..3]);
			+/
			
			// Damp the rotation velocity so we just get a little drift effect on the
			// rotation
			m_RotVelocity = m_RotVelocity * (1 - m_RotationDampening * dt_sec);
			
			// Count down the boost usage so it can be used again after the cooldown
			if (m_BoostUsage.value > 0){
				m_BoostUsage -= timeDiff;
				if (m_BoostUsage.value < 0)
					m_BoostUsage = 0;
			}
			
			if (m_BoostFactor.value > 1){
				m_BoostFactor = m_BoostFactor - m_BoostDropoff * dt_sec;
				if (m_BoostFactor.value < 1)
					m_BoostFactor = 1;
			}
		}
	}
	
	override void debugDraw(shared(IRenderer) renderer){
		super.debugDraw(renderer);
		
		/+
		// Draw the artifical horizon of the player
		vec3[3] axis = orientation();
		vec3 horizonRight = axis[0];
		vec3 horizonLook = m_HorizonUp.cross(horizonRight);
		
		void drawHorizon(float radius, vec3 centerOffset, vec4 color){
			vec3 point_a, point_b;
			for(float a = -PI; a < PI; a += PI / 6){
				point_b = centerOffset + (horizonRight * cos(a) + horizonLook * sin(a)) * radius;
				if (!isNaN(point_a.x))
					renderer.drawLine(position + point_a, position + point_b, color);
				point_a = point_b;
			}
		}
		
		auto up = m_HorizonUp.normalize;
		drawHorizon(10, vec3(0, 0, 0), vec4(0, 1, 0, 1));
		drawHorizon(7.5, up * 5, vec4(0, 0.75, 0, 1));
		drawHorizon(5, up * 10, vec4(0, 0.75, 0, 1));
		drawHorizon(7.5, up * -5, vec4(0, 0.75, 0, 1));
		drawHorizon(5, up * -10, vec4(0, 0.75, 0, 1));
		+/
	}
	
	/**
	 * Called by the game when a player should be resurected. The game should
	 * coordinate where players respawn, therefore the indirection.
	 */
	void resurect(Position where, Quaternion orientation){
		m_Hitpoints = m_FullHitpoints;
		m_ShieldStrength = m_FullShieldStrength;
		this.position = where;
		m_Velocity = vec3(0, 0, 0);
		m_Rotation = orientation;
		m_Dead = false;
		toClient.setEngineTrail(true,EventType.preSync);
	}
	
	override void killedBy(HitableGameObject killer){
		base.logger.info("player %s: killedBy %s", this.entityId.id, (killer) ? killer.entityId.id : -1);
		m_Deaths = m_Deaths + 1;
		
		//Spawn explosion
		auto bigExplosion = new BigExplosion(m_Game.factory.nextEntityId(),m_Game,this.position,this.orientation[1],0.125f);
		(cast(GameObjectFactory)m_Game.factory()).SpawnGameObject(bigExplosion);
		toClient.setEngineTrail(false,EventType.preSync);
	}
	
	override void killedOne(HitableGameObject other){
		m_Kills = m_Kills + 1;
		base.logger.info("player %s: killedOne %s, kills: %s", this.entityId.id, (other) ? other.entityId.id : -1, m_Kills.value);
		toClient.killedOne(other.entityId, EventType.preSync, clientId);
	}
	
	void resetScore(){
		m_Deaths = 0;
		m_Kills = 0;
	}
	
	uint kills()  { return m_Kills; }
	uint deaths() { return m_Deaths; }
	rcstring name() { return m_Name; }
	override float temperature() { return m_Temperature; }
	override float fullTemperature() { return m_TemperatureMax; }
	float boostUsage() { return m_BoostUsage; }
	float fullBoostUsage() { return m_BoostCooldown; }
	
	/**
	 * Bullet velocity of the currently used weapon. Used by the HUD to calculate
	 * the aiming help.
	 */
	float weaponVelocity() {
		return m_WeaponVelocity;
	}
	
	
	//
	// Client side game object code
	//
	
	// Client only variables
	private {
		bool m_MainThruster = false;
		uint m_ThrustersOn = 0;
		ISoundSource m_ThrusterFront, m_ThrusterLeft, m_ThrusterRight;
		bool m_FirstPerson = true;
		SmartPtr!EngineTrail m_EngineTrail;
		SmartPtr!DirtCloud m_DirtCloud;
		SmartPtr!IRenderProxy m_CockpitProxy, m_FighterProxy;
		Scheibe m_Scheibe;
		IHitable m_Selected;
		
		bool m_CollMode = false;
	}
	
	__gshared SmartPtr!IRenderProxy m_RedProxy;
	
	/**
	 * Client side constructor. Called when the game object factory creates this
	 * game object as requested by the server. This takes place before the data
	 * for this game object arives. Therefore you can only set attributes but the
	 * netvars will not be set to their proper server values yet.
	 */
	this(EntityId entityId, GameSimulation game){
		if(m_RedProxy is null){
			m_RedProxy = New!RedScreen();
		}
		auto fighterRes = client.resources.model(_T("fighter"));
		m_FighterProxy = fighterRes.proxy;
		auto cockpitRes = client.resources.model(_T("cockpit"));
		m_CockpitProxy = cockpitRes.proxy;
		super(entityId, game, fighterRes.boundingBox, null);
		
		m_Name = _T("Nobody");
		m_Temperature = 0;
		m_BoostFactor = 1.0;
		m_BoostUsage = 0;
		m_WeaponVelocity = 0;

    rcstring[3] soundsToLoad;
    soundsToLoad[0] = _T("thruster");
    soundsToLoad[1] = _T("thruster_right");
    soundsToLoad[2] = _T("thruster_left");
		m_Game.loadSounds(soundsToLoad);
		auto right = m_Game.sound(soundsToLoad[2]);
		right.SetRepeat(true);
		right.SetVolume(1);
		right.SetPosition(2, 0, -2);
		auto left = m_Game.sound(soundsToLoad[1]);
		left.SetRepeat(true);
		left.SetVolume(0.5);
		left.SetPosition(-2, 0, -2);
		
		m_ThrusterFront = m_Game.soundSystem.LoadOggSound(_T("sfx/thruster.ogg"));
		m_ThrusterFront.SetPosition(0, 0, 2);
		m_ThrusterFront.SetVolume(4);
		m_ThrusterLeft = m_Game.soundSystem.LoadOggSound(_T("sfx/thruster.ogg"));
		m_ThrusterLeft.SetPosition(2, 0, 0);
		m_ThrusterLeft.SetVolume(4);
		m_ThrusterRight = m_Game.soundSystem.LoadOggSound(_T("sfx/thruster.ogg"));
		m_ThrusterRight.SetPosition(-2, 0, 0);
		m_ThrusterRight.SetVolume(4);
		
		m_EngineTrail = New!EngineTrail(this);
		m_Game.octree.insert(m_EngineTrail);
		
		InitMessaging();
	}

  ~this()
  {
    Delete(m_ThrusterFront);
    Delete(m_ThrusterLeft);
    Delete(m_ThrusterRight);
  }
	
	private class ClientMsgs {
		// Send by the server to a client that just killed an entity. Use it to
		// deselect a target that we just killed
		void killedOne(EntityId targetId){
			if (m_Selected && m_Selected.entityId == targetId)
				m_Selected = null;
		}
		
		void setEngineTrail(bool on){
			m_EngineTrail.on = on;
		}
	}
	
	/**
	 * Called by the game object factory after the netvars for the new game object
	 * have been received from the server. It is safe to use the netvars now.
	 */
	override void postSpawn(){
		super.postSpawn();
		
		if(!m_OnServer && m_Game.eventSink.clientId == m_ClientId){
			m_DirtCloud = New!DirtCloud(this);
			m_Game.octree.addGlobalRenderable(m_DirtCloud);
			
			m_Scheibe = New!Scheibe(this);
			m_Game.octree.addGlobalObject(m_Scheibe);
			
			toServer.setName(g_Env.playerName, EventType.preSync);
		}
		
		m_Game.rules.onPlayerJoin(this);
		m_Game.rules.registerHitable(this);
	}
	
	override IRenderProxy renderProxy() {
		if(m_Dead){
			if(m_Game.eventSink.clientId == m_ClientId)
				return m_RedProxy;
			else
				return null;
		}
		if(m_Game.eventSink.clientId == m_ClientId && m_FirstPerson){
			return m_CockpitProxy;
		}
		return m_FighterProxy;
	}
	
	override void updateOnClient(float timeDiff){
		// Do client side position prediction
		version(prediction){
			vec3[3] axis = orientation();
			updatePosition(axis, timeDiff);
		}
		
		// Do the rest (updates the bounding box, etc.)
		super.updateOnClient(timeDiff);
		
		//predict position
		//float dt_sec = timeDiff / 1000.0f;
		//position = position + velocity * dt_sec;
		
		/++
		mat4 own_transform = this.transformation(Position(vec3(0, 0, 0)));
		this.collisionHull.debugDraw(own_transform, g_Env.renderer, vec4(0, 0, 1, 1));
		
		auto hits = m_Game.octree.getObjectsInBox(this.boundingBox);
		foreach(hit; hits){
			auto other = cast(GameObject) hit;
			if (other !is null && other !is this && other.collisionHull !is null){
				mat4 other_transform = other.transformation(Position(vec3(0, 0, 0)));
				//other.collisionHull.debugDraw(other_transform, g_Env.renderer, vec4(1, 1, 0, 1));
				/+
				if ( this.m_CollisionHull.intersects(other.collisionHull, own_transform, other_transform) ){
					base.logger.info("game: projectile collision with %s", other.inspect());
				}
				+/
			}
		}
		++/
	}
	
	/**
	 * Called directly before the game object is removed from the world (both on
	 * the server and later on the client). This callback is triggered by the
	 * removeGameObject() message of the game object factory.
	 */
	override void onDeleteRequest(){
    m_RedProxy = null;
		m_Game.rules.removeHitable(this);
		m_Game.rules.onPlayerLeave(this);
		if(!m_OnServer){
			m_Game.octree.remove(m_EngineTrail);
      m_EngineTrail = null;
			if(m_DirtCloud !is null)
      {
				m_Game.octree.removeGlobalRenderable(m_DirtCloud);
        m_DirtCloud = null;
      }
			if(m_Scheibe !is null)
      {
				m_Game.octree.removeGlobalObject(m_Scheibe);
        Delete(m_Scheibe); m_Scheibe = null;
      }
		}
	}
	
	IHitable selected(){
		return m_Selected;
	}
	
	void reloadDirtCloud(){
		m_DirtCloud.loadXml();
	}
	
	override mat4 transformation(Position origin) const {
		return super.transformation(origin);
	}
	
	//
	// Controller stuff used to process input on the client
	//
	void look(float screenDeltaX, float screenDeltaY){
		toServer.look(screenDeltaX, screenDeltaY, EventType.preSync);
	}
	
	void moveForward(bool pressed){
		m_MainThruster = pressed;
		if (m_MainThruster) {
			m_Game.sound(_T("thruster_right")).Play();
			m_Game.sound(_T("thruster_left")).Play();
		} else {
			m_Game.sound(_T("thruster_right")).Stop();
			m_Game.sound(_T("thruster_left")).Stop();
		}
		toServer.moveForward(pressed, EventType.preSync);
	}
	void moveBackward(bool pressed){
		if (pressed)
			m_ThrusterFront.Play();
		else
			m_ThrusterFront.Stop();
		toServer.moveBackward(pressed, EventType.preSync);
	}
	void moveLeft(bool pressed){
		if (pressed)
			m_ThrusterLeft.Play();
		else
			m_ThrusterLeft.Stop();
		toServer.moveLeft(pressed, EventType.preSync);
	}
	void moveRight(bool pressed){
		if (pressed)
			m_ThrusterRight.Play();
		else
			m_ThrusterRight.Stop();
		toServer.moveRight(pressed, EventType.preSync);
	}
	void moveUp(bool pressed){
		toServer.moveUp(pressed, EventType.preSync);
	}
	void moveDown(bool pressed){
		toServer.moveDown(pressed, EventType.preSync);
	}
	
	void rotateLeft(bool pressed){
		toServer.rotateLeft(pressed, EventType.preSync);
	}
	void rotateRight(bool pressed){
		toServer.rotateRight(pressed, EventType.preSync);
	}
	
	void booster(bool pressed){
		toServer.booster(pressed, EventType.preSync);
	}
	
	void fire(ubyte weapon, bool pressed){
		toServer.fire(weapon, pressed, EventType.preSync);
	}
	
	void scoreBoard(bool pressed){
		auto game = cast(GameSimulation) m_Game;
		game.hud.showScore(pressed);
	}

  enum TeamRelation
  {
    Friend,
    Enemy,
    Neutral,
    All
  }
	
	void select(){
		auto viewDir = orientation()[2].normalize();
		
		IGameObject bestEntity;
		float bestProj = -1;
		
		foreach(entity; m_Game.rules.client.hitables){
			vec3 toEntityDir = (entity.position - this.position).normalize();
			float proj = viewDir.dot(toEntityDir);
      if(m_Game.cvars.debugAiming > 0.0)
      {
        g_Env.renderer.DrawTextWorldspace(0, entity.position, vec4(1.0f, 1.0f, 1.0f, 1.0f), "%f", proj);
      }
			if (proj > bestProj){
				bestProj = proj;
				bestEntity = entity;
			}
		}
		
		float angle = acos(bestProj) / PI * 180;
		if (angle < 45)
			m_Selected = cast(IHitable) bestEntity;
		else
			m_Selected = null;
	}
	
	void toggleFirstPerson(){
		m_FirstPerson = !m_FirstPerson;
		m_Scheibe.enabled = (m_FirstPerson);
	}
	
	bool firstPerson() const {
		return m_FirstPerson;
	}
	
	override void toggleCollMode(){
		m_CollMode = !m_CollMode;
		m_RenderProxy = client.resources.model( m_CollMode ? _T("fighter_coll") : _T("fighter") ).proxy;
	}
	
	// Stuff for network integration (message passing mixin added later because of
	// forward reference compiler bugs)
	mixin MakeSerializeable;
	mixin MessageCode;
}

class RedScreen : RenderProxyGameObject!(ObjectInfoShape) {
private:	
	vec4 m_Color;
	vec2[] m_Vertices;
	
public:	
	override void extractImpl(){
		produce!ObjectInfoShape();
	}

	override void initInfo(ref ObjectInfoShape info){
		info.color = vec4(1.0f,0.0f,0.0f,0.5f);
		info.vertices = [ vec2(0.0f,0.0f),
					      vec2(0.0f,g_Env.renderer.GetHeight()),
						  vec2(g_Env.renderer.GetWidth(),0.0f),
					      vec2(g_Env.renderer.GetWidth(),g_Env.renderer.GetHeight()) ];
		info.target = HudTarget.SCREEN;
	}
}
