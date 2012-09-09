module renderer.sdl.main;

import base.sharedlib;

private string dll_declare(string name){
	return "__gshared " ~ name ~ " " ~ name[4..name.length] ~ ";";
}

private string dll_init(string name){
	string sname = name[4..name.length];
	return sname ~ " = cast( typeof ( " ~ sname ~ ") ) GetProc(`" ~ name ~ "`); assert(" ~ sname ~ " !is null, \"" ~ sname ~ " not loaded \");";
}

private string dll_declare_gl(string name){
	return "__gshared " ~ name ~ " " ~ name[7..name.length] ~ ";";
}

private string dll_init_gl(string name){
	string sname = name[7..name.length];
	return "GL." ~ sname ~ " = cast( typeof ( GL." ~ sname ~ ") ) GetProc(`" ~ name ~ "`);";
}

/**
 * binding for SDL c library
 */
class SDL {	
	mixin SharedLib!();
	
	struct Rect {
		short x,y;
		ushort w,h;
	};
	
	struct Color {
		ubyte r,g,b,unused;
	};
	
	struct Palette {
		int ncolors;
		Color *colors;
	};
	
	struct PixelFormat {
		Palette *palette;
		ubyte BitsPerPixel;
		ubyte BytesPerPixel;
		ubyte Rloss,Gloss,Bloss,Aloss;
		ubyte Rshift,Gshift,Bshift,Ashift;
		ubyte Rmask,Gmask,Bmask,Amask;
		uint colorkey;
		ubyte alpha;
	};
	
	struct Surface {
		uint flags;
		PixelFormat *format;
		int width,height;
		ushort pitch;
		void *pixels;
		int offset;
		void *hwdata;
		Rect clip_rect;
		uint unused1;
		uint locked;
		void *map;
		uint format_version;
		int refcount;
	};
	
	enum GLattr : uint {
	    GL_RED_SIZE = 0,
	    GL_GREEN_SIZE,
	    GL_BLUE_SIZE,
	    GL_ALPHA_SIZE,
	    GL_BUFFER_SIZE,
	    GL_DOUBLEBUFFER,
	    GL_DEPTH_SIZE,
	    GL_STENCIL_SIZE,
	    GL_ACCUM_RED_SIZE,
	    GL_ACCUM_GREEN_SIZE,
	    GL_ACCUM_BLUE_SIZE,
	    GL_ACCUM_ALPHA_SIZE,
	    GL_STEREO,
	    GL_MULTISAMPLEBUFFERS,
	    GL_MULTISAMPLESAMPLES,
	    GL_ACCELERATED_VISUAL,
	    GL_SWAP_CONTROL
	};
	
	enum GrabMode : uint {
	  QUERY = -1,
	  OFF = 0,
	  ON = 1
	};
	
	enum Mod : uint {
		KMOD_NONE  = 0x0000,
		KMOD_LSHIFT= 0x0001,
		KMOD_RSHIFT= 0x0002,
		KMOD_LCTRL = 0x0040,
		KMOD_RCTRL = 0x0080,
		KMOD_LALT  = 0x0100,
		KMOD_RALT  = 0x0200,
		KMOD_LMETA = 0x0400,
		KMOD_RMETA = 0x0800,
		KMOD_NUM   = 0x1000,
		KMOD_CAPS  = 0x2000,
		KMOD_MODE  = 0x4000,
		KMOD_RESERVED = 0x8000
	};
	
	enum : uint {
		DISABLE = 0,
		ENABLE = 1
	};
	
	struct Keysym {
		ubyte scancode;
		uint sym;
		Mod mod;
		ushort unicode;
	};
	
	struct ActiveEvent {
		ubyte type;
		ubyte gain;
		ubyte state;
	};
	
	struct KeyboardEvent {
		ubyte type;
		ubyte which;
		ubyte state;
		Keysym keysym;
	};
	
	struct MouseMotionEvent {
		ubyte type;
		ubyte which;
		ubyte state;
		ushort x,y;
		short xrel,yrel;
	};
	
	struct MouseButtonEvent {
		ubyte type;
		ubyte which;
		ubyte button;
		ubyte state;
		ushort x,y;
	};
	
	struct JoyAxisEvent {
		ubyte type;
		ubyte which;
		ubyte axis;
		short value;
	};
	
	struct JoyBallEvent {
		ubyte type;
		ubyte which;
		ubyte ball;
		short xrel;
		short yrel;
	};
	
	struct JoyHatEvent {
		ubyte type;
		ubyte which;
		ubyte hat;
		ubyte value;
	};
	
	struct JoyButtonEvent {
		ubyte type;
		ubyte which;
		ubyte button;
		ubyte state;
	};
	
	struct ResizeEvent {
		ubyte type;
		int width,height;
	};
	
	struct ExposeEvent {
		ubyte type;
	};
	
	struct QuitEvent {
		ubyte type;
	};
	
	struct UserEvent {
		ubyte type;
		int code;
		void *data1;
		void *data2;
	};
	
	struct SysWMEvent {
		ubyte type;
		void *msg;
	};
	
	struct SDL_version {
		ubyte major;
		ubyte minor;
		ubyte patch;
	};
	
	version(Windows){
		struct SysWMinfo{
			SDL_version _version;
			void* window;	/* The display window */
		};
	}
	
	union Event {
		ubyte type;
		ActiveEvent active;
		KeyboardEvent key;
		MouseMotionEvent motion;
		MouseButtonEvent button;
		JoyAxisEvent jaxis;
		JoyBallEvent jball;
		JoyHatEvent jhat;
		JoyButtonEvent jbutton;
		ResizeEvent resize;
		ExposeEvent expose;
		QuitEvent quit;
		UserEvent user;
		SysWMEvent syswm;
	};
	
	enum Eventaction {
		ADDEVENT,
		PEEKEVENT,
		GETEVENT
	};
	
	static void VERSION(SDL_version *v){
		v.major = 1;
		v.minor = 2;
		v.patch = 14;
	}
	
	extern(C){
		//General functions
		alias int function(uint flags) SDL_Init;
		alias int function(uint flags) SDL_InitSubSystem;
		alias int function(uint flags) SDL_QuitSubSystem;
		alias int function(uint flags) SDL_WasInit;
		alias int function() SDL_Quit;
		alias char* function() SDL_GetError;
		
		//Windows specific stuff
		version(Windows){
			alias int function(SysWMinfo *info) SDL_GetWMInfo;
		}
		
		//sdl video
		alias int function(const(char)* driver_name, uint flags) SDL_VideoInit;
		alias int function() SDL_VideoQuit;
		alias Surface* function() SDL_GetVideoSurface;
		alias Rect** function(PixelFormat *format, uint flags) SDL_ListModes;
		alias Surface* function(int width, int height, int bpp, uint flags) SDL_SetVideoMode;
		
		//sdl video gl
		alias int function(const(char)* path) SDL_GL_LoadLibrary;
		alias void* function(const(char)* proc) SDL_GL_GetProcAddress;
		alias int function(GLattr attr, int value) SDL_GL_SetAttribute;
		alias int function(GLattr attr, int* value) SDL_GL_GetAttribute;
		alias int function() SDL_GL_SwapBuffers;		
		
		//sdl timer
		alias int function(uint ms) SDL_Delay;
		
		//sdl event
		alias int function(Event *event) SDL_PollEvent;
		alias int function(Event *event) SDL_WaitEvent;
		alias int function(Event *event) SDL_PushEvent;
		alias int function(int enable) SDL_EnableUNICODE;
		
		//Mouse functions
		alias GrabMode function(GrabMode mode) SDL_WM_GrabInput;
		alias int function(int toggle) SDL_ShowCursor; 
	}
	
	//General sdl functions
	mixin( dll_declare( "SDL_Init" ) );
	mixin( dll_declare( "SDL_InitSubSystem") );
	mixin( dll_declare( "SDL_QuitSubSystem") );
	mixin( dll_declare( "SDL_WasInit") );
	mixin( dll_declare( "SDL_Quit") );
	mixin( dll_declare( "SDL_GetError") );
	
	version(Windows){
		mixin( dll_declare( "SDL_GetWMInfo") );
	}
	
	//sdl video
	mixin( dll_declare( "SDL_VideoInit") );
	mixin( dll_declare( "SDL_VideoQuit") );
	mixin( dll_declare( "SDL_GetVideoSurface") );
	mixin( dll_declare( "SDL_ListModes") );
	mixin( dll_declare( "SDL_SetVideoMode") );
	
	class GL {
		//sdl gl video
		mixin( dll_declare_gl( "SDL_GL_LoadLibrary" ) );
		mixin( dll_declare_gl( "SDL_GL_GetProcAddress" ) );
		mixin( dll_declare_gl( "SDL_GL_SetAttribute" ) );
		mixin( dll_declare_gl( "SDL_GL_GetAttribute" ) );
		mixin( dll_declare_gl( "SDL_GL_SwapBuffers" ) );
	};
	
	//sdl timer
	mixin( dll_declare( "SDL_Delay" ) );
	
	//sdl event
	mixin( dll_declare( "SDL_PollEvent") );
	mixin( dll_declare( "SDL_WaitEvent") );
	mixin( dll_declare( "SDL_PushEvent") );	
	mixin( dll_declare( "SDL_EnableUNICODE") );
	
	//sdl mouse
	mixin( dll_declare("SDL_WM_GrabInput") );
	mixin( dll_declare("SDL_ShowCursor") );
	
	static void LoadDll(string windowsPath, string linuxPath){
		LoadImpl(windowsPath,linuxPath);
		
		//general sdl functions
		mixin( dll_init( "SDL_Init") );
		mixin( dll_init( "SDL_InitSubSystem") );
		mixin( dll_init( "SDL_QuitSubSystem") );
		mixin( dll_init( "SDL_WasInit") );
		mixin( dll_init( "SDL_Quit") );
		mixin( dll_init( "SDL_GetError") );
		
		version(Windows){
			mixin( dll_init( "SDL_GetWMInfo") );
		}
		
		//sdl video
		mixin( dll_init( "SDL_VideoInit") );
		mixin( dll_init( "SDL_VideoQuit") );
		mixin( dll_init( "SDL_GetVideoSurface") );
		mixin( dll_init( "SDL_ListModes") );
		mixin( dll_init( "SDL_SetVideoMode") );
		
		//sdl gl video
		mixin( dll_init_gl( "SDL_GL_LoadLibrary" ) );
		mixin( dll_init_gl( "SDL_GL_GetProcAddress" ) );
		mixin( dll_init_gl( "SDL_GL_SetAttribute" ) );
		mixin( dll_init_gl( "SDL_GL_GetAttribute" ) );
		mixin( dll_init_gl( "SDL_GL_SwapBuffers" ) );
		
		//sdl timer
		mixin( dll_init( "SDL_Delay" ) );
		
		//sdl event
		mixin( dll_init( "SDL_PollEvent") );
		mixin( dll_init( "SDL_WaitEvent") );
		mixin( dll_init( "SDL_PushEvent") );
		mixin( dll_init( "SDL_EnableUNICODE") );
		
		//sdl mouse
		mixin( dll_init("SDL_WM_GrabInput") );
		mixin( dll_init("SDL_ShowCursor") );
	}
	
	static void unload_dll(){
		Unload();
	}
	
	static bool IsDllLoaded(){
		return m_IsLoaded;
	}
	
	enum : uint {
		INIT_TIMER			= 0x00000001,
		INIT_AUDIO			= 0x00000010,
		INIT_VIDEO			= 0x00000020,
		INIT_CDROM			= 0x00000100,
		INIT_JOYSTICK		= 0x00000200,
		INIT_NOPARACHUTE 	= 0x00100000,	/**< Don't catch fatal signals */
		INIT_EVENTTHREAD 	= 0x01000000,	/**< Not supported on all OS's */
		INIT_EVERYTHING		= 0x0000FFFF
	};
	
	enum : uint {
		SWSURFACE 	= 0x00000000,
		HWSURFACE 	= 0x00000001,
		ASYNCBLIT 	= 0x00000004,
		ANYFORMAT 	= 0x10000000,
		HWPALETTE 	= 0x20000000,
		DOUBLEBUF 	= 0x40000000,
		FULLSCREEN	= 0x80000000,
		OPENGL		= 0x00000002,
		OPENGLBLIT	= 0x0000000A,
		RESIZEABLE	= 0x00000010,
		NOFRAME		= 0x00000020,
		HWACCEL		= 0x00000100,
		SRCCOLORKEY = 0x00001000,
		RLEACCELOK  = 0x00002000,
		RLEACCEL	= 0x00004000,
		SRCALPHA	= 0x00010000,
		PREALLOC	= 0x01000000
	};
	
	//SDL events
	enum : uint {
		NOEVENT = 0,
		ACTIVEEVENT,
		KEYDOWN,
		KEYUP,
		MOUSEMOTION,
		MOUSEBUTTONDOWN,
		MOUSEBUTTONUP,
		JOYAXISMOTION,
		JOYBALLMOTION,
		JOYHATMOTION,
		JOYBUTTONDOWN,
		JOYBUTTONUP,
		QUIT,
		SYSWMEVENT,
		EVENT_RESREVEDA,
		EVENT_RESERVEDB,
		VIDEORESIZE,
		VIDEOEXPOSE
	};
	
	enum : ubyte {
		RELEASED = 0,
		PRESSED = 1
	};
};
