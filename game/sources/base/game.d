module base.game;

public import base.octree;
public import core.sync.mutex;
public import base.script;
public import base.events;
public import base.gameobject;
public import base.sound;

interface IGameObjectFactory {
	/**
	 * returns a game object by id
	 * Params:
	 *  id = the game object to get
	 * Returns: the object or null if it does not exist
	 */
	IGameObject getGameObject(EntityId id);
	
	/**
	 * Iterates over all game objects
	 */
	int foreachGameObject(scope int delegate(ref IGameObject) dg);
	
	/**
	 * called for each newly conneted client to transmit existing gameobjects to that client
	 */
	void OnClientConnected(uint clientId);
	
	EntityId nextEntityId();
	void removeGameObject(IGameObject obj);
  void removeClientGameObject(IGameObject obj);
	void registerObject(EntityId id, IGameObject entity);
}

interface IGame {
	Octree octree();
	Octree octree() shared;
	Mutex simulationMutex();
	shared(Mutex) simulationMutex() shared;
	
	IGameObjectFactory factory();
	IEventSink eventSink();
	IGameObject camera();
	
	ISoundSystem soundSystem();
	void loadSounds(rcstring[] names);
	ISoundSource sound(rcstring name);
	
	IScriptSystem scriptSystem();
  void PreInit();
  void RunExtractor();
  void StopExtractor();

	// Called from the server netcode when it accepted a new player and everything
	// is setup properly. Never called on clients.
	void onPlayerConnect(uint clientId);
	// Called from the server netcode when the connection to a player was closed
	// or lost. Never called on clients.
	void onPlayerDisconnect(uint clientId);
}

interface IGameThread : IGame {
	void Init(IScriptSystem scriptSystem, IEventSink eventSink, ISoundSystem soundSystem);
	bool Work();
	void Deinit();
}

interface IGameFactory {
	void Init();
	IGameThread GetGame();
  void DeleteGame(IGameThread game);
}

//extern(D) IGameFactory GetGameFactory();
