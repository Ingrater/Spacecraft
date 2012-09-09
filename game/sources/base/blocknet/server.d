module base.blocknet.server;

/**
 * Data block based network server.
 * 
 * Usage:
 * 
 *   import base.blocknet.server = server;
 *   
 *   server.host("127.0.0.1", 1234);
 *   gameloop {
 *     server.receive();
 *     
 *     foreach(ref client; server.clients){
 *       foreach(block; client.blocks)
 *         writefln("received %s", block);
 *     }
 *     
 *     server.enqueue_for_all_clients("hello");
 *     
 *     server.send();
 *   }
 *   server.close();
 */


import base.socket, base.blocknet.common: block_range_t;
import core.stdc.string: memcpy;

version(Windows) {
	import std.c.windows.winsock: htons, ntohs;
} else {
	import core.sys.posix.arpa.inet: htons, ntohs;
}

struct client_t {
	uint ip;
	ushort port;
	
	private Socket socket;
	private void[] send_buffer, recv_buffer;
	private uint bytes_in_send_buffer, bytes_in_recv_buffer;
	
	/**
	 * Initializes the client struct for the specified connection and allocates
	 * the send and recieve buffers.
	 */
	private this(Socket client_socket){
		socket = client_socket;
		socket.blocking = false;
		auto client_addr = cast(InternetAddress) socket.remoteAddress();
		ip = client_addr.addr;
		port = client_addr.port;
		
		send_buffer.length = 1024 * 4;
		recv_buffer.length = 1024 * 4;
	}
	
	/**
	 * Closes the connection and frees the send and receive buffers.
	 */
	private void close(){
		socket.shutdown(SocketShutdown.BOTH);
		socket.close();
		clear(socket);
		
		send_buffer.length = 0;
		recv_buffer.length = 0;
	}
	
	/**
	 * Copies pending data from the client into the receive buffer. Returns false
	 * if the client connection was lost. True otherwise.
	 * 
	 * First walks though the current receive buffer and copies any incomplete
	 * block data to the beginning of the buffer. This way blocks that lay on a
	 * package boundary are handled correctly.
	 */
	private bool receive(){
		auto block_range = block_range_t(recv_buffer[0 .. bytes_in_recv_buffer]);
		while(!block_range.empty)
			block_range.popFront();
		
		auto rest = block_range.rest;
		void[] free_recv_buffer;
		if (rest.length > 0) {
			// The last block in the receive buffer is incomplete. Copy it to the
			// start of the buffer so the incomming data continues it. Duplicate it
			// before copying to avoid an overlapped copy.
			recv_buffer[0 .. rest.length] = rest.dup;
			free_recv_buffer = recv_buffer[rest.length .. $];
		} else {
			// No incomplete block, reuse the entire receive buffer.
			free_recv_buffer = recv_buffer;
		}
		
		auto bytes_recieved = socket.receive(free_recv_buffer);
		if (bytes_recieved > 0) {
			// We got real data
			bytes_in_recv_buffer = bytes_recieved + rest.length;
			return true;
		} else if (bytes_recieved == 0) {
			// Connection to the client was lost
			return false;
		} else {
			// An error occured, usually EWOULDBLOCK
			bytes_in_recv_buffer = 0;
			return true;
		}
	}
	
	/**
	 * Sends the contents of the send buffer to the client. Resets the send buffer
	 * after a successful send.
	 */
	private void send(){
		auto bytes_send = socket.send(send_buffer[0..bytes_in_send_buffer]);
		if (bytes_send >= 0) {
			bytes_in_send_buffer = 0;
		} else {
			base.logger.warn("net: socket error on sending buffer to client");
		}
	}
	
	/**
	 * Puts the specified data block into the send buffer.
	 */
	private bool enqueue(void[] data)
		in { assert(data.length <= ushort.max, "net: can only enqueue data blocks with a length of ushort.max"); }
	body {
		ushort block_length = htons(cast(ushort) data.length);
		
		// Check if the availible buffer space is large enougth for the block length
		// and block data
		if (send_buffer.length - bytes_in_send_buffer < block_length.sizeof + data.length)
			return false;
		
		// Copy the size in network byte order into the send buffer, followed by the
		// actual data.
		memcpy(send_buffer[bytes_in_send_buffer .. bytes_in_send_buffer + block_length.sizeof].ptr,
			&block_length, block_length.sizeof);
		bytes_in_send_buffer += block_length.sizeof;
		memcpy(send_buffer[bytes_in_send_buffer .. bytes_in_send_buffer + data.length].ptr,
			data.ptr, data.length);
		bytes_in_send_buffer += data.length;
		
		return true;
	}
	
	/**
	 * Returns a range that iterates over all complete byte blocks in the receive
	 * buffer.
	 */
	public block_range_t blocks(){
		return block_range_t(recv_buffer[0 .. bytes_in_recv_buffer]);
	}
}

public client_t[uint] clients;
private uint next_client_id = 0;
private TcpSocket server_socket;

/**
 * Starts up the server on the specified IP and port. The server can accept
 * connections after this call.
 */
public void host(string ip, ushort port){
	server_socket = new TcpSocket();
	server_socket.bind( new InternetAddress(ip, port) );
	server_socket.listen(1);
	server_socket.blocking = false;
}

/**
 * Shuts down the server and all client connections.
 */
public void close(){
	if (server_socket !is null){
		server_socket.shutdown(SocketShutdown.BOTH);
		server_socket.close();
		clear(server_socket);
	}
	
	foreach(client; clients)
		client.close();
}

public bool enqueue_for_client(uint target_client, void[] data){
	auto client = target_client in clients;
	if (client)
		return client.enqueue(data);
	else
		return false;
}

public void enqueue_for_all_clients(void[] data){
	foreach(ref client; clients)
		client.enqueue(data);
}

public void enqueue_for_all_but_client(uint ignored_client, void[] data){
	foreach(id, ref client; clients){
		if (id != ignored_client)
			client.enqueue(data);
	}
}

/**
 * Tries to send all pending data to the clients. If a client connection is not
 * ready the data will not be send and the event is logged.
 */
public void send(){
	foreach(id, ref client; clients)
		client.send();
}

/**
 * Handle new incomming connections and receive incomming data from all
 * connections.
 */
public void receive(){
	// Add a new connection if we got one
	Socket new_connection = server_socket.accept();
	if (new_connection !is null){
		clients[next_client_id] = client_t(new_connection);
		base.logger.info("net: accepted new client %s", next_client_id);
		next_client_id++;
	}
	
	// Copy any incoming data from the OS buffers into our client buffers... if
	// there is any
	uint[] dead_client_ids;
	foreach(id, ref client; clients){
		if ( !client.receive() )
			dead_client_ids ~= id;
	}
	
	// Remove clients marked as dead
	foreach(id; dead_client_ids){
		clients.remove(id);
		base.logger.info("net: removed client %s", id);
	}
}
