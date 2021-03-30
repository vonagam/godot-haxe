package common.data;

import sys.io.File;

import haxe.macro.Expr;

using vhx.str.StringTools;

import vhx.macro.ExprTools;

import vhx.macro.ExprTools.*;


@:using( common.data.PropertyData.PropertyDataTools )

class PropertyData {

  public var name = new NameData();

  public var getter: MethodData;

  public var setter: Null< MethodData >;

  public var index = -1;

  public var doc: Null< String >;


  public function new() {}

}


class PropertyDataTools {

  public static function defineIn( data: PropertyData, definition: ToTypeDefinition ) {

    final name = data.name.hx;

    final type = tPath( data.getter.signature[ 0 ].type.name.hx );

    final eIndex = data.index == -1 ? null : eInt( data.index );

    definition.fields.push( fProp( name, 'get', ( data.setter == null ? 'never' : 'set' ), type, { doc: data.doc, access: [ APublic ] } ) );


    final getterName = 'get_${ name }';

    final getterArgs = new Array< ToExpr >();

    if ( eIndex != null ) getterArgs.push( eIndex );

    final getterCall = eCall( eIdent( data.getter.name.hx ), getterArgs );

    definition.fields.push( gdField( macro class {

      private extern inline function $getterName(): $type {

        return $getterCall;

      }

    } ) );


    if ( data.setter == null ) return;

    final setterName = 'set_${ name }';

    final eValue = eIdent( name );

    final setterArgs = new Array< ToExpr >();

    if ( eIndex != null ) setterArgs.push( eIndex );

    setterArgs.push( eValue );

    final setterCall = eCall( eIdent( data.setter.name.hx ), setterArgs );

    definition.fields.push( gdField( macro class {

      private extern inline function $setterName( $name: $type ): $type {

        $setterCall;

        return $eValue;

      }

    } ) );

  }

}
