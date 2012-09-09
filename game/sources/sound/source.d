module sound.source;



import sound.openal;
import sound.vorbisfile;
import sound.alut;
import thBase.container.vector;
import thBase.math3d.vecs;
import thBase.file;
import base.utilsD2;
import base.sound;
import thBase.string;
import thBase.format;

/** \brief Is a virtual class representing a SoundSource
*  \details Is created and connected with an int Id by the IdManager
*  \n on creating the Source gets the same Position as the Listener Object
*  \n and the Volume is set to 1.
*/
abstract class Source : ISoundSource {
     public:
     /** \brief Defines the Type of the SoundSource
      *
      */
      enum SourceType {
        NORMAL,/**< NO Stream*/
        STREAM /**< IS Stream*/
      }

    protected:
      al.ALint m_aluiState;
      al.ALuint m_aluiBuffer;
      al.ALuint m_aluiSource;
      al.ALenum m_format;
      al.ALsizei m_freq;
      bool m_bDataLoaded = false;
      SourceType m_Type;
	  
	public:		
		SourceType GetType() const {return m_Type;};
		/** \brief virtual method to Load a File to the Source
		 *  \return true if loading was succesfull
		*/
		abstract bool LoadFile(string pFilename);
		/** \brief Set the Pitch of a Sound Source
		*  \details
		*  \param pValue Value the Pitch is set to
		*/
		override void SetPitch(float pValue){
			if(!m_bDataLoaded)
				return;
			al.Sourcef(m_aluiSource,al.PITCH,pValue);
		}
		/** \brief Set the Position of Sound Source
		*  \details Sets the Position of the Source in the World
		*  \param pX X-Value of the Position to set to
		*  \param pY Y-Value of the Position to set to
		*  \param pZ Z-Value of the Position to set to
		*/
		override void SetPosition(float pX, float pY, float pZ){
			if(!m_bDataLoaded)
				return;
			al.Source3f(m_aluiSource,al.POSITION,pX,pY,pZ);
		}
		/** \brief Set the Position of Sound Source
		*  \details Sets the Position of the Source in the World
		*  \param pArray An Array containing three floats
		*  \n first for x, second for y and third for z Value of Position
		*/
		override void SetPosition(float[] pArray)
		in {
			assert(pArray.length == 3);
		}
		body {
			if(!m_bDataLoaded)
				return;
			al.Source3f(m_aluiSource,al.POSITION,pArray[0],pArray[1],pArray[2]);
		}
		/** \brief Set the Position of Sound Source
		*  \details Sets the Position of the Source in the World
		*  \param pPosition a vec4 (4 float values only three are used)
		*/
		override void SetPosition(vec4 pPosition){
			if(!m_bDataLoaded)
				return;
			al.Source3f(m_aluiSource,al.POSITION,pPosition.x,pPosition.y,pPosition.z);
		}
		/** \brief Set the Velocitiy of the Sound Source
		*  \details Sets the Velocity Vector to the given Values
		*  \param pX X-Value of the Velocity to set to
		*  \param pY Y-Value of the Velocity to set to
		*  \param pZ Z-Value of the Velocity to set to
		*/
		override void SetVelocity(float pX, float pY, float pZ){
			if(m_bDataLoaded)
				return;
			al.Source3f(m_aluiSource,al.VELOCITY,pX,pY,pZ);
		}
		/** \brief Set the Velocitiy of the Sound Source
		*  \details Sets the Velocity Vector to the given Values
		*  \param pArray An Array containing three floats
		*  \n first for x, second for y and third for z Value of Position
		*/
		override void SetVelocity(float[] pArray)
		in {
			assert(pArray.length == 3);
		}
		body {
			if(!m_bDataLoaded)
				return;
			al.Source3f(m_aluiSource,al.VELOCITY,pArray[0],pArray[1],pArray[2]);
		}
		/** \brief Set the Velocitiy of the Sound Source
		*  \details Sets the Velocity Vector to the given Values
		*  \param pVelocity a vec3 (3 float values);
		*/
		override void SetVelocity(vec3 pVelocity){
			if(!m_bDataLoaded)
				return;
			al.Source3f(m_aluiSource,al.VELOCITY,pVelocity.x,pVelocity.y,pVelocity.z);
		}
		/** \brief Set the Direction of the Sound Source
		*  \details Sets the Direction Vector to the given Values
		*  \param pArray An Array containing three floats
		*  \n first for x, second for y and third for z Value of Position
		*/
		override void SetDirection(float* pArray){
			if(!m_bDataLoaded)
				return;
			al.Source3f(m_aluiSource,al.DIRECTION,pArray[0],pArray[1],pArray[2]);
		}
		/** \brief Set the Direction of the Sound Source
		*  \details Sets the Direction Vector to the given Values
		*  \param pDirection a vec3 (3 float values);
		*/
		override void SetDirection(vec3 pDirection){
			if(!m_bDataLoaded)
				return;
			al.Source3f(m_aluiSource,al.DIRECTION,pDirection.x,pDirection.y,pDirection.z);
		}
		/** \brief Set the Rolloff of the Sound Source
		*  \details Sets the Rolloff
		*  \param pValue float Value the Rolloff is set to
		*/
		override void SetRolloff(float pValue){
			if(!m_bDataLoaded)
				return;
			al.Sourcef(m_aluiSource,al.ROLLOFF_FACTOR,pValue);
		}
		/** \brief Set if Relatve or not
		*  \details Set to wether the Postions are relative or
		*  \n absolute to each other to calculate
		*  \param pValue the bool flag:
		*  \n true = Relative;
		*  \n false = Absolute;
		*/
		override void SetRelative(bool pValue){
			if(!m_bDataLoaded)
				return;
			al.Sourcei(m_aluiSource,al.SOURCE_RELATIVE,pValue);
		}
		/** \brief Sets the Repeat
		*  \details Sets to wether the Sources are Replaying after
		*  \n finishing playing the bufferor stopped after that
		*  \param pValue the bool flag:
		*  \n true = Replay;
		*  \n false = Stopp;
		*/
		override void SetRepeat(bool pValue){
			if(!m_bDataLoaded)
				return;
			al.Sourcei(m_aluiSource,al.LOOPING,pValue);
		}
		/** \brief Sets the Volume of the Sound Source
		*  \details Sets the maximum Volume the Source is playing with
		*  \param pValue the value the Volume is set to
		*/
		override void SetVolume(float pValue){
			if(!m_bDataLoaded)
				return;
			al.Sourcef(m_aluiSource,al.GAIN,pValue);
		}
		/** \brief Plays the Sound Source
		*/
		override void Play(){
		  if(!m_bDataLoaded)
			return;
		  if(!IsPlaying()){
			al.SourcePlay(m_aluiSource);
		  }
		}
		/** \brief Stops the playing of the Sound Source and sets it to the beginning
		*/
		override void Stop(){
		  if(!m_bDataLoaded)
			return;
		  if(IsPlaying())
			al.SourceStop(m_aluiSource);
		}
		/** \brief Pauses the playing of the Sound Source;
		*/
		override void Pause(){  
			if(!m_bDataLoaded)
				return;
			if(IsPlaying())
				al.SourcePause(m_aluiSource);
		}
		/** \brief Rewind the playing of the Sound Source;
		*/
		override void Rewind(){
		  if(!m_bDataLoaded)
			return;
		  al.ALenum state;
		  al.GetSourcei(m_aluiSource,al.SOURCE_STATE,&state);
		  if(state != al.INITIAL)
			al.SourceRewind(m_aluiSource);
		}
		/** \brief Tests if the Sound Source is playing
		*  \return true for playing and false for not
		*/
		override bool IsPlaying(){
		  if(!m_bDataLoaded)
			return false;
		  al.ALenum state;
		  al.GetSourcei(m_aluiSource,al.SOURCE_STATE,&state);
		  return (state == al.PLAYING);
		}
		
		/*debug {
			invariant(){
				al.ALenum error = al.GetError();
				assert(error == al.NONE,al.errorToString(error));
			}
		}*/
}

/** \brief is a child of sound::Source
*  \details represents a Source object Playing small .ogg vorbis Files
*/
class SourceOgg : Source {
private:
  composite!(Vector!(byte)) m_DataBuffer;

public:
	this(){
		m_DataBuffer = typeof(m_DataBuffer)(DefaultCtor());
    m_DataBuffer.construct();
		m_Type = SourceType.NORMAL;
	}

	~this(){  
		if(!m_bDataLoaded)
			return;
		al.DeleteBuffers(1,&m_aluiBuffer);
		al.DeleteSources(1,&m_aluiSource);
	}

	/** \brief method to Load a Ogg File
	*  \details Loads the Ogg File in a buffer and adds it
	*  \n to the Queue of the Sound Source
	*  \return true if loading was succesfull
	*/
	override bool LoadFile(string pFilename){
	  enum size_t BUFFER_SIZE = 131072;
	  int endian = 0;             // 0 for Little-Endian, 1 for Big-Endian
	  int bitStream;
	  int bytes;
	  byte buffer[BUFFER_SIZE];    // Local fixed size pArray

	  if(m_bDataLoaded)
		return false;

	  ov.vorbis_info *pInfo;
	  ov.OggVorbis_File oggFile;

	  if(ov.fopen(toCString(pFilename), &oggFile) < 0){
		return false;
	  }
	  // Get some information about the OGG file
	  pInfo = ov.info(&oggFile, -1);

	  // Check the number of channels... always use 16-bit samples
	  if (pInfo.channels == 1)
		m_format = al.FORMAT_MONO16;
	  else
		m_format = al.FORMAT_STEREO16;
	  // end if

	  // The frequency of the sampling rate
	  m_freq = pInfo.rate;

	  do {
		// Read up to a buffer's worth of decoded sound data
		bytes = ov.read(&oggFile, buffer.ptr, BUFFER_SIZE, endian, 2, 1, &bitStream);
		// Append to end of buffer
		if(bytes > 0)
			m_DataBuffer ~= buffer[0..bytes];
	  } while (bytes > 0);

	  ov.clear(&oggFile);

	  al.GenBuffers(1,&m_aluiBuffer);
	  al.GenSources(1,&m_aluiSource);
	  al.BufferData(m_aluiBuffer,m_format,&m_DataBuffer[0],m_DataBuffer.size(),m_freq);
	  al.Sourcei(m_aluiSource, al.BUFFER, m_aluiBuffer);

	  m_bDataLoaded = true;
	  return true;
	}
}

class SourceOggStream : Source {
private:
	al.ALuint m_aluiBuffer2;
	ov.OggVorbis_File m_oggFile;
	
	int Stream(al.ALuint Buffer){
		enum size_t BUFFER_SIZE = 131072;
		byte data[BUFFER_SIZE];
		int  size = 0;
		int  section;
		int  result;

		while(size < BUFFER_SIZE)
		{
			result = ov.read(&m_oggFile, data.ptr + size, BUFFER_SIZE - size, 0, 2, 1, &section);

			if(result > 0)
			  size += result;
			else if(result < 0)
			  return -1;
			else
			  break;
		}

		if(size != 0){
		  al.BufferData(Buffer, m_format, data.ptr, size, m_freq);
		}

		return size;		
	}

public:
	this(){
		 m_Type = SourceType.STREAM;
	}
	~this(){
		Close();
	}
	/** \brief method to Load a Ogg File
	*  \details Loads the a part in a buffer and adds it
	*  \n to the Queue of the Sound Source
	*  \return true if loading was succesfull
	*/
	override bool LoadFile(string pFilename){
		int bytes;

		if(m_bDataLoaded)
			return false;

		ov.vorbis_info *pInfo;
		ov.OggVorbis_File oggFile;

		if(ov.fopen(toCString(pFilename),&m_oggFile) < 0){
			throw New!RCException(format("Error opening '%s' as ogg file", pFilename));
		}
		// Get some information about the OGG file
		pInfo = ov.info(&m_oggFile, -1);

		// Check the number of channels... always use 16-bit samples
		if (pInfo.channels == 1)
			m_format = al.FORMAT_MONO16;
		else
			m_format = al.FORMAT_STEREO16;

		// The frequency of the sampling rate
		m_freq = pInfo.rate;
		
		al.GenSources(1,&m_aluiSource);

		al.GenBuffers(1,&m_aluiBuffer);
		bytes = Stream(m_aluiBuffer);
		if( bytes <= 0 ){
			al.DeleteSources(1,&m_aluiSource);
			al.DeleteBuffers(1,&m_aluiBuffer);
			ov.clear(&m_oggFile);
			return false;
		}
		al.SourceQueueBuffers(m_aluiSource,1,&m_aluiBuffer);

		al.GenBuffers(1,&m_aluiBuffer2);
		bytes = Stream(m_aluiBuffer2);
		if( bytes <= 0){
			al.SourceUnqueueBuffers(m_aluiSource,1,&m_aluiBuffer);
			al.DeleteBuffers(1,&m_aluiBuffer);
			al.DeleteBuffers(1,&m_aluiBuffer2);
			al.DeleteSources(1,&m_aluiSource);
			ov.clear(&m_oggFile);
			return false;
		}
		else if(bytes > 0){
			al.SourceQueueBuffers(m_aluiSource,1,&m_aluiBuffer2);
		}

		m_bDataLoaded = true;
		return true;
	}
	/** \brief method to Close the Stream;
	*  \details Closes the Stream and laeves the Buffer empty
	*/
	void Close(){
	  int queued=0;
	  al.ALuint Buffer;

	  Stop();

	  al.GetSourcei(m_aluiSource,al.BUFFERS_QUEUED,&queued);
	  while(queued--)
		al.SourceUnqueueBuffers(m_aluiSource,1,&Buffer);

	  if(m_bDataLoaded){
		al.DeleteBuffers(1,&m_aluiBuffer);
		al.DeleteBuffers(1,&m_aluiBuffer2);
		al.DeleteSources(1,&m_aluiSource);

		ov.clear(&m_oggFile);
		m_bDataLoaded = false;
	  }
	}
	/** \brief method to update the stream
	*  \details Adds a further part of the File to a buffer
	*  \n and adds it to the Sound Source Queue
	*  \return true if updating was succesfull
	*/
	/** \brief Starts streaming from the begining */
	override void Rewind(){
	  if(!m_bDataLoaded)
		return;
	  ov.raw_seek(&m_oggFile,0);
	  Stream(m_aluiBuffer);
	  al.SourceQueueBuffers(m_aluiSource,1,&m_aluiBuffer);
	  Stream(m_aluiBuffer2);
	  al.SourceQueueBuffers(m_aluiSource,1,&m_aluiBuffer2);
	}
	
	/**
	 * streams new data to the sound card
	 */
	bool Update(){
	  int processed=0,bytes;
	  al.ALuint Buffer;
	  al.GetSourcei(m_aluiSource,al.BUFFERS_PROCESSED,&processed);
	  while(processed--){
		al.SourceUnqueueBuffers(m_aluiSource,1,&Buffer);

		bytes = Stream(Buffer);
		if( bytes < 0)
		   return false;
		else if( bytes == 0)
		  break;

		al.SourceQueueBuffers(m_aluiSource,1,&Buffer);
	  }

	  return true;
	}
};
