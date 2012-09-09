module main;

import base.all;
import client.main, server.main;

import base.debughelper;
import base.assimp.assimp;
import thBase.io;
import thBase.conv;
import thBase.file;

version(ParticlePerformance)
{
import game.effects.particle_oo_v4;
}


int main(string[] args){
	try {
		// Parse command line arguments and store everything in g_Env
		for(uint i = 1; i < args.length; i++){
			switch(args[i]){
				case "-server":
					g_Env.isServer = true;
					break;
				case "-ip":
					i++;
					if (i >= args.length){
						writefln("The IP of the server is required after -ip");
						return -1;
					}
					g_Env.serverIp = args[i];
					break;
				case "-port":
					i++;
					if (i >= args.length){
						writefln("The port of the server is required after -port");
						return -1;
					}
					auto result = to!ushort(args[i], g_Env.serverPort);
          if(result == thResult.FAILURE)
          {
            writefln("%s is not a valid port number", args[i]);
            return -1;
          }
					break;
				case "-model":
					i++;
					if (i >= args.length){
						writefln("The name of the model you want to view is required after -model");
						return -1;
					}
					g_Env.viewModel = args[i];
					break;
				case "-submodel":
					i++;
					if (i >= args.length){
						writefln("The path of the submodel you want to view is required after -submodel");
						return -1;
					}
          assert(0, "TODO implement");
					//g_Env.viewSubModel = cast(shared(string[])) split(args[i], "/");
					//break;
				case "-nomusic":
					g_Env.music = false;
					break;
				case "-width":
					i++;
					if (i >= args.length){
						writefln("The width of the screen is required after -width");
						return -1;
					}
					auto result = to!uint(args[i], g_Env.screenWidth);
          if(result == thResult.FAILURE)
          {
            writefln("Invalid screen width value %s", args[i]);
            return -1;
          }
					break;
				case "-height":
					i++;
					if (i >= args.length){
						writefln("The height of the screen is required after -height");
						return -1;
					}
					auto result = to!uint(args[i], g_Env.screenHeight);
          if(result == thResult.FAILURE)
          {
            writefln("Invalid screen height value %s", args[i]);
          }
					break;
				case "-antialiasing":
					i++;
					if (i >= args.length){
						writefln("The amount of antialiasing is required after -antialiasing");
						return -1;
					}
					auto result = to!uint(args[i], g_Env.antialiasing);
          if(result == thResult.FAILURE)
          {
            writefln("Invalid value for antialiasing %s", args[i]);
            return -1;
          }
					break;
				case "-fullscreen":
					g_Env.fullscreen = true;
					break;
        case "-novsync":
          g_Env.vsync = false;
          break;
				case "-nograb":
					g_Env.grabInput = false;
					break;
				case "-name":
					i++;
					if (i >= args.length){
						writefln("The player name is required after -name");
						return -1;
					}
					g_Env.playerName = args[i];
					break;
				case "-level":
					i++;
					if (i >= args.length){
						writefln("The level name is required after -level");
						return -1;
					}
					g_Env.level = args[i];
					break;
				case "-sensitivity":
					i++;
					if (i >= args.length){
						writefln("The mouse sensitivity is required after -sensitivity");
						return -1;
					}
					auto result = to!float(args[i], g_Env.mouseSensitivity);
          if(result == thResult.FAILURE)
          {
            writefln("Invalid mouse sensitivity value %s", args[i]);
            return -1;
          }
					break;
				case "-fps":
					i++;
					if (i >= args.length){
						writefln("The server frame rate is required after -fps");
						return -1;
					}
					auto result = to!ushort(args[i], g_Env.serverFps);
          if(result == thResult.FAILURE)
          {
            writefln("Invalid server fps value %s", args[i]);
            return -1;
          }
					break;
				case "-team":
					i++;
					if (i >= args.length){
						writefln("The team number is required after -team");
						return -1;
					}
					auto result = to!byte(args[i], g_Env.team);
          if(result == thResult.FAILURE)
          {
            writefln("Invalid team value %s", args[i]);
            return -1;
          }
					break;
				default:
					writefln("Unknown command line option: %s", args[i]);
					return -1;
			}
		}
		
		// Clear the log file (truncate does not exist on Windows...)
    {
		   auto file = RawFile("error.log", "w");
    }
		
		base.logger.init( (g_Env.isServer) ? "server.log" : "client.log" );
		base.logger.info("starting up engine");
		
		// Create the main timer
		g_Env.mainTimer = new Timer();
    scope(exit) Delete(g_Env.mainTimer);
		
		//load assimp
		version(X86){
			Assimp.Load("assimp.dll","./libassimp.so");
		}
		version(X86_64){
			Assimp.Load("assimp64.dll","./libassimp.so");
		}

    version(ParticlePerformance)
    {
      // create particle system
      auto particleEmitter = new ParticleEmitterPoint("gfx/xml/emitter.xml");
      auto particleSystem = new ParticleSystem(particleEmitter);
      particleSystem.AddModifier(new ParticleModifierWind(vec3(0.00001f,0,0)));
      particleSystem.AddModifier(new ParticleModifierColorGradient(vec4(1,1,1,1), vec4(0.5f,0.5f,0.5f,1.0f)));
      particleSystem.AddModifier(new ParticleModifierStandard());
    
      //16 mb to trash the cache
      int[] cacheTrash = (cast(int*)malloc(4194304 * int.sizeof))[0..4194304];

      base.logger.hook(&append_to_console);

      core.memory.GC.disable();
      scope(exit){
        core.memory.GC.enable();
        core.memory.GC.collect();
      }

      while(true)
      {
        core.memory.GC.collect();

        particleSystem.update(1000.0f / 30.0f);

        foreach(ref el; cacheTrash)
        {
          ++el;
        }
      }
    }

		// Start the corresponding main loop
		if (g_Env.isServer)
			server_main();
		else
			client_main();
		
		base.logger.info("engine shutdown completed successfully");
		
		return 0;
	}
	catch(Exception e){
		base.logger.error("Exception %s", e.toString()[]);
		DebugOutput(format("Exception %s", e.toString()[])[]);
		auto datei = RawFile("error.log", "a");
		datei.writeArray("Exception");
    datei.writeArray(e.toString()[]);
		datei.close();
    Delete(e);
	}
	catch(Error e){
		base.logger.error("Error %s", e.toString()[]);
		DebugOutput(format("Error %s", e.toString()[])[]);
		auto datei = RawFile("error.log","a");
		datei.writeArray("Error ");
    datei.writeArray(e.toString()[]);
		datei.close();
    Delete(e);
	}

	return -1;
}
