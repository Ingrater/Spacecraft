module server.main;

import base.all, server.net;
static import base.logger, server.resources;
import console = server.console;
import game.factory, script.factory;
import core.thread;

void server_main(){
	assert(g_Env.isServer);
	
	// Setup the server console
	console.init();
	scope(exit) console.shutdown();
	base.logger.hook(&writeToConsole);
	
	// Start up the scripting system for the console
	base.logger.info("Starting scripting...");
	auto factory = NewScriptSystemFactory();
	factory.Init();
	auto scriptSystem = factory.NewScriptSystem();
  scope(exit)
  {
    factory.DeleteScriptSystem(scriptSystem);
    DeleteScriptSystemFactory(factory);
  }
	
	// Register functions that can be called though the console
	//scriptSystem.RegisterGlobal("say", toDelegate(&say));
	
	// Load the resources the server needs
	server.resources.loadCollision(_T("rock1"), _T("models/env/rock_small_1_coll.thModel"));
  server.resources.loadCollision(_T("rock2"), _T("models/env/rock_small_2_coll.thModel"));
  server.resources.loadCollision(_T("rock3"), _T("models/env/rock_small_3_coll.thModel"));
  server.resources.loadCollision(_T("rock1_high"), _T("models/env/rock_small_1_coll_high.thModel"));
  server.resources.loadCollision(_T("rock2_high"), _T("models/env/rock_small_2_coll_high.thModel"));
  server.resources.loadCollision(_T("rock3_high"), _T("models/env/rock_small_3_coll_high.thModel"));
  server.resources.loadCollision(_T("frigate"), _T("models/frigate_coll.thModel"));
  server.resources.loadCollision(_T("heavy_base"), _T("models/weapons/heavy_base_coll.thModel"));
  server.resources.loadCollision(_T("heavy_cannon"), _T("models/weapons/heavy_cannon_coll.thModel"));
  server.resources.loadCollision(_T("flak_base"), _T("models/weapons/flak_base_coll.thModel"));
  server.resources.loadCollision(_T("flak_cannon"), _T("models/weapons/flak_cannon_coll.thModel"));
  server.resources.loadCollision(_T("fighter"), _T("models/figther_coll.thModel"));
  server.resources.loadCollision(_T("spacestation"), _T("models/env/spacestation_full_coll.thModel"));
  server.resources.loadCollision(_T("habitat"), _T("models/env/spacestation2_coll.thModel"));
  scope(exit) 
  {
    server.resources.unloadCollisions();
  }
	
	// Start up network and close it if we're done
	base.logger.info("Starting network...");
	auto netServer = New!NetworkServer(g_Env.serverIp, g_Env.serverPort);
	scope(exit)
  {
    netServer.close();
    Delete(netServer);
  }
	
	// Setup the game
	base.logger.info("Starting game...");
  auto gameFactory = NewGameFactory();
	auto game = gameFactory.GetGame();
  scope(exit) 
  {  
    gameFactory.DeleteGame(game);
    DeleteGameFactory(gameFactory);
  }
  game.PreInit();
	game.Init(scriptSystem, netServer, null);
	scope(exit) game.Deinit();
	
	base.logger.info("Startup complete, running main loop");
	Zeitpunkt cycle_start;
	console.write("> ");
	
	try {
		while(true){
			auto rootProfile = base.profiler.ProfileRoot(base.profiler.GetProfiler());
			cycle_start = Zeitpunkt(g_Env.mainTimer);
			
			// Start the cylce report for events triggerd by accepting new clients and
			// the received stuff. It is here because the event triggered by accept()
			// and receive() have to be in the same cycle report as the synchronized
			// changes created by collectChanges(). Otherwise the post spawn messages
			// will fire on a game object with unsynced data (becase the sync data
			// would be in the next cycle report).
			// 
			// Newly accepted clients will automatically start a new cycle report so
			// after accept() every connected client is within a cycle report.
			netServer.startReports();
			
			// Welcome new clients
			netServer.accept(game);
			
			// Receive pending events from clients and fire them on the game objects
			netServer.receive(game);
			
			// Call update() on all game objects
			bool continueGame = game.Work();
			
			auto command = console.read();
			if (command.length > 0){
				if (command == "exit")
					break;
				
				try {
					scriptSystem.execute(command);
				} catch(ScriptError e) {
					base.logger.warn("Command line error: %s", e.toString()[]);
          Delete(e);
				}
				
				console.write("> ");
			}
			
			// Collect pending changes to the game objects
			netServer.collectChanges(game.factory);
			// And broadcast them to the clients (including the events enqueued for
			// the individual clients)
			netServer.send();
			
			//update octree
			game.octree.update();
			game.octree.optimize();
			
			//run the GC
			core.memory.GC.collect();
			
			// Exit the game loop if we are schedule to do so
			if (!continueGame)
				break;
			
			// Sleep until the next cycle begins
			auto remaining_ms = (1_000 / g_Env.serverFps) - cast(long)(Zeitpunkt(g_Env.mainTimer) - cycle_start);
			if (remaining_ms > 0)
				Thread.getThis().sleep( dur!("msecs")(remaining_ms) );
		}
	} catch(Exception e) {
		base.logger.error("Exception in server main loop %s", e.toString()[]);
    Delete(e);
	} catch(Error e) {
		base.logger.error("Error in server main loop %s", e.toString()[]);
    Delete(e);
	}
}

void writeToConsole(string message) {
	console.writeln(message);
}

void say(uint client_id, string text){
	console.writeln("server says: " ~ text);
	//base.blocknet.server.enqueue_for_client(client_id, text.dup);
}
