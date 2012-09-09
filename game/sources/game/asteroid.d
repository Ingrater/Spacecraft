module game.asteroid;

import game.gameobject, base.all;
import game.collision;
static import client.resources, server.resources;
import game.game;

class Asteroid : GameObject, ISerializeable {
	
	// Stuff for network integration
	mixin MakeSerializeable;
	mixin DummyMessageCode;
	
	private {
		netvar!ubyte m_Variant;
	}
	
	//
	// Server side game object code
	//
	
	/**
	 * Server side constructor
	 */
	this(EntityId entityId, GameSimulation game, Position pos, Quaternion rot, ubyte variant = 1, vec3 scale = vec3(1, 1, 1)){
		assert(variant >= 1 && variant <= 3, "game: there are only 3 asteroid variants: 1, 2, 3");
		m_Variant = variant;
		
		rcstring variantName;
		if (scale.x > 20 || scale.y > 20 || scale.z > 20)
			variantName = format("rock%d_high", variant);
		else
			variantName = format("rock%d", variant);
		
		super(entityId, game, pos, rot, server.resources.col(variantName), scale);
	}
	
	
	//
	// Client side game object code
	//
	
	/**
	 * Client side constructor. Called when the game object factory creates this
	 * game object as requested by the server. This takes place before the data
	 * for this game object arives. Therefore you can only set attributes but the
	 * netvars will not be set to their proper server values yet.
	 */
	this(EntityId entityId, GameSimulation game){
		auto res = client.resources.model(_T("rock1"));
		m_RenderProxy = res.proxy;
		super(entityId, game, res.boundingBox, null);
	}
	
	override void postSpawn(){
		auto res = client.resources.model(format("rock%d", m_Variant.value));
		m_RenderProxy = res.proxy;
		m_OriginalBoundingBox = res.boundingBox;
		super.postSpawn();
	}
	
	/**
	 * position setter for debugging purposes
	 */
	void setPosition(float x, float y, float z){
		m_Position = Position(vec3(x,y,z));
	}
	
	/**
	 * velocity setter for debugging purposes
	 */
	void setVelocity(float x, float y, float z){
		m_Velocity = vec3(x,y,z);
	}
}
