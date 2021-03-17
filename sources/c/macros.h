#ifndef GH_MACROS_H
#define GH_MACROS_H


#define HL_NAME( n ) gh_##n


#define hl_chars( string ) hl_to_utf8( string->bytes )


#define STATIC_ONCE( type, var, start, init ) \
  \
  static type var = start; if ( var == start ) var = init; \
  \
//

#define STATIC_POINTER_ONCE( type, var, init ) \
  \
  STATIC_ONCE( type, var, NULL, init )
  \
//

#define STATIC_CONSTRUCTOR_BIND( var, class_name ) \
  \
  STATIC_POINTER_ONCE( godot_class_constructor, var, gdnative_core_1_0->godot_get_class_constructor( #class_name ) ) \
  \
//

#define STATIC_METHOD_BIND( var, class_name, method_name ) \
  \
  STATIC_POINTER_ONCE( godot_method_bind *, var, gdnative_core_1_0->godot_method_bind_get_method( #class_name, #method_name ) ) \
  \
//


#endif
