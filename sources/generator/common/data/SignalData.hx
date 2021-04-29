package common.data;

import haxe.macro.Expr;

using vhx.str.StringTools;

import vhx.macro.ExprTools;

import vhx.macro.ExprTools.*;


@:using( common.data.SignalData.SignalDataTools )

class SignalData {

  public var name = new NameData();

  public var arguments = new Array< ValueData >();

  public var doc: Null< String >;


  public function new() {}

}


class SignalDataTools {

  public static function defineIn( data: SignalData, definition: ToTypeDefinition ) {

    final name = data.name.hx;

    final getterName = 'get_${ name }';


    final complexType = TPath( { pack: [ 'gd', 'hl' ], name: 'Signal', params: [

      TPExpr( macro $v{ data.name.gds } ),

      TPType( TFunction( data.arguments.map( _ -> TNamed( _.name.hx, tPath( _.type.name.hx ) ) ), macro : Void ) )

    ] } );


    final fields = gdFields( macro class {

      public var $name( get, never ): $complexType;

      private extern inline function $getterName() return this;

    } );

    fields[ 0 ].doc = data.doc;

    definition.fields.append( fields );

  }

}
