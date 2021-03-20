#include "./macros.h"

#include "./object.h"

#include "./construct.h"


// free an object, called by godot's destroy or haxe's gc finalizer, returns whenever freeing was a complete

bool gh_object_free( gh_gc_root root ) {

  // order can be: haxe's gc then godot's destory or other way around

  if ( *root != NULL ) {

    hl_remove_root( root ); // remove root if it was in use, happens if godot's destroy is called first

    *root = NULL; // first step is complete, root with null is used to communicate that

    return false;

  } else {

    gdnative_core->godot_free( root ); // now second step is complete and root can be freed

    return true;

  }

}


// gc finalizer for an object

static void gh_object_data_free( gh_object_data *data ) {

  if ( gh_object_free( data->root ) ) return; // returns here if godot's destroy was called before finalizer

  gdnative_core->godot_object_destroy( data->owner );

}

// allocate object's data

static gh_object_data *gh_object_data_new( godot_object *owner, gh_gc_root root ) {

  gh_object_data *data = hl_gc_alloc_finalizer( sizeof( gh_object_data ) );

  data->finalize = &gh_object_data_free;

  data->owner = owner;

  data->root = root;

  return data;

}


// call init_ref on an object if it is a reference one, returns whenever an object is a reference

static bool gh_object_init_reference( godot_object *owner ) {

  STATIC_METHOD_BIND( reference_init_ref, Reference, init_ref );

  static void *reference_tag = NULL;

  if ( reference_tag == NULL ) {

    godot_string_name name;

    gdnative_core->godot_string_name_new_data( &name, "Reference" );

    reference_tag = gdnative_core_1_2->godot_get_class_tag( &name );

    gdnative_core->godot_string_name_destroy( &name );

  }

  if ( gdnative_core_1_2->godot_object_cast_to( owner, reference_tag ) == NULL ) return false;

  bool init_ref_success;

  gdnative_core->godot_method_bind_ptrcall( reference_init_ref, owner, NULL, &init_ref_success );

  // TODO: if ( ! init_ref_success ) log it?

  return true;

}


// create an object (or find pending) in haxe, returns it's gc root

gh_gc_root gh_object_new( godot_object *owner, vclosure *construct ) {

  // object can be create either on godot's side or haxe's

  gh_object *object = gh_construct_take_pending( owner ); // find if it is originated on haxe's

  bool is_constructed = object != NULL;

  if ( ! is_constructed ) object = hl_call0( gh_object *, construct ); // call constructor if it is from godot's

  gh_gc_root root = ( gh_gc_root ) gdnative_core->godot_alloc( sizeof( void * ) );

  *root = object;

  object->data = gh_object_data_new( owner, root );

  bool is_reference = gh_object_init_reference( owner );

  if ( ! ( is_constructed && is_reference ) ) hl_add_root( root ); // constructed references need to earn protection

  return root;

}


// react to increment of godot's ref count (only for Reference classes)

void gh_object_on_ref_increment( gh_gc_root root ) {

  hl_remove_root( root ); // just in case, to prevent double addition

  hl_add_root( root );

}

// react to decrement of godot's ref count (only for Reference classes)

bool gh_object_on_ref_decrement( gh_gc_root root ) {

  hl_remove_root( root );

  return false;

}


// get a haxe's object for a godot one

gh_object *gh_object_get( godot_object *owner ) {

  if ( owner == NULL ) return NULL;

  gh_object **root = gdnative_nativescript->godot_nativescript_get_userdata( owner );

  // TODO: if ( root != NULL ) check that it is haxe's nativescript and not from other binding language

  if ( root == NULL ) {

    root = gdnative_nativescript_1_1->godot_nativescript_get_instance_binding_data( gdnative_language, owner );

  }

  return *root;

}
