module server.console;

version(Windows) {
	public import server.windows_console;
} else {
	public import server.posix_console;
}
