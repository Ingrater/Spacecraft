module renderer.exceptions;



/**
 * file exception, thrown on file io error
 */
class FileException : RCException {
public:
	this(rcstring note){
		super(note);
	}
}

/**
 * XmlException, thrown on xml error
 */
class XmlException : RCException {
public:
	this(rcstring msg){
		super(msg);
	}
}

/**
 * font exception, thrown on font loading error
 */
class FontException : RCException {
public:
	this(rcstring msg){
		super(msg);
	}
}

/**
 * model exception, thrown on model loading error
 */
class ModelException : RCException {
public:
	this(rcstring msg){
		super(msg);
	}
}

/**
 * renderer exception, thrown on renderer error
 */
class RendererException : RCException {
public:
	this(rcstring msg){
		super(msg);
	}
}