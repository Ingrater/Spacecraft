module sound.factory;

public import base.sound;
import sound.system;
import sound.openal;
import sound.vorbisfile;
import sound.alut;
import base.utilsD2;
import thBase.string;

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
				base.logger.error(error[]);
				throw New!RCException(error);
			}
			m_IsInit = true;
			base.logger.info("alut init");
		}
	
		~this(){
      Delete(m_SoundSystem);
			if(m_IsInit){
				//base.logger.info("alut deinit");
				alut.Exit();
			}
		}
	
		ISoundSystem GetSoundSystem(){
			if(m_SoundSystem is null)
				m_SoundSystem = new SoundSystem();
			return m_SoundSystem;
		}
}

ISoundSystemFactory NewSoundSystemFactory(){
	return New!SoundSystemFactory();
}

void DeleteSoundSystemFactory(ISoundSystemFactory factory)
{
  Delete(factory);
}
