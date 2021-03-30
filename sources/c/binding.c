#include "./macros.h"

#include "./binding.h"

#include "./object.h"

#include "./construct.h"


// allocate haxe object for binding

static void *gh_binding_instance_alloc( void *data, const void *global_type_tag, godot_object *owner ) {

  return gh_object_new( owner, ( vclosure * ) global_type_tag );

}

// free haxe object

static void gh_binding_instance_free( void *data, void *root ) {

  gh_object_free( root );

}

// ref increment callback

static void gh_binding_instance_on_ref_increment( void *root, godot_object *owner ) {

  gh_object_on_ref_increment( root );

}

// ref decrement callback

static bool gh_binding_instance_on_ref_decrement( void *root, godot_object *owner ) {

  return gh_object_on_ref_decrement( root );

}

// get implementation for godot bindings

godot_instance_binding_functions gh_binding_get_functions() {

  return ( godot_instance_binding_functions ) {

    &gh_binding_instance_alloc,

    &gh_binding_instance_free,

    &gh_binding_instance_on_ref_increment,

    &gh_binding_instance_on_ref_decrement,

    NULL, NULL,

  };

}


typedef struct gh_binding_constructor {

  hl_type *t;

  vstring *name; // name of godot object class

  vclosure *construct; // constructor: () -> haxe object, a global tag value, passed to gh_binding_instance_alloc

} gh_binding_constructor;

static varray *binding_constructors = NULL; // used as gc root

// free global tags array

void gh_binding_free() {

  if ( binding_constructors == NULL ) return;

  hl_remove_root( &binding_constructors );

  binding_constructors = NULL;

}

// set global tags

HL_PRIM void HL_NAME( binding_set_constructors )( varray *constructors ) {

  if ( binding_constructors != NULL ) hl_fatal( "Cannot set binding contructors twice." );

  for ( int i = 0; i < constructors->size; i++ ) {

    gh_binding_constructor *constructor = hl_aptr( constructors, gh_binding_constructor * )[ i ];

    gdnative_nativescript_1_1->godot_nativescript_set_global_type_tag( gdnative_language, hl_chars( constructor->name ), constructor->construct );

  }

  binding_constructors = constructors;

  hl_add_root( &binding_constructors );

}

DEFINE_PRIM( _VOID, binding_set_constructors, _ARR );
