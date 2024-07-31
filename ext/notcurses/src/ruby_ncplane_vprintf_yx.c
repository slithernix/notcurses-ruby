#include <notcurses/notcurses.h>
#include <ruby.h>
#include <stdio.h>

int ruby_ncplane_vprintf_yx(struct ncplane* n, int y, int x, const char* format, VALUE rb_args) {
  int argc = RARRAY_LEN(rb_args);
  VALUE* argv = RARRAY_PTR(rb_args);

  // Create a buffer to hold our formatted string
  char* buffer = NULL;
  size_t buffer_size = 0;
  FILE* memstream = open_memstream(&buffer, &buffer_size);
  if (!memstream) {
    rb_raise(rb_eRuntimeError, "Failed to create memory stream");
    return -1;
  }

  // Use vfprintf to format our string
  for (int i = 0; i < argc; i++) {
    VALUE arg = argv[i];
    switch (TYPE(arg)) {
      case T_FIXNUM:
        fprintf(memstream, format, NUM2INT(arg));
        break;
      case T_FLOAT:
        fprintf(memstream, format, NUM2DBL(arg));
        break;
      case T_STRING:
        fprintf(memstream, format, StringValueCStr(arg));
        break;
      default:
        fclose(memstream);
        free(buffer);
        rb_raise(rb_eTypeError, "Unsupported argument type");
        return -1;
    }
  }

  fclose(memstream);

  int result = ncplane_putstr_yx(n, y, x, buffer);

  free(buffer);
  return result;
}
