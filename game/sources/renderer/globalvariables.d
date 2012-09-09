module renderer.globalvariables;

import thBase.math3d.all;

import thBase.serialize.wrapper;

/**
 * Base class for a global variable which can be used by shader constants
 */
abstract class GlobalVariable {
protected:
	void WrongType(){
		assert(0,"Using wrong type with a global variable");
	}
public:
	
	/**
	 * sets the value of this global, does runtime check for correct type
	 * Params:
	 *  value = value to set
	 */
	void Set(int value){WrongType();}
	void Set(float value){WrongType();} /// ditto
	void Set(vec2 value){WrongType();} /// ditto
	void Set(vec3 value){WrongType();} /// ditto
	void Set(vec4 value){WrongType();} /// ditto
	void Set(mat2 value){WrongType();} /// ditto
	void Set(mat3 value){WrongType();} /// ditto
	void Set(mat4 value){WrongType();} /// ditto
	
	/**
	 * Reads the value out of the constant, does runtime check for correct type
	 * Params:
	 *  value = where to output the value to
	 */
	void Read(out int value){WrongType();}
	void Read(out float value){WrongType();} /// ditto
	void Read(out vec2 value){WrongType();} /// ditto
	void Read(out vec3 value){WrongType();} /// ditto
	void Read(out vec4 value){WrongType();} /// ditto
	void Read(out mat2 value){WrongType();} /// ditto
	void Read(out mat3 value){WrongType();} /// ditto
	void Read(out mat4 value){WrongType();} /// ditto
}

/**
 * A basic global variable
 */
class GlobalVariableBasicType(T) : GlobalVariable {
private:
	T m_Data;
public:
	static assert(is(T == int) ||
	              is(T == float) ||
	              is(T == vec2) ||
	              is(T == vec3) ||
	              is(T == vec4) ||
	              is(T == mat2) ||
	              is(T == mat3) ||
	              is(T == mat4)
	              ,"Wrong type for GlobalVariableBasicType");
	
	alias GlobalVariable.Set Set;
	override void Set(T value){
		m_Data = value;
	}
	
	alias GlobalVariable.Read Read;
	override void Read(out T value) const
	{
		value = m_Data;
	}
	
	/**
	 * gets the value of the variable
	 */
	ref const(T) Get() const { return m_Data; }
	
	static if(is(T == int) || is(T == float)){
		XmlValue!T XmlGetValue(){ return XmlValue!T(m_Data); }
		void XmlSetValue(XmlValue!T value){ m_Data = value.value;}
	}
	else {
		T XmlGetValue(){ return m_Data; }
		void XmlSetValue(T value){ m_Data = value;}
	}
}