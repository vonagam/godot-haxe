#include "./macros.h"

#include <hl.h>

#include "./gdnative.h"

#include "./gen/core.h"


hl_type *string_type = NULL;

HL_PRIM void HL_NAME( extra_set_string_type )( hl_type *type ) {

  string_type = type;

}

DEFINE_PRIM( _VOID, extra_set_string_type, _TYPE );


HL_PRIM vstring *HL_NAME( String_toHaxeString )( gh_godot_string *godot_string ) {

  godot_char_string char_string = gdnative_core->godot_string_utf8( godot_string->value );

  vstring *haxe_string = hl_gc_alloc( string_type, sizeof( vstring ) ); // TODO: correct?

  haxe_string->t = string_type;

  haxe_string->bytes = hl_to_utf16( gdnative_core->godot_char_string_get_data( &char_string ) );

  haxe_string->length = gdnative_core->godot_char_string_length( &char_string );

  gdnative_core->godot_char_string_destroy( &char_string );

  return haxe_string;

}

DEFINE_PRIM( _STRING, String_toHaxeString, _GH_STRING );


HL_PRIM gh_godot_string *HL_NAME( String_fromHaxeString )( vstring *haxe_string ) {

  gh_godot_string *godot_string = gh_String_new();

  gdnative_core->godot_string_parse_utf8( godot_string->value, hl_chars( haxe_string ) );

  return godot_string;

}

DEFINE_PRIM( _GH_STRING, String_fromHaxeString, _STRING );
