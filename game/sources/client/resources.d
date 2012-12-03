module client.resources;

import base.all, base.renderer, game.progressbar;
import thBase.format;
import core.refcounted, core.allocator, core.hashmap;
import core.stdc.stdio;
import thBase.logging;

struct resource {
	shared(IModel) model;
	AlignedBox boundingBox;
	SmartPtr!IRenderProxy proxy;	
}

//__gshared private resource[string] loadedResources;
__gshared private Hashmap!(rcstring, resource) loadedResources;

shared static this()
{
  loadedResources = New!(typeof(loadedResources))();
}

shared static ~this()
{
  Delete(loadedResources);
}

/**
 * Loads the entire list of models and updates the progress bar text and status
 * corresponding to the number of models to load.
 */
public void loadModels(ProgressBar progressBar, IGame game, float start, float end, rcstring[][] nameFilePairs){
	float progressStep = (end - start) / nameFilePairs.length;
	foreach(i, pair; nameFilePairs){
		auto name = pair[0];
		auto path = pair[1];
		
		progressBar.status = format("Loading %s (%s)", name[], path[]);
    game.RunExtractor();
		loadModel(name, path);
		progressBar.progress = progressStep * (i + 1);
	}
}

public void unloadModels()
{
  foreach(ref name, ref res; loadedResources)
  {
    Delete(res.model);
  }
}

/**
 * Loads the model, bounding box and render proxy from the file `path`. The
 * resources are stored under the specified `name` and can be accessed from
 * anywhere with the `model()` function.
 */
public resource loadModel(rcstring name, rcstring path){
	logInfo("resources: loading %s from %s...", name[], path[]);
	
	resource res;
	res.model = g_Env.renderer.assetLoader.LoadModel(path);
	
	vec3 minBounds, maxBounds;
	res.model.FindMinMax(minBounds, maxBounds);
	res.boundingBox = AlignedBox(Position(minBounds), Position(maxBounds));
	
	res.proxy = g_Env.renderer.CreateRenderProxy(res.model);
	
	loadedResources[name] = res;
	return res;
}

/**
 * Returns the previously loaded resources that were stored under the specified
 * `name`. 
 */
public resource model(rcstring name){
	if (loadedResources.exists(name))
  {
		auto res = loadedResources[name];
    return res;
  }
	throw New!RCException(format("resources: could not find the resources for '%s'. It's probably not loaded.", name[]));
}
