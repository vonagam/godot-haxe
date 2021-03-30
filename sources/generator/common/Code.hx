package common;

import sys.io.File;


abstract Code( StringBuf ) {

  static final indentPattern = ~/(^|\n(?=[^\n]))/g;


  public function new()

    this = new StringBuf();

  @:op( _ << _ ) public function add( string: String )

    this.add( string );

  @:to public inline function toString()

    return this.toString();

  @:op( _ >> _ ) public function output( name: String )

    File.saveContent( 'sources/c/gen/${ name }', this.toString() );

}
