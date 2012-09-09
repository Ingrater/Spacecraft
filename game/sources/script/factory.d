module script.factory;

public import base.script;
import script.lua;
import script.system;

class ScriptSystemFactory : IScriptSystemFactory {
	override void Init(){
		Lua.LoadDll("lua5.1.dll","./liblua5.1.so.0");
	}
	
	override IScriptSystem NewScriptSystem(){
		return new ScriptSystem();
	}

  override void DeleteScriptSystem(IScriptSystem system)
  {
    Delete(system);
  }
}

IScriptSystemFactory NewScriptSystemFactory(){
	return New!ScriptSystemFactory();
}

void DeleteScriptSystemFactory(IScriptSystemFactory factory)
{
  Delete(factory);
}
