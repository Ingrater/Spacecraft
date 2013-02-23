module script.system;

import base.script;
import script.lua;

import base.utilsD2;
import core.memory;
import thBase.format;
import thBase.string;
import thBase.casts;

class ScriptContext : IScriptContext {
private:
	Lua.State L;	
	
	extern(C) static int ScriptProxyFunc(Lua.State L){
		try {
			assert(Lua.isuserdata(L,1));
			void* func = Lua.touserdata(L,Lua.upvalueindex(1));
			void* self = Lua.touserdata(L,1);
			assert(func !is null && self !is null);
			ScriptFunction dg;
			dg.ptr = self;
			dg.funcptr = cast(typeof(dg.funcptr))func;
			return dg();
		}
		catch(Throwable e){
			auto error = format("Exception during execution:\n %s", e.toString()[]);
      Delete(e);
			Lua.pushstring(L, toCString(error));
			Lua.error(L);
		}
		return 0;
	}
	
	string BindString(Bind b){
		mixin(EnumToStringGenerate!(Bind,"__")("b"));
	}
	
protected:
	override void* newUserData(size_t size){
		void* mem = Lua.newuserdata(L,size);
		GC.addRange(mem,size);
		return mem;
	}
	
	override void deleteUserData(void *p){
		GC.removeRange(p);
	}
	
	override void createFunctionBinding(string name, ScriptFunction call, ScriptFunction destroy)
	in{
		assert(call.ptr is destroy.ptr);
	}
	body {
		//Create metatable
		if( Lua._newmetatable(L, toCString(name)) == 1 ){
			int metatable = Lua.gettop(L);
			
			Lua.pushstring(L, toCString("__call"));
			Lua.pushlightuserdata(L, call.funcptr);
			Lua.pushcclosure(L,&ScriptProxyFunc,1);
			Lua.settable(L,metatable);
			
			Lua.pushstring(L, toCString("__gc"));
			Lua.pushlightuserdata(L, destroy.funcptr);
			Lua.pushcclosure(L,&ScriptProxyFunc,1);
			Lua.settable(L,metatable);
		}
		
		Lua.setmetatable(L,-2);	
	}
	
	override void createBinding(string name, Binding[] binding){
		//Create metatable
		if( Lua._newmetatable(L, toCString(name)) == 1 ){
			int metatable = Lua.gettop(L);
			
			foreach(b;binding){
				Lua.pushstring(L,toCString(BindString(b.bind)));
				Lua.pushlightuserdata(L,b.func.funcptr);
				Lua.pushcclosure(L,&ScriptProxyFunc,1);
				Lua.settable(L,metatable);
			}
		}
		
		Lua.setmetatable(L,-2);	
	}
	
	override void push(double value){
		Lua.pushnumber(L,value);
	}
	
	override void push(bool value){
		Lua.pushboolean(L,value);
	}
	
	override void push(rcstring value){
		Lua.pushlstring(L,value.ptr,value.length);
	}
	
public:
	this(Lua.State state){
		L = state;
	}

  ~this()
  {
    Lua.close(L);
  }
	
	override int getStackSize(){
		return Lua.gettop(L);
	}
	
	override bool checkArg(Types type, int n){
		return (type == Lua.type(L,n));
	}
	
	override int getInteger(int n){
		return int_cast!int(Lua.tointeger(L,n));
	}
	
	override double getNumber(int n){
		return Lua.tonumber(L,n);
	}
	
	override rcstring getString(int n){
		return Lua.tostring(L,n);
	}
	
	override bool getBool(int n){
		return (Lua.toboolean(L,n) != 0);
	}
}

class ScriptSystem : IScriptSystem {
private:
	ScriptContext c;
	
	extern(C) static int GenerateDebugInfo(Lua.State L){
	  rcstring errorMessage;
		if(Lua.isstring(L,1))
			errorMessage ~= Lua.tostring(L,1);
		errorMessage ~= "\nTraceback:";
	  Lua.Debug ar;
	  int level = 1;
	  while(Lua.getstack(L,level,&ar) && level < 50){
		Lua.getinfo(L,"nSl",&ar);
		errorMessage ~= format("\n%d: ",level);
		if(ar.source[0] == '@')
		  errorMessage ~= "file:" ~ fromCString(ar.source);
		else
		  errorMessage ~= "string";
		errorMessage ~= format("(%d) ",ar.currentline);
		if(ar.name != null)
		  errorMessage ~= format("%s type: %s",fromCString(ar.name)[],fromCString(ar.namewhat)[]);
		int var = 1;
		int varcount = 1;
		auto varname = fromCString(Lua.getlocal(L,&ar,var));
		while(varname){
		  if(varname != "(*temporary)") {
			if(varcount == 1)
			  errorMessage ~= "\nlocals: ";
			else
			  errorMessage ~= ", ";
			errorMessage ~= varname ~ "=";
			switch(Lua.type(L,-1)){
			  case Lua.Types.NIL:
				errorMessage ~= "nil";
				break;
			  case Lua.Types.BOOLEAN:
				{
				  bool value = (Lua.toboolean(L,-1) != 0);
				  if(value)
					errorMessage ~= "true";
				  else
					errorMessage ~= "false";
				}
				break;
			  case Lua.Types.NUMBER:
				errorMessage ~= format("%f",Lua.tonumber(L,-1));
				break;
			  case Lua.Types.STRING:
				errorMessage ~= "\"" ~ Lua.tostring(L,-1) ~ "\"";
				break;
			  case Lua.Types.TABLE:
				errorMessage ~= "(table)";
				break;
			  case Lua.Types.THREAD:
				errorMessage ~= "(thread)";
				break;
			  case Lua.Types.FUNCTION:
				errorMessage ~= "(function)";
				break;
			  case Lua.Types.LIGHTUSERDATA:
				errorMessage ~= "(lightusderdata)";
				break;
			  case Lua.Types.USERDATA:
				errorMessage ~= "(userdata)";
				break;
			  default:
				errorMessage ~= "(unkown)";
				break;
			}
			varcount++;
		  }
		  Lua.pop(L,1);
		  var++;
		  varname = fromCString(Lua.getlocal(L,&ar,var));
		}
		level++;
	  }
	  errorMessage ~= "\n";
	  Lua.pushstring(L, toCString(errorMessage));
	  return 1;
	}

  private bool isUserDataWithTypename(int index, const(char)[] typename)
  {
		int top = Lua.gettop(c.L);
		scope(exit) Lua.settop(c.L,top);

    mixin(stackCString("typename", "cstr"));
    Lua.getfield(c.L, Lua.REGISTRYINDEX, cstr.ptr);
    assert(Lua.type(c.L, -1) != Lua.Types.NONE && Lua.type(c.L, -1) != Lua.Types.NIL, "type does not exist in registry");
    if( Lua.getmetatable(c.L, index) == 0)
      return false;
    return (Lua.equal(c.L, -1, -2) != 0);
  }

  private bool isUserDataType(T)(int index)
  {
    return isUserDataWithTypename(index, T.stringof);
  }
	
protected:
	override void RegisterGlobalStart(string name){
		Lua.pushstring(c.L, toCString(name));
	}

	override void RegisterGlobalEnd(){
		Lua.settable(c.L,Lua.GLOBALSINDEX);
	}

public:
	this(){
		Lua.State L = Lua._newstate();
		Lua._openlibs(L);
		c = New!ScriptContext(L);
	}

  ~this()
  {
    Delete(c);
  }
	
	override void execute(const(char)[] commands){
		int top = Lua.gettop(c.L);
		scope(exit) Lua.settop(c.L,top);
		
		//logInfo("Executing : %s",commands);
		
		Lua.pushcfunction(c.L,&GenerateDebugInfo);
		int debugfunc = Lua.gettop(c.L);
		int error = Lua._loadstring(c.L,toCString(commands)) || Lua.pcall(c.L,0,Lua.MULTRET,debugfunc);
		if(error != 0){
			if(!Lua.isstring(c.L,-1)){
				throw New!ScriptError(_T("ScriptError without error message"));
			}
			else {
				throw New!ScriptError(Lua.tostring(c.L,-1));
			}	
		}
	}

  override void executeFile(rcstring filename)
  {
		int top = Lua.gettop(c.L);
		scope(exit) Lua.settop(c.L,top);
		Lua.pushcfunction(c.L,&GenerateDebugInfo);
		int debugfunc = Lua.gettop(c.L);
		int error = Lua._loadfile(c.L,toCString(filename)) || Lua.pcall(c.L,0,Lua.MULTRET,debugfunc);
    if(error != 0)
    {
      if(error == Lua.ERRFILE)
      {
        throw New!ScriptError(format("Couldn't read file '%s' for lua execution", filename[]));
      }
			else if(!Lua.isstring(c.L,-1)){
				throw New!ScriptError(_T("ScriptError without error message"));
			}
			else {
				throw New!ScriptError(Lua.tostring(c.L,-1));
			}	
    }
  }
	
	override IScriptContext context(){
		return c;
	}

  override size_t autocomplete(const(char)[] command, rcstring[] buffers)
  {
    sizediff_t scopeEndIndex = command.indexOf('.');
    if(scopeEndIndex == 0) //invalid syntax
      return 0;

    const(char)[] cmdEnd = command[scopeEndIndex+1..$];
    const(char)[] remainingScope = command;

    //make sure we clean the lua c-api scope correctly
    int top = Lua.gettop(c.L);
    scope(exit) Lua.settop(c.L, top);


    int tableIndex = Lua.GLOBALSINDEX;

    while(scopeEndIndex > 0)
    {
      const(char)[] scopeName = remainingScope[0..scopeEndIndex];
      Lua.pushlstring(c.L, scopeName.ptr, scopeName.length);
      Lua.gettable(c.L, tableIndex);
      auto type = Lua.type(c.L, -1);
      //is there no such entry in the current table?
      if(type == Lua.Types.NONE || type == Lua.Types.NIL)
        return 0;

      tableIndex = Lua.gettop(c.L);
      remainingScope = remainingScope[scopeEndIndex+1..$];
      scopeEndIndex = remainingScope.indexOf('.');
      if(scopeEndIndex > 0)
        cmdEnd = remainingScope[scopeEndIndex+1..$];
      else
        cmdEnd = remainingScope;
    }

    int scopeType = Lua.type(c.L, tableIndex);
    if(scopeType == Lua.Types.TABLE)
    {
      Lua.pushnil(c.L);
      size_t i=0;
      while(Lua.next(c.L, tableIndex) && i < buffers.length)
      {
        Lua.pushvalue(c.L, -2); //make a copy of the key
        size_t len = 0;
        const(char)* keyptr = Lua.tolstring(c.L, -1, &len); //convert copy to string
        auto key = keyptr[0..len];
        if(cmdEnd.length == 0)
        {
          buffers[i++] = format("%s%s", command, key);
        }
        else if(startsWith(key, cmdEnd, CaseSensitive.no))
        {
          buffers[i++] = format("%s%s", command[0..$-cmdEnd.length], key);
        }
        Lua.pop(c.L, 2); //pop value and copy of key
      }
      Lua.pop(c.L, 1); //pop key
      return i;
    }
    else if(scopeType == Lua.Types.USERDATA)
    {
      if(isUserDataType!ConfigVarsBinding(tableIndex))
      {
        size_t i=0;
        ConfigVarsBinding* cvars = cast(ConfigVarsBinding*)Lua.touserdata(c.L, tableIndex);
        foreach(string key, double* value; cvars.cvars)
        {
          if(i >= buffers.length)
            return i;
          if(cmdEnd.length == 0)
          {
            buffers[i++] = format("%s%s", command, key);
          }
          else if(startsWith(key, cmdEnd, CaseSensitive.no))
          {
            buffers[i++] = format("%s%s", command[0..$-cmdEnd.length], key);
          }
        }
        return i;
      }
    }
    return 0;
  }
}
