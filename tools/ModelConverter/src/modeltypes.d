module modeltypes;

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