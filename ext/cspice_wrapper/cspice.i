/****************************************************************************************************************
* SWIG interface definitions to support the generation of wrappers around a subset of the NAIF CSPICE API.      *
* Note this contains actual copies of function declarations from the CSPICE header files as of version N0064.   *
* To use this with a different version of the CSPICE toolkit, modifications may be necessary                    *
****************************************************************************************************************/
%module cspice_wrapper 
%include "typemaps.i"
%include "cstring.i"
%include "carrays.i"

/* In the generated wrapper file, include the CSPICE headers.  We won't include most of them in the SWIG interface
file itself since we need to customize the generated wrappers */
%{
#include "SpiceUsr.h"
#include "SpiceZfc.h"
%}

/****************************************************************************************************************
* Custom macros to handle CSPICE's own strange ways of doing things                                             *
****************************************************************************************************************/

/* Treat SpiceBoolean as ruby bools */
%typemap(out) SpiceBoolean 
 "$result = ($1 == SPICETRUE) ? Qtrue : Qfalse;";

/* Declare a wrapper class around an array of doubles since this is a common pattern with CSPICE */
%array_class(SpiceDouble,SpiceDoubleArray);

/*
 * %output_maxsize_sizefirst(SIZE, TYPEMAP)
 *
 * This macro returns data in a string of some user-defined size.  It's based on cstring_output_maxsize, but modified
 * for the case in which the int max parameter is before the char* out parameter.
 *
 *     output_maxsize_sizefirst(int max, char *outx) {
 *     void foo(int max, char *outx) {
 *         sprintf(outx,"blah blah\n");
 *     }
 */
%define output_maxsize_sizefirst(SIZE,TYPEMAP)                       
%typemap(in,noblock=1,fragment=SWIG_AsVal_frag(size_t)) (SIZE, TYPEMAP) (int res, size_t size, char *buff = 0) {   
  res = SWIG_AsVal(size_t)($input, &size);
  if (!SWIG_IsOK(res)) {
    %argument_fail(res, "(SIZE, TYPEMAP)", $symname, $argnum);
  }
  buff= %new_array(size+1, char);
  $1 = %numeric_cast(size, $1_ltype);
  $2 = %static_cast(buff, $2_ltype);
}
%typemap(freearg,noblock=1,match="in") (SIZE, TYPEMAP) {
  if (buff$argnum) %delete_array(buff$argnum);
} 
%typemap(argout,noblock=1,fragment="SWIG_FromCharPtr") (SIZE,TYPEMAP) { 
  %append_output(SWIG_FromCharPtr($2));
}
%enddef


/* Import the typedefs used by CSPICE so SWIG will understand things like ConstSpiceChar* */
%import "SpiceZdf.h"

/* Import the SpiceCell typedef for the same reason */
%import "SpiceCel.h"

/****************************************************************************************************************
* The following are hacks to suppose CSPICE CELL structures within Ruby.  The sadistic asshat who devised these *
* fixed-size stack-stored types has given me serious heartburn on this one.  Cells can only be created using    *
* a bunch of macros, and are stored on the stack but with some pointer trickery thrown in.  As you might imagine*
* adapting such a monstrosity to a dynamic language with a mark and sweep garbage collector is, to put it mildly*
* a fucking pain in the ass.                                                                                    *
****************************************************************************************************************/
%inline %{

class SpiceCellBase {
public:
  SpiceCell* cell_pointer() {
    return &_cell;
  }

protected:
  SpiceCellBase() {}

  SpiceCell _cell;
};

class SpiceDoubleCell : public SpiceCellBase {
  public:
    SpiceDoubleCell(size_t size) {
      _cell_data = new SpiceDouble[SPICE_CELL_CTRLSZ + size];

      SpiceCell cell = { SPICE_DP,                                                
        0,                                                                
        static_cast<SpiceInt>(size),                                                             
        0,                                                                
        SPICETRUE,                                                        
        SPICEFALSE,                                                       
        SPICEFALSE,                                                       
        (void *) _cell_data,                                    
        (void *) &(_cell_data[SPICE_CELL_CTRLSZ])  };
      _cell = cell;
    }

    ~SpiceDoubleCell() {
      delete[] _cell_data;
      _cell_data = NULL;
    }

    /* Gets an element in a CSPICE double cell */
    SpiceDouble get_element(SpiceInt index) {
      double item;
      SPICE_CELL_GET_D(&_cell, index, &item);
      return item;
    }

    /* Sets an element in a CSPICE double cell */
    void set_element(SpiceInt index, double item) {
      SPICE_CELL_SET_D(item, index, &_cell);
    }

    /* Gets a range of values in a CSPICE double cell, into a SpiceDoubleArray.  Careful, no bounds checking on that array */
    void get_elements(SpiceInt index, SpiceInt length, SpiceDouble* array) {
      SpiceInt idx;

      for (idx = 0; idx < length; idx++) {
        SPICE_CELL_GET_D(&_cell, index + idx, &array[idx]);
      }
    }

    /* Sets a range of values in a CSPICE double cell copied from a SpiceDoubleArray */
    void set_elements(SpiceInt index, SpiceInt length, ConstSpiceDouble* array) {
      SpiceInt idx;

      for (idx = 0; idx < length; idx++) {
        SPICE_CELL_SET_D(array[idx], index + idx, &_cell);
      }
    }

  private:
    SpiceDouble* _cell_data;  
};

/** TODO: Use a SWIG macro so it's possible to declare int and double cells without all this code duplication */
class SpiceIntCell : public SpiceCellBase {
  public:
    SpiceIntCell(size_t size) {
      _cell_data = new SpiceInt[SPICE_CELL_CTRLSZ + size];

      SpiceCell cell = { SPICE_INT,                                                
        0,                                                                
        static_cast<SpiceInt>(size),                                                             
        0,                                                                
        SPICETRUE,                                                        
        SPICEFALSE,                                                       
        SPICEFALSE,                                                       
        (void *) _cell_data,                                    
        (void *) &(_cell_data[SPICE_CELL_CTRLSZ])  };
      _cell = cell;
    }

    ~SpiceIntCell() {
      delete[] _cell_data;
      _cell_data = NULL;
    }

    /* Gets an element in a CSPICE double cell */
    SpiceInt get_element(SpiceInt index) {
      SpiceInt item;
      SPICE_CELL_GET_I(&_cell, index, &item);
      return item;
    }

    /* Sets an element in a CSPICE double cell */
    void set_element(SpiceInt index, SpiceInt item) {
      SPICE_CELL_SET_I(item, index, &_cell);
    }

    /* Gets a range of values in a CSPICE double cell, into a SpiceIntArray.  Careful, no bounds checking on that array */
    void get_elements(SpiceInt index, SpiceInt length, SpiceInt* array) {
      SpiceInt idx;

      for (idx = 0; idx < length; idx++) {
        SPICE_CELL_GET_I(&_cell, index + idx, &array[idx]);
      }
    }

    /* Sets a range of values in a CSPICE double cell copied from a SpiceIntArray */
    void set_elements(SpiceInt index, SpiceInt length, ConstSpiceInt* array) {
      SpiceInt idx;

      for (idx = 0; idx < length; idx++) {
        SPICE_CELL_SET_I(array[idx], index + idx, &_cell);
      }
    }

  private:
    SpiceInt* _cell_data;  
};

%}

/****************************************************************************************************************
* The following are from SpiceZfc.h.  This is just a subset of the methods declared there, based on need.       *
* If you need to add additional functions, copy their declarations from SpiceZfc.h and then think carefully     *
* about which SWIG incantations will be required to make the generated wrapper work correctly                   *
****************************************************************************************************************/

typedef int       ftnlen;

%cstring_output_maxsize(char *trace, ftnlen trace_len);
int qcktrc_(char *trace, ftnlen trace_len);

/* expln_ is a very awkward method, so we'll wrap it in one that's less awkward, and use a typemap 
that tells SWIG expl is an ouptut string allocated to hold up to expl_len characters */
/*int expln_(char *msg, char *expl, ftnlen msg_len, ftnlen expl_len); */

%cstring_output_maxsize(char *expl, ftnlen expl_len);

%rename(expln_) expln_wrapper;

%inline %{
  int expln_wrapper(char* msg, char* expl, ftnlen expl_len) {
    return expln_(msg, expl, (ftnlen)strlen(msg), expl_len);
  }
%}


/****************************************************************************************************************
* The following are from SpiceZpr.h.  This is just a subset of the methods declared there, based on need.       *
* If you need to add additional functions, copy their declarations from SpiceZfc.h and then think carefully     *
* about which SWIG incantations will be required to make the generated wrapper work correctly                   *
****************************************************************************************************************/

void appndd_c ( SpiceDouble     item,
                   SpiceCell     * cell );
   
void appndi_c ( SpiceInt        item,
                   SpiceCell     * cell );

output_maxsize_sizefirst(SpiceInt            lenout,
                         SpiceChar         * name);
void bodc2s_c ( SpiceInt        code,
                   SpiceInt        lenout,
                   SpiceChar     * name );

%apply SpiceInt *OUTPUT { SpiceInt* dim };
void bodvrd_c ( ConstSpiceChar   * bodynm,
               ConstSpiceChar   * item,
               SpiceInt           maxn,
               SpiceInt         * dim,
               SpiceDouble      * values );

SpiceInt card_c ( SpiceCell  * cell );

 void copy_c (  SpiceCell   * cell,
                  SpiceCell   * copy  );

%apply SpiceDouble *OUTPUT { SpiceDouble* delta };
void deltet_c ( SpiceDouble      epoch,
                 ConstSpiceChar * eptype,
                 SpiceDouble    * delta );

SpiceDouble dpr_c ( void );
                                 
void              erract_c ( ConstSpiceChar    * operation,
                            SpiceInt            lenout,
                            SpiceChar         * action    );


void              errprt_c ( ConstSpiceChar    * operation,
                            SpiceInt            lenout,
                            SpiceChar         * list     );

output_maxsize_sizefirst(SpiceInt            lenout,
                         SpiceChar         * utcstr);
void et2utc_c (  SpiceDouble       et,
                    ConstSpiceChar  * format,
                    SpiceInt          prec,
                    SpiceInt          lenout,
                    SpiceChar       * utcstr   );
   
SpiceBoolean      failed_c ( void );

void              furnsh_c ( ConstSpiceChar    * file );


/* MOD: getmsg_c cannot be used as-is; it requires some SWIG type mapping to ensure the output string is marshalled properly.  Just like expln_ above */
output_maxsize_sizefirst(SpiceInt            lenout,
                         SpiceChar         * msg     );
 void              getmsg_c ( ConstSpiceChar    * option,
                              SpiceInt            lenout,
                              SpiceChar         * msg     ); 

/* The same trick used with expln_ must be used here to reorder kdata_c parameters so we can use them with the SWIG macros related to output buffers */
/*void kdata_c ( SpiceInt          which,
                  ConstSpiceChar  * kind,
                  SpiceInt          fillen,
                  SpiceInt          typlen,
                  SpiceInt          srclen,
                  SpiceChar       * file,
                  SpiceChar       * filtyp,
                  SpiceChar       * source,
                  SpiceInt        * handle,
                  SpiceBoolean    * found  );*/

%cstring_output_maxsize(SpiceChar *file, SpiceInt fillen);
%cstring_output_maxsize(SpiceChar *filtyp, SpiceInt typlen);
%cstring_output_maxsize(SpiceChar *source, SpiceInt srclen);
%apply SpiceInt *OUTPUT { SpiceInt* handle };
%apply SpiceBoolean *OUTPUT { SpiceBoolean* found };

%rename(kdata_c) kdata_c_wrapper;

%inline %{
  void kdata_c_wrapper(SpiceInt which, 
        ConstSpiceChar* kind, 
        SpiceChar* file, SpiceInt fillen,
        SpiceChar* filtyp, SpiceInt typlen,
        SpiceChar* source, SpiceInt srclen,
        SpiceInt* handle,
        SpiceBoolean* found) {
    kdata_c(which,
        kind,
        fillen,
        typlen,
        srclen,
        file,
        filtyp,
        source,
        handle,
        found);
  }
%}

%apply SpiceInt *OUTPUT { SpiceInt* count };
void ktotal_c ( ConstSpiceChar   * kind,
                   SpiceInt         * count );

SpiceDouble lspcn_c ( ConstSpiceChar   * body,
                         SpiceDouble        et,
                         ConstSpiceChar   * abcorr );

/* MOD: matrices are represented as one-dimensional arrays for ease of interoperability */
%rename(mxv_c) mxv_c_wrapper;
%inline %{
void mxv_c_wrapper (  ConstSpiceDouble    m1 [9],
              ConstSpiceDouble    vin [3],
              SpiceDouble         vout[3]    ) {
  mxv_c(m1, vin, vout);
}
%}


/* MOD: matrices are represented as one-dimensional arrays for ease of interoperability */
%rename(pxform_c) pxform_c_wrapper;
%inline %{
void pxform_c_wrapper ( ConstSpiceChar   * from,
                   ConstSpiceChar   * to,
                   SpiceDouble        et,
                   SpiceDouble        rotate[9]) {
  pxform_c(from,
    to,
    et,
    reinterpret_cast<SpiceDouble(*)[3]>(rotate));
}
%}

%apply SpiceDouble *OUTPUT { SpiceDouble* radius };
%apply SpiceDouble *OUTPUT { SpiceDouble* longitude };
%apply SpiceDouble *OUTPUT { SpiceDouble* latitude };
void reclat_c ( ConstSpiceDouble    rectan[3],
                   SpiceDouble       * radius,
                   SpiceDouble       * longitude,
                   SpiceDouble       * latitude  );

%apply SpiceDouble *OUTPUT { SpiceDouble* lon };
%apply SpiceDouble *OUTPUT { SpiceDouble* lat };
%apply SpiceDouble *OUTPUT { SpiceDouble* alt };
void recpgr_c ( ConstSpiceChar   * body,
                   SpiceDouble        rectan[3],
                   SpiceDouble        re,
                   SpiceDouble        f,
                   SpiceDouble      * lon,
                   SpiceDouble      * lat,
                   SpiceDouble      * alt       ); 

void              reset_c  ( void );   

void scard_c (  SpiceInt      card,   
                   SpiceCell   * cell  );

SpiceInt size_c ( SpiceCell  * cell );

void spkobj_c ( ConstSpiceChar  * spk,
                   SpiceCell       * ids );

%apply SpiceDouble *OUTPUT { SpiceDouble *lt };
void spkezr_c ( ConstSpiceChar     *targ,
                   SpiceDouble         et,
                   ConstSpiceChar     *ref,
                   ConstSpiceChar     *abcorr,
                   ConstSpiceChar     *obs,
                   SpiceDouble        starg[6],
                   SpiceDouble        *lt);

void ssize_c (  SpiceInt      size,   
                   SpiceCell   * cell  );

%apply SpiceDouble *OUTPUT { SpiceDouble* et };
void str2et_c ( ConstSpiceChar * str,
                   SpiceDouble    * et   );

%apply SpiceDouble *OUTPUT { SpiceDouble* trgepc };
void subpnt_c ( ConstSpiceChar       * method,
                   ConstSpiceChar       * target,
                   SpiceDouble            et,
                   ConstSpiceChar       * fixref,
                   ConstSpiceChar       * abcorr,
                   ConstSpiceChar       * obsrvr,
                   SpiceDouble            spoint [3],
                   SpiceDouble          * trgepc,
                   SpiceDouble            srfvec [3] );

SpiceDouble unitim_c ( SpiceDouble        epoch,
                          ConstSpiceChar   * insys,
                          ConstSpiceChar   * outsys );

void unload_c ( ConstSpiceChar  * file );

%apply SpiceDouble *OUTPUT { SpiceDouble* et };
void utc2et_c ( ConstSpiceChar  * utcstr,
                   SpiceDouble     * et      );

SpiceDouble vnorm_c ( ConstSpiceDouble v1[3] );

SpiceDouble vsep_c ( ConstSpiceDouble v1[3], ConstSpiceDouble v2[3] );
