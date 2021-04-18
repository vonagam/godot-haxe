package core;

using vhx.str.StringTools;

import vhx.macro.ExprTools;

import vhx.macro.ExprTools.*;

import common.data.*;

import common.Docs;


function fixType( type: CoreTypeData ) {

  switch ( type.name.hx ) {

    case 'Variant':

      final docs = new ClassDocs( '@GlobalScope' );

      for ( name in [ 'Type', 'Operator' ] ) {

        final id = 'Variant.${ name }';

        final data = new EnumData();

        data.name.gds = name;

        data.name.hx = 'Variant_${ name }';

        data.values = docs.constants().filter( _ -> _.enumed() == id ).map( ( constant ) -> {

          final value = new EnumValueData();

          value.name.gds = constant.name();

          value.value = constant.value();

          value.doc = constant.description();

          return value;

        } );

        data.nameValues();

        type.enums.push( data );

      }

    case 'Vector3' | 'Vector2':

      final axes = type.name.hx == 'Vector2' ? [ 'X', 'Y' ] : [ 'X', 'Y', 'Z' ];


      final data = new EnumData();

      data.name.gds = 'Axis';

      data.name.hx = '${ type.name.hx }_Axis';

      data.values = [ for ( index => axis in axes ) new EnumValueData().tap( _ -> {

        _.name.hx = axis;

        _.value = '${ index }';

      } ) ];

      type.enums.push( data );


      if ( type.name.hx == 'Vector2' ) return;

      final getter = type.methods.iter().find( _ -> _.name.hx == 'getAxis' )!;

      final setter = type.methods.iter().find( _ -> _.name.hx == 'setAxis' )!;

      for ( index => axis in axes ) {

        type.properties.push( new PropertyData().tap( _ -> {

          _.name.hx = axis.toLowerCase();

          _.getter = getter;

          _.setter = setter;

          _.index = index;

        } ) );

      }

    case _:

  }

}


function fixHaxe( coreType: CoreTypeData, definition: ToTypeDefinition ) {

  switch ( coreType.name.hx ) {

    case 'Dictionary' | 'Array' | 'PoolByteArray' | 'PoolColorArray' | 'PoolIntArray' | 'PoolRealArray' | 'PoolStringArray' | 'PoolVector2Array' | 'PoolVector3Array':

      final getIndex = definition.fields.iter().find( _ -> _.name == 'getIndex' )!;

      if ( getIndex != null ) definition.fields.remove( getIndex );


      definition.fields.iter().find( _ -> _.name == 'get' )!.meta!.push( geMeta( macro @:op( [] ) _ ) );

      definition.fields.iter().find( _ -> _.name == 'set' )!.meta!.push( geMeta( macro @:op( [] ) _ ) );


      if ( coreType.name.hx == 'Dictionary' ) {

        final iterators = gdFields( macro class {

          public function iterator() {

            return values().iterator();

          }

          public function keyValueIterator() {

            final keys = keys();

            final size = keys.size();

            var index = 0;

            return { hasNext: () -> index < size, next: () -> {

              final key = keys.get( index++ );

              return { key: key, value: get( key ) };

            } };

          }

        } );

        definition.fields.push( iterators[ 0 ] );

        definition.fields.push( iterators[ 1 ] );

      } else {

        final iterators = gdFields( macro class {

          public function iterator() {

            final size = size();

            var index = 0;

            return { hasNext: () -> index < size, next: () -> get( index++ ) };

          }

          public function keyValueIterator() {

            final size = size();

            var index = 0;

            return { hasNext: () -> index < size, next: () -> { key: index, value: get( index++ ) } };

          }

        } );

        definition.fields.push( iterators[ 0 ] );

        definition.fields.push( iterators[ 1 ] );

      }

    case 'Variant':

      for ( field in definition.fields ) {

        if ( field.name.hasPrefix( 'as' ) ) field.meta!.push( meta( ':to' ) );

        if ( field.name.hasPrefix( 'new' ) ) switch ( field.kind ) {

          case FFun( { args: [ { type: TPath( { name: _ == 'Variant' => false } ) } ] } ):

            field.meta!.push( meta( ':from' ) );

          case _:

        }

      }

      final types = [

        'NIL' => 'Nil',
        'BOOL' => 'Bool',
        'INT' => 'Int',
        'REAL' => 'Real',
        'STRING' => 'String',
        'VECTOR2' => 'Vector2',
        'RECT2' => 'Rect2',
        'VECTOR3' => 'Vector3',
        'TRANSFORM2D' => 'Transform2D',
        'PLANE' => 'Plane',
        'QUAT' => 'Quat',
        'AABB' => 'Aabb',
        'BASIS' => 'Basis',
        'TRANSFORM' => 'Transform',
        'COLOR' => 'Color',
        'NODE_PATH' => 'NodePath',
        'RID' => 'Rid',
        'OBJECT' => 'Object',
        'DICTIONARY' => 'Dictionary',
        'ARRAY' => 'Array',
        'RAW_ARRAY' => 'PoolByteArray',
        'INT_ARRAY' => 'PoolIntArray',
        'REAL_ARRAY' => 'PoolRealArray',
        'STRING_ARRAY' => 'PoolStringArray',
        'VECTOR2_ARRAY' => 'PoolVector2Array',
        'VECTOR3_ARRAY' => 'PoolVector3Array',
        'COLOR_ARRAY' => 'PoolColorArray'

      ];

      for ( value => name in types ) {

        final name = 'is${ name }';

        definition.fields.push( gdField( macro class {

          public inline function $name(): Bool return getType() == Variant_Type.$value;

        } ) );

      }

    case _:

  }

}
