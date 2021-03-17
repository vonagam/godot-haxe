package core;

using StringTools;

import haxe.macro.Expr;

using vhx.str.StringTools;

using vhx.iter.IterTools;

import vhx.macro.ExprTools;

import vhx.macro.ExprTools.*;

import common.Haxe;

import common.Docs;

import core.Data;


function fixHaxe( coreType: CoreTypeData, definitions: Array< ToTypeDefinition > ) {

  switch ( coreType.name.hx ) {

    case 'Dictionary':

      definitions[ 0 ].fields.iter().find( _ -> _.name == 'set' )!.meta!.push( geMeta( macro @:op( [] ) _ ) );

    case 'GdArray':

      definitions[ 0 ].fields.iter().find( _ -> _.name == 'set' )!.meta!.push( geMeta( macro @:op( [] ) _ ) );

    case 'PoolByteArray' | 'PoolColorArray' | 'PoolIntArray' | 'PoolRealArray' | 'PoolStringArray' | 'PoolVector2Array' | 'PoolVector3Array':

      definitions[ 0 ].fields.iter().find( _ -> _.name == 'get' || _.name == 'set' )!.meta!.push( geMeta( macro @:op( [] ) _ ) );

    case 'Variant':

      final docs = new ClassDocs( '@GlobalScope' );

      for ( name in [ 'Type', 'Operator' ] ) {

        final id = 'Variant.${ name }';

        definitions.push( HaxeTools.makeEnum( name, docs.constants().filter( _ -> _.group() == id ).map( constant -> {

          name: constant.name(),

          value: constant.value(),

          doc: constant.description(),

        } ) ) );

      }

      for ( field in definitions[ 0 ].fields ) {

        if ( field.name.hasPrefix( 'as' ) ) field.meta!.push( meta( ':to' ) );

        if ( field.name.hasPrefix( 'new' ) ) switch ( field.kind ) {

          case FFun( { args: [ { type: TPath( { name: _ == 'Variant' => false } ) } ] } ):

            field.meta!.push( meta( ':from' ) );

          case _:

        }

      }

    case 'Vector3':

      definitions.push( HaxeTools.makeEnum( 'Axis', [

        { name: 'X', value: '0' },

        { name: 'Y', value: '1' },

        { name: 'Z', value: '2' },

      ] ) );


      final getter = coreType.methods.iter().find( _ -> _.name.hx == 'getAxis' )!;

      final setter = coreType.methods.iter().find( _ -> _.name.hx == 'setAxis' )!;

      for ( index => name in [ 'x', 'y', 'z' ] ) {

        HaxeTools.addMemberFields( definitions[ 0 ], name, getter, setter, index, null );

      }

    case _:

  }

}
