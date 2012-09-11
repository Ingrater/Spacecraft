module modeltypes;

/**
* exisiting texture types
*/
enum TextureType : ubyte {
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
  UNKNOWN /// unkown texture type
}

enum ModelFormatVersion : uint
{
  Version1 = 1 //Initial version
}