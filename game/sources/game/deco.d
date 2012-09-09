module game.deco;

import game.gameobject;
import game.collision;
import game.game;
static import client.resources, server.resources;

class Station : GameObject, ISerializeable {
	
	// Stuff for network integration
	mixin MakeSerializeable;
	mixin DummyMessageCode;
	
	//
	// Server side game object code
	//
	
	/**
	 * Server side constructor
	 */
	this(EntityId entityId, GameSimulation game, Position pos, Quaternion rot, vec3 scale){
		super(entityId, game, pos, rot, server.resources.col(_T("spacestation")), scale);
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
		auto res = client.resources.model(_T("spacestation"));
		m_RenderProxy = res.proxy;
		super(entityId, game, res.boundingBox, null);
	}
}

class Habitat : GameObject, ISerializeable {
	
	// Stuff for network integration
	mixin MakeSerializeable;
	mixin DummyMessageCode;
	
	//
	// Server side game object code
	//
	
	/**
	 * Server side constructor
	 */
	this(EntityId entityId, GameSimulation game, Position pos, Quaternion rot, vec3 scale){
		super(entityId, game, pos, rot, server.resources.col(_T("habitat")), scale);
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
		auto res = client.resources.model(_T("habitat"));
		m_RenderProxy = res.proxy;
		super(entityId, game, res.boundingBox, null);
	}
}
