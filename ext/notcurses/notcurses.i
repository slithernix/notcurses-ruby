%module notcurses

// This should change things like notcurses_options to NotcursesOptions,
// instead of the default Notcurses_options
%rename("%(camelcase)s", %$isclass) "";

%constant unsigned long NANOSECS_IN_SEC = 1000000000ul;
%constant const char* PRIu64 = PRIu64;
%constant const char* PRId64 = PRId64;

// These empty defines are needed because SWIG seems to think compound macros
// are syntax errors.
%define __attribute__(x)
%enddef
%define __attribute(x)
%enddef
%define __declspec(x)
%enddef
%define __nonnull(x)
%enddef

%include <ruby/rubywstrings.swg>
%include <./modified_ruby_std_wstring.i>

%include <carrays.i>
%include <cdata.i>
%include <cmalloc.i>
%include <constraints.i>
%include <cpointer.i>
%include <cstring.i>
%include <inttypes.i>
%include <math.i>
%include <stdint.i>
%include <wchar.i>

%include <typemaps/attribute.swg>
%include <typemaps/carrays.swg>
%include <typemaps/cdata.swg>
%include <typemaps/cmalloc.swg>
%include <typemaps/cpointer.swg>
%include <typemaps/cstrings.swg>
%include <typemaps/cstring.swg>
%include <typemaps/cwstring.swg>
%include <typemaps/enumint.swg>
%include <typemaps/exception.swg>
%include <typemaps/factory.swg>
%include <typemaps/fragments.swg>
%include <typemaps/implicit.swg>
%include <typemaps/inoutlist.swg>
%include <typemaps/misctypes.swg>
%include <typemaps/primtypes.swg>
%include <typemaps/ptrtypes.swg>
%include <typemaps/strings.swg>
%include <typemaps/string.swg>
%include <typemaps/swigmacros.swg>
%include <typemaps/swigobject.swg>
%include <typemaps/swigtypemaps.swg>
%include <typemaps/swigtype.swg>
%include <typemaps/typemaps.swg>
%include <typemaps/valtypes.swg>
%include <typemaps/void.swg>
%include <typemaps/wstring.swg>

%include <ruby/argcargv.i>
%include <ruby/rubyautodoc.swg>
%include <ruby/file.i>
%include <ruby/progargcargv.i>
%include <ruby/rubycomplex.swg>
%include <ruby/rubykw.swg>
%include <ruby/rubymacros.swg>
%include <ruby/rubyprimtypes.swg>
%include <ruby/rubystrings.swg>
%include <ruby/timeval.i>
%include <ruby/typemaps.i>

%{
#include <fcntl.h>
#include <unistd.h>

// Helper function to determine file mode
static const char* get_file_mode(int fd) {
  int flags = fcntl(fd, F_GETFL);
  if (flags == -1) return "r"; // Default to read mode on error

  int access_mode = flags & O_ACCMODE;
  int append_flag = flags & O_APPEND;

  if (access_mode == O_RDONLY) return "r";
  if (access_mode == O_WRONLY) return append_flag ? "a" : "w";
  if (access_mode == O_RDWR) return append_flag ? "a+" : "r+";

  return "r";
}
%}

// IO
%typemap(in) FILE* {
  if ($input == Qnil) {
    $1 = NULL;
  } else if (rb_respond_to($input, rb_intern("fileno"))) {
    int fd = NUM2INT(rb_funcall($input, rb_intern("fileno"), 0));
    const char* mode = get_file_mode(fd);
    $1 = fdopen(dup(fd), mode);
    if (!$1) {
      rb_raise(rb_eIOError, "Unable to get FILE* from Ruby IO object");
    }
  } else {
    SWIG_exception(SWIG_TypeError, "Expected IO object or nil");
  }
}

%typemap(out) FILE* {
  if ($1 == NULL) {
    $result = Qnil;
  } else {
    int fd = fileno($1);
    if (fd == -1) {
      rb_raise(rb_eIOError, "Invalid file descriptor");
    }
    VALUE io_class = rb_const_get(rb_cObject, rb_intern("IO"));
    $result = rb_funcall(io_class, rb_intern("for_fd"), 1, INT2NUM(fd));
    rb_funcall($result, rb_intern("binmode"), 0);
  }
}


%typemap(argout) FILE** {
  if (*$1 != NULL) {
    int fd = fileno(*$1);
    if (fd == -1) {
      rb_raise(rb_eIOError, "Invalid file descriptor");
    }
    VALUE io_class = rb_const_get(rb_cObject, rb_intern("IO"));
    VALUE io_obj = rb_funcall(io_class, rb_intern("for_fd"), 1, INT2NUM(fd));

    // Set the mode of the IO object
    const char* mode = "r";  // Default to read mode
    if ((*$1)->_flags & _IO_NO_READS) {
      if ((*$1)->_flags & _IO_APPEND) {
        mode = "a";
      } else {
        mode = "w";
      }
    }
    if (!((*$1)->_flags & _IO_NO_WRITES)) {
      mode = (strcmp(mode, "r") == 0) ? "r+" : "w+";
    }

    // Set the mode
    rb_funcall(io_obj, rb_intern("set_encoding"), 1, rb_str_new2(mode));

    // Preserve the original encoding if possible
    VALUE enc = rb_funcall(io_obj, rb_intern("internal_encoding"), 0);
    if (enc == Qnil) {
      enc = rb_funcall(io_obj, rb_intern("external_encoding"), 0);
    }
    if (enc != Qnil) {
      rb_funcall(io_obj, rb_intern("set_encoding"), 1, enc);
    } else {
      // Fallback to binary mode if no encoding is detected
      rb_funcall(io_obj, rb_intern("binmode"), 0);
    }

    rb_io_taint_check(io_obj);

    $result = io_obj;
  } else {
    $result = Qnil;
  }
}

%typemap(in) FILE** (FILE* tempfile = NULL) {
  if ($input == Qnil) {
    $1 = &tempfile;
  } else if (rb_obj_is_kind_of($input, rb_cIO)) {
    VALUE fileno = rb_funcall($input, rb_intern("fileno"), 0);
    int fd = NUM2INT(fileno);
    const char* mode = StringValueCStr(rb_funcall($input, rb_intern("mode"), 0));
    tempfile = fdopen(dup(fd), mode);
    if (!tempfile) {
      rb_raise(rb_eIOError, "Could not create FILE* from Ruby IO object");
    }
    $1 = &tempfile;
  } else {
    SWIG_exception(SWIG_TypeError, "Expected IO object or nil");
  }
}

%typemap(freearg) FILE** {
  if (tempfile$argnum != NULL) {
    fclose(tempfile$argnum);
  }
}

// Integer Pointers
%typemap(in) int* (int temp) {
  temp = NUM2INT($input);
  $1 = &temp;
}

%typemap(in) unsigned int* (unsigned int temp) {
  temp = NUM2UINT($input);
  $1 = &temp;
}

%typemap(in) long* (long temp) {
  temp = NUM2LONG($input);
  $1 = &temp;
}

%typemap(in) unsigned long* (unsigned long temp) {
  temp = NUM2ULONG($input);
  $1 = &temp;
}

%typemap(in) short* (short temp) {
  temp = NUM2SHORT($input);
  $1 = &temp;
}

%typemap(in) unsigned short* (unsigned short temp) {
  temp = NUM2USHORT($input);
  $1 = &temp;
}

%typemap(in) int64_t* (int64_t temp) {
  temp = NUM2LL($input);
  $1 = &temp;
}

%typemap(in) uint64_t* (uint64_t temp) {
  temp = NUM2ULL($input);
  $1 = &temp;
}

%typemap(argout) int*, unsigned int*, long*, unsigned long*, short*, unsigned short*, int64_t*, uint64_t* {
  if ($1 != NULL) {
    $result = INT2NUM(*$1);
  }
}


// Stuff in the inline block is both written to the generated C code AND has
// swig wrappers generated for the functions.
%inline %{
#include <notcurses/ncport.h>
#include <notcurses/version.h>
#include <notcurses/nckeys.h>
#include <notcurses/ncseqs.h>
#include <notcurses/notcurses.h>
#include <notcurses/direct.h>


// Put fake function macros here.
// NCCHANNEL_INITIALIZER
uint32_t ncchannel_initializer(
  uint32_t r,
  uint32_t g,
  uint32_t b
) {
  return ((r << 16u) + (g << 8u) + b + NC_BGDEFAULT_MASK);
}

// NCCHANNELS_INITIALIZER
uint64_t ncchannels_initializer(
  uint32_t fr,
  uint32_t fg,
  uint32_t fb,
  uint32_t br,
  uint32_t bg,
  uint32_t bb
) {

  uint64_t tmp_fg_chan = ((uint64_t)ncchannel_initializer(fr, fg, fb) << 32ull);
  uint64_t tmp_bg_chan = ncchannel_initializer(br, bg, bb);

  return tmp_fg_chan + tmp_bg_chan;
}


// NCMETRICFWIDTH
int ncmetricfwidth(const char* x, int cols) {
  return (int)(strlen(x) - ncstrwidth(x, NULL, NULL) + cols);
}

// NCPREFIXFMT (note this macro expands to this as well as ", x")
int ncprefixfmt(const char* x) {
  return (int)ncmetricfwidth(x, NCPREFIXCOLUMNS);
}

// NCIPREFIXFMT (note this macro expands to this as well as ", x")
int nciprefixfmt(const char* x) {
  return (int)ncmetricfwidth(x, NCIPREFIXCOLUMNS);
}

// NCBPREFIXFMT (note this macro expands to this as well as ", x")
int ncbprefixfmt(const char* x) {
  return (int)ncmetricfwidth(x, NCBPREFIXCOLUMNS);
}

// Prototypes for functions that replace va_list arg functions, actual
// definitions are in .c files in this current directory.
int ruby_ncplane_vprintf_yx(struct ncplane* n, int y, int x, const char* format, VALUE rb_args);
int ruby_ncplane_vprintf_aligned(struct ncplane* n, int y, ncalign_e align, const char* format, VALUE rb_args);
int ruby_ncplane_vprintf_stained(struct ncplane* n, const char* format, VALUE rb_args);

int ruby_ncplane_vprintf(struct ncplane* n, const char* format, VALUE rb_args) {
  return ruby_ncplane_vprintf_yx(n, -1, -1, format, rb_args);
}
%}

// Ignore problematic functions (va_list stuff)
%ignore ncplane_vprintf_yx;
%ignore ncplane_vprintf;
%ignore ncplane_vprintf_aligned;
%ignore ncplane_vprintf_stained;

%include <notcurses/ncport.h>
%include <notcurses/version.h>
%include <notcurses/nckeys.h>
%include <notcurses/ncseqs.h>
%include <notcurses/notcurses.h>
%include <notcurses/direct.h>

%rename("ncplane_vprintf_yx") ruby_ncplane_vprintf_yx;
%rename("ncplane_vprintf_aligned") ruby_ncplane_vprintf_aligned;
%rename("ncplane_vprintf_stained") ruby_ncplane_vprintf_stained;
%rename("ncplane_vprintf") ruby_ncplane_vprintf;

// Still a little unsure why I need the prototypes in two places, oh well
int ruby_ncplane_vprintf_yx(struct ncplane* n, int y, int x, const char* format, VALUE rb_args);
int ruby_ncplane_vprintf_aligned(struct ncplane* n, int y, ncalign_e align, const char* format, VALUE rb_args);
int ruby_ncplane_vprintf_stained(struct ncplane* n, const char* format, VALUE rb_args);
int ruby_ncplane_vprintf(struct ncplane* n, const char* format, VALUE rb_args);

