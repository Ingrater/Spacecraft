import std.stdio, std.string;
static import base.blocknet.client;

void main(){
	base.blocknet.client.connect("127.0.0.1", 1234);
	scope(exit) base.blocknet.client.disconnect();
	
	writef("net test client\n> ");
	
	main_loop: while(true){
		base.blocknet.client.receive();
		
		foreach(block; base.blocknet.client.blocks)
			writefln("received: %s", block);
		
		auto input = readln().dup;
		auto first_space = indexOf(input[0 .. $-1], ' ');
		auto command = (first_space == -1) ? input : input[0 .. first_space];
		
		if (command.length > 0){
			switch(command){
				case "exit":
					break main_loop;
				case "send":
					base.blocknet.client.enqueue(input[first_space + 1 .. $]);
					break;
				default:
					writefln("unknown command: %s", command);
					break;
			}
			writef("> ");
		}
		
		base.blocknet.client.send();
	}
}
