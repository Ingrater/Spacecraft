module main;

import base.all;
import client.main, server.main;

import base.debughelper;
import thBase.io;
import thBase.conv;
import thBase.file;
import thBase.directory;
import thBase.logging;

debug
{
  static import thBase.asserthandler;
}

version(ParticlePerformance)
{
import game.effects.particle_oo_v4;
}


int main(string[] args){
  debug thBase.asserthandler.Init();
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
        case "-nosound":
          g_Env.sound = false;
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

    //Set a additional dll directory so the correct dlls (x86 or x64) are found
    version(Windows)
    {
      {
        char[1024] workingDir;
        size_t len = getWorkingDirectory(workingDir);
        setDllDirectory(workingDir[0..len]);
      }
    }

    setWorkingDirectory("..\\");
		
		// Clear the log file (truncate does not exist on Windows...)
    {
		   auto file = RawFile("error.log", "w");
    }
		
		base.logger.init( (g_Env.isServer) ? "server.log" : "client.log" );
		logMessage("starting up engine");
    {
      char[1024] workingDir;
      size_t len = getWorkingDirectory(workingDir);
      logMessage("Working directory is: %s", workingDir[0..len]);
    }
		
		// Create the main timer
		g_Env.mainTimer = cast(shared(Timer))New!Timer();
    scope(exit) Delete(g_Env.mainTimer);

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

      /*core.memory.GC.disable();
      scope(exit){
        core.memory.GC.enable();
        core.memory.GC.collect();
      }*/

      while(true)
      {
        //core.memory.GC.collect();

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
		
		logInfo("engine shutdown completed successfully");
		
		return 0;
	}
	catch(Exception e){
		logError("Exception %s", e.toString()[]);
		DebugOutput(format("Exception %s", e.toString()[])[]);
		auto datei = RawFile("error.log", "a");
		datei.writeArray("Exception");
    datei.writeArray(e.toString()[]);
		datei.close();
    Delete(e);
	}
	catch(Error e){
		logError("Error %s", e.toString()[]);
		DebugOutput(format("Error %s", e.toString()[])[]);
		auto datei = RawFile("error.log","a");
		datei.writeArray("Error ");
    datei.writeArray(e.toString()[]);
		datei.close();
    Delete(e);
	}

	return -1;
}

