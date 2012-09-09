module base.logger;

import thBase.container.vector;
import core.sync.mutex;

/**
 * Logger module. Allows the rest of this engine to log messages. Each message
 * is saved to the "game.log" file. Usage:
 * 
 *   base.logger.test("player died again...");
 *   base.logger.warn("Velocity of game object %s is above threshold: %f", projectile.id, projectile.vel);
 * 
 * There are logging function for each level: test, info, warn and error. Each
 * accepts the same arguments as std.string.format().
 * 
 * The current log level can be set by setting base.logger.level to one of the
 * values of base.logger.level_t. For example:
 * 
 *   base.logger.level = base.logger.level_t.INFO;
 * 
 * You can also register new message handlers for the logging system:
 * 
 *   base.logger.hook(delegate void(string msg){
 *     stderr.writeln(msg);
 *   });
 * 
 * This can be used to make other subsystems (like a console) display the log
 * messages.
 */

import core.vararg;
import core.allocator;
import thBase.file;
import thBase.format;

// Level enum and variable for the current log level
public enum level_t { TEST, INFO, WARN, ERROR };
public __gshared level_t level;

// List of handlers that process the log messages
private __gshared Vector!(void delegate(string)) message_handlers;
// Log file for messages
private __gshared RawFile log_file;

private __gshared Mutex mutex;

//
// Logging functions. Each function logs the message with the corresponding log
// level.
//

public void test(string fmt, ...){
	if (level <= level_t.TEST)
		log("TEST: ", fmt, _arguments, _argptr);
}

public void info(string fmt, ...){
	if (level <= level_t.INFO)
		log("INFO: ", fmt, _arguments, _argptr);
}

public void warn(string fmt, ...){
	if (level <= level_t.WARN)
		log("WARN: ", fmt, _arguments, _argptr);
}

public void error(string fmt, ...){
	if (level <= level_t.ERROR)
		log("ERROR: ", fmt, _arguments, _argptr);
}

/**
 * Registers a new message handler with the logger. This can be used to allow
 * other subsystems (e.g. a console) to output the log messages.
 */
public void hook(void delegate(string) message_handler){
	synchronized(mutex)
		message_handlers.push_back(message_handler);
}

public void hook(void function(string) message_handler){
	typeof(message_handlers[0]) handler_dg;
	handler_dg.funcptr = cast(void function(string)) message_handler;
	synchronized(mutex)
		message_handlers.push_back(handler_dg);
}

public void unhook(void delegate(string) message_handler)
{
  synchronized(mutex)
    message_handlers.remove(message_handler);
}

public void unhook(void function(string) message_handler){
	typeof(message_handlers[0]) handler_dg;
	handler_dg.funcptr = cast(void function(string)) message_handler;
	synchronized(mutex)
		message_handlers.remove(handler_dg);
}

private void log(string prefix, string fmt, TypeInfo[] arg_types, va_list args){	
	char[2048] fmtBuf;
  char[2048] buf;
  char[] fmtResult;
  char[] message;

  if(prefix.length + fmt.length > fmtBuf.length)
  {
    fmtResult = NewArray!char(prefix.length + fmt.length);
  }
  else
  {
    fmtResult = fmtBuf[0..(prefix.length + fmt.length)];
  }
  scope(exit)
  {
    if(fmtResult.ptr != fmtBuf.ptr)
      Delete(fmtResult);
  }

  fmtResult[0..prefix.length] = prefix[];
  fmtResult[prefix.length..$] = fmt[];

  auto needed = formatDoStatic(buf, cast(string)fmtResult, arg_types, args);
  if(needed > buf.length)
  {
    message = NewArray!char(needed);
    formatDoStatic(message, cast(string)fmtResult, arg_types, args);
  }
  else
  {
    message = buf[0..needed];
  }
  scope(exit)
  {
    if(message.ptr != buf.ptr)
      Delete(message.ptr);
  }

	synchronized(mutex){
		foreach(handler; message_handlers)
			handler(cast(string)message);
	}
}

//
// Stuff for file logging
//

/**
 * Open the log file when the logger module is loaded and register the log file
 * message handler.
 */
shared static this(){
  message_handlers = New!(typeof(message_handlers))();
	mutex = New!Mutex();
	level = level_t.TEST;
}

/**
 * Close the file when the module is unloaded.
 */
shared static ~this(){
	log_file.close();
  Delete(mutex);
  Delete(message_handlers);
}

public void init(string file){
	log_file = RawFile(file, "w");
	hook(&append_to_log_file);
}

/**
 * Message handler that writes the specified message to the log file.
 */
private void append_to_log_file(string msg){
	synchronized(mutex)
  { 
    log_file.writeArray(msg);
    log_file.write('\n');
  }
}
