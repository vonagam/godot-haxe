package object;

using StringTools;

import haxe.Json;

import sys.io.File;

using vhx.ds.MapTools;

using vhx.str.StringTools;

using vhx.iter.IterTools;

import common.Data;

import core.Data;

import object.Data;


typedef ObjectJson = {

  name: String,

  base_class: String,

  singleton_name: String,

  instanciable: Bool,

  is_reference: Bool,

  constants: haxe.DynamicAccess< Int >,

  properties: Array< {

    name: String,

    type: String,

    getter: String,

    setter: String,

    index: Int,

  } >,

  signals: Array< {

    name: String,

    arguments: Array< {

      name: String,

      type: String,

      default_value: String,

    } >,

  } >,

  methods: Array< {

    name: String,

    return_type: String,

    is_virtual: Bool,

    has_varargs: Bool,

    arguments: Array< {

      name: String,

      type: String,

      has_default_value: Bool,

      default_value: String,

    } >,

  } >,

  enums: Array< {

    name: String,

    values: haxe.DynamicAccess< Int >,

  } >,

};


function getObjectType() {

  final type = new ObjectTypeData();

  type.name.gds = 'Object';

  type.name.hx = 'Object';

  type.isInstanciable = true;

  return type;

}


function getObjectTypes( primitiveTypes: Array< PrimitiveTypeData >, objectType: ObjectTypeData, coreTypes: Array< CoreTypeData > ) {

  final basicTypes = new Map< String, TypeData >();

  primitiveTypes.iter().map( _ -> { key: _.name.gds, value: ( _: TypeData ) } ).toMapInto( basicTypes ); // TODO: find a way to remove value cast

  coreTypes.iter().map( _ -> { key: _.name.gds, value: ( _: TypeData ) } ).toMapInto( basicTypes );


  final objectJsons: Array< ObjectJson > = Json.parse( File.getContent( 'inputs/godot_headers/api.json' ) );

  final objectTypes = [ for ( objectJson in objectJsons ) {

    objectJson.name => new ObjectTypeData().tap( type -> {

      type.name.gds = objectJson.name;

      type.name.hx = ~/[^A-Za-z0-9]/.replace( objectJson.name, '' ); // TODO: check if such names exist

      type.isInstanciable = objectJson.instanciable;

      type.isSingleton = objectJson.singleton_name != ''; // TODO: check if singleton name can be different from name

    } );

  } ];

  objectTypes[ objectType.name.gds ] = objectType;


  final getType = ( gdsName: String ) -> nil( basicTypes[ gdsName ] ).orMaybe( () -> objectTypes[ gdsName ] );

  for ( objectJson in objectJsons ) {

    final objectType = objectTypes[ objectJson.name ];

    objectType.parent = objectTypes[ objectJson.base_class ];

    for ( methodJson in objectJson.methods ) {

      if ( methodJson.name == 'new' ) continue;

      if ( methodJson.has_varargs ) continue; // TODO: handle varargs

      final returnType = getType( methodJson.return_type );

      if ( returnType == null ) continue; // TODO: check if any

      final signature = [ for ( argJson in methodJson.arguments ) {

        final type = getType( argJson.type )!;

        if ( type == null ) break;

        final value = new ValueData();

        value.name.gh = 'p_' + argJson.name;

        value.name.hx = value.name.gh.toCamelCase();

        value.type = type;

        value.isPointer = type.isPointer;

        value;

      } ];

      if ( signature.length != methodJson.arguments.length ) continue;

      signature.unshift( new ValueData().tap( value -> value.type = returnType ) );

      final method = new MethodData();

      method.name.gds = methodJson.name;

      method.name.hx = ( methodJson.name.charAt( 0 ) == '_' ? '_' : '' ) + methodJson.name.toCamelCase();

      method.name.prim = '${ objectType.name.hx }_${ method.name.hx }';

      method.isVirtual = methodJson.is_virtual;

      method.signature = signature;

      objectType.methods.push( method );

    }

    // public var properties = new Array< PropertyData >();

    // public var signals = new Array< SignalData >();

    // public var enums = new Array< EnumData >();

  }


  return objectTypes.iterValues().toArray();

}
