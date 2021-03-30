package common.data;

using vhx.str.StringTools;

import vhx.macro.ExprTools.*;


@:using( common.data.MethodData.MethodDataTools )

class MethodData {

  public var name = new NameData();

  public var isVirtual = false;

  public var signature = new Array< ValueData >();

  public var callee = '';

  public var doc: Null< String >;


  public function new() {}

}


class MethodDataTools {

  public static function isConstructor( method: MethodData )

    return method.name.hx == 'new' || method.name.gdn.hasPrefix( 'new_' );

  public static function metas( method: MethodData )

    return [ meta( ':hlNative', [ 'gh', method.name.prim ] ) ];


  public static function hSignature( method: MethodData, returns: ValueData, arguments: Array< ValueData > ) {

    return (

      '${ returns.ghType() }HL_NAME( ${ method.name.prim } )( ${

        arguments.map( _ -> _.ghArg() ).join( ', ' )

      } );\n\n'

    );

  }

  public static function cSignature( method: MethodData, returns: ValueData, arguments: Array< ValueData > ) {

    return (

      'HL_PRIM ${ returns.ghType() }HL_NAME( ${ method.name.prim } )( ${

        arguments.map( _ -> _.ghArg() ).join( ', ' )

      } ) {\n\n'

    );

  }

  public static function primSignature( method: MethodData, returns: ValueData, arguments: Array< ValueData > ) {

    return (

      'DEFINE_PRIM( ${ returns.type.name.prim }, ${ method.name.prim }, ${

        arguments.length == 0 ? '_NO_ARG' : arguments.map( _ -> _.ghPrim() ).join( ' ' )

      } );\n\n'

    );

  }

}
