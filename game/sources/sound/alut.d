module sound.alut;

import base.sharedlib;
import base.utilsD2;
import sound.openal;

private string dll_declare(string name){
	return "__gshared " ~ name ~ " " ~ name[4..name.length] ~ ";";
}

private string dll_init(string name){
	string sname = name[4..name.length];
	return sname ~ " = cast( typeof ( " ~ sname ~ ") ) GetProc(`" ~ name ~ "`);";
}

class alut {
	mixin SharedLib!();
	
	extern(C){
		alias al.ALboolean function(int *argcp, char **argv) alutInit;
		alias const(char)*  function(al.ALenum error) alutGetErrorString;
		alias al.ALenum function() alutGetError;
		alias al.ALboolean function() alutExit;
	}
	
	//This compile time function generates the function pointer variables	
	mixin( generateDllCode!(alut)(&dll_declare) );
	
	static void LoadDll(string windowsName, string linuxName){
		LoadImpl(windowsName,linuxName);
		//This compile time function generates the calls to load the functions from the dll
		mixin ( generateDllCode!(alut)(&dll_init) );
	}
}
