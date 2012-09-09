module base.messages;

import std.traits;
import std.typetuple;
import thBase.metatools;
public import thBase.container.queue;

alias ThreadSafeRingBuffer!() MessageQueue_t;

/**
 * Basic message information, every message structure has to start with this as a member
 */
struct BaseMessage
{
  TypeInfo type;
}

/**
 * Warning: Black template magic. Do not read this if you don't like templates
 * Usage:
 *  Sending a message
 *
 *  send(tid,makeMsg(classname,"functionname",arg1,arg2,...);
 *
 *
 *  Receiving a message
 *
 *  receive(
 *    (Msg_t!(classname,"functionname") msg){ msg.call(this); }
 *  );
 *
 *  this calls the function <functionname> assuming you receive the message inside the class <classname>
 *  and passes all the arguments to the function you specified when constructing the message
 */

auto makeMsg(C, string func, T1)(T1 arg1){
	assert(__traits(hasMember,C,func),"The class test does not have a member with the name '" ~ func ~ "'");
	alias typeof(&__traits(getMember,C,func)) T;
	static assert(isFunctionPointer!(T),"first template argument has to be a function. T = " ~ T.stringof);
	alias staticMap!(StoreType,ParameterTypeTuple!(T)) TS;
	static assert(TS.length == 1,"Number of arguments of the given function does not match the given parameters");
	static assert(is(TS[0] == T1),"First argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	return Msg!(C,func,T1)(arg1);
}

auto makeMsg(C, string func, T1, T2)(T1 arg1, T2 arg2){
	assert(__traits(hasMember,C,func),"The class test does not have a member with the name '" ~ func ~ "'");
	alias typeof(&__traits(getMember,C,func)) T;
	static assert(isFunctionPointer!(T),"first template argument has to be a function. T = " ~ T.stringof);
	alias staticMap!(StoreType,ParameterTypeTuple!(T)) TS;
	static assert(TS.length == 2,"Number of arguments of the given function does not match the given parameters");
	static assert(is(TS[0] == T1),"First argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	static assert(is(TS[1] == T2),"Second argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	return Msg!(C,func,T1,T2)(arg1,arg2);
}

auto makeMsg(C, string func, T1, T2, T3)(T1 arg1, T2 arg2, T3 arg3){
	assert(__traits(hasMember,C,func),"The class test does not have a member with the name '" ~ func ~ "'");
	alias typeof(&__traits(getMember,C,func)) T;
	static assert(isFunctionPointer!(T),"first template argument has to be a function. T = " ~ T.stringof);
	alias staticMap!(StoreType,ParameterTypeTuple!(T)) TS;
	static assert(TS.length == 3,"Number of arguments of the given function does not match the given parameters");
	static assert(is(TS[0] == T1),"First argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	static assert(is(TS[1] == T2),"Second argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	static assert(is(TS[2] == T3),"Third argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	return Msg!(C,func,T1,T2,T3)(arg1,arg2,arg3);
}

auto makeMsg(C, string func, T1, T2, T3, T4)(T1 arg1, T2 arg2, T3 arg3, T4 arg4){
	assert(__traits(hasMember,C,func),"The class test does not have a member with the name '" ~ func ~ "'");
	alias typeof(&__traits(getMember,C,func)) T;
	static assert(isFunctionPointer!(T),"first template argument has to be a function. T = " ~ T.stringof);
	alias staticMap!(StoreType,ParameterTypeTuple!(T)) TS;
	static assert(TS.length == 4,"Number of arguments of the given function does not match the given parameters");
	static assert(is(TS[0] == T1),"First argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	static assert(is(TS[1] == T2),"Second argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	static assert(is(TS[2] == T3),"Third argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	static assert(is(TS[3] == T4),"Fourth argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	return Msg!(C,func,T1,T2,T3,T4)(arg1,arg2,arg3,arg4);
}

auto makeMsg(C, string func, T1, T2, T3, T4, T5)(T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5){
	assert(__traits(hasMember,C,func),"The class test does not have a member with the name '" ~ func ~ "'");
	alias typeof(&__traits(getMember,C,func)) T;
	static assert(isFunctionPointer!(T),"first template argument has to be a function. T = " ~ T.stringof);
	alias staticMap!(StoreType,ParameterTypeTuple!(T)) TS;
	static assert(TS.length == 5,"Number of arguments of the given function does not match the given parameters");
	static assert(is(TS[0] == T1),"First argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	static assert(is(TS[1] == T2),"Second argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	static assert(is(TS[2] == T3),"Third argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	static assert(is(TS[3] == T4),"Fourth argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	static assert(is(TS[4] == T5),"Fith argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	return Msg!(C,func,T1,T2,T3,T4,T5)(arg1,arg2,arg3,arg4,arg5);
}

auto makeMsg(C, string func, T1, T2, T3, T4, T5, T6)(T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6){
	assert(__traits(hasMember,C,func),"The class test does not have a member with the name '" ~ func ~ "'");
	alias typeof(&__traits(getMember,C,func)) T;
	static assert(isFunctionPointer!(T),"first template argument has to be a function. T = " ~ T.stringof);
	alias staticMap!(StoreType,ParameterTypeTuple!(T)) TS;
	static assert(TS.length == 6,"Number of arguments of the given function does not match the given parameters");
	static assert(is(TS[0] == T1),"First argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	static assert(is(TS[1] == T2),"Second argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	static assert(is(TS[2] == T3),"Third argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	static assert(is(TS[3] == T4),"Fourth argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	static assert(is(TS[4] == T5),"Fith argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	static assert(is(TS[5] == T6),"Sixth argument does not match in type: " ~ TS[1].stringof ~ " <> " ~ T2.stringof);
	return Msg!(C,func,T1,T2,T3,T4,T5,T6)(arg1,arg2,arg3,arg4,arg5,arg6);
}

template Msg_t(C, string func){
	alias Msg!(C,func,staticMap!(StoreType,ParameterTypeTuple!(typeof(&__traits(getMember,C,func))))) Msg_t;
}

private template TargetType(T){
	static if(is(T == class))
		alias shared(T) TargetType;
	else
		alias T TargetType;
}

private template StoreType(T){
	static if(is(T == class))
		alias T StoreType;
	else
		alias StripConst!(T) StoreType;
}

struct Msg(C,string func,T1){
	alias TargetType!(T1) TT1;
	
  BaseMessage bm;
	TT1 arg1;
	
	this(ref T1 arg1){
    bm.type = typeid(typeof(this));
		this.arg1 = cast(TT1)arg1;
	}
	
	this(ref typeof(this) rh){
    this.bm = rh.bm;
		this.arg1 = rh.arg1;
	}
	
	void call(C c){
		__traits(getMember,c,func)(cast(T1)arg1);
	}
}

struct Msg(C,string func,T1,T2){
	alias TargetType!(T1) TT1;
	alias TargetType!(T2) TT2;
	
  BaseMessage bm;
	TT1 arg1;
	TT2 arg2;
	
	this(ref T1 arg1, ref T2 arg2){
    bm.type = typeid(typeof(this));
		this.arg1 = cast(TT1)arg1;
		this.arg2 = cast(TT2)arg2;
	}
	
	void call(C c){
		__traits(getMember,c,func)(cast(T1)arg1,cast(T2)arg2);
	}
}

struct Msg(C,string func,T1,T2,T3){
	alias TargetType!(T1) TT1;
	alias TargetType!(T2) TT2;
	alias TargetType!(T3) TT3;
	
  BaseMessage bm;
	TT1 arg1;
	TT2 arg2;
	TT3 arg3;
	
	this(ref T1 arg1, ref T2 arg2, ref T3 arg3){
		bm.type = typeid(typeof(this));
    this.arg1 = cast(TT1)arg1;
		this.arg2 = cast(TT2)arg2;
		this.arg3 = cast(TT3)arg3;
	}
	
	void call(C c){
		__traits(getMember,c,func)(cast(T1)arg1,cast(T2)arg2,cast(T3)arg3);
	}
}

struct Msg(C,string func,T1,T2,T3,T4){
	alias TargetType!(T1) TT1;
	alias TargetType!(T2) TT2;
	alias TargetType!(T3) TT3;
	alias TargetType!(T4) TT4;
	
  BaseMessage bm;
	TT1 arg1;
	TT2 arg2;
	TT3 arg3;
	TT4 arg4;
	
	this(ref T1 arg1, ref T2 arg2, ref T3 arg3, ref T4 arg4){
    bm.type = typeid(typeof(this));
		this.arg1 = cast(TT1)arg1;
		this.arg2 = cast(TT2)arg2;
		this.arg3 = cast(TT3)arg3;
		this.arg4 = cast(TT4)arg4;
	}
	
	void call(C c){
		__traits(getMember,c,func)(cast(T1)arg1,cast(T2)arg2,cast(T3)arg3,cast(T4)arg4);
	}
}

struct Msg(C,string func,T1,T2,T3,T4,T5){
	alias TargetType!(T1) TT1;
	alias TargetType!(T2) TT2;
	alias TargetType!(T3) TT3;
	alias TargetType!(T4) TT4;
	alias TargetType!(T5) TT5;
	
  BaseMessage bm;
	TT1 arg1;
	TT2 arg2;
	TT3 arg3;
	TT4 arg4;
	TT5 arg5;
	
	this(ref T1 arg1, ref T2 arg2, ref T3 arg3, ref T4 arg4, ref T5 arg5){
    bm.type = typeid(typeof(this));
		this.arg1 = cast(TT1)arg1;
		this.arg2 = cast(TT2)arg2;
		this.arg3 = cast(TT3)arg3;
		this.arg4 = cast(TT4)arg4;
		this.arg5 = cast(TT5)arg5;
	}
	
	void call(C c){
		__traits(getMember,c,func)(cast(T1)arg1,cast(T2)arg2,cast(T3)arg3,cast(T4)arg4,cast(T5)arg5);
	}
}

struct Msg(C,string func,T1,T2,T3,T4,T5,T6){
	alias TargetType!(T1) TT1;
	alias TargetType!(T2) TT2;
	alias TargetType!(T3) TT3;
	alias TargetType!(T4) TT4;
	alias TargetType!(T5) TT5;
	alias TargetType!(T6) TT6;
	
  BaseMessage bm;
	TT1 arg1;
	TT2 arg2;
	TT3 arg3;
	TT4 arg4;
	TT5 arg5;
	TT6 arg6;
	
	this(ref T1 arg1, ref T2 arg2, ref T3 arg3, ref T4 arg4, ref T5 arg5, ref T6 arg6){
    bm.type = typeid(typeof(this));
		this.arg1 = cast(TT1)arg1;
		this.arg2 = cast(TT2)arg2;
		this.arg3 = cast(TT3)arg3;
		this.arg4 = cast(TT4)arg4;
		this.arg5 = cast(TT5)arg5;
		this.arg6 = cast(TT6)arg6;
	}
	
	void call(C c){
		__traits(getMember,c,func)(cast(T1)arg1,cast(T2)arg2,cast(T3)arg3,cast(T4)arg4,cast(T5)arg5,cast(T6)arg6);
	}
}

unittest {
	class test {
		void foo1(const int a){}
		void foo2(const int a, int b){}
		void foo3(const int a, int b, ref const int c){}
		void foo4(const int a, int b, ref const int c, int d){}
		void foo5(const int a, int b, ref const int c, int d, const int f){}
		void foo6(const int a, int b, ref const int c, int d, const int f, int g){}
	}
	
	int c = 3;
	auto msg1 = makeMsg!(test,"foo1")(1);
	static assert(is(typeof(msg1) == Msg_t!(test,"foo1")));
	assert(msg1.arg1 == 1);
				  
	auto msg2 = makeMsg!(test,"foo2")(1,2);
	static assert(is(typeof(msg2) == Msg_t!(test,"foo2")));
	assert(msg2.arg1 == 1 && msg2.arg2 == 2);
	
	auto msg3 = makeMsg!(test,"foo3")(1,2,c);
	static assert(is(typeof(msg3) == Msg_t!(test,"foo3")));
	assert(msg3.arg1 == 1 && msg3.arg2 == 2 && msg3.arg3 == c);
	
	auto msg4 = makeMsg!(test,"foo4")(1,2,c,4);
	static assert(is(typeof(msg4) == Msg_t!(test,"foo4")));
	assert(msg4.arg1 == 1 && msg4.arg2 == 2 && msg4.arg3 == c && msg4.arg4 == 4);
	
	auto msg5 = makeMsg!(test,"foo5")(1,2,c,4,5);
	static assert(is(typeof(msg5) == Msg_t!(test,"foo5")));
	assert(msg5.arg1 == 1 && msg5.arg2 == 2 && msg5.arg3 == c && msg5.arg4 == 4 && msg5.arg5 == 5);
	
	auto msg6 = makeMsg!(test,"foo6")(1,2,c,4,5,6);
	static assert(is(typeof(msg6) == Msg_t!(test,"foo6")));
	assert(msg6.arg1 == 1 && msg6.arg2 == 2 && msg6.arg3 == c && msg6.arg4 == 4 && msg6.arg5 == 5 && msg6.arg6 == 6);
}