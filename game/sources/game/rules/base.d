module game.rules.base;

import base.gameobject, base.game, base.renderer, base.all;
import game.player, game.game, game.hitable;
import thBase.container.hashmap;

/**
 * All game objects that can react to hits should implement this interface.
 */
interface IHitable {
	// Accepts the damage and returns `true` if the projectile impacted (and has
	// to be destroyed). `false` if the projectile was reflected (usually by a
	// shield).
	bool hit(float damage, IGameObject other = null);
	float hitpoints();
	float fullHitpoints();
	float shieldStrength();
	float fullShieldStrength();
	EntityId entityId() const;
	
	float temperature();
	float fullTemperature();
	
	bool isDead();
	rcstring name();
	byte team();
	byte threatLevel();
	
	AlignedBox originalBoundingBox();
	mat4 transformation(Position origin) const;
}

interface ICommonRules {
	// Called from the game initialization
	void onGameStart();
	// Called on every game update
	void onUpdate(float timeDiff);
	// Called from the games deinit function when everything shuts down
	void onGameEnd();
	
	// Called from the constructor of the Player object. On the server from the
	// server constructor, on the client from the post spawn callback. Therefore
	// the player is always filled with valid information. An exception is the
	// player name which arrives one cycle later and is still the default value
	// when this callback is fired.
	void onPlayerJoin(Player player);
	// Called from the onDeleteRequest method of the player. This if fired on the
	// server and client before the player is removed from the world.
	void onPlayerLeave(Player player);
	
	// Called by the player update function in case the hitpoints have fallen
	// below zero.
	void onPlayerDeath(Player player);
	
	// Manages the list of selectable game objects for the player (on client) and
	// turrets (on server).
	void registerHitable(HitableGameObject entity);
	void removeHitable(HitableGameObject entity);
	Hashmap!(EntityId, HitableGameObject) hitables();

  enum Relation
  {
    Friend,
    Enemy,
    Neutral,
    Unkown
  }
  /**
   * Checks the relation between two entities
   * Params:
   *  ent1 = the first entity
   *  ent2 = the second entity
   * Returns: The relation between the two entities
   */
  Relation getRelation(EntityId ent1, EntityId ent2);
}

interface IRulesBase : ICommonRules {
	IServerRules server();
	IClientRules client();

  alias ICommonRules.getRelation getRelation;
}

interface IServerRules : ICommonRules {
	// Called from the server netcode when it accepted a new player and everything
	// is setup properly. Never called on clients.
	void onPlayerConnect(uint clientId);
	// Called from the server netcode when the connection to a player was closed
	// or lost. Never called on clients.
	void onPlayerDisconnect(uint clientId);
}

interface IClientRules : ICommonRules {
	Hashmap!(uint, Player) players();
	float roundTimeLeft();
}

/**
 * Base host class for game rules. Is a game object itself to use the message
 * passing.
 */
abstract class RulesBase : IGameObject, IRulesBase {
	protected {
		EntityId m_EntityId;
		IServerRules m_ServerRules;
		IClientRules m_ClientRules;
		GameSimulation m_Game;
	}
	
	this(GameSimulation game){
		m_Game = game;
		m_EntityId = 2;
    IGameObject tempInterface = this;
		game.factory.registerObject(m_EntityId, tempInterface);
	}
	
	IServerRules server(){
		assert(g_Env.isServer, "game: You should not try to use the server rules on the client!");
		return m_ServerRules;
	}
	IClientRules client(){
		assert(!g_Env.isServer, "game: You should not try to use the client rules on the server!");
		return m_ClientRules;
	}
	
	override void update(float timeDiff){
		onUpdate(timeDiff);
	}
	
	
	//
	// Shortcuts for callbacks that are the same on the client and server
	//
	
	override {
		void onGameStart(){
			if (g_Env.isServer)
				m_ServerRules.onGameStart();
			else
				m_ClientRules.onGameStart();
		}
		void onUpdate(float timeDiff){
			if (g_Env.isServer)
				m_ServerRules.onUpdate(timeDiff);
			else
				m_ClientRules.onUpdate(timeDiff);
		}
		void onGameEnd(){
			if (g_Env.isServer)
				m_ServerRules.onGameEnd();
			else
				m_ClientRules.onGameEnd();
		}
	
		void onPlayerJoin(Player player){
			if (g_Env.isServer)
				m_ServerRules.onPlayerJoin(player);
			else
				m_ClientRules.onPlayerJoin(player);
		}
		void onPlayerLeave(Player player){
			if (g_Env.isServer)
				m_ServerRules.onPlayerLeave(player);
			else
				m_ClientRules.onPlayerLeave(player);
		}
	
		void onPlayerDeath(Player player){
			if (g_Env.isServer)
				m_ServerRules.onPlayerDeath(player);
			else
				m_ClientRules.onPlayerDeath(player);
		}
		
		void registerHitable(HitableGameObject entity){
			if (g_Env.isServer)
				m_ServerRules.registerHitable(entity);
			else
				m_ClientRules.registerHitable(entity);
		}
		
		void removeHitable(HitableGameObject entity){
			if (g_Env.isServer)
				m_ServerRules.removeHitable(entity);
			else
				m_ClientRules.removeHitable(entity);
		}
		
		Hashmap!(EntityId, HitableGameObject) hitables(){
			if (g_Env.isServer)
				return m_ServerRules.hitables();
			else
				return m_ClientRules.hitables();
		}
	}
	
	override {
		
		// Stuff important for message passing
		EntityId entityId() const {
			return m_EntityId;
		}
		bool syncOverNetwork() const {
			return true;
		}
		
		// Other interface stuff we don't really need
		Position position() const {
			return Position(vec3(0, 0, 0));
		}
		void position(Position pos) {
		}
		Quaternion rotation() const {
			return Quaternion(vec3(0, 1, 0), 0);
		}
		mat4 transformation(Position origin) const {
			return mat4.Identity();
		}
		const(IGameObject) father() const {
			return null;
		}
		AlignedBox boundingBox() const {
			return AlignedBox(Position(vec3(-1, -1, -1)), Position(vec3(1, 1, 1)));
		}
		bool hasMoved() {
			return false;
		}
		IRenderProxy renderProxy(){
			return null;
		}
		
		void postSpawn() { }
		void onDeleteRequest() { }
		void toggleCollMode() { }
		void debugDraw(shared(IRenderer) renderer) { }
		
		IEvent constructEvent(EventId id, IAllocator allocator) {
			return null;
		}
		rcstring inspect(){
			return _T("Rules object");
		}
	}
}
