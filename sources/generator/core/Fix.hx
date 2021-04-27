package core;

using vhx.ds.ArrayTools;

using vhx.str.StringTools;

import vhx.macro.ExprTools;

import vhx.macro.ExprTools.*;

import common.data.*;

import common.Docs;


function fixType( type: CoreTypeData ) {

  switch ( type.name.hx ) {

    case 'Variant':

      final docs = new ClassDocs( '@GlobalScope' );

      for ( name in [ 'Type', 'Operator' ] ) {

        final id = 'Variant.${ name }';

        final data = new EnumData();

        data.name.gds = name;

        data.name.hx = 'Variant_${ name }';

        data.values = docs.constants().filter( _ -> _.enumed() == id ).map( ( constant ) -> {

          final value = new EnumValueData();

          value.name.gds = constant.name();

          value.value = constant.value();

          value.doc = constant.description();

          return value;

        } );

        data.nameValues();

        type.enums.push( data );

      }

    case 'Vector3' | 'Vector2':

      final axes = type.name.hx == 'Vector2' ? [ 'X', 'Y' ] : [ 'X', 'Y', 'Z' ];


      final data = new EnumData();

      data.name.gds = 'Axis';

      data.name.hx = '${ type.name.hx }_Axis';

      data.values = [ for ( index => axis in axes ) new EnumValueData().tap( _ -> {

        _.name.hx = axis;

        _.value = '${ index }';

      } ) ];

      type.enums.push( data );


      if ( type.name.hx == 'Vector2' ) return;

      final getter = type.methods.iter().find( _ -> _.name.hx == 'getAxis' )!;

      final setter = type.methods.iter().find( _ -> _.name.hx == 'setAxis' )!;

      for ( index => axis in axes ) {

        type.properties.push( new PropertyData().tap( _ -> {

          _.name.hx = axis.toLowerCase();

          _.getter = getter;

          _.setter = setter;

          _.index = index;

        } ) );

      }

    case _:

  }

}


function fixHaxe( coreType: CoreTypeData, definition: ToTypeDefinition ) {

  final haxeName = coreType.name.hx;

  final markNewFroms = () -> {

    for ( field in definition.fields ) if ( field.name.hasPrefix( 'new' ) ) switch ( field.kind ) {

      case FFun( { args: [ { type: TPath( { name: name } ) } ] } ) if ( name != haxeName ):

        field.meta!.push( meta( ':from' ) );

    case _: }

  };

  switch ( haxeName ) {

    case 'Dictionary' | 'Array' | 'PoolByteArray' | 'PoolColorArray' | 'PoolIntArray' | 'PoolRealArray' | 'PoolStringArray' | 'PoolVector2Array' | 'PoolVector3Array':

      markNewFroms();


      final getIndex = definition.fields.iter().find( _ -> _.name == 'getIndex' )!;

      if ( getIndex != null ) definition.fields.remove( getIndex );


      final get = definition.fields.iter().find( _ -> _.name == 'get' )!;

      final set = definition.fields.iter().find( _ -> _.name == 'set' )!;

      get.meta!.push( geMeta( macro @:op( [] ) _ ) );

      set.meta!.push( geMeta( macro @:op( [] ) _ ) );


      if ( haxeName == 'Dictionary' ) {

        definition.fields.append( gdFields( macro class {

          public function iterator(): Iterator< Variant > {

            return values().iterator();

          }

          public function keyValueIterator(): KeyValueIterator< Variant, Variant > {

            final keys = keys();

            final size = keys.size();

            var index = 0;

            return { hasNext: () -> index < size, next: () -> {

              final key = keys.get( index++ );

              return { key: key, value: get( key ) };

            } };

          }

          @:from public static function fromHaxeMap( map: Map< Variant, Variant > ): Dictionary {

            final dictionary = new Dictionary();

            for ( key => value in map ) dictionary.set( key, value );

            return dictionary;

          }

          // @:to public function toHaxeMap(): Map< Variant, Variant > { // TODO: haxe#10221

          //   final map = new Map< Variant, Variant >();

          //   for ( key => value in keyValueIterator() ) map.set( key, value );

          //   return map;

          // }

        } ) );

      } else {

        final typePath = tyPath( haxeName );

        final complexType = tPath( haxeName );

        final elementType = switch ( get.kind ) { case FFun( func ): func.ret; case _: throw false; };

        definition.fields.append( gdFields( macro class {

          public function iterator(): Iterator< $elementType > {

            final size = size();

            var index = 0;

            return { hasNext: () -> index < size, next: () -> get( index++ ) };

          }

          public function keyValueIterator(): KeyValueIterator< Int, $elementType > {

            final size = size();

            var index = 0;

            return { hasNext: () -> index < size, next: () -> { key: index, value: get( index++ ) } };

          }

          @:from public static function fromHaxeArray( array: std.Array< $elementType > ): $complexType {

            final result = new $typePath();

            for ( value in array ) result.pushBack( value );

            return result;

          }

          @:to public function toHaxeArray(): std.Array< $elementType > {

            final array = new std.Array< $elementType >();

            for ( value in iterator() ) array.push( value );

            return array;

          }

        } ) );

      }

    case 'Variant':

      markNewFroms();

      for ( field in definition.fields ) if ( field.name.hasPrefix( 'as' ) ) field.meta!.push( meta( ':to' ) );


      final types = [

        'NIL' => 'Nil',
        'BOOL' => 'Bool',
        'INT' => 'Int',
        'REAL' => 'Real',
        'STRING' => 'String',
        'VECTOR2' => 'Vector2',
        'RECT2' => 'Rect2',
        'VECTOR3' => 'Vector3',
        'TRANSFORM2D' => 'Transform2D',
        'PLANE' => 'Plane',
        'QUAT' => 'Quat',
        'AABB' => 'Aabb',
        'BASIS' => 'Basis',
        'TRANSFORM' => 'Transform',
        'COLOR' => 'Color',
        'NODE_PATH' => 'NodePath',
        'RID' => 'Rid',
        'OBJECT' => 'Object',
        'DICTIONARY' => 'Dictionary',
        'ARRAY' => 'Array',
        'RAW_ARRAY' => 'PoolByteArray',
        'INT_ARRAY' => 'PoolIntArray',
        'REAL_ARRAY' => 'PoolRealArray',
        'STRING_ARRAY' => 'PoolStringArray',
        'VECTOR2_ARRAY' => 'PoolVector2Array',
        'VECTOR3_ARRAY' => 'PoolVector3Array',
        'COLOR_ARRAY' => 'PoolColorArray'

      ];

      for ( value => name in types ) {

        final name = 'is${ name }';

        definition.fields.push( gdField( macro class {

          public inline function $name(): Bool return getType() == Variant_Type.$value;

        } ) );

      }


      final arrays = [

        { godot: 'Array', haxe: 'HaxeArray', type: macro : std.Array< Variant > },
        { godot: 'PoolByteArray', haxe: 'HaxeByteArray', type: macro : std.Array< hl.UI8 > },
        { godot: 'PoolIntArray', haxe: 'HaxeIntArray', type: macro : std.Array< Int > },
        { godot: 'PoolRealArray', haxe: 'HaxeRealArray', type: macro : std.Array< hl.F32 > },
        { godot: 'PoolStringArray', haxe: 'HaxeStringArray', type: macro : std.Array< String > },
        { godot: 'PoolVector2Array', haxe: 'HaxeVector2Array', type: macro : std.Array< Vector2 > },
        { godot: 'PoolVector3Array', haxe: 'HaxeVector3Array', type: macro : std.Array< Vector3 > },
        { godot: 'PoolColorArray', haxe: 'HaxeColorArray', type: macro : std.Array< Color > }

      ];

      for ( array in arrays ) {

        final newGdArray = 'new${ array.godot }';

        final asGdArray = 'as${ array.godot }';

        final fromHxArray = 'from${ array.haxe }';

        final toHxArray = 'to${ array.haxe }';

        final hxType = array.type;

        definition.fields.append( gdFields( macro class {

          @:from public static inline function $fromHxArray( array: $hxType ): Variant return $i{ newGdArray }( array );

          @:to public inline function $toHxArray(): $hxType return $i{ asGdArray }();

        } ) );

      }


      definition.fields.append( gdFields( macro class {

        @:from public static inline function fromHaxeMap( map: Map< Variant, Variant > ): Variant return newDictionary( map );

        // @:to public inline function toHaxeMap(): Map< Variant, Variant > return asDictionary();

        @:from public static inline function fromHaxeString( string: std.String ): Variant return newString( string );

        @:to public inline function toHaxeString(): std.String return asString();

      } ) );

    case 'String':

      definition.fields.append( gdFields( macro class {

        @:hlNative( "gh", "String_fromHaxeString" ) @:from

        public static function fromHaxeString( string: std.String ): gd.String throw 8;


        @:hlNative( "gh", "String_toHaxeString" ) @:to

        public function toHaxeString(): std.String throw 8;

      } ) );

    case _:

  }

}
