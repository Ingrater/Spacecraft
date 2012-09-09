module renderer.texture;

import base.renderer;

interface ITextureInternal : ITexture {	
	/**
	 * Binds the texture to a gpu texture channel
	 * Params:
	 * 		pChannel = number of the channel to bind to, has to be 0 <= pChannel < 16 
	 */
	void BindToChannel(int pChannel);
}