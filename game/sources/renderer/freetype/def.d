module renderer.freetype.def;

extern(C):

version(Windows) 
{
	const int _JBLEN = 16;
} 
else 
{
	const int _JBLEN = 10;
}

// constants

const uint FT_LOAD_DEFAULT     =   0x0;
const uint FT_LOAD_NO_SCALE    =   0x1;
const uint FT_LOAD_NO_HINTING  =   0x2;
const uint FT_LOAD_RENDER      =   0x4;
const uint FT_LOAD_NO_BITMAP   =    0x8;
const uint FT_LOAD_VERTICAL_LAYOUT =  0x10;
const uint FT_LOAD_FORCE_AUTOHINT  =  0x20;
const uint FT_LOAD_CROP_BITMAP     =  0x40;
const uint FT_LOAD_PEDANTIC        =  0x80;
const uint FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH =  0x200;
const uint FT_LOAD_NO_RECURSE      =  0x400;
const uint FT_LOAD_IGNORE_TRANSFORM = 0x800;
const uint FT_LOAD_MONOCHROME      =  0x1000;
const uint FT_LOAD_LINEAR_DESIGN   =  0x2000;

  /* temporary hack! */
const uint FT_LOAD_SBITS_ONLY = 0x4000;
const uint FT_LOAD_NO_AUTOHINT = 0x8000U;

FT_Int32 FT_LOAD_TARGET_( int x )  { return    ( cast(FT_Int32)( x & 15 ) << 16 ); }
FT_Int32 FT_LOAD_TARGET_MODE( int x ) { return  ( cast(FT_Render_Mode)( ( x >> 16 ) & 15 ) ); }
/*
#define FT_LOAD_TARGET_NORMAL     FT_LOAD_TARGET_( FT_RENDER_MODE_NORMAL )
#define FT_LOAD_TARGET_LIGHT      FT_LOAD_TARGET_( FT_RENDER_MODE_LIGHT  )
#define FT_LOAD_TARGET_MONO       FT_LOAD_TARGET_( FT_RENDER_MODE_MONO   )
#define FT_LOAD_TARGET_LCD        FT_LOAD_TARGET_( FT_RENDER_MODE_LCD    )
#define FT_LOAD_TARGET_LCD_V      FT_LOAD_TARGET_( FT_RENDER_MODE_LCD_V  )
*/

alias short 			FT_Int16;
alias ushort 			FT_UInt16;
alias int				FT_Int32;
alias uint 				FT_UInt32;
alias int				FT_Fast;
alias uint 				FT_UFast;
alias int 				FT_Pos;
alias byte 				FT_Bool;
alias short 			FT_FWord;
alias ushort 			FT_UFWord;
alias char 				FT_Char;
alias ubyte 			FT_Byte;
alias FT_Byte* 			FT_Bytes;
alias FT_UInt32 		FT_Tag;
alias char				FT_String;
alias short		 		FT_Short;
alias ushort 			FT_UShort;
alias int		 		FT_Int;
alias uint		 		FT_UInt;

version(CPU64BIT)
{
	alias long			FT_Long;
	alias ulong			FT_ULong;
} else {
	alias int			FT_Long;
	alias uint			FT_ULong;
}

alias short 			FT_F2Dot14;
alias int			 	FT_F26Dot6;
alias int			 	FT_Fixed;
alias int 				FT_Error;
alias void* 			FT_Pointer;


version(Windows)
{
}

version(linux)
{
}

version(OSX)
{
}

version(CPU64BIT)
{
	alias ulong		FT_Offset;
	alias long		FT_PtrDist;
}
else
{
	alias uint 		FT_Offset;
	alias int		  FT_PtrDist;
}

alias FT_MemoryRec* 		FT_Memory;
alias FT_StreamRec* 		FT_Stream;
alias FT_RasterRec* 		FT_Raster;
alias FT_ListNodeRec* 		FT_ListNode;
alias FT_ListRec* 			FT_List;
alias FT_LibraryRec*		FT_Library;
alias FT_ModuleRec* 		FT_Module;
alias FT_DriverRec* 		FT_Driver;
alias FT_RendererRec* 		FT_Renderer;
alias FT_FaceRec* 			FT_Face;
alias FT_SizeRec* 			FT_Size;
alias FT_GlyphSlotRec* 		FT_GlyphSlot;
alias FT_CharMapRec* 		FT_CharMap;
alias FT_Face_InternalRec* 	FT_Face_Internal;
alias FT_Size_InternalRec* 	FT_Size_Internal;
alias FT_SubGlyphRec* 		FT_SubGlyph;
alias FT_Slot_InternalRec* 	FT_Slot_Internal;

alias FT_Pointer 			FT_Module_Interface;
// alias FT_Glyph_Class_ FT_Glyph_Class;
alias FT_GlyphRec* 			FT_Glyph;
alias FT_BitmapGlyphRec* 	FT_BitmapGlyph;
alias FT_OutlineGlyphRec* 	FT_OutlineGlyph;

alias PS_FontInfoRec* 		PS_FontInfo;
alias PS_FontInfoRec 		T1_FontInfo;
alias PS_PrivateRec* 		PS_Private;
alias PS_PrivateRec 		T1_Private;
alias PS_DesignMap_ 		PS_DesignMapRec;
alias PS_DesignMap_* 		PS_DesignMap;
alias PS_DesignMapRec	 	T1_DesignMap;
alias PS_BlendRec*			PS_Blend;
alias PS_BlendRec 			T1_Blend;

alias CID_FaceDictRec*		CID_FaceDict;
alias CID_FaceDictRec 		CID_FontDict;
alias CID_FaceInfoRec*		CID_FaceInfo;
alias CID_FaceInfoRec 		CID_Info;

alias BDF_PropertyRec* 		BDF_Property;

alias FT_WinFNT_HeaderRec* 	FT_WinFNT_Header;

alias FTC_FaceIDRec_* 		FTC_FaceID;
alias FTC_FontRec* 			FTC_Font;
alias FTC_ManagerRec* 		FTC_Manager;
alias FTC_NodeRec* 			FTC_Node;
alias FTC_ScalerRec* 		FTC_Scaler;
alias FTC_CMapCacheRec* 	FTC_CMapCache;
alias FTC_ImageTypeRec* 	FTC_ImageType;
alias FTC_ImageCacheRec*	FTC_ImageCache;
alias FTC_SBitRec* 			FTC_SBit;
alias FTC_SBitCacheRec* 	FTC_SBitCache;

alias FT_Fixed 				FT_Angle;
alias FT_StrokerRec* 		FT_Stroker;

alias FTC_MruNodeRec* 		FTC_MruNode;
alias FTC_MruListRec* 		FTC_MruList;
alias FTC_MruListClassRec* 	FTC_MruListClass;
alias FTC_CacheRec* 		FTC_Cache;
alias FTC_CacheClassRec* 	FTC_CacheClass;
alias FTC_FamilyRec*		FTC_Family;
alias FTC_GNodeRec* 		FTC_GNode;
alias FTC_GQueryRec* 		FTC_GQuery;
alias FTC_GCacheRec*		FTC_GCache;
alias FTC_GCacheClassRec* 	FTC_GCacheClass;
alias FTC_INodeRec* 		FTC_INode;
alias FTC_IFamilyClassRec* 	FTC_IFamilyClass;
alias FTC_SNodeRec* 		FTC_SNode;
alias FTC_SFamilyClassRec* 	FTC_SFamilyClass;
alias FT_IncrementalRec* 	FT_Incremental;
alias FT_Incremental_MetricsRec* FT_Incremental_Metrics;
alias FT_GlyphLoaderRec* 	FT_GlyphLoader ;
alias FT_GlyphLoadRec* 		FT_GlyphLoad;
alias FT_Driver_ClassRec* 	FT_Driver_Class;
alias FT_AutoHinterRec*		FT_AutoHinter;
alias FT_AutoHinter_ServiceRec*  FT_AutoHinter_Service;
alias FT_ServiceDescRec* 	FT_ServiceDesc;
alias FT_ServiceCacheRec*  	FT_ServiceCache;
alias FT_CMapRec* 			FT_CMap;
alias FT_CMap_ClassRec* 	FT_CMap_Class;

alias SFNT_HeaderRec* 		SFNT_Header;

alias TT_TableRec* 			TT_Table;
alias TT_LongMetricsRec*  	TT_LongMetrics;

alias FT_Short 				TT_ShortMetrics;
alias TT_NameEntryRec*  	TT_NameEntry;
alias TT_NameTableRec*  	TT_NameTable;
alias TT_GaspRangeRec*  	TT_GaspRange;
alias TT_HdmxEntryRec* 		TT_HdmxEntry;
alias TT_HdmxRec*  			TT_Hdmx;
alias TT_Kern0_PairRec*  	TT_Kern0_Pair;
alias TT_SBit_MetricsRec*  	TT_SBit_Metrics;
alias TT_SBit_SmallMetricsRec*  TT_SBit_SmallMetrics;
alias TT_SBit_LineMetricsRec*  TT_SBit_LineMetrics;
alias TT_SBit_RangeRec*  	TT_SBit_Range;
alias TT_SBit_StrikeRec*  	TT_SBit_Strike;
alias TT_SBit_ComponentRec* TT_SBit_Component;
alias TT_SBit_ScaleRec*  	TT_SBit_Scale;
alias TT_Post_20Rec* 		TT_Post_20;
alias TT_Post_25Rec*  		TT_Post_25;
alias TT_Post_NamesRec*  	TT_Post_Names;
alias GX_BlendRec* 			GX_Blend;
alias TT_FaceRec* 			TT_Face;
alias TT_GlyphZoneRec*  	TT_GlyphZone;
alias TT_ExecContextRec* 	TT_ExecContext;
alias SFNT_Interface* 		SFNT_Service;
alias FT_ValidatorRec*  	FT_Validator;
alias PSH_GlobalsRec* 		PSH_Globals;
alias PSH_Globals_FuncsRec* PSH_Globals_Funcs;
alias T1_HintsRec* 			T1_Hints;
alias T1_Hints_FuncsRec* 	T1_Hints_Funcs;
alias T2_HintsRec*  		T2_Hints;
alias T2_Hints_FuncsRec*  	T2_Hints_Funcs;
alias PSHinter_Interface* 	PSHinter_Service;
// alias FT_Service_PsCMapsRec  FT_Service_PsCMapsRec; 
alias FT_Service_PsCMapsRec* FT_Service_PsCMaps; 
alias T1_EncodingRec*  		T1_Encoding;
alias T1_FontRec*  			T1_Font;
alias CID_SubrsRec*  		CID_Subrs;
alias T1_FaceRec* 			T1_Face;
alias CID_FaceRec* 			CID_Face;
alias PS_TableRec* 			PS_Table;
alias PS_Table_FuncsRec* 	PS_Table_Funcs;
alias PS_ParserRec* 		PS_Parser;
alias T1_TokenRec* 			T1_Token;
alias T1_FieldRec* 			T1_Field;
alias PS_Parser_FuncsRec* 	PS_Parser_Funcs;
alias T1_BuilderRec* 		T1_Builder;
alias T1_Builder_FuncsRec* 	T1_Builder_Funcs;
alias T1_Decoder_ZoneRec*  	T1_Decoder_Zone;
alias T1_DecoderRec* 		T1_Decoder;
alias T1_Decoder_FuncsRec* 	T1_Decoder_Funcs;
alias T1_CMap_ClassesRec* 	T1_CMap_Classes;
alias PSAux_ServiceRec*  	PSAux_Service;
alias PSAux_ServiceRec 		PSAux_Interface;
alias TT_LoaderRec* 		TT_Loader;


/********************************************************************
 *  Freetype constants
 ********************************************************************/

enum 
{ 
  FT_Mod_Err_Base  = 0, 
  FT_Mod_Err_Autofit  = 0, 
  FT_Mod_Err_BDF  = 0, 
  FT_Mod_Err_Cache  = 0, 
  FT_Mod_Err_CFF  = 0, 
  FT_Mod_Err_CID  = 0, 
  FT_Mod_Err_Gzip  = 0, 
  FT_Mod_Err_LZW  = 0, 
  FT_Mod_Err_OTvalid  = 0, 
  FT_Mod_Err_PCF  = 0, 
  FT_Mod_Err_PFR  = 0, 
  FT_Mod_Err_PSaux  = 0, 
  FT_Mod_Err_PShinter  = 0, 
  FT_Mod_Err_PSnames  = 0, 
  FT_Mod_Err_Raster  = 0, 
  FT_Mod_Err_SFNT  = 0, 
  FT_Mod_Err_Smooth  = 0, 
  FT_Mod_Err_TrueType  = 0, 
  FT_Mod_Err_Type1  = 0, 
  FT_Mod_Err_Type42  = 0, 
  FT_Mod_Err_Winfonts  = 0, 
  FT_Mod_Err_Max 
} 

enum 
{ 
  FT_Err_Ok  = 0x00, 
  FT_Err_Cannot_Open_Resource  = 0x01 + 0 , 
  FT_Err_Unknown_File_Format  = 0x02 + 0 , 
  FT_Err_Invalid_File_Format  = 0x03 + 0 , 
  FT_Err_Invalid_Version  = 0x04 + 0 , 
  FT_Err_Lower_Module_Version  = 0x05 + 0 , 
  FT_Err_Invalid_Argument  = 0x06 + 0 , 
  FT_Err_Unimplemented_Feature  = 0x07 + 0 , 
  FT_Err_Invalid_Table  = 0x08 + 0 , 
  FT_Err_Invalid_Offset  = 0x09 + 0 , 
  FT_Err_Invalid_Glyph_Index  = 0x10 + 0 , 
  FT_Err_Invalid_Character_Code  = 0x11 + 0 , 
  FT_Err_Invalid_Glyph_Format  = 0x12 + 0 , 
  FT_Err_Cannot_Render_Glyph  = 0x13 + 0 , 
  FT_Err_Invalid_Outline  = 0x14 + 0 , 
  FT_Err_Invalid_Composite  = 0x15 + 0 , 
  FT_Err_Too_Many_Hints  = 0x16 + 0 , 
  FT_Err_Invalid_Pixel_Size  = 0x17 + 0 , 
  FT_Err_Invalid_Handle  = 0x20 + 0 , 
  FT_Err_Invalid_Library_Handle  = 0x21 + 0 , 
  FT_Err_Invalid_Driver_Handle  = 0x22 + 0 , 
  FT_Err_Invalid_Face_Handle  = 0x23 + 0 , 
  FT_Err_Invalid_Size_Handle  = 0x24 + 0 , 
  FT_Err_Invalid_Slot_Handle  = 0x25 + 0 , 
  FT_Err_Invalid_CharMap_Handle  = 0x26 + 0 , 
  FT_Err_Invalid_Cache_Handle  = 0x27 + 0 , 
  FT_Err_Invalid_Stream_Handle  = 0x28 + 0 , 
  FT_Err_Too_Many_Drivers  = 0x30 + 0 , 
  FT_Err_Too_Many_Extensions  = 0x31 + 0 , 
  FT_Err_Out_Of_Memory  = 0x40 + 0 , 
  FT_Err_Unlisted_Object  = 0x41 + 0 , 
  FT_Err_Cannot_Open_Stream  = 0x51 + 0 , 
  FT_Err_Invalid_Stream_Seek  = 0x52 + 0 , 
  FT_Err_Invalid_Stream_Skip  = 0x53 + 0 , 
  FT_Err_Invalid_Stream_Read  = 0x54 + 0 , 
  FT_Err_Invalid_Stream_Operation  = 0x55 + 0 , 
  FT_Err_Invalid_Frame_Operation  = 0x56 + 0 , 
  FT_Err_Nested_Frame_Access  = 0x57 + 0 , 
  FT_Err_Invalid_Frame_Read  = 0x58 + 0 , 
  FT_Err_Raster_Uninitialized  = 0x60 + 0 , 
  FT_Err_Raster_Corrupted  = 0x61 + 0 , 
  FT_Err_Raster_Overflow  = 0x62 + 0 , 
  FT_Err_Raster_Negative_Height  = 0x63 + 0 , 
  FT_Err_Too_Many_Caches  = 0x70 + 0 , 
  FT_Err_Invalid_Opcode  = 0x80 + 0 , 
  FT_Err_Too_Few_Arguments  = 0x81 + 0 , 
  FT_Err_Stack_Overflow  = 0x82 + 0 , 
  FT_Err_Code_Overflow  = 0x83 + 0 , 
  FT_Err_Bad_Argument  = 0x84 + 0 , 
  FT_Err_Divide_By_Zero  = 0x85 + 0 , 
  FT_Err_Invalid_Reference  = 0x86 + 0 , 
  FT_Err_Debug_OpCode  = 0x87 + 0 , 
  FT_Err_ENDF_In_Exec_Stream  = 0x88 + 0 , 
  FT_Err_Nested_DEFS  = 0x89 + 0 , 
  FT_Err_Invalid_CodeRange  = 0x8A + 0 , 
  FT_Err_Execution_Too_Long  = 0x8B + 0 , 
  FT_Err_Too_Many_Function_Defs  = 0x8C + 0 , 
  FT_Err_Too_Many_Instruction_Defs  = 0x8D + 0 , 
  FT_Err_Table_Missing  = 0x8E + 0 , 
  FT_Err_Horiz_Header_Missing  = 0x8F + 0 , 
  FT_Err_Locations_Missing  = 0x90 + 0 , 
  FT_Err_Name_Table_Missing  = 0x91 + 0 , 
  FT_Err_CMap_Table_Missing  = 0x92 + 0 , 
  FT_Err_Hmtx_Table_Missing  = 0x93 + 0 , 
  FT_Err_Post_Table_Missing  = 0x94 + 0 , 
  FT_Err_Invalid_Horiz_Metrics  = 0x95 + 0 , 
  FT_Err_Invalid_CharMap_Format  = 0x96 + 0 , 
  FT_Err_Invalid_PPem  = 0x97 + 0 , 
  FT_Err_Invalid_Vert_Metrics  = 0x98 + 0 , 
  FT_Err_Could_Not_Find_Context  = 0x99 + 0 , 
  FT_Err_Invalid_Post_Table_Format  = 0x9A + 0 , 
  FT_Err_Invalid_Post_Table  = 0x9B + 0 , 
  FT_Err_Syntax_Error  = 0xA0 + 0 , 
  FT_Err_Stack_Underflow  = 0xA1 + 0 , 
  FT_Err_Ignore  = 0xA2 + 0 , 
  FT_Err_Missing_Startfont_Field  = 0xB0 + 0 , 
  FT_Err_Missing_Font_Field  = 0xB1 + 0 , 
  FT_Err_Missing_Size_Field  = 0xB2 + 0 , 
  FT_Err_Missing_Chars_Field  = 0xB3 + 0 , 
  FT_Err_Missing_Startchar_Field  = 0xB4 + 0 , 
  FT_Err_Missing_Encoding_Field  = 0xB5 + 0 , 
  FT_Err_Missing_Bbx_Field  = 0xB6 + 0 , 
  FT_Err_Max  
}

enum FT_Render_Mode
{
 FT_RENDER_MODE_NORMAL = 0,
 FT_RENDER_MODE_LIGHT,
 FT_RENDER_MODE_MONO,
 FT_RENDER_MODE_LCD,
 FT_RENDER_MODE_LCD_V,
 FT_RENDER_MODE_MAX
}

enum FT_Kerning_Mode
{
 FT_KERNING_DEFAULT = 0,
 FT_KERNING_UNFITTED,
 FT_KERNING_UNSCALED
}


enum FT_Pixel_Mode 
{
 FT_PIXEL_MODE_NONE = 0,
 FT_PIXEL_MODE_MONO,
 FT_PIXEL_MODE_GRAY,
 FT_PIXEL_MODE_GRAY2,
 FT_PIXEL_MODE_GRAY4,
 FT_PIXEL_MODE_LCD,
 FT_PIXEL_MODE_LCD_V,
 FT_PIXEL_MODE_MAX
}

enum FT_Glyph_Format 
{
  FT_GLYPH_FORMAT_NONE = ( ( cast(uint)0 << 24 ) | ( cast(uint)0 << 16 ) | ( cast(uint)0 << 8 ) | cast(uint)0 ) ,
  FT_GLYPH_FORMAT_COMPOSITE = ( ( cast(uint)'c' << 24 ) | ( cast(uint)'o' << 16 ) | ( cast(uint)'m' << 8 ) | cast(uint)'p' ) ,
  FT_GLYPH_FORMAT_BITMAP = ( ( cast(uint)'b' << 24 ) | ( cast(uint)'i' << 16 ) | ( cast(uint)'t' << 8 ) | cast(uint)'s' ) ,
  FT_GLYPH_FORMAT_OUTLINE = ( ( cast(uint)'o' << 24 ) | ( cast(uint)'u' << 16 ) | ( cast(uint)'t' << 8 ) | cast(uint)'l' ) ,
  FT_GLYPH_FORMAT_PLOTTER = ( ( cast(uint)'p' << 24 ) | ( cast(uint)'l' << 16 ) | ( cast(uint)'o' << 8 ) | cast(uint)'t' ) 
}

enum FT_Encoding
{
  FT_ENCODING_NONE = ( ( cast(FT_UInt32)(0) << 24 ) | ( cast(FT_UInt32)(0) << 16 ) | ( cast(FT_UInt32)(0) << 8 ) | cast(FT_UInt32)(0) ) ,
  FT_ENCODING_MS_SYMBOL = ( ( cast(FT_UInt32)('s') << 24 ) | ( cast(FT_UInt32)('y') << 16 ) | ( cast(FT_UInt32)('m') << 8 ) | cast(FT_UInt32)('b') ) ,
  FT_ENCODING_UNICODE = ( ( cast(FT_UInt32)('u') << 24 ) | ( cast(FT_UInt32)('n') << 16 ) | ( cast(FT_UInt32)('i') << 8 ) | cast(FT_UInt32)('c') ) ,
  FT_ENCODING_SJIS = ( ( cast(FT_UInt32)('s') << 24 ) | ( cast(FT_UInt32)('j') << 16 ) | ( cast(FT_UInt32)('i') << 8 ) | cast(FT_UInt32)('s') ) ,
  FT_ENCODING_GB2312 = ( ( cast(FT_UInt32)('g') << 24 ) | ( cast(FT_UInt32)('b') << 16 ) | ( cast(FT_UInt32)(' ') << 8 ) | cast(FT_UInt32)(' ') ) ,
  FT_ENCODING_BIG5 = ( ( cast(FT_UInt32)('b') << 24 ) | ( cast(FT_UInt32)('i') << 16 ) | ( cast(FT_UInt32)('g') << 8 ) | cast(FT_UInt32)('5') ) ,
  FT_ENCODING_WANSUNG = ( ( cast(FT_UInt32)('w') << 24 ) | ( cast(FT_UInt32)('a') << 16 ) | ( cast(FT_UInt32)('n') << 8 ) | cast(FT_UInt32)('s') ) ,
  FT_ENCODING_JOHAB = ( ( cast(FT_UInt32)('j') << 24 ) | ( cast(FT_UInt32)('o') << 16 ) | ( cast(FT_UInt32)('h') << 8 ) | cast(FT_UInt32)('a') ) ,
  FT_ENCODING_MS_SJIS = FT_ENCODING_SJIS,
  FT_ENCODING_MS_GB2312 = FT_ENCODING_GB2312,
  FT_ENCODING_MS_BIG5 = FT_ENCODING_BIG5,
  FT_ENCODING_MS_WANSUNG = FT_ENCODING_WANSUNG,
  FT_ENCODING_MS_JOHAB = FT_ENCODING_JOHAB,
  FT_ENCODING_ADOBE_STANDARD = ( ( cast(FT_UInt32)('A') << 24 ) | ( cast(FT_UInt32)('D') << 16 ) | ( cast(FT_UInt32)('O') << 8 ) | cast(FT_UInt32)('B') ) ,
  FT_ENCODING_ADOBE_EXPERT = ( ( cast(FT_UInt32)('A') << 24 ) | ( cast(FT_UInt32)('D') << 16 ) | ( cast(FT_UInt32)('B') << 8 ) | cast(FT_UInt32)('E') ) ,
  FT_ENCODING_ADOBE_CUSTOM = ( ( cast(FT_UInt32)('A') << 24 ) | ( cast(FT_UInt32)('D') << 16 ) | ( cast(FT_UInt32)('B') << 8 ) | cast(FT_UInt32)('C') ) ,
  FT_ENCODING_ADOBE_LATIN_1 = ( ( cast(FT_UInt32)('l') << 24 ) | ( cast(FT_UInt32)('a') << 16 ) | ( cast(FT_UInt32)('t') << 8 ) | cast(FT_UInt32)('1') ) ,
  FT_ENCODING_OLD_LATIN_2 = ( ( cast(FT_UInt32)('l') << 24 ) | ( cast(FT_UInt32)('a') << 16 ) | ( cast(FT_UInt32)('t') << 8 ) | cast(FT_UInt32)('2') ) ,
  FT_ENCODING_APPLE_ROMAN = ( ( cast(FT_UInt32)('a') << 24 ) | ( cast(FT_UInt32)('r') << 16 ) | ( cast(FT_UInt32)('m') << 8 ) | cast(FT_UInt32)('n') ) 
}

enum FT_Orientation
{
 FT_ORIENTATION_TRUETYPE = 0,
 FT_ORIENTATION_POSTSCRIPT = 1,
 FT_ORIENTATION_FILL_RIGHT = FT_ORIENTATION_TRUETYPE,
 FT_ORIENTATION_FILL_LEFT = FT_ORIENTATION_POSTSCRIPT
}

enum FT_Glyph_BBox_Mode
{
 FT_GLYPH_BBOX_UNSCALED = 0,
 FT_GLYPH_BBOX_SUBPIXELS = 0,
 FT_GLYPH_BBOX_GRIDFIT = 1,
 FT_GLYPH_BBOX_TRUNCATE = 2,
 FT_GLYPH_BBOX_PIXELS = 3
}

enum T1_Blend_Flags
 {
 T1_BLEND_UNDERLINE_POSITION = 0,
 T1_BLEND_UNDERLINE_THICKNESS,
 T1_BLEND_ITALIC_ANGLE,
 T1_BLEND_BLUE_VALUES,
 T1_BLEND_OTHER_BLUES,
 T1_BLEND_STANDARD_WIDTH,
 T1_BLEND_STANDARD_HEIGHT,
 T1_BLEND_STEM_SNAP_WIDTHS,
 T1_BLEND_STEM_SNAP_HEIGHTS,
 T1_BLEND_BLUE_SCALE,
 T1_BLEND_BLUE_SHIFT,
 T1_BLEND_FAMILY_BLUES,
 T1_BLEND_FAMILY_OTHER_BLUES,
 T1_BLEND_FORCE_BOLD,
 T1_BLEND_MAX
}

enum FT_Sfnt_Tag
{
 ft_sfnt_head = 0,
 ft_sfnt_maxp = 1,
 ft_sfnt_os2 = 2,
 ft_sfnt_hhea = 3,
 ft_sfnt_vhea = 4,
 ft_sfnt_post = 5,
 ft_sfnt_pclt = 6,
 sfnt_max
}
 
enum BDF_PropertyType
{
 BDF_PROPERTY_TYPE_NONE = 0,
 BDF_PROPERTY_TYPE_ATOM = 1,
 BDF_PROPERTY_TYPE_INTEGER = 2,
 BDF_PROPERTY_TYPE_CARDINAL = 3
}

enum FT_Stroker_LineJoin
{
 FT_STROKER_LINEJOIN_ROUND = 0,
 FT_STROKER_LINEJOIN_BEVEL,
 FT_STROKER_LINEJOIN_MITER
}

enum FT_Stroker_LineCap
{
 FT_STROKER_LINECAP_BUTT = 0,
 FT_STROKER_LINECAP_ROUND,
 FT_STROKER_LINECAP_SQUARE
}

enum FT_StrokerBorder
{
 FT_STROKER_BORDER_LEFT = 0,
 FT_STROKER_BORDER_RIGHT
}

enum FT_Frame_Op
{
 ft_frame_end = 0,
 ft_frame_start =  ((1  << 2 ) | ( 0 << 1 ) | 0 ) ,
 ft_frame_byte =  ( ( 2  << 2  ) | ( 0 << 1 ) | 0 ) ,
 ft_frame_schar =  ( ( 2  << 2  ) | ( 0 << 1 ) | 1 ) ,
 ft_frame_ushort_be =  ( ( 3  << 2  ) | ( 0 << 1 ) | 0 ) ,
 ft_frame_short_be =  ( ( 3  << 2  ) | ( 0 << 1 ) | 1 ) ,
 ft_frame_ushort_le =  ( ( 3  << 2  ) | ( 1 << 1 ) | 0 ) ,
 ft_frame_short_le =  ( ( 3  << 2  ) | ( 1 << 1 ) | 1 ) ,
 ft_frame_ulong_be =  ( ( 4  << 2  ) | ( 0 << 1 ) | 0 ) ,
 ft_frame_long_be =  ( ( 4  << 2  ) | ( 0 << 1 ) | 1 ) ,
 ft_frame_ulong_le =  ( ( 4  << 2  ) | ( 1 << 1 ) | 0 ) ,
 ft_frame_long_le =  ( ( 4  << 2  ) | ( 1 << 1 ) | 1 ) ,
 ft_frame_uoff3_be =  ( ( 5  << 2  ) | ( 0 << 1 ) | 0 ) ,
 ft_frame_off3_be =  ( ( 5  << 2  ) | ( 0 << 1 ) | 1 ) ,
 ft_frame_uoff3_le =  ( ( 5  << 2  ) | ( 1 << 1 ) | 0 ) ,
 ft_frame_off3_le =  ( ( 5  << 2  ) | ( 1 << 1 ) | 1 ) ,
 ft_frame_bytes =  ( ( 6  << 2  ) | ( 0 << 1 ) | 0 ) ,
 ft_frame_skip =  ( ( 6  << 2  ) | ( 0 << 1 ) | 1 ) 
}

enum FT_ValidationLevel
{
 FT_VALIDATE_DEFAULT = 0,
 FT_VALIDATE_TIGHT,
 FT_VALIDATE_PARANOID
}

enum T1_EncodingType
{
 T1_ENCODING_TYPE_NONE = 0,
 T1_ENCODING_TYPE_ARRAY,
 T1_ENCODING_TYPE_STANDARD,
 T1_ENCODING_TYPE_ISOLATIN1,
 T1_ENCODING_TYPE_EXPERT
}

enum T1_TokenType
{
 T1_TOKEN_TYPE_NONE = 0,
 T1_TOKEN_TYPE_ANY,
 T1_TOKEN_TYPE_STRING,
 T1_TOKEN_TYPE_ARRAY,
 T1_TOKEN_TYPE_MAX
}

enum T1_FieldType
{
 T1_FIELD_TYPE_NONE = 0,
 T1_FIELD_TYPE_BOOL,
 T1_FIELD_TYPE_INTEGER,
 T1_FIELD_TYPE_FIXED,
 T1_FIELD_TYPE_FIXED_1000,
 T1_FIELD_TYPE_STRING,
 T1_FIELD_TYPE_KEY,
 T1_FIELD_TYPE_BBOX,
 T1_FIELD_TYPE_INTEGER_ARRAY,
 T1_FIELD_TYPE_FIXED_ARRAY,
 T1_FIELD_TYPE_CALLBACK,
 T1_FIELD_TYPE_MAX
}

enum T1_FieldLocation
{
 T1_FIELD_LOCATION_CID_INFO,
 T1_FIELD_LOCATION_FONT_DICT,
 T1_FIELD_LOCATION_FONT_INFO,
 T1_FIELD_LOCATION_PRIVATE,
 T1_FIELD_LOCATION_BBOX,
 T1_FIELD_LOCATION_MAX
}

enum T1_ParseState
{
 T1_Parse_Start,
 T1_Parse_Have_Width,
 T1_Parse_Have_Moveto,
 T1_Parse_Have_Path
}

/********************************************************************
 * Freetype structures
 ********************************************************************/

// Opaque types
struct FT_RasterRec;
//struct FT_LibraryRec;
//struct FT_ModuleRec;
//struct FT_DriverRec;
//struct FT_RendererRec;
//struct FT_Face_InternalRec;
struct FT_Size_InternalRec;
//struct FT_SubGlyphRec;
//struct FT_Slot_InternalRec;

struct FTC_FaceIDRec_;
struct FTC_CMapCacheRec;
struct FTC_ImageCacheRec;
struct FTC_SBitCacheRec;
struct FT_StrokerRec;
struct FT_IncrementalRec;
struct FT_AutoHinterRec;
struct GX_BlendRec;
struct TT_ExecContextRec;
struct PSH_GlobalsRec;
struct T1_HintsRec;
struct T2_HintsRec;

union FT_StreamDesc 
{
 int value;
 void* pointer;
}

struct FT_MemoryRec 
{
 void* user;
 FT_Alloc_Func alloc;
 FT_Free_Func free;
 FT_Realloc_Func realloc;
}

struct FT_StreamRec
{
 ubyte* base;
 uint size;
 uint pos;
 FT_StreamDesc descriptor;
 FT_StreamDesc pathname;
 FT_Stream_IoFunc read;
 FT_Stream_CloseFunc close;
 FT_Memory memory;
 ubyte* cursor;
 ubyte* limit;
}

struct FT_Vector 
{
 FT_Pos x;
 FT_Pos y;
}

struct FT_BBox 
{
 FT_Pos xMin, yMin;
 FT_Pos xMax, yMax;
}

struct FT_Bitmap
{
 int rows;
 int width;
 int pitch;
 ubyte* buffer;
 short num_grays;
 byte pixel_mode;
 byte palette_mode;
 void* palette;
}

struct FT_Outline
{
 short n_contours;
 short n_points;
 FT_Vector* points;
 byte* tags;
 short* contours;
 int flags;
}

struct FT_Outline_Funcs
{
 FT_Outline_MoveToFunc move_to;
 FT_Outline_LineToFunc line_to;
 FT_Outline_ConicToFunc conic_to;
 FT_Outline_CubicToFunc cubic_to;
 int shift;
 FT_Pos delta;
}

struct FT_Span 
{
 short x;
 ushort len;
 ubyte coverage;
}

struct FT_Raster_Params
{
 const FT_Bitmap* target;
 const void* source;
 int flags;
 FT_SpanFunc gray_spans;
 FT_SpanFunc black_spans;
 FT_Raster_BitTest_Func bit_test;
 FT_Raster_BitSet_Func bit_set;
 void* user;
 FT_BBox clip_box;
}

struct FT_Raster_Funcs
{
 FT_Glyph_Format glyph_format;
 FT_Raster_NewFunc raster_new;
 FT_Raster_ResetFunc raster_reset;
 FT_Raster_SetModeFunc raster_set_mode;
 FT_Raster_RenderFunc raster_render;
 FT_Raster_DoneFunc raster_done;
}

struct FT_UnitVector
{
 FT_F2Dot14 x;
 FT_F2Dot14 y;
}

struct FT_Matrix
{
 FT_Fixed xx, xy;
 FT_Fixed yx, yy;
}

struct FT_Data
{
 const FT_Byte* pointer;
 FT_Int length;
}

struct FT_Generic
{
 void* data;
 FT_Generic_Finalizer finalizer;
}

struct FT_ListNodeRec
{
 FT_ListNode prev;
 FT_ListNode next;
 void* data;
}

struct FT_ListRec
{
 FT_ListNode head;
 FT_ListNode tail;
}

struct FT_Glyph_Metrics
{
 FT_Pos width;
 FT_Pos height;
 FT_Pos horiBearingX;
 FT_Pos horiBearingY;
 FT_Pos horiAdvance;
 FT_Pos vertBearingX;
 FT_Pos vertBearingY;
 FT_Pos vertAdvance;
}

struct FT_Bitmap_Size
{
 FT_Short height;
 FT_Short width;
 FT_Pos size;
 FT_Pos x_ppem;
 FT_Pos y_ppem;
}

struct FT_CharMapRec
{
 FT_Face face;
 FT_Encoding encoding;
 FT_UShort platform_id;
 FT_UShort encoding_id;
}

struct FT_FaceRec
{
 FT_Long num_faces;
 FT_Long face_index;
 FT_Long face_flags;
 FT_Long style_flags;
 FT_Long num_glyphs;
 FT_String* family_name;
 FT_String* style_name;
 FT_Int num_fixed_sizes;
 FT_Bitmap_Size* available_sizes;
 FT_Int num_charmaps;
 FT_CharMap* charmaps;
 FT_Generic generic;
 FT_BBox bbox;
 FT_UShort units_per_EM;
 FT_Short ascender;
 FT_Short descender;
 FT_Short height;
 FT_Short max_advance_width;
 FT_Short max_advance_height;
 FT_Short underline_position;
 FT_Short underline_thickness;
 FT_GlyphSlot glyph;
 FT_Size size;
 FT_CharMap charmap;
 FT_Driver driver;
 FT_Memory memory;
 FT_Stream stream;
 FT_ListRec sizes_list;
 FT_Generic autohint;
 void* extensions;
 FT_Face_Internal internal;
}

struct FT_Size_Metrics
{
 FT_UShort x_ppem;
 FT_UShort y_ppem;

 FT_Fixed x_scale;
 FT_Fixed y_scale;

 FT_Pos ascender;
 FT_Pos descender;
 FT_Pos height;
 FT_Pos max_advance;
}

struct FT_SizeRec
{
 FT_Face face;
 FT_Generic generic;
 FT_Size_Metrics metrics;
 FT_Size_Internal internal;
}

struct FT_GlyphSlotRec
{
 FT_Library library;
 FT_Face face;
 FT_GlyphSlot next;
 FT_UInt reserved;
 FT_Generic generic;
 FT_Glyph_Metrics metrics;
 FT_Fixed linearHoriAdvance;
 FT_Fixed linearVertAdvance;
 FT_Vector advance;
 FT_Glyph_Format format;
 FT_Bitmap bitmap;
 FT_Int bitmap_left;
 FT_Int bitmap_top;
 FT_Outline outline;
 FT_UInt num_subglyphs;
 FT_SubGlyph subglyphs;
 void* control_data;
 int control_len;
 FT_Pos lsb_delta;
 FT_Pos rsb_delta;
 void* other;
 FT_Slot_Internal internal;
}

struct FT_Parameter
{
 FT_ULong tag;
 FT_Pointer data;
}

struct FT_Open_Args
{
 FT_UInt flags;
 const FT_Byte* memory_base;
 FT_Long memory_size;
 FT_String* pathname;
 FT_Stream stream;
 FT_Module driver;
 FT_Int num_params;
 FT_Parameter* params;
}

struct FT_Module_Class
{
 FT_ULong module_flags;
 FT_Long module_size;
 FT_String* module_name;
 FT_Fixed module_version;
 FT_Fixed module_requires;
 void* module_interface;
 FT_Module_Constructor module_init;
 FT_Module_Destructor module_done;
 FT_Module_Requester get_interface;
}

struct FT_GlyphRec
{
 FT_Library library;
 FT_Glyph_Class* clazz;
 FT_Glyph_Format format;
 FT_Vector advance;
}

struct FT_BitmapGlyphRec
{
 FT_GlyphRec root;
 FT_Int left;
 FT_Int top;
 FT_Bitmap bitmap;
}

struct FT_OutlineGlyphRec
{
 FT_GlyphRec root;
 FT_Outline outline;
}

struct FT_Glyph_Class
{
 FT_Long glyph_size;
 FT_Glyph_Format glyph_format;
 FT_Glyph_InitFunc glyph_init;
 FT_Glyph_DoneFunc glyph_done;
 FT_Glyph_CopyFunc glyph_copy;
 FT_Glyph_TransformFunc glyph_transform;
 FT_Glyph_GetBBoxFunc glyph_bbox;
 FT_Glyph_PrepareFunc glyph_prepare;
}

struct FT_Renderer_Class
{
 FT_Module_Class root;
 FT_Glyph_Format glyph_format;
 FT_Renderer_RenderFunc render_glyph;
 FT_Renderer_TransformFunc transform_glyph;
 FT_Renderer_GetCBoxFunc get_glyph_cbox;
 FT_Renderer_SetModeFunc set_mode;
 FT_Raster_Funcs* raster_class;
}
 
struct PS_FontInfoRec
 {
 FT_String* _version;
 FT_String* notice;
 FT_String* full_name;
 FT_String* family_name;
 FT_String* weight;
 FT_Long italic_angle;
 FT_Bool is_fixed_pitch;
 FT_Short underline_position;
 FT_UShort underline_thickness;
} 

struct PS_PrivateRec
{
 FT_Int unique_id;
 FT_Int lenIV;
 FT_Byte num_blue_values;
 FT_Byte num_other_blues;
 FT_Byte num_family_blues;
 FT_Byte num_family_other_blues;
 FT_Short[14] blue_values;
 FT_Short[10] other_blues;
 FT_Short[14] family_blues;
 FT_Short[10] family_other_blues;
 FT_Fixed blue_scale;
 FT_Int blue_shift;
 FT_Int blue_fuzz;
 FT_UShort[1] standard_width;
 FT_UShort[1] standard_height;
 FT_Byte num_snap_widths;
 FT_Byte num_snap_heights;
 FT_Bool force_bold;
 FT_Bool round_stem_up;
 FT_Short[13] snap_widths;
 FT_Short[13] snap_heights;
 FT_Fixed expansion_factor;
 FT_Long language_group;
 FT_Long password;
 FT_Short[2] min_feature;
} 

struct PS_DesignMap_
{
 FT_Byte num_points;
 FT_Long* design_points;
 FT_Fixed* blend_points;
} 

struct PS_BlendRec
{
 FT_UInt num_designs;
 FT_UInt num_axis;
 FT_String*[4] axis_names;
 FT_Fixed*[16] design_pos;
 PS_DesignMapRec[4] design_map;
 FT_Fixed* weight_vector;
 FT_Fixed* default_weight_vector;
 PS_FontInfo[16+1] font_infos;
 PS_Private[16+1] privates;
 FT_ULong blend_bitflags;
 FT_BBox*[16+1] bboxes;
}

struct CID_FaceDictRec
{
 PS_PrivateRec private_dict;
 FT_UInt len_buildchar;
 FT_Fixed forcebold_threshold;
 FT_Pos stroke_width;
 FT_Fixed expansion_factor;
 FT_Byte paint_type;
 FT_Byte font_type;
 FT_Matrix font_matrix;
 FT_Vector font_offset;
 FT_UInt num_subrs;
 FT_ULong subrmap_offset;
 FT_Int sd_bytes;
} 

struct CID_FaceInfoRec
 {
 FT_String* cid_font_name;
 FT_Fixed cid_version;
 FT_Int cid_font_type;
 FT_String* registry;
 FT_String* ordering;
 FT_Int supplement;
 PS_FontInfoRec font_info;
 FT_BBox font_bbox;
 FT_ULong uid_base;
 FT_Int num_xuid;
 FT_ULong[16] xuid;
 FT_ULong cidmap_offset;
 FT_Int fd_bytes;
 FT_Int gd_bytes;
 FT_ULong cid_count;
 FT_Int num_dicts;
 CID_FaceDict font_dicts;
 FT_ULong data_offset;
} 

struct TT_Header
{
 FT_Fixed Table_Version;
 FT_Fixed Font_Revision;
 FT_Long CheckSum_Adjust;
 FT_Long Magic_Number;
 FT_UShort Flags;
 FT_UShort Units_Per_EM;
 FT_Long[2] Created;
 FT_Long[2] Modified;
 FT_Short xMin;
 FT_Short yMin;
 FT_Short xMax;
 FT_Short yMax;
 FT_UShort Mac_Style;
 FT_UShort Lowest_Rec_PPEM;
 FT_Short Font_Direction;
 FT_Short Index_To_Loc_Format;
 FT_Short Glyph_Data_Format;
}

struct TT_HoriHeader
{
 FT_Fixed Version;
 FT_Short Ascender;
 FT_Short Descender;
 FT_Short Line_Gap;
 FT_UShort advance_Width_Max;
 FT_Short min_Left_Side_Bearing;
 FT_Short min_Right_Side_Bearing;
 FT_Short xMax_Extent;
 FT_Short caret_Slope_Rise;
 FT_Short caret_Slope_Run;
 FT_Short caret_Offset;
 FT_Short[4] Reserved;
 FT_Short metric_Data_Format;
 FT_UShort number_Of_HMetrics;
 void* long_metrics;
 void* short_metrics;
}

struct TT_VertHeader
{
 FT_Fixed Version;
 FT_Short Ascender;
 FT_Short Descender;
 FT_Short Line_Gap;
 FT_UShort advance_Height_Max;
 FT_Short min_Top_Side_Bearing;
 FT_Short min_Bottom_Side_Bearing;
 FT_Short yMax_Extent;
 FT_Short caret_Slope_Rise;
 FT_Short caret_Slope_Run;
 FT_Short caret_Offset;
 FT_Short[4] Reserved;
 FT_Short metric_Data_Format;
 FT_UShort number_Of_VMetrics;
 void* long_metrics;
 void* short_metrics;
}

struct TT_OS2
{
 FT_UShort _version;
 FT_Short xAvgCharWidth;
 FT_UShort usWeightClass;
 FT_UShort usWidthClass;
 FT_Short fsType;
 FT_Short ySubscriptXSize;
 FT_Short ySubscriptYSize;
 FT_Short ySubscriptXOffset;
 FT_Short ySubscriptYOffset;
 FT_Short ySuperscriptXSize;
 FT_Short ySuperscriptYSize;
 FT_Short ySuperscriptXOffset;
 FT_Short ySuperscriptYOffset;
 FT_Short yStrikeoutSize;
 FT_Short yStrikeoutPosition;
 FT_Short sFamilyClass;
 FT_Byte[10] panose;
 FT_ULong ulUnicodeRange1;
 FT_ULong ulUnicodeRange2;
 FT_ULong ulUnicodeRange3;
 FT_ULong ulUnicodeRange4;
 FT_Char[4] achVendID;
 FT_UShort fsSelection;
 FT_UShort usFirstCharIndex;
 FT_UShort usLastCharIndex;
 FT_Short sTypoAscender;
 FT_Short sTypoDescender;
 FT_Short sTypoLineGap;
 FT_UShort usWinAscent;
 FT_UShort usWinDescent;
 FT_ULong ulCodePageRange1;
 FT_ULong ulCodePageRange2;
 FT_Short sxHeight;
 FT_Short sCapHeight;
 FT_UShort usDefaultChar;
 FT_UShort usBreakChar;
 FT_UShort usMaxContext;
}

struct TT_Postscript
{
 FT_Fixed FormatType;
 FT_Fixed italicAngle;
 FT_Short underlinePosition;
 FT_Short underlineThickness;
 FT_ULong isFixedPitch;
 FT_ULong minMemType42;
 FT_ULong maxMemType42;
 FT_ULong minMemType1;
 FT_ULong maxMemType1;
}

struct TT_PCLT
{
 FT_Fixed Version;
 FT_ULong FontNumber;
 FT_UShort Pitch;
 FT_UShort xHeight;
 FT_UShort Style;
 FT_UShort TypeFamily;
 FT_UShort CapHeight;
 FT_UShort SymbolSet;
 FT_Char[16] TypeFace;
 FT_Char[8] CharacterComplement;
 FT_Char[6] FileName;
 FT_Char StrokeWeight;
 FT_Char WidthType;
 FT_Byte SerifStyle;
 FT_Byte Reserved;
}

struct TT_MaxProfile
{
 FT_Fixed _version;
 FT_UShort numGlyphs;
 FT_UShort maxPoints;
 FT_UShort maxContours;
 FT_UShort maxCompositePoints;
 FT_UShort maxCompositeContours;
 FT_UShort maxZones;
 FT_UShort maxTwilightPoints;
 FT_UShort maxStorage;
 FT_UShort maxFunctionDefs;
 FT_UShort maxInstructionDefs;
 FT_UShort maxStackElements;
 FT_UShort maxSizeOfInstructions;
 FT_UShort maxComponentElements;
 FT_UShort maxComponentDepth;
}


struct BDF_PropertyRec
{
 BDF_PropertyType type;
 union u
 {
   char* atom;
   FT_Int32 integer;
   FT_UInt32 cardinal;
 }
}

struct FT_WinFNT_HeaderRec
{
 FT_UShort _version;
 FT_ULong file_size;
 FT_Byte[60] copyright;
 FT_UShort file_type;
 FT_UShort nominal_point_size;
 FT_UShort vertical_resolution;
 FT_UShort horizontal_resolution;
 FT_UShort ascent;
 FT_UShort internal_leading;
 FT_UShort external_leading;
 FT_Byte italic;
 FT_Byte underline;
 FT_Byte strike_out;
 FT_UShort weight;
 FT_Byte charset;
 FT_UShort pixel_width;
 FT_UShort pixel_height;
 FT_Byte pitch_and_family;
 FT_UShort avg_width;
 FT_UShort max_width;
 FT_Byte first_char;
 FT_Byte last_char;
 FT_Byte default_char;
 FT_Byte break_char;
 FT_UShort bytes_per_row;
 FT_ULong device_offset;
 FT_ULong face_name_offset;
 FT_ULong bits_pointer;
 FT_ULong bits_offset;
 FT_Byte reserved;
 FT_ULong flags;
 FT_UShort A_space;
 FT_UShort B_space;
 FT_UShort C_space;
 FT_UShort color_table_offset;
 FT_ULong[4] reserved1;
} 

struct FTC_FontRec
{
 FTC_FaceID face_id;
 FT_UShort pix_width;
 FT_UShort pix_height;
}

struct FTC_ScalerRec
{
 FTC_FaceID face_id;
 FT_UInt width;
 FT_UInt height;
 FT_Int pixel;
 FT_UInt x_res;
 FT_UInt y_res;
} 

struct FTC_ImageTypeRec
{
 FTC_FaceID face_id;
 FT_Int width;
 FT_Int height;
 FT_Int32 flags;
}

struct FTC_SBitRec
{
 FT_Byte width;
 FT_Byte height;
 FT_Char left;
 FT_Char top;
 FT_Byte format;
 FT_Byte max_grays;
 FT_Short pitch;
 FT_Char xadvance;
 FT_Char yadvance;
 FT_Byte* buffer;
}

struct FT_MM_Axis
{
 FT_String* name;
 FT_Long minimum;
 FT_Long maximum;
}

struct FT_Multi_Master
{
 FT_UInt num_axis;
 FT_UInt num_designs;
 FT_MM_Axis[4] axis;
}

struct FT_Var_Axis
{
 FT_String* name;
 FT_Fixed minimum;
 FT_Fixed def;
 FT_Fixed maximum;
 FT_ULong tag;
 FT_UInt strid;
}

struct FT_Var_Named_Style
{
 FT_Fixed* coords;
 FT_UInt strid;
}
 
struct FT_MM_Var
{
 FT_UInt num_axis;
 FT_UInt num_designs;
 FT_UInt num_namedstyles;
 FT_Var_Axis* axis;
 FT_Var_Named_Style* namedstyle;
}

struct FT_SfntName
{
 FT_UShort platform_id;
 FT_UShort encoding_id;
 FT_UShort language_id;
 FT_UShort name_id;
 FT_Byte* string;
 FT_UInt string_len;
}

struct FTC_MruNodeRec
{
 FTC_MruNode next;
 FTC_MruNode prev;
} 

struct FTC_MruListClassRec
{
 FT_UInt node_size;
 FTC_MruNode_CompareFunc node_compare;
 FTC_MruNode_InitFunc node_init;
 FTC_MruNode_ResetFunc node_reset;
 FTC_MruNode_DoneFunc node_done;
}

struct FTC_MruListRec
{
 FT_UInt num_nodes;
 FT_UInt max_nodes;
 FTC_MruNode nodes;
 FT_Pointer data;
 FTC_MruListClassRec clazz;
 FT_Memory memory;
}

struct FTC_NodeRec
{
 FTC_MruNodeRec mru;
 FTC_Node link;
 FT_UInt32 hash;
 FT_UShort cache_index;
 FT_Short ref_count;
}

struct FTC_CacheClassRec
{
 FTC_Node_NewFunc node_new;
 FTC_Node_WeightFunc node_weight;
 FTC_Node_CompareFunc node_compare;
 FTC_Node_CompareFunc node_remove_faceid;
 FTC_Node_FreeFunc node_free;
 FT_UInt cache_size;
 FTC_Cache_InitFunc cache_init;
 FTC_Cache_DoneFunc cache_done;
} 

struct FTC_CacheRec
{
 FT_UFast p;
 FT_UFast mask;
 FT_Long slack;
 FTC_Node* buckets;
 FTC_CacheClassRec clazz;
 FTC_Manager manager;
 FT_Memory memory;
 FT_UInt index;
 FTC_CacheClass org_class;
}

struct FTC_ManagerRec
{
 FT_Library library;
 FT_Memory memory;
 FTC_Node nodes_list;
 FT_ULong max_weight;
 FT_ULong cur_weight;
 FT_UInt num_nodes;
 FTC_Cache[16] caches;
 FT_UInt num_caches;
 FTC_MruListRec faces;
 FTC_MruListRec sizes;
 FT_Pointer request_data;
 FTC_Face_Requester request_face;
}

struct FTC_FamilyRec
{
 FTC_MruNodeRec mrunode;
 FT_UInt num_nodes;
 FTC_Cache cache;
 FTC_MruListClass clazz;
}

struct FTC_GNodeRec
{
 FTC_NodeRec node;
 FTC_Family family;
 FT_UInt gindex;
} 

struct FTC_GQueryRec
{
 FT_UInt gindex;
 FTC_Family family;
} 

struct FTC_GCacheRec 
{
 FTC_CacheRec cache;
 FTC_MruListRec families;
} 

struct FTC_GCacheClassRec
{
 FTC_CacheClassRec clazz;
 FTC_MruListClass family_class;
}

struct FTC_INodeRec
{
 FTC_GNodeRec gnode;
 FT_Glyph glyph;
} 

struct FTC_IFamilyClassRec
{
 FTC_MruListClassRec clazz;
 FTC_IFamily_LoadGlyphFunc family_load_glyph;
} 

struct FTC_SNodeRec
{
 FTC_GNodeRec gnode;
 FT_UInt count;
 FTC_SBitRec[16] sbits;
} 

struct FTC_SFamilyClassRec
{
 FTC_MruListClassRec clazz;
 FTC_SFamily_GetCountFunc family_get_count;
 FTC_SFamily_LoadGlyphFunc family_load_glyph;
}

struct FT_Incremental_MetricsRec
{
 FT_Long bearing_x;
 FT_Long bearing_y;
 FT_Long advance;
} 

struct FT_Incremental_FuncsRec
{
 FT_Incremental_GetGlyphDataFunc get_glyph_data;
 FT_Incremental_FreeGlyphDataFunc free_glyph_data;
 FT_Incremental_GetGlyphMetricsFunc get_glyph_metrics;
}

struct FT_Incremental_InterfaceRec
{
 FT_Incremental_FuncsRec* funcs;
 FT_Incremental object;
}

struct FT_SubGlyphRec
{
 FT_Int index;
 FT_UShort flags;
 FT_Int arg1;
 FT_Int arg2;
 FT_Matrix transform;
}

struct FT_GlyphLoadRec
{
 FT_Outline outline;
 FT_Vector* extra_points;
 FT_UInt num_subglyphs;
 FT_SubGlyph subglyphs;
} 

struct FT_GlyphLoaderRec
{
 FT_Memory memory;
 FT_UInt max_points;
 FT_UInt max_contours;
 FT_UInt max_subglyphs;
 FT_Bool use_extra;
 FT_GlyphLoadRec base;
 FT_GlyphLoadRec current;
 void* other;
}

struct FT_Driver_ClassRec
{
 FT_Module_Class root;
 FT_Long face_object_size;
 FT_Long size_object_size;
 FT_Long slot_object_size;
 FT_Face_InitFunc init_face;
 FT_Face_DoneFunc done_face;
 FT_Size_InitFunc init_size;
 FT_Size_DoneFunc done_size;
 FT_Slot_InitFunc init_slot;
 FT_Slot_DoneFunc done_slot;
 FT_Size_ResetPointsFunc set_char_sizes;
 FT_Size_ResetPixelsFunc set_pixel_sizes;
 FT_Slot_LoadFunc load_glyph;
 FT_Face_GetKerningFunc get_kerning;
 FT_Face_AttachFunc attach_file;
 FT_Face_GetAdvancesFunc get_advances;
} 

struct FT_AutoHinter_ServiceRec
{
 FT_AutoHinter_GlobalResetFunc reset_face;
 FT_AutoHinter_GlobalGetFunc get_global_hints;
 FT_AutoHinter_GlobalDoneFunc done_global_hints;
 FT_AutoHinter_GlyphLoadFunc load_glyph;
}

/* #pragma warning( disable : 4127 ) */

struct FT_ServiceDescRec
{
 char* serv_id;
 void* serv_data;
}

struct FT_ServiceCacheRec
{
 FT_Pointer service_POSTSCRIPT_FONT_NAME;
 FT_Pointer service_MULTI_MASTERS;
 FT_Pointer service_GLYPH_DICT;
 FT_Pointer service_PFR_METRICS;
 FT_Pointer service_WINFNT;
} 

struct FT_CMapRec
{
 FT_CharMapRec charmap;
 FT_CMap_Class clazz;
}

struct FT_CMap_ClassRec
{
 FT_ULong size;
 FT_CMap_InitFunc init;
 FT_CMap_DoneFunc done;
 FT_CMap_CharIndexFunc char_index;
 FT_CMap_CharNextFunc char_next;
}

struct FT_Face_InternalRec
{
 FT_UShort max_points;
 FT_Short max_contours;
 FT_Matrix transform_matrix;
 FT_Vector transform_delta;
 FT_Int transform_flags;
 FT_ServiceCacheRec services;
}
 
struct FT_Slot_InternalRec
{
 FT_GlyphLoader loader;
 FT_UInt flags;
 FT_Bool glyph_transformed;
 FT_Matrix glyph_matrix;
 FT_Vector glyph_delta;
 void* glyph_hints;
}

struct FT_ModuleRec
{
 FT_Module_Class* clazz;
 FT_Library library;
 FT_Memory memory;
 FT_Generic generic;
}

struct FT_RendererRec
{
 FT_ModuleRec root;
 FT_Renderer_Class* clazz;
 FT_Glyph_Format glyph_format;
 FT_Glyph_Class glyph_class;
 FT_Raster raster;
 FT_Raster_RenderFunc  raster_render;
 FT_Renderer_RenderFunc render;
}

struct FT_DriverRec
{
 FT_ModuleRec root;
 FT_Driver_Class clazz;
 FT_ListRec faces_list;
 void* extensions;
 FT_GlyphLoader glyph_loader;
}

struct FT_LibraryRec
{
 FT_Memory memory;
 FT_Generic generic;
 FT_Int version_major;
 FT_Int version_minor;
 FT_Int version_patch;
 FT_UInt num_modules;
 FT_Module[32] modules;
 FT_ListRec renderers;
 FT_Renderer cur_renderer;
 FT_Module auto_hinter;
 FT_Byte* raster_pool;
 FT_ULong raster_pool_size;
 FT_DebugHook_Func[4] debug_hooks;
}

struct FT_Frame_Field
{
 FT_Byte value;
 FT_Byte size;
 FT_UShort offset;
}

struct TTC_HeaderRec
{
 FT_ULong tag;
 FT_Fixed _version;
 FT_Long count;
 FT_ULong* offsets;
}

struct SFNT_HeaderRec
{
 FT_ULong format_tag;
 FT_UShort num_tables;
 FT_UShort search_range;
 FT_UShort entry_selector;
 FT_UShort range_shift;
 FT_ULong offset;
} 

struct TT_TableRec
 {
 FT_ULong Tag;
 FT_ULong CheckSum;
 FT_ULong Offset;
 FT_ULong Length;
}

struct TT_LongMetricsRec
{
 FT_UShort advance;
 FT_Short bearing;
} 

struct TT_NameEntryRec
{
 FT_UShort platformID;
 FT_UShort encodingID;
 FT_UShort languageID;
 FT_UShort nameID;
 FT_UShort stringLength;
 FT_ULong stringOffset;
 FT_Byte* string;
} 

struct TT_NameTableRec
{
 FT_UShort format;
 FT_UInt numNameRecords;
 FT_UInt storageOffset;
 TT_NameEntryRec* names;
 FT_Stream stream;
} 

struct TT_GaspRangeRec
{
 FT_UShort maxPPEM;
 FT_UShort gaspFlag;
} 

struct TT_GaspRec
{
 FT_UShort _version;
 FT_UShort numRanges;
 TT_GaspRange gaspRanges;
}

struct TT_HdmxEntryRec
{
 FT_Byte ppem;
 FT_Byte max_width;
 FT_Byte* widths;
}

struct TT_HdmxRec
{
 FT_UShort _version;
 FT_Short num_records;
 TT_HdmxEntry records;
} 

struct TT_Kern0_PairRec
{
 FT_UShort left;
 FT_UShort right;
 FT_FWord value;
} 

struct TT_SBit_MetricsRec
{
 FT_Byte height;
 FT_Byte width;
 FT_Char horiBearingX;
 FT_Char horiBearingY;
 FT_Byte horiAdvance;
 FT_Char vertBearingX;
 FT_Char vertBearingY;
 FT_Byte vertAdvance;
} 

struct TT_SBit_SmallMetricsRec
{
 FT_Byte height;
 FT_Byte width;
 FT_Char bearingX;
 FT_Char bearingY;
 FT_Byte advance;
} 

struct TT_SBit_LineMetricsRec
{
 FT_Char ascender;
 FT_Char descender;
 FT_Byte max_width;
 FT_Char caret_slope_numerator;
 FT_Char caret_slope_denominator;
 FT_Char caret_offset;
 FT_Char min_origin_SB;
 FT_Char min_advance_SB;
 FT_Char max_before_BL;
 FT_Char min_after_BL;
 FT_Char[2] pads;
} 

struct TT_SBit_RangeRec
{
 FT_UShort first_glyph;
 FT_UShort last_glyph;
 FT_UShort index_format;
 FT_UShort image_format;
 FT_ULong image_offset;
 FT_ULong image_size;
 TT_SBit_MetricsRec metrics;
 FT_ULong num_glyphs;
 FT_ULong* glyph_offsets;
 FT_UShort* glyph_codes;
 FT_ULong table_offset;
}

struct TT_SBit_StrikeRec
{
 FT_Int num_ranges;
 TT_SBit_Range sbit_ranges;
 FT_ULong ranges_offset;
 FT_ULong color_ref;
 TT_SBit_LineMetricsRec hori;
 TT_SBit_LineMetricsRec vert;
 FT_UShort start_glyph;
 FT_UShort end_glyph;
 FT_Byte x_ppem;
 FT_Byte y_ppem;
 FT_Byte bit_depth;
 FT_Char flags;
} 

struct TT_SBit_ComponentRec
{
 FT_UShort glyph_code;
 FT_Char x_offset;
 FT_Char y_offset;
} 

struct TT_SBit_ScaleRec
{
 TT_SBit_LineMetricsRec hori;
 TT_SBit_LineMetricsRec vert;
 FT_Byte x_ppem;
 FT_Byte y_ppem;
 FT_Byte x_ppem_substitute;
 FT_Byte y_ppem_substitute;
} 

struct TT_Post_20Rec
{
 FT_UShort num_glyphs;
 FT_UShort num_names;
 FT_UShort* glyph_indices;
 FT_Char** glyph_names;
} 

struct TT_Post_25Rec
{
 FT_UShort num_glyphs;
 FT_Char* offsets;
} 

struct TT_Post_NamesRec
{
 FT_Bool loaded;
 union names
 {
 TT_Post_20Rec format_20;
 TT_Post_25Rec format_25;
 }
}

struct TT_FaceRec
{
 FT_FaceRec root;
 TTC_HeaderRec ttc_header;
 FT_ULong format_tag;
 FT_UShort num_tables;
 TT_Table dir_tables;
 TT_Header header;
 TT_HoriHeader horizontal;
 TT_MaxProfile max_profile;
 FT_ULong max_components;
 FT_Bool vertical_info;
 TT_VertHeader vertical;
 FT_UShort num_names;
 TT_NameTableRec name_table;
 TT_OS2 os2;
 TT_Postscript postscript;
 FT_Byte* cmap_table;
 FT_ULong cmap_size;
 TT_Loader_GotoTableFunc goto_table;
 TT_Loader_StartGlyphFunc access_glyph_frame;
 TT_Loader_EndGlyphFunc forget_glyph_frame;
 TT_Loader_ReadGlyphFunc read_glyph_header;
 TT_Loader_ReadGlyphFunc read_simple_glyph;
 TT_Loader_ReadGlyphFunc read_composite_glyph;
 void* sfnt;
 void* psnames;
 TT_HdmxRec hdmx;
 TT_GaspRec gasp;
 TT_PCLT pclt;
 FT_ULong num_sbit_strikes;
 TT_SBit_Strike sbit_strikes;
 FT_ULong num_sbit_scales;
 TT_SBit_Scale sbit_scales;
 TT_Post_NamesRec postscript_names;
 FT_UShort num_locations;
 FT_Long* glyph_locations;
 FT_ULong glyf_len;
 FT_ULong font_program_size;
 FT_Byte* font_program;
 FT_ULong cvt_program_size;
 FT_Byte* cvt_program;
 FT_ULong cvt_size;
 FT_Short* cvt;
 FT_Int num_kern_pairs;
 FT_Int kern_table_index;
 TT_Kern0_Pair kern_pairs;
 TT_Interpreter interpreter;
 FT_Bool unpatented_hinting;
 FT_Bool doblend;
 GX_Blend blend;
 FT_Generic extra;
 char* postscript_name;
}

struct TT_GlyphZoneRec
{
 FT_Memory memory;
 FT_UShort max_points;
 FT_UShort max_contours;
 FT_UShort n_points;
 FT_Short n_contours;
 FT_Vector* org;
 FT_Vector* cur;
 FT_Byte* tags;
 FT_UShort* contours;
} 

struct TT_LoaderRec
{
 FT_Face face;
 FT_Size size;
 FT_GlyphSlot glyph;
 FT_GlyphLoader gloader;
 FT_ULong load_flags;
 FT_UInt glyph_index;
 FT_Stream stream;
 FT_Int byte_len;
 FT_Short n_contours;
 FT_BBox bbox;
 FT_Int left_bearing;
 FT_Int advance;
 FT_Int top_bearing;
 FT_Int vadvance;
 FT_Int linear;
 FT_Bool linear_def;
 FT_Bool preserve_pps;
 FT_Vector pp1;
 FT_Vector pp2;
 FT_Vector pp3;
 FT_Vector pp4;
 FT_ULong glyf_offset;
 TT_GlyphZoneRec base;
 TT_GlyphZoneRec zone;
 TT_ExecContext exec;
 FT_Byte* instructions;
 FT_ULong ins_pos;
 void* other;
}

struct SFNT_Interface
{
 TT_Loader_GotoTableFunc goto_table;
 TT_Init_Face_Func init_face;
 TT_Load_Face_Func load_face;
 TT_Done_Face_Func done_face;
 FT_Module_Requester get_interface;
 TT_Load_Any_Func load_any;
 TT_Load_SFNT_HeaderRec_Func load_sfnt_header;
 TT_Load_Directory_Func load_directory;
 TT_Load_Table_Func load_header;
 TT_Load_Metrics_Func load_metrics;
 TT_Load_Table_Func load_charmaps;
 TT_Load_Table_Func load_max_profile;
 TT_Load_Table_Func load_os2;
 TT_Load_Table_Func load_psnames;
 TT_Load_Table_Func load_names;
 TT_Free_Table_Func free_names;
 TT_Load_Table_Func load_hdmx;
 TT_Free_Table_Func free_hdmx;
 TT_Load_Table_Func load_kerning;
 TT_Load_Table_Func load_gasp;
 TT_Load_Table_Func load_pclt;
 TT_Load_Table_Func load_bitmap_header;
 TT_Set_SBit_Strike_Func set_sbit_strike;
 TT_Load_Table_Func load_sbits;
 TT_Find_SBit_Image_Func find_sbit_image;
 TT_Load_SBit_Metrics_Func load_sbit_metrics;
 TT_Load_SBit_Image_Func load_sbit_image;
 TT_Free_Table_Func free_sbits;
 TT_Face_GetKerningFunc get_kerning;
 TT_Get_PS_Name_Func get_psname;
 TT_Free_Table_Func free_psnames;
}

struct FT_ValidatorRec
{
 FT_Byte* base;
 FT_Byte* limit;
 FT_ValidationLevel level;
 FT_Error error;
 int[_JBLEN]  jump_buffer;
}

struct PSH_Globals_FuncsRec
{
 PSH_Globals_NewFunc create;
 PSH_Globals_SetScaleFunc set_scale;
 PSH_Globals_DestroyFunc destroy;
} 

struct T1_Hints_FuncsRec
{
 T1_Hints hints;
 T1_Hints_OpenFunc open;
 T1_Hints_CloseFunc close;
 T1_Hints_SetStemFunc stem;
 T1_Hints_SetStem3Func stem3;
 T1_Hints_ResetFunc reset;
 T1_Hints_ApplyFunc apply;
}

struct T2_Hints_FuncsRec
{
 T2_Hints hints;
 T2_Hints_OpenFunc open;
 T2_Hints_CloseFunc close;
 T2_Hints_StemsFunc stems;
 T2_Hints_MaskFunc hintmask;
 T2_Hints_CounterFunc counter;
 T2_Hints_ApplyFunc apply;
}

struct PSHinter_Interface
{
 PSH_Globals_Funcs function( FT_Module mod ) get_globals_funcs;
 T1_Hints_Funcs function( FT_Module mod ) get_t1_funcs;
 T2_Hints_Funcs function( FT_Module mod ) get_t2_funcs;
}

struct PS_UniMap
{
 FT_UInt unicode;
 FT_UInt glyph_index;
}

struct PS_Unicodes
{
 FT_UInt num_maps;
 PS_UniMap* maps;
}

struct FT_Service_PsCMapsRec 
{
 PS_Unicode_ValueFunc unicode_value;

 PS_Unicodes_InitFunc unicodes_init;
 PS_Unicodes_CharIndexFunc unicodes_char_index;
 PS_Unicodes_CharNextFunc unicodes_char_next;

 PS_Macintosh_Name_Func macintosh_name;
 PS_Adobe_Std_Strings_Func adobe_std_strings;
 ushort* adobe_std_encoding;
 ushort* adobe_expert_encoding;
}
 
struct T1_EncodingRec
{
 FT_Int num_chars;
 FT_Int code_first;
 FT_Int code_last;
 FT_UShort* char_index;
 FT_String** char_name;
} 


struct T1_FontRec
{
 PS_FontInfoRec font_info;
 PS_PrivateRec private_dict;
 FT_String* font_name;
 T1_EncodingType encoding_type;
 T1_EncodingRec encoding;
 FT_Byte* subrs_block;
 FT_Byte* charstrings_block;
 FT_Byte* glyph_names_block;
 FT_Int num_subrs;
 FT_Byte** subrs;
 FT_PtrDist* subrs_len;
 FT_Int num_glyphs;
 FT_String** glyph_names;
 FT_Byte** charstrings;
 FT_PtrDist* charstrings_len;
 FT_Byte paint_type;
 FT_Byte font_type;
 FT_Matrix font_matrix;
 FT_Vector font_offset;
 FT_BBox font_bbox;
 FT_Long font_id;
 FT_Fixed stroke_width;
}

struct CID_SubrsRec
{
 FT_UInt num_subrs;
 FT_Byte** code;
}

struct T1_FaceRec
{
 FT_FaceRec root;
 T1_FontRec type1;
 void* psnames;
 void* psaux;
 void* afm_data;
 FT_CharMapRec[2] charmaprecs;
 FT_CharMap[2] charmaps;
 PS_Unicodes unicode_map;
 PS_Blend blend;
 void* pshinter;
}

struct CID_FaceRec
{
 FT_FaceRec root;
 void* psnames;
 void* psaux;
 CID_FaceInfoRec cid;
 void* afm_data;
 FT_Byte* binary_data;
 FT_Stream cid_stream;
 CID_Subrs subrs;
 void* pshinter;
}
 
struct PS_Table_FuncsRec
{
 FT_Error function( PS_Table table, FT_Int count, FT_Memory memory ) init;
 void 	  function( PS_Table table ) done;
 FT_Error function( PS_Table table, FT_Int idx, void* object, FT_PtrDist length ) add;
 void	  function( PS_Table table ) release;
}

struct PS_TableRec
{
 FT_Byte* block;
 FT_Offset cursor;
 FT_Offset capacity;
 FT_Long init;
 FT_Int max_elems;
 FT_Int num_elems;
 FT_Byte** elements;
 FT_PtrDist* lengths;
 FT_Memory memory;
 PS_Table_FuncsRec funcs;
}

struct T1_TokenRec
{
 FT_Byte* start;
 FT_Byte* limit;
 T1_TokenType type;
}

struct T1_FieldRec
{
 char* ident;
 T1_FieldLocation location;
 T1_FieldType type;
 T1_Field_ParseFunc reader;
 FT_UInt offset;
 FT_Byte size;
 FT_UInt array_max;
 FT_UInt count_offset;
}

struct PS_Parser_FuncsRec
{
 void 		function( PS_Parser parser, FT_Byte* base, FT_Byte* limit, FT_Memory memory ) init;
 void 		function( PS_Parser parser ) done;
 void 		function( PS_Parser parser ) skip_spaces;
 void 		function( PS_Parser parser ) skip_PS_token;
 FT_Long	function( PS_Parser parser ) to_int;
 FT_Fixed	function( PS_Parser parser, FT_Int power_ten ) to_fixed;
 FT_Error	function( PS_Parser parser, FT_Byte* bytes, FT_Long max_bytes, FT_Long* pnum_bytes, FT_Bool delimiters ) to_bytes;
 FT_Int		function( PS_Parser parser, FT_Int max_coords, FT_Short* coords ) to_coord_array;
 FT_Int		function( PS_Parser parser, FT_Int max_values, FT_Fixed* values, FT_Int power_ten ) to_fixed_array;
 void		function( PS_Parser parser, T1_Token token ) to_token;
 void		function( PS_Parser parser, T1_Token tokens, FT_UInt max_tokens, FT_Int* pnum_tokens ) to_token_array;
 FT_Error	function( PS_Parser parser, T1_Field field, void** objects,  FT_UInt max_objects,  FT_ULong* pflags ) load_field;
 FT_Error	function( PS_Parser parser, T1_Field field, void** objects, FT_UInt max_objects, FT_ULong* pflags ) load_field_table;
}

struct PS_ParserRec
{
 FT_Byte* cursor;
 FT_Byte* base;
 FT_Byte* limit;
 FT_Error error;
 FT_Memory memory;
 PS_Parser_FuncsRec funcs;
}

struct T1_Builder_FuncsRec
{
 void function( T1_Builder builder, FT_Face face, FT_Size size, FT_GlyphSlot slot, FT_Bool hinting ) init;
 void function( T1_Builder builder ) done;

 T1_Builder_Check_Points_Func check_points;
 T1_Builder_Add_Point_Func add_point;
 T1_Builder_Add_Point1_Func add_point1;
 T1_Builder_Add_Contour_Func add_contour;
 T1_Builder_Start_Point_Func start_point;
 T1_Builder_Close_Contour_Func close_contour;
}

struct T1_BuilderRec
{
 FT_Memory memory;
 FT_Face face;
 FT_GlyphSlot glyph;
 FT_GlyphLoader loader;
 FT_Outline* base;
 FT_Outline* current;
 FT_Vector last;
 FT_Fixed scale_x;
 FT_Fixed scale_y;
 FT_Pos pos_x;
 FT_Pos pos_y;
 FT_Vector left_bearing;
 FT_Vector advance;
 FT_BBox bbox;
 T1_ParseState parse_state;
 FT_Bool load_points;
 FT_Bool no_recurse;
 FT_Bool shift;
 FT_Bool metrics_only;
 void* hints_funcs;
 void* hints_globals;
 T1_Builder_FuncsRec funcs;
}

struct T1_Decoder_ZoneRec
{
 FT_Byte* cursor;
 FT_Byte* base;
 FT_Byte* limit;
} 

struct T1_Decoder_FuncsRec
{
 FT_Error function( T1_Decoder, FT_Face, FT_Size, FT_GlyphSlot, FT_Byte**, PS_Blend, FT_Bool, FT_Render_Mode, T1_Decoder_Callback ) init;
 void	  function( T1_Decoder decoder ) done;
 FT_Error function( T1_Decoder decoder, FT_Byte* base, FT_UInt len ) parse_charstrings;
}

struct T1_DecoderRec
{
 T1_BuilderRec builder;
 FT_Long[256] stack;
 FT_Long* top;
 T1_Decoder_ZoneRec[16+1] zones;
 T1_Decoder_Zone zone;
 FT_Service_PsCMaps psnames;
 FT_UInt num_glyphs;
 FT_Byte** glyph_names;
 FT_Int lenIV;
 FT_UInt num_subrs;
 FT_Byte** subrs;
 FT_PtrDist* subrs_len;
 FT_Matrix font_matrix;
 FT_Vector font_offset;
 FT_Int flex_state;
 FT_Int num_flex_vectors;
 FT_Vector[7] flex_vectors;
 PS_Blend blend;
 FT_Render_Mode hint_mode;
 T1_Decoder_Callback parse_callback;
 T1_Decoder_FuncsRec funcs;
}

struct T1_CMap_ClassesRec
{
 FT_CMap_Class standard;
 FT_CMap_Class expert;
 FT_CMap_Class custom;
 FT_CMap_Class unicode;
}

struct PSAux_ServiceRec
{
 PS_Table_FuncsRec* ps_table_funcs;
 PS_Parser_FuncsRec* ps_parser_funcs;
 T1_Builder_FuncsRec* t1_builder_funcs;
 T1_Decoder_FuncsRec* t1_decoder_funcs;
 void function( FT_Byte* buffer, FT_Offset length, FT_UShort seed ) t1_decrypt;
 T1_CMap_Classes t1_cmap_classes;
}

/********************************************************************
 *   Freetype Function Callback Types
 ********************************************************************/

alias void* function( FT_Memory memory, int size ) 	
	FT_Alloc_Func;
alias void  function( FT_Memory memory, void* block ) 
	FT_Free_Func;
alias void* function( FT_Memory memory, int cur_size, int new_size, void* block ) 
	FT_Realloc_Func;

alias uint function( FT_Stream stream, uint offset, ubyte* buffer, uint count ) 
	FT_Stream_IoFunc;
alias void 		  function( FT_Stream stream ) 
	FT_Stream_CloseFunc;

alias int function( FT_Vector* to, void* user ) 
	FT_Outline_MoveToFunc;
alias int function( FT_Vector* to, void* user ) 
	FT_Outline_LineToFunc;
alias int function( FT_Vector* control, FT_Vector* to, void* user ) 
	FT_Outline_ConicToFunc;
alias int function( FT_Vector* control1, FT_Vector* control2, FT_Vector* to, void* user ) 
	FT_Outline_CubicToFunc;


alias void function( int y, int count, FT_Span* spans, void* user ) 
	FT_SpanFunc;
alias int  function( int y, int x, void* user ) 
	FT_Raster_BitTest_Func;
alias void function( int y, int x, void* user ) 
	FT_Raster_BitSet_Func;

alias int function( void* memory, FT_Raster* raster ) 
	FT_Raster_NewFunc;
alias void function( FT_Raster raster ) 
	FT_Raster_DoneFunc;
alias void function( FT_Raster raster, ubyte* pool_base, uint pool_size ) 
	FT_Raster_ResetFunc;
alias int function( FT_Raster raster,uint mode, void* args ) 
	FT_Raster_SetModeFunc;
alias int function( FT_Raster raster, FT_Raster_Params* params ) 
	FT_Raster_RenderFunc;

alias void function(void* object) 
	FT_Generic_Finalizer;

alias FT_Error function( FT_ListNode node, void* user ) FT_List_Iterator;
alias void	 function( FT_Memory memory, void* data, void* user ) FT_List_Destructor;
alias FT_Error 	function( FT_Module mod ) FT_Module_Constructor;
alias void 		function( FT_Module mod ) FT_Module_Destructor;
alias FT_Module_Interface function( FT_Module mod, char* name ) FT_Module_Requester;
 
alias void function( void* arg ) FT_DebugHook_Func;

alias FT_Error function( FT_Glyph glyph, FT_GlyphSlot slot ) FT_Glyph_InitFunc;
alias void function( FT_Glyph glyph ) FT_Glyph_DoneFunc;
alias void function( FT_Glyph glyph, FT_Matrix* matrix, FT_Vector* delta ) FT_Glyph_TransformFunc;
alias void function( FT_Glyph glyph, FT_BBox* abbox ) FT_Glyph_GetBBoxFunc;
alias FT_Error function( FT_Glyph source, FT_Glyph target ) FT_Glyph_CopyFunc;
alias FT_Error function( FT_Glyph glyph, FT_GlyphSlot slot ) FT_Glyph_PrepareFunc;

alias FT_Error function( FT_Renderer renderer, FT_GlyphSlot slot, FT_UInt mode, FT_Vector* origin ) FT_Renderer_RenderFunc;
alias FT_Error function( FT_Renderer renderer, FT_GlyphSlot slot, FT_Matrix* matrix, FT_Vector* delta ) FT_Renderer_TransformFunc;
alias void function( FT_Renderer renderer, FT_GlyphSlot slot, FT_BBox* cbox ) FT_Renderer_GetCBoxFunc;
alias FT_Error function( FT_Renderer renderer, FT_ULong mode_tag, FT_Pointer mode_ptr ) FT_Renderer_SetModeFunc;
 
alias FT_Error function( FTC_FaceID face_id, FT_Library library, FT_Pointer request_data, FT_Face* aface ) FTC_Face_Requester;

alias FT_Bool function( FTC_MruNode node, FT_Pointer key ) FTC_MruNode_CompareFunc;
alias FT_Error function( FTC_MruNode node, FT_Pointer key, FT_Pointer data ) FTC_MruNode_InitFunc;
alias FT_Error function( FTC_MruNode node, FT_Pointer key, FT_Pointer data ) FTC_MruNode_ResetFunc;
alias void function( FTC_MruNode node, FT_Pointer data ) FTC_MruNode_DoneFunc;

alias FT_Error function( FTC_Node *pnode, FT_Pointer query, FTC_Cache cache ) FTC_Node_NewFunc;
alias FT_ULong function( FTC_Node node, FTC_Cache cache ) FTC_Node_WeightFunc;
alias FT_Bool  function( FTC_Node node, FT_Pointer key, FTC_Cache cache ) FTC_Node_CompareFunc;
alias void 	 function( FTC_Node node, FTC_Cache cache ) FTC_Node_FreeFunc;
alias FT_Error function( FTC_Cache cache ) FTC_Cache_InitFunc;
alias void 	 function( FTC_Cache cache ) FTC_Cache_DoneFunc;

alias FT_Error function( FTC_Family family, FT_UInt gindex, FTC_Cache cache, FT_Glyph *aglyph ) FTC_IFamily_LoadGlyphFunc;

alias FT_UInt	 function( FTC_Family family, FTC_Manager manager ) FTC_SFamily_GetCountFunc;
alias FT_Error function( FTC_Family family, FT_UInt gindex, FTC_Manager manager, FT_Face *aface ) FTC_SFamily_LoadGlyphFunc;

alias FT_Error function( FT_Incremental incremental, FT_UInt glyph_index, FT_Data* adata ) FT_Incremental_GetGlyphDataFunc;
alias void 	 function( FT_Incremental incremental, FT_Data* data ) FT_Incremental_FreeGlyphDataFunc;
alias FT_Error function( FT_Incremental incremental, FT_UInt glyph_index, FT_Bool vertical, FT_Incremental_MetricsRec *ametrics ) FT_Incremental_GetGlyphMetricsFunc;

alias FT_Error function( FT_Stream stream, FT_Face face, FT_Int typeface_index, FT_Int num_params, FT_Parameter* parameters ) FT_Face_InitFunc;
alias void	 function( FT_Face face ) FT_Face_DoneFunc;
alias FT_Error function( FT_Size size ) FT_Size_InitFunc;
alias void 	 function( FT_Size size ) FT_Size_DoneFunc;
alias FT_Error function( FT_GlyphSlot slot )FT_Slot_InitFunc;
alias void	 function( FT_GlyphSlot slot ) FT_Slot_DoneFunc;
alias FT_Error function( FT_Size size, FT_F26Dot6 char_width, FT_F26Dot6 char_height, FT_UInt horz_resolution, FT_UInt vert_resolution ) FT_Size_ResetPointsFunc;
alias FT_Error function( FT_Size size, FT_UInt pixel_width, FT_UInt pixel_height ) FT_Size_ResetPixelsFunc;
alias FT_Error function( FT_GlyphSlot slot, FT_Size size, FT_UInt glyph_index, FT_Int32 load_flags ) FT_Slot_LoadFunc;
alias FT_UInt  function( FT_CharMap charmap, FT_Long charcode ) FT_CharMap_CharIndexFunc;
alias FT_Long  function( FT_CharMap charmap, FT_Long charcode ) FT_CharMap_CharNextFunc;
alias FT_Error function( FT_Face face, FT_UInt left_glyph, FT_UInt right_glyph, FT_Vector* kerning ) FT_Face_GetKerningFunc;
alias FT_Error function( FT_Face face, FT_Stream stream ) FT_Face_AttachFunc;
alias FT_Error function( FT_Face face, FT_UInt first, FT_UInt count, FT_Bool vertical, FT_UShort* advances ) FT_Face_GetAdvancesFunc;

alias void 		function( FT_AutoHinter hinter, FT_Face face, void** global_hints, int* global_len ) FT_AutoHinter_GlobalGetFunc;
alias void 		function( FT_AutoHinter hinter, void* global ) FT_AutoHinter_GlobalDoneFunc;
alias void		function( FT_AutoHinter hinter, FT_Face face ) FT_AutoHinter_GlobalResetFunc;
alias FT_Error 	function( FT_AutoHinter hinter, FT_GlyphSlot slot, FT_Size size, FT_UInt glyph_index, FT_Int32 load_flags ) FT_AutoHinter_GlyphLoadFunc;

alias FT_Error function( FT_CMap cmap, FT_Pointer init_data ) FT_CMap_InitFunc;
alias void 	 function( FT_CMap cmap ) FT_CMap_DoneFunc;
alias FT_UInt  function( FT_CMap cmap, FT_UInt32 char_code ) FT_CMap_CharIndexFunc;
alias FT_UInt  function( FT_CMap cmap, FT_UInt32 *achar_code ) FT_CMap_CharNextFunc;

alias char*		function( FT_Face face ) FT_Face_GetPostscriptNameFunc;
alias FT_Error  	function( FT_Face face, FT_UInt glyph_index, FT_Pointer buffer, FT_UInt buffer_max ) FT_Face_GetGlyphNameFunc;
alias FT_UInt		function( FT_Face face, FT_String* glyph_name ) FT_Face_GetGlyphNameIndexFunc;

alias FT_Error function( void* exec_context ) TT_Interpreter;

alias FT_Error function( TT_Face face, FT_ULong tag, FT_Stream stream, FT_ULong* length ) TT_Loader_GotoTableFunc;
alias FT_Error function( TT_Loader loader, FT_UInt glyph_index, FT_ULong offset, FT_UInt byte_count ) TT_Loader_StartGlyphFunc;
alias FT_Error function( TT_Loader loader ) TT_Loader_ReadGlyphFunc;
alias void 	 function( TT_Loader loader ) TT_Loader_EndGlyphFunc;

alias FT_Error function( FT_Stream stream, TT_Face face, FT_Int face_index, FT_Int num_params, FT_Parameter* params ) TT_Init_Face_Func;
alias FT_Error function( FT_Stream stream, TT_Face face, FT_Int face_index, FT_Int num_params, FT_Parameter* params ) TT_Load_Face_Func;
alias void     function( TT_Face face ) TT_Done_Face_Func;
alias FT_Error function( TT_Face face, FT_Stream stream, FT_Long face_index, SFNT_Header sfnt ) TT_Load_SFNT_HeaderRec_Func;
alias FT_Error function( TT_Face face, FT_Stream stream, SFNT_Header sfnt ) TT_Load_Directory_Func;
alias FT_Error function( TT_Face face, FT_ULong tag, FT_Long offset, FT_Byte *buffer, FT_ULong* length ) TT_Load_Any_Func;
alias FT_Error function( TT_Face face, FT_UInt glyph_index, FT_ULong strike_index, TT_SBit_Range *arange, TT_SBit_Strike *astrike, FT_ULong *aglyph_offset ) TT_Find_SBit_Image_Func;
alias FT_Error function( FT_Stream stream, TT_SBit_Range range, TT_SBit_Metrics metrics ) TT_Load_SBit_Metrics_Func;
alias FT_Error function( TT_Face face, FT_ULong strike_index, FT_UInt glyph_index, FT_UInt load_flags, FT_Stream stream, FT_Bitmap *amap, TT_SBit_MetricsRec *ametrics ) TT_Load_SBit_Image_Func;
alias FT_Error function( TT_Face face, FT_UInt x_ppem, FT_UInt y_ppem, FT_ULong *astrike_index ) TT_Set_SBit_Strike_Func;
alias FT_Error function( TT_Face face, FT_UInt idx, FT_String** PSname ) TT_Get_PS_Name_Func;
alias FT_Error function( TT_Face face, FT_Stream stream, FT_Bool vertical ) TT_Load_Metrics_Func;
alias FT_Error function( TT_Face face, FT_Stream stream ) TT_Load_Table_Func;
alias void 	 function( TT_Face face ) TT_Free_Table_Func;
alias FT_Int	 function( TT_Face face, FT_UInt left_glyph, FT_UInt right_glyph ) TT_Face_GetKerningFunc;

alias FT_Error function( FT_Memory memory, T1_Private* private_dict, PSH_Globals* aglobals ) PSH_Globals_NewFunc;
alias FT_Error function( PSH_Globals globals, FT_Fixed x_scale, FT_Fixed y_scale, FT_Fixed x_delta, FT_Fixed y_delta ) PSH_Globals_SetScaleFunc;
alias void	 function( PSH_Globals globals ) PSH_Globals_DestroyFunc;

alias void 		function( T1_Hints hints ) T1_Hints_OpenFunc;
alias void 		function( T1_Hints hints, FT_UInt dimension, FT_Long* coords ) T1_Hints_SetStemFunc;
alias void 		function( T1_Hints hints, FT_UInt dimension, FT_Long* coords ) T1_Hints_SetStem3Func;
alias void 		function( T1_Hints hints, FT_UInt end_point ) T1_Hints_ResetFunc;
alias FT_Error	function( T1_Hints hints, FT_UInt end_point ) T1_Hints_CloseFunc;
alias FT_Error 	function( T1_Hints hints, FT_Outline* outline, PSH_Globals globals, FT_Render_Mode hint_mode ) T1_Hints_ApplyFunc;

alias void		function( T2_Hints hints ) T2_Hints_OpenFunc;
alias void 		function( T2_Hints hints, FT_UInt dimension, FT_UInt count, FT_Fixed* coordinates ) T2_Hints_StemsFunc;
alias void		function( T2_Hints hints, FT_UInt end_point, FT_UInt bit_count, FT_Byte* bytes ) T2_Hints_MaskFunc;
alias void		function( T2_Hints hints, FT_UInt bit_count, FT_Byte* bytes ) T2_Hints_CounterFunc;
alias FT_Error 	function( T2_Hints hints, FT_UInt end_point ) T2_Hints_CloseFunc;
alias FT_Error	function( T2_Hints hints, FT_Outline* outline, PSH_Globals globals, FT_Render_Mode hint_mode ) T2_Hints_ApplyFunc;
 
alias FT_UInt32 	function( char* glyph_name ) PS_Unicode_ValueFunc;
alias FT_UInt		function( FT_UInt num_glyphs, char** glyph_names, FT_ULong unicode ) PS_Unicode_Index_Func;
alias char*		function( FT_UInt name_index ) PS_Macintosh_Name_Func;
alias char* 		function( FT_UInt string_index ) PS_Adobe_Std_Strings_Func;

alias FT_Error function( FT_Memory memory, FT_UInt num_glyphs, char** glyph_names, PS_Unicodes* unicodes ) PS_Unicodes_InitFunc;
alias FT_UInt	 function( PS_Unicodes* unicodes, FT_UInt unicode ) PS_Unicodes_CharIndexFunc;
alias FT_ULong function( PS_Unicodes* unicodes, FT_ULong unicode ) PS_Unicodes_CharNextFunc;

alias void  function( FT_Face face, FT_Pointer parser ) T1_Field_ParseFunc;

alias FT_Error function( T1_Builder builder, FT_Int count ) T1_Builder_Check_Points_Func;
alias void 	 function( T1_Builder builder, FT_Pos x, FT_Pos y, FT_Byte flag ) T1_Builder_Add_Point_Func;
alias FT_Error function( T1_Builder builder, FT_Pos x, FT_Pos y ) T1_Builder_Add_Point1_Func;
alias FT_Error function( T1_Builder builder ) T1_Builder_Add_Contour_Func;
alias FT_Error function( T1_Builder builder, FT_Pos x, FT_Pos y ) T1_Builder_Start_Point_Func;
alias void	 function( T1_Builder builder ) T1_Builder_Close_Contour_Func;

alias FT_Error function( T1_Decoder decoder, FT_UInt glyph_index ) T1_Decoder_Callback;

/***********************************************************************
 * Extra macros carried over from Freetype.  Something needs to be done?
 ***********************************************************************/

 /*
 FT_NOERRORDEF_( Ok, 0x00, "no error" )
 FT_ERRORDEF_( Cannot_Open_Resource, 0x01, "cannot open resource" )
 FT_ERRORDEF_( Unknown_File_Format, 0x02, "unknown file format" )
 FT_ERRORDEF_( Invalid_File_Format, 0x03, "broken file" )
 FT_ERRORDEF_( Invalid_Version, 0x04, "invalid FreeType version" )
 FT_ERRORDEF_( Lower_Module_Version, 0x05, "module version is too low" )
 FT_ERRORDEF_( Invalid_Argument, 0x06, "invalid argument" )
 FT_ERRORDEF_( Unimplemented_Feature, 0x07, "unimplemented feature" )
 FT_ERRORDEF_( Invalid_Table, 0x08, "broken table" )
 FT_ERRORDEF_( Invalid_Offset, 0x09, "broken offset within table" )
 FT_ERRORDEF_( Invalid_Glyph_Index, 0x10, "invalid glyph index" )
 FT_ERRORDEF_( Invalid_Character_Code, 0x11, "invalid character code" )
 FT_ERRORDEF_( Invalid_Glyph_Format, 0x12, "unsupported glyph image format" )
 FT_ERRORDEF_( Cannot_Render_Glyph, 0x13, "cannot render this glyph format" )
 FT_ERRORDEF_( Invalid_Outline, 0x14, "invalid outline" )
 FT_ERRORDEF_( Invalid_Composite, 0x15, "invalid composite glyph" )
 FT_ERRORDEF_( Too_Many_Hints, 0x16, "too many hints" )
 FT_ERRORDEF_( Invalid_Pixel_Size, 0x17, "invalid pixel size" )
 FT_ERRORDEF_( Invalid_Handle, 0x20, "invalid object handle" )
 FT_ERRORDEF_( Invalid_Library_Handle, 0x21, "invalid library handle" )
 FT_ERRORDEF_( Invalid_Driver_Handle, 0x22, "invalid module handle" )
 FT_ERRORDEF_( Invalid_Face_Handle, 0x23, "invalid face handle" )
 FT_ERRORDEF_( Invalid_Size_Handle, 0x24, "invalid size handle" )
 FT_ERRORDEF_( Invalid_Slot_Handle, 0x25, "invalid glyph slot handle" )
 FT_ERRORDEF_( Invalid_CharMap_Handle, 0x26, "invalid charmap handle" )
 FT_ERRORDEF_( Invalid_Cache_Handle, 0x27, "invalid cache manager handle" )
 FT_ERRORDEF_( Invalid_Stream_Handle, 0x28, "invalid stream handle" )
 FT_ERRORDEF_( Too_Many_Drivers, 0x30, "too many modules" )
 FT_ERRORDEF_( Too_Many_Extensions, 0x31, "too many extensions" )
 FT_ERRORDEF_( Out_Of_Memory, 0x40, "out of memory" )
 FT_ERRORDEF_( Unlisted_Object, 0x41, "unlisted object" )
 FT_ERRORDEF_( Cannot_Open_Stream, 0x51, "cannot open stream" )
 FT_ERRORDEF_( Invalid_Stream_Seek, 0x52, "invalid stream seek" )
 FT_ERRORDEF_( Invalid_Stream_Skip, 0x53, "invalid stream skip" )
 FT_ERRORDEF_( Invalid_Stream_Read, 0x54, "invalid stream read" )
 FT_ERRORDEF_( Invalid_Stream_Operation, 0x55, "invalid stream operation" )
 FT_ERRORDEF_( Invalid_Frame_Operation, 0x56, "invalid frame operation" )
 FT_ERRORDEF_( Nested_Frame_Access, 0x57, "nested frame access" )
 FT_ERRORDEF_( Invalid_Frame_Read, 0x58, "invalid frame read" )
 FT_ERRORDEF_( Raster_Uninitialized, 0x60, "raster uninitialized" )
 FT_ERRORDEF_( Raster_Corrupted, 0x61, "raster corrupted" )
 FT_ERRORDEF_( Raster_Overflow, 0x62, "raster overflow" )
 FT_ERRORDEF_( Raster_Negative_Height, 0x63, "negative height while rastering" )
 FT_ERRORDEF_( Too_Many_Caches, 0x70, "too many registered caches" )
 FT_ERRORDEF_( Invalid_Opcode, 0x80, "invalid opcode" )
 FT_ERRORDEF_( Too_Few_Arguments, 0x81, "too few arguments" )
 FT_ERRORDEF_( Stack_Overflow, 0x82, "stack overflow" )
 FT_ERRORDEF_( Code_Overflow, 0x83, "code overflow" )
 FT_ERRORDEF_( Bad_Argument, 0x84, "bad argument" )
 FT_ERRORDEF_( Divide_By_Zero, 0x85, "division by zero" )
 FT_ERRORDEF_( Invalid_Reference, 0x86, "invalid reference" )
 FT_ERRORDEF_( Debug_OpCode, 0x87, "found debug opcode" )
 FT_ERRORDEF_( ENDF_In_Exec_Stream, 0x88, "found ENDF opcode in execution stream" )
 FT_ERRORDEF_( Nested_DEFS, 0x89, "nested DEFS" )
 FT_ERRORDEF_( Invalid_CodeRange, 0x8A, "invalid code range" )
 FT_ERRORDEF_( Execution_Too_Long, 0x8B, "execution context too long" )
 FT_ERRORDEF_( Too_Many_Function_Defs, 0x8C, "too many function definitions" )
 FT_ERRORDEF_( Too_Many_Instruction_Defs, 0x8D, "too many instruction definitions" )
 FT_ERRORDEF_( Table_Missing, 0x8E, "SFNT font table missing" )
 FT_ERRORDEF_( Horiz_Header_Missing, 0x8F, "horizontal header (hhea) table missing" )
 FT_ERRORDEF_( Locations_Missing, 0x90, "locations (loca) table missing" )
 FT_ERRORDEF_( Name_Table_Missing, 0x91, "name table missing" )
 FT_ERRORDEF_( CMap_Table_Missing, 0x92, "character map (cmap) table missing" )
 FT_ERRORDEF_( Hmtx_Table_Missing, 0x93, "horizontal metrics (hmtx) table missing" )
 FT_ERRORDEF_( Post_Table_Missing, 0x94, "PostScript (post) table missing" )
 FT_ERRORDEF_( Invalid_Horiz_Metrics, 0x95, "invalid horizontal metrics" )
 FT_ERRORDEF_( Invalid_CharMap_Format, 0x96, "invalid character map (cmap) format" )
 FT_ERRORDEF_( Invalid_PPem, 0x97, "invalid ppem value" )
 FT_ERRORDEF_( Invalid_Vert_Metrics, 0x98, "invalid vertical metrics" )
 FT_ERRORDEF_( Could_Not_Find_Context, 0x99, "could not find context" )
 FT_ERRORDEF_( Invalid_Post_Table_Format, 0x9A, "invalid PostScript (post) table format" )
 FT_ERRORDEF_( Invalid_Post_Table, 0x9B, "invalid PostScript (post) table" )
 FT_ERRORDEF_( Syntax_Error, 0xA0, "opcode syntax error" )
 FT_ERRORDEF_( Stack_Underflow, 0xA1, "argument stack underflow" )
 FT_ERRORDEF_( Ignore, 0xA2, "ignore" )
 FT_ERRORDEF_( Missing_Startfont_Field, 0xB0, "`STARTFONT' field missing" )
 FT_ERRORDEF_( Missing_Font_Field, 0xB1, "`FONT' field missing" )
 FT_ERRORDEF_( Missing_Size_Field, 0xB2, "`SIZE' field missing" )
 FT_ERRORDEF_( Missing_Chars_Field, 0xB3, "`CHARS' field missing" )
 FT_ERRORDEF_( Missing_Startchar_Field, 0xB4, "`STARTCHAR' field missing" )
 FT_ERRORDEF_( Missing_Encoding_Field, 0xB5, "`ENCODING' field missing" )
 FT_ERRORDEF_( Missing_Bbx_Field, 0xB6, "`BBX' field missing" )
 */

/* 
FT_TRACE_DEF( any )
FT_TRACE_DEF( calc )
FT_TRACE_DEF( memory )
FT_TRACE_DEF( stream )
FT_TRACE_DEF( io )
FT_TRACE_DEF( list )
FT_TRACE_DEF( init )
FT_TRACE_DEF( objs )
FT_TRACE_DEF( outline )
FT_TRACE_DEF( glyph )
FT_TRACE_DEF( raster )
FT_TRACE_DEF( smooth )
FT_TRACE_DEF( mm )
FT_TRACE_DEF( raccess )
FT_TRACE_DEF( cache )
FT_TRACE_DEF( sfobjs )
FT_TRACE_DEF( ttcmap )
FT_TRACE_DEF( ttkern )
FT_TRACE_DEF( ttload )
FT_TRACE_DEF( ttpost )
FT_TRACE_DEF( ttsbit )
FT_TRACE_DEF( ttdriver )
FT_TRACE_DEF( ttgload )
FT_TRACE_DEF( ttinterp )
FT_TRACE_DEF( ttobjs )
FT_TRACE_DEF( ttpload )
FT_TRACE_DEF( ttgxvar )
FT_TRACE_DEF( t1driver )
FT_TRACE_DEF( t1gload )
FT_TRACE_DEF( t1hint )
FT_TRACE_DEF( t1load )
FT_TRACE_DEF( t1objs )
FT_TRACE_DEF( t1parse )
FT_TRACE_DEF( t1decode )
FT_TRACE_DEF( psobjs )
FT_TRACE_DEF( pshrec )
FT_TRACE_DEF( pshalgo1 )
FT_TRACE_DEF( pshalgo2 )
FT_TRACE_DEF( cffdriver )
FT_TRACE_DEF( cffgload )
FT_TRACE_DEF( cffload )
FT_TRACE_DEF( cffobjs )
FT_TRACE_DEF( cffparse )
FT_TRACE_DEF( t42 )
FT_TRACE_DEF( cidafm )
FT_TRACE_DEF( ciddriver )
FT_TRACE_DEF( cidgload )
FT_TRACE_DEF( cidload )
FT_TRACE_DEF( cidobjs )
FT_TRACE_DEF( cidparse )
FT_TRACE_DEF( winfnt )
FT_TRACE_DEF( pcfdriver )
FT_TRACE_DEF( pcfread )
FT_TRACE_DEF( bdfdriver )
FT_TRACE_DEF( bdflib )
FT_TRACE_DEF( pfr )
FT_TRACE_DEF( otvmodule )
FT_TRACE_DEF( otvcommon )
FT_TRACE_DEF( otvbase )
FT_TRACE_DEF( otvgdef )
FT_TRACE_DEF( otvgpos )
FT_TRACE_DEF( otvgsub )
FT_TRACE_DEF( otvjstf )
*/

/*
FT_USE_MODULE(autofit_module_class)
FT_USE_MODULE(tt_driver_class)
FT_USE_MODULE(t1_driver_class)
FT_USE_MODULE(cff_driver_class)
FT_USE_MODULE(t1cid_driver_class)
FT_USE_MODULE(pfr_driver_class)
FT_USE_MODULE(t42_driver_class)
FT_USE_MODULE(winfnt_driver_class)
FT_USE_MODULE(pcf_driver_class)
FT_USE_MODULE(psaux_module_class)
FT_USE_MODULE(psnames_module_class)
FT_USE_MODULE(pshinter_module_class)
FT_USE_MODULE(ft_raster1_renderer_class)
FT_USE_MODULE(sfnt_module_class)
FT_USE_MODULE(ft_smooth_renderer_class)
FT_USE_MODULE(ft_smooth_lcd_renderer_class)
FT_USE_MODULE(ft_smooth_lcdv_renderer_class)
FT_USE_MODULE(otv_module_class)
FT_USE_MODULE(bdf_driver_class)
*/
