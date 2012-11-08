module base.sound;

public import thBase.math3d.vecs;

interface ISoundSource {
		/** \brief Set the Pitch of a Sound Source
		*  \details
		*  \param pValue Value the Pitch is set to
		*/
		void SetPitch(float pValue);
		/** \brief Set the Position of Sound Source
		*  \details Sets the Position of the Source in the World
		*  \param pX X-Value of the Position to set to
		*  \param pY Y-Value of the Position to set to
		*  \param pZ Z-Value of the Position to set to
		*/
		void SetPosition(float pX, float pY, float pZ);
		/** \brief Set the Position of Sound Source
		*  \details Sets the Position of the Source in the World
		*  \param pArray An Array containing three floats
		*  \n first for x, second for y and third for z Value of Position
		*/
		void SetPosition(float[] pArray);
		/** \brief Set the Position of Sound Source
		*  \details Sets the Position of the Source in the World
		*  \param pPosition a vec4 (4 float values only three are used)
		*/
		void SetPosition(vec4 pPosition);
		/** \brief Set the Velocitiy of the Sound Source
		*  \details Sets the Velocity Vector to the given Values
		*  \param pX X-Value of the Velocity to set to
		*  \param pY Y-Value of the Velocity to set to
		*  \param pZ Z-Value of the Velocity to set to
		*/
		void SetVelocity(float pX, float pY, float pZ);
		/** \brief Set the Velocitiy of the Sound Source
		*  \details Sets the Velocity Vector to the given Values
		*  \param pArray An Array containing three floats
		*  \n first for x, second for y and third for z Value of Position
		*/
		void SetVelocity(float[] pArray);
		/** \brief Set the Velocitiy of the Sound Source
		*  \details Sets the Velocity Vector to the given Values
		*  \param pVelocity a vec3 (3 float values);
		*/
		void SetVelocity(vec3 pVelocity);
		/** \brief Set the Direction of the Sound Source
		*  \details Sets the Direction Vector to the given Values
		*  \param pArray An Array containing three floats
		*  \n first for x, second for y and third for z Value of Position
		*/
		void SetDirection(float* pArray);
		/** \brief Set the Direction of the Sound Source
		*  \details Sets the Direction Vector to the given Values
		*  \param pDirection a vec3 (3 float values);
		*/
		void SetDirection(vec3 pDirection);
		/** \brief Set the Rolloff of the Sound Source
		*  \details Sets the Rolloff
		*  \param pValue float Value the Rolloff is set to
		*/
		void SetRolloff(float pValue);
		/** \brief Set if Relatve or not
		*  \details Set to wether the Postions are relative or
		*  \n absolute to each other to calculate
		*  \param pValue the bool flag:
		*  \n true = Relative;
		*  \n false = Absolute;
		*/
		void SetRelative(bool pValue);
		/** \brief Sets the Repeat
		*  \details Sets to wether the Sources are Replaying after
		*  \n finishing playing the bufferor stopped after that
		*  \param pValue the bool flag:
		*  \n true = Replay;
		*  \n false = Stopp;
		*/
		void SetRepeat(bool pValue);
		/** \brief Sets the Volume of the Sound Source
		*  \details Sets the maximum Volume the Source is playing with
		*  \param pValue the value the Volume is set to
		*/
		void SetVolume(float pValue);
		/** \brief Plays the Sound Source
		*/
		void Play();
		/** \brief Stops the playing of the Sound Source and sets it to the beginning
		*/
		void Stop();
		/** \brief Pauses the playing of the Sound Source;
		*/
		void Pause();
		/** \brief Rewind the playing of the Sound Source;
		*/
		void Rewind();
		/** \brief Tests if the Sound Source is playing
		*  \return true for playing and false for not
		*/
		bool IsPlaying();
}

interface ISoundSystem {
	/**
	 * this will load a new sound from a ogg file
	 * Params:
	 *  filename = the name of the file to load
	 *  stream = true if the sound should be streamed, false otherwise
	 */
	ISoundSource LoadOggSound(rcstring filename, bool stream = false);
	
	/**
	 * this will remove a streamed sound from the sound system
	 * Params:
	 *  stream = the streamed sound to remove
	 */
	void RemoveStream(ISoundSource stream);
	
	/**
	 * Streams new sound data for all streamed sounds
	 */
	void Update();
}

enum SoundSystemType
{
  OpenAL,
  None
}

interface ISoundSystemFactory {
	ISoundSystem GetSoundSystem();
}
