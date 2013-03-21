module sound.openal;

import base.sharedlib;
import base.utilsD2;

private string dll_declare(string name){
	return "__gshared " ~ name ~ " " ~ name[2..name.length] ~ ";";
}

private string dll_init(string name){
	string sname = name[2..name.length];
	return sname ~ ` = cast( typeof ( ` ~ sname ~ `) ) GetProc("` ~ name ~ `"); assert(` ~ sname ~ ` !is null, "` ~ name ~ ` could not be loaded from openal");`;
}

class al {
	mixin SharedLib!();
	
	alias byte ALbyte;
	alias ubyte ALubyte;
	alias int ALenum;
	alias float ALfloat;
	alias uint ALuint;
	alias bool ALboolean;
	alias double ALdouble;
	alias int ALint;
	alias int ALsizei;
	alias char ALchar;
	alias void ALvoid;

  alias void ALCdevice;
  alias void ALCcontext;
	
	enum : ALenum {
		INVALID = -1,
		NONE = 0,
		FALSE = 0,
		TRUE = 1,
		SOURCE_RELATIVE = 0x202,
		CONE_INNER_ANGLE = 0x1001,
		CONE_OUTER_ANGLE = 0x1002,
		PITCH = 0x1003,
		POSITION = 0x1004,
		DIRECTION = 0x1005,		  
		VELOCITY = 0x1006,
		LOOPING = 0x1007,
		BUFFER = 0x1009,		  
		GAIN = 0x100A,
		MIN_GAIN = 0x100D,
		MAX_GAIN = 0x100E,
		ORIENTATION = 0x100F,
		CHANNEL_MASK = 0x3000,
		SOURCE_STATE = 0x1010,
		INITIAL = 0x1011,
		PLAYING = 0x1012,
		PAUSED = 0x1013,
		STOPPED = 0x1014,
		BUFFERS_QUEUED = 0x1015,
		BUFFERS_PROCESSED = 0x1016,
		SEC_OFFSET = 0x1024,
		SAMPLE_OFFSET = 0x1025,
		BYTE_OFFSET = 0x1026,
		SOURCE_TYPE = 0x1027,
		STATIC = 0x1028,
		STREAMING = 0x1029,
		UNDETERMINED = 0x1030,
		FORMAT_MONO8 = 0x1100,
		FORMAT_MONO16 = 0x1101,
		FORMAT_STEREO8 = 0x1102,
		FORMAT_STEREO16 = 0x1103,
		REFERENCE_DISTANCE = 0x1020,
		ROLLOFF_FACTOR = 0x1021,
		CONE_OUTER_GAIN = 0x1022,
		MAX_DISTANCE = 0x1023,
		FREQUENCY = 0x2001,
		BITS = 0x2002,
		CHANNELS = 0x2003,
		SIZE = 0x2004,
		UNUSED = 0x2010,
		PENDING = 0x2011,
		PROCESSED = 0x2012,
		NO_ERROR = FALSE,
		INVALID_NAME = 0xA001,
		ILLEGAL_ENUM = 0xA002,
		INVALID_ENUM = 0xA002,
		INVALID_VALUE = 0xA003,
		ILLEGAL_COMMAND = 0xA004,
		INVALID_OPERATION = 0xA004,		  
		OUT_OF_MEMORY = 0xA005,
		VENDOR = 0xB001,
		VERSION = 0xB002,
		RENDERER = 0xB003,
		EXTENSIONS = 0xB004,
		DOPPLER_FACTOR = 0xC000,
		DOPPLER_VELOCITY = 0xC001,
		SPEED_OF_SOUND = 0xC003,
		DISTANCE_MODEL = 0xD000,
		INVERSE_DISTANCE = 0xD001,
		INVERSE_DISTANCE_CLAMPED = 0xD002,
		LINEAR_DISTANCE = 0xD003,
		LINEAR_DISTANCE_CLAMPED = 0xD004,
		EXPONENT_DISTANCE = 0xD005,
		EXPONENT_DISTANCE_CLAMPED = 0xD006
	}
	
	extern(C){
		alias void function( ALenum capability ) alEnable;
		alias void function( ALenum capability ) alDisable; 
		alias ALboolean function( ALenum capability ) alIsEnabled; 
		alias const(ALchar)* function( ALenum param ) alGetString;
		alias void function( ALenum param, ALboolean* data ) alGetBooleanv;
		alias void function( ALenum param, ALint* data ) alGetIntegerv;
		alias void function( ALenum param, ALfloat* data ) alGetFloatv;
		alias void function( ALenum param, ALdouble* data ) alGetDoublev;
		alias ALboolean function( ALenum param ) alGetBoolean;
		alias ALint function( ALenum param ) alGetInteger;
		alias ALfloat function( ALenum param ) alGetFloat;
		alias ALdouble function( ALenum param ) alGetDouble;
		alias ALenum function() alGetError;
		alias ALboolean function( const(ALchar)* extname ) alIsExtensionPresent;
		alias void* function( const(ALchar)* fname ) alGetProcAddress;
		alias ALenum function( const(ALchar)* ename ) alGetEnumValue;
		alias void function( ALenum param, ALfloat value ) alListenerf;
		alias void function( ALenum param, ALfloat value1, ALfloat value2, ALfloat value3 ) alListener3f;
		alias void function( ALenum param, const(ALfloat)* values ) alListenerfv; 
		alias void function( ALenum param, ALint value ) alListeneri;
		alias void function( ALenum param, ALint value1, ALint value2, ALint value3 ) alListener3i;
		alias void function( ALenum param, const(ALint)* values ) alListeneriv;
		alias void function( ALenum param, ALfloat* value ) alGetListenerf;
		alias void function( ALenum param, ALfloat *value1, ALfloat *value2, ALfloat *value3 ) alGetListener3f;
		alias void function( ALenum param, ALfloat* values ) alGetListenerfv;
		alias void function( ALenum param, ALint* value ) alGetListeneri;
		alias void function( ALenum param, ALint *value1, ALint *value2, ALint *value3 ) alGetListener3i;
		alias void function( ALenum param, ALint* values ) alGetListeneriv;
		alias void function( ALsizei n, ALuint* sources ) alGenSources; 
		alias void function( ALsizei n, const(ALuint)* sources ) alDeleteSources;
		alias ALboolean function( ALuint sid ) alIsSource; 
		alias void function( ALuint sid, ALenum param, ALfloat value ) alSourcef; 
		alias void function( ALuint sid, ALenum param, ALfloat value1, ALfloat value2, ALfloat value3 ) alSource3f;
		alias void function( ALuint sid, ALenum param, const(ALfloat)* values ) alSourcefv; 
		alias void function( ALuint sid, ALenum param, ALint value ) alSourcei; 
		alias void function( ALuint sid, ALenum param, ALint value1, ALint value2, ALint value3 ) alSource3i;
		alias void function( ALuint sid, ALenum param, const(ALint)* values ) alSourceiv;
		alias void function( ALuint sid, ALenum param, ALfloat* value ) alGetSourcef;
		alias void function( ALuint sid, ALenum param, ALfloat* value1, ALfloat* value2, ALfloat* value3) alGetSource3f;
		alias void function( ALuint sid, ALenum param, ALfloat* values ) alGetSourcefv;
		alias void function( ALuint sid,  ALenum param, ALint* value ) alGetSourcei;
		alias void function( ALuint sid, ALenum param, ALint* value1, ALint* value2, ALint* value3) alGetSource3i;
		alias void function( ALuint sid,  ALenum param, ALint* values ) alGetSourceiv;
		alias void function( ALsizei ns, const(ALuint)* sids ) alSourcePlayv;
		alias void function( ALsizei ns, const(ALuint)* sids ) alSourceStopv;
		alias void function( ALsizei ns, const(ALuint)* sids ) alSourceRewindv;
		alias void function( ALsizei ns, const(ALuint)* sids ) alSourcePausev;
		alias void function( ALuint sid ) alSourcePlay;
		alias void function( ALuint sid ) alSourceStop;
		alias void function( ALuint sid ) alSourceRewind;
		alias void function( ALuint sid ) alSourcePause;
		alias void function( ALuint sid, ALsizei numEntries, const(ALuint)* bids ) alSourceQueueBuffers;
		alias void function( ALuint sid, ALsizei numEntries, ALuint *bids ) alSourceUnqueueBuffers;
		alias void function( ALsizei n, ALuint* buffers ) alGenBuffers;
		alias void function( ALsizei n, const(ALuint)* buffers ) alDeleteBuffers;
		alias ALboolean function( ALuint bid ) alIsBuffer;
		alias void function( ALuint bid, ALenum format, const(ALvoid)* data, ALsizei size, ALsizei freq ) alBufferData;
		alias void function( ALuint bid, ALenum param, ALfloat value ) alBufferf;
		alias void function( ALuint bid, ALenum param, ALfloat value1, ALfloat value2, ALfloat value3 ) alBuffer3f;
		alias void function( ALuint bid, ALenum param, const(ALfloat)* values ) alBufferfv;
		alias void function( ALuint bid, ALenum param, ALint value ) alBufferi;
		alias void function( ALuint bid, ALenum param, ALint value1, ALint value2, ALint value3 ) alBuffer3i;
		alias void function( ALuint bid, ALenum param, const(ALint)* values ) alBufferiv;
		alias void function( ALuint bid, ALenum param, ALfloat* value ) alGetBufferf;
		alias void function( ALuint bid, ALenum param, ALfloat* value1, ALfloat* value2, ALfloat* value3) alGetBuffer3f;
		alias void function( ALuint bid, ALenum param, ALfloat* values ) alGetBufferfv;
		alias void function( ALuint bid, ALenum param, ALint* value ) alGetBufferi;
		alias void function( ALuint bid, ALenum param, ALint* value1, ALint* value2, ALint* value3) alGetBuffer3i;
		alias void function( ALuint bid, ALenum param, ALint* values ) alGetBufferiv;
		alias void function( ALfloat value ) alDopplerFactor;
		alias void function( ALfloat value ) alDopplerVelocity;
		alias void function( ALfloat value ) alSpeedOfSound;
		alias void function( ALenum distanceModel ) alDistanceModel;

    //alc functions
    alias ALCdevice* function( const char *devicename ) alcOpenDevice;
    alias ALboolean function( ALCdevice *device ) alcCloseDevice;
    alias ALCcontext* function ( ALCdevice *device, const ALint* attrlist ) alcCreateContext;
    alias ALboolean function( ALCcontext *context ) alcMakeContextCurrent;
    alias ALCcontext* function() alcGetCurrentContext;
    alias void function( ALCcontext *context ) alcDestroyContext;
	}
	
	static string errorToString(ALenum error){
		switch(error){
			case NO_ERROR:
				return "no error";
			case INVALID_NAME:
				return "invalid name";
			case ILLEGAL_ENUM:
				return "illegal enum or invalid enum";
			case INVALID_VALUE:
				return "invalid value";
			case ILLEGAL_COMMAND:
				return "illegal command or invalid operation";
			case OUT_OF_MEMORY:
				return "out of memory";
			default:
				return "invalid error code";
		}
		assert(0,"not reachable");
	}
	
	//This compile time function generates the function pointer variables	
	mixin( generateDllCode!(al)(&dll_declare) );
	
	static void LoadDll(string windowsName, string linuxName){
		LoadImpl(windowsName,linuxName);
		//This compile time function generates the calls to load the functions from the dll
		mixin ( generateDllCode!(al)(&dll_init) );
	}
}
