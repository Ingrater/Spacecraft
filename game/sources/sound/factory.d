module sound.factory;

public import base.sound;
import sound.system;
import sound.openal;
import sound.vorbisfile;
import sound.alut;
import base.utilsD2;
import thBase.string;
import thBase.logging;

class SoundSystemFactory : ISoundSystemFactory {
	SoundSystem m_SoundSystem = null;
	bool m_IsInit = false;
	public:
		this(){
			al.LoadDll("OpenAL32.dll","./libopenal.so.1");
			ov.LoadDll("libvorbisfile.dll","./libvorbisfile.so.3");
			alut.LoadDll("alut.dll","./libalut.so.0");
			
			
			if(!alut.Init(null,null)){
				auto error = fromCString(alut.GetErrorString(alut.GetError()));
				logError(error[]);
				throw New!RCException(error);
			}
			m_IsInit = true;
			logInfo("alut init");
		}
	
		~this(){
      Delete(m_SoundSystem);
			if(m_IsInit){
				//logInfo("alut deinit");
				alut.Exit();
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
