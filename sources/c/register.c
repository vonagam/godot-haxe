#include "./macros.h"

#include "./core_wrapper.h"

#include "./gc_root.h"

#include "./gdnative.h"

#include "./object.h"

#include "./gen/core.h"


// Common

// method/signal argument data

typedef struct gh_register_argument_data {

  hl_type *t;

  vstring *name;

  int type;

} gh_register_argument_data;

// just an adapter to match godot signature (void * vs void **)

static void gh_register_gc_root_free( void *root ) {

  gh_gc_root_free( root );

}

// make a godot string

static godot_string gh_register_make_godot_string( vstring *value ) {

  godot_string result;

  gdnative_core->godot_string_new( &result );

  if ( value != NULL ) {

    gdnative_core->godot_string_parse_utf8( &result, hl_chars( value ) );

  }

  return result;

}

// make a godot variant

static godot_variant gh_register_make_godot_variant( gh_godot_variant *wrapper ) {

  godot_variant result;

  wrapper != NULL && wrapper->value != NULL

    ? gdnative_core->godot_variant_new_copy( &result, wrapper->value )

    : gdnative_core->godot_variant_new_nil( &result );

  return result;

}


// Class

// create an instance of a registered class

static void *gh_register_class_create( godot_object *owner, void *construct_root ) {

  return gh_object_new( owner, *( vclosure ** ) construct_root );

}

// destroy an instance of a registered class

static void gh_register_class_destroy( godot_object *owner, void *method_data, void *root ) {

  gh_object_free( root );

}

// _refcount_incremented method for a registered class

static godot_variant gh_register_class_on_ref_increment( godot_object *owner, void *method_data, void *root, int nargs, godot_variant **args ) {

  gh_object_on_ref_increment( root );

  godot_variant variant;

  gdnative_core->godot_variant_new_nil( &variant );

  return variant;

}

// _refcount_decremented method for a registered class

static godot_variant gh_register_class_on_ref_decrement( godot_object *owner, void *method_data, void *root, int nargs, godot_variant **args ) {

  bool result = gh_object_on_ref_decrement( root ); // bool saying whenever the object can be collected/destroyed by godot, always false

  godot_variant variant;

  gdnative_core->godot_variant_new_bool( &variant, result );

  return variant;

}

// register a class, construct: () -> gh_object

HL_PRIM void HL_NAME( register_class )(

  vstring *class_name,

  vstring *parent_name,

  vclosure *construct,

  bool is_tool,

  vstring *documentation

) {

  ( is_tool ? gdnative_nativescript->godot_nativescript_register_tool_class : gdnative_nativescript->godot_nativescript_register_class )(

    gdnative_handle,

    hl_chars( class_name ),

    hl_chars( parent_name ),

    ( godot_instance_create_func ) { &gh_register_class_create, gh_gc_root_alloc( construct ), &gh_register_gc_root_free },

    ( godot_instance_destroy_func ) { &gh_register_class_destroy, NULL, NULL }

  );

  if ( documentation != NULL ) {

    gdnative_nativescript_1_1->godot_nativescript_set_class_documentation(

      gdnative_handle,

      hl_chars( class_name ),

      gh_register_make_godot_string( documentation )

    );

  }

  // TODO: proper to check if owner class is a Reference before adding refcount callbacks

  gdnative_nativescript->godot_nativescript_register_method(

    gdnative_handle,

    hl_chars( class_name ),

    "_refcount_incremented",

    ( godot_method_attributes ) { GODOT_METHOD_RPC_MODE_DISABLED },

    ( godot_instance_method ) { &gh_register_class_on_ref_increment, NULL, NULL }

  );

  gdnative_nativescript->godot_nativescript_register_method(

    gdnative_handle,

    hl_chars( class_name ),

    "_refcount_decremented",

    ( godot_method_attributes ) { GODOT_METHOD_RPC_MODE_DISABLED },

    ( godot_instance_method ) { &gh_register_class_on_ref_decrement, NULL, NULL }

  );

}

DEFINE_PRIM( _VOID, register_class, _STRING _STRING _GH_OBJECT_CONSTRUCTOR _BOOL _STRING );


// Method

// call a registered method on an instance

static godot_variant gh_register_method_call( godot_object *owner, void *method_root, void *root, int nargs, godot_variant **args ) {

  vclosure *method = *( vclosure ** ) method_root;

  vdynamic *object = *( vdynamic ** ) root;

  varray *wrapped = hl_alloc_array( &hlt_abstract, nargs );

  for ( int i = 0; i < nargs; i++ ) {

    godot_variant *variant = args[ i ]; // TODO: should passed in variant args be destroyed???

    if ( variant == NULL ) continue;

    gh_godot_variant *wrapper = gh_core_wrapper_alloc( sizeof( godot_variant ), ( void * ) gdnative_core->godot_variant_destroy );

    gdnative_core->godot_variant_new_copy( wrapper->value, variant );

    hl_aptr( wrapped, gh_godot_variant* )[ i ] = wrapper;

  }

  gh_godot_variant *output = hl_call2( gh_godot_variant *, method, vdynamic *, object, varray *, wrapped );

  godot_variant result = gh_register_make_godot_variant( output );

  return result;

}

// register a method, method: ( instance, variants[] ) -> any

HL_PRIM void HL_NAME( register_method )(

  vstring *class_name,

  vstring *method_name,

  vclosure *method,

  godot_method_rpc_mode rpc_mode,

  vstring *documentation

) {

  gdnative_nativescript->godot_nativescript_register_method(

    gdnative_handle,

    hl_chars( class_name ),

    hl_chars( method_name ),

    ( godot_method_attributes ) { rpc_mode },

    ( godot_instance_method ) { &gh_register_method_call, gh_gc_root_alloc( method ), &gh_register_gc_root_free }

  );

  // TODO: godot_nativescript_set_method_argument_information

  if ( documentation != NULL ) {

    gdnative_nativescript_1_1->godot_nativescript_set_method_documentation(

      gdnative_handle,

      hl_chars( class_name ),

      hl_chars( method_name ),

      gh_register_make_godot_string( documentation )

    );

  }

}

DEFINE_PRIM( _VOID, register_method, _STRING _STRING _FUN( _GH_VARIANT, _DYN _ARR ) _I32 _STRING );


// Property

// get a register property

static godot_variant gh_register_property_get( godot_object *owner, void *getter_root, void *root ) {

  vclosure *getter = *( vclosure ** ) getter_root;

  vdynamic *object = *( vdynamic ** ) root;

  gh_godot_variant *output = hl_call1( gh_godot_variant *, getter, vdynamic *, object );

  godot_variant result = gh_register_make_godot_variant( output );

  return result;

}

// set a register property

static void gh_register_property_set( godot_object *owner, void *setter_root, void *root, godot_variant *value ) {

  vclosure *setter = *( vclosure ** ) setter_root;

  vdynamic *object = *( vdynamic ** ) root;

  gh_godot_variant *wrapper = gh_core_wrapper_alloc( sizeof( godot_variant ), ( void * ) gdnative_core->godot_variant_destroy );

  gdnative_core->godot_variant_new_copy( wrapper->value, value ); // TODO: who owns passed in variant value???

  hl_call2( void, setter, vdynamic *, object, gh_godot_variant *, wrapper );

}

// register a property, getter: ( instance ) -> value, setter: ( instance, value ) -> void

HL_PRIM void HL_NAME( register_property )(

  vstring *class_name,

  vstring *property_path,

  vclosure *getter,

  vclosure *setter,

  godot_variant_type type,

  gh_godot_variant *default_value,

  godot_property_usage_flags usage,

  godot_property_hint hint,

  vstring *hint_string,

  godot_method_rpc_mode rpc_mode,

  vstring *documentation

) {

  gdnative_nativescript->godot_nativescript_register_property(

    gdnative_handle,

    hl_chars( class_name ),

    hl_chars( property_path ),

    &( godot_property_attributes ) { rpc_mode, type, hint, gh_register_make_godot_string( hint_string ), usage, gh_register_make_godot_variant( default_value ) },

    setter ? ( godot_property_set_func ) { &gh_register_property_set, gh_gc_root_alloc( setter ), &gh_register_gc_root_free } : ( godot_property_set_func ) { NULL, NULL, NULL },

    getter ? ( godot_property_get_func ) { &gh_register_property_get, gh_gc_root_alloc( getter ), &gh_register_gc_root_free } : ( godot_property_get_func ) { NULL, NULL, NULL }

  );

  gdnative_nativescript_1_1->godot_nativescript_set_type_tag( gdnative_handle, hl_chars( class_name ), gdnative_handle );

  if ( documentation != NULL ) {

    gdnative_nativescript_1_1->godot_nativescript_set_property_documentation(

      gdnative_handle,

      hl_chars( class_name ),

      hl_chars( property_path ),

      gh_register_make_godot_string( documentation )

    );

  }

}

DEFINE_PRIM( _VOID, register_property, _STRING _STRING _FUN( _GH_VARIANT, _DYN ) _FUN( _VOID, _DYN _GH_VARIANT ) _I32 _GH_VARIANT _I32 _I32 _STRING _I32 _STRING );


// Signal

// register a signal

HL_PRIM void HL_NAME( register_signal )(

  vstring *class_name,

  vstring *signal_name,

  varray *arguments,

  vstring *documentation

) {

  godot_signal_argument *args = gdnative_core->godot_alloc( sizeof( godot_signal_argument ) * arguments->size );

  for ( int i = 0; i < arguments->size; i++ ) {

    gh_register_argument_data *argument = hl_aptr( arguments, gh_register_argument_data * )[ i ];

    args[ i ] = ( godot_signal_argument ) {

      gh_register_make_godot_string( argument->name ),

      argument->type,

      GODOT_PROPERTY_HINT_NONE,

      gh_register_make_godot_string( NULL ),

      GODOT_PROPERTY_USAGE_DEFAULT, // TODO: meaningless param?

      gh_register_make_godot_variant( NULL )

    };

  }

  godot_signal signal = { gh_register_make_godot_string( signal_name ), arguments->size, args, 0, NULL };

  gdnative_nativescript->godot_nativescript_register_signal( gdnative_handle, hl_chars( class_name ), &signal );

  gdnative_core->godot_free( args );

  if ( documentation != NULL ) {

    gdnative_nativescript_1_1->godot_nativescript_set_signal_documentation(

      gdnative_handle,

      hl_chars( class_name ),

      hl_chars( signal_name ),

      gh_register_make_godot_string( documentation )

    );

  }

}

DEFINE_PRIM( _VOID, register_signal, _STRING _STRING _ARR _STRING );
