module script.factory;

public import base.script;
import script.lua;
import script.system;

class ScriptSystemFactory : IScriptSystemFactory {
	override void Init(){
		Lua.LoadDll("Lua5.2.dll","./liblua5.2.so.0");
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
