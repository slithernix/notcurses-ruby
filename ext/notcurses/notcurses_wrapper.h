#ifndef NOTCURSES_WRAPPER_H
#define NOTCURSES_WRAPPER_H

#define ALLOC
#define API
#define __attribute__(x)
#define __attribute(x)
#define __declspec(x)
#define __nonnull(x)

#include <notcurses/notcurses.h>

#undef ALLOC
#undef API
#undef __attribute__
#undef __attribute
#undef __declspec
#undef __nonnull

#endif // NOTCURSES_WRAPPER_H
