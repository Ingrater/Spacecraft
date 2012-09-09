module renderer.shader;

import renderer.opengl;
import renderer.openglex;

import renderer.vertexbuffer;
import renderer.shaderconstants;
import thBase.math3d.all;
import thBase.container.vector;

import renderer.exceptions;
import renderer.uniformtype;

static import base.logger;
import core.stdc.stdlib;
import base.all;
import thBase.string;
import thBase.file;

/**
 * API Wrapper for OpenGL shader functions
 */
class Shader {
public:
	
	/**
	 * existing shader types
	 */
	enum ShaderType {
		VERTEX_SHADER = gl.VERTEX_SHADER, /// vertex shader
		FRAGMENT_SHADER = gl.FRAGMENT_SHADER, /// fragment (pixel) shader
		GEOMETRY_SHADER = gl.GEOMETRY_SHADER_ARB /// geometry shader
	}
	
	/**
	 * existing parameters to the geometry shader
	 */
	enum GeoShaderParam {
		INPUT, /// input primitive
		OUTPUT, /// output primitive
		OUTPUT_NUM /// maximum number of output vertices
	}
	
	/**
	 * buffer mode for transform feedback
	 */
	enum BufferMode : uint {
		INTERLEAVED_ATTRIBS = gl.INTERLEAVED_ATTRIBS_EXT, /// save attribs in a interleaved manner
		SEPARATE_ATTRIBS = gl.SEPARATE_ATTRIBS_EXT /// save attribs in a separate manner
	}
	
	/**
	 * information where a attribute should be bound to
	 */
	struct BindAttributeInfo {
		string name; /// name of the attribute inside the shader
		VertexBuffer.DataChannels channel; /// binding location
	};
	
	/**
	 * attribute load information
	 */
	struct AttributeInput {
		string name; /// name of the attribute inside the shader
		VertexBuffer.DataChannels type; /// binding location
	}
	
private:
	static struct ConstantReference {
		this(int pNum, ShaderConstant pPtr){
			m_Num = pNum;
			m_Ptr = pPtr;
		}
		int m_Num;
		ShaderConstant m_Ptr;
	};
	
	static struct UniformInfo {
		rcstring m_Name;
		UniformType m_Type;
		size_t m_Size;
	};
	
	static struct AttributeInfo {
		int m_Id;
		VertexBuffer.DataChannels m_DataType;
	};
	
	gl.handle m_ShaderProgram;
	gl.handle m_VertexShader;
	gl.handle m_GeometryShader;
	gl.handle m_FragmentShader;
	bool m_Linked = false;
	rcstring m_Name;
	Vector!(int) m_Uniforms;
	Vector!(AttributeInfo) m_Attributes;
	Vector!(ConstantReference) m_ShaderConstants;
	
	static Shader m_ActiveShader;
	
	void ShaderSource(const(char)[] pSource, out gl.handle pShader, ShaderType pShaderType){
		int CompileStatus;
		pShader = gl.CreateShader(cast(gl.GLenum)pShaderType);
		if(pShader == 0){
			throw New!OpenGLException(_T("Couldn't create shader"));
		}
		int length = cast(int)pSource.length;
    {
      auto source = toCString(pSource);
      auto csource = source.str();
		  gl.ShaderSource(pShader, 1, &csource, &length);
    }
		gl.CompileShader(pShader);
		gl.GetShaderiv(pShader,gl.COMPILE_STATUS,&CompileStatus);
		if(CompileStatus != 1){
			GetError(pShader,true);
		}
		gl.AttachShader(m_ShaderProgram,pShader);
	}
	
	void GetError(gl.handle obj, bool pIsShader){
		int infologLength = 0;
		int charsWritten = 0;
		
		if(pIsShader)
			gl.GetShaderiv(obj, gl.INFO_LOG_LENGTH, &infologLength);
		else
			gl.GetProgramiv(obj, gl.INFO_LOG_LENGTH, &infologLength);
		
		if(infologLength > 1){
			char[] infoLog = NewArray!char(infologLength);
			if(pIsShader)
				gl.GetShaderInfoLog(obj, infologLength, &charsWritten, infoLog.ptr);
			else
				gl.GetProgramInfoLog(obj, infologLength, &charsWritten, infoLog.ptr);
			throw New!OpenGLException(format("shader error :: %s\n(%d) %s", m_Name[], infologLength, infoLog), true);
		}
	}
	
	void CheckWarnings(gl.handle obj, string title, bool pIsShader){
		int infologLength = 0;
		int charsWritten = 0;
		
		if(pIsShader)
			gl.GetShaderiv(obj, gl.INFO_LOG_LENGTH, &infologLength);
		else
			gl.GetProgramiv(obj, gl.INFO_LOG_LENGTH, &infologLength);
		
		if(infologLength > 1){
			char[] infoLog = new char[infologLength];
			if(pIsShader)
				gl.GetShaderInfoLog(obj, infologLength, &charsWritten, infoLog.ptr);
			else
				gl.GetProgramInfoLog(obj, infologLength, &charsWritten, infoLog.ptr);
			if("vertex shader will run in hardware. fragment shader will run in hardware." == toLower(infoLog))
				return;
			
			auto ErrorMessage = format("Warning in shader '%s' in '%s'\n%s", m_Name[], title, infoLog);
			base.logger.warn("%s\n",ErrorMessage[]);
			
			if(indexOf(ErrorMessage,"software") != -1 || indexOf(ErrorMessage,"Software") != -1){
				throw New!OpenGLException(format("Shader '%s' seems to be running in software emulation", m_Name[]), false);
			}
		}
	}
	
	debug {
		invariant() {
			if(gl.GetContextAlive()){
				gl.ErrorCode error = gl.GetError();
        if(error != gl.ErrorCode.NO_ERROR)
        {
				  auto msg = format("Error in shader '%s' invariant: %s", m_Name[], gl.TranslateError(error));
				  assert(0, msg[]);
        }
			}
		}
	}
	
public:
	/**
	 * Constructor
	 * Params:
 	 * 		name = name of the shader to create
 	 */ 
	this(rcstring name){
		m_Name = name;
		m_Linked = false;
		m_ShaderProgram = gl.CreateProgram();
		m_VertexShader = 0;
		m_FragmentShader = 0;
		m_GeometryShader = 0;
		m_Uniforms = New!(Vector!int)();
		m_Attributes = New!(Vector!AttributeInfo)();
		m_ShaderConstants = New!(Vector!ConstantReference)();
	}
 	
 	~this(){
		if(m_VertexShader != 0){
 			gl.DetachShader(m_ShaderProgram, m_VertexShader);
 			gl.DeleteShader(m_VertexShader);
 		}
 		if(m_GeometryShader != 0){
 			gl.DetachShader(m_ShaderProgram, m_GeometryShader);
 			gl.DeleteShader(m_GeometryShader);
 		}
 		if(m_FragmentShader != 0){
 			gl.DetachShader(m_ShaderProgram, m_FragmentShader);
 			gl.DeleteShader(m_FragmentShader);
 		}
 		gl.DeleteProgram(m_ShaderProgram);

    Delete(m_Uniforms);
    Delete(m_Attributes);
    Delete(m_ShaderConstants);
 	}
 	
 	/**
 	 * loads the source from a file
 	 * Params:
 	 * 		pFileName path of the file to load
 	 *		pShaderType for wich shader part this source should be used
 	 */
 	void LoadSourceFile(const(char[]) pFileName, ShaderType pShaderType)
 	in {
 		if(m_Linked)
 			throw New!OpenGLException(format("Shader '%s' is already linked. Can not add more sourcefiles!", m_Name[]), false);
 	}
 	body {
 		auto datei = RawFile(pFileName, "r");
 		if(!datei.isOpen()){
 			throw New!FileException(format("Couldn't open '%s' for loading into shader '%s'", pFileName, m_Name[]));
 		}
 		
 		int i = datei.size();
 		
 		char[] content = NewArray!char(i);
    scope(exit) Delete(content);
 		datei.readArray(content);
 		datei.close();
 		
 		final switch(pShaderType){
 			case ShaderType.VERTEX_SHADER:
 				ShaderSource(content, m_VertexShader, ShaderType.VERTEX_SHADER);
 				break;
 			case ShaderType.FRAGMENT_SHADER:
 				ShaderSource(content, m_FragmentShader, ShaderType.FRAGMENT_SHADER);
 				break;
 			case ShaderType.GEOMETRY_SHADER:
 				ShaderSource(content, m_GeometryShader, ShaderType.GEOMETRY_SHADER);
 				break;
 		}
 	}
 	
 	/**
 	 * load the source from a string
 	 * Params:
 	 *		pSource the source
 	 *		pShaderType for which shader part this source should be used
 	 */
 	void LoadShaderSource(const(char)[] pSource, ShaderType pShaderType){
 		final switch(pShaderType){
 			case ShaderType.VERTEX_SHADER:
 				ShaderSource(pSource,m_VertexShader,ShaderType.VERTEX_SHADER);
 				break;
 			case ShaderType.FRAGMENT_SHADER:
 				ShaderSource(pSource,m_FragmentShader,ShaderType.FRAGMENT_SHADER);
 				break;
 			case ShaderType.GEOMETRY_SHADER:
 				ShaderSource(pSource,m_GeometryShader,ShaderType.GEOMETRY_SHADER);
 				break;
 		}
 	}
 	
 	/**
 	 * sets a parameter for the geometry shader
 	 * Params:
 	 *		pParam the parameter
 	 *		pValue the value to set
 	 */
 	void SetGSParameter(GeoShaderParam pParam, int pValue){
 		final switch(pParam){
 			case GeoShaderParam.INPUT:
 				//gl.ProgramParameteriARB(m_ShaderProgram,gl.GEOMETRY_INPUT_TYPE_ARB,pValue);
 				break;
 			case GeoShaderParam.OUTPUT:
 				//gl.ProgramParameteriARB(m_ShaderProgram,gl.GEOMETRY_OUTPUT_TYPE_ARB,pValue);
 				break;
 			case GeoShaderParam.OUTPUT_NUM:
 				//gl.ProgramParameteriARB(m_ShaderProgram,gl.GEOMETRY_VERTICES_OUT_ARB,pValue);
 				break;
 		}
 	}
 	
 	/**
 	 * validates the shader
 	 * throws exception if not valid
 	 */
 	void Validate()
 	in {
    debug {
      if(!m_Linked)
      {
        auto err = format("Trying to validate shader '%s' before linking!", m_Name[]);
        assert(0, err[]);
      }
    }
 	}
 	body {
 		int isValid = 0;
 		GetError(m_ShaderProgram,false);
 		gl.ValidateProgram(m_ShaderProgram);
 		gl.GetProgramiv(m_ShaderProgram,gl.VALIDATE_STATUS,&isValid);
 		if(isValid != 1){
 			GetError(m_ShaderProgram,false);
 		}
 	}
 	
 	/**
 	 * links the shader
 	 * throws a exception if an error occurs 
 	 */
 	void Link()
 	in {
    debug {
      if(m_Linked)
      {
        auto err = format("Shader '%s' is already linked. Can not re-link!", m_Name[]);
        assert(0, err[]);
      }
    }
 	}
 	body {
 		int isLinked = 0;
 		gl.LinkProgram(m_ShaderProgram);
 		gl.GetProgramiv(m_ShaderProgram,gl.LINK_STATUS,&isLinked);
 		if(isLinked != 1){
 			GetError(m_ShaderProgram,false);
 			m_Linked = false;
 			throw New!OpenGLException(format("Failed to link shader '%s' link status is %d", m_Name[], isLinked),false);
 		}
 		CheckWarnings(m_ShaderProgram,"Shader Program",false);
 		if(m_VertexShader != 0)
 			CheckWarnings(m_VertexShader,"Vertex Shader",true);
 		if(m_GeometryShader != 0)
 			CheckWarnings(m_GeometryShader,"Geometry Shader",true);
 		m_Linked = true;
 	}
 	
 	/**
 	 * uses the shader
 	 */
 	void Use()
 	in {
    debug {
      if(!m_Linked)
      {
        auto err = format("Trying to use unlinked shader '%s'", m_Name[]);
        assert(0, err[]);
      }
    }
 	}
 	body {
 		if(m_ActiveShader == this){
 			foreach(e; m_ShaderConstants.GetRange()){
 				if(e.m_Ptr.ToReupload()){
 					e.m_Ptr.Reupload();
 				}
 			}
 		}
 		else {
 			gl.UseProgram(m_ShaderProgram);
 			debug(0){
 				gl.ErrorCode error = gl.GetError();
 				if(error != gl.ErrorCode.NO_ERROR){
 					throw New!OpenGLException("Error using shader", error);
 				}
 			}
 			foreach(e; m_ShaderConstants.GetRange()){
 				e.m_Ptr.Update(e.m_Num,this);
 			}
 			m_ActiveShader = this;
 		}
 	}
 	
 	/**
 	 * Resets the overrides on all shader constants 
 	 */
 	void ResetOverwrites(){
 		foreach(e; m_ShaderConstants.GetRange()){
 			e.m_Ptr.SetOverwrite(false);
 		}
 	}
 	
 	/**
 	 * returns the name of the shader
 	 */
 	rcstring GetName() {
 		return m_Name;
 	}
 	
 	/**
 	 * Gets a attribute location
 	 * Params:
 	 * 		name = name of the attribute
 	 * Returns: the attribute location
 	 */
 	int GetAttrib(const(char)[] name){
 		int temp = gl.GetAttribLocation(m_ShaderProgram, toCString(name));
 		if(temp == -1){
 			base.logger.warn("Shader '%s'\nCouldn't find attribute '%s' in shader context", m_Name[], name);
 		}
 		return temp;
 	}
 	
 	/**
 	 * Gets a uniform location
 	 * Params:
 	 *		name = name of the uniform
 	 * Returns: location of the uniform
 	 */
 	int GetUniform(string name){
 		int temp = gl.GetUniformLocation(m_ShaderProgram, toCString(name));
 		if(temp == -1){
 			base.logger.warn("Shader '%s':\nCouldn't find Uniform Var '%s' in Shader Context", m_Name[], name);
 		}
 		return temp;
 	}
 	
 	/**
 	 * Gets informatoin about a active unform at a specified index
 	 * Params:
  	 * 		pIndex = index of the uniform
  	 *		pInfo = out: reference to info structure
  	 * Returns: true if successfull, false otherwise
  	 */
  	bool GetUniformInfo(int pIndex, ref UniformInfo pInfo){
  		int NumActiveUniforms = -1;
  		gl.GetProgramiv(m_ShaderProgram,gl.ACTIVE_UNIFORMS,&NumActiveUniforms);
  		if(pIndex >= NumActiveUniforms || pIndex < 0)
  			return false;
  		
  		char[256] UniformName;
  		int UniformSize = -1;
  		gl.GLenum Type;
  		gl.GetActiveUniform(m_ShaderProgram,pIndex,UniformName.length,null,&UniformSize,&Type,UniformName.ptr);
  		switch(Type){
  			case gl.INT:
  				pInfo.m_Type = UniformType.INT;
  				break;
  			case gl.FLOAT:
  				pInfo.m_Type = UniformType.FLOAT;
  				break;
  			case gl.FLOAT_VEC2:
  				pInfo.m_Type = UniformType.VEC2;
  				break;
  			case gl.FLOAT_VEC3:
  				pInfo.m_Type = UniformType.VEC3;
  				break;
  			case gl.FLOAT_VEC4:
  				pInfo.m_Type = UniformType.VEC4;
  				break;
  			case gl.FLOAT_MAT2:
  				pInfo.m_Type = UniformType.MAT2;
  				break;
  			case gl.FLOAT_MAT3:
  				pInfo.m_Type = UniformType.MAT3;
  				break;
  			case gl.FLOAT_MAT4:
  				pInfo.m_Type = UniformType.MAT4;
  				break;
  			case gl.INT_VEC2:
  				pInfo.m_Type = UniformType.IVEC2;
  				break;
  			case gl.INT_VEC3:
  				pInfo.m_Type = UniformType.IVEC3;
  				break;
  			case gl.INT_VEC4:
  				pInfo.m_Type = UniformType.IVEC4;
  				break;
  			case gl.SAMPLER_1D:
  				pInfo.m_Type = UniformType.SAMPLER_1D;
  				break;
  			case gl.SAMPLER_2D:
  				pInfo.m_Type = UniformType.SAMPLER_2D;
  				break;
  			case gl.SAMPLER_3D:
  				pInfo.m_Type = UniformType.SAMPLER_3D;
  				break;
  			case gl.SAMPLER_CUBE:
  				pInfo.m_Type = UniformType.SAMPLER_CUBE;
  				break;
  			default:
  				pInfo.m_Type = UniformType.UNKOWN;
  				break;
  		}
  		pInfo.m_Name = cast(string)UniformName;
  		pInfo.m_Size = UniformSize;
  		return true;
  	}
  	
  	/**
  	 * Loads a list of uniforms from the shader
  	 * Params:
  	 * 		pNames = list of uniforms to load
  	 */
  	void LoadUniforms(string[] pNames){
  		m_Uniforms.resize(pNames.length);
  		for(size_t i=0;i<m_Uniforms.size();i++){
  			m_Uniforms[i] = GetUniform(pNames[i]);
  		}
  	}
  	
  	/**
  	 * Loads a list of attributes from the shader
  	 * Params:
  	 * 		pInfo = list of attributes to load
  	 */
  	void LoadAttributes(AttributeInput[] pInfo){
  		m_Attributes.resize(pInfo.length);
  		for(size_t i=0;i<pInfo.length;i++){
  			m_Attributes[i].m_Id = GetAttrib(pInfo[i].name);
  			m_Attributes[i].m_DataType = pInfo[i].type;
  		}
  	}
  	
  	/**
  	 * loads a list of varyings from the shader
  	 * Params:
  	 *		pNames = a vector of the varyings to load
  	 */
  	/*void LoadVaryings(ref const(Vector!(string)) pNames, BufferMode pBufferMode){
  		const(char)*[] strings = new char*[pNames.size()];
  		for(size_t i=0;i<pNames.size();i++){
  			strings[i] = toStringz(pNames[i]);
  		}
  		gl.TransformFeedbackVaryingsEXT(m_ShaderProgram,pNames.size(),strings.ptr,cast(gl.GLenum)pBufferMode);
  	}*/
  	
  	/**
  	 * Binds multiple attributes to a value
  	 * Params:
  	 *		pBindInfo = vector of bind information
  	 */
  	void BindAttributes(BindAttributeInfo[] pBindInfo){
  		foreach(e; pBindInfo){
  			if(e.channel < 0)
  				continue;
  			gl.BindAttribLocation(m_ShaderProgram,VertexBuffer.DataChannelLocation(e.channel),toCString(e.name));
  		}
  	}
  	
  	/**
  	 * gets a attribute location
  	 * Params:
  	 *		pNum = number of the attribute
  	 * Returns: the attribute location
  	 */
  	int GetAttributeLocation(size_t pNum){
  		if(m_Attributes.size() > pNum)
  			return m_Attributes[pNum].m_Id;
  		return -1;
  	}
  	
  	/**
  	 * get a list of the needed data channels by this shader
  	 * Returns: A array of the needed datachannels
  	 */
  	VertexBuffer.DataChannels[] GetNeededDataChannels(VertexBuffer.DataChannels[] buffer)
  	in{
  		assert(m_Linked == true, "Shader has not been linked yet");
  		assert(m_Attributes.size() != 0, "No attributes loaded");
      assert(buffer.length >= m_Attributes.size(), "given buffer is to small");
  	}
  	body {
  		for(size_t i=0;i<m_Attributes.size();i++){
  			buffer[i] = m_Attributes[i].m_DataType;
  		}
  		return buffer[0..m_Attributes.size()];
  	}
  	
  	// Float 1-4
  	/**
  	 * sets a uniform of type float
  	 * Params:
  	 *		num = number of the uniform
  	 *		f1 = value
  	 */
  	void SetUniform(int num, float f1){
  		if(m_Uniforms[num]==-1)
  			return;
  		gl.Uniform1f(m_Uniforms[num],f1);
  	}
  	
  	/**
  	 * set a uniform of type vec2 
  	 * Params:
  	 *		num = number of the uniform
  	 *		f1 = vec2.x
  	 *		f2 = vec2.y
  	 */
  	void SetUniform(int num, float f1, float f2){
  		if(m_Uniforms[num]==-1)
  			return;
  		gl.Uniform2f(m_Uniforms[num],f1,f2);
  	}
  	
  	/**
  	 * sets a uniform of type vec3
  	 * Params:
  	 *		num = number of the uniform
  	 *		f1 = vec3.x
  	 *		f2 = vec3.y
  	 *		f3 = vec3.z
  	 */
  	void SetUniform(int num, float f1, float f2, float f3){
  		if(m_Uniforms[num]==-1)
  			return;
  		gl.Uniform3f(m_Uniforms[num],f1,f2,f3);
  	}
  	
  	/**
  	 * sets a unifrom of type vec4
  	 * Params:
  	 *		num = number of the uniform
  	 *		f1 = vec4.x
  	 *		f2 = vec4.y
  	 *		f3 = vec4.z
  	 *		f4 = vec4.w
  	 */
  	void SetUniform(int num, float f1, float f2, float f3, float f4){
  		if(m_Uniforms[num]==-1)
  			return;
  		gl.Uniform4f(m_Uniforms[num],f1,f2,f3,f4);
  	}
  	
  	//Float Array
  	/**
  	 * sets a uniform array of type float,vec2,vec3 or vec4
  	 * Params:
  	 *		num = number of the uniform
  	 *		size1 = 1=float, 2=vec2, 3=vec3, 4=vec4
  	 *		size2 = size of the array
  	 *		data = float array data
  	 */
  	void SetUniform(int num, int size1, in float[] data)
  	in {
  		assert(size1 > 0 && size1 < 5,"size1 is out of range");
  	}
  	body {
  		if(m_Uniforms[num]==-1)
  			return;
  		switch(size1){
  			case 1:
  				gl.Uniform1fv(m_Uniforms[num], cast(int)data.length, data.ptr);
  				break;
  			case 2:
  				gl.Uniform2fv(m_Uniforms[num], cast(int)data.length, data.ptr);
  				break;
  			case 3:
  				gl.Uniform3fv(m_Uniforms[num], cast(int)data.length, data.ptr);
  				break;
  			case 4:
  				gl.Uniform4fv(m_Uniforms[num], cast(int)data.length, data.ptr);
  				break;
			default:
				assert(0,"size1 is out of range");
  		}
  	}
  	
  	/**
  	 * sets a uniform of type mat2,mat3,mat4
  	 * Params:
  	 * 		num = number of the uniform
  	 *		size = 2=mat2, 3=mat3 and 4=mat4
  	 *		transponse = if the matrix should be transponsed or not 
  	 *		data = float array data for the matrix
  	 */
  	void SetUniform(int num, int size, bool transpose, in float[] data)
  	in {
  		assert(size > 1 && size < 5,"size is out of range");
  		switch(size){
  			case 2:
  				assert(data.length == 4,"data has to be 4 elements for a 2x2 matrix");
  				break;
  			case 3:
  				assert(data.length == 9,"data has to be 9 elements for a 3x3 matrix");
  				break;
  			case 4:
  				assert(data.length == 16,"data has to be 16 elements for a 4x4 matrix");
  				break;
			default:
				assert(0,"size is out of range");
  		}
  	}
  	body {
  		if(m_Uniforms[num]==-1)
  			return;
  		switch(size){
  			case 2:
  				gl.UniformMatrix2fv(m_Uniforms[num], 1, transpose, data.ptr);
  				break;
  			case 3:
  				gl.UniformMatrix3fv(m_Uniforms[num], 1, transpose, data.ptr);
  				break;
  			case 4:
  				gl.UniformMatrix4fv(m_Uniforms[num], 1, transpose, data.ptr);
  				break;
			default:
				assert(0,"size is out of range");
  		}
  	}
  	
  	/**
  	 * sets a uniform of type mat2
  	 * Params:
  	 * 		num = number of the uniform
  	 *		value = the value
  	 *		transpose = if the matrix should be transposed or not
  	 */
  	void SetUniform(int num, ref const(mat2) value, bool transpose = false)
  	{
  		SetUniform(num,2,false,value.f);
  	}
  	
  	/**
  	 * sets a uniform of type mat3
  	 * Params:
  	 *		num = number of the uniform
  	 *		value = the value
  	 *		transpose = if the matrix should be transposed or not
  	 */
  	void SetUniform(int num, ref const(mat3) value, bool transpose = false)
  	{
  		SetUniform(num,3,false,value.f);
  	}
  	
  	/**
  	 * sets a uniform of type mat4
  	 * Params:
  	 *		num = number of the uniform
  	 *		value = the value
  	 *		transpose = if the matrix should be transposed or not
  	 */
  	void SetUniform(int num, ref const(mat4) value, bool transpose = false)
  	{
  		SetUniform(num,4,false,value.f);
  	}
  	
  	/**
  	 * sets a uniform of type vec4
  	 * Params:
  	 *		num = number of the uniform
  	 *		vektor = the value
  	 */
  	void SetUniform(int num, ref const(vec4) vektor){
  		if(m_Uniforms[num]==-1)
  			return;
  		gl.Uniform4fv(m_Uniforms[num],1,vektor.f.ptr);
  	}
  	
  	/**
  	 * sets a uniform of type vec3
  	 * Params:
  	 *		num = number of the uniform
  	 *		vektor = the value
  	 */
  	void SetUniform(int num, ref const(vec3) vektor){
  		if(m_Uniforms[num]==-1)
  			return;
  		gl.Uniform3fv(m_Uniforms[num],1,vektor.f.ptr);
  	}
  	
  	/**
  	 * sets a uniform of type vec2
  	 * Params:
  	 *		num = number of the uniform
  	 *		vektor = the value
  	 */
  	void SetUniform(int num, ref const(vec2) vektor){
  		if(m_Uniforms[num]==-1)
  			return;
  		gl.Uniform2fv(m_Uniforms[num],1,vektor.f.ptr);
  	}
  	
  	//Int 1-4
  	/**
  	 * set a uniform of type int 
  	 * Params:
  	 *		num = number of the uniform
  	 *		i1 = the value
  	 */
  	void SetUniform(int num, int i1){
  		if(m_Uniforms[num]==-1)
  			return;
  		gl.Uniform1i(m_Uniforms[num],i1);
  	}
  	
  	/**
  	 * sets a uniform of type ivec2
  	 * Params:
  	 *		num = number of the uniform
  	 *		i1 = ivec2.x
  	 *		i2 = ivec2.y
  	 */
  	void SetUniform(int num, int i1, int i2){
  		if(m_Uniforms[num]==-1)
  			return;
  		gl.Uniform2i(m_Uniforms[num],i1,i2);
  	}
  	
  	/**
  	 * sets a uniform of type ivec3
  	 * Params:
  	 *		num = number of the uniform
  	 *		i1 = ivec3.x
  	 *		i2 = ivec3.y
  	 *		i3 = ivec3.z
  	 */
  	void SetUniform(int num, int i1, int i2, int i3){
  		if(m_Uniforms[num]==-1)
  			return;
  		gl.Uniform3i(m_Uniforms[num],i1,i2,i3);
  	}
  	
  	/**
  	 * sets a uniform of type ivec4
  	 * Params:
  	 *		num = number of the uniform
  	 *		i1 = ivec4.x
  	 *		i2 = ivec4.y
  	 *		i3 = ivec4.z
  	 *		i4 = ivec4.w
  	 */
  	void SetUniform(int num, int i1, int i2, int i3, int i4){
  		if(m_Uniforms[num]==-1)
  			return;
  		gl.Uniform4i(m_Uniforms[num],i1,i2,i3,i4);
  	}
  	
  	//Int Array
  	/**
  	 * sets a uniform array of type int, ivec2, ivec3 or ivec4
  	 * Params:
  	 *		num = number of the uniform
  	 *		size1 = 1=int, 2=ivec2, 3=ivec3, 4=ivec4
  	 *		size2 = size of the array
  	 *		data = array data
  	 */
  	void SetUniform(int num, int size1, ref const(int[]) data)
  	in {
  		assert(size1 > 0 && size1 < 5,"size1 is out of range");
  	}
  	body {
  		if(m_Uniforms[num]==-1)
  			return;
  		switch(size1){
  			case 1:
  				gl.Uniform1iv(m_Uniforms[num],cast(int)data.length,data.ptr);
  				break;
  			case 2:
  				gl.Uniform2iv(m_Uniforms[num],cast(int)data.length,data.ptr);
  				break;
  			case 3:
  				gl.Uniform3iv(m_Uniforms[num],cast(int)data.length,data.ptr);
  				break;
  			case 4:
  				gl.Uniform4iv(m_Uniforms[num],cast(int)data.length,data.ptr);
  				break;
			default:
				assert(0,"size1 is out of range");
  		}
  	}
  	
  	/**
  	 * Adds a shader constant to the shader
  	 * Params:
  	 *		num = uniform to which the constant should be bound
  	 *		constant = the shader constant
  	 */
  	void AddShaderConstant(int num, ShaderConstant constant){
  		m_ShaderConstants.push_back(ConstantReference(num,constant));
  	}
  	
  	/**
  	 * Converts a UniformType enum to a string
  	 * Params:
  	 *		pType = type to convert
  	 * Returns: a string containing the type name
  	 */
  	static string ToString(UniformType pType){
  		final switch(pType){
  			case UniformType.FLOAT:
  				return "float";
  			case UniformType.VEC2:
  				return "vec2";
  			case UniformType.VEC3:
  				return "vec3";
  			case UniformType.VEC4:
  				return "vec4";
  			case UniformType.INT:
  				return "int";
  			case UniformType.IVEC2:
  				return "ivec2";
  			case UniformType.IVEC3:
  				return "ivec3";
  			case UniformType.IVEC4:
  				return "ivec4";
  			case UniformType.MAT2:
  				return "mat2";
  			case UniformType.MAT3:
  				return "mat3";
  			case UniformType.MAT4:
  				return "mat4";
  			case UniformType.SAMPLER_1D:
  				return "sampler1D";
  			case UniformType.SAMPLER_2D:
  				return "sampler2D";
  			case UniformType.SAMPLER_3D:
  				return "sampler3D";
  			case UniformType.SAMPLER_CUBE:
  				return "samplerCube";
  			case UniformType.UNKOWN:
  				return "unkown";
  		}
  		assert(0,"not reachable");
  	}
  	
  	/**
  	 * Returns the shader in use
  	 */
  	static Shader GetActiveShader(){return m_ActiveShader;}
  	
  	/**
  	 * Unloads the current shader in use
  	 */
  	static void UnloadCurrentShader(){
  		m_ActiveShader = null;
  		gl.UseProgram(0);
  	}
  	
  	
};
