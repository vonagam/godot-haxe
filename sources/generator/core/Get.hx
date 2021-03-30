package core;

using StringTools;

import haxe.Json;

import sys.FileSystem;

import sys.io.File;

using vhx.ds.MapTools;

using vhx.str.StringTools;

import common.data.*;

import common.Docs;

import core.Fix;

import core.Operator;


private typedef ApiJson = {

  api: Array< FuncJson >,

  version: { major: Int, minor: Int },

  ?next: ApiJson,

};

private typedef FuncJson = {

  name: String,

  return_type: String,

  arguments: Array< Array< String > >,

};


function getCoreTypes( primitiveTypes: Array< PrimitiveTypeData >, objectType: TypeData ) {

  final gdnTypes = new Map< String, TypeData >();

  for ( type in primitiveTypes ) gdnTypes[ type.name.gdn ] = type;

  gdnTypes[ objectType.name.gdn ] = objectType;


  final gdsNames = [ for ( name in FileSystem.readDirectory( 'inputs/godot/doc/classes' ) ) {

    if ( ! ~/^[A-Z].+\.xml/.match( name ) ) continue;

    final gdsName = name.removeSuffix( '.xml' );

    final id = 'godot' + gdsName.toLowerCase();

    id => gdsName;

  } ];


  final coreTypes = new Map< String, CoreTypeData >();

  final funcs = new Array< {

    type: CoreTypeData,

    version: String,

    name: String,

    signature: Array< Array< String > >,

  } >();

  var api: ApiJson = Json.parse( File.getContent( 'inputs/godot-headers/gdnative_api.json' ) ).core;

  while ( api != null ) {

    for ( func in api.api ) {

      if ( func.arguments.length == 0 ) continue;

      if ( ! func.arguments[ 0 ][ 0 ].endsWith( ' *' ) ) continue;

      final signature = [ [ func.return_type, '' ] ].concat( func.arguments );

      if ( signature.iter().any( part -> part[ 0 ].endsWith( 'void *' ) || part[ 0 ].endsWith( '**' ) ) ) continue;

      final gdnName = func.arguments[ 0 ][ 0 ].removePrefix( 'const ' ).removeSuffix( ' *' );

      if ( gdnName == 'godot_object' ) continue;

      final methodName = func.name.removePrefix( gdnName + '_' );

      if ( methodName == func.name ) continue;

      final gdsName = gdsNames[ gdnName.remove( '_' ) ];

      if ( gdsName == null ) continue;

      final type = coreTypes.getOrSet( gdnName, () -> new CoreTypeData().tap( type -> {

        type.name.gdn = gdnName;

        type.name.gds = gdsName;

        type.name.c = gdnName;

        type.name.gh = 'gh_${ gdnName }';

        type.name.hx = gdsName;

        type.name.prim = '_GH_${ gdnName.removePrefix( 'godot_' ).toUpperCase() }';

        type.allocate = 'hl_gc_alloc_noptr( sizeof( ${ gdnName } ) )';

        gdnTypes[ type.name.gdn ] = type;

      } ) );

      final version = '${ api.version.major }_${ api.version.minor }';

      if ( methodName == 'destroy' ) {

        type.name.c = 'gh_core_wrapper';

        type.allocate = 'gh_core_wrapper_alloc( sizeof( ${ gdnName } ), ( void * ) gdnative_core_${ version }->${ gdnName }_destroy )';

        type.unwrap = '->value';

        continue;

      }

      funcs.push( { type: type, version: version, name: methodName, signature: signature } );

    }

    api = api.next;

  }


  for ( func in funcs ) {

    final type = func.type;

    final signature = [ for ( index => part in func.signature ) {

      if ( index != 1 && part[ 1 ].startsWith( 'r_' ) ) break; // TODO: 4 methods...

      final type = gdnTypes[ part[ 0 ].removePrefix( 'const ' ).removeSuffix( ' *' ) ];

      if ( type == null ) break;

      final isConst =  part[ 0 ].startsWith( 'const ' );

      if ( index == 0 && isConst ) break;

      final isPointer = part[ 0 ].endsWith( ' *' );

      if ( type is PrimitiveTypeData && isPointer ) break;

      final value = new ValueData();

      value.name.gh = 'p_' + part[ 1 ].removePrefix( 'p_' ).removePrefix( 'r_' );

      value.name.hx = value.name.gh.toCamelCase();

      value.type = type;

      value.isPointer = part[ 0 ].endsWith( ' *' );

      value;

    } ];

    if ( signature.length != func.signature.length ) continue;

    final method = new MethodData();

    method.name.gdn = func.name;

    method.name.hx = func.name.toCamelCase();

    method.name.prim = '${ type.name.hx }_${ method.name.hx }';

    method.signature = signature;

    method.callee = 'gdnative_core_${ func.version }->${ type.name.gdn }_${ func.name }';

    changeOperatorName( method );

    type.methods.push( method );

  }


  for ( type in coreTypes ) {

    final docs = new ClassDocs( type.name.gds );

    if ( docs == null ) continue;

    type.doc = docs.description();

    for ( docs in docs.methods() ) {

      final name = docs.name();

      final method = type.methods.iter().find( _ -> _.name.gdn == name )!;

      if ( method == null ) continue;

      method.doc = docs.description();

    }

    for ( docs in docs.members() ) {

      final name = docs.name();

      final getterName = docs.getter().pipe( _ -> _ == '' ? 'get_${ name }' : _ );

      final getter = type.methods.iter().find( _ -> _.name.gdn == getterName );

      if ( getter == null ) continue;

      final setterName = docs.setter().pipe( _ -> _ == '' ? 'set_${ name }' : _ );

      final setter = type.methods.iter().find( _ -> _.name.gdn == setterName );

      final property = new PropertyData();

      property.name.gds = name;

      property.name.hx = name.toCamelCase();

      property.getter = getter;

      property.setter = setter;

      property.doc = docs.description();

      type.properties.push( property );

    }

    // TODO: constants

    fixType( type );

  }


  return coreTypes.iterValues().toArray();

}
