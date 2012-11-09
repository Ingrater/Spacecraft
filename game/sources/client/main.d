module client.main;

import base.all;
static import base.logger;
import game.factory, base.game, renderer.factory, base.renderer, script.factory, game.progressbar;
import base.sound, sound.factory;
import client.net;
static import client.resources;
import thBase.format;
import thBase.file;
import thBase.io;
import core.allocator;
import core.refcounted;

import base.debughelper;
import core.thread;

void client_main(){
	assert(!g_Env.isServer);
  scope(exit) g_Env.reset(); //after leaving main the environment is invalid
	
	// The garbage collector is run manually by the client
	core.memory.GC.disable();
	scope(exit){
		core.memory.GC.enable();
		core.memory.GC.collect();
	}
	
	// Print all messages on stdout
	debug {
		base.logger.hook(&append_to_console);
	}

	// Load and initialize the renderer factory
	IRendererFactory rendererFactory = GetRendererFactory();
  scope(exit)  DeleteRendererFactory(rendererFactory);
	rendererFactory.Init(g_Env.screenWidth, g_Env.screenHeight, g_Env.fullscreen, g_Env.vsync, g_Env.fullscreen, g_Env.grabInput, g_Env.antialiasing);

	IRenderer renderer = null;
  scope(exit)   
  {  	
    if(renderer !is null)
		  renderer.Deinit();
    g_Env.renderer = null;
  }
	
	// Build the basic game simulation
	IGameFactory gameFactory = NewGameFactory();
	IGameThread game = gameFactory.GetGame();
  scope(exit)
  {
    gameFactory.DeleteGame(game);
    DeleteGameFactory(gameFactory);
  }

  // Initialize the renderer
  renderer = rendererFactory.GetRenderer();
	g_Env.renderer = cast(shared(IRenderer)) renderer;
	renderer.OnResize(g_Env.screenWidth, g_Env.screenHeight);
	renderer.Init(cast(shared(IGameThread))game);
	base.logger.info("loaded renderer");
	
	// Build the event handler
	EventHandler eventHandler = New!EventHandler();
  scope(exit)
  { 
    g_Env.eventHandler = null;
    Delete(eventHandler);
  }
	g_Env.eventHandler = cast(shared(EventHandler)) (eventHandler);
	eventHandler.RegisterEventListener(renderer);
	
	// Initialize the scripting system and kick of the game thread
	IScriptSystemFactory scriptFactory = NewScriptSystemFactory();
  scope(exit) DeleteScriptSystemFactory(scriptFactory);
	scriptFactory.Init();
  IScriptSystem scriptSystem = scriptFactory.NewScriptSystem();
  scope(exit) scriptFactory.DeleteScriptSystem(scriptSystem);
	
	// Kick of the game thread that loads the content and connects to the server
	SmartPtr!GameThread gameThread = New!GameThread(game, scriptSystem);
	gameThread.start();
	
	
	//++++++++++++++++++++++++
	// Game Loop
	//++++++++++++++++++++++++
	
	eventHandler.EnableTextmode(true);
	
	try {		
		bool running = true;
		while(running){
			if(!eventHandler.ProgressEvents()){
				running = false;
			}
			
			renderer.Work();
			
			
			if(!gameThread.isRunning)
				running = false;
		}
	}
	catch(Exception e){
    auto msg = format("Exception in main loop %s", e.toString()[]);
		base.logger.error("%s", msg[]);
		DebugOutput(msg[]);
		auto datei = RawFile("error.log","a");
		datei.writeArray(msg);
    datei.write('\n');
    Delete(e);
	}
	catch(Error e){
    auto msg = format("Error in main loop %s", e.toString()[]);
		base.logger.error("%s", msg[]);
		DebugOutput(msg[]);
		auto datei = RawFile("error.log","a");
		datei.writeArray(msg[]);
		datei.write('\n');
    Delete(e);
	}

  if(gameThread !is null){
    gameThread.stop();
    gameThread.join();
  }
}

void append_to_console(string msg) {
	writefln(msg);
}


class GameThread : Thread {
private:
	IGameThread game;
	IScriptSystem scriptSystem;
	NetworkConnection connection;
	ISoundSystem soundSystem;
	ISoundSystemFactory soundFactory;
	bool m_Stop = false;
public:
	this(IGameThread game, IScriptSystem scriptSystem)
  {
		this.game = game;
		this.scriptSystem = scriptSystem;
		
		super( &run );
	}
	
	~this(){
	}
	
	void run()
  {
		base.logger.info("game thread started");
    scope(exit)
    {
      if(connection !is null)
      {
        connection.close();
        Delete(connection);
        connection = null;
      }
      game.StopExtractor();
      base.logger.info("game thread ended");
    }
		try {
      {
        SmartPtr!ProgressBar progressBar = New!ProgressBar();
        //Init the extractor so we can render from here
        game.PreInit(); 
        auto rootProfile = base.profiler.ProfileRoot(base.profiler.GetProfiler());

        //Add the progress bar as entity to be always rendered
			  synchronized(game.simulationMutex){
				  game.octree.addGlobalRenderable(progressBar);
			  }
        scope(exit)
        {
          synchronized(game.simulationMutex){
            game.octree.removeGlobalRenderable(progressBar);
          }
        }

			  scriptSystem.RegisterGlobal("exit", &stop);
			  progressBar.status = _T("Initializing Sound System");
        game.RunExtractor();
			  // Load and initialize the sound system
			  soundFactory = NewSoundSystemFactory(g_Env.sound ? SoundSystemType.OpenAL : SoundSystemType.None);
			  this.soundSystem = soundFactory.GetSoundSystem();
			
			  if(!g_Env.viewModel){
				  // Load the resources required by the client. We do this before the network
				  // connection because this can take some seconds. If many game objects are
				  // flying around this can be enought to fill the network buffers.
				  base.logger.info("Loading resources...");

          auto resourceData = [
					  [_T("nothing"), _T("models/weapons/flak_cannon.thModel")], // This model is used as a placeholder if the real model is still unknown (pending from network)
					  [_T("rock1"), _T("models/env/rock_small_1.thModel")],
					  [_T("rock2"), _T("models/env/rock_small_2.thModel")],
					  [_T("rock3"), _T("models/env/rock_small_3.thModel")],
					  [_T("frigate"), _T("models/frigate.thModel")],
					  [_T("heavy_base"), _T("models/weapons/heavy_base.thModel")],
					  [_T("heavy_cannon"), _T("models/weapons/heavy_cannon.thModel")],
					  [_T("frigate_coll"), _T("models/frigate_coll.thModel")],
					  [_T("heavy_base_coll"), _T("models/weapons/heavy_base_coll.thModel")],
					  [_T("heavy_cannon_coll"), _T("models/weapons/heavy_cannon_coll.thModel")],
					  [_T("flak_base"), _T("models/weapons/flak_base.thModel")],
					  [_T("flak_cannon"), _T("models/weapons/flak_cannon.thModel")],
					  [_T("flak_base_coll"), _T("models/weapons/flak_base_coll.thModel")],
					  [_T("flak_cannon_coll"), _T("models/weapons/flak_cannon_coll.thModel")],
					  [_T("fighter"), _T("models/figther.thModel")],
					  [_T("fighter_coll"), _T("models/figther_coll.thModel")],
					  [_T("cockpit"), _T("models/cockpit.thModel")],
					  [_T("cockpit_glass"), _T("models/cockpit_glass.thModel")],
					  [_T("spacestation"), _T("models/env/spacestation_full.thModel")],
					  [_T("habitat"), _T("models/env/spacestation2.thModel")]
				  ];
				
				  client.resources.loadModels(progressBar, game, 0, 0.75, resourceData);
          foreach(ref a; resourceData)
          {
            Delete(a);
            a = [];
          }
          Delete(resourceData);
			  }
			
			  // Connect to server if a non-empty IP was given
			  if (g_Env.serverIp != "" && !g_Env.viewModel) {
				  base.logger.info("Connecting to server...");
				  progressBar.status = _T("Connecting to server ...");
          game.RunExtractor();
				  this.connection = New!NetworkConnection(g_Env.serverIp, g_Env.serverPort);
			  } else {
				  this.connection = New!NetworkConnection();
			  }
			  progressBar.progress = 0.825;
			
			  progressBar.status = _T("Initializing Game");
        game.RunExtractor();
			  game.Init(scriptSystem, connection, soundSystem);
			  progressBar.progress = 1.0;
			  progressBar.status = _T("Done");
        game.RunExtractor();
      }

      scope(exit)
      {
        DeleteSoundSystemFactory(soundFactory);
        soundFactory = null;
        this.soundSystem = null;
      }
			
			while(!m_Stop){				
        auto rootProfile = base.profiler.ProfileRoot(base.profiler.GetProfiler());
				{
					auto mutexprofile = base.profiler.Profile("net mutexed");
					synchronized(game.simulationMutex){
						auto profile = base.profiler.Profile("net recieve");
						// Receive events from the server and synchronize entities
						connection.receive(game);
					}
				}
				
				// Do client side game logic
				bool continueGame = game.Work();
				if (!continueGame)
					m_Stop = true;
				
				//Update sound streams
				{
					auto profile = base.profiler.Profile("sound");
					soundSystem.Update();
				}
				
				// Send any input we got from the player to the server
				{
					auto profile = base.profiler.Profile("net send");
					connection.send();
				}
			}
			game.Deinit();
		}
		catch(Exception e){
      auto msg = format("Exception in game thread %s", e.toString()[]);
			base.logger.error("%s", msg[]);
			auto datei = RawFile("error.log", "a");
			datei.writeArray(msg[]);
			datei.write('\n');
      Delete(e);
		}
		catch(Error e){
      auto msg = format("Error in game thread %s", e.toString()[]);
			base.logger.error("%s", msg[]);
			auto datei = RawFile("error.log", "a");
			datei.writeArray(msg[]);
			datei.write('\n');
      Delete(e);
		} 
		catch(Throwable e){
			base.logger.error("unexpected error %s", e.toString()[]);
      Delete(e);
		}
	}
	
	void stop(){
		m_Stop = true;
	}
}
