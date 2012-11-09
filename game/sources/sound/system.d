module sound.system;

import base.sound;
import thBase.container.vector;
import sound.source;



class SoundSystem : ISoundSystem {
private:
	Vector!(SourceOggStream) m_StreamingSounds;
public:
	
	this(){
		m_StreamingSounds = New!(Vector!(SourceOggStream))();
	}

  ~this()
  {
    foreach(stream; m_StreamingSounds[])
    {
      Delete(stream);
    }
    Delete(m_StreamingSounds);
  }

	override ISoundSource LoadOggSound(rcstring filename, bool stream = false){
		if(stream){
			SourceOggStream temp = New!SourceOggStream();
			m_StreamingSounds ~= temp;
			temp.LoadFile(filename[]);
			temp.Update();
			return temp;
		}
		else {
			SourceOgg temp = New!SourceOgg();
			temp.LoadFile(filename[]);
			return temp;
		}
		assert(0,"not reachable");
	}
	
	override void RemoveStream(ISoundSource stream){
		SourceOggStream src = cast(SourceOggStream)stream;
    assert(src !is null, "passed a non streaming sound to RemoveStream");
		m_StreamingSounds.remove(src);
	}
	
	override void Update(){
		foreach(sound;m_StreamingSounds[]){
			if(sound.isStreaming){
				//writefln("updating streaming sound");
				sound.Update();
			}
		}
	}
}

class SoundSystemDummy : ISoundSystem {

  public:
    override ISoundSource LoadOggSound(rcstring filename, bool stream = false)
    {
      return New!SoundSourceDummy();
    }

    override void RemoveStream(ISoundSource stream){}
    override void Update(){}
}