module base.windowevents;

import base.inputlistener;
import thBase.enumbitfield;

enum FocusRecieved : ubyte
{
  Mouse       = 0x01,
  Input       = 0x02,
  Application = 0x04
}

/**
 * EventListener interface
 */
interface IWindowEventListener {
	/**
	 * called on focus event
	 * Params:
	 *  hasFocus = true when window has focus, false otherwise
	 */
	void OnFocus(bool hasFocus, EnumBitfield!FocusRecieved focusRecieved);
	/**
	 * called on window resize
	 * Params:
	 *  width = new window width
	 *  height = new window height
	 */
	void OnResize(int width, int height);
	
	/**
	 * called on quit
	 */
	void OnQuit();
};

/**
 * dummy implementation of IEventListener, does nothing
 * should be used when you only want to implement some of the event functions, but not all of them
 */
class WindowEventListenerAdapter : IWindowEventListener {
	void OnFocus(bool hasFocus, EnumBitfield!FocusRecieved focusRecieved){}
	void OnResize(int width, int height){}
	void OnQuit(){}
};

interface IWindowEventHandler
{
	/**
  * registers a new input listener
  * Params:
  *  listener = new listener to add
  */
	void RegisterInputListener(IInputListener listener);

	///ditto
	void RegisterInputListener(shared(IInputListener) listener) shared;

	/**
  * deregisters a input listener
  * Params:
  *  listener = listener to remove
  */
  void DeregisterInputListener(IInputListener listener);

  ///ditto
  void DeregisterInputListener(shared(IInputListener) listener) shared;

	/**
  * registers a new event listener
  * Params:
  *  listener = new listener to add
  */
	void RegisterEventListener(IWindowEventListener listener);

  /**
  * unregisters a preivous registerd event listener
  * Params:
  *  listener = the listener to remove
  */
  void DeregisterEventListener(IWindowEventListener listener);
};