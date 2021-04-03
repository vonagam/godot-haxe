package common.data;

import haxe.macro.Expr;

using vhx.str.ERegTools;

using vhx.ds.MapTools;

import vhx.macro.ExprTools;

import vhx.macro.ExprTools.*;

import common.Docs;


@:using( common.data.ConstantData )

class ConstantData {

  public var name = new NameData();

  public var type: TypeData;

  public var index: Int = -1;

  public var value: String;

  public var doc: Null< String >;


  public function new() {}


  private static final infPattern = ~/\binf\b/;

  private static final callPattern = ~/^(.+)\( (.*) \)$/;

  public static function setConstants( type: ClassTypeData, docs: ClassDocs, primitiveTypes: Iterable< PrimitiveTypeData >, coreTypes: Iterable< CoreTypeData > ) {

    final int = primitiveTypes.iter().find( _ -> _.name.gds == 'int' )!;

    for ( docs in docs.constants() ) {

      if ( docs.enumed() != '' ) continue;

      final value = docs.value();

      if ( infPattern.match( value ) ) continue; // TODO: look into infinity in gdn/hx?

      final constructor = callPattern.getMatched( value, 1 );

      final constant = new ConstantData();

      constant.name.gds = docs.name();

      constant.name.hx = constant.name.gds;

      constant.type = constructor == null ? int : coreTypes.iter().find( _ -> _.name.gds == constructor )!;

      constant.value = value;

      constant.doc = docs.description();

      type.constants.push( constant );

    }

  }

  public static function setDefaults( argument: ValueData, docs: ValueDocs ) {

    final value = docs.defaults();

    if ( value == null ) return;

    final constant = new ConstantData();

    constant.type = argument.type;

    constant.value = value;

    argument.defaults = constant;

  }


  public static function collectDefaults( types: Iterable< ClassTypeData > ) {

    final constants = new Array< ConstantData >();

    final indexes = new Map< String, Int >();

    for ( type in types ) for ( method in type.methods ) for ( value in method.signature ) {

      final constant = value.defaults;

      if ( constant == null || constant.value == 'null' || ! constant.type.isPointer ) continue;

      constant.index = indexes.getOrSet( constant.value, () -> constants.push( constant ) - 1 );

    }

    return constants;

  }


  public static function cCreate( constant: ConstantData, name: String ) {

    final value = constant.value;

    final info = callPattern.getMatcheds( value, [ 1, 2 ] );

    return ( switch ( info! ) {

      case null if ( value.charAt( 0 ) == '"' ):

        'gh_String_new(); gdnative_core->godot_string_parse_utf8( ( ( gh_godot_string * ) ${ name } )->value, ${ value } )';

      case null if ( value == '[  ]' ):

        'gh_Array_new()';

      case [ 'Basis', args ]:

        final vectors = ~/-?\d, -?\d, -?\d/.forMatched( args ).iter().map( _ -> 'gh_Vector3_new( ${ _ } )' );

        'gh_Basis_newWithRows( ${ vectors.join( ', ' ) } )';

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

      case [ 'Plane', args ]:

        'gh_Plane_newWithReals( ${ args } )';

      case [ 'Quat', args ]:

        'gh_Quat_new( ${ args } )';

      case [ 'Rect2', args ]:

        'gh_Rect2_new( ${ args } )';

      case [ 'Transform', args ]:

        final vectors = ~/-?\d, -?\d, -?\d/.forMatched( args ).iter().map( _ -> 'gh_Vector3_new( ${ _ } )' );

        'gh_Transform_newWithAxisOrigin( ${ vectors.join( ', ' ) } )';

      case [ 'Transform2D', args ]:

        final vectors = ~/-?\d, -?\d/.forMatched( args ).iter().map( _ -> 'gh_Vector2_new( ${ _ } )' );

        'gh_Transform2D_newAxisOrigin( ${ vectors.join( ', ' ) } )';

      case [ 'Vector2', args ]:

        'gh_Vector2_new( ${ args } )';

      case [ 'Vector3', args ]:

        'gh_Vector3_new( ${ args } )';

      case _:

        trace( 'Cannot understand value: ${ value }.' );

        'NULL';

    } ) + ';\n\n';

  }

  public static function cGetter( constant: ConstantData, type: ClassTypeData ) {

    if ( ! constant.type.isPointer ) return '';

    return (

      'HL_PRIM ${ constant.type.name.gh } *HL_NAME( ${ type.name.hx }_${ constant.name.hx } )() {\n\n' +

      '  ${ constant.type.name.gh } *result = ${ constant.cCreate( 'result' ) }' +

      '  return result;\n\n' +

      '}\n\n' +

      'DEFINE_PRIM( ${ constant.type.name.prim }, ${ type.name.hx }_${ constant.name.hx }, _NO_ARG );\n\n\n'

    );

  }

  public static function cDefaultsInit( constants: Array< ConstantData > ) {

    return (

      'void gh_defaults_init() {\n\n' +

      '  gh_defaults = hl_alloc_array( &hlt_abstract, ${ constants.length } );\n\n' +

      '  hl_add_root( &gh_defaults );\n\n' +

      [ for ( index => constant in constants ) {

        final access = 'hl_aptr( gh_defaults, void * )[ ${ index } ]';

        '  ${ access } = ${ constant.cCreate( access ) }';

      } ].join( '' ) +

      '}\n\n\n'

    );

  }

  public static function cDefaultsUse( constant: Null< ConstantData >, argument: ValueData ) {

    if ( constant == null ) return '';

    final value = constant.value;

    if ( value == 'null' ) return '';

    final index = constant.index;

    final name = argument.name.gh;

    final type = argument.type;

    if ( type.isPointer ) {

      return '  ${ name } = ${ name } == NULL ? hl_aptr( gh_defaults, void * )[ ${ index } ] : ${ name };\n\n';

    } else {

      return '  ${ type.name.gh } ${ name } = o${ name } == NULL ? ${ value } : o${ name }->v.${ type.name.hlv };\n\n';

    }

  }

  public static function defineIn( constant: ConstantData, definition: ToTypeDefinition ) {

    final doc = constant.doc;

    final name = constant.name.hx;

    final type = tPath( constant.type.name.hx );

    if ( constant.type.isPointer ) {

      definition.fields.push( fProp( name, 'get', 'never', type, { doc: doc, access: [ APublic, AStatic ] } ) );


      final metas = [ meta( ':hlNative', [ 'gh', '${ definition.name }_${ name }' ] ) ];

      final body = eThrow( 8 );

      definition.fields.push( fFun( 'get_${ name }', [], type, { meta: metas, access: [ APrivate, AStatic ], body: body } ) );

    } else {

      final expr = EConst( constant.value.indexOf( '.' ) == -1 ? CInt( constant.value ) : CFloat( constant.value ) );

      definition.fields.push( fVar( name, type, { doc: doc, access: [ APublic, AStatic, AFinal ], defaults: expr } ) );

    }

  }

}
