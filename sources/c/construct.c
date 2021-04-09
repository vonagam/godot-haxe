#include "./macros.h"

#include "./construct.h"


static godot_object *pending_owner = NULL; // current godot object waiting for pairing

static gh_object *pending_object = NULL; // current haxe object waiting for pairing

// remember current constructing pair

static void gh_construct_set_pending( godot_object *owner, gh_object *object ) {

  pending_owner = owner;

  pending_object = object;

}

// retrieve and forget current constructing pair

gh_object *gh_construct_take_pending( godot_object *owner ) {

  if ( owner != pending_owner ) return NULL;

  gh_object *object = pending_object;

  gh_construct_free();

  return object;

}

// reset pointers

void gh_construct_free() {

  pending_owner = NULL;

  pending_object = NULL;

}


// construct godot object and set it up for pairing with haxe object

static godot_object *gh_construct_owner( gh_object *object, const char *owner_class_name ) {

  godot_class_constructor owner_constructor = gdnative_core->godot_get_class_constructor( owner_class_name );

  godot_object *owner = owner_constructor();

  gh_construct_set_pending( owner, object );

  return owner;

}


// construct instance of godot object class

HL_PRIM void HL_NAME( construct_binding )( gh_object *object, vstring *owner_class_name ) {

  godot_object *owner = gh_construct_owner( object, hl_chars( owner_class_name ) );

  gdnative_nativescript_1_1->godot_nativescript_get_instance_binding_data( gdnative_language, owner );

}

DEFINE_PRIM( _VOID, construct_binding, _GH_OBJECT _STRING );


// construct instance of library registered class

HL_PRIM void HL_NAME( construct_script )( gh_object *object, vstring *owner_class_name, vstring *script_class_name ) {

  STATIC_CONSTRUCTOR_BIND( script_new, NativeScript );

  STATIC_METHOD_BIND( script_set_library, NativeScript, set_library );

  STATIC_METHOD_BIND( script_set_class_name, NativeScript, set_class_name );

  STATIC_METHOD_BIND( owner_set_script, Object, set_script );


  godot_object *script = script_new();

  gdnative_core->godot_method_bind_ptrcall( script_set_library, script, ( const void *[] ) { gdnative_library }, NULL );

  {

    godot_string arg0;

    gdnative_core->godot_string_new( &arg0 );

    gdnative_core->godot_string_parse_utf8( &arg0, hl_chars( script_class_name ) );

    gdnative_core->godot_method_bind_ptrcall( script_set_class_name, script, ( const void *[] ) { &arg0 }, NULL );

    gdnative_core->godot_string_destroy( &arg0 );

  }


  godot_object *owner = gh_construct_owner( object, hl_chars( owner_class_name ) );

  gdnative_core->godot_method_bind_ptrcall( owner_set_script, owner, ( const void *[] ) { script }, NULL );

}

DEFINE_PRIM( _VOID, construct_script, _GH_OBJECT _STRING _STRING );
