package gd.hl;


@:transitive @:forward

extern abstract NativeArray< T >( hl.NativeArray< T > ) from hl.NativeArray< T > to hl.NativeArray< T > {

  @:from public static inline function fromArray< T >( array: std.Array< T > ): NativeArray< T > {

    final result = new hl.NativeArray< T >( array.length );

    for ( index => arg in array ) result[ index ] = arg;

    return result;

  }

  @:from public static inline function fromRest< T >( rest: haxe.Rest< T > ): NativeArray< T > {

    final result = new hl.NativeArray< T >( rest.length );

    for ( index => arg in rest ) result[ index ] = arg;

    return result;

  }

}
