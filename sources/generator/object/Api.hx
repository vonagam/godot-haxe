package object;

import vhx.macro.ExprTools.*;

import common.data.*;

using common.HaxeTools;


class Api {

  public static function writeApiHaxe( objectTypes: Array< ObjectTypeData > ) {

    final bindingDefinition = macro class ConstructorBinding {

      final name: std.String;

      final construct: () -> Object;


      public function new( name: std.String, construct: () -> Object ) {

        this.name = name;

        this.construct = construct;

      }

    };

    bindingDefinition.output( true );


    final initTypes = objectTypes.filter( _ -> _.name.hx != 'GlobalConstants' );

    final initDefinition = macro class InitApi {

      public static function init() {

        final constructors = new hl.NativeArray< ConstructorBinding >( $v{ initTypes.length } );

        $b{ [ for ( index => type in initTypes ) {

          macro constructors[ $v{ index } ] = new ConstructorBinding(

            $v{ type.name.gds },

            () -> $e{ eNew( tyPath( 'gd.${ type.name.hx }' ), [ eBool( false ) ] ) }

          );

        } ] }

        Api.bindingSetConstructors( constructors );

      }

    };

    initDefinition.output( true );


    final apiDefinition = dClass( {

      meta: [ meta( ':hlNative', [ 'gh' ] ) ],

      isExtern: true,

      name: 'Api',

      fields: gdFields( macro class {

        static function registerClass(

          className: std.String,

          ownerName: std.String,

          construct: () -> Object,

          isTool: Bool,

          ?documentation: std.String

        ): Void;

        static function registerMethod(

          className: std.String,

          methodName: std.String,

          method: ( instance: Any, args: hl.NativeArray< Variant > ) -> Variant,

          rpcMode: MultiplayerAPI_RPCMode,

          ?documentation: std.String

        ): Void;

        static function registerProperty(

          className: std.String,

          propertyPath: std.String,

          getter: Null< ( instance: Any ) -> Variant >,

          setter: Null< ( instance: Any, value: Variant ) -> Void >,

          type: Variant_Type,

          defaultValue: Variant, // TODO: nil?

          usage: PropertyUsageFlags,

          hint: PropertyHint,

          hintString: std.String,

          rpcMode: MultiplayerAPI_RPCMode,

          ?documentation: std.String

        ): Void;

        static function constructBinding( object: Object, godotClassName: std.String ): Void;

        static function constructScript( object: Object, godotClassName: std.String, libraryClassName: std.String ): Void;

        static function bindingSetConstructors( constructors: hl.NativeArray< ConstructorBinding > ): Void;

      } ),

    } );

    apiDefinition.output( true );

  }

}
