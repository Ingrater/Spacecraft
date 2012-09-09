module renderer.shaderconstants;

import renderer.shader;
import renderer.uniformtype;
import thBase.math3d.all;
import renderer.globalvariables;
import renderer.exceptions;
import thBase.container.hashmap;
import thBase.format;


/**
 * Interface for a shader constant library
 */
interface ShaderConstantLib {
	/**
	 * Gets a shader constant
	 * Returns: the shader constant or null if not found
	 */
	ShaderConstant GetShaderConstant(rcstring pName);
	
	/**
	 * Registers a new shader constant
	 * Throws a exception if the shader constant already exists
	 */ 
	void RegisterShaderConstant(rcstring pName, ShaderConstant pConstant);
}

/**
 * Simple implementation of shader constant library
 */
class ShaderConstantLibImpl : ShaderConstantLib {
private:
  Hashmap!(rcstring, ShaderConstant) m_Map;
public:	
	this(){
    m_Map = New!(typeof(m_Map))();
	}

  ~this()
  {
    foreach(ref rcstring name, ShaderConstant constant; m_Map)
    {
      Delete(constant);
    }
    Delete(m_Map);
  }

	override ShaderConstant GetShaderConstant(rcstring pName){
		if(!m_Map.exists(pName)){
			throw New!RendererException(format("The shader constant '%s' does not exist", pName[]));
		}
		return m_Map[pName];
	}
	
  /**
   * Registers a shader constant. The ConstantLib takes ownership of the constant
   *
   * Params:
   *  pName = the name of the shader constant
   * 
   *  pConstant = the constant
   */
	override void RegisterShaderConstant(rcstring pName, ShaderConstant pConstant)
	{
		if(m_Map !is null){
			if(m_Map.exists(pName))
				throw New!RCException(format("ShaderConstant %s already exists in this Library", pName[]));
		}
		m_Map[pName] = pConstant;
	}
}

/**
 * Base class for every shaderconstant
 */
abstract class ShaderConstant {
protected:
	Shader m_InUse;
	int m_UsageNum;
	bool m_Overwrite;
	bool m_ToReupload;
	int m_Order;
	
	void WrongTypeError(){
		assert(0,"You tried to use a shader constant with a wrong type");
	}
public:
	abstract void Update(int pNum, Shader pRef);
	
	/**
     * Sets the shader constant to a given value
     * the value has to match the constant in type, otherwise there will be a runtime error
     * Params:
     *		value = the value to set
     */
	void Set(int value){WrongTypeError();}
	void Set(float value){WrongTypeError();} ///ditto
	void Set(vec2 value){WrongTypeError();} ///ditto
	void Set(ref const(vec3) value){WrongTypeError();} ///ditto
	void Set(ref const(vec4) value){WrongTypeError();} ///ditto
	void Set(vec3[] value){WrongTypeError();} ///ditto
	void Set(vec4[] value){WrongTypeError();} ///ditto
	void Set(ref const(mat3) value){WrongTypeError();} ///ditto
	void Set(ref const(mat4) value){WrongTypeError();} ///ditto
	void Set(mat4[] value){WrongTypeError();} ///ditto

	/**
	 * Overwrites the value with the given one for the given scope
	 * the value has to match the constant in type, otherwise there will be a runtime error
	 * Params:
	 *		value = the value to overwrite with
	 */
	void Overwrite(int value){WrongTypeError();} 
	void Overwrite(float value){WrongTypeError();} ///ditto
	void Overwrite(vec2 value){WrongTypeError();} ///ditto
	void Overwrite(ref const(vec3) value){WrongTypeError();} ///ditto
	void Overwrite(ref const(vec4) value){WrongTypeError();} ///ditto
	void Overwrite(vec3[] value){WrongTypeError();} ///ditto
	void Overwrite(vec4[] value){WrongTypeError();} ///ditto
	void Overwrite(ref const(mat3) value){WrongTypeError();} ///ditto
	void Overwrite(ref const(mat4) value){WrongTypeError();} ///ditto
	void Overwrite(mat4[] value){WrongTypeError();} ///ditto
	void Overwrite(ref const(renderer.uniformtype.Overwrite) value){WrongTypeError();} ///ditto
	
	/**
	 * reuploads the shaderconstant to the graphics card
	 */
	abstract void Reupload();
	
	/**
	 * Returns: the type of the shaderconstant
	 */
	abstract UniformType GetType();
	
	void SetOverwrite(bool value){m_Overwrite = value;}
	
	/**
	 * Returns: If the shaderconstant needs to be reuploaded or not
	 */
	bool ToReupload() 
	{
		return m_ToReupload;
	}
	
	int opCmp(ShaderConstant o)
	{
		return this.m_Order - o.m_Order;
	}

  bool Equals(ShaderConstant rh)
  {
    return (this is rh);
  }
}

/**
 * Shader constant that stores the data inside
 */
class ShaderConstantSimpleType(T) : ShaderConstant {
private:
	T m_Data;
	T m_OverwriteData;
public:
	alias Object.opCmp opCmp;
	alias ShaderConstant.opCmp opCmp;
	
	override void Update(int pNum, Shader pRef){
		if(!m_Overwrite){
			pRef.SetUniform(pNum,m_Data);
			m_ToReupload = false;
		}
		else {
			pRef.SetUniform(pNum,m_OverwriteData);
		}
		m_InUse = pRef;
		m_UsageNum = pNum;		
	}
	
	alias ShaderConstant.Set Set;
	static if(T.sizeof > 8){
		override void Set(ref const(T) value){
			if(!m_Overwrite)
				m_Data = value;
			else
				m_OverwriteData = value;
		}
	}
	else {
		override void Set(T value){
			if(!m_Overwrite)
				m_Data = value;
			else
				m_OverwriteData = value;	
		}
	}
	
	alias ShaderConstant.Overwrite Overwrite;
	static if(T.sizeof > 8){
		override void Overwrite(ref const(T) value){
			m_OverwriteData = value;
			m_Overwrite = true;
			m_ToReupload = true;
		}
	}
	else {
		override void Overwrite(T value){
			m_OverwriteData = value;
			m_Overwrite = true;
			m_ToReupload = true;
		}
	}
	
	override void Overwrite(ref const(renderer.uniformtype.Overwrite) value){
		if(value.type != TypeToUniformType!(T)){
			WrongTypeError();
		}
		m_OverwriteData = value.Get!T();
		m_Overwrite = true;
		m_ToReupload = true;
	}
	
	override void Reupload(){
		if(!m_Overwrite){
			m_InUse.SetUniform(m_UsageNum,m_Data);
			m_ToReupload = false;
		}
		else
			m_InUse.SetUniform(m_UsageNum,m_OverwriteData);
	}
	
	override UniformType GetType()
	{
		static if(is(T == float))
			return UniformType.FLOAT;
		else static if(is(T == int))
			return UniformType.INT;
		else static if(is(T == vec2))
			return UniformType.VEC2;
		else static if(is(T == vec3))
			return UniformType.VEC3;
		else static if(is(T == vec4))
			return UniformType.VEC4;
		else static if(is(T == mat2))
			return UniformType.MAT2;
		else static if(is(T == mat3))
			return UniformType.MAT3;
		else static if(is(T == mat4))
			return UniformType.MAT4;
		else
			static assert(0,"unsupported type " ~ T.stringof);
	}
	
	/**
	 * Returns: the value of this constant
	 */
	ref const(T) Get() const {
		if(m_Overwrite){
			return m_OverwriteData;
		}
		else {
			return m_Data;
		}
	}
}

/**
 * Shader constant that stores the value inside a GlobalVariable
 */
class ShaderConstantRef(T) : ShaderConstant {
private:
	const(GlobalVariableBasicType!(T)) m_RefData;
	T m_OverwriteData;
public:
	/**
	 * constructor
	 * Params:
	 *	pRef = the global variable where the data is stored
	 */
	this(const(GlobalVariableBasicType!(T)) pRef){
		m_RefData = pRef;
	}
	
	alias Object.opCmp opCmp;
	alias ShaderConstant.opCmp opCmp;
	
	override void Update(int pNum, Shader pRef){
		if(!m_Overwrite){
			pRef.SetUniform(pNum,m_RefData.Get());
			m_ToReupload = false;
		}
		else
			pRef.SetUniform(pNum,m_OverwriteData);
		m_InUse = pRef;
		m_UsageNum = pNum;
	}
	
	alias ShaderConstant.Set Set;
	static if(T.sizeof > 8){
		override void Set(ref const(T) value){
			if(!m_Overwrite)
				assert(0,"Can not set a ShaderConstantRef. only possible to overwrite");
			else
				m_OverwriteData = value;
		}
	}
	else {
		override void Set(T value){
			if(!m_Overwrite)
				assert(0,"Can not set a ShaderConstantRef. only possible to overwrite");
			else
				m_OverwriteData = value;
		}
	}
	
	alias ShaderConstant.Overwrite Overwrite;
	static if(T.sizeof > 8){
		override void Overwrite(ref const(T) value){
			m_OverwriteData = value;
			m_Overwrite = true;
			m_ToReupload = true;
		}		
	}
	else {
		override void Overwrite(T value){
			m_OverwriteData = value;
			m_Overwrite = true;
			m_ToReupload = true;
		}
	}
	
	override void Overwrite(ref const(renderer.uniformtype.Overwrite) value){
		if(value.type != TypeToUniformType!(T)){
			WrongTypeError();
		}
		m_OverwriteData = value.Get!T();
		m_Overwrite = true;
		m_ToReupload = true;
	}
	
	override void Reupload(){
		if(!m_Overwrite){
			m_InUse.SetUniform(m_UsageNum,m_RefData.Get());
			m_ToReupload = false;
		}
		else
			m_InUse.SetUniform(m_UsageNum,m_OverwriteData);
	}
	
	override UniformType GetType()
	{
		static if(is(T == float))
			return UniformType.FLOAT;
		else static if(is(T == int))
			return UniformType.INT;
		else static if(is(T == vec2))
			return UniformType.VEC2;
		else static if(is(T == vec3))
			return UniformType.VEC3;
		else static if(is(T == vec4))
			return UniformType.VEC4;
		else static if(is(T == mat2))
			return UniformType.MAT2;
		else static if(is(T == mat3))
			return UniformType.MAT3;
		else
			static assert(0,"unsupported type");
	}
}

/**
 * Base class for every shader constant that depends on a mat4
 */
abstract class ShaderConstantMat4Child : ShaderConstant {
public:
	override UniformType GetType() { return UniformType.MAT4; }
	/**
	 * Returns: the value of this constant
	 */
	abstract mat4 GetData() const;
}

/**
 * a mat4 shader constant, it can have childs
 */
class ShaderConstantMat4 : ShaderConstantMat4Child {
private:
	const(GlobalVariableBasicType!(mat4)) m_Data;
	mat4 m_OverwriteData;
public:
	this(GlobalVariableBasicType!(mat4) pData)
	in {
		assert(pData !is null,"pData may not be null");
	}
	body {
		m_Data = pData;
	}
	
	alias Object.opCmp opCmp;
	alias ShaderConstant.opCmp opCmp;
	override void Update(int pNum, Shader pShader)
	in {
		assert(m_Data !is null);
	}
	body {
		if(!m_Overwrite){
			pShader.SetUniform(pNum,4,false,m_Data.Get().f);
			m_ToReupload = false;
		}
		else
			pShader.SetUniform(pNum,4,false,m_OverwriteData.f);
		m_InUse = pShader;
		m_UsageNum = pNum;
	}
	
	alias ShaderConstant.Set Set;
	override void Set(ref const(mat4) value){
		if(!m_Overwrite)
			assert(0,"ShaderConstantMat4 can not be set");
		else
			m_OverwriteData = value;
	}
	
	alias ShaderConstant.Overwrite Overwrite;
	override void Overwrite(ref const(mat4) value)
	{
		m_Overwrite = true;
		m_ToReupload = true;
		m_OverwriteData = value;
	}
	
	override void Overwrite(ref const(renderer.uniformtype.Overwrite) value){
		if(value.type != TypeToUniformType!(mat4)){
			WrongTypeError();
		}
		m_OverwriteData = value.Get!mat4();
		m_Overwrite = true;
		m_ToReupload = true;
	}
	
	override void Reupload(){
		if(!m_Overwrite){
			m_InUse.SetUniform(m_UsageNum,4,false,m_Data.Get().f);
			m_ToReupload = false;
		}
		else
			m_InUse.SetUniform(m_UsageNum,4,false,m_OverwriteData.f);
	}
	
	override mat4 GetData() const {
		if(m_Overwrite)
			return m_OverwriteData;
		return m_Data.Get();
	}
}

/**
 * a mat4 shader constant
 * its the inverse of a given mat4 constant
 */
class ShaderConstantMat4ChildInverse : ShaderConstantMat4Child {
private:
	GlobalVariableBasicType!(mat4) m_Data;
	ShaderConstantMat4Child m_Father;
public:
	this(GlobalVariableBasicType!(mat4) pData)
	in {
		assert(pData !is null);
	}
	body {
		m_ToReupload = true;
		m_Data = pData;
	}
	
	/**
	 * Sets for which mat4 constant the inverse should be computed
	 * Params:
	 *		pFather = reference to the father
	 */
	void SetFather(ShaderConstantMat4Child pFather) { m_Father = pFather; }
	
	alias ShaderConstant.Set Set;
	alias Object.opCmp opCmp;
	alias ShaderConstant.opCmp opCmp;
	override void Set(ref const(mat4) value){
		assert(0,"can not set a Mat4ChildInverse");
	}
	
	alias ShaderConstant.Overwrite Overwrite;
	override void Overwrite(ref const(mat4) value){
		assert(0,"ShaderConstantMat4ChildInverse can not be overwritten");
	}
	
	override void Update(int pNum, Shader pShader)
	in {
		assert(m_Data !is null);
		assert(m_Father !is null);
	}
	body {
		m_Data.Set(m_Father.GetData().Inverse());
		pShader.SetUniform(pNum,4,false,m_Data.Get().f);
		m_InUse = pShader;
		m_UsageNum = pNum;
	}
	
	override void Reupload()
	in{
		assert(m_Data !is null);
		assert(m_Father !is null);
	}
	body {
		m_Data.Set(m_Father.GetData().Inverse());
		m_InUse.SetUniform(m_UsageNum,4,false,m_Data.Get().f);
	}
	
	override mat4 GetData() const {
		return m_Data.Get();
	}
}

/**
 * a mat4 shader constant
 * multiplies to other mat4 shader constants
 */
class ShaderConstantMat4ChildMul : ShaderConstantMat4Child {
private:
	GlobalVariableBasicType!(mat4) m_Data;
	ShaderConstantMat4Child m_Father1 = null;
	ShaderConstantMat4Child m_Father2 = null;
public:
	this(GlobalVariableBasicType!(mat4) pData){
		m_Data = pData;
		m_ToReupload = true;
	}
	
	alias Object.opCmp opCmp;
	alias ShaderConstant.opCmp opCmp;
	
	/**
	 * sets first operand
	 */
	void SetFather1(ShaderConstantMat4Child pFather1){m_Father1 = pFather1;}
	/**
	 * sets second operand
	 */
	void SetFather2(ShaderConstantMat4Child pFather2){m_Father2 = pFather2;}
	
	override void Update(int pNum, Shader pShader)
	in {
		assert(m_Data !is null);
		assert(m_Father1 !is null);
		assert(m_Father2 !is null);
	}
	body {
		m_Data.Set(m_Father1.GetData() * m_Father2.GetData());
		pShader.SetUniform(pNum,4,false,m_Data.Get().f);
		m_InUse = pShader;
		m_UsageNum = pNum;
	}
	
	alias ShaderConstant.Set Set;
	override void Set(ref const(mat4) value)
	{
		assert(0,"ShaderConstantMat4ChildMul can not be set");
	}
	
	alias ShaderConstant.Overwrite Overwrite;
	override void Overwrite(ref const(mat4) value)
	{
		assert(0,"ShaderConstantMat4ChildMul can not be overwritten");
	}
	
	override void Reupload()
	in {
		assert(m_Data !is null);
		assert(m_Father1 !is null);
		assert(m_Father2 !is null);
	}
	body {
		m_Data.Set(m_Father1.GetData() * m_Father2.GetData());
		m_InUse.SetUniform(m_UsageNum,4,false,m_Data.Get().f);
	}
	
	override mat4 GetData() const { return m_Data.Get(); }
};

/**
 * a mat3 shader constants
 * computes a normal matrix (inverse transposed) out of a mat4 constant
 */
class ShaderConstantMat4ChildNormal : ShaderConstant {
private:
	GlobalVariableBasicType!(mat3) m_Data;
	ShaderConstantMat4Child m_Father = null;
public:
	this(GlobalVariableBasicType!(mat3) pData) {
		m_Data = pData;
		m_ToReupload = true; 
	}
	
	alias Object.opCmp opCmp;
	alias ShaderConstant.opCmp opCmp;
	
	override void Update(int pNum, Shader pShader)
	in {
		assert(m_Data !is null);
		assert(m_Father !is null);
	}
	body {
		m_Data.Set(m_Father.GetData().NormalMatrix());
		pShader.SetUniform(pNum,3,false,m_Data.Get().f);
		m_InUse = pShader;
		m_UsageNum = pNum;
	}
	
	override void Reupload()
	in {
		assert(m_Data !is null);
		assert(m_Father !is null);
	}
	body {
		m_Data.Set(m_Father.GetData().NormalMatrix());
		m_InUse.SetUniform(m_UsageNum,3,false,m_Data.Get().f);
	}
	
	alias ShaderConstant.Set Set;
	override void Set(ref const(mat3) value){
		assert(0,"ShaderConstantMat4ChildNormal can not be set");
	}
	
	alias ShaderConstant.Overwrite Overwrite;
	override void Overwrite(ref const(mat3) value){
		assert(0,"ShaderConstantMat4ChildNormal can not be overwritten");
	}
	
	/**
	 * sets the mat4 constant to compute the normal matrix for
	 */
	void SetFather(ShaderConstantMat4Child pFather) { m_Father = pFather; }
	
	override UniformType GetType() {
		return UniformType.MAT3;
	}
}
