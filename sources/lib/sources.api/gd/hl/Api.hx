package gd.hl;

import String;


class ConstructorBind {

  final name: String;

  final construct: () -> gd.Object;


  public function new( name: String, construct: () -> gd.Object ) {

    this.name = name;

    this.construct = construct;

  }

}

class ArgumentData {

  final name: String;

  final type: gd.Variant_Type;


  public function new( name: String, type: gd.Variant_Type ) {

    this.name = name;

    this.type = type;

  }

}


class Api {

  @:hlNative( 'gh', 'register_class' )

  public static function registerClass(

    className: String,

    parentName: String,

    construct: () -> gd.Object,

    isTool: Bool,

    ?documentation: String

  ): Void throw 8;


  @:hlNative( 'gh', 'register_method' )

  public static function registerMethod(

    className: String,

    methodName: String,

    method: ( instance: Any, args: hl.NativeArray< gd.Variant > ) -> gd.Variant,

    rpcMode: gd.MultiplayerAPI_RPCMode,

    ?documentation: String

  ): Void throw 8;


  @:hlNative( 'gh', 'register_property' )

  public static function registerProperty(

    className: String,

    propertyPath: String,

    getter: Null< ( instance: Any ) -> gd.Variant >,

    setter: Null< ( instance: Any, value: gd.Variant ) -> Void >,

    type: gd.Variant_Type,

    defaultValue: Null< gd.Variant >,

    usage: gd.PropertyUsageFlags,

    hint: gd.PropertyHint,

    hintString: String,

    rpcMode: gd.MultiplayerAPI_RPCMode,

    ?documentation: String

  ): Void throw 8;


  @:hlNative( 'gh', 'register_signal' )

  public static function registerSignal(

    className: String,

    signalName: String,

    arguments: gd.hl.NativeArray< ArgumentData >,

    ?documentation: String

  ): Void throw 8;


  @:hlNative( 'gh', 'construct_binding' )

  public static function constructBinding( object: gd.Object, ownerClassName: String ): Void throw 8;


  @:hlNative( 'gh', 'construct_singleton' )

  public static function constructSingleton( object: gd.Object, ownerClassName: String ): Void throw 8;


  @:hlNative( 'gh', 'construct_script' )

  public static function constructScript( object: gd.Object, ownerClassName: String, scriptClassName: String ): Void throw 8;


  @:hlNative( 'gh', 'binding_set_constructors' )

  public static function bindConstructors( constructors: hl.NativeArray< ConstructorBind > ): Void throw 8;


  @:hlNative( 'gh', 'extra_set_string_type' )

  public static function setStringType( type: hl.Type ): Void throw 8;


  public static function init() {

    setStringType( hl.Type.get( ( null: String ) ) );

    gd.hl.Objects.init();

    gd.hl.Macro.register();

  }

}
