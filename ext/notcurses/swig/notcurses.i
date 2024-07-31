%module notcurses

%feature("autodoc", "2");
%feature("kwargs", "1");

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

%include <ruby/ruby.swg>
%include <ruby/argcargv.i>
%include <ruby/rubyautodoc.swg>
%include <ruby/file.i>
%include <ruby/progargcargv.i>
%include <ruby/rubycomplex.swg>
%include <ruby/rubyprimtypes.swg>
%include <ruby/rubystrings.swg>
%include <ruby/timeval.i>
%include <ruby/typemaps.i>

// Put Helper Functions in this block
%{
#include <fcntl.h>
#include <unistd.h>
#include <locale.h>

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

// Helper function to call Ruby procs
static VALUE call_ruby_proc(VALUE proc, int argc, VALUE* argv) {
  return rb_funcall2(proc, rb_intern("call"), argc, argv);
}
%}

// Package all function results in a hash
%typemap(out) SWIGTYPE*, SWIGTYPE& {
  VALUE hash = rb_hash_new();
  VALUE obj;

  if (strcmp("$1_type", "void") == 0) {
    obj = Qnil;
  } else {
    obj = SWIG_Ruby_NewPointerObj($1, $1_descriptor, $owner);
  }

  rb_hash_aset(hash, ID2SYM(rb_intern("return")), obj);
  $result = hash;
}

%typemap(argout) SWIGTYPE*, SWIGTYPE & {
  if ($result == Qnil) {
    $result = rb_hash_new();
  }
  if (!RB_TYPE_P($result, T_HASH)) {
    VALUE temp = rb_hash_new();
    rb_hash_aset(temp, ID2SYM(rb_intern("return")), $result);
    $result = temp;
  }

  swig_type_info *ty = SWIG_TypeQuery("$1_type");
  if (!ty) ty = $1_descriptor;

  VALUE obj = SWIG_NewPointerObj((void *)$1, ty, 0);
  rb_hash_aset($result, ID2SYM(rb_intern("$1_name")), obj);
}

%typemap(out) char*, const char* {
  VALUE hash = rb_hash_new();
  VALUE obj;

  if ($1 == NULL) {
    obj = Qnil;
  } else {
    // Convert C string to Ruby string
    obj = rb_str_new2($1);
  }

  rb_hash_aset(hash, ID2SYM(rb_intern("return")), obj);
  $result = hash;
}

%typemap(argout) char*, const char* {
  if ($result == Qnil) {
    $result = rb_hash_new();
  }
  if (!RB_TYPE_P($result, T_HASH)) {
    VALUE temp = rb_hash_new();
    rb_hash_aset(temp, ID2SYM(rb_intern("return")), $result);
    $result = temp;
  }

  VALUE obj = $1 ? rb_str_new2($1) : Qnil;
  rb_hash_aset($result, ID2SYM(rb_intern("$1_name")), obj);
}

%typemap(out) wchar_t* {
  VALUE hash = rb_hash_new();
  VALUE obj;

  if ($1 == NULL) {
    obj = Qnil;
  } else {
    // Convert wchar_t* to UTF-8 encoded Ruby string
    setlocale(LC_ALL, "");
    size_t len = wcslen($1);
    size_t utf8_len = wcstombs(NULL, $1, 0);  // Get required buffer size
    if (utf8_len != (size_t)-1) {
      char *utf8_str = (char*)malloc(utf8_len + 1);
      if (utf8_str) {
        wcstombs(utf8_str, $1, utf8_len + 1);
        obj = rb_str_new2(utf8_str);
        rb_enc_associate(obj, rb_utf8_encoding());
        free(utf8_str);
      } else {
        obj = Qnil; // Handle allocation failure
      }
    } else {
      obj = Qnil; // Handle conversion failure
    }
  }

  rb_hash_aset(hash, ID2SYM(rb_intern("return")), obj);
  $result = hash;
}

%typemap(argout) wchar_t* {
  if ($result == Qnil) {
    $result = rb_hash_new();
  }
  if (!RB_TYPE_P($result, T_HASH)) {
    VALUE temp = rb_hash_new();
    rb_hash_aset(temp, ID2SYM(rb_intern("return")), $result);
    $result = temp;
  }

  VALUE obj;
  if ($1 == NULL) {
    obj = Qnil;
  } else {
    // Convert wchar_t* to UTF-8 encoded Ruby string
    setlocale(LC_ALL, "");
    size_t utf8_len = wcstombs(NULL, $1, 0);  // Get required buffer size
    if (utf8_len != (size_t)-1) {
      char *utf8_str = (char*)malloc(utf8_len + 1);
      if (utf8_str) {
        wcstombs(utf8_str, $1, utf8_len + 1);
        obj = rb_str_new2(utf8_str);
        rb_enc_associate(obj, rb_utf8_encoding());
        free(utf8_str);
      } else {
        obj = Qnil; // Handle allocation failure
      }
    } else {
      obj = Qnil; // Handle conversion failure
    }
  }

  rb_hash_aset($result, ID2SYM(rb_intern("$1_name")), obj);
}

// Time is not on your side
%typemap(in) const struct timespec* {
  if ($input == Qnil) {
    $1 = NULL;
  } else if (rb_obj_is_kind_of($input, rb_cTime)) {
    static struct timespec ts;
    VALUE seconds = rb_funcall($input, rb_intern("to_f"), 0);
    ts.tv_sec = NUM2LONG(rb_funcall(seconds, rb_intern("floor"), 0));
    ts.tv_nsec = NUM2LONG(rb_funcall(rb_funcall(rb_funcall(seconds, rb_intern("-"), 1, seconds), rb_intern("*"), 1, INT2NUM(1000000000)), rb_intern("floor"), 0));
    $1 = &ts;
  } else {
    SWIG_exception(SWIG_TypeError, "Expected Time or nil");
  }
}

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
%typemap(in)
  short*,
  int*,
  long*,
  double*,
  long long*,
  int8_t*,
  int16_t*,
  int32_t*,
  int64_t*,
  unsigned short*,
  unsigned int*,
  unsigned long*,
  unsigned long long*,
  uint8_t*,
  uint16_t*,
  uint32_t*,
  uint64_t* {

  $1 = ($1_ltype) malloc(sizeof($*1_type));
  if ($1 == NULL) {
    SWIG_exception_fail(SWIG_MemoryError, "Failed to allocate memory");
  }
  switch(sizeof($*1_type)) {
    case 1:
    case 2:
    case 4:
      *$1 = ($*1_type) NUM2INT($input);
      break;
    case 8:
      if (strcmp("$*1_type", "double") == 0) {
        *$1 = ($*1_type) NUM2DBL($input);
      } else {
        *$1 = ($*1_type) NUM2LL($input);
      }
      break;
    default:
      SWIG_exception_fail(SWIG_TypeError, "Unsupported integer size");
  }
}

%typemap(argout)
  short*,
  int*,
  long*,
  double*,
  long long*,
  int8_t*,
  int16_t*,
  int32_t*,
  int64_t*,
  size_t*,
  unsigned short*,
  unsigned int*,
  unsigned long*,
  unsigned long long*,
  uint8_t*,
  uint16_t*,
  uint32_t*,
  uint64_t* {

  if ($1 != NULL) {
    if ($result == Qnil) {
      $result = rb_hash_new();
    } else if (!RB_TYPE_P($result, T_HASH)) {
      VALUE temp = rb_hash_new();
      rb_hash_aset(temp, ID2SYM(rb_intern("return")), $result);
      $result = temp;
    }
    VALUE converted_value;
    switch(sizeof($*1_type)) {
      case 1:
      case 2:
      case 4:
        converted_value = INT2NUM(*$1);
        break;
      case 8:
        if (strcmp("$*1_type", "double") == 0) {
          converted_value = DBL2NUM(*$1);
        } else {
          converted_value = LL2NUM(*$1);
        }
        break;
      default:
        rb_raise(rb_eTypeError, "Unsupported integer size");
    }
    rb_hash_aset($result, ID2SYM(rb_intern("$1_name")), converted_value);
    free($1);
  }
}

// Callbacks
%typemap(in) fadecb, ncstreamcb, tabletcb, tabcb, ncfdplane_done_cb {
  if (!NIL_P($input)) {
    $1 = ($1_ltype)rb_proc_new((VALUE (*)(ANYARGS))call_ruby_proc, $input);
  } else {
    $1 = NULL;
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

// NCCELL_INITIALIZER
void nccell_initializer(nccell* cell, uint32_t c, uint16_t s, uint64_t chan) {
  if (cell == NULL) return;
  cell->gcluster = htole(c);
  cell->gcluster_backstop = 0;
  cell->width = (uint8_t)((wcwidth(c) < 0 || !c) ? 1 : wcwidth(c));
  cell->stylemask = s;
  cell->channels = chan;
}

// NCCELL_CHAR_INITIALIZER
void nccell_char_initializer(nccell* cell, uint32_t c) {
  if (cell == NULL) return;
  cell->gcluster = htole(c);
  cell->gcluster_backstop = 0;
  cell->width = (uint8_t)((wcwidth(c) < 0 || !c) ? 1 : wcwidth(c));
  cell->stylemask = 0;
  cell->channels = 0;
}

// NCCELL_TRIVIAL_INITIALIZER
void nccell_trivial_initializer(nccell* cell) {
  if (cell == NULL) return;
  cell->gcluster = 0;
  cell->gcluster_backstop = 0;
  cell->width = 1;
  cell->stylemask = 0;
  cell->channels = 0;
}

// Prototypes for functions that replace va_list arg functions, actual
// definitions are in .c files in ../src
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

