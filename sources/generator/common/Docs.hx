package common;

using StringTools;

import sys.FileSystem;

import sys.io.File;

import haxe.xml.Parser;

import haxe.xml.Access;


abstract ClassDocs( Null< Access > ) from Null< Access > to Null< Access > {

  public inline function new( name: String ) {

    if ( FileSystem.exists( 'inputs/godot/doc/classes/${ name }.xml' ) ) {

      this = new Access( Parser.parse( File.getContent( 'inputs/godot/doc/classes/${ name }.xml' ) ).firstElement() );

    } else {

      this = null;

    }

  }

  public inline function description()

    return this != null ? trimDescription( this.node.description.innerHTML ) : null;

  public inline function methods(): Array< MethodDocs >

    return this != null && this.hasNode.methods ? this.node.methods.nodes.method : [];

  public inline function members(): Array< MemberDocs >

    return this != null && this.hasNode.members ? this.node.members.nodes.member : [];

  public inline function signals(): Array< SinglaDocs >

    return this != null && this.hasNode.signals ? this.node.signals.nodes.signal : [];

  public inline function constants(): Array< ConstantDocs >

    return this != null && this.hasNode.constants ? this.node.constants.nodes.constant : [];

}


abstract MethodDocs( Access ) from Access to Access {

  public inline function name()

    return this.att.name;

  public inline function description()

    return trimDescription( this.node.description.innerHTML );

}


abstract MemberDocs( Access ) from Access to Access {

  public inline function name()

    return this.att.name;

  public inline function description()

    return trimDescription( this.innerHTML );

}


abstract SinglaDocs( Access ) from Access to Access {

  public inline function name()

    return this.att.name;

  public inline function description()

    return trimDescription( this.node.description.innerHTML );

}


abstract ConstantDocs( Access ) from Access to Access {

  public inline function name()

    return this.att.name;

  public inline function value()

    return this.att.value;

  public inline function group()

    return this.has.resolve( 'enum' ) ? this.att.resolve( 'enum' ) : '';

  public inline function description()

    return trimDescription( this.innerHTML );

}


private function trimDescription( html: String )

  return ~/\n\t{2}/g.replace( html, '\n' ).trim();
