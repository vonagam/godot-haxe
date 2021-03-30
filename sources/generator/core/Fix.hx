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

    case 'Dictionary':

      definition.fields.iter().find( _ -> _.name == 'set' )!.meta!.push( geMeta( macro @:op( [] ) _ ) );

    case 'GdArray':

      definition.fields.iter().find( _ -> _.name == 'set' )!.meta!.push( geMeta( macro @:op( [] ) _ ) );

    case 'PoolByteArray' | 'PoolColorArray' | 'PoolIntArray' | 'PoolRealArray' | 'PoolStringArray' | 'PoolVector2Array' | 'PoolVector3Array':

      definition.fields.iter().find( _ -> _.name == 'get' || _.name == 'set' )!.meta!.push( geMeta( macro @:op( [] ) _ ) );

    case 'Variant':

      for ( field in definition.fields ) {

        if ( field.name.hasPrefix( 'as' ) ) field.meta!.push( meta( ':to' ) );

        if ( field.name.hasPrefix( 'new' ) ) switch ( field.kind ) {

          case FFun( { args: [ { type: TPath( { name: _ == 'Variant' => false } ) } ] } ):

            field.meta!.push( meta( ':from' ) );

          case _:

        }

      }

    case _:

  }

}
