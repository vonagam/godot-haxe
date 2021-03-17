#ifndef GH_OBJECT_H
#define GH_OBJECT_H

#include <hl.h>

#include "./gdnative.h"

#include "./gc_root.h"


// finalizer, reference to godot owner and haxe's gc root

typedef struct gh_object_data {

  void ( *finalize )( struct gh_object_data * ); // will be called by gc when nor it, nor godot use an object

  godot_object *owner;

  gh_gc_root root; // prevents gc from collecting an object if it is still used by godot

} gh_object_data;

// signature for haxe's object representation

typedef struct gh_object {

  hl_type *t;

  gh_object_data *data; // in separate structure for finalizer

} gh_object;


#define _GH_OBJECT_DATA _ABSTRACT( gh_object_data )

#define _GH_OBJECT _OBJ( _GH_OBJECT_DATA )

#define _GH_OBJECT_CONSTRUCTOR _FUN( _GH_OBJECT, _NO_ARG )


bool gh_object_free( gh_gc_root root );

gh_gc_root gh_object_new( godot_object *owner, vclosure *construct );

void gh_object_on_ref_increment( gh_gc_root root );

bool gh_object_on_ref_decrement( gh_gc_root root );

gh_object *gh_object_get( godot_object *owner );


#endif
