package common.data;

import vhx.macro.ExprTools.*;


@:using( common.data.ValueData.ValueDataTools )

class ValueData {

  public var name = new NameData();

  public var type: TypeData;

  public var isPointer = false;

  public var defaults: Null< ConstantData > = null;


  public function new() {}

}


class ValueDataTools {

  public static function gdnType( value: ValueData )

    return '${ value.type.name.gdn } ${ value.isPointer ? '*' : '' }';

  public static function ghType( value: ValueData )

    return '${ value.type.name.gh } ${ value.type.isPointer ? '*' : '' }';

  public static function ghVariable( value: ValueData )

    return ghType( value ) + value.name.gh;

  public static function ghArg( value: ValueData )

    return value.defaults == null || value.type.isPointer ? ghVariable( value ) : 'vdynamic *o${ value.name.gh }';

  public static function ghPrim( value: ValueData )

    return value.defaults == null || value.type.isPointer ? value.type.name.prim : '_NULL( ${ value.type.name.prim } )';

  public static function hxArg( value: ValueData )

    return arg( ( value.defaults == null ? '' : '?' ) + value.name.hx, tPath( value.type.name.hx ) );

  public static function ghUnwrap( value: ValueData ) {

    final expression = '${ value.name.gh }${ value.type.unwrap }';

    if ( value.isPointer == value.type.isPointer ) return expression;

    if ( value.isPointer == true ) return '&' + expression;

    if ( value.type.unwrap == '' ) return '*' + expression;

    return '*( ( ${ value.type.name.gdn } * ) ${ expression } )';

  }

}
