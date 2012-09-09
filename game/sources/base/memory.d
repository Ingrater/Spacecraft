module base.memory;

public import core.stdc.stdlib;
public import core.stdc.string;
public import core.exception;
public import core.memory;
public import core.stdc.stdio;
public import core.sync.mutex;

/**
 * mixin template for growing memory pool (TODO fix)
 */
mixin template GrowingPool(T){
	private struct MemoryRange {
		void* start;
		void* end;
		void* current;
		
		this(void* start, void* end){
			this.start = start;
			this.end = end;
			this.current = start;
		}
	}
	private enum MEMORY_POOL_SIZE = 1000 * T.sizeof;
	
	private static MemoryRange[] MemoryPool;
	
	static this(){
		void *p = malloc(MEMORY_POOL_SIZE);
		printf("Initial malloc");
		if(!p)
			throw new OutOfMemoryError(__FILE__,__LINE__);
		GC.addRange(p,MEMORY_POOL_SIZE);
		MemoryPool ~= MemoryRange(p,p+MEMORY_POOL_SIZE);
	}
	
	static ~this(){
		try {
		int count = 0;
		foreach(ref range;MemoryPool){
			GC.removeRange(range.start);
			free(range.start);
			count++;
		}
		printf(T.stringof ~ " pool was %d elements in size",MEMORY_POOL_SIZE / T.sizeof * count);
		MemoryPool = null;
		} catch(Throwable e){ asm { int 3; } }
	}
	
	public new(size_t sz){
		foreach(ref range;MemoryPool){
			if(range.current + sz <= range.end){
				void *p = range.current;
				range.current += sz;
				return p;
			}
		}
		
		void *p = malloc(MEMORY_POOL_SIZE);
		printf("new malloc");
		if(!p)
			throw new OutOfMemoryError(__FILE__,__LINE__);
		GC.addRange(p,MEMORY_POOL_SIZE);
		
		auto range = MemoryRange(p,p+MEMORY_POOL_SIZE);
		range.current += sz;
		MemoryPool ~= range;
		return p;
	}
	
	public delete(void* p){
		assert(0,"Can not delete a " ~ T.stringof);
	}
	
	static void FreeInstances(){
		foreach(ref range;MemoryPool){
			range.current = range.start;
		}
	}
}

/**
 * SameSizePool 
 */
mixin template SameSizePool(T,size_t startSize) {
	private:
		struct MemPool {
			byte* start;
			byte* end;
			MemPool* next;
			
			public new(size_t sz){
				return malloc(sz);
			}
			
			public delete(void *p){
				if(p !is null)
					free(p);
			}
		}
		
		__gshared immutable(size_t) ELEMENT_SIZE;
		__gshared MemPool* memStart = null;
		__gshared size_t memSize = startSize;
		__gshared byte** stackStart = null;
		__gshared byte** stackEnd = null;
		__gshared byte** stackCur = null;
		__gshared Mutex mutex;
		
		shared static this() {
			mutex = new Mutex;
			static if(is(T == class)){
				ELEMENT_SIZE = T.classinfo.init.length;
			}
			else {
				ELEMENT_SIZE = T.sizeof;
			}
			memSize *= ELEMENT_SIZE;
			//writefln("new Pool %d -> %d" ~ T.stringof, ELEMENT_SIZE, memSize);
			//writefln("thread %x",core.thread.Thread.getThis().toHash());
			memStart = new MemPool();
			//writefln("new MemPool %x",memStart);
			memStart.start = cast(byte*)malloc(memSize);
			memStart.end = memStart.start + memSize;
			memset(memStart.start,0,memSize);
			//writefln("new MemRange %x",memStart.start);
			GC.addRange(memStart.start,memSize);
			stackStart = cast(byte**)malloc(startSize * (byte*).sizeof);
			stackEnd = stackStart + startSize;
			stackCur = stackStart;
			for(byte* cur = memStart.start;cur < memStart.end;cur+=ELEMENT_SIZE){
				assert(stackStart <= stackCur && stackCur < stackEnd);
				*stackCur = cur;
				stackCur++;
			}
			//writefln("stackStart %x, stackEnd %x, stackCur %x",stackStart,stackEnd,stackCur);
			//writefln("allocated stackStart %x "~T.stringof,stackStart);
		}
		
		shared static ~this() {
			try {
			//writefln("thread %x",core.thread.Thread.getThis().toHash());
			size_t numElems = 0;
			MemPool* cur = memStart;
			while(cur !is null){
				numElems += (cur.end - cur.start) / ELEMENT_SIZE;
				MemPool* next = cur.next;
				//writefln("Freeing pool %x",cur.start);
				GC.removeRange(cur.start);
				free(cur.start);

				//writefln("delete MemPool %x",cur);
				delete cur;
				cur = next;
			}
			//writefln("free stack start %x "~T.stringof,stackStart);
			//this free operation crashes for whatever reason
			if(stackStart !is null)
				free(stackStart);
			base.logger.info("Total pool size of " ~ __traits(identifier,T) ~ " was %d taking %dkb", numElems, numElems * ELEMENT_SIZE / 1024);
			} catch(Throwable e){ asm { int 3; } }
		}
		
		public new(size_t sz)
		in {
			assert(sz == ELEMENT_SIZE);
		}
		body {
			assert(mutex !is null);
			synchronized(mutex){
				//writefln("new "~ T.stringof);
				if(stackStart is stackCur){
					//no free memory left
					MemPool* pool = new MemPool();
					assert(pool !is null);
					memSize *= 2;
					//writefln("pool = %x, start = %x, allocating %d",pool,pool.start,memSize);
					debug base.logger.info("new pool for " ~ T.stringof);
					pool.start = cast(byte*)malloc(memSize);
					memset(pool.start,0,memSize);
					//writefln("new pool %x %d",pool.start,memSize);
					GC.addRange(pool.start,memSize);
					pool.end = pool.start + memSize;
					
					//we need room for memSize elements on the free stack so lets see
					//if we need to extend the stack
					size_t numElements = memSize / ELEMENT_SIZE;
					if(stackEnd - stackStart < numElements){
						free(stackStart); //we can delete the stack memory here because it is empty
						stackStart = cast(byte**)malloc(numElements * (byte*).sizeof);
						stackEnd = stackStart + numElements;
						stackCur = stackStart;
						//writefln("new stack %x %d" ~ T.stringof,stackStart,memSize);
					}
					
					pool.next = memStart;
					memStart = pool;
					
					//initialize elements
					//writefln("initializing elements");
					for(byte* cur = pool.start;cur < pool.end;cur+=ELEMENT_SIZE){
						assert(pool.start <= cur && cur < pool.end);
						addFree(cur);
					}
				}
				stackCur--;
				assert(stackStart <= stackCur && stackCur < stackEnd);
				return *stackCur;
			}
			assert(0,"not reachable");
		}
		
		public delete(void* p)
		in {
			bool found = false;
			for(MemPool* pool = memStart;pool !is null; pool = pool.next){
				if(pool.start <= p && p < pool.end){
					found = true;
					break;
				}
			}
			assert(found == true,"trying to free a pointer that is not inside a pool");
		}
		body {
			assert(mutex !is null);
			synchronized(mutex){
				//writefln("delete "~ T.stringof);
				byte* cur = cast(byte*)p;
				memset(cur,0,ELEMENT_SIZE);
				addFree(cur);
			}
		}
		
		static void addFree(byte* elem) 
		in {
			bool found = false;
			for(MemPool* pool = memStart;pool !is null; pool = pool.next){
				if(pool.start <= elem && elem < pool.end){
					found = true;
					break;
				}
			}
			assert(found == true,"trying to add a free pointer that is not in the pool");
		}
		body {
			if(stackCur is stackEnd){
				size_t curSize = stackEnd - stackStart;
				stackStart = cast(byte**)realloc(stackStart,curSize * 2 * (byte*).sizeof);
				stackEnd = stackStart + (curSize * 2);
				stackCur = stackStart + curSize;
				//writefln("extended stack %x %d "~T.stringof,stackStart,stackEnd - stackStart);
			}
			assert(stackStart <= stackCur && stackCur < stackEnd);
			*stackCur = elem;
			stackCur++;
		}
}