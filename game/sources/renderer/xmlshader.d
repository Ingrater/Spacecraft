module renderer.xmlshader;

import renderer.shader;
import renderer.shaderconstants;
import renderer.vertexbuffer;
import renderer.exceptions;
import renderer.openglex;

import thBase.tinyxml;
import thBase.container.vector;
import thBase.container.hashmap;
import thBase.policies.hashing;
import thBase.format;
import thBase.file;
import thBase.allocator;
import thBase.string;
import thBase.logging;

/**
 * loads a shader from a xml file
 * To create this type use the factory method inside the renderer
 */
class XmlShader {
private:
	struct UniformInfo {
		rcstring m_Name;
		int m_Init;
		ShaderConstant m_ShaderConstant;	
	}
	
	struct AttributeInfo {
		rcstring m_Name;
		VertexBuffer.DataChannels m_Type;
	}
	
	ShaderConstantLib m_ShaderConstants;
	Shader m_Shader = null;
	rcstring m_Name;
	rcstring m_Path;
	bool m_DataGenerated = false;
	bool m_DataUploaded = false;
	Vector!UniformInfo m_Uniforms;
	Vector!AttributeInfo m_Attributes;
	
	rcstring m_VertexShaderSource;
	rcstring m_GeometryShaderSource;
	rcstring m_FragmentShaderSource;
	
	__gshared Hashmap!(string, VertexBuffer.DataChannels, StringHashPolicy) m_AttributeTypeToEnum;
	
	void GenerateShaderSource(ref rcstring pSource, TiXmlNode pFather, string pShaderName){
		TiXmlNode Child;
		TiXmlNode Child2;
		TiXmlElement Element;
		for(Child = pFather.FirstChild(); Child !is null; Child = Child.NextSibling()){
			if(Child.Type() == TiXmlNode.NodeType.ELEMENT){
				if(Child.Value() == "source"){
					for(Child2 = Child.FirstChild();Child2 !is null; Child2 = Child2.NextSibling()){
						pSource ~= Child2.Value();
					}
				}
				else if(Child.Value() == "include"){
					Element = Child.ToElement();
					if(!Element.Attribute("file")){
						throw New!XmlException(format("Couldn't find attribute 'file' for include Element for Shader '%s'", m_Name[]));
					}
          auto filename = format("%s/%s", m_Path[], Element.Attribute("file")[]);
					auto datei = RawFile(filename[],"r");
					if(!datei.isOpen()){
						throw New!XmlException(format("Couldn't open file '%s' for inclusion", filename[]));
					}
					char[] buf = AllocatorNewArray!char(ThreadLocalStackAllocator.globalInstance, datei.size());
          scope(exit) AllocatorDelete(ThreadLocalStackAllocator.globalInstance, buf);
					datei.readArray(buf);
					datei.close();
          pSource ~= buf;
				}
				else {
					throw New!XmlException(format("Unkown tag '%s' inside of an '%s' tag. Shader: '%s'", Child.Value()[], pFather.Value()[], m_Name[]));
				}
			}
			else if(Child.Type() != TiXmlNode.NodeType.COMMENT) {
				throw New!XmlException(format("The tag '%s' has a illegal child. Only elements or comments are allowed. Shader: %s'", Child.Value()[], m_Name[]));
			}
		}
	}
	
	void ProgressUniforms(TiXmlNode pFather){
		TiXmlNode Child;
		TiXmlElement Element;
		TiXmlAttribute Attribute;
		for(Child = pFather.FirstChild(); Child !is null; Child = Child.NextSibling()){
			if(Child.Type() == TiXmlNode.NodeType.ELEMENT){
				if(Child.Value() == "uniform"){
					UniformInfo info;
					info.m_ShaderConstant = null;
					info.m_Init = -1;
					
					Element = Child.ToElement();
					if(!Element.Attribute("name")){
						throw New!XmlException(format("XmlShader '%s' has a uniform without name attribute", m_Name[]));
					}
					if(Element.Attribute("init") && Element.Attribute("constant")){
						throw New!XmlException(format("XmlShader '%s' has a uniform with init and constant attribute", m_Name[]));
					}
					
					info.m_Name = rcstring(Element.Attribute("name")[]);
					
					Element.QueryIntAttribute("init",info.m_Init);
					
					if(Element.Attribute("constant")){
            auto constant = Element.Attribute("constant");
						info.m_ShaderConstant = m_ShaderConstants.GetShaderConstant( rcstring(constant[]) );
					}
					
					m_Uniforms ~= info;
				}
			}
		}
	}
		
	void ProgressAttributes(TiXmlNode pFather){
		TiXmlNode Child;
		TiXmlElement Element;
		for(Child = pFather.FirstChild();Child !is null; Child = Child.NextSibling()){
			if(Child.Type() == TiXmlNode.NodeType.ELEMENT){
				if(Child.Value() == "attribute"){
					Element = Child.ToElement();
					AttributeInfo info;
					if(!Element.Attribute("name")){
						throw New!XmlException(format("XmlShader '%s' has a attribute element without a name tag", m_Name[]));
					}
					if(!Element.Attribute("binding")){
						throw New!XmlException(format("XmlShader '%s' has a attribute element without a binding tag", m_Name[]));
					}
					info.m_Type = StringToAttributeBinding(Element.Attribute("binding")[]);
					info.m_Name = rcstring(Element.Attribute("name")[]);
					
					m_Attributes ~= info;
				}
			}
		}
	}
	
	void CheckUniformTypes(){
		Shader.UniformInfo Info;
		for(uint i=0;m_Shader.GetUniformInfo(i,Info);i++){
			for(size_t j=0;j<m_Uniforms.length;j++){
				if(m_Uniforms[j].m_Name == Info.m_Name){
					if(m_Uniforms[j].m_ShaderConstant !is null){
						if(m_Uniforms[j].m_ShaderConstant.GetType() != Info.m_Type){
							logWarning("The uniform '%s' of the shader '%s'"  
							         ~ " (%s) does not match in type with the given constant '%s'" 
							         ~ " (%s)"
                       , Info.m_Name[], m_Name[], Shader.ToString(Info.m_Type), m_Uniforms[j].m_Name[], Shader.ToString(m_Uniforms[j].m_ShaderConstant.GetType()));
						}
					}
				}
			}
		}
	}
	
public:
	shared static this(){
    m_AttributeTypeToEnum = New!(typeof(m_AttributeTypeToEnum))();
		m_AttributeTypeToEnum["binormal"] = VertexBuffer.DataChannels.BINORMAL;
		m_AttributeTypeToEnum["boneids"] = VertexBuffer.DataChannels.BONEIDS;
		m_AttributeTypeToEnum["boneweights"] = VertexBuffer.DataChannels.BONEWEIGHTS;
		m_AttributeTypeToEnum["color"] = VertexBuffer.DataChannels.COLOR;
		m_AttributeTypeToEnum["normal"] = VertexBuffer.DataChannels.NORMAL;
		m_AttributeTypeToEnum["position"] = VertexBuffer.DataChannels.POSITION;
		m_AttributeTypeToEnum["tangent"] = VertexBuffer.DataChannels.TANGENT;
		m_AttributeTypeToEnum["texcoord0"] = VertexBuffer.DataChannels.TEXCOORD0;
		m_AttributeTypeToEnum["texcoord1"] = VertexBuffer.DataChannels.TEXCOORD1;
		m_AttributeTypeToEnum["texcoord2"] = VertexBuffer.DataChannels.TEXCOORD2;
		m_AttributeTypeToEnum["texcoord3"] = VertexBuffer.DataChannels.TEXCOORD3;
		m_AttributeTypeToEnum["unfolding"] = VertexBuffer.DataChannels.UNFOLDING;
		m_AttributeTypeToEnum["undefdata0"] = VertexBuffer.DataChannels.UNDEFDATA0;
		m_AttributeTypeToEnum["undefdata1"] = VertexBuffer.DataChannels.UNDEFDATA1;
		m_AttributeTypeToEnum["undefdata2"] = VertexBuffer.DataChannels.UNDEFDATA2;
		m_AttributeTypeToEnum["undefdata3"] = VertexBuffer.DataChannels.UNDEFDATA3;
	}

  shared static ~this()
  {
    Delete(m_AttributeTypeToEnum);
  }
	
	this(ShaderConstantLib pLib){
		m_ShaderConstants = pLib;
    m_Uniforms = New!(typeof(m_Uniforms))();
    m_Attributes = New!(typeof(m_Attributes))();
	}

  ~this()
  {
    Delete(m_Uniforms);
    Delete(m_Attributes);
    Delete(m_Shader);
  }
	
	/**
	 * Loads a xml file
	 * Params:
	 * 		pFileName = path of the file to load
	 */ 
	void Load(rcstring pFileName)
	in {
		assert(m_DataGenerated == false,"Another shader has already been loaded in this instance");
	}
	body {
		TiXmlNode MainNode;
		TiXmlNode Child;
		TiXmlNode Child2;
		
    if(!thBase.file.exists(pFileName[]))
    {
      throw New!FileException(format("Couldn't open file '%s'", pFileName[]));
    }
		
		//Find path
		size_t last = lastIndexOf(pFileName, '/');
		if(last == -1){
			last = lastIndexOf(pFileName, '\\');
		}
		if(last == -1){
			m_Path = ".";
		}
		else {
			m_Path = pFileName[0..last];
		}
		
    auto allocator = GetNewTemporaryAllocator();
    scope(exit) Delete(allocator);
    TiXmlDocument XmlFile = AllocatorNew!TiXmlDocument(allocator, cast(TiXmlString)pFileName, allocator);
    scope(exit)
    {
      AllocatorDelete(allocator, XmlFile);
    }
		//XmlFile.SetCondenseWhiteSpace(false);
		if(!XmlFile.LoadFile()){
			throw New!XmlException(rcstring(XmlFile.ErrorDesc()));
		}
		
		MainNode = XmlFile.FirstChild("shader");
		if(MainNode is null){
			throw New!XmlException(format("Couldn't find main node 'shader' in '%s'", pFileName[]));
		}
		
		Child = MainNode.FirstChild("name");
		if(Child is null){
			throw New!XmlException(format("Couldn't find name node in file '%s'", pFileName[]));
		}
		
		Child2 = Child.FirstChild();
		if(Child2.Type() != TiXmlNode.NodeType.TEXT){
			throw New!XmlException(format("The name node can only contain text inside '%s' type is %d" , pFileName[], Child2.Type()) );
		}
		m_Name = rcstring(Child2.Value()[]);
		
		for(Child = MainNode.FirstChild(); Child !is null; Child = Child.NextSibling()){
			if(Child.Type() == TiXmlNode.NodeType.ELEMENT){
				if("vertexshader" == Child.Value()){
					GenerateShaderSource(m_VertexShaderSource, Child, "Vertex Shader");
				}
				else if("fragmentshader" == Child.Value()){
					GenerateShaderSource(m_FragmentShaderSource, Child, "Fragment Shader");
				}
				else if("geometryshader" == Child.Value()){
					GenerateShaderSource(m_GeometryShaderSource, Child, "Geometry Shader");
				}
				else if("uniforms" == Child.Value()){
					ProgressUniforms(Child);
				}
				else if("attributes" == Child.Value()){
					ProgressAttributes(Child);
				}
			}
		}
		
		m_DataGenerated = true;
	}
	
	/**
	 * uploads the shader to the graphics card
	 * hase to be executed in the main thread
	 */
	void Upload()
	in {
		assert(m_DataGenerated,"There is no data to upload");
		assert(!m_DataUploaded,"Data has already been uploaded");
	}
	body {
		//Create the shader
		m_Shader = New!Shader(m_Name);
		
		debug {
			if(m_VertexShaderSource.length > 0){
        auto logfile = format("logs/VertexShader_%s.log", m_Name[]);
				auto datei = RawFile(logfile[], "w");
        if(datei.isOpen())
        {
				  datei.writeArray(m_VertexShaderSource[]);
				  datei.close();
        }
			}
			if(m_GeometryShaderSource.length > 0){
        auto logfile = format("logs/GeometryShader_%s.log", m_Name[]);
				auto datei = RawFile(logfile[], "w");
        if(datei.isOpen())
        {
				  datei.writeArray(m_GeometryShaderSource[]);
				  datei.close();
        }
			}
			if(m_FragmentShaderSource.length > 0){
        auto logfile = format("logs/FragmentShader_%s.log", m_Name[]);
				auto datei = RawFile(logfile[], "w");
        if(datei.isOpen())
        {
				  datei.writeArray(m_FragmentShaderSource[]);
				  datei.close();		
        }
			}
		}
		
		//Load Shader Sources
		if(m_VertexShaderSource.length > 0){
			m_Shader.LoadShaderSource(m_VertexShaderSource[], Shader.ShaderType.VERTEX_SHADER);
		}
		if(m_GeometryShaderSource.length > 0){
			m_Shader.LoadShaderSource(m_GeometryShaderSource[], Shader.ShaderType.GEOMETRY_SHADER);
		}
		if(m_FragmentShaderSource.length > 0){
			m_Shader.LoadShaderSource(m_FragmentShaderSource[], Shader.ShaderType.FRAGMENT_SHADER);
		}
		
		//Bind Attribute Locations
		if(m_Attributes.length > 0){
			auto BindInfo = AllocatorNewArray!(Shader.BindAttributeInfo)(ThreadLocalStackAllocator.globalInstance, m_Attributes.length);
      scope(exit) AllocatorDelete(ThreadLocalStackAllocator.globalInstance, BindInfo);
			foreach(int i, ref b;BindInfo){
				b.name = m_Attributes[i].m_Name[];
				b.channel = m_Attributes[i].m_Type;
			}
			m_Shader.BindAttributes(BindInfo);
		}
		
		//Link Shader
		m_Shader.Link();
		
		//Load Attributes
		if(m_Attributes.length > 0){
			auto AttribInfo = AllocatorNewArray!(Shader.AttributeInput)(ThreadLocalStackAllocator.globalInstance, m_Attributes.length);
      scope(exit) AllocatorDelete(ThreadLocalStackAllocator.globalInstance, AttribInfo);
			foreach(int i,ref a;AttribInfo){
				a.name = m_Attributes[i].m_Name[];
				a.type = m_Attributes[i].m_Type;
			}
			m_Shader.LoadAttributes(AttribInfo);
			
			//Check if they have the correct binding
			foreach(ref a;m_Attributes){
				auto location = m_Shader.GetAttrib(a.m_Name[]);
				if(location < 0){
					logWarning("vertex attribute '%s' was optimized out of shader '%s'", a.m_Name[], m_Name[]);
				}
				else if(VertexBuffer.DataChannelLocation(a.m_Type) != location){
					throw New!OpenGLException(format("vertex attribute '%s' is not bound to where it should be in shader '%s'", a.m_Name[], m_Name[]));
				}
			}
		}
		
		//Load Uniforms
		if(m_Uniforms.length > 0){
			auto UniformNames = AllocatorNewArray!string(ThreadLocalStackAllocator.globalInstance, m_Uniforms.length);
      scope(exit) AllocatorDelete(ThreadLocalStackAllocator.globalInstance, UniformNames);
			foreach(int i, ref u;UniformNames)
				u = m_Uniforms[i].m_Name[];
			m_Shader.LoadUniforms(UniformNames);
			
			CheckUniformTypes();
			
			m_Shader.Use();
			
			for(int i=0;i<m_Uniforms.length;i++){
				if(m_Uniforms[i].m_Init > 0)
					m_Shader.SetUniform(i,m_Uniforms[i].m_Init);
			}
			m_Shader.UnloadCurrentShader();
			
			for(int i=0;i<m_Uniforms.length;i++){
				if(m_Uniforms[i].m_ShaderConstant !is null)
					m_Shader.AddShaderConstant(i, m_Uniforms[i].m_ShaderConstant);
			}
		}
		
		m_DataUploaded = true;
	}
		
	/**
	 * returns the generated shader
	 */
	Shader GetShader() { return m_Shader; }
	
	/* Shader manipulation functions*/
	/**
	 * Adds source lines
	 * Params:
	 *		pSrc = the source to add
	 *		pType = to which shader part the source should be added
	 */
	void AddSource(string pSrc, Shader.ShaderType pType)
	{
		switch(pType){
			case Shader.ShaderType.VERTEX_SHADER:
				m_VertexShaderSource ~= pSrc;
				break;
			case Shader.ShaderType.GEOMETRY_SHADER:
				m_GeometryShaderSource ~= pSrc;
				break;
			case Shader.ShaderType.FRAGMENT_SHADER:
				m_FragmentShaderSource ~= pSrc;
				break;
			default:
				break;
		}
	}
	
	/**
	 * changes the shader name
	 * Params:
	 *		pName = the name
	 */
	void SetName(rcstring pName)
	{
		m_Name = pName;
	}
	
	/**
	 * Adds a uniform to the shader
	 * Params:
	 *		pName = name of the uniform
	 *		pConstant = the constant to bind the uniform to
	 *		pInit = the value to init the uniform
	 */
	void AddUniform(rcstring pName, string pConstant, int pInit)
	in {
		assert(pInit < 0 || pConstant is null,"A uniform can not be bound to a constant and have a init avlue simultaniously");
	}
	body {
		if(pInit < 0 && pConstant == null){
			logWarning("The uniform '%s' of the shader '%s' remains without data because it has no init value and is not bound to a constant!", pName[], m_Name[]);
		}
		
		UniformInfo info;
		if(pInit < 0)
			info.m_Init = -1;
		
		if(pConstant.length > 0){
			info.m_ShaderConstant = m_ShaderConstants.GetShaderConstant(rcstring(pConstant, IsStatic.Yes));
		}
		
		info.m_Name = pName;
		
		m_Uniforms ~= info;
	}
	
	/**
	 * Adds a attribute to the shader
	 * Params:
	 *		pName = the name of the attribute
	 *		pBinding = the binding of the attribute
	 */
	void AddAttribute(string pName, VertexBuffer.DataChannels pBinding)
	in {
		assert(pName.length > 0,"No Attribute name has been given");
	}
	body {
		AttributeInfo info;
		info.m_Name = pName;
		info.m_Type = pBinding;
	}
	
	/**
	 * converts a string to an attribute binding
	 * Params:
	 *		pString = the string
	 * Returns: the attribute data channel enum value
	 */ 
	VertexBuffer.DataChannels StringToAttributeBinding(string pString)
	{
		if(!m_AttributeTypeToEnum.exists(pString)){
			throw New!XmlException(format("Invalid value '%s' for an attribute binding attribute in XmlShader '%s'", pString, m_Name[]));
		}
		return m_AttributeTypeToEnum[pString];
	}
	
	
}
