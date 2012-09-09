module server.server;


import console = server.console;

/+
void main(){
	server.console.init();
	
	while(true){
		auto command = server.console.read();
		if (command.length > 0)
			writefln("cmd: %s", command);
	}
	
	server.console.shutdown();
}
+/
