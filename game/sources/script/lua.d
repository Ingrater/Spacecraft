module script.lua;

import thBase.sharedlib;

import std.c.string;

private string dll_declare(string name){
	return "__gshared " ~ name ~ " " ~ name[4..name.length] ~ ";";
}

private string dll_init(string name){
	string sname = name[4..name.length];
	return sname ~ " = cast( typeof ( " ~ sname ~ ") ) GetProc(`" ~ name ~ "`); check("~sname~",`" ~ name ~ "`);";
}

/**
 * binding for lua c library
 */
class Lua {	
	mixin SharedLib!();
	
	alias void* State;
	
	alias double Number;
	alias ptrdiff_t Integer;
	
  struct funcs
  {
    extern(C)
    {
      alias void function(void *ud, void *ptr, size_t osize, size_t nsize) Alloc;
      alias int function(State L) CFunction;
      alias const(char)* function(State L, void *ud, size_t *sz) Reader;
      alias int function(State L, const(void)* p, size_t sz, void* ud) Writer;
      alias void function(State L, Debug* ar) Hook;
    }
  }
	
	enum size_t IDSIZE = 60;
	enum int MULTRET = -1;
	
	enum Types : int {
		NONE = -1,
		NIL = 0,
		BOOLEAN = 1,
		LIGHTUSERDATA = 2,
		NUMBER = 3,
		STRING = 4,
		TABLE = 5,
		FUNCTION = 6,
		USERDATA = 7,
		THREAD = 8
	}

  enum : uint
  {
    YIELD     = 1,
    ERRRUN    = 2,
    ERRSYNTAX = 3,
    ERRMEM    = 4,
    ERRERR    = 5,
    ERRFILE   = 6
  }
	
	enum GC : int {
		STOP = 0,
		RESTART	= 1,
		COLLECT	= 2,
		COUNT = 3,
		COUNTB	= 4,
		STEP = 5,
		SETPAUSE = 6,
		SETSTEPMUL = 7
	}

  enum OP : int
  {
    EQ = 0,
    LT = 1,
    LE = 2
  }
	
	struct Debug {
	  int event;
	  const(char)* name;	/* (n) */
	  const(char)* namewhat;	/* (n) `global', `local', `field', `method' */
	  const(char)* what;	/* (S) `Lua', `C', `main', `tail' */
	  const(char)* source;	/* (S) */
	  int currentline;	/* (l) */
	  int nups;		/* (u) number of upvalues */
	  int linedefined;	/* (S) */
	  int lastlinedefined;	/* (S) */
	  char[IDSIZE] short_src; /* (S) */
	  /* private part */
	  int i_ci;  /* active function */
	}

	enum HOOK : int {
		CALL = 0,
		RET = 1,
		LINE = 2,
		COUNT = 3,
		TAILRET = 4
	}

	enum MASK : int {
		CALL = (1 << HOOK.CALL),
		RET = (1 << HOOK.RET),
		LINE = (1 << HOOK.LINE),
		COUNT = (1 << HOOK.COUNT)
	}


  enum int I_MAXSTACK	=	1000000;
  enum int I_FIRSTPSEUDOIDX	= (-I_MAXSTACK - 1000);
	enum int REGISTRYINDEX = I_FIRSTPSEUDOIDX;

	static int upvalueindex(int i){
		return REGISTRYINDEX - i;
	}	

  enum int RIDX_MAINTHREAD = 1;
  enum int RIDX_GLOBALS	   = 2;
  enum int RIDX_LAST       = RIDX_GLOBALS;
	
	extern(C){		
		/*
		** state manipulation
		*/
		alias State function(funcs.Alloc f, void *ud) lua_newstate;
		alias void   function(State L) lua_close;
		alias State function(State L) lua_newthread;

		alias funcs.CFunction function(State L, funcs.CFunction panicf) lua_atpanic;
		
		/*
		** basic stack manipulation
		*/
		alias int   function(State L) lua_gettop;
		alias void  function(State L, int idx) lua_settop;
		alias void  function(State L, int idx) lua_pushvalue;
		alias void  function(State L, int idx) lua_remove;
		alias void  function(State L, int idx) lua_insert;
		alias void  function(State L, int idx) lua_replace;
		alias int   function(State L, int sz) lua_checkstack;

		alias void  function(State *from, State *to, int n) lua_xmove;
		
		/*
		** access functions (stack -> C)
		*/

		alias int             function(State L, int idx) lua_isnumber;
		alias int             function(State L, int idx) lua_isstring;
		alias int             function(State L, int idx) lua_iscfunction;
		alias int             function(State L, int idx) lua_isuserdata;
		alias int             function(State L, int idx) lua_type;
		alias const(char)*    function(State L, int tp) lua_typename;

		alias int             function(State L, int idx1, int idx2, OP op) lua_compare;
		alias int             function(State L, int idx1, int idx2) lua_rawequal;

		alias Number      function(State L, int idx, int* isnum) lua_tonumberx;
		alias Integer     function(State L, int idx, int* isint) lua_tointegerx;
		alias int             function(State L, int idx) lua_toboolean;
		alias const(char)*    function(State L, int idx, size_t *len) lua_tolstring;
		alias size_t          function(State L, int idx) lua_rawlen;
		alias funcs.CFunction   function(State L, int idx) lua_tocfunction;
		alias void*           function(State L, int idx) lua_touserdata;
		alias State      function(State L, int idx) lua_tothread;
		alias const(void)*    function(State L, int idx) lua_topointer;
		
		/*
		** push functions (C -> stack)
		*/
		alias void   function(State L) lua_pushnil;
		alias void   function(State L, Number n) lua_pushnumber;
		alias void   function(State L, Integer n) lua_pushinteger;
		alias void   function(State L, const(char)* s, size_t l) lua_pushlstring;
		alias void   function(State L, const(char)* s) lua_pushstring;
		//alias const(char)* function(State L, const(char)* fmt,va_list argp) lua_pushvfstring;
		//alias const(char)* function(State L, const(char)* fmt, ...) lua_pushfstring;
		alias void   function(State L, funcs.CFunction fn, int n) lua_pushcclosure;
		alias void   function(State L, int b) lua_pushboolean;
		alias void   function(State L, void *p) lua_pushlightuserdata;
		alias int    function(State L) lua_pushthread;
		
		/*
		** get functions (Lua -> stack)
		*/
		alias void   function(State L, int idx) lua_gettable;
		alias void   function(State L, int idx, const(char)* k) lua_getfield;
		alias void   function(State L, int idx) lua_rawget;
		alias void   function(State L, int idx, int n) lua_rawgeti;
		alias void   function(State L, int narr, int nrec) lua_createtable;
		alias void * function(State L, size_t sz) lua_newuserdata;
		alias int    function(State L, int objindex) lua_getmetatable;
		
		/*
		** set functions (stack -> Lua)
		*/
    alias void   function(State L, const char *var) lua_setglobal;
    alias void   function(State L, int idx) lua_settable;
		alias void   function(State L, int idx, const(char)* k) lua_setfield;
		alias void   function(State L, int idx) lua_rawset;
		alias void   function(State L, int idx, int n) lua_rawseti;
		alias int    function(State L, int objindex) lua_setmetatable;


		/*
		** `load' and `call' functions (load and run Lua code)
		*/
		alias void   function(State L, int nargs, int nresults, int ctx, funcs.CFunction k) lua_callk;
		alias int    function(State L, int nargs, int nresults, int errfunc, int ctx, funcs.CFunction k) lua_pcallk;
		alias int    function(State L, funcs.Reader reader, void *dt, const(char)* chunkname) lua_load;

		alias int  function(State L, funcs.Writer writer, void *data) lua_dump;


		/*
		** coroutine functions
		*/
		alias int   function(State L, int nresults, int ctx, funcs.CFunction k) lua_yieldk;
		alias int   function(State L, int narg) lua_resume;
		alias int   function(State L) lua_status;
		
		/*
		** garbage-collection function
		*/
		alias int  function(State L, int what, int data) lua_gc;
		
		/*
		** miscellaneous functions
		*/
		alias int    function(State L) lua_error;
		alias int    function(State L, int idx) lua_next;
		alias void   function(State L, int n) lua_concat;
		alias funcs.Alloc  function(State L, void **ud) lua_getallocf;
		alias void  function(State L, funcs.Alloc f, void *ud) lua_setallocf;

		/*
		** Debug functions
		*/
		alias int  function(State L, int level, Debug *ar) lua_getstack;
		alias int  function(State L, const(char)* what, Debug *ar) lua_getinfo;
		alias const(char)* function(State L, const Debug *ar, int n) lua_getlocal;
		alias const(char)* function(State L, const Debug *ar, int n) lua_setlocal;
		alias const(char)* function(State L, int funcindex, int n) lua_getupvalue;
		alias const(char)* function(State L, int funcindex, int n) lua_setupvalue;

		alias int  function(State L, funcs.Hook func, int mask, int count) lua_sethook;
		alias funcs.Hook  function(State L) lua_gethook;
		alias int  function(State L) lua_gethookmask;
		alias int  function(State L) lua_gethookcount;
		
		/*
		** auxiliary functions
		*/
		alias int function(State L, const(char)* filename, const(char)* mode) luaL_loadfilex;
		alias int function(State L, const(char)* s) luaL_loadstring;

		alias State function() luaL_newstate;
		alias int   function(State L, const(char)* tname) luaL_newmetatable;
		alias void function(State L) luaL_openlibs; 
	}	
	
	//This compile time function generates the function pointer variables	
	mixin( generateDllCode!(Lua)(&dll_declare) );
	
	//Lua macros
  static void call(State L, int nargs, int nresults)
  {
    callk(L, nargs, nresults, 0, null);
  }

  static int pcall(State L, int nargs, int nresults, int msgh)
  {
    return pcallk(L, nargs, nresults, msgh, 0, null);
  }

  static int yield(State L, int nresults)
  {
    return yieldk(L, nresults, 0, null);
  }

  static int _loadfile(State L, const(char)* filename)
  {
    return _loadfilex(L, filename, null);
  }

	static void pop(State L, int n){
		settop(L, -(n)-1);
	}

	static void newtable(State L){
		createtable(L, 0, 0);
	}
	
	static rcstring tostring(State L, int i){
    size_t len = 0;
		const(char)* str = tolstring(L, i, &len);
		if(len == 0 || str is null)
      return rcstring();
		return rcstring(str[0..len]);
	}
	
	static void pushcfunction(State L, funcs.CFunction f){
		pushcclosure(L, f, 0);
	}
	
	static void register(State L, const(char)* name, funcs.CFunction f){
		pushcfunction(L,f);
		setglobal(L,name);
	}
	
	static bool isfunction(State L, int n){
		return (type(L,n) == Types.FUNCTION);
	}
	
	static bool istable(State L, int n){
		return (type(L,n) == Types.TABLE);
	}
	
	static bool islightuserdata(State L, int n){
		return (type(L,n) == Types.LIGHTUSERDATA);
	}
	
	static bool isnil(State L, int n){
		return (type(L,n) == Types.NIL);
	}
	
	static bool isboolean(State L, int n){
		return (type(L,n) == Types.BOOLEAN);
	}
	
	static bool isthread(State L, int n){
		return (type(L,n) == Types.THREAD);
	}
	
	static bool isnone(State L, int n){
		return (type(L,n) == Types.NONE);
	}
	
	static bool isnoneornil(State L, int n){
		return (type(L,n) <= 0);
	}
	
	private static void check(void* func, string name){
		if(func is null){
			throw new Error("Couldn't find '" ~ name ~ "'");
		}
	}
	
	static void LoadDll(string windowsName, string linuxName){
		LoadImpl(windowsName,linuxName);
		
		//This compile time function generates the calls to load the functions from the dll
		mixin ( generateDllCode!(Lua)(&dll_init) );
		
		assert(pushstring !is null);
	}
}