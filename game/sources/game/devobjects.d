module game.devobjects;

import game.gameobject, base.all;
import game.collision;
static import client.resources, server.resources;
import game.game;
import physics.rigidbody;

class Box : GameObject, ISerializeable {
private:
  RigidBody m_RigidBody;

public:
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
	this(EntityId entityId, GameSimulation game, float bounciness){
		auto res = client.resources.model(_T("box"));
		m_RenderProxy = res.proxy;
		super(entityId, game, res.boundingBox, null);
    m_RigidBody = New!RigidBody(server.resources.col(_T("box")), bounciness);
    game.physics.AddSimulatedBody(m_RigidBody);
	}

  ~this()
  {
    m_Game.physics.RemoveSimulatedBody(m_RigidBody);
    Delete(m_RigidBody);
  }

	/**
  * position setter for debugging purposes
  */
	void setPosition(float x, float y, float z){
    m_RigidBody.position = Position(vec3(x,y,z));
	}

	/**
  * velocity setter for debugging purposes
  */
	void setVelocity(float x, float y, float z){
		m_RigidBody.velocity = vec3(x,y,z);
	}

  override Object physicsComponent()
  {
    return m_RigidBody;
  }

  override void update(float timeDiff)
  {
    m_Position = m_RigidBody.position;
    m_Rotation = m_RigidBody.rotation;

    updateBoundingBox();
  }

}

class Plane : GameObject, ISerializeable {
private:
  RigidBody m_RigidBody;

public:
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
	this(EntityId entityId, GameSimulation game, float bounciness){
		auto res = client.resources.model(_T("plane"));
		m_RenderProxy = res.proxy;
		super(entityId, game, res.boundingBox, null);
    m_RigidBody = New!RigidBody(server.resources.col(_T("plane")), bounciness);
	}

  ~this()
  {
    Delete(m_RigidBody);
  }

	/**
  * position setter for debugging purposes
  */
	void setPosition(float x, float y, float z){
		m_Position = Position(vec3(x,y,z));
    m_RigidBody.position = m_Position;
	}

  override Object physicsComponent()
  {
    return m_RigidBody;
  }
}