module base.logger;

import thBase.logging;
import thBase.file;

__gshared RawFile g_logFile;

/**
 * initializes the logging to a file
 */
public void init(string file){
	g_logFile = RawFile(file, "w");
	RegisterLogHandler(&append_to_log_file);
}

enum EngineSubsystem
{
  Renderer = LogSubsystem.Global << 1,
  Game = Renderer << 1,
  Network = Game << 1,
  Sound = Network << 1,
  Script = Sound << 1
}

/**
 * Message handler that writes the specified message to the log file.
 */
private void append_to_log_file(LogLevel level, ulong subsystem, scope string msg){
  final switch(level)
  {
    case LogLevel.Message:
      break;
    case LogLevel.Info:
      g_logFile.writeArray("Info: ");
      break;
    case LogLevel.Warning:
      g_logFile.writeArray("Warning: ");
      break;
    case LogLevel.Error:
      g_logFile.writeArray("Error: ");
      break;
    case LogLevel.FatalError:
      g_logFile.writeArray("Fatal Error: ");
      break;
  }
  g_logFile.writeArray(msg);
  g_logFile.write('\n');
}
