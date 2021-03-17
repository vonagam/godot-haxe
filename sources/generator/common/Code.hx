package common;

import common.Data;


abstract Code( StringBuf ) {

  public function new()

    this = new StringBuf();

  @:op( _ << _ ) inline function add( string: String )

    this.add( string );

  @:to inline function toString()

    return this.toString();

}


class CodeTools {

  public static function ghType( value: ValueData )

    return '${ value.type.name.gh } ${ value.type.isPointer ? '*' : '' }';

  public static function ghVariable( value: ValueData )

    return ghType( value ) + value.name.gh;

  public static function gdnType( value: ValueData )

    return '${ value.type.name.gdn } ${ value.isPointer ? '*' : '' }';

  public static function ghUnwrap( value: ValueData ) {

    final expression = '${ value.name.gh }${ value.type.unwrap }';

    if ( value.isPointer == value.type.isPointer ) return expression;

    if ( value.isPointer == true ) return '&' + expression;

    if ( value.type.unwrap == '' ) return '*' + expression;

    return '*( ( ${ value.type.name.gdn } * ) ${ expression } )';

  }


  public static function ghSignature( returns: ValueData, method: MethodData, arguments: Array< ValueData > ) {

    return (

      'HL_PRIM ${ ghType( returns ) }HL_NAME( ${ method.name.prim } )( ' +

      arguments.map( ghVariable ).join( ', ' ) +

      ' ) {\n\n'

    );

  }

  public static function primSignature( returns: ValueData, method: MethodData, arguments: Array< ValueData > ) {

    return (

      'DEFINE_PRIM( ${ returns.type.name.prim }, ${ method.name.prim }, ' +

      ( arguments.length == 0 ? '_NO_ARG' : arguments.map( _ -> _.type.name.prim ).join( ' ' ) ) +

      ' );\n\n'

    );

  }

}
