module base.renderer;

public import base.game;
public import base.windowevents;
import base.all;

alias void delegate() destroyFunc;

interface IDebugDrawRecorder
{
  void Replay();
}

interface IRenderer : IWindowEventListener{
	void Init(shared(IGame) game, IWindowEventHandler eventHandler);
	void RegisterCVars(ConfigVarsBinding* CVarStorage) shared;
	void Deinit();
	void Work();
	shared int GetWidth() const;
	shared int GetHeight() const;
	int GetWidth() const;
	int GetHeight() const;
	shared(IAssetLoader) assetLoader() shared;

  /// Returns: the renderer extractor
  IRendererExtractor GetExtractor() shared;
	
	/// Returns: a sub model render proxy
	IRenderProxy CreateRenderProxy(shared(ISubModel) subModel) shared;
	/// Returns: a camera render proxy
	IRenderProxy CreateRenderProxy() shared;
	/**
	 * Returns: a skymap render proxy
	 * Params: 
     *	texture = the cube map texture to use (make shure it is a cube map texture)
	 */
	IRenderProxy CreateRenderProxySkyBox(shared(ITexture) texture) shared;
	/**
	 * Returns: a 3d hud render proxy
	 * Params:
	 *  model = the model to use for the 3d hud, has to contain only 1 material
	 */
	IRenderProxy CreateRenderProxy3DHud(shared(IModel) model) shared;
	
	void camera(IGameObject obj);
	void camera(IGameObject obj) shared;
	
	void DrawText(uint pFont, vec2 pPos, vec4 pColor, const(char)[] fmt, ...);
	void DrawText(uint pFont, vec2 pPos, vec4 pColor, const(char)[] fmt, ...) shared;
	void DrawText(uint pFont, vec2 pPos, const(char)[] fmt, ...);
	void DrawText(uint pFont, vec2 pPos, const(char)[] fmt, ...) shared;

  void DrawRect(vec2 pos, float width, float height, vec4 color);
	
	vec2 GetTextSize(uint font, const(char)[] text) shared;
	vec2 GetTextSize(uint font, const(char)[] text);
	int GetFontHeight(uint font) shared;
	
	/// Sets the simulations per second value (for displaying only)
	void setSPS(float sps) shared;
	
	///Debug drawing functions
  IDebugDrawRecorder createDebugDrawRecorder() shared;
  void destroyDebugDrawRecorder(IDebugDrawRecorder recorder) shared;

  void startDebugDrawRecording(IDebugDrawRecorder recorder) shared;
  void stopDebugDrawRecording(IDebugDrawRecorder recorder) shared;

	void drawBox(ref const(AlignedBox) box, ref const(vec4) color);
	void drawBox(AlignedBox box, vec4 color = vec4(1.0f,0.0f,0.0f,1.0f)) shared;
	
	void drawLine(ref const Position start, ref const Position end, ref const vec4 color);
	void drawLine(Position start, Position end, vec4 color = vec4(1.0f,0.0f,0.0f,1.0f)) shared;
  void drawArrow(Position from, Position to, vec4 color = vec4(1.0f, 1.0f, 1.0f, 1.0f)) shared;

  void DrawTextWorldspace(uint font, Position pos, vec4 color, const(char)[] fmt, ...) shared;
	
	void freezeCamera();
	void loadAmbientSettings(rcstring path) shared;
}

struct ScopedDebugDrawRecording
{
  private IDebugDrawRecorder m_recorder;

  @disable this();

  this(IDebugDrawRecorder recorder)
  {
    m_recorder = recorder;
    g_Env.renderer.startDebugDrawRecording(recorder);
  }

  ~this()
  {
    g_Env.renderer.stopDebugDrawRecording(m_recorder);
  }
}

interface IRendererFactory {
	void Init(int screenWidth, int screenHeight, bool fullScreen, bool vsync, bool noBorder, bool grabInput, int antialiasing);
	IRenderer GetRenderer();
}

interface ISubModel {
	/**
	 * Searches for the minimum and maximum coordinates of the model
	 * Params:
	 *		pMin = result minimum
	 *		pMax = result maximum
	 *		pApplyModelMatrix = if the model matrix should be applied to the result or not
	 */
	void FindMinMax(ref vec3 pMin, ref vec3 pMax) shared;
	
	///ditto
	void FindMinMax(ref vec3 pMin, ref vec3 pMax);
}

interface IModel : ISubModel {	
	/**
	 * Prints the node tree
	 */
	void PrintNodes() shared;
		
	///ditto
	void PrintNodes();
	
	/**
	 * Gets a sub model of this model
	 * Params:
	 *  depth = -1 for any depth, otherwise depth in tree to traverse
	 *  path = path to the new root node for the sub model
	 */
	shared(ISubModel) GetSubModel(int depth, string[] path) shared;
	
	///ditto
	ISubModel GetSubModel(int depth, string[] path);
}


interface ITexture {
}

struct Sprite {
	vec2 offset;
	vec2 size;
	uint atlas;
}

interface ISpriteAtlas {
	/**
	 * Gets a single sprite from the sprite atlas
	 * Params:
	 *  x = x coordinates in pixels on the sprite atlas (left top is origin)
	 *  y = y coordinates in pixels on the sprite atlas
	 *  width = width in pixels
	 *  params = height in pixels
	 * Returns: a sprite handle
	 */
	Sprite GetSprite(int x, int y, int width, int height);
	
	///ditto
	Sprite GetSprite(int x, int y, int width, int height) shared;
}

shared interface IAssetLoader {
	/**
	 * this tells the resource loader, to load a model, the call blocks until the model was loaded
	 * Params:
	 *  path = path to the model file
	 */
	shared(IModel) LoadModel(rcstring path);
	
	/**
	 * this tells the resource loader, to load a cube map, the call blocks until the model was loaded
	 * Params:
	 *  path = path to the cubemap file
	 */
	shared(ITexture) LoadCubeMap(rcstring path);
	
	/**
	 * this loads a sprite atlas (a image containing multiple sprites)
	 * Params:
	 *  path = the path to the image file
	 * Returns: A sprite atlas interface
	 */
	shared(ISpriteAtlas) LoadSpriteAtlas(rcstring path);
}


//extern(D) IRendererFactory GetRendererFactory();
