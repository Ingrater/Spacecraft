static import server.console, base.logger, base.blocknet.server;
import script.factory;
import std.functional, std.string;

void main(){
	server.console.init();
	scope(exit) server.console.shutdown();
	base.logger.hook(toDelegate(&server.console.writeln));
	
	// Start up the scripting system for the console
	auto factory = GetScriptSystemFactory();
	factory.Init();
	auto scripting = factory.GetScriptSystem();
	
	// Register functions that can be called though the console
	scripting.RegisterGlobal("say", toDelegate(&say));
	
	// Start up network and close it if we're done
	base.blocknet.server.host("127.0.0.1", 1234);
	scope(exit) base.blocknet.server.close();
	
	server.console.write("> ");
	
	while(true){
		base.blocknet.server.receive();
		
		foreach(id, ref client; base.blocknet.server.clients){
			foreach(block; client.blocks){
				server.console.writeln(format("received from client %d: %s", id, cast(char[]) block));
			}
		}
		
		auto command = server.console.read();
		if (command.length > 0){
			if (command == "exit")
				break;
			
			try {
				scripting.execute(command.idup);
			} catch(ScriptError e) {
				base.logger.warn("Error: %s", e);
			}
			
			server.console.write("> ");
		}
		
		base.blocknet.server.send();
	}
}

void say(uint client_id, string text){
	server.console.writeln("server says: " ~ text);
	base.blocknet.server.enqueue_for_client(client_id, text.dup);
}
