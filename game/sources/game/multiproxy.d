module game.multiproxy;

import base.gameobject, base.renderproxy;

/**
 * A basic multiplexer proxy. Allows a game object to have multiple render
 * proxies attached to it.
 * 
 * FIXME: Even this simple render proxy causes all sorts of seg faults.
 * Something is really wrong here. This proxy can not be used safely right now.
 */
class MultiProxy : IRenderProxy {
	SmartPtr!IRenderProxy target;
	
	this(IRenderProxy target){
		this.target = target;
	}
	
	override void extractDo(IGameObject object, IRendererExtractor extractor){
		target.extractDo(object, extractor);
	}
	
	override void extractDo(IRenderable object, IRendererExtractor extractor){
		target.extractDo(object, extractor);
	}
	
	/+
	IRenderProxy[ubyte] targets;
	
	void extract(IGameObject object, IRendererExtractor extractor){
		foreach(proxy; targets)
			proxy.extract(object, extractor);
	}
	
	void extract(IRenderable object, IRendererExtractor extractor){
		assert(0, "MultiProxy is only for game objects, sorry");
	}
	
	void add(ubyte key, IRenderProxy proxy){
		targets[key] = proxy;
	}
	
	void remove(ubyte key){
		targets.remove(key);
	}
	+/
}
