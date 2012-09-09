module renderer.camera;

import thBase.math3d.all;
import std.math;
import thBase.file;

/**
 * base class for every camera
 */
abstract class Camera {
protected:
	vec4 m_From;
	vec4 m_To;
	vec4 m_Up;
	vec4 m_Dir;
	mat4 m_CameraMatrix;
	float m_Rotation;
	bool m_ReCalc = true;
	float m_Near,m_Far;
	
public:
	/**
	 * Constructor
	 * Params:
	 *		pNear = near clipping
	 *		pFar = far clipping
	 */ 
	this(float pNear, float pFar){
		m_From.set(0.0f);
		m_To.set(0.0f);
		m_Up.set(0.0f);
		m_Dir.set(0.0f);
		m_ReCalc = true;
		m_Rotation = 0.0f;
		m_Near = pNear;
		m_Far = pFar;
	}
	
	/**
	 * sets the rotatoni along the view axis
	 * Params:
	 *		pDegrees = rotation in degress
	 */
	void SetRotation(float pDegrees){
		while(pDegrees < 0)
			pDegrees += 360.0f;
		while(pDegrees > 360.0f)
			pDegrees -= 360.0f;
		m_Rotation = pDegrees / 180.0f * PI;
		m_ReCalc = true;
	}
	
	/**
	 * sets the position of the camera
	 * Params:
	 *		pX = position x
	 *		pY = position y
	 *		pZ = position z
	 */
	void SetFrom(float pX, float pY, float pZ){
		m_From.x = pX; m_From.y = pY; m_From.z = pZ; m_From.w = 1.0f;
		m_ReCalc = true;
	}
	
	/**
	 * sets the position of the camera
	 * Params:
	 *		pFrom = the position
	 */
	void SetFrom(ref const(vec4) pFrom){
		m_From = pFrom;
		m_ReCalc = true;
	}
	
	/**
	 * sets the position of the camera
	 * Params:
	 *		pFrom = the position
	 */
	void SetFrom(ref const(vec3) pFrom){
		m_From = vec4(pFrom,1.0f);
		m_ReCalc = true;
	}
	
	/**
	 * sets the point the camera is looking at
	 * Params:
	 *		pX = position x
	 *		pY = position Y
	 *		pZ = position z
	 */
	void SetTo(float pX, float pY, float pZ){
		m_To.x = pX;
		m_To.y = pY;
		m_To.z = pZ;
		m_To.w = 1.0f;
		m_ReCalc = true;
	}
	
	/**
	 * sets the point the camera is looking at
	 * Params:
	 *		pTo = the point
	 */
	void SetTo(vec4 pTo){
		m_To = pTo;
		m_ReCalc = true;
	}
	
	/**
	 * sets the poin the camera is looking at
	 * Params:
	 *		pTo = the point
	 */
	void SetTo(vec3 pTo){
		m_To = vec4(pTo,1.0f);
		m_ReCalc = true;
	}
	
	/**
	 * recomputes the camera matrix
	 */
	void Recalc(){
		if(m_ReCalc){
			vec4 temp;
			Quaternion q;
			m_Dir = m_From.direction(m_To);
			m_Up.set(0.0f); m_Up.z = 1.0f; m_Up.w = 1.0f;
			if(m_Dir.z == 1.0f || m_Dir.z == -1.0f){
				m_Up.x = 1.0f;
				m_Up.z = 0.0f;
			}
			else {
				temp = m_Up.cross(m_Dir).normalize();
				m_Up = m_Dir.cross(temp);
			}
			if(m_Rotation != 0.0f){
				q = Quaternion(m_Dir,m_Rotation);
				q = q.normalize();
				m_Up = q.toMat4() * m_Up;
			}
			m_CameraMatrix = mat4.LookAtMatrix(m_From,m_To,m_Up);
			m_ReCalc = false;
		}
	}
	
	/**
	 * gets the camera position
	 */
	vec4 GetFrom() const { return m_From; }
	
	/**
	 * gets the camera matrix
	 */
	mat4 GetCameraMatrix() const { return m_CameraMatrix; }
	
	/**
	 * gets the camera view direction
	 */
	vec4 GetViewDir() const { return m_Dir; }
	
	/**
	 *  gets the camera up vector
	 */
	vec4 GetUp() const { return m_Up; }
	
	/**
	 * Returns: a vector paralell to the horizon of the camera
	 */
	vec4 GetHorizon() const {
		return m_Up.cross(m_Dir).normalize();
	}
	
	/**
	 * gets the camera rotation
	 */
	float GetRotation() const {
		return m_Rotation / PI * 180.0f;
	}
	
	/**
	 * saves the current camera data to a file
	 * Params:
	 * 		pFilename = the file name to save to
	 */
	void SaveToFile(string pFilename){
		auto f = new RawFile(pFilename,"wb");
		if(!f.isOpen())
			return;
		f.write(m_From.f);
		f.write(m_To.f);
		f.write(m_Up.f);
		f.write(m_Dir.f);
		f.write(m_Rotation);
		f.close();
	}
	
	/**
	 * loads camera data from a file
	 * Params:
	 *		pFilename = the file name to load from
	 */
	void LoadFromFile(string pFilename){
		auto f = new RawFile(pFilename,"rb");
		if(!f.isOpen())
			return;
		f.read(m_From.f);
		f.read(m_To.f);
		f.read(m_Up.f);
		f.read(m_Dir.f);
		f.read(m_Rotation);
		m_ReCalc = true;
		f.close();
	}
	
	/**
	 * Returns: The near clipping value
	 */
	float GetNear() const {
		return m_Near;
	}
	
	/**
	 * Returns: The far clipping value
	 */
	float GetFar() const {
		return m_Far;
	}
	
	abstract ref const(mat4) GetProjectionMatrix() const;
}

/**
 * camera with perspective projection
 */
class CameraProjection : Camera {
private:
	float m_Width, m_Height, m_ViewAngle;
	mat4 m_ProjectionMatrix;
public:
	/**
	 * Constructor
	 * Params:
	 *		pWidth = width of the display
	 *		pHeight = height of the display
	 *		pViewAngle = view angle (in degrees)
	 */ 
	this(float pWidth, float pHeight, float pNear, float pFar, float pViewAngle){
		super(pNear,pFar);
		m_Width = pWidth;
		m_Height = pHeight;
		m_ViewAngle = pViewAngle;
		m_ProjectionMatrix = mat4.ProjectionMatrix(m_ViewAngle,m_Height/m_Width,m_Near,m_Far);
	}
	
	/**
	 * Sets the display size
	 * Params:
	 *		pWidth = width of the display
	 *		pHeight = height of the display
	 */
	void SetDisplaySize(float pWidth, float pHeight){
		m_Width = pWidth;
		m_Height = pHeight;
		m_ProjectionMatrix = mat4.ProjectionMatrix(m_ViewAngle,m_Height/m_Width,m_Near,m_Far);
	}
	
	/**
	 * Set view angle
	 * Params:
	 *		pViewAngle = the view angle to use (in degrees)
	 */
	void SetViewAngle(float pViewAngle){
		m_ViewAngle = pViewAngle;
		m_ProjectionMatrix = mat4.ProjectionMatrix(m_ViewAngle,m_Height/m_Width,m_Near,m_Far);
	}
	
	/**
	 * Returns: The view angle (in degrees)
	 */
	float GetViewAngle() const {
		return m_ViewAngle;
	}
	
	/**
	 * Returns: The Projection Matrix
	 */
	override ref const(mat4) GetProjectionMatrix() const {
		return m_ProjectionMatrix;
	}
}

/**
 * camera with paralell projection
 */
class CameraParalell : Camera {
private:
	float m_Left, m_Right, m_Top, m_Bottom;
	mat4 m_ProjectionMatrix;
public:
	/**
	 * Constructor
	 * Params:
	 *		pLeft = left bound
	 *		pRight = right bound
	 *		pTop = top bound
	 *		pBottom = bottom bound
	 *		pNear = near bound
	 *		pFar = far bound
	 */
	this(float pLeft, float pRight, float pTop, float pBottom, float pNear, float pFar){
		super(pNear,pFar);
		m_Left = pLeft;
		m_Right = pRight;
		m_Top = pTop;
		m_Bottom = pBottom;
		m_ProjectionMatrix = mat4.Ortho(m_Left,m_Right,m_Bottom,m_Top,m_Near,m_Far);
	}
	
	/**
	 * Set the bounds
	 * Params:
	 *		pLeft = left bound
	 *		pRight = right bound
	 *		pBottom = bottom bound
	 *		pTop = top bound
	 */
	void SetBounds(float pLeft, float pRight, float pBottom, float pTop){
		m_Left = pLeft;
		m_Right = pRight;
		m_Top = pTop;
		m_Bottom = pBottom;
		m_ProjectionMatrix = mat4.Ortho(m_Left,m_Right,m_Bottom,m_Top,m_Near,m_Far);
	}
	
	/**
	 * Set the bounds
	 * Params:
	 *		pLeft = left bound
	 *		pRight = right bound
	 *		pTop = top bound
	 *		pBottom = bottom bound
	 *		pNear = near bound
	 *		pFar = far bound
	 */ 
	void SetBounds(float pLeft, float pRight, float pBottom, float pTop, float pNear, float pFar){
		m_Left = pLeft;
		m_Right = pRight;
		m_Top = pTop;
		m_Bottom = pBottom;
		m_Near = pNear;
		m_Far = pFar;
		m_ProjectionMatrix = mat4.Ortho(m_Left,m_Right,m_Bottom,m_Top,m_Near,m_Far);
	}
	
	/**
	 * Returns: The Projection Matrix
	 */
	override ref const(mat4) GetProjectionMatrix() const {
		return m_ProjectionMatrix;
	}
	
	/**
	 * Returns: left bound
	 */
	float GetLeft(){
		return m_Left;
	}
	
	/**
	 * Returns: right bound
	 */
	float GetRight(){
		return m_Right;
	}
	
	/**
	 *  Returns: Top bound
	 */
	float GetTop(){
		return m_Top;
	}
	
	/**
	 * Returns: Bottom Bound
	 */
	float GetBottom(){
		return m_Bottom;
	}
}