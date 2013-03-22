module base.script;


import core.refcounted;
import core.hashmap;
import std.traits;
import thBase.format;
import thBase.policies.hashing;
import core.stdc.string;

alias int delegate() ScriptFunction;

class ScriptError : RCException {
	this(rcstring str){
		super(str);
	}
	
	this(const(char)[] str){
		super(rcstring(str));
	}
}

abstract class IScriptSystem {
protected:
	void RegisterGlobalImpl(string name);
	
public:
	/**
	 * Executes a string as script
	 * Params:
	 *  commands = the string to execute
	 * Throws: ScriptError on error
	 */
	void execute(const(char)[] commands);

  /**
   * Executes a file as script
   * Params:
   *  filename = the file to execute
   * Throws: ScriptError on error
   */
  void executeFile(rcstring filename);

	/**
     * Returns: The script context of this script system
     */
	IScriptContext context();
	
	/**
	 * Registers a new global function, or variable
	 */
	void RegisterGlobal(F)(string name, F func) if(is(F == delegate))
	{
		IScriptContext c = context();
		ScriptFunc!(F) *inst = cast(ScriptFunc!(F)*)c.newUserData((ScriptFunc!(F)).sizeof);
		(*inst).init(c,func);
		RegisterGlobalImpl(name);
	}
	
	/**
	 * Registers a new global variable scope
	 * Returns: the newly registered variable scope
	 */
	ConfigVarsBinding* RegisterVariableScope(string name)
	{
		IScriptContext c = context();
		ConfigVarsBinding* inst = cast(ConfigVarsBinding*)c.newUserData(ConfigVarsBinding.sizeof);
		memset(inst,0,ConfigVarsBinding.sizeof);
		(*inst).init(c);
		RegisterGlobalImpl(name);
		return inst;
	}

  /**
   * tries to autocomplete a given command
   * Params:
   *  command = the command to auto complete
   *  buffers = a preallocated array of rcstrings which will contain the results of the autocompletion
   * Returns: The number of results found and written to buffers
   */
  size_t autocomplete(const(char)[] command, rcstring[] buffers);
}

enum Bind : ushort {
	add, /// + operator
	sub, /// - operator
	mul, /// * operator
	div, /// / operator
	mod, /// % operator
	pow, /// ^ operator
	unm, /// unary -
	concat, /// .. operator
	len, /// # operator
	eq, /// == operator
	lt, /// < operator
	le, /// <= operator
	index, /// table[key]
	newindex, /// table[key] = value
	call, /// () operator
	gc /// destructor
}

struct Binding {
	Bind bind;
	ScriptFunction func;
}

abstract class IScriptContext {
protected:	
	void* newUserData(size_t size);
	void deleteUserData(void *p);
	void createFunctionBinding(string name, ScriptFunction call, ScriptFunction destroy);
	void createBinding(string name, Binding[] binding);
	
	void push(double value);
	void push(bool value);
	void push(rcstring value);

public:
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
	
	int getStackSize();
	bool checkArg(Types type, int n);
	int getInteger(int n);
	double getNumber(int n);
	rcstring getString(int n);
	bool getBool(int n);
	
	int end()(){
		return 0;
	}
	
	int end(T1)(T1 v1){
		push(v1);
		return 1;
	}
	
	int end(T1,T2)(T1 v1, T2 v2){
		push(v1);
		push(v2);
		return 2;
	}
	
	int end(T1,T2,T3)(T1 v1, T2 v3, T3 v3){
		push(v1);
		push(V2);
		push(V3);
		return 3;
	}
	
	int end(T1,T2,T3,T4)(T1 v1, T2 v2, T3 v3, T4 v4){
		push(v1);
		push(v2);
		push(v3);
		push(v4);
		return 4;
	}
}

interface IScriptSystemFactory {
	void Init();
	IScriptSystem NewScriptSystem();
  void DeleteScriptSystem(IScriptSystem system);
}

T checkAndGet(T : int)(IScriptContext c,int n){
	if(!c.checkArg(IScriptContext.Types.NUMBER,n)){
		throw New!ScriptError(format("argument %d has to be a number",n));
	}
	return c.getInteger(n);
}

T checkAndGet(T : float)(IScriptContext c, int n){
	if(!c.checkArg(IScriptContext.Types.NUMBER,n)){
		throw New!ScriptError(format("argument %d has to be a number",n));
	}
	return cast(float)c.getNumber(n);
}

T checkAndGet(T : double)(IScriptContext c, int n){
	if(!c.checkArg(IScriptContext.Types.NUMBER,n)){
		throw New!ScriptError(format("argument %d has to be a number",n));
	}
	return c.getNumber(n);
}

T checkAndGet(T : rcstring)(IScriptContext c, int n){
	if(!c.checkArg(IScriptContext.Types.STRING,n)){
		throw New!ScriptError(format("argument %d has to be a string",n));
	}
	return c.getString(n);
}

T checkAndGet(T : bool)(IScriptContext c, int n){
	if(!c.checkArg(IScriptContext.Types.BOOLEAN,n)){
		throw New!ScriptError(format("argument %d has to be a boolean",n));
	}
	return c.getBool(n);
}

T checkAndGet(T)(IScriptContext c, int n){
	static assert(0,"not supported argument type '" ~ T.stringof ~ "'");
}

struct ScriptFunc(F) 
{
	static assert(is(F == delegate));	
	static assert(ParameterTypeTuple!(F).length <= 9,"Function to bind has to many arguments");
	static assert(is(ReturnType!(F) == void) ||
				  is(ReturnType!(F) == bool) ||
				  is(ReturnType!(F) == double) ||
				  is(ReturnType!(F) == rcstring),"Function to bind can not have a return value of type " ~ ReturnType!(F).stringof);
private:
	F func;
	IScriptContext c;

  private void CheckNumArgs(int numArgs)
  {
    if(c.getStackSize()-1 != numArgs)
    {
      throw New!ScriptError(format("Wrong number of arguments, expected 0, got %d", c.getStackSize()-1));
    }
  }
	
public:
	/**
	 * creates a new lua user data and pushes it onto the lua stack
	 */
	void init(IScriptContext c, F func) {	
		//When the constructor gets called the user data value is already on the lua stack
		this.func = func;
		this.c = c;
		c.createFunctionBinding(typeof(this).stringof, &call!(ParameterTypeTuple!(F)), &destroy);
	}	

	int call()(){
		CheckNumArgs(0);
		static if(is(ReturnType!(F) == void)){
			func();
			return c.end();
		}
		else {
			auto retval = func();
			return c.end(retval);
		}
	}
	
	int call(T1)(){
		CheckNumArgs(1);
		static if(is(ReturnType!(F) == void)){
			func(checkAndGet!(T1)(c,2));
			return c.end();
		}
		else {
			auto retval = func(checkAndGet!(T1)(c,2));
			return c.end(retval);
		}
	}
	
	int call(T1, T2)(){
		CheckNumArgs(2);
		static if(is(ReturnType!(F) == void)){
			func(checkAndGet!(T1)(c,2),checkAndGet!(T2)(c,3));
			return c.end();
		}
		else {
			auto retval = func(checkAndGet!(T1)(c,2),checkAndGet!(T2)(c,3));
			return c.end(retval);
		}
	}
	
	int call(T1, T2, T3)(){
		CheckNumArgs(3);
		static if(is(ReturnType!(F) == void)){
			func(checkAndGet!(T1)(c,2),checkAndGet!(T2)(c,3),checkAndGet!(T3)(c,4));
			return c.end();
		}
		else {
			auto retval = func(checkAndGet!(T1)(c,2),checkAndGet!(T2)(c,3),checkAndGet!(T3)(c,4));
			return c.end();
		}
	}
	
	int call(T1, T2, T3, T4)(){
		CheckNumArgs(4);
		static if(is(ReturnType!(F) == void)){
			func(checkAndGet!(T1)(c,2),checkAndGet!(T2)(c,3),
				 checkAndGet!(T3)(c,4),checkAndGet!(T4)(c,5));
			return c.end();
		}
		else {
			auto retval = func(checkAndGet!(T1)(c,2),checkAndGet!(T2)(c,3),
				 checkAndGet!(T3)(c,4),checkAndGet!(T4)(c,5));
			return c.end(retval);
		}
	}
	
	int call(T1, T2, T3, T4, T5)(){
		CheckNumArgs(5);
		static if(is(ReturnType!(F) == void)){
			func(checkAndGet!(T1)(c,2),checkAndGet!(T2)(c,3),
				 checkAndGet!(T3)(c,4),checkAndGet!(T4)(c,5),
				 checkAndGet!(T5)(c,6));
			return c.end();
		}
		else {
			auto retval = func(checkAndGet!(T1)(c,2),checkAndGet!(T2)(c,3),
				 checkAndGet!(T3)(c,4),checkAndGet!(T4)(c,5),
				 checkAndGet!(T5)(c,6));
			return c.end(retval);
		}
	}
	
	int call(T1, T2, T3, T4, T5, T6)(){
		CheckNumArgs(6);
		static if(is(ReturnType!(F) == void)){
			func(checkAndGet!(T1)(c,2),checkAndGet!(T2)(c,3),
				 checkAndGet!(T3)(c,4),checkAndGet!(T4)(c,5),
				 checkAndGet!(T5)(c,6),checkAndGet!(T6)(c,7));
			return c.end();
		} 
		else {
			auto retval = func(checkAndGet!(T1)(c,2),checkAndGet!(T2)(c,3),
				 checkAndGet!(T3)(c,4),checkAndGet!(T4)(c,5),
				 checkAndGet!(T5)(c,6),checkAndGet!(T6)(c,7));
			return c.end(retval);
		}
	}
	
	int call(T1, T2, T3, T4, T5, T6, T7)(){
		CheckNumArgs(7);
		static if(is(ReturnType!(F) == void)){
			func(checkAndGet!(T1)(c,2),checkAndGet!(T2)(c,3),
				 checkAndGet!(T3)(c,4),checkAndGet!(T4)(c,5),
				 checkAndGet!(T5)(c,6),checkAndGet!(T6)(c,7),
				 checkAndGet!(T7)(c,8));
			return c.end();
		}
		else {
			auto retval = func(checkAndGet!(T1)(c,2),checkAndGet!(T2)(c,3),
				 checkAndGet!(T3)(c,4),checkAndGet!(T4)(c,5),
				 checkAndGet!(T5)(c,6),checkAndGet!(T6)(c,7),
				 checkAndGet!(T7)(c,8));
			return c.end(retval);
		}
	}
	
	int call(T1, T2, T3, T4, T5, T6, T7, T8)(){
		CheckNumArgs(8);
		static if(is(ReturnType!(F) == void)){
			func(checkAndGet!(T1)(c,2),checkAndGet!(T2)(c,3),
				 checkAndGet!(T3)(c,4),checkAndGet!(T4)(c,5),
				 checkAndGet!(T5)(c,6),checkAndGet!(T6)(c,7),
				 checkAndGet!(T7)(c,8),checkAndGet!(T8)(c,9));
			return c.end();
		}
		else {
			auto retval = func(checkAndGet!(T1)(c,2),checkAndGet!(T2)(c,3),
				 checkAndGet!(T3)(c,4),checkAndGet!(T4)(c,5),
				 checkAndGet!(T5)(c,6),checkAndGet!(T6)(c,7),
				 checkAndGet!(T7)(c,8),checkAndGet!(T8)(c,9));
			return c.end(retval);
		}
	}
	
	int call(T1, T2, T3, T4, T5, T6, T7, T8, T9)(){
		CheckNumArgs(9);
		static if(is(ReturnType!(F) == void)){
			func(checkAndGet!(T1)(c,2),checkAndGet!(T2)(c,3),
				 checkAndGet!(T3)(c,4),checkAndGet!(T4)(c,5),
				 checkAndGet!(T5)(c,6),checkAndGet!(T6)(c,7),
				 checkAndGet!(T7)(c,8),checkAndGet!(T8)(c,9),
				 checkAndGet!(T8)(c,10));
			return c.end();
		}
		else {
			auto retval = func(checkAndGet!(T1)(c,2),checkAndGet!(T2)(c,3),
				 checkAndGet!(T3)(c,4),checkAndGet!(T4)(c,5),
				 checkAndGet!(T5)(c,6),checkAndGet!(T6)(c,7),
				 checkAndGet!(T7)(c,8),checkAndGet!(T8)(c,9),
				 checkAndGet!(T8)(c,10));
			return c.end(retval);
		}
	}
	
	int destroy(){
		c.deleteUserData(&this);
		return c.end();
	}
}

struct ConfigVarsBinding {
private:
	IScriptContext c;

  Hashmap!(string, double*, StringHashPolicy) variables;
	
	/**
	 * creates a new lua usderdata and pushes it onto the stack
	 */
	void init(IScriptContext c){
    variables = New!(typeof(variables))();
		this.c = c;
    Binding[3] binding;
    binding[0] = Binding(Bind.index, &index);
    binding[1] = Binding(Bind.newindex, &indexAssign);
    binding[2] = Binding(Bind.gc, &destroy);
		c.createBinding(typeof(this).stringof, binding);
	}

  /**
   * the lua index operator
   **/
	int index(){
		assert(c.getStackSize()-1 == 1);
		rcstring key = checkAndGet!(rcstring)(c,2);
		if(variables.exists(key[])){
			return c.end(*variables[key[]]);
		}
		throw New!ScriptError(format("The variable '%s' does not exist",key[]));
		assert(0,"not reachable");
	}
	
  /**
   * lua index assign operator
   */
	int indexAssign(){
		assert(c.getStackSize()-1 == 2);
		rcstring key = checkAndGet!(rcstring)(c,2);
		double value = checkAndGet!(double)(c,3);
		if(variables.exists( key[] )){
			*variables[ key[] ] = value;
			return c.end();
		}
		throw New!ScriptError(format("The variable '%s' does not exist",key[]));
		assert(0,"not reachable");
	}
	
	int destroy(){
    Delete(variables);
		c.deleteUserData(&this);
		return c.end();
	}

public:

  auto cvars() { return variables; } //TODO make const correct

	void registerVariable(string name, ref double value){
		variables[name] = &value;
	}
}
