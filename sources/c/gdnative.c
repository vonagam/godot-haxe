#include "./binding.h"

#include "./construct.h"

#include "./defaults.h"

#include "./embed_jit.h"

#include "./gdnative.h"


const godot_gdnative_core_api_struct *gdnative_core = NULL;

const godot_gdnative_core_api_struct *gdnative_core_1_0 = NULL;

const godot_gdnative_core_1_1_api_struct *gdnative_core_1_1 = NULL;

const godot_gdnative_core_1_2_api_struct *gdnative_core_1_2 = NULL;

const godot_gdnative_ext_nativescript_api_struct *gdnative_nativescript = NULL;

const godot_gdnative_ext_nativescript_api_struct *gdnative_nativescript_1_0 = NULL;

const godot_gdnative_ext_nativescript_1_1_api_struct *gdnative_nativescript_1_1 = NULL;

void *gdnative_library = NULL;

void *gdnative_handle = NULL;

int gdnative_language = -1;

bool gdnative_in_editor = false;

bool gdnative_in_init = true;


// prepare

void GDN_EXPORT godot_gdnative_init( godot_gdnative_init_options *options ) {

  gdnative_core = options->api_struct;

  gdnative_core_1_0 = gdnative_core;

  gdnative_core_1_1 = ( godot_gdnative_core_1_1_api_struct * ) gdnative_core_1_0->next;

  gdnative_core_1_2 = ( godot_gdnative_core_1_2_api_struct * ) gdnative_core_1_1->next;

  for ( int i = 0; i < gdnative_core->num_extensions; i++ ) {

    const godot_gdnative_api_struct *extension = gdnative_core->extensions[ i ];

    if ( extension->type != GDNATIVE_EXT_NATIVESCRIPT ) continue;

    gdnative_nativescript = ( godot_gdnative_ext_nativescript_api_struct * ) extension;

    gdnative_nativescript_1_0 = gdnative_nativescript;

    gdnative_nativescript_1_1 = ( godot_gdnative_ext_nativescript_1_1_api_struct * ) extension->next;

  }

  gdnative_library = options->gd_native_library;

  gdnative_in_editor = options->in_editor;

  gdnative_in_init = true;

  gh_embed_jit_init();

  gh_defaults_init();

}

// start

void GDN_EXPORT godot_nativescript_init( void *handle ) {

  gdnative_handle = handle;

  gdnative_language = gdnative_nativescript_1_1->godot_nativescript_register_instance_binding_data_functions( gh_binding_get_functions() );

  gh_embed_jit_main();

  gdnative_in_init = false;

}

// free

void GDN_EXPORT godot_gdnative_terminate( godot_gdnative_terminate_options *options ) {

  gh_binding_free();

  gh_construct_free();

  gh_defaults_free();

  gh_embed_jit_free();

  gdnative_nativescript_1_1->godot_nativescript_unregister_instance_binding_data_functions( gdnative_language );

  gdnative_core = NULL;

  gdnative_core_1_0 = NULL;

  gdnative_core_1_1 = NULL;

  gdnative_core_1_2 = NULL;

  gdnative_nativescript = NULL;

  gdnative_nativescript_1_0 = NULL;

  gdnative_nativescript_1_1 = NULL;

  gdnative_library = NULL;

  gdnative_handle = NULL;

  gdnative_language = -1;

  gdnative_in_editor = false;

  gdnative_in_init = true;

}
