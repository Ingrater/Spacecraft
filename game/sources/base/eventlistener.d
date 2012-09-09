module base.eventlistener;

/**
 * EventListener interface
 */
interface IEventListener {
	/**
	 * called on focus event
	 * Params:
	 *  hasFocus = true when window has focus, false otherwise
	 */
	void OnFocus(bool hasFocus, ubyte state);
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
class EventListenerAdapter : IEventListener {
	void OnFocus(bool hasFocus, ubyte state){}
	void OnResize(int width, int height){}
	void OnQuit(){}
};