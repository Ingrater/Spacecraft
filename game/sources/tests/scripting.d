/**
 * A small example on how to use the scripting system to call D functions.
 */

import script.factory;
import std.stdio, std.functional;

void main(){
	auto factory = GetScriptSystemFactory();
	factory.Init();
	auto scripting = factory.GetScriptSystem();
	
	scripting.RegisterGlobal("say", toDelegate(&say));
	
	try {
		scripting.execute(`say("hello")`);
	} catch(ScriptError e) {
		writefln("Scripting error: %s", e);
	}
}

void say(string text){
	writefln("say: %s", text);
}
