#ifndef GH_GDNATIVE_H
#define GH_GDNATIVE_H

#include <gdnative_api_struct.gen.h>


const godot_gdnative_core_api_struct *gdnative_core;

const godot_gdnative_core_api_struct *gdnative_core_1_0;

const godot_gdnative_core_1_1_api_struct *gdnative_core_1_1;

const godot_gdnative_core_1_2_api_struct *gdnative_core_1_2;

const godot_gdnative_ext_nativescript_api_struct *gdnative_nativescript;

const godot_gdnative_ext_nativescript_api_struct *gdnative_nativescript_1_0;

const godot_gdnative_ext_nativescript_1_1_api_struct *gdnative_nativescript_1_1;

void *gdnative_library; // used for construction

void *gdnative_handle; // used for registering things

int gdnative_language; // used for bindings related things

bool gdnative_in_editor; // not used, just in case

bool gdnative_in_init; // used to safe guard against creating objects during registration


#endif
