unit Flash8;

// http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/2/index.html

interface

const
  clBlack   = $FF000000;
  clMaroon  = $FF800000;
  clGreen   = $FF00FF00;
  clOlive   = $FF808000;
  clNavy    = $FF000080;
  clPurple  = $FF800080;
  clTeal    = $FF008080;
  clGray    = $FF808080;
  clSilver  = $FFC0C0C0;
  clRed     = $FFFF0000;
  clLime    = $FF00FF00;
  clYellow  = $FFFFFF00;
  clBlue    = $FF0000FF;
  clFuchsia = $FFFF00FF;
  clAqua    = $FF00FFFF;
  clLtGray  = $FFC0C0C0;
  clDkGray  = $FF808080;
  clWhite   = $FFFFFFFF;

  clMoneyGreen = $FFC0DCC0;
  clSkyBlue    = $FFA6CAF0;
  clCream      = $FFFFFBF0;
  clMedGray    = $FFA0A0A4;
  
type
  Number = Double;
  
  BitmapFilter = class;
  ContextMenu = class;
  ColorTransform = class;
  Matrix = class;
  MovieClip = class;
  Point = class;
  Rectangle = class;
  TextField = class;
  
  Accessibility = external class(Accessibility)
    class function isActive: Boolean;
    class procedure updateProperties;
  end;
  
  arguments = external class(arguments)
    class property callee: TObject;
    class property caller: TObject;
    class property length: Number;
    class property []: TObject deprecated;
  end;
  
  TArray = external class(Array)
    class property CASEINSENSITIVE: Number readonly;
    class property DESCENDING: Number readonly;
    property length: Number;
    class property NUMERIC: Number readonly;
    class property RETURNINDEXARRAY: Number readonly;
    class property UNIQUESORT: Number readonly;

    constructor Create(value: TObject = nil);
    
    function concat(value: TObject = nil): TArray;
    function join(delimiter: string = ''): string;
    function pop: TObject;
    function push(value: TObject): Number;
    procedure revers();
    function shift: TObject;
    function slice(startIndex, endIndex: Number = 0): TArray;
    function sort(compareFunction: TObject = nil; options: Number = 0): TArray;
    function sortOn(fieldName: TObject; options: TObject = nil): TArray;
    function splice(startIndex: Number; deleteCount: Number = 0; value: TObject = nil): TArray;
    function toString(): string;
    function unshift(value: TObject): Number;
    property []: TObject deprecated;
  end;  
  
  AsBroadcaster = external class
    property _listeners: TArray readonly;
    
    constructor Create;
    
    function addListener(listenerObj: TObject): Boolean;
    procedure broadcastMessage(eventName: string);
    class procedure initialize(obj: TObject);
    function removeListener(listenerObj: TObject): Boolean;
  end;
  
  BevelFilter = external class(BitmapFilter, flash.filters.BevelFilter)
    property angle: Number;
    property blurX: Number;
    property blurY: Number;
    property distance: Number;
    property highlightAlpha: Number;
    property highlightColor: Number;
    property knockout: Boolean;
    property quality: Number;
    property shadowAlpha: Number;
    property shadowColor: Number;
    property strenght: Number;
    property type: string;

    constructor Create(distance, angle, highlighColor, highlighAlpha, shadowColor, shadowAlpha, blurX, blurY, strength, quality: Number = 0; type: string = ''; knockout: Boolean = False);

    function clone: BevelFilter;
  end;
  
  BitmapData = external class(flash.display.BitmapData)
    property height: Number readonly;
    property rectangle: Rectangle readonly;
    property transparent: Boolean readonly;
    property width: Number readonly;

    constructor Create(width, height: Number; transparent: Boolean = False; fillColor: Number = 0);

    function applyFilter(sourceBitmap: BitmapData; sourceRect: Rectangle; destPoint: Point; filter: BitmapFilter): Number;
    function clone: BitmapData;
    procedure colorTransform(rect: Rectangle; colorTransform: ColorTransform);
    function compare(otherBitmapData: BitmapData): TObject;
    procedure copyChannel(sourceBitmap: BitmapData; sourceRect: Rectangle; destPoint: Point; sourceChannel, destChannel: Number);
    procedure copyPixels(sourceBitmap: BitmapData; sourceRect: Rectangle; destPoint: Point; alphaBitmap: BitmapData = nil; alphaPoint: Point = nil; mergeAlpha: Boolean = False);
    procedure dispose;
    procedure draw(Source: TObject; matrix: Matrix = nil; colorTransform: ColorTransform = nil; blendMode : string = ''; clipRect : Rectangle = nil; smooth: Boolean = False);
    procedure fillRect(rect: Rectangle; color: Number);
    procedure floodFill(x, y, color: Number);
    function generateFilterRect(sourceRect: Rectangle; filter: BitmapFilter): Rectangle;
    function getColorBoundsRect(mask, color: Number; findColor: Boolean = False): Rectangle;
    function getPixel(x, y: Number): Number;
    function getPixel32(x, y: Number): Number;
    function hitTest(firstPoint: Point; firstAlphaThreshold: Number; secondObject: TObject; secondBitmapPoint: Point = nil; secondAlphaThreshold: Number = 0): Boolean;
    class function loadBitmap(id: String): BitmapData;
    procedure merge(sourceBitmap: BitmapData; sourceRect: Rectangle; destPoint: Point; redMult, greenMult, blueMult, alphaMult: Number);
    procedure noise(randomSeed: Number; low, high, channelOptions: Number = 0; grayScale: Boolean = False);
    procedure paletteMap(sourceBitmap: BitmapData; sourceRect: Rectangle; destPoint: Point; redArray, greenArray, blueArray, alphaArray: TArray = nil);
    procedure perlinNoise(baseX, baseY, numOctaves, randomSeed: Number; stitch, fractalNoise: Boolean; channelOptions: Number = 0; grayScale: Boolean = False; offsets: TObject = nil);
    function pixelDissolve(sourceBitmap: BitmapData; sourceRect: Rectangle; destPoint: Point; randomSeed, numberOfPixels, fillColor: Number = 0): Number;
    procedure scroll(x, y: Number);
    procedure setPixel(x, y, color: Number);
    procedure setPixel32(x, y, color: Number);
    function threshold(sourceBitmap: BitmapData; sourceRect: Rectangle; destPoint: Point; operation: string; threshold: Number; color, mask: Number = 0; copySource: Boolean = False): Number;
  end;
  
  BitmapFilter = external class(flash.filters.BitmapFilter)
    constructor Create;
    function clone: BitmapFilter;
  end;

  BlurFilter = external class(BitmapFilter, flash.filters.BlurFilter)
    property blurX: Number;
    property blurY: Number;
    property quality: Number;
    
    constructor Create(blurX, blurY, quality: Number = 0);
    
    function clone: BlurFilter;
  end;
  
  TBoolean = external class(Boolean)
    constructor Create(Value: TObject);
    
    function toString: string;
    function valueOf: Boolean;
  end;
  
  // Peut-on utiliser Button sans passer par Flash ?!
  (*
  Button = external class(Button)
    property _alpha: Number;
    property blendMode: string;
    property caseAsBitmap: Boolean;
    property enabled: Boolean;
    property filters: TArray;
    property _focusRect: Boolean;
    property _height: Number;
  //property _highquality: Number; deprecated -> _quality
    property menu: ContextMenu;
    property _name: string;
    property _parent: MovieClip;
    property _quality: string;
    property _rotation: Number;
    property scale9Grid: Rectangle;
    property _soundbuftime: Number;
    property tabEnabled: Boolean;
    property tabIndex: Integer;
    property _target: string readonly;
    property trackAsMenu: Boolean;
    property _url: string readonly;
    property useHandCursor: Boolean;
    property _visible: Boolean;
    property _width: Number;
    property _x: Number;
    property _xmouse: Number readonly;
    property _xscale: Number;
    property _y: Number;
    property _ymouse: Number readonly;
    property _yscale: Number;
    
    constructor Create;
    
    property onDragOut: procedure of object;
    property onDragOver: procedure of object;
    property onKeyDown: procedure of object;
    property onKeyUp: procedure of object;
    property onKillFocus: procedure(newFocus: TObject) of object;
    property onPress: procedure of object;
    property onRelease: procedure of object;
    property onReleaseOutside: procedure of object;
    property onRollOut: procedure of object;
    property onRollOver: procedure of object;
    property onSetFocus: procedure (oldFocus: TObject) of object;

    function getDepth: Number;
  end;
  *)
  
  Camera = external class
    property activityLevel: Number readonly;
    property bandwidth: Number readonly;
    property currentFps: Number readonly;
    property fps: Number readonly;
    property height: Number readonly;
    property index: Number readonly;
    property motionLevel: Number readonly;
    property motionTimeOut: Number readonly;
    property muted: Boolean readonly;
    property name: string readonly;
    class property names: array of string readonly;
    property quality: Number readonly;
    property width: Number readonly;
    
    procedure onActivity(active: Boolean); virtual;
    procedure onStatus(infoObject: TObject); virtual;
    
    class function get(Index: Number = 0): Camera;
    procedure setMode(width, height, fps : Number = 0; favorArea: Boolean = False);
    procedure setMotionLevel(motionLevel, timeOut: Number = 0);
    procedure setQuality(bandwidth, quality: Number = 0);
  end;
  
  capabilities = external class(System.capabilities)
    class property avHardwareDisable: Boolean readonly;
    class property hasAccessibility: Boolean readonly;
    class property hasAudio: Boolean readonly;
    class property hasAudioEncoder: Boolean readonly;
    class property hasEmbeddedVideo: Boolean readonly;
    class property hasIME: Boolean readonly;
    class property hasMP3: Boolean readonly;
    class property hasPrinting: Boolean readonly;
    class property hasScreenBroadcast: Boolean readonly;
    class property hasScreenPlayback: Boolean readonly;
    class property hasStreamingAudio: Boolean readonly;
    class property hasStreamingVideo: Boolean readonly;
    class property hasVideoEncoder: Boolean readonly;
    class property isDebugger: Boolean readonly;
    class property language: String readonly;
    class property localFileReadDisable: Boolean readonly;
    class property manufacturer: String readonly;
    class property os: String readonly;
    class property pixelAspectRatio: Number readonly;
    class property playerType: string readonly;
    class property screenColor: string readonly;
    class property screenDPI: Number readonly;
    class property screenResolutionX: Number readonly;
    class property screenResolutionY: Number readonly;
    class property serverString: string readonly;
    class property version: string readonly;
  end;
  
  ColorMatrixFilter = external class(BitmapFilter, flash.filters.ColorMatrixFilter)
    property matrix: array[0..19] of Number;
    
    constructor Create(matrix: array[0..19] of Number);
    
    function clone: colorMatrixFilter;
  end;
  
  ContextMenu = external class
    property builtInItems: TObject;
    property customItems: TObject;

    procedure onSelect(item, item_menu: TObject); virtual;

    constructor Create(callbackFunction: procedure of object = nil);

    function copy: ContextMenu;
    procedure hideBuiltInItems;
  end;

  ConvolutionFilter = external class(BitmapFilter, flash.filters.ConvolutionFilter)
    property alpha: Number;
    property bias: Number;
    property clamp: Boolean;
    property color: Number;
    property divisor: Number;
    property matrix: TArray;
    property matrixX: Number;
    property matrixY: Number;
    property preserveAlpha: Boolean;
    
    constructor Create(matrixX, matrixY: Number; matrix: array of Number; divisor, bias: Number = 0; preserveAlpha, clamp: Boolean = False; color, alpha: Number = 0);
    
    function clone: ConvolutionFilter;
  end;
  
  DisplacementMapFilter = external class(BitmapFilter, flash.filters.DisplacementMapFilter)
    property alpha: Number;
    property color: Number;
    property componentX: Number;
    property componentY: Number;
    property mapBitmap: BitmapData;
    property mapPoint: Point;
    property mode: string;
    property scaleX: Number;
    property scaleY: Number;
    
    constructor Create(mapBitmap: BitmapData; mapPoint: Point; componentX, componenY, scaleX, scaelY: Number; mode: string = ''; color, alpha: Number = 0);
    
    function close: DisplacementMapFilter;
  end;
  
  ExternalInterface = external class(flash.external.ExternalInterface)
    class property available: Boolean;
    class function addCallback(methodName: string; instance: TObject; method: procedure of object): Boolean;
    class function call(methodName: string; parameter: Variant = nil): Variant;
  end;
  
  GlowFilter = external class(BitmapFilter, flash.filters.GlowFilter)
    property alpha: Number;
    property blurX: Number;
    property blurY: Number;
    property color: Number;
    property inner: Boolean;
    property knockout: Boolean;
    property quality: Number;
    property strength: Number;
    
    constructor Create(color, alpha, blurX, blurY, strength, quality: Number = 0; inner, knockout: Boolean = False);
    
    function clone: GlowFilter;
  end; 
  
  Rectangle = external class(flash.geom.Rectangle)
    property bottom: Number;
    property bottoRight: Point;
    property height: Number;
    property left: Number;
    property right: Number;
    property size: Point;
    property top: Number;
    property topLeft: Point;
    property width: Number;
    property x: Number;
    property y: Number;
    
    constructor Create(x, y, width, height: Number);
    
    function clone: Rectangle;
    function contains(x, y: Number): Boolean;
    function containsPoint(pt: Point): Boolean;
    function containsRectangle(rect: Rectangle): Boolean;
    function equals(toCompare: TObject): Boolean;
    procedure inflate(dx, dy: Number);
    procedure infatePoint(pt: Point);
    function intersection(toIntersect: Rectangle): Rectangle;
    function intersects(toIntersect: Rectangle): Boolean;
    function isEmpty: Boolean;
    procedure offset(dx, dy: Number);
    procedure offsetPoint(pt: Point);
    procedure setEmpty;
    function toString: string;
    function union(toUnion: Rectangle): Rectangle;
  end;
  
  Point = external class(flash.geom.Point)
    property length: Number;
    property x: Number;
    property y: Number;
    
    constructor Create(x, y: Number = 0);
    
    function add(v: Point): Point;
    function clone: Point;
    class function distance(pt1, pt2: Point): Number;
    function equals(toCompare: TObject): Boolean;
    class function interpolate(pt1, pt2: Point; f: Number): Point;
    procedure normalize(length: Number);
    procedure offset(dx, dy: Number);
    class function polar(len, angle: Number): Point;
    function subtract(v: Point): Point;
    function toString: string;
  end;

  Matrix = external class(flash.geom.Matrix)
    property a : Number;
    property b : Number;
    property c : Number;
    property d : Number;
    property tx: Number;
    property ty: Number;
    
    constructor Create(a, b, c, d, tx, ty: Number = 0);
    
    function clone: Matrix;
    function concat(m: Matrix): Matrix;
    procedure createBox(scaleX, scaleY: Number; rotation, tx, ty: Number = 0);
    procedure createGradientBox(width, height: Number; rotation, tx, ty: Number = 0);
    function deltaTransformPoint(pt: Point): Point;
    procedure identity();
    procedure invert();
    procedure rotate(angle: Number);
    procedure scale(sx, sy: Number);
    function toString: string;
    function transformPoint(pt: Point): Point;
    procedure translate(tx, ty: Number);
  end;
  
  ColorTransform = external class(flash.geom.ColorTransform)
    property alphaMultiplier: Number;
    property alphaOffset: Number;
    property blueMultiplier: Number;
    property blueOffset: Number;
    property greenMultiplier: Number;
    property greenOffset: Number;
    property redMultiplier: Number;
    property redOffset: Number;
    property rgb: Number;
    constructor Create(redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier, redOffset, greenOffset, blueOffset, alphaOffset: Number = 0);
    procedure concat(second: ColorTransform);
    function toString: string;
  end;
  
  LoadVars = external class
    property contentType: string;  // The MIME type that is sent to the server when you call LoadVars.send() or LoadVars.sendAndLoad().
    property loaded: Boolean;      // A Boolean value that indicates whether a load or sendAndLoad operation has completed, undefined by default.

    procedure onData(src: string); virtual;              // Invoked when data has completely downloaded from the server or when an error occurs while data is downloading from a server.
    procedure onHTTPStatus(httpStatus: Number); virtual; // Invoked when Flash Player receives an HTTP status code from the server.
    procedure onLoad(success: Boolean); virtual;         // Invoked when a LoadVars.load() or LoadVars.sendAndLoad() operation has ended.

    constructor Create();
    
    procedure addRequestHeader(header: TObject; headerValue: string); // Adds or changes HTTP request headers (such as Content-Type or SOAPAction) sent with POST actions.
    procedure decode(queryString: string);                            // Converts the variable string to properties of the specified LoadVars object.
    function getBytesLoaded: Number;                                  // Returns the number of bytes downloaded by LoadVars.load() or LoadVars.sendAndLoad().
    function getBytesTotal: Number;                                   // Returns the total number of bytes downloaded by LoadVars.load() or LoadVars.sendAndLoad().
    function load(url: string): Boolean;                              // Downloads variables from the specified URL, parses the variable data, and places the resulting variables in my_lv.    function send(url, target: string; method: string = 'POST'): Boolean; // Sends the variables in the my_lv object to the specified URL.
    function sendAndLoad(url: string; target: TObject; method: string = 'POST'): Boolean; // Posts variables in the my_lv object to the specified URL.
    function toString: string;                                        // Returns a string containing all enumerable variables in my_lv, in the MIME content encoding application/x-www-form-urlencoded.
  end;
  
  Transform = external class(flash.geom.Transform)
    property colorTransform: ColorTransform;
    property concatenatedColorTransform: ColorTransform readonly;
    property concatenatedMatrix: Matrix readonly;
    property matrix: Matrix;
    property pixelBounds: Rectangle;
    
    constructor Create(mc: MovieClip);
  end;
  
  Mouse = external class
  { events:
    procedure onMouseDown;
    procedure onMouseMove;
    procedure onMouseUp;
    procedure onMouseWheel(delta: Number = 0; scrollTarget: TObject = nil);
  }
    class procedure addListener(listener: TObject);
    class function hide: Number;
    class function removeListener(listener: TObject): Boolean;
    class function show: Number;
  end;
  
  MovieClip = external class
    property _alpha: Number;
    property blendMode: string;
    property cacheAsBitmap: Boolean;
    property _currentframe: Number readonly;
    property _droptarget: string readonly;
    property enabled: Boolean;
    property filters: TArray writeonly; // WARNING: can't use push(), need to set a new TArray
    property focusEnabled: Boolean;
    property _focusrect: Boolean;
    property forceSmoothing: Boolean;
    property _framesloaded: Number readonly;
    property _height: Number;
    property _highquality: Number deprecated;
    property hitArea: TObject;
    property _lockroot: Boolean;
    property menu: ContextMenu;
    property _name: string;
    property opaqueBackground: Number;
    property _parent: MovieClip;
    property _quality: string;
    property _rotation: Number;
    property scale9Grid: Rectangle;
    property scrollRect: TObject;
    property _soundbuftime: Number;
    property tabChildren: Boolean;
    property tabEnabled: Boolean;
    property tabIndex: Number;
    property _target: string readonly;
    property _totalframes: Number readonly;
    property trackAsMenu: Boolean;
    property transform: Transform;
    property _url: string readonly;
    property useHandCursor: Boolean;
    property _visible: Boolean;
    property _width: Number;
    property _x: Number;
    property _xmouse: Number readonly;
    property _xscale: Number;
    property _y: Number;
    property _ymouse: Number readonly;
    property _yscale: Number;
    
    constructor Create(Parent: MovieClip; Name: string; Depth: Number) as Parent.createEmptyMovieClip;

    procedure onData; virtual;
    procedure onDragOut; virtual;
    procedure onDragOver; virtual;
    procedure onEnterFrame; virtual;
    procedure onKeyDown; virtual;
    procedure onKeyUp; virtual;
    procedure onKillFocus(newFocus: TObject); virtual;
    procedure onLoad; virtual;
    procedure onMouseDown; virtual;
    procedure onMouseMove; virtual;
    procedure onMouseUp; virtual;
    procedure onPress; virtual;
    procedure onRelease; virtual;
    procedure onReleaseOutside; virtual;
    procedure onRollOut; virtual;
    procedure onRollOver; virtual;
    procedure onSetFocus(oldFocus: TObject); virtual;
    procedure onUnload; virtual;

    procedure attachAudio(id: TObject);
    procedure attachBitmap(bmp: BitmapData; depth: Number; pixelSnapping: string = ''; smoothing: Boolean = False);
    function attachMovie(id, name: string; depth: Number; initObject: TObject = nil): MovieClip;
    procedure beginBitmapFill(bmp: BitmapData; AMatrix: Matrix = nil; repeat, smoothing : Boolean = False);
    procedure beginFill(rgb: Number; alpha: Number = 100);
    procedure beginGradientFill(fillType: string; colors, alphas, ratios: array of Number; matrix: TObject; spreadMethod, interpolationMethod: string = ''; focalPointRatio: Number = 0);
    procedure clear;
    function createEmptyMovieClip(name: string; depth: Number): MovieClip;
    function createTextField(instanceName: string; depth: Number; x, y, width, height: Number): TextField;
    procedure curveTo(controlX, controlY, anchorX, anchorY: Number);
    function duplicateMovieClip(name: string; depth: Number; initObject : TObject = nil): MovieClip;
    procedure endFill();
    function getBounds(bounds: TObject): TObject;
    function getBytesLoaded: Number;
    function getBytesTotal: Number;
    function getDepth: Number;
    function getInstanceAtDepth(depth: Number): MovieClip;
    function getNextHighestDepth() : Number;
    function getRect(bounds: TObject): TObject;
    function getSWFVersion: Number;
//  function getTextSnapshot: TextSnapshot;
    procedure getURL(url: string; window, method: string = '');
    procedure globalToLocal(pt: TObject);
    procedure gotoAndPlay(frame: TObject);
    procedure gotoAndStop(frame: TObject);
    function hitTest(x, y: Number; shapeFlag: Boolean = False): Boolean; { overload
    function hitTest(target: TObject); Boolean; overload }
    procedure lineGradientStyle(fillType: string; colors, alphas, ratios: array of Number; matrix: TObject; spreadMethod, interpolationMethod: string = ''; focalPointRatio: Number = 0);
    procedure lineStyle(thickness, rgb : Number = 0; alpha: Number = 100; pixelHingint : Boolean = False; noScale : string = 'normal'; capsStyle: string = 'round'; jointStyle : string = 'round'; miterLimit: Number = 3);
    procedure lineTo(x, y: Number);
    procedure loadMovie(url: string; Method: string = '');
    procedure localToGlobal(pt: TObject);
    procedure moveTo(x, y: Number);
    procedure nextFrame;
    procedure play;
    procedure prevFrame;
    procedure removeMovieClip();
    procedure setMask(mc: MovieClip);
    procedure startDrag(lockCenter: Boolean = False; left, top, right, bottom: Number = 0);
    procedure stop;
    procedure stopDrag;    
    procedure swapDepths(target: Number); {overload;
    procedure swapDepths(target: TObject); overload; }
    procedure unloadMovie();
    
    function toString: string;
 end;
 
 (*
 TOnLoadCompleteEvent = procedure(target_mc: MovieClip; HttpStatus: Integer) of object;
 TOnLoadErrorEvent = procedure(target_mc: MovieClip; ErrorCode: string; HttpStatus: Integer) of object;
 TOnLoadInitEvent = procedure(target_mc: MovieClip) of object;
 TOnLoadProgressEvent = procedure(target_mc: MovieClip; loadedBytes, totalBytes: Integer) of object;
 TOnLoadStartEvent = procedure(target_mc: MovieClip) of object;
 *)
 MovieClipLoader = external class
   constructor Create();
   function addListener(listener: TObject): Boolean;
   function getProgress(target: TObject): TObject;
   function loadClip(url: string; target: TObject): Boolean;
   function removeListener(listener: TObject): Boolean;
   function unloadClip(target: TObject): Boolean;
   property checkPolicyFile: Boolean;
  (*
   property onLoadComplete : TOnLoadCompleteEvent;
   property onLoadError : TOnLoadErrorEvent;
   property onLoadInit: TOnLoadInitEvent;
   property onLoadProgress: TOnLoadProgressEvent;
   property onLoadStart: TOnLoadStartEvent;
  *)
 end;
 
  NetConnection = external class
    constructor Create;
    function connect(targetURI: string): Boolean;
  end;
  
  TCueObject = class // or record
    name       : string;
    time       : Number;
    type       : string;
    parameters : Variant; // parameters['name'] = 'value'
  end;

  TMetaData = class
    videocodecid  : Number;
    framerate     : Number;
    videodatarate : Number;
    height        : Number;
    width         : Number;
    duration      : Number;
  end;
  
  TInfoObject = class // or record
    code : string;
    level: string;
  end;

  NetStream = external class
    property bufferLength: Number readonly;
    property bufferTime: Number readonly;
    property bytesLoaded: Number readonly;
    property bytesTotal: Number readonly;
    property checkPolicyFile: Boolean;
    property currentFps: Number readonly;
    property time: Number readonly;

    procedure onCuePoint(infoObject: TCueObject); virtual;
    procedure onMetaData(infoObject: TMetaData); virtual;
    procedure onStatus(infoObject: TInfoObject); virtual;

    constructor Create(connection: NetConnection);

    procedure attachVideo(theCamera: Camera; snapshotMilliseconds: Number);
    procedure close;
    procedure pause(flag: Boolean = False);
    //procedure play(name: TObject; start, len: Number; reset: TObject);
    procedure play(name: string; start, len: Number = 0; reset: TObject = nil);
    procedure seek(offset: Number);
    procedure setBufferTime(bufferTime: Number);
  end;

  TextExtent = class // or record
    ascent          : Number;
    descent         : Number;
    width           : Number;
    height          : Number;
    textFieldHeight : Number;
    textFieldWidth  : Number;
  end;

  TextFormat = external class
    property align: string;
    property blockIndent: Number;
    property bold: Boolean;
    property bullet: Boolean;
    property color:Number;
    property font: string;
    property indent: Number;
    property italic: Boolean;
    property kerning: Boolean;
    property leading: Number;
    property leftMargin: Number;
    property letterSpacing: Number;
    property rightMargin: Number;
    property size: Number;
    property tabStops: Array of Number;
    property target: string;
    property underline: Boolean;
    property url: string;

    constructor Create(font: string = ''; size, color: Number = 0; bold, italic, underline: Boolean = False; url, target, align: string = ''; leftMargin, rightMargin, indent, leading: Number = 0);

    function getTextExtent(text: string; width: Number = 0): TextExtent;
  end;

  TextField = external class
    constructor Create(Parent: MovieClip; Name: string; Depth, Left, Top, Width, Height: Number) as Parent.createTextField;

    property _alpha: Number; // Sets or retrieves the alpha transparency value of the text field.
    property antiAliasType: string; // The type of anti-aliasing used for this TextField instance.
    property autoSize: string; // Controls automatic sizing and alignment of text fields : 'none', 'left', 'right', 'center' 
    property background: Boolean; // Specifies if the text field has a background fill.
    property backgroundColor: Number; // The color of the text field background.
    property border: Boolean; // Specifies if the text field has a border.
    property borderColor: Number; // The color of the text field border.
    property bottomScroll: Number readonly; //  An integer (one-based index) that indicates the bottommost line that is currently visible the text field.
    property condenseWhite: Boolean; // A Boolean value that specifies whether extra white space (spaces, line breaks, and so on) in an HTML text field should be removed.
    property embedFonts: Boolean; // Specifies whether to render using embedded font outlines.
    property filters: TArray;
    property gridFitType: string; // The type of grid fitting used for this TextField instance. 
    property _height: Number; // The height of the text field in pixels.
    property _highquality: Number deprecated; // Deprecated since Flash Player 7. This property was deprecated in favor of TextField._quality.
    property hscroll: Number; // Indicates the current horizontal scrolling position.
    property html: Boolean; // A flag that indicates whether the text field contains an HTML representation.
    property htmlText: string; // If the text field is an HTML text field, this property contains the HTML representation of the text field's contents.
    property length: Number readonly; // Indicates the number of characters in a text field.
    property maxChars: Number;           // Indicates the maximum number of characters that the text field can contain.
    property maxhscroll: Number readonly; // Indicates the maximum value of TextField.hscroll.
    property menu: ContextMenu;          // Associates the ContextMenu object contextMenu with the text field my_txt.
    property mouseWheelEnabled: Boolean; // A Boolean value that indicates whether Flash Player should automatically scroll multiline text fields when the mouse pointer clicks a text field and the user rolls the mouse wheel.
    property multiline: Boolean;         // Indicates whether the text field is a multiline text field.
    property _name: string;              // The instance name of the text field.
    property _parent: MovieClip;         // A reference to the movie clip or object that contains the current text field or object.
    property password: Boolean;          // Specifies whether the text field is a password text field.
    property _quality: string;           // The rendering quality used for a SWF file : 'LOW', 'MEDIUM', 'HIGH', 'BEST' 
    property restrict: string;           // Indicates the set of characters that a user may enter into the text field.
    property _rotation: Number;          // The rotation of the text field, in degrees, from its original orientation.
    property scroll: Number;             // The vertical position of text in a text field.
    property selectable: Boolean;        // A Boolean value that indicates whether the text field is selectable.
    property sharpness: Number;          // The sharpness of the glyph edges in this TextField instance.
    property _soundbuftime: Number;      // The number of seconds a sound prebuffers before it starts to stream.
 // property styleSheet: StyleSheet;     // Attaches a style sheet to the text field.
    property tabEnabled: Boolean;        // Specifies whether the text field is included in automatic tab ordering.
    property tabIndex: Number;  // Lets you customize the tab ordering of objects in a SWF file.
    property _target: string readonly; // The target path of the text field instance.
    property text:string;       // Indicates the current text in the text field.
    property textColor: Number; // Indicates the color of the text in a text field.
    property textHeight: Number;// Indicates the height of the text, in pixels.
    property textWidth: Number; // Indicates the width of the text, in pixels.
    property thickness: Number; // The thickness of the glyph edges in this TextField instance.
    property type: string;      // Specifies the type of text field : 'dynamic', 'input'.
    property _url: string readonly; // Retrieves the URL of the SWF file that created the text field.
    property variable: string;  // The name of the variable that the text field is associated with.
    property _visible: Boolean; // A Boolean value that indicates whether the text field my_txt is visible.
    property _width: Number;    // The width of the text field, in pixels.
    property wordWrap: Boolean; // A Boolean value that indicates if the text field has word wrap.
    property _x: Number;       // An integer that sets the x coordinate of a text field relative to the local coordinates of the parent movie clip.
    property _xmouse: Number readonly;   // Returns the x coordinate of the mouse position relative to the text field.
    property _xscale: Number;   // Determines the horizontal scale of the text field as applied from the registration point of the text field, expressed as a percentage.
    property _y: Number;       // The y coordinate of a text field relative to the local coordinates of the parent movie clip.
    property _ymouse: Number readonly;   // Indicates the y coordinate of the mouse position relative to the text field.
    property _yscale: Number;   // The vertical scale of the text field as applied from the registration point of the text field, expressed as a percentage.
    
    procedure onChanged(changedField: TextField); virtual;
    procedure onKillFocus(newFocus: TObject); virtual;
    procedure onScroller(scrolledField: TextField); virtual;
    procedure onSetFocus(oldFocus: TObject); virtual;
    
   { events :
    procedure onChanged(changedField: TextField); virtual;
    procedure onScroller(scrolledField: TextField); virtual;
   }
    function addListener(listener: TObject): Boolean;
    function getDepth: Number;
    function getFontList: TArray;
    function getNewTextFormat: TextFormat;
    function getTextFormat(beginIndex, endIndex: Number = 0): TextFormat;
    function removeListener(listener: TObject): Boolean;
    procedure removeTextField();
    procedure replaceSel(newText: string);
    procedure replaceText(beginIndex, endIndex: Number; newText: string);
    procedure setNewTextFormat(tf: TextFormat);
   {
    procedure setTextFormat(textFormat: TextFormat); overload;
    procedure setTextFormat(beginIndex: Number; textFormat: TextFormat); overload;}
    procedure setTextFormat(beginIndex, endIndex: Number; textFormat: TextFormat); //overload;}
 end;

  Math = external class
    class property E: Number;
    class property LN10: Number;
    class property LN2: Number;
    class property LOG10E: Number;
    class property LOG2E: Number;
    class property PI: Number;
    class property SQRT1_2: Number;
    class property SQRT2: Number;
    
    class function abs(x: Number): Number;
    class function acos(x: Number): Number;
    class function asin(x: Number): Number;
    class function atan(tangent: Number): Number;
    class function atan2(y, x: Number): Number;
    class function ceil(x: Number): Number;
    class function cos(x: Number): Number;
    class function exp(x: Number): Number;
    class function floor(x: Number): Integer;
    class function log(x: Number): Number;
    class function max(x, y: Number): Number;
    class function min(x, y: Number): Number;
    class function pow(x, y: Number): Number;
    class function random(): Number;
    class function round(x: Number): Number;
    class function sin(x: Number): Number;
    class function sqrt(x: Number): Number;
    class function tan(x: Number): Number;
  end;

  Key = external class
    class property BACKSPACE: Number;  //  8
    class property CAPSLOCK : Number;  // 20
    class property CONTROL  : Number;  // 17
    class property DELETEKEY: Number;  // 46
    class property DOWN : Number;      // 40
    class property END: Number;        // 35
    class property ENTER: Number;      // 13
    class property ESCAPE: Number;     // 27
    class property HOME: Number;       // 36
    class property INSERT: Number;     // 45
    class property LEFT: Number;       // 37
    class property _listeners: TArray readonly;
    class property PGDN: Number;       // 34
    class property PGUP: Number;       // 33
    class property RIGHT: Number;      // 39
    class property SHIFT: Number;      // 16
    class property SPACE: Number;      // 32
    class property TAB: Number;        //  9
    class property UP: Number;         // 38
   { events:
     procedure onKeyDown;
     procedure onKeyUp;
   }
    class procedure addListener(listener: TObject);
    class function getAscii: Number;
    class function getCode: Number;
    class function isAccessible: Boolean;
    class function isDown(Code: Number): Boolean;
    class function isToggled(Code: Number): Boolean;
    class function removeListener(listener: TObject): Boolean;
  end;

  Selection = external class
 { events:
   procedure onSetFocus(oldfocus, newfocus: TObject);
 }
    class procedure addListener(listener: TObject);
    class function getBeginIndex: Number;
    class function getCaretIndex: Number;
    class function getEndIndex: Number;
    class function getFocus: string;
    class function removeListener(listener: TObject): Boolean;
    class function setFocus(newFocus: TObject): Boolean;  // WARNING ! the Target object MUST have a Name !
    class procedure setSelection(beginIndex, endIndex: Number);
  end;
  
  SharedObject = external class
    property Data: Variant;
    property onStatus: procedure(infoObject: TObject) of object;
    property onSync  : procedure(objArray: TArray) of object;
    procedure clear;
    function flush(minDiskSpace: Number = 0): TObject;
    class function getLocal(name: string; localPath: string = ''; secure: Boolean = False): SharedObject;
    function getSize: Number;
    function setFps(updatesPerSecond: Number): Boolean;
  end;
  
  Sound = external class
    property checkPolicyFile: Boolean;
    property duration: Number readonly;
    property id3: TObject readonly;
    property position: Number readonly;
    
    procedure onID3; virtual;
    procedure onLoad(success: Boolean); virtual;
    procedure onSoundComplete; virtual;
    
    constructor Create(target: TObject = nil);
    
    procedure attachSound(id: string);
    function getBytesLoaded: Number;
    function getBytesTotal: Number;
    function getPan: Number;
    function getTransform: TObject;
    function getVolume: Number;
    procedure loadSound(url: string; isStreaming: Boolean = False);
    procedure setPan(value: Number);
    procedure setTransform(transformObject: TObject);
    procedure setVolume(value: Number);
    procedure start(secondOffset, loops: Number = 0);
    procedure stop(linkageID: string);
  end;
 
  Stage = external class
    class property align: string;
    class property displayState: string;
    class property fullScreenSourceRect: Rectangle;
    class property height: Number readonly;
    class property scaleMode: string;
    class property showMenu: Boolean;
    class property width: Number readonly;
   { events :
    procedure onFullScreen(bFull: Boolean);
    procedure onResize;
   }
    class procedure addListener(listener: TObject);
    class function removeListener(listener: TObject): Boolean;
  end;
 
  Video = external class
    property _alpha: Number;
    property deblocking: Number;
    property _height: Number;
    property height: Number readonly;
    property _name: string;
    property _parent: MovieClip;
    property _rotation: Number;
    property smoothing: Boolean;
    property _visible: Boolean;
    property _width: Number;
    property width: Number readonly;
    property _x: Number;
    property _xmouse: Number readonly;
    property _xscale: Number;
    property _y: Number;
    property _ymouse: Number readonly;
    property _yscale: Number;
    
  //constructor Create; use {$VIDEO} instead
    
    procedure attachVideo(source: TObject);
    procedure clear;
  end;
 
  XMLNode = external class
    property attributes: TObject;//[Name: string]: string;
    property childNodes: array of XMLNode readonly;
    property firstChild: XMLNode readonly;
    property lastChild: XMLNode readonly;
    property localName: string readonly;
    property namespaceURI: string readonly;
    property nextSibling: XMLNode readonly;
    property nodeName: string;
    property nodeType: Number readonly;
    property nodeValue: string;
    property parentNode: XMLNode readonly;
    property prefix: string readonly;
    property previoussibling: XMLNode readonly;
    
    constructor Create(type: Number; value: string);
    
    procedure appendChild(newChild: XMLNode);
    function cloneNode(deep: Boolean): XMLNode;
    function getNamespaceForPrefix(prefix: string): string;
    function getPrefixForNamespace(nsURI: string): string;
    function hasChildNodes: Boolean;
    procedure insertBefore(newChild, insertPoint: XMLNode);
    procedure removeNode;
    function toString: string;
  end;
 
  XML = external class(XMLNode, XML)
    property contentType: string;
    property docTypeDecl: string;
    property idMap: TObject;
    property ignoreWhite: Boolean;
    property loaded: Boolean;
    property status: Number;
    property xmlDecl: string;
    
    procedure onData(src: string); virtual;
    procedure onHTTPStatus(httpStatus: Number); virtual;
    procedure onLoad(success: Boolean); virtual;
    
    constructor Create(text: string = '');
    
    procedure addRequestHeader(header: TObject; headerValue: string);
    function createElement(name: string): XMLNode;
    function createTextNode(value: string): XMLNode;
    function getBytesLoaded: Number;
    function getBytesTotal: Number;
    function load(url: string): Boolean;
    procedure parseXML(value: string);
    function send(url: string; target, method: string = ''): Boolean;
    procedure sendAndLoad(url: string; resultXML: XML);
  end;

// Shortcuts for Math
function cos(x: Number): Number external Math.cos;
function sin(x: Number): Number external Math.sin;
function random: Number external Math.random;
function floor(x: Number): Integer external Math.floor;
function Round(x: Number): Integer external Math.round;
function sqrt(x: Number): Number external Math.sqrt;
function atan2(x, y: Number): Number external Math.atan2;

function KeyDown(key:Number):boolean external Key.isDown;

function loadBitmap(id: string): BitmapData external flash.display.BitmapData.loadBitmap;

// global functions (tested)
function escape(expression: string): string external;
function parseInt(expression: string; radix: Number = 10): Number external;
function parseFloat(expression: string): Number external;

// Delphi like alias
function StrToInt(expression: string; radix: Number = 10): Number external 'parseInt';
function StrToFloat(expression: string): Number external 'parseFloat';

// global functions (not tested)
procedure duplicateMovieClip(target: TObject; newname: string; depth: Number) external;
function eval(expression: TObject): TObject external;
procedure fscommand(command: string; parameters: string) external;
function getProperty(my_mc, property: TObject): TObject external;
procedure loadMovie(url: string; target: TObject; method: string = '') external;
procedure loadMovieNum(url: string; level: Number; method: string = '') external;
procedure loadVariables(url: string; target: TObject; method: string = '') external;
procedure loadVariablesNum(url: string; level: Number; method: string = '') external;
function MMExecute(command: string): string external;
// specific built-in functions...
function getTimer: Number external 52; // opcode 52
function getVersion: string external '/:$version'; // global variable

const
  KEY_BACKSPACE =  8;
  KEY_CAPSLOCK  = 20;
  KEY_CONTROL   = 17;
  KEY_DELETEKEY = 46;
  KEY_DOWN      = 40;
  KEY_END       = 35;
  KEY_ENTER     = 13;
  KEY_ESCAPE    = 27;
  KEY_HOME      = 36;
  KEY_INSERT    = 45;
  KEY_LEFT      = 37;
  KEY_PGDN      = 34;
  KEY_PGUP      = 33;
  KEY_RIGHT     = 39;
  KEY_SHIFT     = 16;
  KEY_SPACE     = 32;
  KEY_TAB       =  9;
  KEY_UP        = 38;

var
 _root     : MovieClip external; // static...

implementation

end.