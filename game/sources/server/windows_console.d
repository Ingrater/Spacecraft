module server.windows_console;

import thBase.logging;
import thBase.casts;

import std.uni;

version(Windows){
	
	import core.sys.windows.windows;
	import core.stdc.stdio;
	
	
	// Console handles for stdin and stdout
	private HANDLE conStdin;
	private HANDLE conStdout;
	// Line buffer, reused for each new line
	private char[] lineBuffer;
	// Number of valid bytes in the line buffer. It is also used as an index at
	// which the next input character is written.
	private uint bytesInBuffer;
	
	/**
	 * Allocates a windows console. This shows a console window if the application
	 * was not started though a console. We also let the console handle ctrl+c but
	 * do all other stuff by ourselfs. Fancy stuff like line input, automatic
	 * backspace and tab handling doesn't work with nonblocking console events.
	 * The line buffer is also allocated here. Pieces of it are returned by each
	 * read() call.
	 * 
	 * NOTE: On WinXP the context menu of the console always blocks the read()
	 * call. This can be prevented a bit with the ENABLE_QUICK_EDIT_MODE console
	 * mode. However this is not defined in the core D files. This problem does
	 * not occur on Win7.
	 */
	public void init(){
		AllocConsole();
		
		conStdin = GetStdHandle(STD_INPUT_HANDLE);
		conStdout = GetStdHandle(STD_OUTPUT_HANDLE);
		if (conStdin == INVALID_HANDLE_VALUE || conStdout == INVALID_HANDLE_VALUE)
			throw New!Exception("Failed to get stdin or stdout of the console");
		
		if ( !SetConsoleMode(conStdin, ENABLE_PROCESSED_INPUT) )
			throw New!Exception("Failed to set console mode");
		
		lineBuffer = NewArray!char(1024);
		bytesInBuffer = 0;
	}
	
	/**
	 * Frees the line buffer and console window.
	 */
	public void shutdown(){
		Delete(lineBuffer);
		FreeConsole();
	}
	
	/**
	 * Handles all pending console input events and prints them on the console.
	 * If a whole command was received the command is returned, an empty string
	 * otherwise.
	 */
	public char[] read(){
		DWORD pendingEventCount = 0;
		if ( !GetNumberOfConsoleInputEvents(conStdin, &pendingEventCount) )
			throw new Exception("Could not get number of pending console input events");
		
		INPUT_RECORD inputRecords[10];
		DWORD eventsRead;
		
		while(pendingEventCount > 0) {
			if ( !ReadConsoleInputA(conStdin, inputRecords.ptr, inputRecords.length, &eventsRead) )
				throw New!Exception("Could not read console input events");
			
			pendingEventCount -= eventsRead;
			foreach(input; inputRecords[0 .. eventsRead]){
				// Ignore all input events except key presses
				if (input.EventType == KEY_EVENT && input.KeyEvent.bKeyDown){
					CHAR key = input.KeyEvent.AsciiChar;
					
					if (key == '\b') {
						// Eraze the last character when backspace is pressed
						if(bytesInBuffer > 0){
							printf("\b \b");
							bytesInBuffer--;
						}
						
					} else if (key == '\r') {
						// When the users presses enter return the current line buffer
						// content and reset it for the next line. Also print a new line on
						// the console.
						auto command = lineBuffer[0 .. bytesInBuffer];
						key = '\n';
						WriteConsoleA(conStdout, &key, 1, null, null);
						bytesInBuffer = 0;
						return command;
					} else if ( isGraphical(key) || key == ' ' ) {
						// Store all graphalbe (printable) characters in the buffer and
						// write them on the console.
						lineBuffer[bytesInBuffer] = key;
						if (bytesInBuffer < lineBuffer.length - 1)
							bytesInBuffer++;
						WriteConsoleA(conStdout, &key, 1, null, null);
					} 
				}
			}
		}
		
		return lineBuffer[0..0];
	}
	
	/**
	 * Writes the specified text to the console. Does not append a new line.
	 */
	public void write(const char[] message){
		WriteConsoleA(conStdout, message.ptr, int_cast!uint(message.length), null, null);
	}
	
	/**
	 * Writes the specified text to the console, followed by a new line.
	 */
	public void writeln(const char[] message){
		write(message);
		write("\n");
	}
}
