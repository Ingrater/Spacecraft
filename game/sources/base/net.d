module base.net;

import std.typetuple;
import std.traits;

public import thBase.timer;
public import thBase.math3d.vecs, thBase.math3d.mats, thBase.math3d.position;
public import base.socket, base.events;
import thBase.ctfe;
public import thBase.format;
public import thBase.allocator;
import thBase.file;
import core.refcounted;
import core.allocator;
import thBase.ctfe;
import thBase.logging;
import thBase.casts;

import base.all;
import core.stdc.string: memmove, memset;
import core.stdc.stdlib: malloc, free;


// Protocol version of the server and client
enum protocolVersion = 1;
// Type IDs for blocks of the cycle report
enum blockType : ubyte { preSyncEvent, syncData, postSyncEvent };

/**
 * Interface for objects that read and write data from the serializable
 * entities.
 */
interface ISerializer {
	bool serialize(ubyte varId, ref bool value);
	bool serialize(ubyte varId, ref byte value);
	bool serialize(ubyte varId, ref short value);
	bool serialize(ubyte varId, ref int value);
	bool serialize(ubyte varId, ref long value);
	bool serialize(ubyte varId, ref ubyte value);
	bool serialize(ubyte varId, ref ushort value);
	bool serialize(ubyte varId, ref uint value);
	bool serialize(ubyte varId, ref ulong value);
	bool serialize(ubyte varId, ref float value);
	bool serialize(ubyte varId, ref double value);
	bool serialize(ubyte varId, ref Zeitpunkt value);
	bool serialize(ubyte varId, ref vec2 value);
	bool serialize(ubyte varId, ref vec3 value);
	bool serialize(ubyte varId, ref vec4 value);
	bool serialize(ubyte varId, ref mat3 value);
	bool serialize(ubyte varId, ref mat4 value);
	bool serialize(ubyte varId, ref rcstring value);
	bool serialize(ubyte varId, ref Position value);
	bool serialize(ubyte varId, ref EntityId value);
	bool serialize(ubyte varId, ref Quaternion value);
}

/**
 * Interface for entities that want to be synchronized over the network.
 */
interface ISerializeable {
	void serialize(ISerializer ser, bool fullSerialization);
	void resetChangedFlags();
}


//
// Interfaces for event code (message passing)
//

enum EventType {
	preSync,
	postSync
}

interface IEventSink {
	void pushEvent(EntityId objId, EventId eventId, IEvent event, EventType type);
	void pushEvent(EntityId objId, EventId eventId, IEvent event, EventType type, uint clientId);
	// Client only stuff (so much to consistency and encapsulation...)
	@property bool connected();
	@property uint clientId();
}

int NumberOfMessages(C)(){
	int result = 0;
	foreach(funcName;__traits(allMembers,C)){
		static if(funcName != "this" && funcName != "toString" && 
				  funcName != "toHash" && funcName != "opCmp" && 
				  funcName != "opEquals" && funcName != "Monitor" && 
				  funcName != "factory"){
			alias typeof(__traits(getMember,C,funcName)) func_t;
			static if(is(func_t == function)){
				result++;
			}
		}
	}
	return result;
}

string GenerateMsg(H,C,string prefix,int startId)(){
	string result = "";
	int eventId = startId;
	foreach(funcName;__traits(allMembers,C)){
		static if(funcName != "this" && funcName != "toString" && 
				  funcName != "toHash" && funcName != "opCmp" && 
				  funcName != "opEquals" && funcName != "Monitor" && 
				  funcName != "factory"){
			static assert(__traits(compiles,typeof(__traits(getMember,C,funcName))),"Fail at " ~ H.stringof ~ "." ~ C.stringof ~ "." ~ funcName);
			
			alias typeof(__traits(getMember,C,funcName)) func_t;
			static if(is(func_t == function)){
				//Generate the function
				static assert(is(ReturnType!(func_t) == void),funcName ~ " does have a non void return type: " ~ ReturnType!(func_t).stringof);
				result ~= "void " ~ funcName ~ "(";
				foreach(int i,parameter_t;ParameterTypeTuple!(func_t)){
					if(i != 0)
						result ~= ",";
          static assert(!is(parameter_t == string), "parameter " ~ toString(i) ~ " of function " ~ H.stringof ~ "." ~ C.stringof ~ "." ~ funcName ~ " has a invalid type " ~ parameter_t.stringof);
					result ~= parameter_t.stringof ~ " arg" ~ toString(i);
				}
				static if(ParameterTypeTuple!(func_t).length > 0)
					result ~= ",";
				result ~= "EventType type, int clientId = -1) {\n";
        result ~= "#line " ~ toString(__LINE__+1) ~ " \"" ~ __FILE__ ~ "\"\n";
				result ~= "auto msg = AllocatorNew!(" ~ prefix ~ "Msg" ~ toString(eventId) ~ ")(ThreadLocalStackAllocator.globalInstance";
				for(int i;i<ParameterTypeTuple!(func_t).length;i++){
					result ~= ", arg" ~ toString(i);
				}
				result ~= ");\n";
        result ~= "#line " ~ toString(__LINE__+1) ~ " \"" ~ __FILE__ ~ "\"\n";
        result ~= "scope(exit) AllocatorDelete(ThreadLocalStackAllocator.globalInstance, msg);\n";
        result ~= "#line " ~ toString(__LINE__+1) ~ " \"" ~ __FILE__ ~ "\"\n";
				result ~= "auto eventSink = this.outer.m_Game.eventSink();\n";
        result ~= "#line " ~ toString(__LINE__+1) ~ " \"" ~ __FILE__ ~ "\"\n";
				result ~= "if (clientId == -1)\n";
				result ~= "  eventSink.pushEvent(this.outer.entityId(), EventId(" ~ toString(eventId) ~ "), msg, type);\n";
				result ~= "else\n";
				result ~= "  eventSink.pushEvent(this.outer.entityId(), EventId(" ~ toString(eventId) ~ "), msg, type, clientId);\n";
				result ~= "}\n";
				
				
				//Generate the message type
				result ~= "static class " ~ prefix ~"Msg" ~ toString(eventId) ~ " : IEvent { \n";
				result ~= H.stringof ~ "." ~ C.stringof ~ " m_Ref;\n";
				foreach(int i,parameter_t;ParameterTypeTuple!(func_t)){
					result ~= parameter_t.stringof ~ " arg" ~ toString(i) ~ ";\n";
				}
				//Generate constructor
        result ~= "#line " ~ toString(__LINE__+1) ~ " \"" ~ __FILE__ ~ "\"\n";
				result ~= "this(" ~ H.stringof ~ "." ~ C.stringof ~ " pref){m_Ref = pref;}\n";
        result ~= "#line " ~ toString(__LINE__+1) ~ " \"" ~ __FILE__ ~ "\"\n";
				result ~= "this(";
				foreach(int i,parameter_t;ParameterTypeTuple!(func_t)){
					if(i != 0)
						result ~= ",";
					result ~= parameter_t.stringof ~ " arg" ~ toString(i);
				}
				result ~= "){\n";
				for(int i;i<ParameterTypeTuple!(func_t).length;i++){
					result ~= "this.arg" ~ toString(i) ~ " = arg" ~ toString(i) ~ ";\n";
				}
				result ~= "}\n";
				
				//Generate serialize method
        result ~= "#line " ~ toString(__LINE__+1) ~ " \"" ~ __FILE__ ~ "\"\n";
				result ~= "override void serialize(ISerializer ser, bool fullSerialization){\n";
				for(int i;i<ParameterTypeTuple!(func_t).length;i++){
					result ~= "ser.serialize(cast(ubyte)" ~ toString(i) ~ ",arg" ~ toString(i) ~ ");\n";
				}
				result ~= "}\n";
				
				result ~= "override void resetChangedFlags(){}\n";
				
				//Generate call method
        result ~= "#line " ~ toString(__LINE__+1) ~ " \"" ~ __FILE__ ~ "\"\n";
				result ~= "override void call(){\n";
				result ~= "m_Ref." ~ funcName ~ "(";
				for(int i;i<ParameterTypeTuple!(func_t).length;i++){
					if(i > 0)
						result ~= ",";
					result ~= "arg" ~ toString(i);
				}
				result ~= ");\n}\n";

        //Generate toString method
        result ~= "override string description(){";
        result ~= "return \"" ~ H.stringof ~ "." ~ C.stringof ~ "." ~ funcName ~"\"; }";
				
				result ~= "}\n";
			}
			eventId++;
		}
	}
	return result;
}

string GenerateConstruct(H,Cl,Sv,string ClPrefix,string SvPrefix)(){
	string result;
	int eventId = 0;
	
	result = "switch(eventId.id){\n";
	
	foreach(funcName;__traits(allMembers,Cl)){
		static if(funcName != "this" && funcName != "toString" && 
				  funcName != "toHash" && funcName != "opCmp" && 
				  funcName != "opEquals" && funcName != "Monitor" && 
				  funcName != "factory")
		{
			alias typeof(__traits(getMember,Cl,funcName)) func_t;
			static if(is(func_t == function)){
				result ~= "case " ~ toString(eventId) ~ ":\n";
        result ~= "#line " ~ toString(__LINE__+1) ~ " \"" ~ __FILE__ ~ "\"\n";
				result ~= "return AllocatorNew!(toClient." ~ ClPrefix ~ "Msg" ~ toString(eventId) ~ ")(allocator, m_ClientMsgs);\n";
				eventId++;
			}
		}
	}
	
	foreach(funcName;__traits(allMembers,Sv)){
		static if(funcName != "this" && funcName != "toString" && 
				  funcName != "toHash" && funcName != "opCmp" && 
				  funcName != "opEquals" && funcName != "Monitor" && 
				  funcName != "factory")
		{
			alias typeof(__traits(getMember,Sv,funcName)) func_t;
			static if(is(func_t == function)){
				result ~= "case " ~ toString(eventId) ~ ":\n";
        result ~= "#line " ~ toString(__LINE__+1) ~ " \"" ~ __FILE__ ~ "\"\n";
				result ~= "return AllocatorNew!(toServer." ~ SvPrefix ~ "Msg" ~ toString(eventId) ~ ")(allocator, m_ServerMsgs);\n";
				eventId++;
			}
		}
	}
	
	result ~= "default: auto msg = format(\"unkown event id %d\",eventId.id); assert(0,msg[]);\n}\n";
	return result;
}

private template MemberFunctions(C){
	alias MemberFunctionsImpl!(C,__traits(allMembers,C)).result result;
}

private template MemberFunctionsImpl(C,string NAME, NAME_REST...){
	static if(is(typeof(__traits(getMember,C,NAME)) == function)){
		static if(NAME_REST.length > 0)
			alias TypeTuple!(typeof(__traits(getMember,C,NAME)),MemberFunctionsImpl!(C,NAME_REST).result[0..$]) result;
		else
			alias TypeTuple!(typeof(__traits(getMember,C,NAME))) result;
	}
	else {
		static if(NAME_REST.length > 0)
			alias MemberFunctionsImpl!(C,NAME_REST).result result;
		else
			alias TypeTuple!() result;
	}
}

struct output(string message)
{
  pragma(msg,message);
}

mixin template MessageCode(){
	alias typeof(this) C;

  static struct MessageDeinitHelper
  {
    C m_outer;

    this(C outer)
    {
      m_outer = outer;
    }

    ~this()
    {
      //BUG 11246
      //assert(m_outer !is null, "Messaging has not been initialized");
      if(m_outer !is null)
        m_outer.DoDeinitMessaging();
      debug m_outer = null;
    }
  }
	
	static assert(__traits(hasMember,C,"ClientMsgs"),C.stringof ~ " does not have a ClientMsgs inner class");
	static assert(__traits(hasMember,C,"ServerMsgs"),C.stringof ~ " does not have a ServerMsgs inner class");
	
	static assert(is(C.ClientMsgs == class),C.stringof ~ ": ClientMsgs is not a class: " ~ C.ClientMsgs.stringof);
	static assert(is(C.ServerMsgs == class),C.stringof ~ ": ServerMsgs is not a class: " ~ C.ServerMsgs.stringof);
	
	public CToClient toClient = null;
	public CToServer toServer = null;
	private C.ClientMsgs m_ClientMsgs = null;
	private C.ServerMsgs m_ServerMsgs = null;
  private MessageDeinitHelper m_MessageDeinitHelper;
	
	private class CToClient {
		//output!(GenerateMsg!(C,C.ClientMsgs,"Client",0)()) blup;
		mixin(GenerateMsg!(C,C.ClientMsgs,"Client",0)());
	}
	
	private class CToServer {
		//output!(GenerateMsg!(C,C.ServerMsgs,"Server",NumberOfMessages!(C.ClientMsgs)())()) blup;
		mixin(GenerateMsg!(C,C.ServerMsgs,"Server",NumberOfMessages!(C.ClientMsgs)()));
	}
	
	public override IEvent constructEvent(EventId eventId, IAllocator allocator){
		//output!(GenerateConstruct!(C,C.ClientMsgs,C.ServerMsgs,"Client","Server")()) blup;
		mixin(GenerateConstruct!(C,C.ClientMsgs,C.ServerMsgs,"Client","Server")());
	}
	
	private void InitMessaging(){
    toClient = new CToClient();
		toServer = new CToServer();
		m_ClientMsgs = new ClientMsgs();
		m_ServerMsgs = new ServerMsgs();
    m_MessageDeinitHelper = MessageDeinitHelper(this);
	}

  private void DoDeinitMessaging()
  {
    Delete(toClient);
    Delete(toServer);
    Delete(m_ClientMsgs);
    Delete(m_ServerMsgs);
  }
}

mixin template DummyMessageCode(){
	public override IEvent constructEvent(EventId eventId, IAllocator allocator){
		assert(0,"not implemented");
	}
}


//
// Stuff for game object interaction with the net code
//

struct netvar(T) {
  static assert(!is(T == string), T.stringof ~ " is a invalid netvar type");
	T value;
	alias value this;
	bool changed = true;
	
	void opAssign(T newVal){
		if (newVal != value) {
			changed = true;
			value = newVal;
		}
	}
	
	/**
	 * Should mark the netvar as changed when operators like -= or += are used.
	 * DOES NOT WORK! Maybe a bug in D but the value of the variable is not
	 * changed.
	 */
	void opOpAssign(string op, U)(U newVal){
		if (newVal != value){
			changed = true;
			mixin("value = value " ~ op ~ " newVal;");
		}
	}
}

unittest
{
  netvar!float v1;
  netvar!float v2;

  v1.changed = false;
  v2.changed = false;

  v1 = 0.0f;
  assert(v1.changed == true, "opAssign does not work on netvar");

  v2 += 1.0f;
  assert(v2.changed == true, "opOpAssign does not work on netvar");
}

template isNetvar(T){
	enum bool isNetvar = false;
}

template isNetvar(T : netvar!(U),U){
	enum bool isNetvar = true;
}

unittest
{
  static assert(isNetvar!(netvar!int) == true);
  static assert(isNetvar!(netvar!float) == true);
  static assert(isNetvar!(float) == false);
}

mixin template MakeSerializeable() {
	alias typeof(this) T;
	
	/**
	 * Calls `serialize()` for each net var of the class this mixin is mixed into.
	 */
	override void serialize(ISerializer ser, bool fullSerialization){
		ubyte varId = 0;
		
		foreach(member; __traits(allMembers,T)){
			static if( (member.length < 2 || member[0..2] != "__") && member != "Monitor" && member != "ServerMsgs" && member != "ClientMsgs" ){
				static if(__traits(compiles,typeof(__traits(getMember, T, member)))){
					alias typeof(__traits(getMember, T, member)) MT;
					static if(isNetvar!(MT)){
						if(fullSerialization || __traits(getMember, this, member).changed){
							bool sourceChanged = ser.serialize(varId, __traits(getMember, this, member).value);
							if (sourceChanged)
								__traits(getMember, this, member).changed = true;
						}
						varId++;
					}
					assert(varId <= ubyte.max, "to many variables");
				}
			}
		}
	}
	
	/**
	 * Resets the changed flag of all net vars to `false`.
	 * 
	 * TODO: Investigate if the changed flag reset really works. If the getMember
	 * trait returns a copy of the netvar the changed flag will not be reset on
	 * the original. The generated cycle reports look like there is always a full
	 * serialization.
	 */
	override void resetChangedFlags(){
		foreach(member; __traits(allMembers, T)){
			static if( (member.length < 2 || member[0..2] != "__") && member != "Monitor" && member != "ServerMsgs" && member != "ClientMsgs" ){
				static if(__traits(compiles,typeof(__traits(getMember, T, member)))){
					static if(isNetvar!(typeof(__traits(getMember, T, member))))
						__traits(getMember, this, member).changed = false;
				}
			}
		}
	}
}


//
// Writer and Reader for buffers. These buffer then travel over the wire.
//

/**
 * Writer for a raw data buffer. It's the job of the writer to manage that the
 * data is written at the right position and in the correct format into the
 * buffer.
 */
class BufferWriter : ISerializer {
	private void[] buffer;
	private uint pos;
	
	// A stack with the positions of the first field (the length) of the currently
	// started blocks. As soon as a block is finished the length of that block is
	// written to that position and it is popped off the stack.
	uint[] block_start_pos;
	// The current block nesting level. Used as an index for the block_length_pos
	// stack.
	ubyte block_level = 0;
	
	this(void[] buffer){
		this.buffer = buffer;
		block_start_pos = NewArray!uint(2);
		reset();
	}

  ~this()
  {
    Delete(block_start_pos);
  }
	
	/**
	 * Resets the writer to continue writer after `valid_bytes_in_buffer`. Meant
	 * to be called after the buffer was send over the network and is free for new
	 * data. `valid_bytes_in_buffer` is the number of bytes that could not be send
	 * and therefore the writer has to continue writing new data directly after
	 * that.
	 */
	void reset(uint valid_bytes_in_buffer = 0){
		pos = valid_bytes_in_buffer;
		block_level = 0;
		debug(net) base.logger.test("net: writer reset, valid_bytes_in_buffer: %s", valid_bytes_in_buffer);
	}
	
	/**
	 * Mixin template for value type serialization (byte, short, etc.). Generates
	 * a method that copies the specified varID and value into the buffer.
	 * Basically this works for every type that can be pushed directly into the
	 * buffer with push().
	 */
	mixin template BasicTypeSerialize(T) {
		override bool serialize(ubyte varId, ref T value){
			push!ubyte(varId);
			push!T(value);
			return false;
		}
	}
	
	mixin BasicTypeSerialize!(bool) M1;
  alias M1.serialize serialize;
	mixin BasicTypeSerialize!(byte) M2;
  alias M2.serialize serialize;
	mixin BasicTypeSerialize!(short) M3;
  alias M3.serialize serialize;
	mixin BasicTypeSerialize!(int) M4;
  alias M4.serialize serialize;
	mixin BasicTypeSerialize!(long) M5;
  alias M5.serialize serialize;
	mixin BasicTypeSerialize!(ubyte) M6;
  alias M6.serialize serialize;
	mixin BasicTypeSerialize!(ushort) M7;
  alias M7.serialize serialize;
	mixin BasicTypeSerialize!(uint) M8;
  alias M8.serialize serialize;
	mixin BasicTypeSerialize!(ulong) M9;
  alias M9.serialize serialize;
	mixin BasicTypeSerialize!(float) M10;
  alias M10.serialize serialize;
	mixin BasicTypeSerialize!(double) M11;
  alias M11.serialize serialize;
	mixin BasicTypeSerialize!(rcstring) M12;
  alias M12.serialize serialize;
	mixin BasicTypeSerialize!(EntityId) M13;
  alias M13.serialize serialize;
	
	
	/**
	 * Serializes a point in time into the send buffer. Only works for Zeitpunkt
	 * instances that use the main timer.
	 */
	override bool serialize(ubyte varId, ref Zeitpunkt value){
		push!ubyte(varId);
		push!ulong(value.getMilliseconds(g_Env.mainTimer));
		return false;
	}
	
	
	/**
	 * Mixin template that generates a method that serializes the vector and
	 * matrix types. Each of them allows access to it's components though the
	 * array `f`. This allows to handle them in the same way.
	 */
	mixin template MathTypeSerialize(T) {
		override bool serialize(ubyte varId, ref T value){
			push!ubyte(varId);
			foreach(elem; value.f)
				push!float(elem);
			return false;
		}
	}
	
	mixin MathTypeSerialize!(vec2);
	mixin MathTypeSerialize!(vec3);
	mixin MathTypeSerialize!(vec4);
	mixin MathTypeSerialize!(mat3);
	mixin MathTypeSerialize!(mat4);
	
	
	/**
	 * Serializes a position into the buffer. The position is stored as the cell
	 * vector followed by the relative position vector.
	 */
	override bool serialize(ubyte varId, ref Position value){
		push!ubyte(varId);
		foreach(elem; value.cell.f)
			push(elem);
		foreach(elem; value.relPos.f)
			push!float(elem);
		return false;
	}
	
	/**
	 * Serializes a quaternion into the buffer.
	 */
	override bool serialize(ubyte varId, ref Quaternion value){
		push!ubyte(varId);
		push!float(value.x);
		push!float(value.y);
		push!float(value.z);
		push!float(value.angle);
		return false;
	}

	
	/**
	 * Pushes a value into the buffer at the current position. Basic types like
	 * int are copied into the buffer as they are. Strings are pushed as a length
	 * followed by this amount of bytes of data.
	 */
	void push(T)(T val){
		static if ( __traits(isScalar, T) || is(T == EntityId) || is(T == EventId) ) {
			assert(pos + T.sizeof <= buffer.length, "BufferWriter, push: no space left in the buffer!");
			*( cast(T*)(buffer.ptr + pos) ) = val;
			debug(net) base.logger.test("net: %5d > %s %10s: %s (length: %d)", pos, replicate("|", block_level), T.stringof, val, T.sizeof);
			pos += T.sizeof;
		} else static if ( is(T == rcstring) ) {
			assert(pos + uint.sizeof + val.length <= buffer.length, "BufferWriter, push: no space left in the buffer!");
			push!uint(int_cast!uint(val.length));
			buffer[pos .. pos + val.length] = (cast(void[])(val[]))[];
			debug(net) base.logger.test("net: %5d > %s %10s: %s (length: %d)", pos, replicate("|", block_level), T.stringof, val, val.length);
			pos += val.length;
		} else {
			static assert(0, "BufferWriter, push: tried to use push with an unsupported type: " ~ T.stringof);
		}
	}
	
	/**
	 * Returns the valid data written into the buffer.
	 */
	void[] data(){
		return buffer[0..pos];
	}
	
	/**
	 * Starts a new block. Leaves room for a length field and remembers the start
	 * position of the block in an internal stack. When the block is ended with a
	 * call to finishBlock() the length of the block is written at the rememberd
	 * position.
	 */
	void startBlock(){
		assert(block_level < block_start_pos.length,
			"BufferWriter, startBlock: tried to start a nested block with a to deep nesting level");
		debug(net) base.logger.test("net: %5d > %s-- block start --", pos, replicate("|", block_level));
		block_start_pos[block_level] = pos;
		block_level++;
		pos += uint.sizeof;
	}
	
	/**
	 * Finished a block and writes the block length at the remembered block.
	 * Params:
	 *  throwAway = if true the block gets reverted
	 */
	void finishBlock(bool throwAway = false){
		assert(block_level > 0,
			"BufferWriter, finishBlock: tried to finish a block that was not started. Looks like a nesting error.");
		block_level--;
		if(!throwAway){
			uint length = pos - block_start_pos[block_level] - cast(uint)(uint.sizeof);
			if(length != 0){
				*( cast(uint*)(buffer.ptr + block_start_pos[block_level]) ) = length;
				debug(net) base.logger.test("net: %5d > %s-- block end, length: %d --", pos, replicate("|", block_level), length);
				return;
			}
		}
		debug(net) base.logger.test("net: throw away %d -> %d",pos,block_start_pos[block_level]);
		pos = block_start_pos[block_level];
	}
	
	/**
	 * Returns the current position in the buffer
	 */
	uint curPos(){
		return pos;
	}
}

unittest {
	ubyte[] test_buffer = NewArray!ubyte(13);
	auto writer = New!BufferWriter(test_buffer);
  scope(exit)
  {
    Delete(writer);
    Delete(test_buffer);
  }
	
	writer.push!ubyte(1);
	assert(writer.data == x"01");
	writer.push!uint(2);
	assert(writer.data == x"01 02000000");
	writer.push!ulong(3);
	assert(writer.data == x"01 02000000 03000000 00000000");
	
	test_buffer[] = 0;
  Delete(writer);
	writer = New!BufferWriter(test_buffer);
	writer.startBlock();
	assert(writer.data == x"00000000");
	writer.push!ubyte(2);
	assert(writer.data == x"00000000 02");
	writer.finishBlock();
	assert(writer.data == x"01000000 02");
}


/**
 * Reader for the network buffers that have been written with BufferWriter.
 */
class BufferReader : ISerializer {
	private void[] buffer;
	private uint pos;
	private uint content_length;
	
	// Stack that contains the end boundaries of the blocks we are currently in.
	private uint[] block_limits;
	// Current nesting depth of the blocks.
	private ubyte block_level = 0;
	private int remembered_pos = -1;
	private uint[] remembered_block_limits;
	private ubyte remembered_block_level = 0;
	
	this(void[] buffer, uint content_length = 0){
		this.buffer = buffer;
		block_limits = NewArray!uint(2);
    remembered_block_limits = NewArray!uint(2);
		reset(content_length);
	}

  ~this()
  {
    Delete(block_limits);
    Delete(remembered_block_limits);
  }
	
	/**
	 * Resets all internal reader state and updates the length of the valid
	 * content. Basically it's the same as constructing a new reader but reuses
	 * the current object.
	 */
	void reset(uint new_content_length){
		debug(net) base.logger.test("net: reader reset, new content length: %s", new_content_length);
		assert(new_content_length <= buffer.length,
			"net: content length of buffer can not be larger than the buffer itself");
		content_length = new_content_length;
		pos = 0;
		block_level = 0;
		forgetPos();
	}
	
	/**
	 * Markes the specified number of bytes directly after the used buffer space
	 * as valid content. Effectively this extends the content length by the
	 * specified number of bytes.
	 */
	void expand(uint number_of_added_bytes){
		debug(net) base.logger.test("net: reader expand, content_length: %s, added bytes: %s, new length: %s",
			content_length, number_of_added_bytes, content_length + number_of_added_bytes);
		assert(content_length + number_of_added_bytes <= buffer.length,
			"net: tried to extend the content length of the reader above the buffer length");
		content_length += number_of_added_bytes;
	}
	
	/**
	 * Checks if the current position is at the end of buffer. If it returns
	 * `true` a call to peek() or shift() will fail.
	 */
	bool atEndOfBuffer(){
		return (pos >= content_length) || (block_level > 0 && pos >= block_limits[block_level-1]);
	}
	
	/**
	 * Interprets the current position as a serialized field (one byte defining
	 * the field number followed by the field data) and decides if it should be
	 * skipped or not.
	 * 
	 * Ignore any calls to serialize if we are at the end of the buffer. Also
	 * ignore fields with a varId smaller than the requested one so we will
	 * silently skip ommited fields.
	 */
	bool shouldSkipSerializeField(ubyte varId){
		if (atEndOfBuffer() || varId < peek!ubyte())
			return true;
	
		if (varId > peek!ubyte()){
			logError("server net: expected varId %s but got %s", varId, peek!ubyte());
			return true;
		}
		
		return false;
	}
	
	/**
	 * Generates a serialize method that reads basic types (byte, short, etc.)
	 * from the buffer into the specified value parameter. If the varId does not
	 * match the varId at the current buffer position a warning is send and the
	 * method does nothing. The idea behind this behaviour is to make the netcode
	 * more robust. Reading unknown fields is ignored but new fields in the data
	 * stream will prevent the client from reading the rest of the block.
	 */
	mixin template BasicTypeSerialize(T) {
		override bool serialize(ubyte varId, ref T value){
			if ( shouldSkipSerializeField(varId) )
				return false;
			
			// Throw the verified varId away and read the value
			shift!ubyte();
			
			// Only set the value of the new value is different from the current one
			auto newVal = shift!T();
			if (value != newVal){
				value = newVal;
				return true;
			}
			
			return false;
		}
	}
	
	mixin BasicTypeSerialize!(bool) M1;
  alias M1.serialize serialize;
	mixin BasicTypeSerialize!(byte) M2;
  alias M2.serialize serialize;
	mixin BasicTypeSerialize!(short) M3;
  alias M3.serialize serialize;
	mixin BasicTypeSerialize!(int) M4;
  alias M4.serialize serialize;
	mixin BasicTypeSerialize!(long) M5;
  alias M5.serialize serialize;
	mixin BasicTypeSerialize!(ubyte) M6;
  alias M6.serialize serialize;
	mixin BasicTypeSerialize!(ushort) M7;
  alias M7.serialize serialize;
	mixin BasicTypeSerialize!(uint) M8;
  alias M8.serialize serialize;
	mixin BasicTypeSerialize!(ulong) M9;
  alias M9.serialize serialize;
	mixin BasicTypeSerialize!(float) M10;
  alias M10.serialize serialize;
	mixin BasicTypeSerialize!(double) M11;
  alias M11.serialize serialize;
	mixin BasicTypeSerialize!(rcstring) M12;
  alias M12.serialize serialize;
	mixin BasicTypeSerialize!(EntityId) M13;
  alias M13.serialize serialize;
	
	
	/**
	 * Updates the specified Zeitpunkt instance with the value from the buffer.
	 * Only works for Zeitpunkt instances that use the main timer.
	 */
	override bool serialize(ubyte varId, ref Zeitpunkt value){
		if ( shouldSkipSerializeField(varId) )
			return false;
		
		shift!ubyte();
		value.setMilliseconds( shift!ulong(), g_Env.mainTimer );
		return true;
	}
	
	/**
	 * Reads the vector and matrix types. Each of them allows access to it's
	 * components though the array `f`. This allows to handle them in the same
	 * way.
	 */
	mixin template MathTypeSerialize(T) {
		override bool serialize(ubyte varId, ref T value){
			if ( shouldSkipSerializeField(varId) )
				return false;
			
			shift!ubyte();

      // BUG 11245
			//float[T.f.length] newValues;
			//foreach(ref elem; newValues)
				//elem = shift!float();

      T newValue;
      foreach(ref elem; newValue.f)
        elem = shift!float();
			
			if (value.f != newValue.f){
				value.f[] = newValue.f[];
				return true;
			}
			
			return false;
		}
	}
	
	mixin MathTypeSerialize!(vec2);
	mixin MathTypeSerialize!(vec3);
	mixin MathTypeSerialize!(vec4);
	mixin MathTypeSerialize!(mat3);
	mixin MathTypeSerialize!(mat4);
	
	
	/**
	 * Reads a position from the buffer. The position is stored as the cell vector
	 * followed by the relative position vector.
	 */
	override bool serialize(ubyte varId, ref Position value){
		if ( shouldSkipSerializeField(varId) )
			return false;
		
		shift!ubyte();
		
		Position newValue;
		foreach(ref elem; newValue.cell.f)
			elem = shift!(typeof(elem))();
		foreach(ref elem; newValue.relPos.f)
			elem = shift!float();
		
		if (value != newValue){
			value = newValue;
			return true;
		}
		
		return false;
	}
	
	/**
	 * Reads a quaternion from the buffer.
	 */
	override bool serialize(ubyte varId, ref Quaternion value){
		if ( shouldSkipSerializeField(varId) )
			return false;
		
		shift!ubyte();
		
		Quaternion newValue;
		newValue.x = shift!float();
		newValue.y = shift!float();
		newValue.z = shift!float();
		newValue.angle = shift!float();
		
		if (value != newValue){
			value = newValue;
			return true;
		}
		
		return false;
	}
	
	/**
	 * Pushes an value type into the buffer at the current position.
	 */
	T shift(T)()
	{
		static if ( __traits(isScalar, T) || is( T == EntityId) || is(T == EventId) ) {
			auto val = peek!T();
			debug(net) base.logger.test("net: %5d < %s %10s: %s (length: %d)", pos, replicate("|", block_level), T.stringof, val, T.sizeof);
			pos += T.sizeof;
			return val;
		} else static if ( is(T == rcstring) ) {
			uint len = peek!uint();
			assert(pos + uint.sizeof + len <= buffer.length, "BufferReader, shift: not enought data in the buffer to read the string!");
			pos += uint.sizeof;
			auto val = cast(char[]) buffer[pos .. pos + len];
			debug(net) base.logger.test("net: %5d < %s %10s: %s (length: %d)", pos, replicate("|", block_level), T.stringof, val, len);
			pos += len;
			return rcstring(val);
		} else {
			static assert(0, "BufferReader, shift: tried to use shift with an unsupported type: " ~ T.stringof);
		}
	}
	
	/**
	 * Interprets the current position of the buffer as value type T and returns
	 * it. Does not advance the position. An exception is thrown if you try to
	 * peek at the end of a buffer or if not enough data is left in the buffer.
	 */
	T peek(T)()
		if (__traits(isScalar, T) || is(T == EntityId) || is(T == EventId) )
	{
		assert(pos + T.sizeof <= content_length, "BufferReader, peek: not enought bytes in the buffer!");
		if(block_level > 0 && pos + T.sizeof > block_limits[block_level-1]){
			throw New!RCException(format(
				"net: BufferReader, peek: attempt to read over block boundary! boundaries: %s, level: %s, pos: %s, tried to read %d bytes",
				block_limits, block_level, pos, T.sizeof
			));
		}
		return *( cast(T*)(buffer.ptr + pos) );
	}
	
	/**
	 * Returns the buffer data not yet consumed.
	 */
	@property void[] unconsumed(){
		return buffer[pos .. content_length];
	}
	
	/**
	 * Returns the part of the buffer that is currently unused (everything after
	 * the content length barrier).
	 */
	@property void[] unused(){
		return buffer[content_length .. $];
	}
	
	/**
	 * Reads the bytes at the current position as the length of a block and checks
	 * if that block is completely within the valid buffer content.
	 */
	bool isBlockComplete(){
		// Block can not be complete if the is not enought data in the buffer to
		// read a block length.
		auto block_end = pos + uint.sizeof;
		if (block_end > content_length || (block_level > 0 && block_end > block_limits[block_level-1]))
			return false;
		
		auto length = peek!uint();
		return (pos + uint.sizeof + length <= content_length);
	}
	
	
	bool enterBlock()
		in { assert(block_level < block_limits.length, "BufferReader, enterBlock: nesting level to deep"); }
	body {
		if ( isBlockComplete() ) {
			auto block_length = shift!uint();
			block_limits[block_level] = pos + block_length;
			debug(net) base.logger.test("net: %5d < %s-- enter block, length: %d, end: %d, content length: %d --",
				pos, replicate("|", block_level), block_length, block_limits[block_level], content_length);
			block_level++;
			
			if (block_length == 0) {
        auto file = RawFile("recv_buffer.raw", "w");
        file.writeArray(buffer[0..content_length]);
				throw New!RCException(_T("net: block with length 0 received! This should not happen since every block contains an EntityId. Receive buffer written to recv_buffer.raw"));
			}
			
			return true;
		} else {
			return false;
		}
	}
	
	void leaveBlock(bool intentionalUnreadData = false)
		in { assert(block_level > 0, "BufferReader, leaveBlock: tried to leave a block that was not entered (invalid nesting)"); }
	body {
		block_level--;
		if (pos < block_limits[block_level] && !intentionalUnreadData)
			logWarning("BufferReader, leaveBlock: not consumed all block content");
		else if (pos > block_limits[block_level])
			throw New!RCException(format("BlockReader, leaveBlock: consumed data over the end of the block! pos: %s, limits: %s, level: %s",
				pos, block_limits, block_level));
			//logError("BlockReader, leaveBlock: consumed data over the end of the block");
		
		debug(net) base.logger.test("net: %5d < %s-- leave block --", pos, replicate("|", block_level));
		pos = block_limits[block_level];
	}
	
	void rememberPos(){
		assert(remembered_pos == -1, "A position is already remembered, can not remember two positions");
		debug(net) base.logger.test("net: %5d ------ remembering: pos: %d, level: %d, limits: %s --", pos, pos, block_level, block_limits);
		remembered_pos = pos;
		remembered_block_level = block_level;
		remembered_block_limits[] = block_limits[];
	}
	
	void restorePos(){
		assert(remembered_pos != -1, "No position remembered!");
		pos = remembered_pos;
		block_level = remembered_block_level;
		block_limits[] = remembered_block_limits[];
		debug(net) base.logger.test("net: %5d ------ restoring: pos: %d, level: %d, limits: %s --", pos, pos, block_level, block_limits);
	}
	
	void forgetPos(){
		remembered_pos = -1;
	}
}

unittest {
	ubyte[] test_buffer = cast(ubyte[]) x"01 08000000 03000000 00000000 ffffffff";
	auto reader = New!BufferReader(test_buffer, int_cast!uint(test_buffer.length - 4));
  scope(exit) Delete(reader);
	
	assert(reader.unconsumed == test_buffer[0..13]);
	assert(reader.unused == test_buffer[13..$]);
	
	assert(reader.shift!ubyte() == 1);
	assert(reader.unconsumed == test_buffer[1..13]);
	assert(reader.enterBlock() == true);
	assert(reader.unconsumed == test_buffer[5..13]);
	assert(reader.shift!ulong() == 3);
	assert(reader.unconsumed == []);
	reader.leaveBlock();
}


/**
 * Communication end point between client and server. A client manages one pit
 * to communicate with the server. A server manages one pit for each client.
 */
class NetworkBuffer {
	private Socket socket;
	private void[] recv_buffer, send_buffer;
	BufferReader reader;
	BufferWriter writer;
	
	/**
	 * Allocates the send and receive buffers with the specified size. Also sets
	 * the socket to non blocking IO.
	 */
	this(Socket connection, uint buffer_size = 4 * 1024 * 1024){
		connection.blocking = false;
		this.socket = connection;
		auto mem_ptr = StdAllocator.globalInstance.AllocateMemory(buffer_size);
		recv_buffer = mem_ptr[0 .. buffer_size];
		reader = New!BufferReader(recv_buffer);
		
		mem_ptr = StdAllocator.globalInstance.AllocateMemory(buffer_size);
		send_buffer = mem_ptr[0 .. buffer_size];
		writer = New!BufferWriter(send_buffer);
	}
	
	/**
	 * Closes the connection and frees the send and receive buffers.
	 */
	~this()
  {
		socket.shutdown(SocketShutdown.BOTH);
		socket.close();
		
		Delete(reader); reader = null;
		StdAllocator.globalInstance.FreeMemory(recv_buffer.ptr);
		Delete(writer); writer = null;
		StdAllocator.globalInstance.FreeMemory(send_buffer.ptr);
	}
	
	/**
	 * Copies pending data from the socket into the receive buffer. Returns
	 * `false` if the client connection was lost. `true` otherwise.
	 * 
	 * First walks though the current receive buffer and copies any incomplete
	 * block data to the beginning of the buffer. This way blocks that were
	 * incomplete on the last receive will now be completed.
	 */
	bool receive(){
		auto unconsumed_data = reader.unconsumed;
		debug(net) base.logger.test("net: receive: unconsumed data: recv_buffer[%s .. %s]",
			reader.unconsumed.ptr - recv_buffer.ptr, reader.unconsumed.length);
		if (unconsumed_data.length > 0)
			memmove(recv_buffer.ptr, unconsumed_data.ptr, unconsumed_data.length);
		reader.reset(int_cast!uint(unconsumed_data.length));
		// Not really necessary, only used during testing to make sure the rest of
		// the buffer was nilled
		//memset(recv_buffer.ptr + unconsumed_data.length, 0, recv_buffer.length - unconsumed_data.length);
		
		debug(net) base.logger.test("net: receive: socket receive into recv_buffer[%s .. %s]", unconsumed_data.length, recv_buffer.length);
		auto free_recv_buffer = recv_buffer[unconsumed_data.length .. $];
		auto bytes_recieved = socket.receive(free_recv_buffer);
		debug(net) base.logger.test("net: receive: got %s bytes", bytes_recieved);
		if (bytes_recieved > 0) {
			// We got real data
			reader.expand(int_cast!uint(bytes_recieved));
			return true;
		} else if (bytes_recieved == 0) {
			// Connection to the client was lost
			return false;
		} else {
			switch(socket.errno){
				// An error occured, usually EWOULDBLOCK or EINTR, ignore those
				case EWOULDBLOCK, EINTR:
					return true;
				// Client died and was kind enough to reset its connection before its
				// death
				case ECONNRESET:
					logWarning("net: connection to client lost, connection reset by client (probably died)");
					return false;
				// Other errors are not ok and usually indicate the the client died
				default:
					logWarning("net: connection to client lost, reason unknown, socket errno: %s", socket.errno);
					return false;
			}
		}
	}
	
	/**
	 * Receives the specified number of bytes in a blocking way. That is the call
	 * only returns if all requested data is received.
	 */
	void receiveBlocking(uint length){
		socket.blocking = true;
		scope(exit) socket.blocking = false;
		
		uint total_received_bytes = 0;
		ptrdiff_t received_bytes = 0;
		while(total_received_bytes < length){
			received_bytes = socket.receive(reader.unused[total_received_bytes .. $]);
			
			if (received_bytes == 0)
				throw New!RCException(_T("net: lost connection during a blocking receive"));
			else if (received_bytes == -1)
				throw New!RCException(format("net: socket receive failed with error %s", socket.errno));
			
			total_received_bytes += received_bytes;
		}
		
		reader.expand(total_received_bytes);
	}
	
	/**
	 * Sends the contents of the send buffer to the client. Resets the send buffer
	 * after a successful send.
	 * 
	 * The sending stops on any error. EWOULDBLOCK is ignored as is ECONNRESET. In
	 * case of ECONNRESET the next receive will figure out that the client is dead
	 * and clean up the connection.
	 */
	void send(){
		uint total_bytes_send = 0;
		ptrdiff_t bytes_send;
		
		sender: while(total_bytes_send < writer.data.length){
			bytes_send = socket.send(writer.data[total_bytes_send .. $]);
			assert(bytes_send != 0, "net: send 0 bytes, this should not have happend...");
			
			if (bytes_send == -1){
				if( !(socket.errno == EWOULDBLOCK || socket.errno == ECONNRESET) )
					logWarning("net: socket send failed with error %s", socket.errno);
				break sender;
			}
			
			total_bytes_send += bytes_send;
		}
		
		auto unsend_bytes = writer.data.length - total_bytes_send;
		if (unsend_bytes > 0)
			memmove(send_buffer.ptr, writer.data[total_bytes_send .. $].ptr, unsend_bytes);
		
		writer.reset(int_cast!uint(unsend_bytes));
	}
}
