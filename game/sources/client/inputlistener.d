module client.inputlistener;

import base.messages : BaseMessage;
import thBase.container.queue;

/**
 * list of keys that change the behaviour of other keys 
 */
enum ModKeys : uint {
	LSHIFT= 0x0001, /// left shift
	RSHIFT= 0x0002, /// right shift
	LCTRL = 0x0040, /// left ctrl
	RCTRL = 0x0080, /// right ctrl
	LALT  = 0x0100, /// left alt
	RALT  = 0x0200, /// right alt
	LMETA = 0x0400, /// left windows key
	RMETA = 0x0800, /// right windows key
	NUM   = 0x1000, /// num
	CAPS  = 0x2000, /// caps lock
	MODE  = 0x4000 /// mode
};

enum Keys : uint {
    /* The keyboard syms have been cleverly chosen to map to ASCII */
    UNKNOWN        = 0,
    FIRST      = 0,
    BACKSPACE      = 8,
    TAB        = 9,
    CLEAR      = 12,
    RETURN     = 13,
    PAUSE      = 19,
    ESCAPE     = 27,
    SPACE      = 32,
    EXCLAIM        = 33,
    QUOTEDBL       = 34,
    HASH       = 35,
    DOLLAR     = 36,
    AMPERSAND      = 38,
    QUOTE      = 39,
    LEFTPAREN      = 40,
    RIGHTPAREN     = 41,
    ASTERISK       = 42,
    PLUS       = 43,
    COMMA      = 44,
    MINUS      = 45,
    PERIOD     = 46,
    SLASH      = 47,
    NUMBER_0          = 48,
    NUMBER_1          = 49,
    NUMBER_2          = 50,
    NUMBER_3          = 51,
    NUMBER_4          = 52,
    NUMBER_5          = 53,
    NUMBER_6          = 54,
    NUMBER_7          = 55,
    NUMBER_8          = 56,
    NUMBER_9          = 57,
    COLON      = 58,
    SEMICOLON      = 59,
    LESS       = 60,
    EQUALS     = 61,
    GREATER        = 62,
    QUESTION       = 63,
    AT         = 64,
    /*
       Skip uppercase letters
     */
    LEFTBRACKET    = 91,
    BACKSLASH      = 92,
    RIGHTBRACKET   = 93,
    CARET      = 94,
    UNDERSCORE     = 95,
    BACKQUOTE      = 96,
    a          = 97,
    b          = 98,
    c          = 99,
    d          = 100,
    e          = 101,
    f          = 102,
    g          = 103,
    h          = 104,
    i          = 105,
    j          = 106,
    k          = 107,
    l          = 108,
    m          = 109,
    n          = 110,
    o          = 111,
    p          = 112,
    q          = 113,
    r          = 114,
    s          = 115,
    t          = 116,
    u          = 117,
    v          = 118,
    w          = 119,
    x          = 120,
    y          = 121,
    z          = 122,
    DELETE     = 127,
    /* End of ASCII mapped keysyms */

    /* International keyboard syms */
    WORLD_0        = 160,      /* 0xA0 */
    WORLD_1        = 161,
    WORLD_2        = 162,
    WORLD_3        = 163,
    WORLD_4        = 164,
    WORLD_5        = 165,
    WORLD_6        = 166,
    WORLD_7        = 167,
    WORLD_8        = 168,
    WORLD_9        = 169,
    WORLD_10       = 170,
    WORLD_11       = 171,
    WORLD_12       = 172,
    WORLD_13       = 173,
    WORLD_14       = 174,
    WORLD_15       = 175,
    WORLD_16       = 176,
    WORLD_17       = 177,
    WORLD_18       = 178,
    WORLD_19       = 179,
    WORLD_20       = 180,
    WORLD_21       = 181,
    WORLD_22       = 182,
    WORLD_23       = 183,
    WORLD_24       = 184,
    WORLD_25       = 185,
    WORLD_26       = 186,
    WORLD_27       = 187,
    WORLD_28       = 188,
    WORLD_29       = 189,
    WORLD_30       = 190,
    WORLD_31       = 191,
    WORLD_32       = 192,
    WORLD_33       = 193,
    WORLD_34       = 194,
    WORLD_35       = 195,
    WORLD_36       = 196,
    WORLD_37       = 197,
    WORLD_38       = 198,
    WORLD_39       = 199,
    WORLD_40       = 200,
    WORLD_41       = 201,
    WORLD_42       = 202,
    WORLD_43       = 203,
    WORLD_44       = 204,
    WORLD_45       = 205,
    WORLD_46       = 206,
    WORLD_47       = 207,
    WORLD_48       = 208,
    WORLD_49       = 209,
    WORLD_50       = 210,
    WORLD_51       = 211,
    WORLD_52       = 212,
    WORLD_53       = 213,
    WORLD_54       = 214,
    WORLD_55       = 215,
    WORLD_56       = 216,
    WORLD_57       = 217,
    WORLD_58       = 218,
    WORLD_59       = 219,
    WORLD_60       = 220,
    WORLD_61       = 221,
    WORLD_62       = 222,
    WORLD_63       = 223,
    WORLD_64       = 224,
    WORLD_65       = 225,
    WORLD_66       = 226,
    WORLD_67       = 227,
    WORLD_68       = 228,
    WORLD_69       = 229,
    WORLD_70       = 230,
    WORLD_71       = 231,
    WORLD_72       = 232,
    WORLD_73       = 233,
    WORLD_74       = 234,
    WORLD_75       = 235,
    WORLD_76       = 236,
    WORLD_77       = 237,
    WORLD_78       = 238,
    WORLD_79       = 239,
    WORLD_80       = 240,
    WORLD_81       = 241,
    WORLD_82       = 242,
    WORLD_83       = 243,
    WORLD_84       = 244,
    WORLD_85       = 245,
    WORLD_86       = 246,
    WORLD_87       = 247,
    WORLD_88       = 248,
    WORLD_89       = 249,
    WORLD_90       = 250,
    WORLD_91       = 251,
    WORLD_92       = 252,
    WORLD_93       = 253,
    WORLD_94       = 254,
    WORLD_95       = 255,      /* 0xFF */

    /* Numeric keypad */
    KP0        = 256,
    KP1        = 257,
    KP2        = 258,
    KP3        = 259,
    KP4        = 260,
    KP5        = 261,
    KP6        = 262,
    KP7        = 263,
    KP8        = 264,
    KP9        = 265,
    KP_PERIOD      = 266,
    KP_DIVIDE      = 267,
    KP_MULTIPLY    = 268,
    KP_MINUS       = 269,
    KP_PLUS        = 270,
    KP_ENTER       = 271,
    KP_EQUALS      = 272,

    /* Arrows + Home/End pad */
    UP         = 273,
    DOWN       = 274,
    RIGHT      = 275,
    LEFT       = 276,
    INSERT     = 277,
    HOME       = 278,
    END        = 279,
    PAGEUP     = 280,
    PAGEDOWN       = 281,

    /* Function keys */
    F1         = 282,
    F2         = 283,
    F3         = 284,
    F4         = 285,
    F5         = 286,
    F6         = 287,
    F7         = 288,
    F8         = 289,
    F9         = 290,
    F10        = 291,
    F11        = 292,
    F12        = 293,
    F13        = 294,
    F14        = 295,
    F15        = 296,

    /* Key state modifier keys */
    NUMLOCK        = 300,
    CAPSLOCK       = 301,
    SCROLLOCK      = 302,
    RSHIFT     = 303,
    LSHIFT     = 304,
    RCTRL      = 305,
    LCTRL      = 306,
    RALT       = 307,
    LALT       = 308,
    RMETA      = 309,
    LMETA      = 310,
    LSUPER     = 311,      /* Left "Windows" key */
    RSUPER     = 312,      /* Right "Windows" key */
    MODE       = 313,      /* "Alt Gr" key */
    COMPOSE        = 314,      /* Multi-key compose key */

    /* Miscellaneous function keys */
    HELP       = 315,
    PRINT      = 316,
    SYSREQ     = 317,
    BREAK      = 318,
    MENU       = 319,
    POWER      = 320,      /* Power Macintosh power key */
    EURO       = 321,      /* Some european keyboards */
    UNDO       = 322,      /* Atari keyboard has Undo */

    /* Add any other keys here */

    LAST
}

/**
 * Input listener
 */
interface IInputListener {
	/**
	 * called on mouse button click
	 * Params:
	 *  device = number of the mouse device
	 *  button = number of the mouse button
	 *  pressed = true when pressed, false when released
	 *  x = window coordinates x
	 *  y = window coordinates y 
	 */ 
	void OnMouseButton(ubyte device, ubyte button, bool pressed, ushort x, ushort y);
	
	/**
	 * called on mouse move 
	 * Params:
	 *  device = number of the mouse device
	 *  x = window coordinates x
	 *  y = window coordiantes y
	 *  xrel = relative x movement
	 *  yrel = relative y movement
	 */
	void OnMouseMove(ubyte device, ushort x, ushort y, short xrel, short yrel);
	
	/**
	 * called on keyboard key event
	 * Params:
	 *  device = number of the keyboard
	 *  pressed = true when pressed, false when released
	 *  key = the key
	 *  unicode = unicode char of the key pressed
	 *  scancode = the scancode of the key 
	 *  mod = modding keys pressed, see ModKeys
	 */
	void OnKeyboard(ubyte device, bool pressed, uint key, ushort unicode, ubyte scancode, uint mod);
	
	/**
	 * called on joystick axis event
	 * Params:
	 *  device = number of the joystick
	 *  axis = number of the axis
	 *  value = value of the axis
	 */
	void OnJoyAxis(ubyte device, ubyte axis, short value);
	
	/**
	 * called on joystick button event
	 * Params:
	 *  device = number of the joystick
	 *  button = number of the button 
	 *  pressed = true when pressed, false otherwise
	 */
	void OnJoyButton(ubyte device, ubyte button, bool pressed);
	
	/**
	 * called on joystick ball event
	 * Params:
	 *  device = number of the joystick
	 *  ball = number of the ball
	 *  xrel = relative x movement
	 *  yrel = relative y movement
	 */
	void OnJoyBall(ubyte device, ubyte ball, short xrel, short yrel);
	
	/**
	 * called on joystick hat (POV) movement
	 * Params:
	 *  device = number of the joystick
	 *  hat = number of the hat (POV)
	 *  value = value
	 */
	void OnJoyHat(ubyte device, ubyte hat, ubyte value);

  /**
   * getter for the thread safe ring buffer for communication between threads
   */
  @property ThreadSafeRingBuffer!() ringBuffer();

  ///ditto
  @property shared(ThreadSafeRingBuffer!()) ringBuffer() shared;
	
	final void OnMouseButton(ubyte device, ubyte button, bool pressed, ushort x, ushort y) shared {
		//send(getTid(),MsgOnMouseButton(device,button,pressed,x,y));
    this.ringBuffer.enqueue(MsgOnMouseButton(device, button, pressed, x, y));
	}
	
	final void OnMouseMove(ubyte device, ushort x, ushort y, short xrel, short yrel) shared {
		//send(getTid(),MsgOnMouseMove(device,x,y,xrel,yrel));
    this.ringBuffer.enqueue(MsgOnMouseMove(device, x, y, xrel, yrel));
	}
	
	final void OnKeyboard(ubyte device, bool pressed, uint key, ushort unicode, ubyte scancode, uint mod) shared {
		//send(getTid(),MsgOnKeyboard(device,pressed,key,unicode,scancode,mod));
    this.ringBuffer.enqueue(MsgOnKeyboard(device, pressed, key, unicode, scancode, mod));
	}
	
	final void OnJoyAxis(ubyte device, ubyte axis, short value) shared {
		//send(getTid(),MsgOnJoyAxis(device,axis,value));
    this.ringBuffer.enqueue(MsgOnJoyAxis(device, axis, value));
	}
	
	final void OnJoyButton(ubyte device, ubyte button, bool pressed) shared {
		//send(getTid(),MsgOnJoyButton(device,button,pressed));
    this.ringBuffer.enqueue(MsgOnJoyButton(device, button, pressed));
	}

	final void OnJoyBall(ubyte device, ubyte ball, short xrel, short yrel) shared {
		//send(getTid(),MsgOnJoyBall(device,ball,xrel,yrel));
    this.ringBuffer.enqueue(MsgOnJoyBall(device, ball, xrel, yrel));
	}
	
	final void OnJoyHat(ubyte device, ubyte hat, ubyte value) shared {
		//send(getTid(),MsgOnJoyHat(device,hat,value));
    this.ringBuffer.enqueue(MsgOnJoyHat(device, hat, value));
	}
		
	final void ProgressMessages(){
    InputMessage* im = null;
    while((im = this.ringBuffer.tryGet!InputMessage()) !is null)
    {
      final switch(im.event)
      {
         case InputEvent.MouseButton:
           {
             auto msg = cast(MsgOnMouseButton*)im;
             this.OnMouseButton(msg.device,msg.button,msg.pressed,msg.x,msg.y);
             this.ringBuffer.skip!MsgOnMouseButton();
           }
           break;
         case InputEvent.MouseMove:
           {
             auto msg = cast(MsgOnMouseMove*)im;
             this.OnMouseMove(msg.device,msg.x,msg.y,msg.xrel,msg.yrel);
             this.ringBuffer.skip!MsgOnMouseMove();
           }
           break;
         case InputEvent.Keyboard:
           {
             auto msg = cast(MsgOnKeyboard*)im;
             this.OnKeyboard(msg.device,msg.pressed,msg.key,msg.unicode,msg.scancode,msg.mod);
             this.ringBuffer.skip!MsgOnKeyboard();
           }
           break;
         case InputEvent.JoyAxis:
           {
             auto msg = cast(MsgOnJoyAxis*)im;
             this.OnJoyAxis(msg.device,msg.axis,msg.value);
             this.ringBuffer.skip!MsgOnJoyAxis();
           }
           break;
         case InputEvent.JoyButton:
           {
             auto msg = cast(MsgOnJoyButton*)im;
             this.OnJoyButton(msg.device,msg.button,msg.pressed);
             this.ringBuffer.skip!MsgOnJoyButton();
           }
           break;
         case InputEvent.JoyHat:
           {
             auto msg = cast(MsgOnJoyHat*)im;
             this.OnJoyHat(msg.device,msg.hat,msg.value);
             this.ringBuffer.skip!MsgOnJoyHat();
           }
           break;
         case InputEvent.JoyBall:
           {
             auto msg = cast(MsgOnJoyBall*)im;
             this.OnJoyBall(msg.device,msg.ball,msg.xrel,msg.yrel);
             this.ringBuffer.skip!MsgOnJoyBall();
           }
           break;
      }
    }
	}
};

/**
 * dummy implementation of IInputListener, does nothing
 * should be used when you only want to implement some of the event functions, but not all of them
 */
abstract class InputListenerAdapter : IInputListener {
	void OnMouseButton(ubyte device, ubyte button, bool pressed, ushort x, ushort y){}
	void OnMouseMove(ubyte device, ushort x, ushort y, short xrel, short yrel){}
	void OnKeyboard(ubyte device, bool pressed, uint key, ushort unicode, ubyte scancode, uint mod){}
	void OnJoyAxis(ubyte device, ubyte axis, short value){}
	void OnJoyButton(ubyte device, ubyte button, bool pressed){}
	void OnJoyBall(ubyte device, ubyte ball, short xrel, short yrel){}
	void OnJoyHat(ubyte device, ubyte hat, ubyte value){}
};

enum InputEvent : uint
{
  MouseButton,
  MouseMove,
  Keyboard,
  JoyAxis,
  JoyButton,
  JoyBall,
  JoyHat
}

struct InputMessage
{
  InputEvent event;
}

struct MsgOnMouseButton {
  InputMessage im;
	ubyte device;
	ubyte button;
	bool pressed;
	ushort x;
	ushort y;
	this(ubyte device, ubyte button, bool pressed, ushort x, ushort y){
    im.event = InputEvent.MouseButton;
		this.device = device;
		this.button = button;
		this.pressed = pressed;
		this.x = x;
		this.y = y;
	}
}

struct MsgOnMouseMove {
  InputMessage im;
	ubyte device;
	ushort x;
	ushort y;
	short xrel;
	short yrel;
	this(ubyte device, ushort x, ushort y, short xrel, short yrel){
    im.event = InputEvent.MouseMove;
		this.device = device;
		this.x = x;
		this.y = y;
		this.xrel = xrel;
		this.yrel = yrel;
	}
}

struct MsgOnKeyboard {
  InputMessage im;
	ubyte device;
	bool pressed;
	uint key;
	ushort unicode;
	ubyte scancode;
	uint mod;
	this(ubyte device, bool pressed, uint key, ushort unicode, ubyte scancode, uint mod){
    im.event = InputEvent.Keyboard;
		this.device = device;
		this.pressed = pressed;
		this.key = key;
		this.unicode = unicode;
		this.scancode = scancode;
		this.mod = mod;
	}
}

struct MsgOnJoyAxis {
  InputMessage im;
	ubyte device;
	ubyte axis;
	short value;
	this(ubyte device, ubyte axis, short value){
    im.event = InputEvent.JoyAxis;
		this.device = device;
		this.axis = axis;
		this.value = value;
	}
}

struct MsgOnJoyButton {
  InputMessage im;
	ubyte device;
	ubyte button;
	bool pressed;
	this(ubyte device, ubyte button, bool pressed){
    im.event = InputEvent.JoyButton;
		this.device = device;
		this.button = button;
		this.pressed = pressed;
	}
}

struct MsgOnJoyBall {
  InputMessage im;
	ubyte device;
	ubyte ball;
	short xrel;
	short yrel;
	this(ubyte device, ubyte ball, short xrel, short yrel){
    im.event = InputEvent.JoyBall;
		this.device = device;
		this.ball = ball;
		this.xrel = xrel;
		this.yrel = yrel;
	}
}

struct MsgOnJoyHat {
  InputMessage im;
	ubyte device;
	ubyte hat;
	ubyte value;
	this(ubyte device, ubyte hat, ubyte value){
    im.event = InputEvent.JoyHat;
		this.device = device;
		this.hat = hat;
		this.value = value;
	}
}
