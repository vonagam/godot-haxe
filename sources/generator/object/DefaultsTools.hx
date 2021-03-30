package object;

using StringTools;

using vhx.ds.MapTools;

using vhx.str.ERegTools;

import common.data.*;

import common.Code;


typedef DefaultsData = Map< String, { index: Int, access: String, init: String } >;


class DefaultsTools {

  static final callPattern = ~/^(.+)\( (.*) \)$/;

  public static function collectDefaults( objectTypes: Array< ObjectTypeData > ) {

    final result = new DefaultsData();

    var counter = 0;

    for ( type in objectTypes ) for ( method in type.methods ) for ( i => argument in method.signature ) if ( i > 0 ) {

      final type = argument.type;

      final defaults = argument.defaults;

      if ( defaults == '' || defaults == 'null' || ! type.isPointer || result.exists( defaults ) ) continue;

      final index = counter++;

      final info = callPattern.getMatcheds( defaults, [ 1, 2 ] );

      final access = 'hl_aptr( gh_defaults, void * )[ ${ index } ]';

      final init = '  ${ access } = ' + ( switch ( info! ) {

        case null if ( defaults.charAt( 0 ) == '"' ):

          'gh_String_new(); gdnative_core->godot_string_parse_utf8( hl_aptr( gh_defaults, gh_godot_string * )[ ${ index } ]->value, ${ defaults } )';

        case null if ( defaults == '[  ]' ):

          'gh_Array_new()';

        case [ 'Color', args ]:

          'gh_Color_newRgba( ${ args } )';

        case [ 'PoolColorArray', '' ]:

          'gh_PoolColorArray_new()';

        case [ 'PoolIntArray', '' ]:

          'gh_PoolIntArray_new()';

        case [ 'PoolRealArray', '' ]:

          'gh_PoolRealArray_new()';

        case [ 'PoolStringArray', '' ]:

          'gh_PoolStringArray_new()';

        case [ 'PoolVector2Array', '' ]:

          'gh_PoolVector2Array_new()';

        case [ 'PoolVector3Array', '' ]:

          'gh_PoolVector3Array_new()';

        case [ 'Rect2', args ]:

          'gh_Rect2_new( ${ args } )';

        case [ 'Transform', args ]:

          final vectors = ~/\d, \d, \d/.forMatched( args ).iter().map( _ -> 'gh_Vector3_new( ${ _ } )' );

          'gh_Transform_newWithAxisOrigin( ${ vectors.join( ', ' ) } )';

        case [ 'Transform2D', args ]:

          final vectors = ~/\d, \d/.forMatched( args ).iter().map( _ -> 'gh_Vector2_new( ${ _ } )' );

          'gh_Transform2D_newAxisOrigin( ${ vectors.join( ', ' ) } )';

        case [ 'Vector2', args ]:

          'gh_Vector2_new( ${ args } )';

        case [ 'Vector3', args ]:

          'gh_Vector3_new( ${ args } )';

        case _:

          trace( 'Cannot understand default value: ${ defaults }.' );

          'NULL';

      } ) + ';\n\n';

      result[ defaults ] = { index: index, access: access, init: init };

    }

    return result;

  }

  public static function getInitCode( data: DefaultsData ) {

    final cCode = new Code();

    cCode << 'void gh_defaults_init() {\n\n';

    cCode << '  gh_defaults = hl_alloc_array( &hlt_abstract, ${ data.iter().count() } );\n\n';

    cCode << '  hl_add_root( &gh_defaults );\n\n';

    final data = data.iterValues().toArray();

    data.sort( ( a, b ) -> a.index - b.index );

    for ( data in data ) cCode << data.init;

    cCode << '}\n\n';

    return cCode.toString();

  }

  public static function getDefaultsCode( argument: ValueData, data: DefaultsData ) {

    final defaults = argument.defaults;

    if ( defaults == '' || defaults == 'null' ) return '';

    final type = argument.type;

    final name = argument.name.gh;

    if ( type.isPointer ) {

      return '  ${ name } = ${ name } == NULL ? ${ data[ defaults ].access } : ${ name };\n\n';

    } else {

      return '  ${ argument.ghVariable() } = o${ name } == NULL ? ${ defaults } : o${ name }->v.${ type.name.hlv };\n\n';

    }

  }

}
