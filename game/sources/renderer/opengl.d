module renderer.opengl;

import renderer.sdl.main;
import std.traits;
import base.sharedlib;

import base.utilsD2;
import core.stdc.string : strlen;
import thBase.string;

static import base.logger;

version(NO_OPENGL)
{
  import thBase.container.hashmap;
}

private void* GetProcAddress(string name){
  void* proc = SDL.GL.GetProcAddress(toCString(name));
  if(proc is null){
    proc = SDL.GL.GetProcAddress(toCString(name ~ "ARB"));
    if(proc !is null){
      base.logger.info("Falling back to ARB for '" ~ name ~"'");
    }
    else {
      proc = SDL.GL.GetProcAddress(toCString(name ~ "EXT"));
      if(proc !is null){
        base.logger.info("Falling back to EXT for '" ~ name ~"'");
      }
    }
  }
  //base.logger.info("%s %x",name,proc);
  return proc;
}

version(OPENGL_ERROR_CHECK)
{
  import thBase.format;

  private string dll_declare(string name){
    if(name != "glGetError")
    {
	    string code = "static " ~ name ~ " _" ~ name[2..name.length] ~ ";";
      code ~= "static ReturnType!(" ~ name ~ ") " ~ name[2..name.length] ~ "(ARGS...)(ARGS args){";
      code ~= "static if(is(ReturnType!(" ~ name ~ ") == void))";
      code ~= "  _" ~ name[2..name.length] ~ "(args);";
      code ~= "else";
      code ~= "  auto retval =  _" ~ name[2..name.length] ~ "(args);";
      code ~= "gl.ErrorCode error = gl.GetError();";
      code ~= "if(error != gl.ErrorCode.NO_ERROR){";
      code ~= "auto msg = format(\"Error calling " ~ name ~ ": %s\", gl.TranslateError(error));";
      code ~= "assert(0, msg[]); }";
      code ~= "static if(!is(ReturnType!(" ~ name ~ ") == void))";
      code ~= "  return retval; }";
      return code;
    }
    return "static " ~ name ~ " " ~ name[2..name.length] ~ ";";
  }

  //for loading extension functions
  private string dll_init(string name){
    if(name != "glGetError")
    {
	    string sname = "_" ~ name[2..name.length];
	    return sname ~ " = cast( typeof ( " ~ sname ~ ") ) GetProcAddress(`" ~ name ~ "`); check("~sname~",`" ~ name ~ "`);";
    }
    string sname = name[2..name.length];
    return sname ~ " = cast( typeof ( " ~ sname ~ ") ) GetProcAddress(`" ~ name ~ "`); check("~sname~",`" ~ name ~ "`);";
  }
}
else
{
  private string dll_declare(string name){
	  return "static " ~ name ~ " " ~ name[2..name.length] ~ ";";
  }

  //for loading extension functions
  private string dll_init(string name){
	  string sname = name[2..name.length];
	  return sname ~ " = cast( typeof ( " ~ sname ~ ") ) GetProcAddress(`" ~ name ~ "`); check("~sname~",`" ~ name ~ "`);";
  }
}

version(NO_OPENGL)
{
  class IdGenerator(T)
  {
    composite!(Hashmap!(T, bool)) m_ids;
    T m_nextId = 1;

    this()
    {
      m_ids = typeof(m_ids)(DefaultCtor());
      m_ids.construct();
    }

    ~this(){}

    T getNextId()
    {
      T id = m_nextId;
      m_nextId++;
      m_ids[id] = true;
      return id;
    }

    bool isValidId(T id)
    {
      if(!m_ids.exists(id))
        return false;
      return m_ids[id];
    }

    void invalidateId(T id)
    {
      m_ids[id] = false;
    }
  }
}

/**
 * OpenGL c library biding
 */
class gl {
	alias uint GLenum;
	alias int handle;

  /+version(NO_OPENGL)
  {
    static bool g_IsOpenGLThread = false;
    static IdGenerator!(uint) g_textureIdGenerator = null;
    static IdGenerator!(uint) g_bufferIdGenerator = null;
    static IdGenerator!(handle) g_programIdGenerator = null;
    static IdGenerator!(handle) g_shaderIdGenerator = null;
    static IdGenerator!(uint) g_framebufferIdGenerator = null;
    static IdGenerator!(uint) g_renderbufferIdGenerator = null;

    static struct BufferInfo
    {
      GLenum target;
      size_t requestedSize;
      void[] memory;
    }
    static Hashmap!(uint, BufferInfo) g_bufferInfos = null;
    static uint[2] g_currentlyBoundBuffer = 0;

    static struct ProgramId
    {
      handle program;
      rcstring name;

      this(handle program, const(char)* name)
      {
        this.program = program;
        this.name = name[0..strlen(name)];
      }

      uint Hash()
      {
        return name.Hash() + program;
      }

      bool opEquals(ref const(ProgramId) rh) const
      {
        return rh.program == program && rh.name == name;
      }
    }
    static Hashmap!(ProgramId, int) g_attributeLocations = null;
    static Hashmap!(ProgramId, int) g_uniformLocations = null;

    static struct ProgramInfo
    {
      int nextAttribute = 0;
      int nextUniform = 0;
    }
    static Hashmap!(handle, ProgramInfo) g_programInfos = null;

    static invariant()
    {
      assert(g_IsOpenGLThread, "OpenGL call from non OpenGL thread");
    }

    static void ClearColor(float r, float g, float b, float a){}
    static void Viewport(int x, int y, size_t width, size_t height){}
    static void Clear(uint mask){}
    static void Flush(){}
    static void MatrixMode(GLenum mode){}
    static void Ortho(double left, double right, double bottom, double top, double near, double far){}
    static void LoadIdentity(){}
    static void Begin(GLenum mode){}
    static void End(){}
    static void Vertex2f(float x, float y){}
    static void Color3f(float x, float y){}
    static void DeleteTextures(size_t n, uint *textures)
    {
      assert(n > 0, "n has to be larger then 0");
      for(size_t i=0; i<n; i++)
      {
        if(textures[i] == 0)
          continue;
        assert(g_textureIdGenerator.isValidId(textures[i]), "invalid texture id");
        g_textureIdGenerator.invalidateId(textures[i]);
      }
    }
    static void GenTextures(size_t n, uint *textures)
    {
      assert(n > 0);
      for(size_t i=0; i<n; i++)
      {
        textures[i] = g_textureIdGenerator.getNextId();
      }
    }
    static void BindTexture(GLenum target, uint texture)
    {
      assert(g_textureIdGenerator.isValidId(texture) || texture == 0, "invalid texture id");
    }
    static void TexSubImage2D(GLenum target, int level, int xoffset, int yoffset, size_t width, size_t height, GLenum format, GLenum type, const(void) *data){}
    static void CopyTexImage2D(GLenum target, int level, GLenum internalformat, int x, int y, size_t width, size_t height, int border){}
    static void CopyTexSubImage2D(GLenum target, int level, int xoffset, int yoffset, int x, int y, size_t width, size_t height){}
    static void TexParameteri(GLenum target, GLenum pname, int param ){}
    static void TexImage2D(GLenum target, int level, int internalFormat, size_t width, size_t height, int border, GLenum format, GLenum type, const(void) *pixels ){}
    static void ActiveTexture(GLenum texture){}
    static void GetTexImage(GLenum target, int level, GLenum format, GLenum type, void *pixels){}
    static void DrawArrays(GLenum mode, int first, size_t count){}
    static void DrawElements(GLenum mode, size_t count, GLenum type, const(void*) indicies){}
    static ErrorCode GetError() { return ErrorCode.NO_ERROR; }
    static void DepthFunc(GLenum func){}
    static void DepthMask(ubyte flag){}
    static void ClipPlane(GLenum plane, const(double)* equation){}
    static void PolygonMode(GLenum face, GLenum mode){}
    static void Disable(GLenum cap){}
    static void Enable(GLenum cap){}
    static void GetIntegerv(GLenum pname, int* params)
    {
      switch(pname)
      {
        case MAX_DRAW_BUFFERS:
          *params = 4;
          break;
        case MAX_COLOR_ATTACHMENTS:
          *params = 4;
          break;
        case MAX_TEXTURE_SIZE:
          *params = 4096;
          break;
        default:
          assert(0, "not implemented");
      }
    }
    static void DrawBuffer(GLenum mode){}
    static void ReadBuffer(GLenum mode){}
    static void PushAttrib(uint mask){}
    static void PopAttrib(){}
    static void PointSize(float size){}
    static const(char)* GetString(GLenum name)
    {
      assert(name == EXTENSIONS, "not implemented");
      return "GL_ARB_texture_compression GL_EXT_texture_compression_s3tc".ptr;
    }

    //OpenGL 2.0 functions
    private static size_t MapBufferTargetToIndex(GLenum target)
    {
      switch(target)
      {
        case ARRAY_BUFFER:
          return 0;
        case ELEMENT_ARRAY_BUFFER:
          return 1;
        default:
          assert(0, "invalid buffer target value");
      }
    }
    static void GenBuffers(size_t n, uint *buffers)
    {
      assert(n > 0);
      for(size_t i=0; i<n; i++)
      {
        buffers[i] = g_bufferIdGenerator.getNextId();
      }
    }

    static void DeleteBuffers(size_t n, uint* buffers)
    {
      assert(n > 0);
      for(size_t i=0; i<n; i++)
      {
        if(buffers[i] == 0)
          continue;
        assert(g_bufferIdGenerator.isValidId(buffers[i]), "invalid buffer id");
        g_bufferIdGenerator.invalidateId(buffers[i]);
        auto info = g_bufferInfos[buffers[i]];
        g_bufferInfos.remove(buffers[i]);
        if(info.memory !is null)
          Delete(info.memory);
      }
    }
    static void* MapBuffer(GLenum target, GLenum access)
    {
      assert(access == WRITE_ONLY, "access pattern not implemented");
      size_t targetIndex = MapBufferTargetToIndex(target);
      assert(g_bufferIdGenerator.isValidId(g_currentlyBoundBuffer[targetIndex]), "currently bound buffer is not valid");
      assert(g_bufferInfos.exists(g_currentlyBoundBuffer[targetIndex]), "currenlty bound buffer contains no data");
      auto info = g_bufferInfos[g_currentlyBoundBuffer[targetIndex]];
      assert(info.target == target, "target does not match");
      if(info.memory is null)
      {
        info.memory = StdAllocator.globalInstance.AllocateMemory(info.requestedSize);
        g_bufferInfos[g_currentlyBoundBuffer[targetIndex]] = info;
      }
      return info.memory.ptr;
    }
    static void UnmapBuffer(GLenum target)
    {
      size_t targetIndex = MapBufferTargetToIndex(target);
      assert(g_bufferInfos.exists(g_currentlyBoundBuffer[targetIndex]), "bound buffer contains no data");
      assert(g_bufferInfos[g_currentlyBoundBuffer[targetIndex]].target == target, "target does not match");
    }
    static void BindBuffer(GLenum target, uint buffer)
    {
      if(buffer != 0)
      {
        assert(g_bufferIdGenerator.isValidId(buffer), "invalid buffer id");
      }
      g_currentlyBoundBuffer[MapBufferTargetToIndex(target)] = buffer;
    }
    static void BufferData(GLenum target, size_t size, const(void*) data, GLenum usage)
    {
      size_t targetIndex = MapBufferTargetToIndex(target);
      assert(g_bufferIdGenerator.isValidId(g_currentlyBoundBuffer[targetIndex]), "no valid buffer bound");
      BufferInfo info;
      if(g_bufferInfos.exists(g_currentlyBoundBuffer[targetIndex]))
        info = g_bufferInfos[g_currentlyBoundBuffer[targetIndex]];
      if(size != info.requestedSize && info.memory !is null)
      {
        Delete(info.memory);
        info.memory = [];
      }
      info.requestedSize = size;
      info.target = target;
      g_bufferInfos[g_currentlyBoundBuffer[targetIndex]] = info;
    }
    static void BufferSubData(GLenum target, size_t offset, size_t size, const(void*) data)
    {
      size_t targetIndex = MapBufferTargetToIndex(target);
      assert(g_bufferIdGenerator.isValidId(g_currentlyBoundBuffer[targetIndex]), "no valid buffer bound");
      assert(g_bufferInfos.exists(g_currentlyBoundBuffer[targetIndex]), "buffer has no data");
      auto info = g_bufferInfos[g_currentlyBoundBuffer[targetIndex]];
      assert(info.target == target, "target does not match");
      assert(offset + size <= info.requestedSize, "sub data is to large");
    }

    static void EnableVertexAttribArray(uint index){}
    static void DisableVertexAttribArray(uint index){}
    static void VertexAttribPointer(uint index, int size, GLenum type, bool normalized, size_t stride, const (void*) pointer){}
    static void MultiDrawElements(GLenum mode, const(size_t*) count, GLenum type, const(void*) indicies, size_t primcount){}
    static void DrawRangeElements(GLenum mode, uint start, uint end, size_t count, GLenum type, const(void*) indicies){}

    static void UseProgram(handle program)
    {
      if(program != 0)
        assert(g_programIdGenerator.isValidId(program), "invalid program");
    }
    static handle CreateProgram()
    {
      return g_programIdGenerator.getNextId();
    }
    static void DeleteProgram(handle program)
    {
      assert(g_programIdGenerator.isValidId(program), "invalid program");
      g_programInfos.remove(program);
      g_attributeLocations.removeWhere((ref ProgramId id, ref int index){ return id.program == program; });
      g_uniformLocations.removeWhere((ref ProgramId id, ref int index){ return id.program == program; });
    }
    static void LinkProgram(handle program)
    {
      assert(g_programIdGenerator.isValidId(program), "invalid program");
    }
    static void ValidateProgram(handle program)
    {
      assert(g_programIdGenerator.isValidId(program), "invalid program");
    }
    static void AttachShader(handle program, handle shader)
    {
      assert(g_programIdGenerator.isValidId(program), "invalid program");
      assert(g_shaderIdGenerator.isValidId(shader), "invalid shader");
    }
    static void DetachShader(handle program, handle shader)
    {
      assert(g_programIdGenerator.isValidId(program), "invalid program");
      assert(g_shaderIdGenerator.isValidId(program), "invalid shader");
    }
    static handle CreateShader(GLenum type)
    {
      return g_shaderIdGenerator.getNextId();
    }
    static void DeleteShader(handle shader)
    {
      assert(g_shaderIdGenerator.isValidId(shader), "invalid shader");
    }
    static void CompileShader(handle shader)
    {
      assert(g_shaderIdGenerator.isValidId(shader), "invalid shader");
    }
    static void ShaderSource(handle shader, size_t count, const(char)** strings, const(int)* length)
    {
      assert(g_shaderIdGenerator.isValidId(shader), "invalid shader");
    }
    static void GetShaderiv(handle shader, GLenum pname, int* params)
    {
      assert(g_shaderIdGenerator.isValidId(shader), "invalid shader");
      assert(params !is null);
      switch(pname)
      {
        case COMPILE_STATUS:
          *params = 1;
          break;
        case INFO_LOG_LENGTH:
          *params = 0;
          break;
        default:
          assert(0, "not implemented");
      }
    }
    static void GetProgramiv(handle program, GLenum pname, int* params)
    {
      assert(g_programIdGenerator.isValidId(program), "invalid program");
      assert(params !is null);
      switch(pname)
      {
        case ACTIVE_UNIFORMS:
          {
            *params = 0;
          }
          break;
        case LINK_STATUS:
          *params = 1;
          break;
        case INFO_LOG_LENGTH:
          *params = 0;
          break;
        case VALIDATE_STATUS:
          *params = 1;
          break;
        default:
          assert(0, "not implemented");
      }
    }
    static void GetShaderInfoLog(handle shader, int bufSize, int* length, char* infoLog)
    {
      assert(g_shaderIdGenerator.isValidId(shader), "invalid shader");
      assert(length !is null);
      *length = 0;
    }
    static void GetProgramInfoLog(handle program, int bufSize, int* length, char* infoLog)
    {
      assert(g_programIdGenerator.isValidId(program), "invalid program");
      assert(length !is null);
      *length = 0;
    }
    static int GetAttribLocation(handle program, const(char)* name)
    {
      assert(g_programIdGenerator.isValidId(program), "invalid program id");
      auto attrib = ProgramId(program, name);
      if(g_attributeLocations.exists(attrib))
      {
        return g_attributeLocations[attrib];
      }
      ProgramInfo info;
      if(g_programInfos.exists(program))
      {
        info = g_programInfos[program];
      }
      int result = info.nextAttribute++;
      g_programInfos[program] = info;
      g_attributeLocations[attrib] = result;
      return result;
    }
    static int GetUniformLocation(handle program, const(char)* name)
    {
      assert(g_programIdGenerator.isValidId(program), "invalid program id");
      auto uniform = ProgramId(program, name);
      if(g_uniformLocations.exists(uniform))
      {
        return g_uniformLocations[uniform];
      }
      ProgramInfo info;
      if(g_programInfos.exists(program))
      {
        info = g_programInfos[program];
      }
      int result = info.nextUniform++;
      g_programInfos[program] = info;
      g_uniformLocations[uniform] = result;
      return result;
    }
    static void GetActiveUniform(handle program, uint index, int bufferSize, int* length, int* size, GLenum* type, char* name)
    {
      assert(0, "not implemented");
    }
    static void BindAttribLocation(handle program, uint index, const(char)* name)
    {
      assert(g_programIdGenerator.isValidId(program), "invalid program id");
      auto attrib = ProgramId(program, name);
      g_attributeLocations[attrib] = index;
    }
    static void Uniform1f(int location, float v0){}
    static void Uniform2f(int location, float v0, float v1){}
    static void Uniform3f(int location, float v0, float v1, float v2){}
    static void Uniform4f(int location, float v0, float v1, float v2, float v3){}
    static void Uniform1i(int location, int v0){}
    static void Uniform2i(int location, int v0, int v1){}
    static void Uniform3i(int location, int v0, int v1, int v2){}
    static void Uniform4i(int location, int v0, int v1, int v3, int v4){}
    static void Uniform1fv(int location, int count, const(float)* values){}
    static void Uniform2fv(int location, int count, const(float)* values){}
    static void Uniform3fv(int location, int count, const(float)* values){}
    static void Uniform4fv(int location, int count, const(float)* values){}
    static void Uniform1iv(int location, int count, const(int)* values){}
    static void Uniform2iv(int location, int count, const(int)* values){}
    static void Uniform3iv(int location, int count, const(int)* values){}
    static void Uniform4iv(int location, int count, const(int)* values){}
    static void UniformMatrix2fv(int location, int count, bool transpose, const(float)* values){}
    static void UniformMatrix3fv(int location, int count, bool transpose, const(float)* values){}
    static void UniformMatrix4fv(int location, int count, bool transpose, const(float)* values){}
    static void StencilFunc(GLenum func, int pRef, uint mask){}
    static void StencilOp(GLenum fail, GLenum zfail, GLenum zpass){}
    static void StencilMask(uint mask){}
    static void ColorMask(ubyte red, ubyte green, ubyte blue, ubyte alpha){}
    static void BlendFunc(GLenum factor, GLenum dfactor){}
    static void CullFace(GLenum mode){}
    static void GenFramebuffers(int n, uint* framebuffers)
    {
      assert(n > 0);
      for(int i=0; i<n; i++)
      {
        framebuffers[i] = g_framebufferIdGenerator.getNextId();
      }
    }
    static void DeleteFramebuffers(int n, uint* framebuffers)
    {
      assert(n > 0);
      for(int i=0; i<n; i++)
      {
        assert(g_framebufferIdGenerator.isValidId(framebuffers[i]));
        g_framebufferIdGenerator.invalidateId(framebuffers[i]);
      }
    }
    static GLenum CheckFramebufferStatus(GLenum target)
    {
      return FRAMEBUFFER_COMPLETE;
    }
    static void FramebufferTexture1D(GLenum target, GLenum attachment, GLenum textarget, uint texture, int level)
    {
      assert(g_textureIdGenerator.isValidId(texture), "invalid texture id");
    }
    static void FramebufferTexture2D(GLenum target, GLenum attachment, GLenum textarget, uint texture, int level)
    {
      assert(g_textureIdGenerator.isValidId(texture), "invalid texture id");
    }
    static void FramebufferTexure3D(GLenum target, GLenum attachment, GLenum textarget, uint texture, int level, int zoffset)
    {
      assert(g_textureIdGenerator.isValidId(texture), "invalid texture id");
    }
    static void FramebufferRenderbuffer(GLenum target, GLenum attachment, GLenum renderbuffertarget, uint renderbuffer)
    {
      assert(g_renderbufferIdGenerator.isValidId(renderbuffer), "invalid renderbuffer id");
    }
    static void BindFramebuffer(GLenum target, uint framebuffer)
    {
      if(framebuffer != 0)
        assert(g_framebufferIdGenerator.isValidId(framebuffer), "invalid framebuffer id");
    }
    static void BindRenderbuffer(GLenum target, int renderbuffer)
    {
      if(renderbuffer != 0)
        assert(g_renderbufferIdGenerator.isValidId(renderbuffer), "invalid renderbuffer id");
    }
    static void GenRenderbuffers(int n, uint* renderbuffers)
    {
      assert(n > 0);
      for(int i=0; i<n; i++)
      {
        renderbuffers[i] = g_renderbufferIdGenerator.getNextId();
      }
    }
    static void DeleteRenderbuffers(int n, uint* renderbuffers)
    {
      assert(n > 0);
      for(int i=0; i<n; i++)
      {
        assert(g_renderbufferIdGenerator.isValidId(renderbuffers[i]));
        g_renderbufferIdGenerator.invalidateId(renderbuffers[i]);
      }
    }
    static void RenderbufferStorage(GLenum target, GLenum internalformat, int width, int height){}
    static void DrawBuffers(int n, GLenum* buffers){}
    static void ClearDepth(double depth){}
    static void ClearStencil(int s){}
    static void GenerateMipmap(GLenum target){}
    static void GetTexLevelParameteriv(GLenum target, int level, GLenum pname, int* params)
    {
      switch(pname)
      {
        case TEXTURE_COMPRESSED_ARB:
          *params = 0;
          break;
        default:
          assert(0, "not implemented");
      }
    }
    static void ClampColorARB(GLenum target, GLenum clamp){}
  }
  else
  {+/
	  extern(System){
		  //OpenGL 1.0 functions
		  alias void function(float r, float g, float b, float a) glClearColor;
		  alias void function(int x, int y, size_t width, size_t height) glViewport;
		  alias void function(uint mask) glClear;
		  alias void function() glFlush;
		  alias void function(GLenum mode) glMatrixMode;
		  alias void function(double left, double right, double bottom, double top, double near, double far) glOrtho;
		  alias void function() glLoadIdentity;
		  alias void function(GLenum mode) glBegin;
		  alias void function() glEnd;
		  alias void function(float x, float y) glVertex2f;
		  alias void function(float r, float g, float b) glColor3f;
		  alias void function(size_t n, uint *textures) glDeleteTextures;
		  alias void function(size_t n, uint *textures) glGenTextures;
		  alias void function(GLenum target, uint texture) glBindTexture;
		  alias void function(GLenum target, int level, int xoffset, int yoffset, size_t width, size_t height, GLenum format, GLenum type, const(void) *data) glTexSubImage2D;
		  alias void function(GLenum target, int level, GLenum internalformat, int x, int y, size_t width, size_t height, int border) glCopyTexImage2D;
		  alias void function(GLenum target, int level, int xoffset, int yoffset, int x, int y, size_t width, size_t height) glCopyTexSubImage2D;
		  alias void function(GLenum target, GLenum pname, int param ) glTexParameteri;
		  alias void function(GLenum target, int level, int internalFormat, size_t width, size_t height, int border, GLenum format, GLenum type, const(void) *pixels ) glTexImage2D;
		  alias void function(GLenum texture) glActiveTexture;
		  alias void function(GLenum target, int level, GLenum format, GLenum type, void *pixels) glGetTexImage;
		  alias void function(GLenum mode, int first, size_t count) glDrawArrays;
		  alias void function(GLenum mode, size_t count, GLenum type, const(void*) indicies) glDrawElements;
		  alias ErrorCode function() glGetError;
		  alias void function(GLenum func) glDepthFunc;
		  alias void function(ubyte flag) glDepthMask;
		  alias void function(GLenum plane, const(double)* equation) glClipPlane;
		  alias void function(GLenum face, GLenum mode) glPolygonMode;
		  alias void function(GLenum cap) glDisable;
		  alias void function(GLenum cap) glEnable;
		  alias void function(GLenum pname, int* params) glGetIntegerv;
		  alias void function(GLenum mode) glDrawBuffer;
		  alias void function(GLenum mode) glReadBuffer;
		  alias void function(uint mask) glPushAttrib;
		  alias void function() glPopAttrib;
		  alias void function(float size) glPointSize;
		  alias const(char)* function(GLenum name) glGetString;
  		
		  //OpenGL 2.0 functions
		  alias void function(size_t n, uint *buffers) glGenBuffers;
		  alias void function(size_t n, uint *buffers) glDeleteBuffers;
		  alias void* function(GLenum target, GLenum access) glMapBuffer;
		  alias bool function(GLenum target) glUnmapBuffer;
		  alias void function(uint index) glEnableVertexAttribArray;
		  alias void function(uint index) glDisableVertexAttribArray;
		  alias void function(uint index, int size, GLenum type, bool normalized, size_t stride, const (void*) pointer) glVertexAttribPointer;
		  alias void function(GLenum mode, const(size_t*) count, GLenum type, const(void*) indicies, size_t primcount) glMultiDrawElements;
		  alias void function(GLenum mode, uint start, uint end, size_t count, GLenum type, const(void*) indicies) glDrawRangeElements;
		  alias void function(GLenum target, uint buffer) glBindBuffer;
		  alias void function(GLenum target, size_t size, const(void*) data, GLenum usage) glBufferData;
		  alias void function(GLenum target, size_t offset, size_t size, const(void*) data) glBufferSubData;
		  alias void function(handle program) glUseProgram;
		  alias void function(handle program) glDeleteProgram;
		  alias void function(handle program) glLinkProgram;
		  alias void function(handle program) glValidateProgram;
		  alias void function(handle program, handle shader) glAttachShader;
		  alias void function(handle program, handle shader) glDetachShader;
		  alias handle function() glCreateProgram;
		  alias handle function(GLenum type) glCreateShader;
		  alias void function(handle shader, size_t count, const(char)** strings, const(int)* length) glShaderSource;
		  alias void function(handle shader) glCompileShader;
		  alias void function(handle shader) glDeleteShader;
		  alias void function(handle shader, GLenum pname, int* params) glGetShaderiv;
		  alias void function(handle program, GLenum pname, int* params) glGetProgramiv;
		  alias void function(handle shader, int bufSize, int* length, char* infoLog) glGetShaderInfoLog;
		  alias void function(handle program, int bufSize, int* length, char* infoLog) glGetProgramInfoLog;
		  //alias void function(handle program, GLenum pname, int value) glProgramParameteriARB;
		  alias int function(handle program, const(char)* name) glGetAttribLocation;
		  alias int function(handle program, const(char)* name) glGetUniformLocation;
		  alias void function(handle program, uint index, int bufferSize, int* length, int* size, GLenum* type, char* name) glGetActiveUniform;
		  //alias void function(handle program, int count, const(char)** locations, GLenum bufferMode) glTransformFeedbackVaryingsEXT;
		  alias void function(handle program, uint index, const(char)* name) glBindAttribLocation;
		  alias void function(int location, float v0) glUniform1f;
		  alias void function(int location, float v0, float v1) glUniform2f;
		  alias void function(int location, float v0, float v1, float v2) glUniform3f;
		  alias void function(int location, float v0, float v1, float v2, float v3) glUniform4f;
		  alias void function(int location, int v0) glUniform1i;
		  alias void function(int location, int v0, int v1) glUniform2i;
		  alias void function(int location, int v0, int v1, int v2) glUniform3i;
		  alias void function(int location, int v0, int v1, int v2, int v3) glUniform4i;
		  alias void function(int location, int count, const(float)* values) glUniform1fv;
		  alias void function(int location, int count, const(float)* values) glUniform2fv;
		  alias void function(int location, int count, const(float)* values) glUniform3fv;
		  alias void function(int location, int count, const(float)* values) glUniform4fv;
		  alias void function(int location, int count, const(int)* values) glUniform1iv;
		  alias void function(int location, int count, const(int)* values) glUniform2iv;
		  alias void function(int location, int count, const(int)* values) glUniform3iv;
		  alias void function(int location, int count, const(int)* values) glUniform4iv;
		  alias void function(int locatoin, int count, bool transpose, const(float)* values) glUniformMatrix2fv;
		  alias void function(int location, int count, bool transpose, const(float)* values) glUniformMatrix3fv;
		  alias void function(int location, int count, bool transpose, const(float)* values) glUniformMatrix4fv;
		  alias void function(GLenum func, int pRef, uint mask) glStencilFunc;
		  alias void function(GLenum fail, GLenum zfail, GLenum zpass) glStencilOp;
		  alias void function(uint mask) glStencilMask;
		  alias void function(ubyte red, ubyte green, ubyte blue, ubyte alpha) glColorMask;
		  alias void function(GLenum factor, GLenum dfactor) glBlendFunc;
		  alias void function(GLenum mode) glCullFace;
		  alias void function(int n, uint* framebuffers) glGenFramebuffers;
		  alias void function(int n, uint* framebuffers) glDeleteFramebuffers;
		  alias GLenum function(GLenum target) glCheckFramebufferStatus;
		  alias void function(GLenum target, GLenum attachment, GLenum textarget, uint texture, int level) glFramebufferTexture1D;
		  alias void function(GLenum target, GLenum attachment, GLenum textarget, uint texture, int level) glFramebufferTexture2D;
		  alias void function(GLenum target, GLenum attachment, GLenum textarget, uint texture, int level, int zoffset) glFramebufferTexture3D;
		  alias void function(GLenum target, GLenum attachment, GLenum renderbuffertarget, uint renderbuffer) glFramebufferRenderbuffer;
		  alias void function(GLenum target, uint framebuffer) glBindFramebuffer;
		  alias void function(GLenum target, uint renderbuffer) glBindRenderbuffer;
		  alias void function(int n, uint* renderbuffers) glDeleteRenderbuffers;
		  alias void function(int n, uint* renderbuffers) glGenRenderbuffers;
		  alias void function(GLenum target, GLenum internalformat, int width, int height) glRenderbufferStorage;
		  alias void function(int n, GLenum* buffers) glDrawBuffers;
		  alias void function(double depth) glClearDepth;
		  alias void function(int s) glClearStencil;
		  alias void function(GLenum target) glGenerateMipmap;
		  alias void function(GLenum target, int level, GLenum pname, int* params) glGetTexLevelParameteriv;
		  //alias void function(GLenum target, uint index) glEnableIndexed;
      //alias void function(GLenum target, uint index) glDisableIndexed;

  		
		  //Extensions
		  alias void function(GLenum target, GLenum clamp) glClampColorARB;
  		
	  //}
  }
	
	//private static HMODULE handle;
	//private static bool isLoaded = false;
	
	private static void check(void* func, string name){
		if(func is null){
			throw new Error("Your OpenGL version does not support '" ~ name ~ "'");
		}
	}
	
	enum : uint {
		TEXTURE_2D						          = 0x0DE1,
		TEXTURE_CUBE_MAP                = 0x8513,
		TEXTURE_BINDING_CUBE_MAP        = 0x8514,
		TEXTURE_CUBE_MAP_POSITIVE_X     = 0x8515,
		TEXTURE_CUBE_MAP_NEGATIVE_X     = 0x8516,
		TEXTURE_CUBE_MAP_POSITIVE_Y     = 0x8517,
		TEXTURE_CUBE_MAP_NEGATIVE_Y     = 0x8518,
		TEXTURE_CUBE_MAP_POSITIVE_Z     = 0x8519,
		TEXTURE_CUBE_MAP_NEGATIVE_Z     = 0x851A,
		MATRIX_MODE						= 0x0BA0,
		MODELVIEW						= 0x1700,
		PROJECTION						= 0x1701,
		TEXTURE							= 0x1702,
		POINTS							= 0x0000,
		LINES							= 0x0001,
		LINE_LOOP						= 0x0002,
		LINE_STRIP						= 0x0003,
		TRIANGLES						= 0x0004,
		TRIANGLE_STRIP					= 0x0005,
		TRIANGLE_FAN					= 0x0006,
		QUADS							= 0x0007,
		QUAD_STRIP						= 0x0008,
		POLYGON							= 0x0009,
		LUMINANCE						= 0x1909,
		LUMINANCE_ALPHA 				= 0x190A,
		LUMINANCE32F_ARB 				= 0x8818,
		R16F							= 0x822D,
		R32F							= 0x822E,
		RGB8							= 0x8051,
		RGB16							= 0x8054,
		RGB16F							= 0x881B,
		RGB32F							= 0x8815,
		RGBA8							= 0x8058,
		RGBA16							= 0x805B,
		RGBA16F							= 0x881A,
		RGBA32F							= 0x8814,
		DEPTH_COMPONENT					= 0x1902,
		DEPTH_COMPONENT16				= 0x81A5,
		DEPTH_COMPONENT24				= 0x81A6,
		DEPTH_COMPONENT32				= 0x81A7,
		DEPTH_STENCIL					= 0x84F9,
		DEPTH24_STENCIL8 				= 0x88F0,
		RGB								= 0x1907,
		RGBA							= 0x1908,
		UNSIGNED_BYTE					= 0x1401,
		UNSIGNED_SHORT					= 0x1403,
		UNSIGNED_INT					= 0x1405,
		UNSIGNED_INT_24_8				= 0x84FA,
		INT								= 0x1404,
		FLOAT							= 0x1406,
		TEXTURE0						= 0x84C0,	
		TEXTURE1						= TEXTURE0 + 1,
		TEXTURE2						= TEXTURE0 + 2,
		TEXTURE3						= TEXTURE0 + 3,
		TEXTURE4						= TEXTURE0 + 4,
		TEXTURE5						= TEXTURE0 + 5,
		TEXTURE6						= TEXTURE0 + 6,
		TEXTURE7						= TEXTURE0 + 7,
		TEXTURE8						= TEXTURE0 + 8,
		GENERATE_MIPMAP					= 0x8191,
		FALSE							= 0x0,
		TRUE							= 0x1,
		S								= 0x2000,
		T								= 0x2001,
		R								= 0x2002,
		Q								= 0x2003,
		REPEAT							= 0x2901,
		CLAMP							= 0x2900,
		LINEAR							= 0x2601,
		NEAREST							= 0x2600,
		NEAREST_MIPMAP_NEAREST			= 0x2700,
		NEAREST_MIPMAP_LINEAR			= 0x2702,
		LINEAR_MIPMAP_NEAREST			= 0x2701,
		LINEAR_MIPMAP_LINEAR			= 0x2703,
		TEXTURE_MIN_FILTER				= 0x2801,
		TEXTURE_MAG_FILTER				= 0x2800,
		TEXTURE_WRAP_S					= 0x2802,
		TEXTURE_WRAP_T					= 0x2803,
		TEXTURE_WRAP_R                  = 0x8072,
		CLAMP_TO_EDGE					= 0x812F,
		ARRAY_BUFFER					= 0x8892,
		ELEMENT_ARRAY_BUFFER			= 0x8893,
		STATIC_DRAW						= 0x88E4,
		DYNAMIC_DRAW					= 0x88E8,
		FLOAT_VEC2						= 0x8B50,
		FLOAT_VEC3						= 0x8B51,
		FLOAT_VEC4						= 0x8B52,
		INT_VEC2						= 0x8B53,
		INT_VEC3						= 0x8B54,
		INT_VEC4						= 0x8B55,
		FLOAT_MAT2                      = 0x8B5A,
		FLOAT_MAT3                      = 0x8B5B,
		FLOAT_MAT4                      = 0x8B5C,
		SAMPLER_1D						= 0x8B5D,
		SAMPLER_2D						= 0x8B5E,
		SAMPLER_3D						= 0x8B5F,
		SAMPLER_CUBE					= 0x8B60,
		LINES_ADJACENCY_ARB 			= 0x000A,
		LINE_STRIP_ADJACENCY_ARB 		= 0x000B,
		TRIANGLES_ADJACENCY_ARB 		= 0x000C,
		TRIANGLE_STRIP_ADJACENCY_ARB 	= 0x000D,
		PROGRAM_POINT_SIZE_ARB 			= 0x8642,
		MAX_GEOMETRY_TEXTURE_IMAGE_UNITS_ARB = 0x8C29,
		FRAMEBUFFER_ATTACHMENT_LAYERED_ARB = 0x8DA7,
		FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS_ARB = 0x8DA8,
		FRAMEBUFFER_INCOMPLETE_LAYER_COUNT_ARB = 0x8DA9,
		GEOMETRY_SHADER_ARB 			= 0x8DD9,
		GEOMETRY_VERTICES_OUT_ARB 		= 0x8DDA,
		GEOMETRY_INPUT_TYPE_ARB 		= 0x8DDB,
		GEOMETRY_OUTPUT_TYPE_ARB 		= 0x8DDC,
		MAX_GEOMETRY_VARYING_COMPONENTS_ARB = 0x8DDD,
		MAX_VERTEX_VARYING_COMPONENTS_ARB = 0x8DDE,
		MAX_GEOMETRY_UNIFORM_COMPONENTS_ARB = 0x8DDF,
		MAX_GEOMETRY_OUTPUT_VERTICES_ARB = 0x8DE0,
		MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS_ARB = 0x8DE1,
		VERTEX_SHADER					= 0x8B31,
		FRAGMENT_SHADER					= 0x8B30,
		INTERLEAVED_ATTRIBS_EXT         = 0x8C8C,
		SEPARATE_ATTRIBS_EXT            = 0x8C8D,
		DELETE_STATUS					= 0x8B80,
		COMPILE_STATUS					= 0x8B81,
		LINK_STATUS						= 0x8B82,
		VALIDATE_STATUS					= 0x8B83,
		INFO_LOG_LENGTH					= 0x8B84,
		ATTACHED_SHADERS				= 0x8B85,
		ACTIVE_UNIFORMS					= 0x8B86,
		ACTIVE_UNIFORM_MAX_LENGTH		= 0x8B87,
		SHADER_SOURCE_LENGTH			= 0x8B88,
		ACTIVE_ATTRIBUTES				= 0x8B89,
		ACTIVE_ATTRIBUTE_MAX_LENGTH		= 0x8B8A,
		SHADING_LANGUAGE_VERSION		= 0x8B8C,
		NEVER							= 0x0200,
		LESS 							= 0x0201,
		EQUAL 							= 0x0202,
		LEQUAL							= 0x0203,
		GREATER							= 0x0204,
		NOTEQUAL						= 0x0205,
		GEQUAL							= 0x0206,
		ALWAYS							= 0x0207,
		KEEP							= 0x1E00,
		REPLACE							= 0x1E01,
		INCR							= 0x1E02,
		DECR							= 0x1E03,
		ZERO							= 0x0,
		INCR_WRAP						= 0x8507,
		DECR_WRAP						= 0x8508,
		ONE								= 0x1,
		SRC_ALPHA						= 0x0302,
		ONE_MINUS_SRC_ALPHA				= 0x0303,
		DST_ALPHA						= 0x0304,
		ONE_MINUS_DST_ALPHA				= 0x0305,
		NONE							= 0x0,
		FRONT							= 0x0404,
		BACK							= 0x0405,
		FRONT_AND_BACK					= 0x0408,
		DEPTH_TEST						= 0x0B71,
		STENCIL_TEST					= 0x0B90,
		BLEND							= 0x0BE2,
		CULL_FACE						= 0x0B44,
		CLIP_PLANE0						= 0x0300,
		MULTISAMPLE						= 0x809D,
		LINE							= 0x1B01,
		FILL							= 0x1B02,
		INVERT							= 0x150A,
		MAX_DRAW_BUFFERS				= 0x8824,
		MAX_COLOR_ATTACHMENTS			= 0x8CDF,
		FRAMEBUFFER						= 0x8D40,
		RENDERBUFFER					= 0x8D41,
		DEPTH_ATTACHMENT				= 0x8D00,
		STENCIL_ATTACHMENT				= 0x8D20,
		COLOR_ATTACHMENT0				= 0x8CE0,
		FRAMEBUFFER_COMPLETE			= 0x8CD5,
		FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7,
		FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 0x8CD6,
		FRAMEBUFFER_INCOMPLETE_DIMENSIONS = 0x8CD9,
		FRAMEBUFFER_INCOMPLETE_FORMATS	= 0x8CDA,
		FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER = 0x8CDB,
		FRAMEBUFFER_INCOMPLETE_READ_BUFFER = 0x8CDC,
		FRAMEBUFFER_UNSUPPORTED 		= 0x8CDD,
		CLAMP_VERTEX_COLOR_ARB          = 0x891A,
		CLAMP_FRAGMENT_COLOR_ARB        = 0x891B,
		CLAMP_READ_COLOR_ARB            = 0x891C,
		POINT_SMOOTH					= 0x0B10,
		DRAW_BUFFER0					= 0x8825,
		MIRRORED_REPEAT                 = 0x8370,
		MAX_TEXTURE_SIZE				= 0x0D33,
		READ_ONLY                       = 0x88B8,
		WRITE_ONLY                      = 0x88B9,
		READ_WRITE                      = 0x88BA,
		COMPRESSED_ALPHA_ARB            = 0x84E9,
		COMPRESSED_LUMINANCE_ARB        = 0x84EA,
		COMPRESSED_LUMINANCE_ALPHA_ARB  = 0x84EB,
		COMPRESSED_INTENSITY_ARB        = 0x84EC,
		COMPRESSED_RGB_ARB              = 0x84ED,
		COMPRESSED_RGBA_ARB             = 0x84EE,
		TEXTURE_COMPRESSION_HINT_ARB    = 0x84EF,
		TEXTURE_COMPRESSED_IMAGE_SIZE_ARB = 0x86A0,
		TEXTURE_COMPRESSED_ARB          = 0x86A1,
		NUM_COMPRESSED_TEXTURE_FORMATS_ARB = 0x86A2,
		COMPRESSED_TEXTURE_FORMATS_ARB  = 0x86A3,
		COMPRESSED_RGB_S3TC_DXT1_EXT    = 0x83F0,
		COMPRESSED_RGBA_S3TC_DXT1_EXT   = 0x83F1,
		COMPRESSED_RGBA_S3TC_DXT3_EXT   = 0x83F2,
		COMPRESSED_RGBA_S3TC_DXT5_EXT   = 0x83F3,
		EXTENSIONS                      = 0x1F03
	};
	
	enum : uint {
		CURRENT_BIT				= 0x00000001,
		POINT_BIT				= 0x00000002,
		LINE_BIT				= 0x00000004,
		POLYGON_BIT				= 0x00000008,
		POLYGON_STIPPLE_BIT		= 0x00000010,
		PIXEL_MODE_BIT			= 0x00000020,
		LIGHTING_BIT			= 0x00000040,
		FOG_BIT					= 0x00000080,
		DEPTH_BUFFER_BIT		= 0x00000100,
		ACCUM_BUFFER_BIT		= 0x00000200,
		STENCIL_BUFFER_BIT		= 0x00000400,
		VIEWPORT_BIT			= 0x00000800,
		TRANSFORM_BIT			= 0x00001000,
		ENABLE_BIT				= 0x00002000,
		COLOR_BUFFER_BIT		= 0x00004000,
		HINT_BIT				= 0x00008000,
		EVAL_BIT				= 0x00010000,
		LIST_BIT				= 0x00020000,
		TEXTURE_BIT				= 0x00040000,
		SCISSOR_BIT				= 0x00080000,
		ALL_ATTRIB_BITS			= 0x000FFFFF
	};
	
	enum Extensions : uint {
		GL_ARB_texture_compression = 0,
		GL_EXT_texture_compression_s3tc
	}
	
	enum ErrorCode : uint {
		NO_ERROR			= 0x0000,
		INVALID_ENUM		= 0x0500,
		INVALID_VALUE		= 0x0501,
		INVALID_OPERATION	= 0x0502,
		STACK_OVERFLOW		= 0x0503,
		STACK_UNDERFLOW		= 0x0504,
		OUT_OF_MEMORY		= 0x0505
	};
	
	static string TranslateError(ErrorCode error){
		switch(error){
			case ErrorCode.NO_ERROR:
				return "GL_NO_ERROR";
			case ErrorCode.INVALID_ENUM:
				return "GL_INVALID_ENUM";
			case ErrorCode.INVALID_VALUE:
				return "GL_INVALID_VALUE";
			case ErrorCode.INVALID_OPERATION:
				return "GL_INVALID_OPERATION";
			case ErrorCode.STACK_OVERFLOW:
				return "GL_STACK_OVERFLOW";
			case ErrorCode.STACK_UNDERFLOW:
				return "GL_STACK_UNDERFLOW";
			case ErrorCode.OUT_OF_MEMORY:
				return "GL_OUT_OF_MEMORY";
			default:
				break;
		}
		return "UNKOWN";
	}
	
	static bool contextAlive = false;
	static private bool[Extensions.max+1] supportedExtensions;
	static void SetContextAlive(bool pValue){
		contextAlive = pValue;
	}
	static bool GetContextAlive(){
		return contextAlive;
	}

	//This compile time function generates the function pointer variables
  version(NO_OPENGL){}
  else
  {
	  mixin( generateDllCode!(gl)(&dll_declare) );
  }

	static void load_dll(){
    version(NO_OPENGL)
    {
      g_IsOpenGLThread = true;
      g_textureIdGenerator = New!(typeof(g_textureIdGenerator))();
      g_bufferIdGenerator = New!(typeof(g_bufferIdGenerator))();
      g_programIdGenerator = New!(typeof(g_programIdGenerator))();
      g_shaderIdGenerator = New!(typeof(g_shaderIdGenerator))();
      g_framebufferIdGenerator = New!(typeof(g_framebufferIdGenerator))();
      g_renderbufferIdGenerator = New!(typeof(g_renderbufferIdGenerator))();
      g_bufferInfos = New!(typeof(g_bufferInfos))();
      g_attributeLocations = New!(typeof(g_attributeLocations))();
      g_uniformLocations = New!(typeof(g_uniformLocations))();
      g_programInfos = New!(typeof(g_programInfos))();
    }
    else
    {
		  assert(SDL.IsDllLoaded()==true,"SDL hast to be loaded first");
		  //This compile time function generates the calls to load the functions from the dll
		  mixin ( generateDllCode!(gl)(&dll_init) );
    }
		
		//Check for supported extensions
    auto extensionsOrg = gl.GetString(EXTENSIONS);
		rcstring extensions = rcstring(extensionsOrg[0..strlen(extensionsOrg)]);
		
		supportedExtensions[Extensions.GL_ARB_texture_compression] = (indexOf(extensions, "GL_ARB_texture_compression") != -1);
		if(supportedExtensions[Extensions.GL_ARB_texture_compression])
			base.logger.info("GL_ARB_texture_compression is supported");
		supportedExtensions[Extensions.GL_EXT_texture_compression_s3tc] = (indexOf(extensions, "GL_EXT_texture_compression_s3tc") != -1);
		if(supportedExtensions[Extensions.GL_EXT_texture_compression_s3tc])
			base.logger.info("GL_EXT_texture_compression_s3tc is supported");
	}
	
	static bool isSupported(Extensions ext){
		return supportedExtensions[ext];
	}

  version(NO_OPENGL)
  {
    shared static ~this()
    {
      g_IsOpenGLThread = false;
      Delete(g_textureIdGenerator);
      Delete(g_bufferIdGenerator);
      Delete(g_programIdGenerator);
      Delete(g_shaderIdGenerator);
      Delete(g_framebufferIdGenerator);
      Delete(g_renderbufferIdGenerator);
      Delete(g_bufferInfos);
      Delete(g_attributeLocations);
      Delete(g_uniformLocations);
      Delete(g_programInfos);
    }
  }
};