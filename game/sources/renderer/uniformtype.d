module renderer.uniformtype;

import thBase.math3d.all;
import renderer.opengl;
import thBase.metatools;

/**
 * all existing types of uniforms
 */
enum UniformType : uint {
	FLOAT = gl.FLOAT, /// float
	INT = gl.INT, /// int
	VEC2 = gl.FLOAT_VEC2, /// vec2
	VEC3 = gl.FLOAT_VEC3, /// vec3
	VEC4 = gl.FLOAT_VEC4, /// vec4
	MAT2 = gl.FLOAT_MAT2, /// mat2
	MAT3 = gl.FLOAT_MAT3, /// mat3
	MAT4 = gl.FLOAT_MAT4, /// mat4
	IVEC2 = gl.INT_VEC2, /// ivec2
	IVEC3 = gl.INT_VEC3, /// ivec3
	IVEC4 = gl.INT_VEC4, /// ivec4
	SAMPLER_1D = gl.SAMPLER_1D, /// sampler1D
	SAMPLER_2D = gl.SAMPLER_2D, /// sampler2D
	SAMPLER_3D = gl.SAMPLER_3D, /// sampler3D
	SAMPLER_CUBE = gl.SAMPLER_CUBE, /// samplerCube
	UNKOWN /// Unkown
}

/**
 * converts a D type to a UniformType enum value
 */
template TypeToUniformType(T){
	static if(is(T==int))
		alias UniformType.INT TypeToUniformType;
	else static if(is(T==float))
		alias UniformType.FLOAT TypeToUniformType;
	else static if(is(T==vec2))
		alias UniformType.VEC2 TypeToUniformType;
	else static if(is(T==vec3))
		alias UniformType.VEC3 TypeToUniformType;
	else static if(is(T==vec4))
		alias UniformType.VEC4 TypeToUniformType;
	else static if(is(T==mat2))
		alias UniformType.MAT2 TypeToUniformType;
	else static if(is(T==mat3))
		alias UniformType.MAT3 TypeToUniformType;
	else static if(is(T==mat4))
		alias UniformType.MAT4 TypeToUniformType;
	else 
		static assert(0,"Type can not be converted " ~ T.stringof);
}

/**
 * Struct to store shader constant overwrites in other places then the shader constant itself
 * For example used in RenderGroup, RenderCall and Model
 */ 
struct Overwrite {
	union {
		int i;	/// integer value only valid if type matches
		float f; /// float value only valid if type matches
		vec2 v2; /// vec2 value only valid if type matches
		vec3 v3; /// vec3 value only valid if type matches
		vec4 v4; /// vec4 value only valid if type matches
		mat2 m2; /// mat2 value only valid if type matches
		mat3 m3; /// mat3 value only valid if type matches
		mat4 m4; /// mat4 value only valid if type matches
	}
	UniformType type; /// Stored type
	
	/**
	 * Sets the overwrite struct to the given type
	 * automatically sets the type field correctly
	 */ 
	void Set(T)(T pValue){
		static if(is(T == int) || is(T == const(int)))
			i = pValue;
		else static if(is(T == float) || is(T == const(float)))
			f = pValue;
		else static if(is(T == vec2) || is(T == const(vec2)))
			v2 = pValue;
		else static if(is(T == vec3) || is(T == const(vec3)))
			v3 = pValue;
		else static if(is(T == vec4) || is(T == const(vec4)))
			v4 = pValue;
		else static if(is(T == mat2) || is(T == const(mat2)))
			m2 = pValue;
		else static if(is(T == mat3) || is(T == const(mat3)))
			m3 = pValue;
		else static if(is(T == mat4) || is(T == const(mat4)))
			m4 = pValue;
		else 
			static assert(0,"Trying to set overwrite with not implemented datatype " ~ T.stringof);
		type = TypeToUniformType!(StripConst!(T));
	}
	
	/**
	 * Tries to get the data stored in this overwrite sturct as the given type T
	 * Performs a runtime check if the stored type matches the type to get
	 */ 
	T Get(T)() const
	in {
		assert(TypeToUniformType!T == type,"Trying to get wrong type " ~ T.stringof);
	}
	body {
		static if(is(T == int))
			return i;
		else static if(is(T == float))
			return f;
		else static if(is(T == vec2))
			return v2;
		else static if(is(T == vec3))
			return v3;
		else static if(is(T == vec4))
			return v4;
		else static if(is(T == mat2))
			return m2;
		else static if(is(T == mat3))
			return m3;
		else static if(is(T == mat4))
			return m4;
		else
			static assert(0,"Trying to get not implemented type from Overwrite " ~ T.stringof);
	}
}