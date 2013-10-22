module game.game;

import base.game;
import base.all;
import base.script;
import base.net;
import base.events;
import thBase.file;
import client.inputlistener;

import game.asteroid;
import game.skybox;
import game.freecam;
import game.console, game.hud;
import game.cvars;
import game.objectfactory;
import game.demomodel, game.frigate, game.player, game.attachedcam;
import game.effects.enginetrail, game.effects.shieldimpact, game.effects.smallexplosion;
import game.effects.bigexplosion;

import game.rules.base, game.rules.deathmatch;
import thBase.container.queue;
import thBase.container.hashmap;

import core.thread;

import client.net;

import thBase.logging;


class GameSimulation : IGameThread, IGame {
	private:		
		version(triangle_intersection_test){
			vec3[6] m_Vertices;
			int m_ToMove = 0;
		}
		class GameInput : IInputListener {
			private:
				bool m_MouseOn = true;
				bool m_ConsoleOn = false;
        ThreadSafeRingBuffer!() m_RingBuffer;

			public:

        this()
        {
          m_RingBuffer = New!(typeof(m_RingBuffer))(8 * 1024); //8kb input buffer
        }

        ~this()
        {
          Delete(m_RingBuffer);
        }

        @property ThreadSafeRingBuffer!() ringBuffer() { return m_RingBuffer; }

        @property shared(ThreadSafeRingBuffer!()) ringBuffer() shared { return m_RingBuffer; }
				
				override void OnMouseButton(ubyte device, ubyte button, bool pressed, ushort x, ushort y) {
					/*if(g_Env.viewModel && pressed){
						vec3 pos = m_FreeCamera.position.toVec3();
						spawnAsteroidAtCam(pos.x,pos.y,pos.z);
					}*/
					m_Controller.fire(button, pressed);
				}
				
				override void OnMouseMove(ubyte device, ushort x, ushort y, short xrel, short yrel) {
					if(m_MouseOn){
						m_Controller.look(xrel * g_Env.mouseSensitivity, yrel * g_Env.mouseSensitivity);
					}
				}
				
				override void OnKeyboard(ubyte device, bool pressed, uint key, ushort unicode, ubyte scancode, uint mod) {
          //core.stdc.stdio.printf("W is pressed 1 = %d\n", pressed);
					if(m_ConsoleOn){
						if(pressed){
							switch(key){
								case Keys.RETURN:
									m_Console.execute();
									break;
								case Keys.BACKSPACE:
									m_Console.delLast();
									break;
								case Keys.CARET:
								case Keys.BACKQUOTE: // ^
								case Keys.F1:
									m_ConsoleOn = !m_ConsoleOn;
									m_Console.show = m_ConsoleOn;
									break;
								case Keys.PAGEUP:
									m_Console.scrollUp();
									break;
								case Keys.PAGEDOWN:
									m_Console.scrollDown();
									break;
                case Keys.UP:
                  m_Console.prevCommand();
                  break;
                case Keys.DOWN:
                  m_Console.nextCommand();
                  break;
                case Keys.ESCAPE:
                  m_Console.abort();
                  break;
                case Keys.TAB:
                  m_Console.useAutocompleteSuggestion();
                  break;
                case Keys.SPACE:
                  if(mod & ModKeys.LCTRL)
                  {
                    m_Console.autocomplete();
                    break;
                  }
                  else
                    goto default;
								default:
									if(unicode != 0)
										m_Console.charIn(unicode);
									break;
							}
						}
					}
					else {
						switch(key){
							case Keys.ESCAPE: //ESC
								m_ExitGame = true;
								break;
							case Keys.w: //W
                //core.stdc.stdio.printf("W is pressed = %d\n", pressed);
								m_Controller.moveForward(pressed);
								break;
							case Keys.s: //S
								m_Controller.moveBackward(pressed);
								break;
							case Keys.a: //A
								m_Controller.moveLeft(pressed);
								break;
							case Keys.d: //D
								m_Controller.moveRight(pressed);
								break;
							case Keys.q: //Q
								m_Controller.rotateLeft(pressed);
								break;
							case Keys.e: //E
								m_Controller.rotateRight(pressed);
								break;
							case Keys.LSHIFT:
								m_Controller.booster(pressed);
								break;
							case Keys.SPACE:
								m_Controller.moveUp(pressed);
								break;
							case Keys.LCTRL:
							case Keys.RCTRL:
								m_Controller.moveDown(pressed);
								break;
							case Keys.TAB:
								m_Controller.scoreBoard(pressed);
								break;
							case Keys.f:
								if(g_Env.viewModel) {
									//TODO fix
									if(pressed)
										(cast(IRenderer)g_Env.renderer).freezeCamera();
								} else {
									m_Controller.select();
								}
								break;
							case Keys.v: //V
								if(pressed){
									Player player = cast(Player)m_Controller;
									if(player){
										player.toggleFirstPerson();
										if(player.firstPerson()){
											m_AttachedCamera.offset = m_FirstPersonOffset;
										}
										else {
											m_AttachedCamera.offset = m_ThirdPersonOffset;
										}
									}
								}
								break;
							case Keys.m: //M
								if(pressed)
									m_MouseOn = !m_MouseOn;
								break;
							case Keys.CARET:
							case Keys.BACKQUOTE: // ^
							case Keys.F1:
								if(pressed){
									m_ConsoleOn = !m_ConsoleOn;
									m_Console.show = m_ConsoleOn;
								}
								break;
							case Keys.F2:
								if(pressed)
									m_Hud.toggleAimingHelp();
								break;
							case Keys.F3:
								if (pressed)
									toggleCollMode();
								break;
							version(triangle_intersection_test){
								case Keys.NUMBER_1:
								case Keys.NUMBER_2:
								case Keys.NUMBER_3:
								case Keys.NUMBER_4:
								case Keys.NUMBER_5:
								case Keys.NUMBER_6:
									m_ToMove = key - Keys.NUMBER_1;
									break;
								case Keys.KP9:
									m_Vertices[m_ToMove].z += 1.0f;
									break;
								case Keys.KP3:
									m_Vertices[m_ToMove].z -= 1.0f;
									break;
								case Keys.KP4:
									m_Vertices[m_ToMove].x -= 1.0f;
									break;
								case Keys.KP6:
									m_Vertices[m_ToMove].x += 1.0f;
									break;
								case Keys.KP8:
									m_Vertices[m_ToMove].y += 1.0f;
									break;
								case Keys.KP2:
									m_Vertices[m_ToMove].y -= 1.0f;
									break;
							}
							
							default:
								logInfo("OnKeyboard %d %c",key,cast(wchar)unicode);
								break;
						}
					}
				}
				
				override void OnJoyAxis(ubyte device, ubyte axis, short value) {
				}
				
				override void OnJoyButton(ubyte device, ubyte button, bool pressed) {
				}
				
				override void OnJoyBall(ubyte device, ubyte ball, short xrel, short yrel) {
				}
				
				override void OnJoyHat(ubyte device, ubyte hat, ubyte value) {
				}
		}
		
		vec3 m_FirstPersonOffset;
		vec3 m_ThirdPersonOffset;
		
		Octree m_Octree;
		Mutex m_Mutex;
		GameInput m_InputHandler;
		bool m_ExitGame = false;
		
		IControllable m_Controller;
		FreeCam m_FreeCamera;
		AttachedCamera m_AttachedCamera;
		IGameObject m_Camera;
		Zeitpunkt m_LastUpdate;
		Zeitpunkt m_LastMeasurement;
		
		IScriptSystem m_ScriptSystem;
		ISoundSystem m_SoundSystem;
		Hashmap!(rcstring,ISoundSource) m_Sounds;
		Console m_Console;
		SmartPtr!HUD m_Hud;
		IRulesBase m_Rules;

    SkyBox m_SkyBox;
		
		CVars m_CVars;
		ConfigVarsBinding* m_CVarsStorage;
		
		IEventSink m_EventSink;
		GameObjectFactory m_GameObjectFactory;
		
		uint m_Simulations = 0;
		float m_LastExplosion = 0.0f;

    IRendererExtractor m_Extractor;
	
	public:
		this(){
			m_Mutex = New!Mutex;
			m_Octree = new Octree(10000.0f,10.0f); // crashes when using New!
      m_Sounds = New!(typeof(m_Sounds))();
			m_GameObjectFactory = New!GameObjectFactory(this);
			m_LastMeasurement = m_LastUpdate;
			m_FirstPersonOffset = vec3(0,0.4f,-1.0f);
			m_ThirdPersonOffset = vec3(0,10,50);
		}

    ~this()
    {
      Delete(m_SkyBox);
      foreach(sound; m_Sounds.values)
      {
        Delete(sound);
      }
      Delete(m_Sounds);
      if(m_Controller is m_FreeCamera)
        m_Controller = null;
      if(m_Camera is m_FreeCamera)
      {
        m_Camera = null;
        if(g_Env.renderer !is null)
          g_Env.renderer.camera = null;
      }
      Delete(m_FreeCamera);
      m_FreeCamera = null;

      Delete(m_AttachedCamera);
      m_AttachedCamera = null;

      if(m_InputHandler !is null)
      {
        if(g_Env.eventHandler !is null)
          g_Env.eventHandler.DeregisterInputListener(cast(shared(GameInput))m_InputHandler);
        Delete(m_InputHandler);
        m_InputHandler = null;
      }

      m_Octree.removeGlobalRenderable(m_Console);
      Delete(m_Console);
      m_Console = null;

      Delete(m_GameObjectFactory);
      Delete(m_Rules); m_Rules = null;
      Delete(m_Octree);
      Delete(m_Mutex);
    }
		
		/////////////////////////////////////////////////////////
		// IGameThread
		/////////////////////////////////////////////////////////
		
		override void Init(IScriptSystem scriptSystem, IEventSink eventSink, ISoundSystem soundSystem)
		in {
			assert(scriptSystem !is null);
			assert(eventSink !is null);
		}
		body {
			synchronized(m_Mutex){
				m_ScriptSystem = scriptSystem;
				m_EventSink = eventSink;
				m_SoundSystem = soundSystem;
				
				RegisterScriptFunctions();
				RegisterCVars();
				
				if (g_Env.viewModel) {
					// Model was given on command line so create a model viewer world
					initModelViewer();
				} else if (eventSink.connected) {
					if (g_Env.isServer) {
						// Game is running on the server
						initNetworkServer();
					} else {
						// Game is running as a connected client
						initNetworkClient();
					}
				} else {
					initStandaloneClient();
				}
				m_LastUpdate = Zeitpunkt(g_Env.mainTimer);
			}
		}
		
		/**
		 * Inits a simple model viewer game. The world is just the model, camera and
		 * skybox.
		 */
		private void initModelViewer(){
			m_Console = New!Console(m_ScriptSystem, g_Env.renderer.GetWidth(), 200);
			m_Octree.addGlobalRenderable(m_Console);
			
			m_InputHandler = new GameInput();
			g_Env.eventHandler.RegisterInputListener(cast(shared(GameInput))m_InputHandler);
			
			shared(ITexture) skyBoxTexture = g_Env.renderer.assetLoader.LoadCubeMap(_T("gfx/env/skybox.dds"));
			auto skyBoxRenderProxy = g_Env.renderer.CreateRenderProxySkyBox(skyBoxTexture);
      m_SkyBox = New!SkyBox(skyBoxRenderProxy);
			m_Octree.addGlobalRenderable( m_SkyBox );
			
			SmartPtr!IRenderProxy cameraRenderProxy = g_Env.renderer.CreateRenderProxy();
			
			m_FreeCamera = New!FreeCam(cameraRenderProxy);
			m_Controller = m_FreeCamera;
			m_Camera = m_FreeCamera;
			g_Env.renderer.camera = m_Camera;
			
      version(ParticlePerformance) {}
      else {
			  auto model = g_Env.renderer.assetLoader.LoadModel(g_Env.viewModel);
			  shared(ISubModel) viewerModel;
			  if (g_Env.viewSubModel.length > 0)
				  viewerModel = model.GetSubModel(-1, cast(string[]) g_Env.viewSubModel);
			  else
				  viewerModel = model;
			  IGameObject modelEntity = New!DemoModel(m_GameObjectFactory.nextEntityId(), viewerModel, Position(vec3(0, 0, 0)), Quaternion(vec3(1, 0, 0), 0));
			  m_Octree.addGlobalObject(modelEntity);
      }
			
			version(triangle_intersection_test){
				m_Vertices[0] = vec3(0.0f,0.0f,0.0f);
				m_Vertices[1] = vec3(1.0f,0.0f,0.0f);
				m_Vertices[2] = vec3(1.0f,0.0f,1.0f);
				
				m_Vertices[3] = vec3(0.0f,1.0f,0.0f);
				m_Vertices[4] = vec3(1.0f,1.0f,0.0f);
				m_Vertices[5] = vec3(1.0f,1.0f,1.0f);
			}
			
			loadAutoexecLua(_T("autoexec.lua"));
		}
		
		/**
		 * Game runs as a server which is connected to many clients. It's just the
		 * game object factory and the game objects for the level (frigates,
		 * asteroids, players, ...) but no skybox or cameras.
		 */
		private void initNetworkServer(){
			m_Rules = New!DeathmatchRulesBase(this);
			m_Rules.onGameStart();
			loadAutoexecLua(_T("autoexec_server.lua"));
		}
		
		/**
		 * Game runs as a client connected to a server. It's just the game object
		 * factory (created in the constructor) the skybox and the unattached
		 * camera.
		 */
		private void initNetworkClient(){
			m_ScriptSystem.RegisterGlobal("sensitivity", &setMouseSensitivity);
			
			m_Console = New!Console(m_ScriptSystem, g_Env.renderer.GetWidth(), 200);
			m_Hud = New!HUD(null, this);
			m_InputHandler = new GameInput();
			g_Env.eventHandler.RegisterInputListener(cast(shared(GameInput))m_InputHandler);
			
			SmartPtr!IRenderProxy cameraProxy = g_Env.renderer.CreateRenderProxy();
			m_FreeCamera = New!FreeCam(cameraProxy);
      m_FreeCamera.update(1.0f);
			m_Camera = m_FreeCamera;
			m_Controller = m_FreeCamera;
			g_Env.renderer.camera = m_FreeCamera;
			
			// Create an attachable camera for the player entity. Because it needs a
			// valid game object we just attach it to the free cam right now (but
			// don't use it!).
			m_AttachedCamera = New!AttachedCamera(m_FreeCamera,m_FirstPersonOffset);
			
			m_Octree.addGlobalRenderable(m_Console);
			m_Octree.addGlobalRenderable(m_Hud);
			
			m_Rules = New!DeathmatchRulesBase(this);
			m_Rules.onGameStart();
			
			loadAutoexecLua(_T("autoexec.lua"));
		}
		
		/**
		 * Game is running as unconnected standalone client. For now just run the
		 * model viewer with a default model.
		 */
		private void initStandaloneClient(){
			g_Env.viewModel = "models/frigatte.thModel";
			initModelViewer();
		}
		
		/**
		 * Check if the specified autoexec file exists and executes it if so. Handy
		 * for development commands that are required on every run but are different
		 * from developer to developer.
		 */
		private void loadAutoexecLua(rcstring filename){
			if (thBase.file.exists(filename[])){
				logInfo("executing %s", filename[]);
				m_ScriptSystem.executeFile(filename);
			}
		}
		
		override bool Work(){
			// If the game is scheduled to exit signal it now so the game thread will
			// stop
			if (m_ExitGame)
				return false;
			
			Zeitpunkt now = Zeitpunkt(g_Env.mainTimer);
			
			synchronized(m_Mutex){
				auto mutexprofile = base.profiler.Profile("mutexed");
				float timeDiff = now - m_LastUpdate;
				if (timeDiff > 10_000){
					logWarning("game: got a cycle time diff of %s ms. Resetting to 100 ms.", timeDiff);
					timeDiff = 100;
				}
				//logInfo("timeDiff %s",timeDiff);
				
				if(now - m_LastMeasurement > 500.0f){
					float simulationsPerSecond = cast(float)m_Simulations * 1000.0f / (now - m_LastMeasurement);
					m_LastMeasurement = now;
					m_Simulations = 0;
					if(g_Env.renderer !is null){
						g_Env.renderer.setSPS(simulationsPerSecond);
					}
				}
				
				//Server game code
				if(g_Env.isServer){
					foreach(obj; m_Octree.allObjects()){
						obj.update(timeDiff);
					}
					
					// Update the rules manually since they are not stored in any list
					m_Rules.onUpdate(timeDiff);
					
					/*m_LastExplosion -= timeDiff;
					if(m_LastExplosion < 0.0f){
						m_LastExplosion += 3.0f;
						auto bigExplosion = new BigExplosion(m_GameObjectFactory.nextEntityId(),this,Position(vec3(500,500,500)),vec3(0,0,1),2.0f);
						m_GameObjectFactory.SpawnGameObject(bigExplosion);
						m_LastExplosion += 3000.0f;
					}*/
					
					// Clean out entities marked as dead during the cycle
					// NOTE: Looks like the dead objects need to be cleaned up before the
					// octree update and optimization.
					m_GameObjectFactory.cleanDeadGameObjects();
				}
				//Client game code
				else {
          //Wait for a command buffer from the renderer
          {
            auto renderbufferprofile = base.profiler.Profile("Wait for render buffer");
            m_Extractor.WaitForBuffer();
          }
					
					//core.stdc.stdio.printf("Messages %d\n",getNumberOfMessages(thisTid()));
					
					//Code for testing debugging draw functions
					/**auto testBox = AlignedBox(vec3(-100,-100,-100),vec3(100,100,100));
					g_Env.renderer.drawBox(testBox,vec4(0.0f,1.0f,0.0f,1.0f));
					g_Env.renderer.drawLine(Position(vec3(-100,0,0)),Position(vec3(100,0,0)));**/
					
					if(m_CVars.debugOctree > 0.0 || m_CVars.debugObjects > 0.0){
						auto profile = base.profiler.Profile("debug draw");
						if(m_CVars.debugOctree > 0.0){
							m_Octree.debugDraw(g_Env.renderer);
						}
						
						if(m_CVars.debugObjects > 0.0){
							foreach(entity; m_Octree.allObjects)
								entity.debugDraw(g_Env.renderer);
						}
					}
					
					//Handle input events
					{
						//core.stdc.stdio.printf("input start\n");
						auto profile = base.profiler.Profile("input handling");
						m_InputHandler.ProgressMessages();
						//core.stdc.stdio.printf("input end\n");
					}
					
					//Update the local camera object
					{
						auto profile = base.profiler.Profile("camera update");
						m_FreeCamera.update(timeDiff);
					}
					
					//This should not be removed as soon as the network is working
					{
						auto profile = base.profiler.Profile("update gameobjects");
						foreach(obj; m_Octree.allObjects()){
							obj.update(timeDiff);
						}

            foreach(obj; m_Octree.globalObjects())
            {
              obj.update(timeDiff);
            }
						
						foreach(obj; m_Octree.allObjects()){
							if(obj.syncOverNetwork)
								obj.resetChangedFlags();
						}

						foreach(obj; m_Octree.globalObjects()){
							if(obj.syncOverNetwork)
								obj.resetChangedFlags();
						}

						// Update the rules manually since they are not stored in any list
						if (m_Rules)
							m_Rules.onUpdate(timeDiff);
					}
					
					// Clean out entities marked as dead during the cycle
					// NOTE: Looks like the dead objects need to be cleaned up before the
					// octree update and optimization.
					m_GameObjectFactory.cleanDeadGameObjects();
					
					//Update and optimize the octree
					{
						auto profile = base.profiler.Profile("Octree update");
						m_Octree.update();
						m_Octree.optimize();
					}
					
					version(triangle_intersection_test){
						if(g_Env.renderer !is null){
							g_Env.renderer.DrawText(0,vec2(20,200),"%f %f %f\n%f %f %f\n%f %f %f\n%f %f %f\n%f %f %f\n%f %f %f",
								m_Vertices[0].x,m_Vertices[0].y,m_Vertices[0].z,
								m_Vertices[1].x,m_Vertices[1].y,m_Vertices[1].z,
								m_Vertices[2].x,m_Vertices[2].y,m_Vertices[2].z,
								m_Vertices[3].x,m_Vertices[3].y,m_Vertices[3].z,
								m_Vertices[4].x,m_Vertices[4].y,m_Vertices[4].z,
								m_Vertices[5].x,m_Vertices[5].y,m_Vertices[5].z);
							
							Triangle t1 = Triangle(m_Vertices[0],m_Vertices[1],m_Vertices[2]);
							Triangle t2 = Triangle(m_Vertices[3],m_Vertices[4],m_Vertices[5]);
							
							bool intersects = t1.intersects(t2);
							vec4 color = (intersects) ? vec4(1.0f,0.0f,0.0f,1.0f) : vec4(0.0f,1.0f,0.0f,1.0f);
							g_Env.renderer.drawLine(Position(m_Vertices[0]),Position(m_Vertices[1]),color);
							g_Env.renderer.drawLine(Position(m_Vertices[0]),Position(m_Vertices[2]),color);
							g_Env.renderer.drawLine(Position(m_Vertices[1]),Position(m_Vertices[2]),color);
							
							g_Env.renderer.drawLine(Position(m_Vertices[3]),Position(m_Vertices[4]),color);
							g_Env.renderer.drawLine(Position(m_Vertices[3]),Position(m_Vertices[5]),color);
							g_Env.renderer.drawLine(Position(m_Vertices[4]),Position(m_Vertices[5]),color);
						}
					}
					
          //Let the extractor do the work
          m_Extractor.extractObjects(this);
				}
				
				m_LastUpdate = now;
				m_Simulations++;
			}		
			
			return true;
		}
		
		override void Deinit(){
			synchronized(m_Mutex){
				if(m_Rules !is null) //null in model viewer
					m_Rules.onGameEnd();
        m_GameObjectFactory.removeAllObjects();
			}
		}
		
		/+
		/**
		 * Called by the server net code after a player was disconnected from the
		 * game. Useful to kill stuff related to the player.
		 */
		override void onPlayerDisconnect(uint clientId){
			IGameObject[] deadEntities;
			foreach(entity; factory.allGameObjects){
				auto player = cast(Player) entity;
				if (player && player.clientId == clientId)
					deadEntities ~= entity;
			}
			
			foreach(entity; deadEntities)
				factory.removeGameObject(entity);
		}
		+/
		
		/**
		 * Gives the specified player the control over the game. Attaches the camera
		 * to the player and tells the HUD to display the stats of this player.
		 */
		void handoverControl(Player controller){
			logInfo("game: setting controller to %s", controller.inspect()[]);
			m_Controller = controller;
			m_AttachedCamera.attachTo(controller);
			m_Camera = m_AttachedCamera;
			g_Env.renderer.camera = m_AttachedCamera;
			m_Hud.localPlayer = controller;
		}
		
		/+
		/**
		 * Called by the client and server constructor of the Player object. Should
		 * be used for code that needs to run every time the player is spawned (e.g.
		 * attaching camera on the client, etc.).
		 */
		override void onPlayerSpawn(IGameObject playerEntity, uint playerClientId){
			
			auto player = cast(Player) playerEntity;
			assert(player !is null, "game: onPlayerSpawn called with a non Player game object as argument");
			m_Players[playerClientId] = player;
			
			if (!g_Env.isServer && m_EventSink.clientId == playerClientId) {
				logInfo("game: player spawned, client id: %s, own client id: %d", playerClientId, m_EventSink.clientId);
				auto controller = cast(IControllable) player;
				if (controller) {
				} else {
					logWarning("game: spawned a player that is not controllable: %s", player.inspect());
				}
			} else {
				logInfo("game: player spawned, client id: %s", playerClientId);
			}
		}
		+/
		
		/+
		/**
		 * Called by the onDeleteRequest method of the player (both on the server
		 * and later on the client). Therefore a good way to do work for both.
		 */
		override void onPlayerLeave(IGameObject playerEntity, uint playerClientId){
			auto player = cast(Player) playerEntity;
			assert(player !is null, "game: onPlayerLeave called with a non Player game object as argument");
			m_Players.remove(playerClientId);
		}
		+/
		
		/+
		/**
		 * A player object calls this function on the server if it has finished
		 * dying.
		 */
		override void onPlayerDeath(IGameObject playerEntity){
			auto player = cast(Player) playerEntity;
			if (player !is null) {
				logInfo("game: player %s died!", player.clientId);
			} else {
				logWarning("game: something called onPlayerRespawn() but was not a Player: %s", playerEntity.inspect);
			}
		}
		+/
		
		IRulesBase rules(){
			assert(m_Rules !is null, "game: Someone asked for the game rules but no rules were set! Maybe the model viewer tries to interact with the rules?");
			return m_Rules;
		}
		
		HUD hud(){
			return m_Hud;
		}

    override void PreInit()
    {
      //initialize the profiler
      base.profiler.Init("game");
      base.profiler.GetProfiler().addChart(_T("mutexed"));
      base.profiler.GetProfiler().addChart(_T("Octree update"));
      base.profiler.GetProfiler().addChart(_T("producing"));
      base.profiler.GetProfiler().addChart(_T("game objects"));
      base.profiler.GetProfiler().addChart(_T("global game objects"));
      base.profiler.GetProfiler().addChart(_T("debug geom"));
      base.profiler.GetProfiler().addChart(_T("renderables"));
      base.profiler.GetProfiler().addChart(_T("dirtcloud"));
      //base.profiler.GetProfiler().addChart(_T("sort"));
      base.profiler.GetProfiler().addChart(_T("respawn"));
      base.profiler.GetProfiler().addChart(_T("Wait for render buffer"));
      //base.profiler.GetProfiler().addChart(_T("net mutexed"));

      //Initialize the extractor
      if(g_Env.viewModel || !g_Env.isServer)
      {
        assert(g_Env.renderer !is null);
        m_Extractor = g_Env.renderer.GetExtractor();
      }
    }

    override void RunExtractor()
    {
      m_Extractor.WaitForBuffer();
      m_Extractor.extractObjects(this);
    }

    override void StopExtractor()
    {
      m_Extractor.stop();
    }
		
		
		//
		// Game console commands
		//
		
		void setMouseSensitivity(float value){
			g_Env.mouseSensitivity = value;
		}
		
		/////////////////////////////////////////////////////////
		// Game inspection functions (called on the console)
		/////////////////////////////////////////////////////////
		
		/**
		 * Logs information about the current game objects. Does not work for the
		 * model viewer since it does not spawn the shown model with the game object
		 * factory.
		 */
		void inspectWorld(){
			// factory.allGameObjects will return a list of all factory registered
			// game objects. This does not work for the model viewer.
			// m_Octree.allObjects will return all objects with some exceptions (?).
			factory.foreachGameObject((ref IGameObject entity)
      {
				logInfo("%s", entity.inspect[]);
        return 0;
      });
		}
		
		/**
		 * Spawns a new asteroid
		 */
		void spawnAsteroid(float x, float y, float z){
			logInfo("spawnAsteroid %f %f %f",x,y,z);
			auto obj = New!Asteroid(m_GameObjectFactory.nextEntityId(), this, Position(vec3(x,y,z)), Quaternion(vec3(1, 0, 0), 0));
			m_GameObjectFactory.SpawnGameObject(obj);
		}
		
		/**
		 * Spawns a new asteroid in the model viewer
		 */
		void spawnAsteroid2(float x, float y, float z){
			logInfo("spawnAsteroid %f %f %f",x,y,z);
			auto obj = New!Asteroid(EntityId(2), this);
			obj.setPosition(x,y,z);
			obj.update(1.0f);
			m_Octree.insert(obj);
		}
		
		/**
		 * Spawns a new asteroid in the model viewer
		 */
		void spawnAsteroidAtCam(float x, float y, float z){
			vec4 dir = m_FreeCamera.rotation().toMat4() * vec4(0,0,-50,1);
			logInfo("spawnAsteroidAtCam %f %f %f, v = %f %f %f",x,y,z,dir.x,dir.y,dir.z);
			auto obj = new Asteroid(EntityId(2), this);
			obj.setPosition(x,y,z);
			obj.update(1.0f);
			obj.setVelocity(dir.x,dir.y,dir.z);
			m_Octree.insert(obj);
		}
		
		/**
		 * sets the attached cam offset
		 */
		void setCamOffset(float x, float y, float z){
			m_AttachedCamera.offset(vec3(x,y,z));
		}
		
		/**
		 * reloads the engine effect
		 */
		void reloadEngineEffect(){
			EngineTrail.loadXml();
		}
		
		/**
		 * reloads the dirt cloud effect
		 */
		void reloadDirtCloudEffect(){
			(cast(Player)m_Controller).reloadDirtCloud();
		}
		
		/**
		 * reloads the shield impact effect
		 */
		void reloadShieldImpactEffect(){
			ShieldImpact.loadXml();
		}
		
		/**
		 * reloads the small explosion effect
		 */
		void reloadSmallExplosionEffect(){
			SmallExplosion.loadXml();
		}
		
		/**
		 * reloads the big explosion effect
		 */
		void reloadBigExplosionEffect(){
			BigExplosion.loadXml();
		}
		
		/**
		 * dumps the octree to the logfile
		 */
		void dumpOctree(){
			m_Octree.dumpToConsole();
		}
		
		/**
		 * starts a rotation in the model viewer
		 */
		void startRotation(float radius, float speed, float offset){
			m_FreeCamera.rotateAroundCenter(radius,speed,offset);
		}
		
		/**
		 * Asks every game object to toggle its collision mesh. Useful for
		 * collision debugging.
		 */
		void toggleCollMode(){
			foreach(object; m_Octree.allObjects)
				object.toggleCollMode();
		}
		
		/**
		 * loads new renderer ambient settings
		 */
		void loadAmbientSettings(rcstring path){
			g_Env.renderer.loadAmbientSettings(path);
		}
		
		/////////////////////////////////////////////////////////
		// Sound stuff
		/////////////////////////////////////////////////////////
		
		void loadSounds(rcstring[] names){
			foreach(ref name; names){
				// FIXME: sound loader currently crashes the game
				logInfo("sound: loading %s", name[]);
				m_Sounds[name] = m_SoundSystem.LoadOggSound(format("sfx/%s.ogg", name[]));
			}
		}
		
		ISoundSource sound(rcstring name){
			if (m_Sounds.exists(name))
				return m_Sounds[name];
			else
				throw new RCException(format("Could not find sound '%s'. Maybe it's not loaded?", name[]));
		}
		
		/////////////////////////////////////////////////////////
		// Game interaction code
		/////////////////////////////////////////////////////////
		
		override IEventSink eventSink(){
			return m_EventSink;
		}
		
		override GameObjectFactory factory(){
			return m_GameObjectFactory;
		}
		
		override ISoundSystem soundSystem(){
			return m_SoundSystem;
		}
		
		override IScriptSystem scriptSystem(){
			return m_ScriptSystem;
		}
		
		override IGameObject camera(){
			return m_Camera;
		}
		
		
		/////////////////////////////////////////////////////////
		// IGame
		/////////////////////////////////////////////////////////
		
		override Octree octree(){
			return m_Octree;
		}
		
		override Octree octree() shared {
			return cast(Octree)m_Octree;
		}
		
		override Mutex simulationMutex(){
			return m_Mutex;
		}
		
		override shared(Mutex) simulationMutex() shared {
			return m_Mutex;
		}

    // Called from the server netcode when it accepted a new player and everything
    // is setup properly. Never called on clients.
    override void onPlayerConnect(uint clientId)
    {
      m_Rules.server.onPlayerConnect(clientId);
    }

    // Called from the server netcode when the connection to a player was closed
    // or lost. Never called on clients.
    override void onPlayerDisconnect(uint clientId)
    {
      m_Rules.server.onPlayerDisconnect(clientId);
    }
		
		/////////////////////////////////////////////////////////
		// Rest
		/////////////////////////////////////////////////////////

		void RegisterScriptFunctions(){
			m_ScriptSystem.RegisterGlobal("inspectWorld", &inspectWorld);
			m_ScriptSystem.RegisterGlobal("dumpOctree", &dumpOctree);
			m_ScriptSystem.RegisterGlobal("setCamOffset",&setCamOffset);
			
			m_ScriptSystem.RegisterGlobal("reloadBigExplosionEffect",&reloadBigExplosionEffect);
			
			// Server side commands
			if(g_Env.isServer){
				m_ScriptSystem.RegisterGlobal("spawnAsteroid", &spawnAsteroid);
			}
			else { //Client side commands
				m_ScriptSystem.RegisterGlobal("reloadEngineEffect",&reloadEngineEffect);
				m_ScriptSystem.RegisterGlobal("reloadDirtCloudEffect",&reloadDirtCloudEffect);
				m_ScriptSystem.RegisterGlobal("reloadShieldImpactEffect",&reloadShieldImpactEffect);
				m_ScriptSystem.RegisterGlobal("reloadSmallExplosionEffect",&reloadSmallExplosionEffect);
				m_ScriptSystem.RegisterGlobal("toggleCollMode",&toggleCollMode);
				m_ScriptSystem.RegisterGlobal("loadAmbientSettings",&loadAmbientSettings);
			}
			if(g_Env.viewModel){
				m_ScriptSystem.RegisterGlobal("sa",&spawnAsteroid2);
				m_ScriptSystem.RegisterGlobal("sav",&spawnAsteroidAtCam);
				m_ScriptSystem.RegisterGlobal("startRotation",&startRotation);
			}
		}
		
		void RegisterCVars(){
			m_CVarsStorage = m_ScriptSystem.RegisterVariableScope("cvars");
			foreach(m;__traits(allMembers, typeof(m_CVars)))
      {
        static if(m.length < 2 || m[0..2] != "__")
				  m_CVarsStorage.registerVariable(m, __traits(getMember, this.m_CVars, m));
			}
			if (g_Env.renderer)
				g_Env.renderer.RegisterCVars(m_CVarsStorage);
		}

    @property CVars cvars()
    {
      return m_CVars;
    }
}
