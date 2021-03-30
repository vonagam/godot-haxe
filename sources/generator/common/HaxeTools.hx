package common;

import sys.io.File;

import vhx.macro.ExprTools;

import vhx.macro.Printer;


class HaxeTools {

  public static function output( definition: ToTypeDefinition, hl: Bool = false ) {

    final pack = hl ? 'gd.hl' : 'gd';

    final folder = hl ? 'gd/hl' : 'gd';

    final printer = new Printer( '  ' );

    final haxe = 'package ${ pack };\n\n' + printer.printTypeDefinition( definition );

    File.saveContent( 'sources/lib/sources/${ folder }/${ definition.name }.hx', haxe );

  }

}
