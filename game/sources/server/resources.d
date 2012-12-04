module server.resources;

import game.collision;
import core.hashmap;
import core.refcounted;
import thBase.format;
import thBase.logging;

//private CollisionHull[string] loadedResources;
private Hashmap!(rcstring, CollisionHull) loadedResources;

static ~this()
{
  Delete(loadedResources);
}


/**
 * Loads the entire list of collision hulls.
 */
public void loadCollisions(rcstring[2][] nameFilePairs){
	foreach(i, pair; nameFilePairs){
		auto name = pair[0];
		auto path = pair[1];
		loadCollision(name, path);
	}
}

public CollisionHull loadCollision(rcstring name, rcstring path){
	logInfo("resources: loading %s from %s...", name[], path[]);
  if(loadedResources is null)
  {
    loadedResources = New!(typeof(loadedResources))();
  }
	
	auto res = New!CollisionHull(path);
	loadedResources[name] = res;
	return res;
}

public void unloadCollisions()
{
  foreach(ref K, V; loadedResources)
  {
    Delete(V);
  }
  loadedResources.clear();
}

/**
 * Returns the previously loaded resources that were stored under the specified
 * `name`.
 */
public CollisionHull col(rcstring name){
  if(loadedResources.exists(name))
    return loadedResources[name];
	throw New!RCException(format("resources: could not find the resources for '%s'. It's probably not loaded.", name[]));
}
