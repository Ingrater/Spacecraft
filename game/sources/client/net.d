module client.net;

import base.net, base.game, base.gameobject, base.events;

import base.all;
import core.allocator;
import core.refcounted;
import thBase.format;
import thBase.allocator;
import thBase.policies.locking;


class NetworkConnection : IEventSink {
  private Socket m_socket;
  private SmartPtr!InternetAddress m_address;
	private NetworkBuffer buffer;
	private bool m_connected = false;
	private uint m_client_id;
  private FixedStackAllocator!(NoLockPolicy, StdAllocator) m_eventAllocator;
	
	/**
	 * Creates an unconnected connection. Only useful to allow a client to work
	 * without a connection to the server.
	 */
	this(){
	}
	
	@property bool connected(){
		return m_connected;
	}
	
	private @property void connected(bool new_val){
		m_connected = new_val;
	}
	
	@property uint clientId(){
		return m_client_id;
	}
	
	/**
	 * Connects to the server and performs the initial handshake.
	 */
	this(string ip, ushort port){
    m_address = New!InternetAddress(ip, port);
		m_socket = New!TcpSocket(m_address);
		m_socket.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, 1);
		buffer = New!NetworkBuffer(m_socket);
    m_eventAllocator = New!(typeof(m_eventAllocator))(2048, StdAllocator.globalInstance);
		handshake();
		connected = true;
	}

  ~this()
  {
    connected = false;
    Delete(buffer);
    Delete(m_socket);
    Delete(m_eventAllocator);
  }
	
	/**
	 * Does initial connection setup in a blocking manner. Checks the protocol
	 * version and syncs the main timer of the client.
	 */
	private void handshake(){
		buffer.receiveBlocking(ubyte.sizeof + ulong.sizeof + uint.sizeof);
		
		auto server_protocol_version = buffer.reader.shift!ubyte();
		if (server_protocol_version != base.net.protocolVersion)
			throw New!RCException(format(
				"Can not connect to server: incompatible protocol version. Server uses v%s, but client is v%s",
				server_protocol_version, base.net.protocolVersion
			));
		
		auto server_time_offset = buffer.reader.shift!ulong();
		g_Env.mainTimer.setStartTime(server_time_offset);
		
		m_client_id = buffer.reader.shift!uint();
	}
	
	/**
	 * Closes the connection to the server and frees the associated buffers.
	 */
	void close(){
		if (!connected)
			return;
		
		Delete(buffer);
    buffer = null;
    connected = false;
	}
	
	/**
	 * Get new data from the socket
	 * Fire all preSync events
	 * Update all game object data stored in the buffer
	 * Fire postSync events
	 */
	void receive(IGame game){
		if (!connected)
			return;
		
		if ( buffer.receive() == false )
			throw New!Exception("Lost connection to server!");
		
		// Enter any cycle report blocks in the buffer as long as they are complete
		while (buffer.reader.enterBlock()){
      auto profile = base.profiler.Profile("read block");
			// Remember the start of the cycle report because we need to iterate over
			// it multiple times
			buffer.reader.rememberPos();
			
			// Iterate over all blocks in the cycle report
			debug(net) base.logger.test("net: read pre sync events");

      {
        auto profile2 = base.profiler.Profile("pre sync events");
			while (buffer.reader.enterBlock()){
				auto entityId = buffer.reader.shift!EntityId();
				auto type = buffer.reader.shift!ubyte();
				if (type == blockType.preSyncEvent) {
					// handle pre sync events
					auto eventId = buffer.reader.shift!EventId();
					auto entity = game.factory.getGameObject(entityId);
					if (entity is null) {
						base.logger.warn("net: received an pre sync event for an unknown game object (id %d)", entityId);
					} else {
						auto event = entity.constructEvent(eventId, m_eventAllocator);
            scope(exit) AllocatorDelete(m_eventAllocator, event);
						if (event is null) {
							base.logger.warn("net: pre sync event: game object (id %d) was unable to construct the requested event object (event id: %d)", entityId, eventId);
						} else {
							debug(net) base.logger.test("net: fireing event...");
							event.serialize(buffer.reader, true);
							synchronized(game.simulationMutex)
								event.call();
						  }
					  }
					
					  buffer.reader.leaveBlock();
				  } else {
					  buffer.reader.leaveBlock(true);
				  }
			  }
      }
			
			// Restart iteration at the begin of the cycle report and handle all sync
			// blocks for game objects.
      {
        auto profile2 = base.profiler.Profile("sync");
			  buffer.reader.restorePos();
			  debug(net) base.logger.test("net: read sync data");
			  while (buffer.reader.enterBlock()){
				  auto entityId = buffer.reader.shift!EntityId();
				  auto type = buffer.reader.shift!ubyte();
				  if (type == blockType.syncData) {
					  // handle sync data for game objects
					  auto entity = game.factory.getGameObject(entityId);
					  if (entity is null) {
						  base.logger.warn("net: received sync data for an unknown game object (id %d)", entityId);
					  } else {
						  entity.serialize(buffer.reader, true);
					  }
					
					  buffer.reader.leaveBlock();
				  } else {
					  buffer.reader.leaveBlock(true);
				  }
			  }
      }

			// Restart iteration at the begin of the cycle report and handle all post
			// sync events.
      {
        auto profile2 = base.profiler.Profile("post sync events");
        double getGameObjectSum = 0.0;
        double constructEventSum = 0.0;
        double callEventSum = 0.0;
        size_t numEvents = 0;

			  buffer.reader.restorePos();
			  debug(net) base.logger.test("net: read post sync events");
			  while (buffer.reader.enterBlock()){
				  auto entityId = buffer.reader.shift!EntityId();
				  auto type = buffer.reader.shift!ubyte();
				  if (type == blockType.postSyncEvent) {
					  // handle post sync events
					  auto eventId = buffer.reader.shift!EventId();
					  auto entity = game.factory.getGameObject(entityId);
					  if (entity is null) {
						  base.logger.warn("net: received an post sync event for an unknown game object (id %d)", entityId);
					  } else {
						  auto event = entity.constructEvent(eventId, m_eventAllocator);
              scope(exit) AllocatorDelete(m_eventAllocator, event);
						  if (event is null) {
							  base.logger.warn("net: post sync event: game object (id %d) was unable to construct the requested event object (event id: %d)", entityId, eventId);
						  } else {
							  debug(net) base.logger.test("net: fireing event...");
                auto preCallEvent = Zeitpunkt(g_Env.mainTimer);
							  event.serialize(buffer.reader, true);
								event.call();
                double callEventLength = Zeitpunkt(g_Env.mainTimer) - preCallEvent;
                callEventSum += callEventLength;
                numEvents++;
                if(callEventLength > 2.0f)
                {
                  base.logger.info("Very long event %s", event.description());
                }
						  }
					  }
					  buffer.reader.leaveBlock();
				  } else {
					  buffer.reader.leaveBlock(true);
				  }
			  }

        if(callEventSum > 5.0f)
        {
          base.logger.info("Very long post sync event execution %d", numEvents);
        }

        {
          auto manualProfile = base.profiler.ProfileManual("getGameObjects", getGameObjectSum);
        }
        {
          auto manualProfile = base.profiler.ProfileManual("constructEvents", constructEventSum);
        }
        {
          auto manualProfile = base.profiler.ProfileManual("callEvents", callEventSum);
        }
      }
			
			// Forget the remembered position (start of cycle report) and leave the
			// cycle report block
			buffer.reader.forgetPos();
			buffer.reader.leaveBlock();
		}
	}
	
	/**
	 * Send all events stored in the send buffer
	 */
	void send(){
		if (!connected)
			return;
		
		buffer.send();
	}
	
	/**
	 * Serializes `event` into the send buffer so it will be send to the server
	 */
	void pushEvent(EntityId entityId, EventId eventId, IEvent event, EventType type){
		if (!connected)
			return;
		
		buffer.writer.startBlock();
		buffer.writer.push(entityId);
		buffer.writer.push(eventId);
		// Let the event serialize all its fields into the send buffer. We always
		// need to do a full serialization.
		event.serialize(buffer.writer, true);
		buffer.writer.finishBlock();
	}
	
	/**
	 * Interface method used by the server to send an event to an individual
	 * client. Only here because the server and client code is not separated at
	 * all and the interface needs to work for both. Should never be called from
	 * client code.
	 */
	void pushEvent(EntityId objId, EventId eventId, IEvent event, EventType type, uint clientId){
		assert(0, "net: client code should never ever addess an individual client. If you see this something in your mind is terribly screwed up.");
	}
}
