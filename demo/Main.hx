function main(): Void {

  gd.hl.InitApi.init();


  gd.hl.Api.registerClass( 'HaxeReference', 'Reference', () -> new HaxeReference( false ), false, null );


  gd.hl.Api.registerClass( 'HaxeNode', 'Node', () -> new HaxeNode( false ), false, null );

  gd.hl.Api.registerMethod( 'HaxeNode', 'hello', function( node: Any, args: hl.NativeArray< gd.Variant > ): gd.Variant {

    trace( args[ 0 ].asReal() );

    final node: HaxeNode = node;

    return node.hello();

  }, 0, null );

  gd.hl.Api.registerProperty( 'HaxeNode', 'prop', function( node: Any ): gd.Variant {

    return ( node: HaxeNode ).prop;

  }, function( node: Any, variant: gd.Variant ) {

    ( node: HaxeNode ).prop = variant;

  }, gd.Variant_Type.INT, 4, 1 + 2, 0, "", 0, null );

}


class HaxeNode extends gd.Node {

  public var prop: Int = 4;

  public function new( doConstruct: Bool = true ) {

    super( false );

    if ( doConstruct ) gd.hl.Api.constructScript( this, 'Node', 'HaxeNode' );

    trace( "HaxeNode is constructed." );

  }

  public function hello(): gd.String {

    final child = new gd.Node();

    this.addChild( child );

    final references = new HaxeReference();

    final vectorOne = new gd.Vector2( 1, 2 );

    final vectorTwo = new gd.Vector2( 3, 4 );

    final vectorThree = vectorOne + vectorTwo + gd.Vector2.UP * 2;

    trace( vectorThree.y );

    trace( prop );

    return this.getClass();

  }

}


class HaxeReference extends gd.Reference {

  public function new( doConstruct: Bool = true ) {

    super( false );

    if ( doConstruct ) gd.hl.Api.constructScript( this, 'Reference', 'HaxeReference' );

    trace( "HaxeReference is constructed." );

  }

}
