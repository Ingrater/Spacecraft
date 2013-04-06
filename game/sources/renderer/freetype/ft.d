/*
 * File:	freetype/ft.d
 * Author:	John Reimer 
 * Date:    2005-09-18  Initial release
 *
 * Updated: 2005-09-25  Minor changes - JJR @ dsource.org
 */

module renderer.freetype.ft;

public import renderer.freetype.def;
import thBase.sharedlib;
import base.utilsD2;

private string dll_declare(string name){
	return "static " ~ name ~ " " ~ name[3..name.length] ~ ";";
}

private string dll_init(string name){
	string sname = name[3..name.length];
	return sname ~ " = cast( typeof ( " ~ sname ~ ") ) GetProc(`" ~ name ~ "`);";
}

class ft {
	mixin SharedLib!();

// The following was mostly auto-generated from the C Freetype source using a python script

	extern(C)
	{
		alias FT_Error		function( FT_Library *alibrary )
				FT_Init_FreeType;
		alias void		function( FT_Library library, FT_Int *amajor, FT_Int *aminor, FT_Int *apatch )
				FT_Library_Version;
		alias FT_Error		function( FT_Library library )
				FT_Done_FreeType;
		alias FT_Error		function( FT_Library library, const(char)* filepathname, FT_Long face_index, FT_Face *aface )
				FT_New_Face;
		alias FT_Error		function( FT_Library library, FT_Byte* file_base, FT_Long file_size, FT_Long face_index, FT_Face *aface )
				FT_New_Memory_Face;
		alias FT_Error		function( FT_Library library, FT_Open_Args* args, FT_Long face_index, FT_Face *aface )
				FT_Open_Face;
		alias FT_Error		function( FT_Face face, char* filepathname )
				FT_Attach_File;
		alias FT_Error		function( FT_Face face, FT_Open_Args* parameters )
				FT_Attach_Stream;
		alias FT_Error		function( FT_Face face )
				FT_Done_Face;
		alias FT_Error		function( FT_Face face, FT_F26Dot6 char_width, FT_F26Dot6 char_height, FT_UInt horz_resolution, FT_UInt vert_resolution )
				FT_Set_Char_Size;
		alias FT_Error		function( FT_Face face, FT_UInt pixel_width, FT_UInt pixel_height )
				FT_Set_Pixel_Sizes;
		alias FT_Error		function( FT_Face face, FT_UInt glyph_index, FT_Int32 load_flags )
				FT_Load_Glyph;
		alias FT_Error		function( FT_Face face, FT_ULong char_code, FT_Int32 load_flags )
				FT_Load_Char;
		alias void		function( FT_Face face, FT_Matrix* matrix, FT_Vector* delta )
				FT_Set_Transform;
		alias FT_Error		function( FT_GlyphSlot slot, FT_Render_Mode render_mode )
				FT_Render_Glyph;
		alias FT_Error		function( FT_Face face, FT_UInt left_glyph, FT_UInt right_glyph, FT_UInt kern_mode, FT_Vector *akerning )
				FT_Get_Kerning;
		alias FT_Error		function( FT_Face face, FT_UInt glyph_index, FT_Pointer buffer, FT_UInt buffer_max )
				FT_Get_Glyph_Name;
		alias char*		function( FT_Face face )
				FT_Get_Postscript_Name;
		alias FT_Error		function( FT_Face face, FT_Encoding encoding )
				FT_Select_Charmap;
		alias FT_Error		function( FT_Face face, FT_CharMap charmap )
				FT_Set_Charmap;
		alias FT_Int		function( FT_CharMap charmap )
				FT_Get_Charmap_Index;
		alias FT_UInt		function( FT_Face face, FT_ULong charcode )
				FT_Get_Char_Index;
		alias FT_ULong		function( FT_Face face, FT_UInt *agindex )
				FT_Get_First_Char;
		alias FT_ULong		function( FT_Face face, FT_ULong char_code, FT_UInt *agindex )
				FT_Get_Next_Char;
		alias FT_UInt		function( FT_Face face, FT_String* glyph_name )
				FT_Get_Name_Index;
		alias FT_Long		function( FT_Long a, FT_Long b, FT_Long c )
				FT_MulDiv;
		/*alias FT_Long		function( FT_Long a, FT_Long b )
				FT_MulFix;*/
		alias FT_Long		function( FT_Long a, FT_Long b )
				FT_DivFix;
		alias FT_Fixed		function( FT_Fixed a )
				FT_RoundFix;
		alias FT_Fixed		function( FT_Fixed a )
				FT_CeilFix;
		alias FT_Fixed		function( FT_Fixed a )
				FT_FloorFix;
		alias void		function( FT_Vector* vec, FT_Matrix* matrix )
				FT_Vector_Transform;
		alias FT_ListNode		function( FT_List list, void* data )
				FT_List_Find;
		alias void		function( FT_List list, FT_ListNode node )
				FT_List_Add;
		alias void		function( FT_List list, FT_ListNode node )
				FT_List_Insert;
		alias void		function( FT_List list, FT_ListNode node )
				FT_List_Remove;
		alias void		function( FT_List list, FT_ListNode node )
				FT_List_Up;
		alias FT_Error		function( FT_List list, FT_List_Iterator iterator, void* user )
				FT_List_Iterate;
		alias void		function( FT_List list, FT_List_Destructor destroy, FT_Memory memory, void* user )
				FT_List_Finalize;
		alias FT_Error		function( FT_Outline* outline, FT_Outline_Funcs* func_interface, void* user )
				FT_Outline_Decompose;
		alias FT_Error		function( FT_Library library, FT_UInt numPoints, FT_Int numContours, FT_Outline *anoutline )
				FT_Outline_New;
		alias FT_Error		function( FT_Memory memory, FT_UInt numPoints, FT_Int numContours, FT_Outline *anoutline )
				FT_Outline_New_Internal;
		alias FT_Error		function( FT_Library library, FT_Outline* outline )
				FT_Outline_Done;
		alias FT_Error		function( FT_Memory memory, FT_Outline* outline )
				FT_Outline_Done_Internal;
		alias FT_Error		function( FT_Outline* outline )
				FT_Outline_Check;
		alias void		function( FT_Outline* outline, FT_BBox *acbox )
				FT_Outline_Get_CBox;
		alias void		function( FT_Outline* outline, FT_Pos xOffset, FT_Pos yOffset )
				FT_Outline_Translate;
		alias FT_Error		function( FT_Outline* source, FT_Outline *target )
				FT_Outline_Copy;
		alias void		function( FT_Outline* outline, FT_Matrix* matrix )
				FT_Outline_Transform;
		alias FT_Error		function( FT_Outline* outline, FT_Pos strength )
				FT_Outline_Embolden;
		alias void		function( FT_Outline* outline )
				FT_Outline_Reverse;
		alias FT_Error		function( FT_Library library, FT_Outline* outline, FT_Bitmap *abitmap )
				FT_Outline_Get_Bitmap;
		alias FT_Error		function( FT_Library library, FT_Outline* outline, FT_Raster_Params* params )
				FT_Outline_Render;
		alias FT_Orientation		function( FT_Outline* outline )
				FT_Outline_Get_Orientation;
		alias FT_Error		function( FT_Face face, FT_Size* size )
				FT_New_Size;
		alias FT_Error		function( FT_Size size )
				FT_Done_Size;
		alias FT_Error		function( FT_Size size )
				FT_Activate_Size;
		alias FT_Error		function( FT_Library library, FT_Module_Class* clazz )
				FT_Add_Module;
		alias FT_Module		function( FT_Library library, char* module_name )
				FT_Get_Module;
		alias FT_Error		function( FT_Library library, FT_Module mod )
				FT_Remove_Module;
		alias FT_Error		function( FT_Memory memory, FT_Library *alibrary )
				FT_New_Library;
		alias FT_Error		function( FT_Library library )
				FT_Done_Library;
		alias void		function( FT_Library library, FT_UInt hook_index, FT_DebugHook_Func debug_hook )
				FT_Set_Debug_Hook;
		alias void		function( FT_Library library )
				FT_Add_Default_Modules;
		alias FT_Error		function( FT_GlyphSlot slot, FT_Glyph *aglyph )
				FT_Get_Glyph;
		alias FT_Error		function( FT_Glyph source, FT_Glyph *target )
				FT_Glyph_Copy;
		alias FT_Error		function( FT_Glyph glyph, FT_Matrix* matrix, FT_Vector* delta )
				FT_Glyph_Transform;
		alias void		function( FT_Glyph glyph, FT_UInt bbox_mode, FT_BBox *acbox )
				FT_Glyph_Get_CBox;
		alias FT_Error		function( FT_Glyph* the_glyph, FT_Render_Mode render_mode, FT_Vector* origin, FT_Bool destroy )
				FT_Glyph_To_Bitmap;
		alias void		function( FT_Glyph glyph )
				FT_Done_Glyph;
		alias void		function( FT_Matrix* a, FT_Matrix* b )
				FT_Matrix_Multiply;
		alias FT_Error		function( FT_Matrix* matrix )
				FT_Matrix_Invert;
		alias FT_Renderer		function( FT_Library library, FT_Glyph_Format format )
				FT_Get_Renderer;
		alias FT_Error		function( FT_Library library, FT_Renderer renderer, FT_UInt num_params, FT_Parameter* parameters )
				FT_Set_Renderer;
		alias FT_Int		function( FT_Face face )
				FT_Has_PS_Glyph_Names;
		alias FT_Error		function( FT_Face face, PS_FontInfoRec *afont_info )
				FT_Get_PS_Font_Info;
		alias FT_Error		function( FT_Face face, PS_PrivateRec *afont_private )
				FT_Get_PS_Font_Private;
		alias void*		function( FT_Face face, FT_Sfnt_Tag tag )
				FT_Get_Sfnt_Table;
		alias FT_Error		function( FT_Face face, FT_ULong tag, FT_Long offset, FT_Byte* buffer, FT_ULong* length )
				FT_Load_Sfnt_Table;
		alias FT_Error		function( FT_Face face, FT_UInt table_index, FT_ULong *tag, FT_ULong *length )
				FT_Sfnt_Table_Info;
		alias FT_ULong		function( FT_CharMap charmap )
				FT_Get_CMap_Language_ID;
		/*alias FT_Error		function( FT_Face face, char* *acharset_encoding, char* *acharset_registry )
				FT_Get_BDF_Charset_ID;*/
		/*alias FT_Error		function( FT_Face face, char* prop_name, BDF_PropertyRec *aproperty )
				FT_Get_BDF_Property;*/
		alias FT_Error		function( FT_Stream stream, FT_Stream source )
				FT_Stream_OpenGzip;
		alias FT_Error		function( FT_Stream stream, FT_Stream source )
				FT_Stream_OpenLZW;
		alias FT_Error		function( FT_Face face, FT_WinFNT_HeaderRec *aheader )
				FT_Get_WinFNT_Header;
		alias void		function( FT_Bitmap *abitmap )
				FT_Bitmap_New;
		alias FT_Error		function( FT_Library library, FT_Bitmap *source, FT_Bitmap *target)
				FT_Bitmap_Copy;
		alias FT_Error		function( FT_Library library, FT_Bitmap* bitmap, FT_Pos xStrength, FT_Pos yStrength )
				FT_Bitmap_Embolden;
		alias FT_Error		function( FT_Library library, FT_Bitmap *source, FT_Bitmap *target, FT_Int alignment )
				FT_Bitmap_Convert;
		alias FT_Error		function( FT_Library library, FT_Bitmap *bitmap )
				FT_Bitmap_Done;
		alias FT_Error		function( FT_Outline* outline, FT_BBox *abbox )
				FT_Outline_Get_BBox;
		alias FT_Error		function( FT_Library library, FT_UInt max_faces, FT_UInt max_sizes, FT_ULong max_bytes, FTC_Face_Requester requester, FT_Pointer req_data, FTC_Manager *amanager )
				FTC_Manager_New;
		alias void		function( FTC_Manager manager )
				FTC_Manager_Reset;
		alias void		function( FTC_Manager manager )
				FTC_Manager_Done;
		alias FT_Error		function( FTC_Manager manager, FTC_FaceID face_id, FT_Face *aface )
				FTC_Manager_LookupFace;
		alias FT_Error		function( FTC_Manager manager, FTC_Scaler scaler, FT_Size *asize )
				FTC_Manager_LookupSize;
		alias void		function( FTC_Node node, FTC_Manager manager )
				FTC_Node_Unref;
		alias void		function( FTC_Manager manager, FTC_FaceID face_id )
				FTC_Manager_RemoveFaceID;
		alias FT_Error		function( FTC_Manager manager, FTC_CMapCache *acache )
				FTC_CMapCache_New;
		alias FT_UInt		function( FTC_CMapCache cache, FTC_FaceID face_id, FT_Int cmap_index, FT_UInt32 char_code )
				FTC_CMapCache_Lookup;
		alias FT_Error		function( FTC_Manager manager, FTC_ImageCache *acache )
				FTC_ImageCache_New;
		alias FT_Error		function( FTC_ImageCache cache, FTC_ImageType type, FT_UInt gindex, FT_Glyph *aglyph, FTC_Node *anode )
				FTC_ImageCache_Lookup;
		alias FT_Error		function( FTC_Manager manager, FTC_SBitCache *acache )
				FTC_SBitCache_New;
		alias FT_Error		function( FTC_SBitCache cache, FTC_ImageType type, FT_UInt gindex, FTC_SBit *sbit, FTC_Node *anode )
				FTC_SBitCache_Lookup;
		alias FT_Error		function( FT_Face face, FT_Multi_Master *amaster )
				FT_Get_Multi_Master;
		alias FT_Error		function( FT_Face face, FT_MM_Var* *amaster )
				FT_Get_MM_Var;
		alias FT_Error		function( FT_Face face, FT_UInt num_coords, FT_Long* coords )
				FT_Set_MM_Design_Coordinates;
		alias FT_Error		function( FT_Face face, FT_UInt num_coords, FT_Fixed* coords )
				FT_Set_Var_Design_Coordinates;
		alias FT_Error		function( FT_Face face, FT_UInt num_coords, FT_Fixed* coords )
				FT_Set_MM_Blend_Coordinates;
		alias FT_Error		function( FT_Face face, FT_UInt num_coords, FT_Fixed* coords )
				FT_Set_Var_Blend_Coordinates;
		alias FT_UInt		function( FT_Face face )
				FT_Get_Sfnt_Name_Count;
		alias FT_Error		function( FT_Face face, FT_UInt idx, FT_SfntName *aname )
				FT_Get_Sfnt_Name;
		/*alias FT_Error		function( FT_Face face, FT_UInt validation_flags, FT_Bytes *BASE_table, FT_Bytes *GDEF_table, FT_Bytes *GPOS_table, FT_Bytes *GSUB_table, FT_Bytes *JSTF_table )
				FT_OpenType_Validate;*/
		alias FT_Fixed		function( FT_Angle angle )
				FT_Sin;
		alias FT_Fixed		function( FT_Angle angle )
				FT_Cos;
		alias FT_Fixed		function( FT_Angle angle )
				FT_Tan;
		alias FT_Angle		function( FT_Fixed x, FT_Fixed y )
				FT_Atan2;
		alias FT_Angle		function( FT_Angle angle1, FT_Angle angle2 )
				FT_Angle_Diff;
		alias void		function( FT_Vector* vec, FT_Angle angle )
				FT_Vector_Unit;
		alias void		function( FT_Vector* vec, FT_Angle angle )
				FT_Vector_Rotate;
		alias FT_Fixed		function( FT_Vector* vec )
				FT_Vector_Length;
		alias void		function( FT_Vector* vec, FT_Fixed *length, FT_Angle *angle )
				FT_Vector_Polarize;
		alias void		function( FT_Vector* vec, FT_Fixed length, FT_Angle angle )
				FT_Vector_From_Polar;
		alias FT_StrokerBorder		function( FT_Outline* outline )
				FT_Outline_GetInsideBorder;
		alias FT_StrokerBorder		function( FT_Outline* outline )
				FT_Outline_GetOutsideBorder;
		alias FT_Error		function( FT_Memory memory, FT_Stroker *astroker )
				FT_Stroker_New;
		alias void		function( FT_Stroker stroker, FT_Fixed radius, FT_Stroker_LineCap line_cap, FT_Stroker_LineJoin line_join, FT_Fixed miter_limit )
				FT_Stroker_Set;
		alias void		function( FT_Stroker stroker )
				FT_Stroker_Rewind;
		alias FT_Error		function( FT_Stroker stroker, FT_Outline* outline, FT_Bool opened )
				FT_Stroker_ParseOutline;
		alias FT_Error		function( FT_Stroker stroker, FT_Vector* to, FT_Bool open )
				FT_Stroker_BeginSubPath;
		alias FT_Error		function( FT_Stroker stroker )
				FT_Stroker_EndSubPath;
		alias FT_Error		function( FT_Stroker stroker, FT_Vector* to )
				FT_Stroker_LineTo;
		alias FT_Error		function( FT_Stroker stroker, FT_Vector* control, FT_Vector* to )
				FT_Stroker_ConicTo;
		alias FT_Error		function( FT_Stroker stroker, FT_Vector* control1, FT_Vector* control2, FT_Vector* to )
				FT_Stroker_CubicTo;
		alias FT_Error		function( FT_Stroker stroker, FT_StrokerBorder border, FT_UInt *anum_points, FT_UInt *anum_contours )
				FT_Stroker_GetBorderCounts;
		alias void		function( FT_Stroker stroker, FT_StrokerBorder border, FT_Outline* outline )
				FT_Stroker_ExportBorder;
		alias FT_Error		function( FT_Stroker stroker, FT_UInt *anum_points, FT_UInt *anum_contours )
				FT_Stroker_GetCounts;
		alias void		function( FT_Stroker stroker, FT_Outline* outline )
				FT_Stroker_Export;
		alias void		function( FT_Stroker stroker )
				FT_Stroker_Done;
		alias FT_Error		function( FT_Glyph *pglyph, FT_Stroker stroker, FT_Bool destroy )
				FT_Glyph_Stroke;
		alias FT_Error		function( FT_Glyph *pglyph, FT_Stroker stroker, FT_Bool inside, FT_Bool destroy )
				FT_Glyph_StrokeBorder;
		alias void		function( FT_GlyphSlot slot )
				FT_GlyphSlot_Embolden;
		alias void		function( FT_GlyphSlot slot )
				FT_GlyphSlot_Oblique;
		/*alias void		function( FTC_MruNode *plist, FTC_MruNode node )
				FTC_MruNode_Prepend;
		alias void		function( FTC_MruNode *plist, FTC_MruNode node )
				FTC_MruNode_Up;
		alias void		function( FTC_MruNode *plist, FTC_MruNode node )
				FTC_MruNode_Remove;
		alias void		function( FTC_MruList list, FTC_MruListClass clazz, FT_UInt max_nodes, FT_Pointer data, FT_Memory memory )
				FTC_MruList_Init;
		alias void		function( FTC_MruList list )
				FTC_MruList_Reset;
		alias void		function( FTC_MruList list )
				FTC_MruList_Done;
		alias FTC_MruNode		function( FTC_MruList list, FT_Pointer key )
				FTC_MruList_Find;
		alias FT_Error		function( FTC_MruList list, FT_Pointer key, FTC_MruNode *anode )
				FTC_MruList_New;
		alias FT_Error		function( FTC_MruList list, FT_Pointer key, FTC_MruNode *pnode )
				FTC_MruList_Lookup;
		alias void		function( FTC_MruList list, FTC_MruNode node )
				FTC_MruList_Remove;
		alias void		function( FTC_MruList list, FTC_MruNode_CompareFunc selection, FT_Pointer key )
				FTC_MruList_RemoveSelection;
		alias void		function( FTC_Node node, FTC_Manager manager )
				ftc_node_destroy;
		alias FT_Error		function( FTC_Cache cache )
				FTC_Cache_Init;
		alias void		function( FTC_Cache cache )
				FTC_Cache_Done;
		alias FT_Error		function( FTC_Cache cache, FT_UInt32 hash, FT_Pointer query, FTC_Node *anode )
				FTC_Cache_Lookup;
		alias FT_Error		function( FTC_Cache cache, FT_UInt32 hash, FT_Pointer query, FTC_Node *anode )
				FTC_Cache_NewNode;
		alias void		function( FTC_Cache cache, FTC_FaceID face_id )
				FTC_Cache_RemoveFaceID;
		alias void		function( FTC_Manager manager )
				FTC_Manager_Compress;
		alias FT_UInt		function( FTC_Manager manager, FT_UInt count )
				FTC_Manager_FlushN;
		alias FT_Error		function( FTC_Manager manager, FTC_CacheClass clazz, FTC_Cache *acache )
				FTC_Manager_RegisterCache;
		alias void		function( FTC_GNode node, FT_UInt gindex, FTC_Family family )
				FTC_GNode_Init;
		alias FT_Bool		function( FTC_GNode gnode, FTC_GQuery gquery )
				FTC_GNode_Compare;
		alias void		function( FTC_GNode gnode, FTC_Cache cache )
				FTC_GNode_UnselectFamily;
		alias void		function( FTC_GNode node, FTC_Cache cache )
				FTC_GNode_Done;
		alias void		function( FTC_Family family, FTC_Cache cache )
				FTC_Family_Init;
		alias FT_Error		function( FTC_GCache cache )
				FTC_GCache_Init;
		alias void		function( FTC_GCache cache )
				FTC_GCache_Done;
		alias FT_Error		function( FTC_Manager manager, FTC_GCacheClass clazz, FTC_GCache *acache )
				FTC_GCache_New;
		alias FT_Error		function( FTC_GCache cache, FT_UInt32 hash, FT_UInt gindex, FTC_GQuery query, FTC_Node *anode )
				FTC_GCache_Lookup;
		alias void		function( FTC_INode inode, FTC_Cache cache )
				FTC_INode_Free;
		alias FT_Error		function( FTC_INode *pinode, FTC_GQuery gquery, FTC_Cache cache )
				FTC_INode_New;
		alias FT_ULong		function( FTC_INode inode )
				FTC_INode_Weight;
		alias void		function( FTC_SNode snode, FTC_Cache cache )
				FTC_SNode_Free;
		alias FT_Error		function( FTC_SNode *psnode, FTC_GQuery gquery, FTC_Cache cache )
				FTC_SNode_New;
		alias FT_ULong		function( FTC_SNode inode )
				FTC_SNode_Weight;
		alias FT_Bool		function( FTC_SNode snode, FTC_GQuery gquery, FTC_Cache cache )
				FTC_SNode_Compare;*/
		/*alias char*		function( FT_Face face )
				FT_Get_X11_Font_Format;*/
		/*alias FT_Error		function( FT_Memory memory, FT_Long size, void* *P )
				FT_Alloc;
		alias FT_Error		function( FT_Memory memory, FT_Long size, void* *p )
				FT_QAlloc;
		alias FT_Error		function( FT_Memory memory, FT_Long current, FT_Long size, void* *P )
				FT_Realloc;
		alias FT_Error		function( FT_Memory memory, FT_Long current, FT_Long size, void* *p )
				FT_QRealloc;
		alias void		function( FT_Memory memory, void* *P )
				FT_Free;
		alias FT_Error		function( FT_Memory memory, FT_GlyphLoader *aloader )
				FT_GlyphLoader_New;
		alias FT_Error		function( FT_GlyphLoader loader )
				FT_GlyphLoader_CreateExtra;
		alias void		function( FT_GlyphLoader loader )
				FT_GlyphLoader_Done;
		alias void		function( FT_GlyphLoader loader )
				FT_GlyphLoader_Reset;
		alias void		function( FT_GlyphLoader loader )
				FT_GlyphLoader_Rewind;
		alias FT_Error		function( FT_GlyphLoader loader, FT_UInt n_points, FT_UInt n_contours )
				FT_GlyphLoader_CheckPoints;
		alias FT_Error		function( FT_GlyphLoader loader, FT_UInt n_subs )
				FT_GlyphLoader_CheckSubGlyphs;
		alias void		function( FT_GlyphLoader loader )
				FT_GlyphLoader_Prepare;
		alias void		function( FT_GlyphLoader loader )
				FT_GlyphLoader_Add;
		alias FT_Error		function( FT_GlyphLoader target, FT_GlyphLoader source )
				FT_GlyphLoader_CopyPoints;
		alias FT_Pointer		function( FT_ServiceDesc service_descriptors, char* service_id )
				ft_service_list_lookup;
		alias FT_UInt32		function( FT_UInt32 value )
				ft_highpow2;
		alias FT_Error		function( FT_CMap_Class clazz, FT_Pointer init_data, FT_CharMap charmap, FT_CMap *acmap )
				FT_CMap_New;
		alias void		function( FT_CMap cmap )
				FT_CMap_Done;
		alias void*		function( FT_Library library, char* mod_name )
				FT_Get_Module_Interface;
		alias FT_Pointer		function( FT_Module mod, char* service_id )
				ft_module_get_service;
		alias FT_Error		function( FT_Face face, FT_GlyphSlot *aslot )
				FT_New_GlyphSlot;
		alias void		function( FT_GlyphSlot slot )
				FT_Done_GlyphSlot;
		alias void		function( FT_GlyphSlot slot )
				ft_glyphslot_free_bitmap;
		alias FT_Error		function( FT_GlyphSlot slot, FT_ULong size )
				ft_glyphslot_alloc_bitmap;
		alias void		function( FT_GlyphSlot slot, FT_Byte* buffer )
				ft_glyphslot_set_bitmap;
		alias FT_Renderer		function( FT_Library library, FT_Glyph_Format format, FT_ListNode* node )
				FT_Lookup_Renderer;
		alias FT_Error		function( FT_Library library, FT_GlyphSlot slot, FT_Render_Mode render_mode )
				FT_Render_Glyph_Internal;
		alias FT_Memory		function()
				FT_New_Memory;
		alias void		function( FT_Memory memory )
				FT_Done_Memory;
		alias FT_Error		function( FT_Stream stream, char* filepathname )
				FT_Stream_Open;
		alias FT_Error		function( FT_Library library, FT_Open_Args* args, FT_Stream *astream )
				FT_Stream_New;
		alias void		function( FT_Stream stream, FT_Int external )
				FT_Stream_Free;
		alias void		function( FT_Stream stream, FT_Byte* base, FT_ULong size )
				FT_Stream_OpenMemory;
		alias void		function( FT_Stream stream )
				FT_Stream_Close;
		alias FT_Error		function( FT_Stream stream, FT_ULong pos )
				FT_Stream_Seek;
		alias FT_Error		function( FT_Stream stream, FT_Long distance )
				FT_Stream_Skip;
		alias FT_Long		function( FT_Stream stream )
				FT_Stream_Pos;
		alias FT_Error		function( FT_Stream stream, FT_Byte* buffer, FT_ULong count )
				FT_Stream_Read;
		alias FT_Error		function( FT_Stream stream, FT_ULong pos, FT_Byte* buffer, FT_ULong count )
				FT_Stream_ReadAt;
		alias FT_ULong		function( FT_Stream stream, FT_Byte* buffer, FT_ULong count )
				FT_Stream_TryRead;
		alias FT_Error		function( FT_Stream stream, FT_ULong count )
				FT_Stream_EnterFrame;
		alias void		function( FT_Stream stream )
				FT_Stream_ExitFrame;
		alias FT_Error		function( FT_Stream stream, FT_ULong count, FT_Byte** pbytes )
				FT_Stream_ExtractFrame;
		alias void		function( FT_Stream stream, FT_Byte** pbytes )
				FT_Stream_ReleaseFrame;
		alias FT_Char		function( FT_Stream stream )
				FT_Stream_GetChar;
		alias FT_Short		function( FT_Stream stream )
				FT_Stream_GetShort;
		alias FT_Long		function( FT_Stream stream )
				FT_Stream_GetOffset;
		alias FT_Long		function( FT_Stream stream )
				FT_Stream_GetLong;
		alias FT_Short		function( FT_Stream stream )
				FT_Stream_GetShortLE;
		alias FT_Long		function( FT_Stream stream )
				FT_Stream_GetLongLE;
		alias FT_Char		function( FT_Stream stream, FT_Error* error )
				FT_Stream_ReadChar;
		alias FT_Short		function( FT_Stream stream, FT_Error* error )
				FT_Stream_ReadShort;
		alias FT_Long		function( FT_Stream stream, FT_Error* error )
				FT_Stream_ReadOffset;
		alias FT_Long		function( FT_Stream stream, FT_Error* error )
				FT_Stream_ReadLong;
		alias FT_Short		function( FT_Stream stream, FT_Error* error )
				FT_Stream_ReadShortLE;
		alias FT_Long		function( FT_Stream stream, FT_Error* error )
				FT_Stream_ReadLongLE;
		alias FT_Error		function( FT_Stream stream, FT_Frame_Field* fields, void* structure )
				FT_Stream_ReadFields;
		alias FT_Int		function()
				FT_Trace_Get_Count;
		alias char*		function( FT_Int idx )
				FT_Trace_Get_Name;
		alias void		function()
				ft_debug_init;
		alias FT_Int32		function( FT_Int32 x )
				FT_SqrtFixed;
		alias FT_Int32		function( FT_Int32 x )
				FT_Sqrt32;
		alias void		function( FT_Library library, FT_Stream stream, char* base_name, char** new_names, FT_Long* offsets, FT_Error* errors )
				FT_Raccess_Guess;
		alias FT_Error		function( FT_Library library, FT_Stream stream, FT_Long rfork_offset, FT_Long *map_offset, FT_Long *rdata_pos )
				FT_Raccess_Get_HeaderInfo;
		alias FT_Error		function( FT_Library library, FT_Stream stream, FT_Long map_offset, FT_Long rdata_pos, FT_Long tag, FT_Long **offsets, FT_Long *count )
				FT_Raccess_Get_DataOffsets;
		alias void		function( FT_Validator valid, FT_Byte* base, FT_Byte* limit, FT_ValidationLevel level )
				ft_validator_init;
		alias FT_Int		function( FT_Validator valid )
				ft_validator_run;
		alias void		function( FT_Validator valid, FT_Error error )
				ft_validator_error;*/
	}
	
	//This compile time function generates the function pointer variables	
	mixin( generateDllCode!(ft)(&dll_declare) );
	
	static void Load(string windowsName, string linuxName){
		LoadImpl(windowsName,linuxName);
		//This compile time function generates the calls to load the functions from the dll
		mixin ( generateDllCode!(ft)(&dll_init) );
	}
}