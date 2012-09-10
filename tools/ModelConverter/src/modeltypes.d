module modeltypes;

import thBase.chunkfile;

/**
* exisiting texture types
*/
enum TextureType {
  DIFFUSE, /// diffuse texture
  AMBIENT, /// ambient texture
  DISPLACEMENT, /// displacement texture
  EMISSIVE, /// emissive texture
  HEIGHT, /// heightmap (normal map for collada)
  LIGHTMAP, /// lightmap
  NONE, ///none (should never happen)
  NORMALS, /// normal map
  OPACITY, /// opacity map
  REFLECTION, /// reflection map
  SHININESS, /// shininess texture
  SPECULAR, /// specular texture
  UNKOWN /// unkown texture type
}

struct TextureInfo
{
  uint textureIndex;
  rcstring textureName;

  void ChunkfileSerialize(Chunkfile file)
  {
    if(file.operation == Chunkfile.Operation.Read)
    {
      file.write(textureIndex);
      file.writeArray(textureName);
    }
    else if(file.operation == ChunkFile.Operation.Write)
    {
      file.read(textureIndex);
      file.readAndAllocateArray(textureName);
    }
    else
    {
      assert(0, "Operation not implemented");
    }
  }
}

enum ModelFormatVersion : uint
{
  Version1 = 1 //Initial version
}