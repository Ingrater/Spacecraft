module sound.vorbisfile;

import base.sharedlib;
import base.utilsD2;

private string dll_declare(string name){
	return "static " ~ name ~ " " ~ name[3..name.length] ~ ";";
}

private string dll_init(string name){
	string sname = name[3..name.length];
	return sname ~ " = cast( typeof ( " ~ sname ~ ") ) GetProc(`" ~ name ~ "`);";
}

class ov {
	mixin SharedLib!();
	
	struct vorbis_info{
	  int _version;
	  int channels;
	  int rate;

	  int bitrate_upper;
	  int bitrate_nominal;
	  int bitrate_lower;
	  int bitrate_window;

	  void *codec_setup;
	};
	
	struct ogg_sync_state {
	  ubyte *data;
	  int storage;
	  int fill;
	  int returned;

	  int unsynced;
	  int headerbytes;
	  int bodybytes;
	};
	
	struct ogg_stream_state {
	  ubyte   *body_data;    /* bytes from packet bodies */
	  int    body_storage;          /* storage elements allocated */
	  int    body_fill;             /* elements stored; fill mark */
	  int    body_returned;         /* elements of fill returned */


	  int     *lacing_vals;      /* The values that will go to the segment table */
	  long *granule_vals; /* granulepos values for headers. Not compact
									this way, but it is simple coupled to the
									lacing fifo */
	  int    lacing_storage;
	  int    lacing_fill;
	  int    lacing_packet;
	  int    lacing_returned;

	  ubyte    header[282];      /* working space for header encode */
	  int              header_fill;

	  int     e_o_s;          /* set when we have buffered the last packet in the
								 logical bitstream */
	  int     b_o_s;          /* set after we've written the initial page
								 of a logical bitstream */
	  int    serialno;
	  int    pageno;
	  long  packetno;  /* sequence number for decode; the framing
								 knows where there's a hole in the data,
								 but we need coupling so that the codec
								 (which is in a seperate abstraction
								 layer) also knows about the gap */
	  long   granulepos;

	};
	
	struct vorbis_dsp_state{
	  int analysisp;
	  vorbis_info *vi;

	  float **pcm;
	  float **pcmret;
	  int      pcm_storage;
	  int      pcm_current;
	  int      pcm_returned;

	  int  preextrapolate;
	  int  eofflag;

	  int lW;
	  int W;
	  int nW;
	  int centerW;

	  long granulepos;
	  long sequence;

	  long glue_bits;
	  long time_bits;
	  long floor_bits;
	  long res_bits;

	  void       *backend_state;
	};
	
	struct oggpack_buffer{
	  int endbyte;
	  int  endbit;

	  ubyte *buffer;
	  ubyte *ptr;
	  int storage;
	};
	
	struct vorbis_block{
	  /* necessary stream state for linking to the framing abstraction */
	  float  **pcm;       /* this is a pointer into local storage */
	  oggpack_buffer opb;

	  int  lW;
	  int  W;
	  int  nW;
	  int   pcmend;
	  int   mode;

	  int         eofflag;
	  long granulepos;
	  long sequence;
	  vorbis_dsp_state *vd; /* For read-only access of configuration */

	  /* local storage to avoid remallocing; it's up to the mapping to
		 structure it */
	  void               *localstore;
	  long                localtop;
	  long                localalloc;
	  long                totaluse;
	  void				 *reap;

	  /* bitmetrics for the frame */
	  long glue_bits;
	  long time_bits;
	  long floor_bits;
	  long res_bits;

	  void *internal;

	};
	
	extern(C){
		struct ov_callbacks{
			size_t function(void *ptr, size_t size, size_t nmemb, void *datasource) read_func;
			int    function(void *datasource, long offset, int whence) seek_func;
			int    function(void *datasource) close_func;
			int   function(void *datasource) tell_func;
		};
	}
	
	struct OggVorbis_File {
	  void            *datasource; /* Pointer to a FILE *, etc. */
	  int              seekable;
	  int			   offset;
	  int		       end;
	  ogg_sync_state   oy;

	  /* If the FILE handle isn't seekable (eg, a pipe), only the current
		 stream appears */
	  int              links;
	  long            *offsets;
	  long            *dataoffsets;
	  int             *serialnos;
	  long            *pcmlengths; /* overloaded to maintain binary
									  compatability; x2 size, stores both
									  beginning and end values */
	  void		      *vi;
	  void			  *vc;

	  /* Decoding working state local storage */
	  long             pcm_offset;
	  int              ready_state;
	  int              current_serialno;
	  int              current_link;

	  double           bittrack;
	  double           samptrack;

	  ogg_stream_state os; /* take physical pages, weld into a logical
							  stream of packets */
	  vorbis_dsp_state vd; /* central working state for the packet->PCM decoder */
	  vorbis_block     vb; /* local working space for packet->PCM decode */

	  ov_callbacks callbacks;

	};
	
	extern(C){
		alias vorbis_info* function(OggVorbis_File *vf,int link) ov_info;
		alias int function(const(char)* path,OggVorbis_File *vf) ov_fopen;
		alias int function(OggVorbis_File *vf,byte *buffer,int length,
                    int bigendianp,int word,int sgned,int *bitstream) ov_read;
		alias int function(OggVorbis_File *vf) ov_clear;
		alias int function(OggVorbis_File *vf,int pos) ov_raw_seek;
	}
	
	//This compile time function generates the function pointer variables	
	mixin( generateDllCode!(ov)(&dll_declare) );
	
	static void LoadDll(string windowsName, string linuxName){
		LoadImpl(windowsName,linuxName);
		//This compile time function generates the calls to load the functions from the dll
		mixin ( generateDllCode!(ov)(&dll_init) );
	}
}