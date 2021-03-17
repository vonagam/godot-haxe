#include <hl.h>

#include "./gc_root.h"

#include "./gdnative.h"


// allocate root for haxe's gc

gh_gc_root gh_gc_root_alloc( void *value ) {

  gh_gc_root root = gdnative_core->godot_alloc( sizeof( void * ) ); // use godot_alloc to help with tracking of memory

  *root = value;

  hl_add_root( root );

  return root;

}

// free root

void gh_gc_root_free( gh_gc_root root ) {

  hl_remove_root( root );

  *root = NULL;

  gdnative_core->godot_free( root );

}
