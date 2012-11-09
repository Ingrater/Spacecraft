module base.all;

public import thBase.timer;
public import base.renderer;
public import base.game;
public import client.eventhandler;
public import base.c_types;
public import core.allocator;
public import core.refcounted;

struct Environment  {
	bool isServer = false;
	shared(Timer) mainTimer;
	shared(IRenderer) renderer;
	shared(EventHandler) eventHandler;
	shared(IGame) game;
	
	// On the client these are the IP and port we're gooing to connect to. On the
	// server these are the IP and port the server is bound to.
	string serverIp = "0.0.0.0";
	ushort serverPort = 50000;
	
	// Frame rate of the server. Used to calculate the cycle length on the server
	// and the collision parameters of the projectile.
	ushort serverFps = 30;
	
	// A small extention to use the game as a simple model viewer. If the -model
	// parameter was given this variable contains the name of the model to view
	// (relative to the data directory).
	rcstring viewModel;
	// A path to a submodel within the loaded model. If the array is empty no
	// submodel was specified.
	rcstring[] viewSubModel;
	
	// Switch to disable music in the game
	bool music = true;
  // Switch to disable all sound in the game
  bool sound = true;
	
	bool fullscreen = false;
  bool vsync = true;
	uint screenWidth = 800;
	uint screenHeight = 600;
	uint antialiasing = 0;
	
	bool grabInput = true;
	float mouseSensitivity = 1.0;
	
	rcstring playerName;
	byte team = 0;
	rcstring level;
	
	void reset() {
		renderer = null;
		eventHandler = null;
		game = null;
    viewModel = rcstring();
    playerName = _T("Nobody");
    level = _T("belt");
	}
};

public __gshared Environment g_Env;

shared static this()
{
  g_Env.reset();
}

shared static ~this()
{
  g_Env.reset();
}