/****************************************************************************************************************
* SWIG interface definitions to support the generation of wrappers around a subset of the NAIF CSPICE API.      *
* Note this contains actual copies of function declarations from the CSPICE header files as of version N0064.   *
* To use this with a different version of the CSPICE toolkit, modifications may be necessary                    *
****************************************************************************************************************/
%module cspice_wrapper 
%include "typemaps.i"
%include "cstring.i"

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
* The following are from SpiceZfc.h.  This is just a subset of the methods declared there, based on need.       *
* If you need to add additional functions, copy their declarations from SpiceZfc.h and then think carefully     *
* about which SWIG incantations will be required to make the generated wrapper work correctly                   *
****************************************************************************************************************/

typedef int       ftnlen;

%cstring_output_maxsize(char *trace, ftnlen trace_len);
int qcktrc_(char *trace, ftnlen trace_len);

/* expln_ is a very awkward method, so we'll wrap it in one that's less awkward, and use a typemap 
that tells SWIG expl is an ouptut string allocated to hold up to expl_len characters */
int expln_(char *msg, char *expl, ftnlen msg_len, ftnlen expl_len);

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
                                 
void              erract_c ( ConstSpiceChar    * operation,
                            SpiceInt            lenout,
                            SpiceChar         * action    );


void              errprt_c ( ConstSpiceChar    * operation,
                            SpiceInt            lenout,
                            SpiceChar         * list     );
   
SpiceBoolean      failed_c ( void );

void              furnsh_c ( ConstSpiceChar    * file );


/* MOD: getmsg_c cannot be used as-is; it requires some SWIG type mapping to ensure the output string is marshalled properly.  Just like expln_ above */
output_maxsize_sizefirst(SpiceInt            lenout,
                         SpiceChar         * msg     );
 void              getmsg_c ( ConstSpiceChar    * option,
                              SpiceInt            lenout,
                              SpiceChar         * msg     ); 

void              reset_c  ( void );
