import godot.GdHl;


function main(): Void {

  godot.Object.GdHlTagsSetup.run();


  GdHl.registerClass( 'HaxeReference', 'Reference', () -> new HaxeReference( false ), false, null );


  GdHl.registerClass( 'HaxeNode', 'Node', () -> new HaxeNode( false ), false, null );

  GdHl.registerMethod( 'HaxeNode', 'hello', function( node: Any, args: hl.NativeArray< godot.Variant > ): godot.Variant {

    trace( args[ 0 ].asReal() );

    final node: HaxeNode = node;

    return node.hello();

  }, 0, null );

  GdHl.registerProperty( 'HaxeNode', 'prop', function( node: Any ): godot.Variant {

    return ( node: HaxeNode ).prop;

  }, function( node: Any, variant: godot.Variant ) {

    ( node: HaxeNode ).prop = variant;

  }, godot.Variant.Type.INT, 4, 1 + 2, 0, "", 0, null );

}


class HaxeNode extends godot.Node {

  public var prop: Int = 4;

  public function new( doConstruct: Bool = true ) {

    super( false );

    if ( doConstruct ) GdHl.constructScript( this, 'Node', 'HaxeNode' );

    trace( "HaxeNode is constructed." );

  }

  public function hello(): godot.Vector2 {

    final child = new godot.Node();

    this.addChild( child, true );

    final references = new HaxeReference();

    final vectorOne = new godot.Vector2( 1, 2 );

    final vectorTwo = new godot.Vector2( 3, 4 );

    final vectorThree = vectorOne + vectorTwo;

    trace( vectorThree.y );

    trace( "Hello from Haxe." );

    return vectorThree;

  }

}


class HaxeReference extends godot.Reference {

  public function new( doConstruct: Bool = true ) {

    super( false );

    if ( doConstruct ) GdHl.constructScript( this, 'Reference', 'HaxeReference' );

    trace( "HaxeReference is constructed." );

  }

}
