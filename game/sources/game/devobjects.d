module game.devobjects;

import game.gameobject, base.all;
import game.collision;
static import client.resources, server.resources;
import game.game;

class Box : GameObject, ISerializeable {
	// Stuff for network integration
	mixin MakeSerializeable;
	mixin DummyMessageCode;

	/**
  * Server side constructor
  */
	this(EntityId entityId, GameSimulation game, Position pos, Quaternion rot, ubyte variant = 1, vec3 scale = vec3(1, 1, 1)){
		super(entityId, game, pos, rot, server.resources.col(_T("box")), scale);
	}

	/**
  * Client side constructor. Called when the game object factory creates this
  * game object as requested by the server. This takes place before the data
  * for this game object arives. Therefore you can only set attributes but the
  * netvars will not be set to their proper server values yet.
  */
	this(EntityId entityId, GameSimulation game){
		auto res = client.resources.model(_T("box"));
		m_RenderProxy = res.proxy;
		super(entityId, game, res.boundingBox, null);
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

class Plane : GameObject, ISerializeable {
	// Stuff for network integration
	mixin MakeSerializeable;
	mixin DummyMessageCode;

	/**
  * Server side constructor
  */
	this(EntityId entityId, GameSimulation game, Position pos, Quaternion rot, ubyte variant = 1, vec3 scale = vec3(1, 1, 1)){
		super(entityId, game, pos, rot, server.resources.col(_T("plane")), scale);
	}

	/**
  * Client side constructor. Called when the game object factory creates this
  * game object as requested by the server. This takes place before the data
  * for this game object arives. Therefore you can only set attributes but the
  * netvars will not be set to their proper server values yet.
  */
	this(EntityId entityId, GameSimulation game){
		auto res = client.resources.model(_T("plane"));
		m_RenderProxy = res.proxy;
		super(entityId, game, res.boundingBox, null);
	}

	/**
  * position setter for debugging purposes
  */
	void setPosition(float x, float y, float z){
		m_Position = Position(vec3(x,y,z));
	}
}