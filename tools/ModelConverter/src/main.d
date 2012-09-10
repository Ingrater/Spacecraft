import thBase.io;
import thBase.string;
import thBase.container.stack;
import thBase.scoped;
import thBase.file;
import thBase.chunkfile;
import assimp.assimp;

void ProgressModel(string path)
{
  try
  {
		const(aiScene)* scene = Assimp.ImportFile(toCString(pFilename), 
                                              aiPostProcessSteps.CalcTangentSpace |
                                              aiPostProcessSteps.Triangulate |
                                              aiPostProcessSteps.JoinIdenticalVertices |
                                              aiPostProcessSteps.FlipUVs);// |
    //aiPostProcessSteps.MakeLeftHanded); // |
    //aiPostProcessSteps.PreTransformVertices );
		if(scene is null){
			throw New!FileException(format("Couldn't load model from file '%s'", pFilename[]));
		}

    rcstring outputFilename = path[0..$-3];
    outputFilename ~= ".thModel";

    auto outFile = scopedRef!Chunkfile(New!Chunkfile(ouputFilename, Chunkfile.Operation.Write));

    outFile.startWriting("thModel", ModelFormatVersion.max);
    scope(exit) outFile.endWriting();


    //Materials
    {
      outFile.startWriteChunk("materials");
      scope(exit) outFile.endWriteChunk();

      if(scene.mMaterials !is null)
      {
        outFile.write!uint(scene.mNumMaterials);


      }

    }
  }
  catch(Exception ex)
  {
    writefln("Error progressing model '%s': %s", path, ex.toString()[]);
    Delete(ex);
  }
}

int main(string[] args)
{
  auto models = scopedRef!(Stack!string)(New!(Stack!string)());
  foreach(arg; args)
  {
    if(arg.endsWith(".dae", CaseSensitive.no))
    {
      if(thBase.file.exists(arg))
        models.push(arg);
      else
      {
        writefln("File: %s does not exist", arg);
      }
    }
  }
  if(models.size == 0)
  {
    writefln("No model specified");
    return 1;
  }

  try {
    while(models.size > 0)
    {
      ProgressModel(models.pop());
    }
  }
  catch(IThrowable ex)
  {
    writefln("Fatal error: %s", ex.toString()[]);
    Delete(ex);
    return -1;
  }

  return 0;
}