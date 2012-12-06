module game.rules.deathmatch;

import game.rules.base, game.objectfactory, game.game;
import game.asteroid, game.frigate, game.player, game.deco, game.skybox;
import base.renderer, base.sound, base.all, thBase.container.linkedlist;
import game.projectiles, game.hitable;
import std.math, std.random;
import thBase.container.hashmap;
import thBase.scoped;

import thBase.logging;

abstract class DeathmatchRulesBase : RulesBase, ISerializeable {
	
	private static {
		const float maxRoundTime = 15 * 60;
		const float pauseDuration = 30;
	}
	
	private {
		ServerRules m_ServerRules;
		ClientRules m_ClientRules;
	}
	
	this(GameSimulation game){
		super(game);
		InitMessaging();
		
		// Remember: also set the interface pointers in the parent class, otherwise
		// the use that uses the interfaces will segfault.
		if (g_Env.isServer) {
			m_ServerRules = new ServerRules(this, game);
			super.m_ServerRules = m_ServerRules;
		} else {
			m_ClientRules = new ClientRules(this, game);
			super.m_ClientRules = m_ClientRules;
		}
	}

  ~this()
  {
    if(m_ServerRules !is null)
    {
      Delete(m_ServerRules);
      m_ServerRules = null;
      super.m_ServerRules = null;
    }
    if(m_ClientRules !is null)
    {
      Delete(m_ClientRules);
      m_ClientRules = null;
      super.m_ClientRules = null;
    }
  }
	
	class ServerMsgs {
		void changeTeam(uint clientId, byte teamNumber){
			m_ServerRules.onTeamChange(clientId, teamNumber);
		}
		
		void loadLevel(rcstring name){
			m_ServerRules.loadLevel(name);
		}
	}
	
	class ClientMsgs {
		void setRoundTime(float currentRoundTime){
			m_ClientRules.roundTime = currentRoundTime;
			logInfo("game: set round time to %s", currentRoundTime);
		}
		void roundStart(){
			logInfo("game: starting round");
			m_Game.hud.roundEnd(false);
			m_ClientRules.roundTime = 0;
		}
		void roundEnd(){
			logInfo("game: round ended");
			m_Game.hud.roundEnd(true);
		}
		void loadLevel(rcstring name){
			m_ClientRules.loadClientLevel(name);
		}
	}
	
	// Stuff for network integration (message passing mixin added later because of
	// forward reference compiler bugs)
	mixin MakeSerializeable;
	mixin MessageCode;
}

class ServerRules : IServerRules {
	
	private {
		DeathmatchRulesBase relay;
		GameSimulation game;
		Hashmap!(uint, Player) m_Players;
		Hashmap!(EntityId, HitableGameObject) m_Hitables;
		float roundTime = 0, pauseTime = -1;
		
		bool checkForIntersections = true;
		vec3 spawnAreaMin, spawnAreaMax;
		Quaternion spawnOrientation;
		
		const float spawnFreeRadius = 20;
		
		byte defaultTeam = 0;
		
		struct ResurectInfo {
			float timeLeft;
			Player player;
		}
		
		DoubleLinkedList!(ResurectInfo) m_DeadPlayers;
	}
	
	this(DeathmatchRulesBase base, GameSimulation game){
		this.relay = base;
		this.game = game;
		
		spawnAreaMin = vec3(-100, -100, -100);
		spawnAreaMax = vec3(100, 100, 100);
		spawnOrientation = Quaternion(vec3(0, 1, 0), 0);
		
		game.scriptSystem.RegisterGlobal("frigate", &spawnFrigate);
		game.scriptSystem.RegisterGlobal("asteroid", &spawnAsteroid);
		game.scriptSystem.RegisterGlobal("station", &spawnStation);
		game.scriptSystem.RegisterGlobal("habitat", &spawnHabitat);
		game.scriptSystem.RegisterGlobal("intersects", &boxIntersects);
		game.scriptSystem.RegisterGlobal("avoidIntersections", &avoidIntersections);
		game.scriptSystem.RegisterGlobal("spawnArea", &setSpawnArea);
		game.scriptSystem.RegisterGlobal("spawnOrientation", &setSpawnOrientation);
		game.scriptSystem.RegisterGlobal("team", &setTeam);
		game.scriptSystem.RegisterGlobal("loadLevel", &loadLevel);

    m_DeadPlayers = New!(typeof(m_DeadPlayers))();
    m_Players = New!(typeof(m_Players))();
    m_Hitables = New!(typeof(m_Hitables))();
	}

  ~this()
  {
    Delete(m_DeadPlayers);
    Delete(m_Players);
    Delete(m_Hitables);
  }
	
	override void onGameStart(){
		logInfo("game: starting...");
		loadLevel(g_Env.level);
	}

  override Relation getRelation(EntityId ent1, EntityId ent2)
  {
    HitableGameObject obj1,obj2;
    m_Hitables.ifExists(ent1,(ref obj){ obj1 = obj;});
    m_Hitables.ifExists(ent2,(ref obj){ obj2 = obj;});
    if(obj1 is null || obj2 is null)
      return Relation.Unkown;
    if(obj1 is obj2)
      return Relation.Friend;
    if(obj1.team < 0 || obj2.team < 0)
      return Relation.Neutral;
    if(obj1.team == obj2.team)
    {
      if(obj1.team == 0)
        return Relation.Enemy;
      return Relation.Friend;
    }
    return Relation.Enemy;
  }
	
	override void onUpdate(float timeDiff){
		float dt_sec = timeDiff / 1_000;
		if (roundTime < relay.maxRoundTime) {
			roundTime += dt_sec;
		} else {
			if (pauseTime < 0) {
				pauseTime = 0;
				onRoundEnd();
			} else {
				pauseTime += dt_sec;
				if (pauseTime > relay.pauseDuration){
					pauseTime = -1;
					roundTime = 0;
					onRoundStart();
				}
			}
		}
		
		auto r = m_DeadPlayers[];
		while(!r.empty()){
			r.front.timeLeft -= timeDiff;
			if(r.front.timeLeft < 0){
				Position pos;
				Quaternion rot;
				calculateSpawnCoords(pos, rot);
				r.front.player.resurect(pos,rot);
				m_DeadPlayers.removeSingle(r);
			}
			else
				r.popFront();
		}
	}
	
	private void onRoundEnd(){
		logInfo("game: round ended");
		relay.toClient.roundEnd(EventType.preSync);
	}
	
	private void onRoundStart(){
		logInfo("game: starting new round");
		relay.toClient.roundStart(EventType.preSync);
		foreach(player; m_Players){
			player.resetScore();
			Position pos;
			Quaternion rot;
			calculateSpawnCoords(pos, rot);
			player.resurect(pos, rot);
		}
	}
	
	override void onGameEnd() {
		logInfo("game: ending...");
	}
	
	override void onPlayerConnect(uint clientId){
		logInfo("game: player %s connected", clientId);
		
		relay.toClient.setRoundTime(this.roundTime, EventType.preSync, clientId);
		
		Position pos;
		Quaternion rot;
		calculateSpawnCoords(pos, rot);
		auto player = new Player(game.factory.nextEntityId(), game, clientId, defaultTeam, pos, rot);
		
		auto fac = cast(GameObjectFactory) game.factory;
		fac.SpawnGameObject(player);
	}
	
	private void calculateSpawnCoords(ref Position pos, ref Quaternion rot){
		float x, y, z;
		
		do {
			x = uniform(spawnAreaMin.x, spawnAreaMax.x);
			y = uniform(spawnAreaMin.y, spawnAreaMax.y);
			z = uniform(spawnAreaMin.z, spawnAreaMax.z);
		} while( boxIntersects(x, y, z, spawnFreeRadius, spawnFreeRadius, spawnFreeRadius) );
		
		pos = Position(vec3(x, y, z));
		rot = spawnOrientation;
	}
	
	override void onPlayerJoin(Player player){
		logInfo("game: player %s joined the game", player.clientId);
		m_Players[player.clientId] = player;
	}
	
	override void onPlayerDisconnect(uint clientId){
		logInfo("game: player %s disconnected", clientId);
		if (m_Players.exists(clientId))
			game.factory.removeGameObject(m_Players[clientId]);
	}
	
	override void onPlayerLeave(Player player){
		logInfo("game: player %s (%s) left the game", player.name[], player.clientId);
    auto id = player.clientId; //workaround dmd 6799
		m_Players.remove(id);
	}
	
	override void onPlayerDeath(Player player){
		logInfo("game: player %s (%s) died", player.name[], player.clientId);
		
		m_DeadPlayers.insertFront(ResurectInfo(3000.0f,player));
	}
	
	override void registerHitable(HitableGameObject entity){
		m_Hitables[entity.entityId] = entity;
	}
	
	override void removeHitable(HitableGameObject entity){
		if (m_Hitables.exists(entity.entityId))
    {
      auto id = entity.entityId; //Workaround dmd 6799
			m_Hitables.remove(id);
    }
	}
	
	override Hashmap!(EntityId, HitableGameObject) hitables(){
		return m_Hitables;
	}
	
	void onTeamChange(uint clientId, byte team){
		if (m_Players.exists(clientId)){
      auto player = m_Players[clientId];
			logInfo("game: player %s (%s) changed team to %s", player.name[], clientId, team);
			player.team = team;
		}
	}
	
	
	//
	// Lua functions to build a level
	//
	
	private {
		bool spawnFrigate(float x, float y, float z, float axisX, float axisY, float axisZ, float angle){
			auto pos = Position(vec3(x, y, z));
			auto rot = Quaternion(vec3(axisX, axisY, axisZ), angle);
			auto fac = cast(GameObjectFactory) game.factory;
			
      auto frigate = New!Frigate(fac.nextEntityId(), game, defaultTeam, pos, rot);
			auto frigateScope = scopedRef!Frigate(frigate);
			if ( checkForIntersections && entityIntersects(frigate) )
				return false;
			
			fac.SpawnGameObject(frigateScope.releaseRef());
			
			auto heavyBase = new TurretBase!HeavyProjectile(
				frigate, Position(vec3(0, 44.722, 76.121)), Quaternion(vec3(0, 1, 0), 0),
				_T("Heavy Turret"), _T("heavy_base"), cast(float)PI_4, 0.75f, 2, 10_000,
				5_000, 2_500, 100
			);
			fac.SpawnGameObject(heavyBase);
			fac.SpawnGameObject(new TurretCannon!HeavyProjectile(
				heavyBase, Position(vec3(9.746, 11.971, -29.185)), Quaternion(vec3(0, 1, 0), 0),
				_T("heavy_cannon"), _T("models/weapons/heavy_cannon_turret.xml"), 0.0
			));
			fac.SpawnGameObject(new TurretCannon!HeavyProjectile(
				heavyBase, Position(vec3(-10.199, 11.971, -29.185)), Quaternion(vec3(0, 1, 0), 0),
				_T("heavy_cannon"), _T("models/weapons/heavy_cannon_turret.xml"), 0.5
			));
			
			heavyBase = new TurretBase!HeavyProjectile(
				frigate, Position(vec3(-0.339, -44.896, 57.784)), Quaternion(vec3(0, 0, 1), 180),
				_T("Heavy Turret"), _T("heavy_base"), PI_4, 0.75, 2, 10_000,
				5_000, 2_500, 100
			);
			fac.SpawnGameObject(heavyBase);
			fac.SpawnGameObject(new TurretCannon!HeavyProjectile(
				heavyBase, Position(vec3(10.139, 11.871, -29.225)), Quaternion(vec3(0, 0, 1), 180),
				_T("heavy_cannon"), _T("models/weapons/heavy_cannon_turret.xml"), 0.0
			));
			fac.SpawnGameObject(new TurretCannon!HeavyProjectile(
				heavyBase, Position(vec3(-9.806, 11.797, -29.225)), Quaternion(vec3(0, 0, 1), 180),
				_T("heavy_cannon"), _T("models/weapons/heavy_cannon_turret.xml"), 0.5
			));
			
			auto flakBase = new TurretBase!FlakProjectile(
				frigate, Position(vec3(38.004, -18.588, -142.258)), Quaternion(vec3(0, 0, 1), 90) * Quaternion(vec3(1, 0, 0), 90),
				_T("Flak"), _T("flak_base"), PI, 0.25, 1, 2_000,
				5_000, 2_500, 100
			);
			fac.SpawnGameObject(flakBase);
			fac.SpawnGameObject(new TurretCannon!FlakProjectile(
				flakBase, Position(vec3(3.895, 4.455, -0.024)), Quaternion(vec3(0, 0, 1), -90),
				_T("flak_cannon"), _T("models/weapons/flak_turret.xml"), 0.0
			));
			fac.SpawnGameObject(new TurretCannon!FlakProjectile(
				flakBase, Position(vec3(-3.908, 4.491, -0.024)), Quaternion(vec3(0, 0, 1), 90),
				_T("flak_cannon"), _T("models/weapons/flak_turret.xml"), 0.5
			));
			
			flakBase = new TurretBase!FlakProjectile(
				frigate, Position(vec3(-39.822, -18.588, -142.258)), Quaternion(vec3(0, 0, 1), -90) * Quaternion(vec3(1, 0, 0), 90),
				_T("Flak"), _T("flak_base"), PI, 0.25, 1, 2_000,
				5_000, 2_500, 100
			);
			fac.SpawnGameObject(flakBase);
			fac.SpawnGameObject(new TurretCannon!FlakProjectile(
				flakBase, Position(vec3(3.895, 4.455, -0.024)), Quaternion(vec3(0, 0, 1), -90),
				_T("flak_cannon"), _T("models/weapons/flak_turret.xml"), 0.0
			));
			fac.SpawnGameObject(new TurretCannon!FlakProjectile(
				flakBase, Position(vec3(-3.908, 4.491, -0.024)), Quaternion(vec3(0, 0, 1), 90),
				_T("flak_cannon"), _T("models/weapons/flak_turret.xml"), 0.5
			));
			
			return true;
		}
		
		bool spawnAsteroid(int variant, float x, float y, float z, float axisX, float axisY, float axisZ, float angle, float scale){
			auto pos = Position(vec3(x, y, z));
			auto rot = Quaternion(vec3(axisX, axisY, axisZ), angle);
			auto fac = cast(GameObjectFactory) game.factory;
			
			auto entity = scopedRef!Asteroid(New!Asteroid(fac.nextEntityId(), game, pos, rot, cast(ubyte)variant, vec3(scale, scale, scale)));
			if ( checkForIntersections && entityIntersects(entity) )
				return false;
			
			fac.SpawnGameObject(entity.releaseRef());
			return true;
		}
		
		bool spawnStation(float x, float y, float z, float axisX, float axisY, float axisZ, float angle, float scale){
			auto pos = Position(vec3(x, y, z));
			auto rot = Quaternion(vec3(axisX, axisY, axisZ), angle);
			auto fac = cast(GameObjectFactory) game.factory;
			
			auto entity = new Station(fac.nextEntityId(), game, pos, rot, vec3(scale, scale, scale));
			if ( checkForIntersections && entityIntersects(entity) )
				return false;
			
			fac.SpawnGameObject(entity);
			return true;
		}
		
		bool spawnHabitat(float x, float y, float z, float axisX, float axisY, float axisZ, float angle, float scale){
			auto pos = Position(vec3(x, y, z));
			auto rot = Quaternion(vec3(axisX, axisY, axisZ), angle);
			auto fac = cast(GameObjectFactory) game.factory;
			
			auto entity = new Habitat(fac.nextEntityId(), game, pos, rot, vec3(scale, scale, scale));
			if ( checkForIntersections && entityIntersects(entity) )
				return false;
			
			fac.SpawnGameObject(entity);
			return true;
		}
		
		void setSpawnArea(float minX, float maxX, float minY, float maxY, float minZ, float maxZ){
			spawnAreaMin = vec3(minX, minY, minZ);
			spawnAreaMax = vec3(maxX, maxY, maxZ);
		}
		
		void setSpawnOrientation(float x, float y, float z, float angle){
			spawnOrientation = Quaternion(vec3(x, y, z), angle);
		}
		
		bool entityIntersects(IGameObject entity){
			auto intersections = game.octree.getObjectsInBox(entity.boundingBox);
			return !intersections.empty;
		}
		
		bool boxIntersects(float x, float y, float z, float xSize, float ySize, float zSize){
			auto box = AlignedBox(vec3(x - xSize/2, y - ySize/2, z - zSize/2), vec3(x + xSize/2, y + ySize/2, z + zSize/2));
			auto intersections = game.octree.getObjectsInBox(box);
			return !intersections.empty;
		}
		
		void avoidIntersections(bool enable){
			checkForIntersections = enable;
		}
		
		void setTeam(int teamNumber){
			defaultTeam = cast(byte) teamNumber;
		}
		
		void loadLevel(rcstring name){
			logInfo("game: loading level %s...", name[]);
			
			// First clean out all game objects except players, the factory and the
			// game rules
      game.factory.foreachGameObject(
        (ref IGameObject entity)
        {
          if (entity.entityId > 2 && cast(Player)entity is null)
            game.factory.removeGameObject(entity);
          return 0;
        }
      );
			
			// Execute the server lua script for the level
			try {
				//game.scriptSystem.execute(std.file.readText("levels/" ~ name ~ "/server.lua"));
        game.scriptSystem.executeFile(format("levels/%s/server.lua", name[]));
			} catch(Exception e) {
				logWarning("game: could not load the level %s:\n%s", name[], e.toString()[]);
        Delete(e);
			}
			
			// Notify the clients so they reload the client side level script
			relay.toClient.loadLevel(name, EventType.preSync);
		}
	}
}

class ClientRules : IClientRules {
	
	private {
		DeathmatchRulesBase relay;
		GameSimulation game;
		Hashmap!(uint, Player) m_Players;
		Hashmap!(EntityId, HitableGameObject) m_Hitables;
		float roundTime = 0;
		
		// Level data
		IRenderable m_skyBox;
		ISoundSource m_music, m_athmo;
	}
	
	this(DeathmatchRulesBase relay, GameSimulation game){
		this.relay = relay;
		this.game = game;
		
		game.scriptSystem.RegisterGlobal("skybox", &createSkybox);
		game.scriptSystem.RegisterGlobal("music", &createMusic);
		game.scriptSystem.RegisterGlobal("athmo", &createAthmo);
		
		game.scriptSystem.RegisterGlobal("team", &changeTeam);
		game.scriptSystem.RegisterGlobal("name", &changeName);
		game.scriptSystem.RegisterGlobal("loadLevel", &loadServerLevel);

    m_Players = New!(typeof(m_Players))();
    m_Hitables = New!(typeof(m_Hitables))();
	}

  ~this()
  {
    Delete(m_Players);
    Delete(m_Hitables);
  }
	
	Hashmap!(uint, Player) players(){
		return m_Players;
	}
	
	override void onGameStart(){
		logInfo("game: starting...");
		
		// Execute the client lua script for the level. Can not be reloaded since
		// it's hard to remove all the stuff in a clean way. Since the server has no
		// way to tell the client which level is running the user have to restart
		// the client anyway.
		loadClientLevel(g_Env.level);
	}
	
	private void loadClientLevel(rcstring name){
		try {
			logInfo("game: loading client level %s:", name[]);
			//game.scriptSystem.execute(std.file.readText("levels/" ~ name ~ "/client.lua"));
      game.scriptSystem.executeFile(format("levels/%s/client.lua", name[]));
		} catch(Exception e) {
			logWarning("game: could not load the level %s:\n%s", name[], e.toString()[]);
      Delete(e);
		}
	}
	
	override void onUpdate(float timeDiff){
		if (m_music !is null && !m_music.IsPlaying){
			m_music.Rewind();
			m_music.Play();
		}
		
		if (roundTime <= relay.maxRoundTime)
			roundTime += timeDiff / 1_000;
	}
	
	override void onGameEnd() {
		logInfo("game: ending...");
    game.soundSystem.RemoveStream(m_music);
    Delete(m_music); m_music = null;
    Delete(m_athmo); m_athmo = null;
    game.octree.removeGlobalRenderable(m_skyBox);
    Delete(m_skyBox); m_skyBox = null;
	}
	
	override void onPlayerJoin(Player player){
		logInfo("game: player %s joined the game", player.clientId);
		m_Players[player.clientId] = player;
		
		if (game.eventSink.clientId == player.clientId)
			game.handoverControl(player);
		
		// Only change the team if the player specified something (0 is the default
		// value). This way we will spawn in the default team set by the map.
		if (g_Env.team != 0)
			changeTeam(g_Env.team);
	}
	
	override void onPlayerLeave(Player player){
		logInfo("game: player %s (%s) left the game", player.name[], player.clientId);

    auto id = player.clientId; //Workaround dmd 6799
		m_Players.remove(id);
	}
	
	override void onPlayerDeath(Player player){
		logInfo("game: player %s (%s) died", player.name[], player.clientId);
	}
	
	
	override void registerHitable(HitableGameObject entity){
		m_Hitables[entity.entityId] = entity;
	}
	
	override void removeHitable(HitableGameObject entity){
		if (m_Hitables.exists(entity.entityId))
    {
      auto id = entity.entityId; //Workaround dmd 6799
			m_Hitables.remove(id);
    }
	}
	
	override Hashmap!(EntityId, HitableGameObject) hitables(){
		return m_Hitables;
	}
	
	float roundTimeLeft(){
		return relay.maxRoundTime - roundTime;
	}

  override Relation getRelation(EntityId ent1, EntityId ent2)
  {
    HitableGameObject obj1,obj2;
    m_Hitables.ifExists(ent1,(ref obj){ obj1 = obj;});
    m_Hitables.ifExists(ent2,(ref obj){ obj2 = obj;});
    if(obj1 is null || obj2 is null)
      return Relation.Unkown;
    if(obj1 is obj2)
      return Relation.Friend;
    if(obj1.team < 0 || obj2.team < 0)
      return Relation.Neutral;
    if(obj1.team == obj2.team)
    {
      if(obj1.team == 0)
        return Relation.Enemy;
      return Relation.Friend;
    }
    return Relation.Enemy;
  }
	
	//
	// Lua functions to initialize the client
	//
	private {
		void createSkybox(rcstring path){
			auto skyBoxTexture = g_Env.renderer.assetLoader.LoadCubeMap(path);
			if (m_skyBox){
				game.octree.removeGlobalRenderable(m_skyBox);
        Delete(m_skyBox);
			}
			auto skyBoxProxy = g_Env.renderer.CreateRenderProxySkyBox(skyBoxTexture);
			m_skyBox = New!SkyBox(skyBoxProxy);
			game.octree.addGlobalRenderable(m_skyBox);
		}
		
		void createMusic(rcstring file){
			// Start the game m_music (if the user did not disable it)
			if (g_Env.music){
				if (m_music)
					m_music.Stop();
				
				m_music = game.soundSystem.LoadOggSound(file, true);
				m_music.SetVolume(0.25);
				m_music.Play();	// repeated by the game loop if the m_music ends
			}
		}
		
		void createAthmo(rcstring file){
			if (m_athmo)
				m_athmo.Stop();
			
			m_athmo = game.soundSystem.LoadOggSound(file);
			m_athmo.SetVolume(0.5);
			m_athmo.SetRepeat(true);
			m_athmo.Play();
		}
		
		void changeTeam(int teamNumber){
			relay.toServer.changeTeam(game.eventSink.clientId, cast(byte) teamNumber, EventType.preSync);
		}
		
		void changeName(rcstring newName){
			auto player = game.hud.localPlayer;
			if (player)
				player.toServer.setName(newName, EventType.preSync);
		}
		
		void loadServerLevel(rcstring name){
			relay.toServer.loadLevel(name, EventType.preSync);
		}
	}
}
