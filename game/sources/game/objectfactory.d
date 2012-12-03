module game.objectfactory;

import std.typetuple;
import base.gameobject;
import base.net, base.game, base.renderer, base.all;
import game.game;

import game.asteroid, game.frigate, game.player, game.projectiles, game.effects.shieldimpact, game.effects.smallexplosion;
import game.effects.bigshieldimpact,game.effects.smallexplosion2, game.effects.flakexplosion;
import game.effects.bigexplosion, game.deco;
import game.rules.deathmatch;
import thBase.container.hashmap;
import thBase.container.vector;
import thBase.logging;

class GameObjectFactory : IGameObject, IGameObjectFactory {
	private:
		alias TypeTuple!(Asteroid, Frigate, Player,
			MgProjectile, TurretBase!MgProjectile, TurretCannon!MgProjectile,
			HeavyProjectile, TurretBase!HeavyProjectile, TurretCannon!HeavyProjectile,
			FlakProjectile, TurretBase!FlakProjectile, TurretCannon!FlakProjectile,
			ShieldImpact, SmallExplosion, BigExplosion, Station, Habitat,
			BigShieldImpact, SmallExplosion2, FlakExplosion
		) ObjectList;
		alias IGameObject delegate(EntityId id, GameSimulation game) creatorFunc;
		
		creatorFunc[ObjectList.length] m_Creators;
		Hashmap!(EntityId, IGameObject) m_Objects;
		Hashmap!(EntityId, int) m_Types;
		
		private IGameObject Make(T)(EntityId id, GameSimulation game){
			return new T(id, game);
		}
		
		GameSimulation m_Game;
		EntityId m_NextEntityId = EntityId(3);
		Vector!IGameObject m_DeadEntities;
    Vector!IGameObject m_DeadClientEntities;
		
		class ClientMsgs {
			/**
			 * spawns a new object on the client side
			 */
			void SpawnObject(int type, EntityId id){
				//logInfo("game: factory received spawn object message for entity %d of type %d", id, type);
				IGameObject obj = m_Creators[type](id,m_Game);
				m_Objects[id] = obj;
				m_Types[id] = type;
				m_Game.octree.insert(obj);
			}
			
			/**
			 * triggers the post spawn event on the client side
			 */
			void PostSpawnObject(EntityId id){
				//logInfo("game: factory received post spawn message for entity %s", id);
				IGameObject obj = m_Objects[id];
				obj.postSpawn();
			}
			
			/**
			 * Triggers removal of a game object. Markes the object as dead and these
			 * will be cleaned up after the cycle by cleanDeadGameObjects().
			 */
			void removeGameObject(EntityId id){
				IGameObject obj = m_Objects[id];
				obj.onDeleteRequest();
				m_DeadEntities ~= obj;
			}
		}
		
		class ServerMsgs {
		}
		
		mixin MessageCode;
	
	public:		
		this(GameSimulation game){
      m_Objects = New!(typeof(m_Objects))();
      m_Types = New!(typeof(m_Types))();
      m_DeadEntities = New!(typeof(m_DeadEntities))();
      m_DeadClientEntities = New!(typeof(m_DeadClientEntities))();
			m_Game = game;
			foreach(T;ObjectList){
				m_Creators[staticIndexOf!(T,ObjectList)] = &Make!(T);
			}
			InitMessaging();
      assert(toClient !is null);
			
			m_Objects[EntityId(1)] = this;
			m_Types[EntityId(1)] = -1;
		}

    ~this()
    {
      removeAllObjects();
      Delete(m_DeadEntities);
      Delete(m_DeadClientEntities);
      Delete(m_Objects);
      Delete(m_Types);
    }

    /**
     * deletes all objects that have been created by the object factory and does a complete cleanup on the octree
     */
    void removeAllObjects()
    {
      cleanDeadGameObjects();
      foreach(id, gameObject; m_Objects)
      {
        if(id > 2) //all ids > 2 are actual spawned objects
        {
          auto result = m_Game.octree.remove(gameObject);
          //logInfo("deleted %x %s => %s", cast(void*)cast(Object)gameObject, gameObject.inspect()[], result);
          gameObject.onDeleteRequest();
          Delete(gameObject);
        }
      }
      m_Objects.clear();
      foreach(obj; m_Game.octree.allObjects)
      {
        logInfo("remaining object %s", obj.inspect()[]);
      }
      m_Game.octree.deleteAllRemainingObjects();
    }
		
		/**
		 * Registers a plain game object in the factory to receive messages under
		 * the specified id.
		 */
		void registerObject(EntityId id, IGameObject entity){
      debug
      {
        if(m_Objects.exists(id))
        {
          auto msg = format("factory: a game object with the id %d is already registered!", id.id);
          assert(0, msg[]);
        }
      }
			//logInfo("factory: registering id %s: %s", id, &entity);
			m_Objects[id] = entity;
			m_Types[id] = -1;
		}
		
		/**
	   * Spawns a new object on all clients, and adds it to the world
	   * Params:
	   *  obj = object to spawn 
	   */
		void SpawnGameObject(T)(T obj){
			static assert(staticIndexOf!(T,ObjectList) != -1,T.stringof ~ "is not in object list");
			int objectTypeId = staticIndexOf!(T,ObjectList);
			EntityId id = obj.entityId();
			assert(id > 2,"entity id has to be > 2");
			m_Objects[id] = obj;
			m_Types[id] = objectTypeId;
			m_Game.octree.insert(obj);
			
			//logInfo("Spawning object SpawnGameObject typeId = %d, entityId = %d",objectTypeId,id);
			toClient.SpawnObject(objectTypeId, id, EventType.preSync);
			toClient.PostSpawnObject(id, EventType.postSync);
		}
		
		/**
		 * This function transmits all currently registered game objects to the newly connected client
		 */
		void OnClientConnected(uint clientId){
			foreach(EntityId id,int objectTypeId;m_Types){
				//Make shure to not try to create the factory
				if(objectTypeId >= 0){
					//logInfo("Spawning object typeId = %d, entityId = %d",objectTypeId,id);
					toClient.SpawnObject(objectTypeId, id, EventType.preSync, clientId);
					toClient.PostSpawnObject(id, EventType.postSync, clientId);
				}
			}
		}
		
		/**
		 * Registers a special creation function for the given type
		 * Params:
		 *  func = the creation function
		 */
		void RegisterCreationFunc(T)(creatorFunc func){
			logInfo("Registering creation func for " ~ T.stringof);
			int objectTypeId = staticIndexOf!(T,ObjectList);
			m_Creators[objectTypeId] = func;
		}
		
		/**
		 * returns a game object by id.
		 * Params:
		 *  id = the game object to get
		 * Returns: the object or null if it does not exist
		 */
		IGameObject getGameObject(EntityId id){			
			if (!m_Objects.exists(id)){
				logWarning("factory: someone asked for id %s, but got null", id);
        return null;
			}
			
			return m_Objects[id];
		}
		
		/**
		 * returns a delegate to iterate over all game objects
		 */
		override int foreachGameObject(scope int delegate(ref IGameObject) dg)
    {
			return m_Objects.opApply(dg);
		}
		
		/**
		 * Notifies everyone that the gameobject should be removed from the game.
		 * After this call the game object is only marked as dead. You need to call
		 * cleanDeadGameObjects() to really remove the dead objects. Be aware that
		 * cleanDeadGameObjects() can not be called from within a loop or the
		 * program will segfault.
		 */
		override void removeGameObject(IGameObject obj){
			assert(g_Env.isServer,"removeGameObject called on client");
			obj.onDeleteRequest();
			toClient.removeGameObject(obj.entityId,EventType.postSync);
			m_DeadEntities ~= obj;
		}

		/**
     * Notifies everyone that a client side only game object should be removed from the game.
     * After this call the game object is only marked as dead. You need to call
     * cleanDeadGameObjects() to really remove the dead objects. Be aware that
     * cleanDeadGameObjects() can not be called from within a loop or the
     * program will segfault.
     */
    override void removeClientGameObject(IGameObject obj)
    {
      assert(!g_Env.isServer, "removeClientGameObject called on server");
      assert(obj !is null, "obj may not be null");
      assert(obj.syncOverNetwork == false, "obj is not client side only");
      m_DeadClientEntities ~= obj;
    }
		
		/**
		 * Removes all entities marked as dead from the game data structures. This
		 * must not be called during an iteration over the game objects or the
		 * system will crash (D arrays are loop invariant).
		 */
		void cleanDeadGameObjects(){
			foreach(entity; m_DeadEntities[]){
				//logInfo("game: cleaning up entity %d", entity.entityId);
        auto id = entity.entityId; //Workaround dmd 6799
				m_Objects.remove(id);
				m_Types.remove(id);
				bool result = m_Game.octree.remove(entity);
        //logInfo("deleted %x %s => %s", cast(void*)cast(Object)entity, entity.inspect()[], result);
        Delete(entity);
			}
			m_DeadEntities.resize(0);

      foreach(entity; m_DeadClientEntities[])
      {
        auto result = m_Game.octree.remove(entity);
        //logInfo("deleted %x %s => %s", cast(void*)cast(Object)entity, entity.inspect()[], result);
        Delete(entity);
      }
      m_DeadClientEntities.resize(0);
		}
		
		EntityId nextEntityId(){
			return EntityId(m_NextEntityId++);
		}
		
		override EntityId entityId() const {
			return cast(EntityId)1;
		}
		
		override rcstring inspect(){
			return format("<%s id: %d>", this.classinfo.name, this.entityId);
		}
		
		override void debugDraw(shared(IRenderer) renderer){
			// Nothing to do right now
		}
		
		override bool syncOverNetwork() const {
			return true;
		}
	
	//
	// Do nothing stuff (WhiteHole exploded so we do it ourselfs)
	//
	
	override Position position() const {
		return Position(vec3(0, 0, 0));
	}
	override void position(Position pos){ }
	
	override Quaternion rotation() const {
		return Quaternion(vec3(1.0f,0.0f,0.0f), 0.0f);
	}
	override mat4 transformation(Position origin) const {
		return mat4.Identity();
	}
	
	override IGameObject father() const {
		return null;
	}
	override AlignedBox boundingBox() const {
		return AlignedBox(vec3(0, 0, 0), vec3(1, 1, 1));
	}
	override bool hasMoved() const {
		return false;
	}
	override void update(float timeDiff){ }
	override void postSpawn(){ }
	override void onDeleteRequest(){ }
	override void toggleCollMode(){ }
	
	override IRenderProxy renderProxy(){
		return null;
	}
	
	override void serialize(ISerializer ser, bool fullSerialization){ }
	override void resetChangedFlags(){ }
}
