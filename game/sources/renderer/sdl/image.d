module renderer.sdl.image;

import thBase.sharedlib;
import renderer.sdl.main;

private string dll_declare(string name){
	return "__gshared " ~ name ~ " " ~ name[4..name.length] ~ ";";
}

private string dll_init(string name){
	string sname = name[4..name.length];
	return sname ~ " = cast( typeof ( " ~ sname ~ ") ) GetProc(`" ~ name ~ "`);";
}

/**
 * binding for sdl image c library
 */
class SDLImage {	
	mixin SharedLib!();
	
	enum InitFlags
	{
		INIT_JPG = 0x00000001,
		INIT_PNG = 0x00000002,
		INIT_TIF = 0x00000004
	};
	
	extern(C){
		alias int function(int flags) IMG_Init;
		alias SDL.Surface* function(const(char)* filename) IMG_Load;
	}
	
	//This compile time function generates the function pointer variables	
	mixin( generateDllCode!(SDLImage)(&dll_declare) );
	
	static void LoadDll(string windowsName, string linuxName){
		LoadImpl(windowsName,linuxName);
		
		//This compile time function generates the calls to load the functions from the dll
		mixin ( generateDllCode!(SDLImage)(&dll_init) );
		
		Init(InitFlags.INIT_JPG | InitFlags.INIT_PNG | InitFlags.INIT_TIF);
	}
}
