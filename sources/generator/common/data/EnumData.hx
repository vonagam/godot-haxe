package common.data;

import haxe.macro.Expr;

using vhx.str.StringTools;

using vhx.str.StringTools;

import vhx.macro.ExprTools;

import vhx.macro.ExprTools.*;


@:using( common.data.EnumData.EnumDataTools )

class EnumData extends TypeData {

  public var values = new Array< EnumValueData >();


  public function new() {

    name.gdn = 'godot_int';

    name.gh = 'int';

    name.hlv = 'i';

    name.prim = '_I32';

  }


  override public function ghReturn( returns: ValueData )

    return '  return gd_return;\n\n';

}


class EnumDataTools {

  static final stringPrefixFix = ~/[^_]+$/;

  static final digitalPrefixFix = ~/[^_]+_$/;

  static final isDigit = ~/[0-9]/;

  public static function nameValues( data: EnumData ) {

    final commonPrefix = data.values.iter().map( _ -> _.name.gds ).reduce( ( prefix, name ) -> {

      if ( prefix.length == 0 || name.hasPrefix( prefix ) ) return prefix;

      var i = 0;

      while ( prefix.charCodeAt( i ) == name.charCodeAt( i ) ) i++;

      return prefix.substr( 0, i );

    } )!;

    final stringPrefix = stringPrefixFix.replace( commonPrefix, '' );

    final digitPrefix = digitalPrefixFix.replace( stringPrefix, '' );

    for ( value in data.values ) {

      final gdsName = value.name.gds;

      final prefix = isDigit.match( gdsName.charAt( stringPrefix.length ) ) ? digitPrefix : stringPrefix;

      final hxName = gdsName.substr( prefix.length );

      value.name.hx = hxName;

    }

  }


  static final type = tPath( 'Int' );

  static final metas = [ meta( ':forward' ), meta( ':transitive' ), meta( ':enum' ) ];

  public static function toDefinition( data: EnumData ) {

    return dAbstract( {

      meta: metas,

      name: data.name.hx,

      type: type,

      from: [ type ],

      to: [ type ],

      fields: [ for ( value in data.values )

        fVar( value.name.hx, null, { doc: value.doc, defaults: EConst( CInt( value.value ) ) } )

      ],

    } );

  }

}
