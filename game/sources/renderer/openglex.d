module renderer.openglex;

import renderer.opengl;
import thBase.format;

/**
 * Exception thrown on OpenGL error
 */
class OpenGLException : RCException {
public:
	
	this(){
		gl.ErrorCode error = gl.GetError();
		super(format("GL error code: %s", gl.TranslateError(error)));
	}
	
	this(rcstring note, bool checkForGlErrors = true){
		if(checkForGlErrors){
			gl.ErrorCode error = gl.GetError();
			super(format("%s\nGL error code: %s", note[], gl.TranslateError(error)));
		}
		else
			super(note);
	}
	
	this(string note, gl.ErrorCode error){
		super(format("%s\nGL error code: %s", note, gl.TranslateError(error)));
	}
}