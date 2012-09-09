module server.net;

import base.all, base.socket, base.net, base.events;
static import server.console;
import game.objectfactory;
import thBase.container.hashmap;
import thBase.container.stack;
import thBase.allocator;
import thBase.policies.locking;


class NetworkServer : IEventSink {
	private TcpSocket socket;
	private Hashmap!(uint, NetworkBuffer) clients;
	private uint next_client_id = 0;
  private FixedStackAllocator!(NoLockPolicy, StdAllocator) m_eventAllocator;
	version(netUsage) private uint numEvents = 0;
	
	/**
	 * Property used by the game simulation to figure out where it runs...
	 */
	@property bool connected(){
		return true;
	}
	
	@property uint clientId(){
		assert(0, "a server should be never asked for it's client id");
	}
	
	/**
	 * Starts up the network system for the game server on the specified IP and
	 * port. After this call the server can accpet client connections.
	 */
	this(string ip, ushort port){
    clients = New!(typeof(clients))();
		socket = New!TcpSocket();
    m_eventAllocator = New!(typeof(m_eventAllocator))(2048, StdAllocator.globalInstance);
    SmartPtr!Address address = New!InternetAddress(ip, port).ptr;
		socket.bind( address );
		socket.listen(1);
		socket.blocking = false;
		socket.setOption(SocketOptionLevel.TCP,SocketOption.TCP_NODELAY,1);
	}

  ~this()
  {
    Delete(socket);
		foreach(client; clients)
    {
			Delete(client);
    }
    Delete(clients);
    Delete(m_eventAllocator);
  }

	/**
	 * Stops the network system for the game server. Stops the server and closes
	 * all client connections.
	 */
	void close(){
		if (socket !is null){
			socket.shutdown(SocketShutdown.BOTH);
			socket.close();
		}
		
		foreach(client; clients.values)
    {
			Delete(client);
    }
    clients.clear();
	}
	
	/**
	 * Checks for new incomming connections and accepts them.
	 */
	void accept(IGame game){
		// Add a new connection if we got one
		Socket con = socket.accept();
		if (con !is null){
			con.setOption(SocketOptionLevel.TCP,SocketOption.TCP_NODELAY,1);
			auto client_buffer = New!NetworkBuffer(con);
			clients[next_client_id] = client_buffer;
			
			handshake(client_buffer, next_client_id);
			sendCompleteWorld(client_buffer, next_client_id, game.factory);
			
			// Start the cycle report for this client. Already connected clients
			// already have a started cycle report.
			client_buffer.writer.startBlock();
			
			base.logger.info("net: accepted new client no. %s: %s", next_client_id, con.remoteAddress.toString()[]);
			
			// Let the game know that a new player joined. Since the game will usually
			// generate events in some way (e.g. spawn something) we needed to open
			// the new cycle report above.
			game.onPlayerConnect(next_client_id);
			
			next_client_id++;
		}
	}
	
	/**
	 * Performs the initial handshake with the specified client. This sends the
	 * client everything it needs to know about the server.
	 */
	private void handshake(NetworkBuffer client, uint client_id){
		client.writer.push!ubyte(base.net.protocolVersion);
		client.writer.push!ulong(g_Env.mainTimer.getStartTime());
		client.writer.push!uint(client_id);
	}
	
	/**
	 * Sends the complete world to the client. The whole thing is build like a
	 * normal cycle report so there is no extra code needed on the client side to
	 * process it.
	 */
	private void sendCompleteWorld(NetworkBuffer client, uint client_id, IGameObjectFactory entity_manager){
		client.writer.startBlock();
		
		// Replicate the game objects first so the client knows them
		debug(net) base.logger.info("net: start sending world events...");
		entity_manager.OnClientConnected(client_id);
		debug(net) base.logger.info("net: finished sending world events...");
		
		// Update the game objects with the newest state
		debug(net) base.logger.info("net: start sending world objects...");
		entity_manager.foreachGameObject((ref IGameObject entity){
			if(entity.syncOverNetwork){
				client.writer.startBlock();
				client.writer.push(entity.entityId);
				client.writer.push(blockType.syncData);
				uint startPos = client.writer.curPos;
				// Let the event serialize all its fields into the send buffer. We always
				// need to do a full serialization.
				entity.serialize(client.writer, true);
				uint endPos = client.writer.curPos;
				
				//if start and endPos are euqal revert the block
				client.writer.finishBlock( (startPos == endPos) );
			}
      return 0;
		});
		debug(net) base.logger.info("net: finished sending world objects...");
		
		client.writer.finishBlock();
	}
	
	/**
	 * Receive pending events from clients and fire them on the game objects
	 */
	void receive(IGame game){
    //Temporary stack of size 128
		auto dead_client_ids = AllocatorNew!(Stack!(uint, ThreadLocalChunkAllocator))(ThreadLocalStackAllocator.globalInstance, 128);
    scope(exit) AllocatorDelete(ThreadLocalStackAllocator.globalInstance, dead_client_ids);

    // Copy any incoming data from the OS buffers into our client buffers... if
		// there is any
		foreach(id, ref client; clients){
			if ( client.receive() ) {
				// Handle all complete blocks within the buffer
				while(client.reader.enterBlock()){
					//server.console.writeln( format("from client %d: %s", id, client.reader.shift!char()) );
					
					auto entityId = client.reader.shift!EntityId();
					auto eventId = client.reader.shift!EventId();
					
					auto gameObject = game.factory.getGameObject(entityId);
					IEvent event = gameObject.constructEvent(eventId, m_eventAllocator);
          scope(exit) AllocatorDelete(m_eventAllocator, event);
					// push data from net buffer into new event object
					event.serialize(client.reader, true);
					// fire event
					event.call();
					
					client.reader.leaveBlock();
				}
			} else {
				// Clean up the client buffer and mark it for removal if the connection
				// was lost
				Delete(client);
        client = null;
				dead_client_ids.push(id);
			}
		}
	
		// Remove clients marked as dead
    // This has to be done here as we can not change the hashmap while iterating over it
		while( !dead_client_ids.empty() )
    {
      auto id = dead_client_ids.pop();
			clients.remove(id);
			base.logger.info("net: lost connection to client %s", id);

      // Notify the game about the disconnected client (game then kills the player
      // or something like that)
      game.onPlayerDisconnect(id);
		}
	}
	
	/**
	 * Starts the cycle report block in each client buffer.
	 */
	void startReports(){
		foreach(client; clients){
			client.writer.startBlock();
		}
	}
	
	/**
	 * Serializes the event into the send buffer of all clients.
	 */
	void pushEvent(EntityId objId, EventId eventId, IEvent event, EventType type){
		version(netUsage) numEvents++;
		foreach(clientId, client; clients){
			pushEvent(objId, eventId, event, type, clientId);
		}
	}
	
	/**
	 * Serializes the event into the send buffer of the specified client.
	 */
	void pushEvent(EntityId objId, EventId eventId, IEvent event, EventType type, uint clientId){
		if (!clients.exists(clientId))
			throw New!Exception("net: tried to send an event to a client that does not exist!");
    auto client = clients[clientId];
		
		client.writer.startBlock();
		client.writer.push(objId);
		client.writer.push(type == EventType.preSync ? blockType.preSyncEvent : blockType.postSyncEvent);
		client.writer.push(eventId);
		// Let the event serialize all its fields into the send buffer. We always
		// need to do a full serialization.
		event.serialize(client.writer, true);
		client.writer.finishBlock();
	}
	
	/**
	 * Should store all changes done to the state of the game objects within the
	 * cycle report. Maybe not a good idea to put this here...
	 */
	void collectChanges(IGameObjectFactory entityManager){
		version(netUsage) uint count = 0;
		entityManager.foreachGameObject((ref IGameObject entity){
			if(entity.syncOverNetwork){
				bool first = true;
				foreach(client; clients){
					client.writer.startBlock();
					client.writer.push(entity.entityId);
					client.writer.push(blockType.syncData);
					uint startPos = client.writer.curPos();
					//Let the entity serialize all its fields to the buffer
					entity.serialize(client.writer, false);
					uint endPos = client.writer.curPos();
					
					//if start and endPos are equal revert the block
					client.writer.finishBlock( (startPos == endPos) );
					version(netUsage){
						if(first && startPos != endPos){
							first = false;
							count++;
						}
					}
				}
			}
			
			entity.resetChangedFlags();
      return 0;
		});
		version(netUsage){
			if(count > 0)
				base.logger.info("send %d updates",count);
		}
	}	
	
	/**
	 * Finishes the cycle report block in each client buffer and sends the pending
	 * data to the clients.
	 */
	void send(){
		foreach(uint i,client; clients){
			client.writer.finishBlock();
			version(netUsage) base.logger.info("client %d, %d bytes",i,client.writer.curPos());
			client.send();
		}
		version(netUsage) {
			if(numEvents > 0){
				base.logger.info("send %d events",numEvents);
				numEvents = 0;
			}
		}
	}
}

/+

/**
 * Accepts new connections to the server and receives the pending data from the
 * clients.
 */
void receive(){
	base.blocknet.server.receive();
	
	//... just taken for code preservation
			foreach(id, ref client; base.blocknet.server.clients){
				foreach(block; client.blocks){
					server.console.writeln(format("received from client %d: %s", id, cast(char[]) block));
				}
			}
	
	// receive bytes from network
	auto derserializer = ....; // TODO
	foreach(block; base.blocknet.server.blocks){
		EntityId id;
		ubyte event_id;
		deserializer.serialize(id);
		deserializer.serialize(event_id);
		
		auto game_object = GameObjectFactory.get(id); // GameObjectFactory does not exist yet
		IEvent event = game_object.constructEvent(event_id);
		event.serialize(deserializer);  // push data from net buffer into new event object
		event.call() // fire event
	}
}

enum Mode {
	toAllClients,
	toOneClient,
	toAllButOneClients
}

enum Order {
	preSync,
	postSync
}

/**
 * puts an event into the send buffer of a client (or many clients)
 */
void enqueueEvent(GameObjectId id, ubyte event_id, IEvent event, Order order, Mode mode, EntityId id = 0){
	// same like client but:
	// type define that this is an _event_ and _which kind_ of event (pre, post)
	serializer.serialize(type);
	// ... from here on same as client
}

/*
 * broadcasts all game object changes to all clients
 */
void broadcastChanges(){
	auto serializer = ...; // pushes changes into the buffer of _each_ client (we broadcast the
		// changes on the game objects to all clients
	foreach(game_object; GameObjectFactory.all){
		serializer.serialize(type); // type defines this block as a game object data block (instead of pre or post event)
		serializer.serialize(game_object.entityId);
		game_object.serialize(serializer);
	}
}



+/
