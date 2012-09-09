module base.blocknet.client;

/**
 * Usage:
 * 
 *   import base.blocknet.client = client;
 * 
 *   client.connect("127.0.0.1", 1234);
 *   
 *   gameloop {
 *     client.receive();
 *     
 *     foreach(block; client.blocks)
 *       writefln("received: %s", block);
 *     
 *     client.enqueue("hello");
 *     
 *     client.send();
 *   }
 *   
 *   client.disconnect();
 * 
 *     client.preSyncEvents
 *     client.syncRequests
 *     client.postSyncEvents
 *     client.enqueuePreEvent()
 *     client.enqueuePostEvent()
 * 
 */

import base.socket, base.blocknet.common: block_range_t;
import std.string;
import core.stdc.string: memcpy;

version(Windows) {
	import std.c.windows.winsock: htons, ntohs;
} else {
	import core.sys.posix.arpa.inet: htons, ntohs;
}


TcpSocket connection;
private void[] send_buffer, recv_buffer;
private uint bytes_in_send_buffer, bytes_in_recv_buffer;

public void connect(string ip, ushort port){
	send_buffer.length = 4 * 1024;
	recv_buffer.length = 4 * 1024;
	
	connection = new TcpSocket(new InternetAddress(ip, port));
	connection.blocking = false;
}

public void disconnect(){
	connection.shutdown(SocketShutdown.BOTH);
	connection.close();
	clear(connection);
	
	send_buffer.length = 0;
	recv_buffer.length = 0;
}

/**
 * Copies pending data from the server into the receive buffer. The content of
 * the receive buffer is overwritten with new data.
 */
public void receive(){
	auto block_range = blocks();
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
	
	auto bytes_recieved = connection.receive(free_recv_buffer);
	if (bytes_recieved > 0) {
		// We got real data
		bytes_in_recv_buffer = bytes_recieved + rest.length;
	} else if (bytes_recieved == 0) {
		// Connection to the client was lost
		throw new Exception("Connection to server lost");
	} else {
		// An error occured, usually EWOULDBLOCK
		bytes_in_recv_buffer = 0;
	}
}

/**
 * Sends the contents of the send buffer to the client. Resets the send buffer
 * after a successful send.
 */
public void send(){
	auto bytes_send = connection.send(send_buffer[0..bytes_in_send_buffer]);
	if (bytes_send != bytes_in_send_buffer) {
		bytes_in_send_buffer = 0;
	} else {
		base.logger.warn("net: socket error on sending buffer to client or not all bytes have been send");
	}
}

/**
 * Puts the specified data block into the send buffer.
 */
public bool enqueue(const(void[]) data)
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
 * Returns a range of all blocks currently in the receive buffer.
 */
public block_range_t blocks(){
	return block_range_t(recv_buffer[0..bytes_in_recv_buffer]);
}
