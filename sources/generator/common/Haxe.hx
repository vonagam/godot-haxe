package common;

import haxe.macro.Expr;

using vhx.str.StringTools;

using vhx.iter.IterTools;

import vhx.macro.ExprTools;

import vhx.macro.ExprTools.*;

import common.Data;


class HaxeTools {

  public static function addMemberFields( definition: ToTypeDefinition, name: String, getter: MethodData, setter: Null< MethodData >, index: Int, doc: String ) {

    final type = tPath( getter.signature[ 0 ].type.name.hx );

    final eIndex = index == -1 ? null : eInt( index );

    definition.fields.push( fProp( name, 'get', ( setter == null ? 'never' : 'set' ), type, { doc: doc, access: [ APublic ] } ) );


    final getterName = 'get_${ name }';

    final getterCall = eCall( eIdent( getter.name.hx ), eIndex == null ? [] : [ eIndex ] );

    definition.fields.push( gdField( macro class {

      private extern inline function $getterName(): $type {

        return $getterCall;

      }

    } ) );


    if ( setter == null ) return;

    final setterName = 'set_${ name }';

    final eValue = eIdent( name );

    final setterCall = eCall( eIdent( setter.name.hx ), eIndex == null ? [ eValue ] : [ eIndex, eValue ] );

    definition.fields.push( gdField( macro class {

      private extern inline function $setterName( $name: $type ): $type {

        $setterCall;

        return $eValue;

      }

    } ) );

  }

  public static function makeEnum( name: String, values: Array< { name: String, value: String, ?doc: String } > ) {

    final real = tPath( 'Int' );

    final metas = [ meta( ':forward' ), meta( ':transitive' ), meta( ':enum' ) ];

    final stringPrefix = values.iter().map( _ -> _.name ).reduce( ( prefix, name ) -> {

      if ( prefix.length == 0 || name.hasPrefix( prefix ) ) return prefix;

      var i = 0;

      while ( prefix.charCodeAt( i ) == name.charCodeAt( i ) ) i++;

      return prefix.substr( 0, i );

    } )!;

    final digitPrefix = ~/[^_]+_$/.replace( stringPrefix, '' );

    final isDigit = ~/[0-9]/;

    final toName = ( input: String ) -> {

      final prefix = isDigit.match( input.charAt( stringPrefix.length ) ) ? digitPrefix : stringPrefix;

      return input.substr( prefix.length );

    };

    final fields = [ for ( value in values ) {

      fVar( toName( value.name ), null, { doc: value.doc, defaults: expr( EConst( CInt( value.value ) ) ) } );

    } ];

    final definition = dAbstract( name, real, fields, { meta: metas, from: [ real ], to: [ real ] } );

    return definition;

  }

}
