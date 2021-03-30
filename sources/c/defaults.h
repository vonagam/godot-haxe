#ifndef GH_DEFAULTS_H
#define GH_DEFAULTS_H

#include <hl.h>


varray *gh_defaults; // array for default values


void gh_defaults_init(); // implemented in gen/object.c

void gh_defaults_free();


#endif
