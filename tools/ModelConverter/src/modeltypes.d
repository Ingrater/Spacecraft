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
  Version1 = 1, //Initial version
  Version2 = 2  //saving material names
}

enum PerVertexData : uint
{
  Position   = 0x0001,
  Normal     = 0x0002,
  Tangent    = 0x0004,
  Bitangent  = 0x0008,
  TexCoord0  = 0x0010,
  TexCoord1  = 0x0020,
  TexCoord2  = 0x0040,
  TexCoord3  = 0x0080
}