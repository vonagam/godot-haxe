package object;

using StringTools;

import haxe.Json;

import sys.io.File;

using vhx.ds.MapTools;

using vhx.str.StringTools;

import common.data.*;

import common.Docs;


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


function getObjectTypes( primitiveTypes: Array< PrimitiveTypeData >, objectType: ObjectTypeData, coreTypes: Array< CoreTypeData > ) {

  final gdsTypes = new Map< String, TypeData >();

  for ( type in primitiveTypes ) gdsTypes[ type.name.gds ] = type;

  for ( type in coreTypes ) {

    gdsTypes[ type.name.gds ] = type;

    for ( data in type.enums ) {

      gdsTypes[ 'enum.${ type.name.gds }::${ data.name.gds }' ] = data;

      gdsTypes[ '${ type.name.gds }.${ data.name.gds }' ] = data;

    }

  }


  final objectJsons: Array< ObjectJson > = Json.parse( File.getContent( 'inputs/godot-headers/api.json' ) );

  final objectTypes = [ for ( objectJson in objectJsons ) {

    objectJson.name => new ObjectTypeData().tap( type -> {

      type.name.gds = objectJson.name;

      type.name.hx = ~/[^A-Za-z0-9]/.replace( objectJson.name, '' );

      type.isInstanciable = objectJson.instanciable;

      type.isSingleton = objectJson.singleton_name != '';

      type.enums = [ for ( enumJson in objectJson.enums ) new EnumData().tap( data -> {

        data.name.gds = enumJson.name;

        data.name.hx = '${ type.name.hx }_${ data.name.gds }';

        data.values = [ for ( name => number in enumJson.values ) new EnumValueData().tap( value -> {

          value.name.gds = name;

          value.value = '${ number }';

        } ) ];

        data.nameValues();

        gdsTypes[ 'enum.${ type.name.gds }::${ data.name.gds }' ] = data;

        gdsTypes[ '${ type.name.gds }.${ data.name.gds }' ] = data;

      } ) ];

      gdsTypes[ type.name.gds ] = type;

    } );

  } ];

  objectTypes[ objectType.name.gds ] = objectType;

  gdsTypes[ objectType.name.gds ] = objectType;


  {

    final type = objectTypes[ 'GlobalConstants' ];

    final docs = new ClassDocs( '@GlobalScope' );

    final groups = docs.constants().iter().key( _ -> _.enumed() ).filter( _ -> _.key != '' && ! _.key.contains( '.' ) ).toGroups();

    type.enums = [ for ( name => constants in groups ) new EnumData().tap( data -> {

      data.name.gds = name;

      data.name.hx = name;

      data.values = [ for ( constant in constants ) new EnumValueData().tap( value -> {

        value.name.gds = constant.name();

        value.value = constant.value();

      } ) ];

      data.nameValues();

      gdsTypes[ 'enum.${ data.name.gds }' ] = data;

      gdsTypes[ data.name.gds ] = data;

    } ) ];

  }


  for ( objectJson in objectJsons ) {

    final docs = new ClassDocs( objectJson.name == 'GlobalConstants' ? '@GlobalScope' : objectJson.name );

    final type = objectTypes[ objectJson.name ];

    type.doc = docs.description();

    type.parent = objectTypes[ objectJson.base_class ];

    for ( methodJson in objectJson.methods ) {

      if ( methodJson.name == 'new' ) continue;

      final returns = new ValueData().tap( ( value ) -> {

        value.type = gdsTypes[ methodJson.return_type ];

      } );

      final arguments = [ for ( argJson in methodJson.arguments ) new ValueData().tap( ( value ) -> {

        value.name.gh = 'p_' + argJson.name;

        value.name.hx = value.name.gh.toCamelCase();

        value.type = gdsTypes[ argJson.type ];

        value.isPointer = type.isPointer;

      } ) ];

      final docs = docs.methods().iter().find( _ -> _.name() == methodJson.name );

      final method = new MethodData();

      method.name.gds = methodJson.name;

      method.name.hx = ( methodJson.name.charAt( 0 ) == '_' ? '_' : '' ) + methodJson.name.toCamelCase();

      if ( method.name.hx == 'import' ) method.name.hx = 'doImport';

      if ( method.name.hx == 'getName' && type.name.hx == 'EditorSpatialGizmoPlugin' ) continue; // TODO: clash, fixed in godot 4

      method.name.prim = '${ type.name.hx }_${ method.name.hx }';

      method.isVirtual = methodJson.is_virtual;

      method.hasVarArg = methodJson.has_varargs;

      method.signature = [ returns ].concat( arguments );

      method.doc = docs.map( _ -> _.description() );

      type.methods.push( method );

      for ( index => docs in docs.map( _ -> _.arguments() ) ) {

        final argument = arguments[ index ];

        argument.type = docs.enumed().pipe( _ -> _ != '' ? gdsTypes[ _ ] : argument.type );

        ConstantData.setDefaults( argument, docs );

      }

    }

  }

  for ( objectJson in objectJsons ) {

    final docs = new ClassDocs( objectJson.name == 'GlobalConstants' ? '@GlobalScope' : objectJson.name );

    final type = objectTypes[ objectJson.name ];

    function findMethod( type: ObjectTypeData, name: String ) {

      final method = type.methods.iter().find( _ -> _.name.gds == name );

      return method == null && type.parent != null ? findMethod( type.parent, name ) : method;

    }

    for ( propertyJson in objectJson.properties ) {

      if ( propertyJson.name.contains( '/' ) ) continue;

      final docs = docs.members().iter().find( _ -> _.name() == propertyJson.name );

      final property = new PropertyData();

      property.name.gds = propertyJson.name;

      property.name.hx = property.name.gds.toCamelCase();

      if ( property.name.hx == 'operator' ) property.name.hx = 'op';

      if ( property.name.hx == 'function' ) property.name.hx = 'func';

      if ( property.name.hx == 'rotate' && type.name.hx == 'PathFollow2D' ) property.name.hx = 'rotates'; // TODO: clash, fixed in godot 4

      if ( property.name.hx == 'lightMask' && type.name.hx == 'LightOccluder2D' ) property.name.hx = 'occluderLightMask'; // TODO: clash, fixed in godot 4

      property.getter = findMethod( type, propertyJson.getter );

      property.setter = propertyJson.setter == '' ? null : findMethod( type, propertyJson.setter );

      property.index = propertyJson.index;

      property.doc = docs.map( _ -> _.description() );

      if ( property.getter == null && type.name.gds == 'RootMotionView' ) continue; // TODO: godot...

      type.properties.push( property );

    }

    for ( data in type.enums ) {

      for ( value in data.values ) {

        final docs = docs.constants().iter().find( _ -> _.name() == value.name.gds );

        value.doc = docs.map( _ -> _.description() );

      }

    }

    ConstantData.setConstants( type, docs, primitiveTypes, coreTypes );

    // TODO: signals

  }


  return objectTypes.iterValues().toArray();

}
