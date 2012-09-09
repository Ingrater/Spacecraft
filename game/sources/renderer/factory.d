module renderer.factory;

import base.renderer;
import renderer.renderer;
import renderer.freetype.ft;
import renderer.sdl.main;
import renderer.sdl.image;
import renderer.opengl;
import renderer.freetype.ft;
import std.c.string;

version(Windows)
{
  import core.sys.windows.windows;

  extern(System) {
    BOOL SetWindowPos( HWND hWnd, HWND hWndInsertAfter, int X, int Y, int cx, int cy, UINT uFlags );     
  }
}

class RendererFactory : IRendererFactory {
	private:
		static IRenderer m_Renderer = null;	
	public:
    ~this()
    {
      Delete(m_Renderer);
    }
		void Init(int screenWidth, int screenHeight, bool fullScreen, bool vsync, bool noBorder, bool grabInput, int antiAliasing){			//Load dlls
			version(X86){
				ft.Load("freetype.dll","libfreetype.so.6");
				
				SDL.LoadDll("SDL.dll","libSDL-1.2.so.0");
				SDLImage.LoadDll("SDL_image.dll","libSDL_image-1.2.so.0");
			}
			version(X86_64){
				ft.Load("freetype.dll","libfreetype.so.6");

				SDL.LoadDll("SDL64.dll","libSDL-1.2.so.0");
				SDLImage.LoadDll("SDL_image64.dll","libSDL_image-1.2.so.0");
			}
			
			if(SDL.Init(SDL.INIT_VIDEO) != 0){
				throw new Exception("Failed initialzing SDL");
			}
		
			if(SDL.GL.LoadLibrary(null) != 0){
				throw new Exception("Error loading opengl");
			}
		
			//initialize OpenGL window
			SDL.GL.SetAttribute(SDL.GLattr.GL_DOUBLEBUFFER,1);
			//SDL.GL.SetAttribute(SDL.GLattr.GL_ACCELERATED_VISUAL,1);
			SDL.GL.SetAttribute(SDL.GLattr.GL_SWAP_CONTROL, vsync ? 1 : 0);
			if(antiAliasing > 0){
				SDL.GL.SetAttribute(SDL.GLattr.GL_MULTISAMPLEBUFFERS, 1);
				SDL.GL.SetAttribute(SDL.GLattr.GL_MULTISAMPLESAMPLES, antiAliasing);
			}
			
			int flags = SDL.OPENGL | SDL.HWSURFACE;
			if(noBorder){
				flags |= SDL.NOFRAME;
			}
			if(fullScreen){
				flags |= SDL.FULLSCREEN;
			}
			
			SDL.Surface *screen = SDL.SetVideoMode(screenWidth, screenHeight, 24, flags );
			if(screen is null){
				char* error = SDL.GetError();
				string message = "Error initializing screen: ";
				if(error !is null){
					message ~= error[0..strlen(error)];
				}
				throw new Exception(message);
			}
			if(screen.flags && SDL.OPENGL == 0){
				throw new Exception("No OpenGL Window created");
			}

      version(Windows)
      {
        if(!fullScreen)
        {
          SDL.SysWMinfo info;
          SDL.VERSION(&info._version);
          SDL.GetWMInfo(&info);
          RECT r;
          SetWindowPos(info.window, null, 0, 0, 0, 0, 0x0001 /*SWP_NOSIZE*/);
        }
      }
			
			//load OpenGL API
			gl.load_dll();
			gl.SetContextAlive(true);
			
			// Set the window attributes
			if (grabInput){
				SDL.WM_GrabInput(SDL.GrabMode.ON);
				SDL.ShowCursor(SDL.DISABLE);
			}
		}
	
		IRenderer GetRenderer(){
			if(m_Renderer is null){
				m_Renderer = New!Renderer();
			}
			return m_Renderer;
		}
}

IRendererFactory GetRendererFactory(){
	return New!RendererFactory();
}

void DeleteRendererFactory(IRendererFactory factory)
{
  Delete(factory);
}
