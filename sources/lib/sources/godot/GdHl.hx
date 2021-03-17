package godot;


class GdHlBindingConstructor {

  final name: String;

  final construct: () -> Object;


  public function new( name: String, construct: () -> Object ) {

    this.name = name;

    this.construct = construct;

  }

}


@:hlNative( 'gh' )

extern class GdHl {

  static function registerClass(

    className: String,

    ownerName: String,

    construct: () -> Object,

    isTool: Bool,

    documentation: Null< String >

  ): Void;

  static function registerMethod(

    className: String,

    methodName: String,

    method: ( instance: Any, args: hl.NativeArray< Variant > ) -> Variant,

    rpcMode: MultiplayerAPI.MultiplayerAPIRPCMode,

    documentation: Null< String >

  ): Void;

  static function registerProperty( // TODO: hint, usage, rpc enums...

    className: String,

    propertyPath: String,

    getter: Null< ( instance: Any ) -> Variant >,

    setter: Null< ( instance: Any, value: Variant ) -> Void >,

    type: Variant.Type,

    defaultValue: Variant, // TODO: nil?

    usage: GlobalConstants.PropertyUsageFlags,

    hint: GlobalConstants.PropertyHint,

    hintString: String,

    rpcMode: MultiplayerAPI.MultiplayerAPIRPCMode,

    documentation: Null< String >

  ): Void;

  static function constructBinding( object: Object, godotClassName: String ): Void;

  static function constructScript( object: Object, godotClassName: String, libraryClassName: String ): Void;

  static function bindingSetConstructors( constructors: hl.NativeArray< GdHlBindingConstructor > ): Void;

}
