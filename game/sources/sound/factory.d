module sound.factory;

public import base.sound;
import sound.system;
import sound.openal;
import sound.vorbisfile;
import base.utilsD2;
import thBase.string;
import thBase.logging;

class SoundSystemFactory : ISoundSystemFactory {
	SoundSystem m_SoundSystem = null;
	bool m_IsInit = false;
  al.ALCdevice* m_device;
  al.ALCcontext* m_context;
	public:
		this(){
			al.LoadDll("OpenAL32.dll","./libopenal.so.1");
			ov.LoadDll("libvorbisfile.dll","./libvorbisfile.so.3");
			
			
      m_device = al.cOpenDevice(null);
      if (m_device == null) 
        throw New!RCException(_T("Could not open default OpenAL device"));

      m_context = al.cCreateContext(m_device, null);
      if (m_context == null) 
        throw New!RCException(_T("Could not create OpenAL context"));

      if (al.cMakeContextCurrent(m_context) == false) 
        throw New!RCException(_T("Could not activate OpenAL context"));
			
			m_IsInit = true;
			logInfo("OpenAL init done");
		}
	
		~this(){
      Delete(m_SoundSystem);
			if(m_IsInit){
        al.cDestroyContext(m_context);
        al.cCloseDevice(m_device);  
			}
		}
	
		ISoundSystem GetSoundSystem(){
			if(m_SoundSystem is null)
				m_SoundSystem = new SoundSystem();
			return m_SoundSystem;
		}
}

class SoundSystemFactoryDummy: ISoundSystemFactory
{
	SoundSystemDummy m_SoundSystem = null;
	bool m_IsInit = false;
public:
  this(){
    m_IsInit = true;
    logInfo("dummy sound init");
  }

  ~this()
  {
    Delete(m_SoundSystem);
  }

  ISoundSystem GetSoundSystem(){
    if(m_SoundSystem is null)
      m_SoundSystem = New!SoundSystemDummy();
    return m_SoundSystem;
  }
}

ISoundSystemFactory NewSoundSystemFactory(SoundSystemType type){
  final switch(type)
  {
    case SoundSystemType.OpenAL:
      return New!SoundSystemFactory();
    case SoundSystemType.None:
      return New!SoundSystemFactoryDummy();
  }
}

void DeleteSoundSystemFactory(ISoundSystemFactory factory)
{
  Delete(factory);
}
