#ifndef GH_CONSTRUCT_H
#define GH_CONSTRUCT_H

#include "./object.h"


gh_object *gh_construct_take_pending( godot_object *owner );

void gh_construct_free();


#endif
