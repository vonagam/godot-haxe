function main(): Void {

  gd.hl.Api.init();

}


@:gd( script )

class HaxeNode extends gd.Node {

  @:gd var prop: Int = 4;


  @:gd function hello(): gd.String {

    final child = new gd.Node();

    this.addChild( child );

    final references = new HaxeReference();

    final vectorOne = new gd.Vector2( 1, 2 );

    final vectorTwo = new gd.Vector2( 3, 4 );

    final vectorThree = vectorOne + vectorTwo + gd.Vector2.UP * 2;

    trace( vectorThree.y );

    trace( prop );

    return 'hello, ${ this.getClass() }';

  }

}


class HaxeReference extends gd.Reference {

}
