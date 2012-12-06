module server.posix_console;

version(Posix){
	
	import core.stdc.errno, core.stdc.stdio;
	import core.sys.posix.fcntl, unistd = core.sys.posix.unistd, core.sys.posix.poll;
	
	// Redefine for 64bit compatibility, core.sys.posix.fcntl only contains 32bit
	// compatible definitions
	extern(C){
		cint_t fcntl(cint_t fildes, cint_t cmd, ...);
		cint_t read(cint_t fildes, void* buf, size_t nbyte);
	}

	// Buffer for the current input line. Reused for each new line.
	private char[] line_buffer;


	/**
	 * Initializes the POSIX console for the server. Sets stdin to non blocking IO
	 * and allocates the line buffer used to store the read data.
	 */
	public void init(){
		auto current_flags = fcntl(unistd.STDIN_FILENO, F_GETFL);
		if ( fcntl(unistd.STDIN_FILENO, F_SETFL, current_flags | O_NONBLOCK) == -1 ){
			perror("fcntl() failed");
			throw new Exception("Failed to set stdio to non blocking IO with fcntl()");
		}
	
		line_buffer.length = 1024;
	}

	/**
	 * Cleans up the POSIX console for the server.
	 */
	public void shutdown(){
		line_buffer.length = 0;
	}

	/**
	 * Reads one line from the console if one is available. If not an empty string
	 * is returned but the function does NOT BLOCK. Therefore it can be used in a
	 * game loop to check for new commands to process.
	 */
	public char[] read(){
		auto bytes_read = unistd.read(unistd.STDIN_FILENO, line_buffer.ptr, line_buffer.length);
		// If we got data return the command (but without the trailing new line)
		if (bytes_read >= 0)
			return line_buffer[0 .. bytes_read - 1];
	
		// Return an empty string if there was nothing to read, otherwise print the
		// error and throw.
		if (errno == EWOULDBLOCK) {
			return line_buffer[0..0];
		} else {
			perror("read() failed");
			throw new Exception("Failed to read from the console with read()");
		}
	}
	
	/**
	 * Writes the specified data to he console. Does not append a new line. The
	 * console is set to blocking for that operation so we do not get killed by
	 * the OS.
	 */
	public void write(const char[] message){
		auto current_flags = fcntl(unistd.STDIN_FILENO, F_GETFL);
		
		fcntl(unistd.STDIN_FILENO, F_SETFL, current_flags & ~O_NONBLOCK);
		scope(exit) fcntl(unistd.STDIN_FILENO, F_SETFL, current_flags);

		auto bytes_written = unistd.write(unistd.STDOUT_FILENO, message.ptr, message.length);
		
		if (bytes_written != message.length)
			throw new Exception("Failed to write all data to the console with write()");
	}
	
	/**
	 * Writes the specified message to the console, followed by a new line.
	 */
	public void writeln(const char[] message){
		write(message);
		write("\n");
	}
}
