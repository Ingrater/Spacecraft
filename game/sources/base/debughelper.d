module base.debughelper;

import base.utilsD2;
import thBase.string;

version(Windows){
	extern(System) void OutputDebugStringA(const(char)* str);
	
	void DebugOutput(string str){
		foreach(s;splitLines(str)){
			OutputDebugStringA(toCString(str));
		}
		OutputDebugStringA(toCString("\n"));
	}
}

version(linux){
	void DebugOutput(string str){
		//nirvana
	}
}
