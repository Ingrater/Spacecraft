module client.eventhandler;

import renderer.sdl.main;
import base.eventlistener;
import client.inputlistener;
import thBase.container.vector;


/**
 * event handler, handles input and window events
 */
class EventHandler {
private:
	struct InputListenerInfo {
		shared(IInputListener) sharedRef;
		IInputListener normalRef;
		this(shared(IInputListener) sharedRef, IInputListener normalRef){
			this.sharedRef = sharedRef;
			this.normalRef = normalRef;
		}

    int opEquals(ref const InputListenerInfo rh) 
    {
      return this.sharedRef is rh.sharedRef && this.normalRef is rh.normalRef;
    }
	}
	
	Vector!InputListenerInfo m_InputListeners;
	Vector!IEventListener m_EventListeners;
public:

  this()
  {
    m_InputListeners = New!(typeof(m_InputListeners))();
    m_EventListeners = New!(typeof(m_EventListeners))();
  }

  ~this()
  {
    Delete(m_InputListeners);
    Delete(m_EventListeners);
  }

	/**
	 * registers a new input listener
	 * Params:
	 *  listener = new listener to add
	 */
	void RegisterInputListener(IInputListener listener){
		m_InputListeners ~= InputListenerInfo(null,listener);
	}

	///ditto
	void RegisterInputListener(shared(IInputListener) listener) shared {
		(cast(Vector!InputListenerInfo)m_InputListeners) ~= InputListenerInfo(listener,null);
	}

  void DeregisterInputListener(shared(IInputListener) listener) shared {
    (cast(Vector!InputListenerInfo)m_InputListeners).remove(InputListenerInfo(listener,null));
  }
	
	/**
   * registers a new event listener
   * Params:
   *  listener = new listener to add
   */
	void RegisterEventListener(IEventListener listener){
		m_EventListeners ~= listener;
	}

  /**
   * unregisters a preivous registerd event listener
   * Params:
   *  listener = the listener to remove
   */
  void DeregisterEventListener(IEventListener listener)
  {
    m_EventListeners.remove(listener);
  }
	
	/**
	 * Changes the grabbing state of the mouse
	 * Params:
	 *	value = true = mouse can not leave the window, false = mouse can leave window
	 */
	void GrabMouse(bool value){
		if(value)
			SDL.WM_GrabInput(SDL.GrabMode.ON);
		else
			SDL.WM_GrabInput(SDL.GrabMode.OFF);
	}
	
	/**
	 * Enters textmode (fills the unicode field of the Keyboard event)
	 * Params:
	 *  value = true to enable textmode, false to disable
	 */
	void EnableTextmode(bool value){
		SDL.EnableUNICODE( (value) ? SDL.ENABLE : SDL.DISABLE );
	}
	
	/**
	 * Changes the visibility of the mouse cursor
	 * Params:
	 *  value = true = show mouse cursor, false = hide mouse cursor
	 */
	void ShowMouse(bool value){
		if(value)
			SDL.ShowCursor(SDL.ENABLE);
		else
			SDL.ShowCursor(SDL.DISABLE);
	}

	/**
	 * Progresses all pending events, call this from main loop only
	 */
	bool ProgressEvents(){
		SDL.Event event;
		while(SDL.PollEvent(&event)){
			// BE AWARE: This is an EXTREMELY ugly hack to avoid threading issues with
			// SDL to toggle the input grabbing. This should hopefully allow to make
			// some screenshots... what a nightmare.
			if (event.type == SDL.KEYDOWN){
				if (event.key.keysym.sym == Keys.F4) {
					ShowMouse(true);
					GrabMouse(false);
				} else if (event.key.keysym.sym == Keys.F5) {
					ShowMouse(false);
					GrabMouse(true);
				}
			}
			
			switch(event.type){
				case SDL.QUIT:
					{
						foreach(listener; m_EventListeners){
							listener.OnQuit();
						}
						return false;
					}
				case SDL.ACTIVEEVENT:
					foreach(listener; m_EventListeners){
						listener.OnFocus((event.active.gain != 0),event.active.state);
					}
					break;
				case SDL.VIDEORESIZE:
					foreach(listener; m_EventListeners){
						listener.OnResize(event.resize.width, event.resize.height);
					}
					break;
				case SDL.KEYDOWN:
				case SDL.KEYUP:
					bool pressed = (event.key.state == SDL.PRESSED);
					foreach(listener; m_InputListeners){
						if(listener.sharedRef)
							listener.sharedRef.OnKeyboard(event.key.which, pressed, event.key.keysym.sym, event.key.keysym.unicode, event.key.keysym.scancode, event.key.keysym.mod);
						else
							listener.normalRef.OnKeyboard(event.key.which, pressed, event.key.keysym.sym, event.key.keysym.unicode, event.key.keysym.scancode, event.key.keysym.mod);
					}
					break;
				case SDL.MOUSEBUTTONUP:
				case SDL.MOUSEBUTTONDOWN:
					bool pressed = (event.button.state == SDL.PRESSED);
					foreach(listener; m_InputListeners){
						if(listener.sharedRef)
							listener.sharedRef.OnMouseButton(event.button.which,event.button.button,pressed,event.button.x,event.button.y);
						else
							listener.normalRef.OnMouseButton(event.button.which,event.button.button,pressed,event.button.x,event.button.y);
					}
					break;
				case SDL.MOUSEMOTION:
					foreach(listener; m_InputListeners){
						if(listener.sharedRef)
							listener.sharedRef.OnMouseMove(event.motion.which,event.motion.x,event.motion.y,event.motion.xrel,event.motion.yrel);
						else
							listener.normalRef.OnMouseMove(event.motion.which,event.motion.x,event.motion.y,event.motion.xrel,event.motion.yrel);
					}
					break;
				case SDL.JOYAXISMOTION:
					foreach(listener; m_InputListeners){
						if(listener.sharedRef)
							listener.sharedRef.OnJoyAxis(event.jaxis.which,event.jaxis.axis,event.jaxis.value);
						else
							listener.normalRef.OnJoyAxis(event.jaxis.which,event.jaxis.axis,event.jaxis.value);
					}
					break;
				case SDL.JOYBALLMOTION:
					foreach(listener; m_InputListeners){
						if(listener.sharedRef)
							listener.sharedRef.OnJoyBall(event.jball.which,event.jball.ball,event.jball.xrel,event.jball.yrel);
						else
							listener.normalRef.OnJoyBall(event.jball.which,event.jball.ball,event.jball.xrel,event.jball.yrel);
					}
					break;
				case SDL.JOYBUTTONDOWN:
				case SDL.JOYBUTTONUP:
					bool pressed = (event.jbutton.state == SDL.PRESSED);
					foreach(listener; m_InputListeners){
						if(listener.sharedRef)
							listener.sharedRef.OnJoyButton(event.jbutton.which,event.jbutton.button,pressed);
						else
							listener.normalRef.OnJoyButton(event.jbutton.which,event.jbutton.button,pressed);
					}
					break;
				case SDL.JOYHATMOTION:
					foreach(listener; m_InputListeners){
						if(listener.sharedRef)
							listener.sharedRef.OnJoyHat(event.jhat.which,event.jhat.hat,event.jhat.value);
						else
							listener.normalRef.OnJoyHat(event.jhat.which,event.jhat.hat,event.jhat.value);
					}
					break;
				default:
					break;
			}
		}
		return true;
	}
};
