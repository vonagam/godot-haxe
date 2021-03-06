package gd.hl;

#if macro

import Array;

import String;

using Lambda;

using StringTools;

import haxe.macro.Context;

import haxe.macro.Expr;

import haxe.macro.Type;

using haxe.macro.Tools;

using gd.hl.Macro.Tools;

using gd.hl.Macro.MetadataTools;


class Tools {

  public static inline function nullOr< T >( value: Null< T >, mapNull: () -> T ): T

    return value != null ? value : mapNull();

  public static inline function nullMap< T, R >( value: Null< T >, mapT: ( value: T ) -> R ): Null< R >

    return value != null ? mapT( value ) : null;

  public static inline function nullTurn< T, R >( value: Null< T >, mapT: ( value: T ) -> R, mapNull: () -> R ): R

    return value != null ? mapT( value ) : mapNull();

  public static inline function nullIsTrue< T >( value: Null< T >, condition: ( value: T ) -> Bool )

    return value != null ? condition( value ) == true : false;

  public static inline function nullIsFalse< T >( value: Null< T >, condition: ( value: T ) -> Bool )

    return value != null ? condition( value ) == false : false;


  public static inline function pipe< T, R >( value: T, func: ( value: T ) -> R )

    return func( value );

  public static inline function tap< T >( value: T, func: ( value: T ) -> Void ) {

    func( value );

    return value;

  }

}


class ClassData {

  public var classType: ClassType;

  public var isNative: Bool;

  public var name: String;

  public var owner: ClassData;


  public function new() {}

}

class CustomClassData extends ClassData {

  public var parent: ClassData;

  public var tool: Bool;

  public var typePath: TypePath;

  public var complexType: ComplexType;

  public var additions: Array< Field >;


  public function new() super();

}

class FieldData {

  public var classData: CustomClassData;

  public var field: Field;

  public var params: Array< Expr >;

  public var name: String;

  public var rpc: String;


  public function new() {}

}


#end

class Macro {

  #if macro

  public static final registerSteps = new Array< Expr >();

  public static final scripts = new Array< String >();


  #end

  public static macro function register() {

    return macro $b{ registerSteps };

  }

  #if macro


  public static function build() {

    Types.init( Context.currentPos() );

    return ClassMacro.build();

  }

  public static function signal() {

    Types.init( Context.currentPos() );

    return SignalMacro.build();

  }

  public static function generate() {

    if ( Sys.args().contains( '--no-output' ) ) return;

    Context.onAfterGenerate( () -> {

      sys.FileSystem.createDirectory( 'gh' );

      final template = new haxe.Template(

        '[gd_resource type="NativeScript" load_steps=2 format=2]\n\n' +

        '[ext_resource path="res://gh.gdnlib" type="GDNativeLibrary" id=1]\n\n' +

        '[resource]\n' +

        'class_name = "::name::"\n' +

        'library = ExtResource( 1 )\n'

      );

      for ( name in scripts ) {

        final path = 'gh/${ name }.gdns';

        final content = template.execute( { name: name } );

        sys.io.File.saveContent( path, content );

      }

    } );

  }

  #end

}

#if macro


class Types {

  public static var Variant: Type;

  public static var Object: Type;


  public static function init( position: Position ) {

    if ( Variant != null ) return;

    Variant = Context.resolveType( TPath( { pack: [ 'gd' ], name: 'Variant' } ), position );

    Object = Context.resolveType( TPath( { pack: [ 'gd' ], name: 'Object' } ), position );

  }

}


class MetadataTools {

  public static function getParams( metadata: Null< Metadata > ) {

    var params: Null< Array< Expr > > = null;

    if ( metadata != null ) for ( meta in metadata ) {

      if ( meta.name == ':gd' ) {

        if ( params == null ) params = [];

        if ( meta.params != null ) for ( param in meta.params ) params.push( param );

      } else if ( meta.name.startsWith( ':gd.' ) ) {

        if ( params == null ) params = [];

        final key = macro $i{ meta.name.substring( 4 ) };

        params.push( meta.params == null || meta.params.length == 0 ? key : macro $key = ${ meta.params[ 0 ] } );

      }

    }

    return params;

  }

}


class ClassDataTools {

  static final datas = new Map< String, ClassData >();

  static final names = new Map< String, ClassData >();


  public static function get( classType: ClassType ) {

    final id = '${ classType.module }.${ classType.name }';

    if ( datas.exists( id ) ) return datas[ id ];


    final classData = classType.meta.has( ':gd.native' )

      ? makeNative( classType )

      : makeCustom( classType );

    datas[ id ] = classData;


    final name = classData.name;

    if ( names.exists( name ) ) throw 'Cannot have multiple classes named "${ name }".';

    names[ name ] = classData;


    return classData;

  }


  static function makeNative( classType: ClassType ) {

    return new ClassData().tap( _ -> {

      _.classType = classType;

      _.isNative = true;

      _.name = classType.name;

      _.owner = _;

    } );

  }

  static function makeCustom( classType: ClassType ) {

    return new CustomClassData().tap( _ -> {

      _.classType = classType;

      _.isNative = false;

      _.name = '${ classType.module }.${ classType.name }';

      _.parent = get( classType.superClass.t.get() );

      _.owner = _.parent.owner;

      _.tool = false;

      _.typePath = { pack: classType.pack, name: classType.module, sub: classType.name };

      _.complexType = TPath( _.typePath );

      _.additions = [];


      var isScript = false;

      final params = classType.meta.get().getParams();

      if ( params != null ) for ( param in params ) switch ( param ) {

        case macro tool, macro tool = true: _.tool = true;

        case macro tool = false: _.tool = false;

        case macro script, macro script = true: isScript = true;

        case macro script = false: isScript = false;

        case macro script = $e{ expr }: isScript = true; _.name = expr.toString();

        case macro name = $e{ expr }: _.name = expr.toString();

        case _: throw 'Cannot understand godot class param "${ param.toString() }".';

      }


      if ( isScript ) Macro.scripts.push( _.name );

    } );

  }

}


class ClassMacro {

  public static function build() {

    final classType = Context.getLocalClass().get();

    final classData = ClassDataTools.get( classType );

    if ( classData.isNative ) return null;


    final classData = ( cast classData: CustomClassData );

    final fields = Context.getBuildFields();


    doRegister( classData );

    doFields( classData, fields );

    doConstructor( classData, fields );

    // TODO: move assigning default values to _init?


    return fields.concat( classData.additions );

  }


  static function doRegister( classData: CustomClassData ) {

    final typePath = classData.typePath;

    Macro.registerSteps.push( macro gd.hl.Api.registerClass(

      $v{ classData.name },

      $v{ classData.parent.name },

      () -> new $typePath( false ),

      $v{ classData.tool },

      $e{ classData.classType.doc.nullTurn( _ -> macro $v{ _ }, () -> macro null ) }

    ) );

  }

  static function doFields( classData: CustomClassData, fields: Array< Field > ) {

    for ( field in fields ) FieldMacro.build( classData, field );

  }

  static function doConstructor( classData: CustomClassData, fields: Array< Field > ) {

    if ( fields.exists( _ -> _.name == 'new' ) ) throw 'Cannot have a constructor in godot class. Use godot hooks.';

    final constructor = ( macro class {

      public function new( doConstruct: Bool = true ) {

        super( false );

        if ( doConstruct ) gd.hl.Api.constructScript( this, $v{ classData.owner.name }, $v{ classData.name } );

      }

    } ).fields[ 0 ];

    classData.additions.push( constructor );

  }

}


class FieldDataTools {

  public static function make( classData: CustomClassData, field: Field, params: Array< Expr > ) {

    return new FieldData().tap( _ -> {

      _.classData = classData;

      _.field = field;

      _.params = params;

      _.name = field.name; // TODO: convert by default?

      _.rpc = 'DISABLED';


      for ( param in params ) switch ( param ) {

        case macro name = $i{ value }: _.name = value;

        case macro remote: _.rpc = 'REMOTE';

        case macro remotesync: _.rpc = 'REMOTESYNC';

        case macro master: _.rpc = 'MASTER';

        case macro puppet: _.rpc = 'PUPPET';

        case macro rpc = $i{ value }: _.rpc = value.toUpperCase();

      case _: }

    } );

  }

}


class FieldMacro {

  public static function build( classData: CustomClassData, field: Field ) {

    final isRegistered = isRegistered( classData, field );

    final params = field.meta.getParams().nullOr( () -> isRegistered ? [] : null );

    if ( params == null ) return;


    field.access = field.access.nullOr( () -> [] );

    if ( ! field.access.contains( APublic ) ) field.access.push( APublic );


    if ( isRegistered ) params.length > 0 ? throw 'Cannot use godot options for a field during override.' : return;


    final fieldData = FieldDataTools.make( classData, field, params );

    switch ( field.kind ) {

      case FFun( func ) if ( params.exists( _ -> switch ( _ ) { case macro signal: true; case _: false; } ) ):

        SignalFieldMacro.build( fieldData, func );

      case FFun( func ):

        MethodFieldMacro.build( fieldData, func );

      case FVar( type, expr ):

        PropertyFieldMacro.build( fieldData, true, true, type, expr );

      case FProp( get, set, type, expr ):

        PropertyFieldMacro.build( fieldData, get != 'null' && get != 'never', set != 'null' && set != 'never', type, expr );

    }

  }

  public static function exprFromVariant( expr: Expr, complexType: ComplexType, fieldData: FieldData ) {

    final topType = Context.resolveType( complexType, fieldData.field.pos );

    if ( Context.unify( Types.Variant, topType ) ) return expr;

    final bottomType = Context.followWithAbstracts( topType );

    if ( Context.unify( bottomType, Types.Object ) ) return macro ( $expr.asObject(): Any );

    return null;

  }

  public static function getVariantType( fieldData: FieldData, ?type: Type, ?params: Array< Expr > ) {

    if ( params != null ) for ( param in params ) switch ( param ) {

      case macro type = $i{ name }: switch ( name ) {

        case 'null': return 'NIL';

        case 'Bool': return 'BOOL';

        case 'UInt' | 'Int': return 'INT';

        case 'Float' | 'Single': return 'REAL';

        case 'String': return 'STRING';

        case _: type = Context.resolveType( TPath( { pack: [ 'gd' ], name: name } ), fieldData.field.pos );

      }

    case _: }

    if ( type == null ) return 'NIL';

    final type = Context.followWithAbstracts( type );

    final pattern = ~/^gh_godot_(pool_)?/;

    switch ( type ) {

      case TAbstract( _.get() => abstractType, _ ): switch ( abstractType ) {

        case { name: 'Bool', pack: [] }: return 'BOOL';

        case { name: 'Int' | 'UInt', pack: [] }: return 'INT';

        case { name: 'Float' | 'Single', pack: [] }: return 'REAL';

      case _: }

      case TInst( _.get() => classType, params ): switch ( classType ) {

        case { name: 'Abstract', pack: [ 'hl' ] }: switch ( params[ 0 ] ) {

          case TInst( _.get() => { kind: KExpr( macro $v{ ( name: String ) } ) }, _ ):

            if ( name == 'gh_godot_variant' ) return 'NIL'; // TODO: correct?

            if ( pattern.match( name ) ) return pattern.replace( name, '' ).toUpperCase();

        case _: }

        case { name: 'String', pack: [] }: return 'STRING';

        case _: if ( Context.unify( type, Types.Object ) ) return 'OBJECT';

      }

    case _: }

    throw 'Cannot determine variant type in "${ fieldData.field.name }".';

  }


  static function isRegistered( classData: CustomClassData, field: Field ) {

    if ( ! field.access.nullIsTrue( _ -> _.contains( AOverride ) ) ) return false;

    var fieldOrigin = classData.classType;

    while ( true ) {

      fieldOrigin = fieldOrigin.superClass.t.get();

      final isRegistered = fieldOrigin.fields.get().find( _ -> _.name == field.name ).nullIsTrue( _ -> _.meta.get().getParams() != null );

      if ( isRegistered ) return true;

      final isOverride = fieldOrigin.overrides.exists( _ -> _.get().name == field.name );

      if ( isOverride ) continue;

      final isNative = fieldOrigin.meta.has( ':gd.native' );

      return ! isNative;

    }

  }

}


class MethodFieldMacro {

  public static function build( fieldData: FieldData, func: Function ) {

    if ( func.ret == null ) throw 'Cannot register a method with an unspecified return type.';

    final method = {

      final arguments = [ for ( index => arg in func.args ) {

        if ( arg.type == null ) throw 'Cannot register a method with an unspecified argument type.';

        final value = FieldMacro.exprFromVariant( macro args[ $v{ index } ], arg.type, fieldData );

        arg.opt != true

          ? value

          : macro args.length > $v{ index } && ! args[ $v{ index } ].isNil() ? $value : null;

      } ];

      final classComplexType = fieldData.classData.complexType;

      final fieldName = fieldData.field.name;

      final call = macro ( instance: $classComplexType ).$fieldName( $a{ arguments } );

      final body = func.ret.match( macro : Void )

        ? macro { $call; return gd.Variant.newNil(); }

        : macro return $call;

      macro function( instance: Any, args: hl.NativeArray< gd.Variant > ): gd.Variant $body;

    };

    final rpc = fieldData.rpc;

    Macro.registerSteps.push( macro gd.hl.Api.registerMethod(

      $v{ fieldData.classData.name },

      $v{ fieldData.name },

      $e{ method },

      gd.MultiplayerAPI_RPCMode.$rpc,

      $e{ fieldData.field.doc.nullTurn( _ -> macro $v{ _ }, () -> macro null ) }

    ) );

  }

}


class PropertyFieldMacro {

  public static function build( fieldData: FieldData, hasGet: Bool, hasSet: Bool, complexType: Null< ComplexType >, expr: Null< Expr > ) {

    if ( complexType == null ) throw 'Cannot register a property with an unspecified type.';

    final type = Context.resolveType( complexType, fieldData.field.pos );

    final variantType = FieldMacro.getVariantType( fieldData, type, fieldData.params );

    final isObject = variantType == 'OBJECT';

    final classComplexType = fieldData.classData.complexType;

    final fieldName = fieldData.field.name;


    var getter = macro null;

    if ( hasGet ) {

      final canCast = Context.unify( type, Types.Variant );

      if ( ! canCast ) throw 'Cannot register a property that cannot be cast to Variant.';

      getter = macro function( instance: Any ): gd.Variant return ( instance: $classComplexType ).$fieldName;

    }


    var setter = macro null;

    if ( hasSet ) {

      final value = FieldMacro.exprFromVariant( macro value, complexType, fieldData );

      if ( value == null ) throw 'Cannot register a property that cannot be cast from Variant.';

      setter = macro function( instance: Any, value: gd.Variant ): Void ( instance: $classComplexType ).$fieldName = $value;

    }


    final defaultValue = expr != null ? macro ( ( $expr: $complexType ): gd.Variant ) : macro null;

    final rpc = fieldData.rpc;


    Macro.registerSteps.push( macro gd.hl.Api.registerProperty(

      $v{ fieldData.classData.name },

      $v{ fieldData.name },

      $e{ getter }, // TODO: get() param

      $e{ setter }, // TODO: set() param

      Variant_Type.$variantType,

      $e{ defaultValue },

      PropertyUsageFlags.DEFAULT | PropertyUsageFlags.SCRIPT_VARIABLE, // TODO: usage() param

      PropertyHint.NONE, // TODO: hint() param, add missing property hints to enum

      '',

      gd.MultiplayerAPI_RPCMode.$rpc,

      $e{ fieldData.field.doc.nullTurn( _ -> macro $v{ _ }, () -> macro null ) }

    ) );

  }

}


class SignalFieldMacro {

  public static function build( fieldData: FieldData, func: Function ) {

    final complexType = TPath( { pack: [ 'gd', 'hl' ], name: 'Signal', params: [

      TPExpr( macro $v{ fieldData.name } ),

      TPType( TFunction( func.args.map( _ -> TNamed( _.name, _.type ) ), macro : Void ) )

    ] } );


    fieldData.field.kind = ( macro class {

      var _( get, null ): $complexType;

    } ).fields[ 0 ].kind;


    final getterName = 'get_${ fieldData.field.name }';

    fieldData.classData.additions.push( ( macro class {

      private extern inline function $getterName() return this;

    } ).fields[ 0 ] );


    final arguments = [ for ( arg in func.args ) {

      if ( arg.type == null ) throw 'Cannot register a method with an unspecified argument type.';

      final name = arg.name;

      final type = Context.resolveType( arg.type, fieldData.field.pos );

      final params = arg.meta.getParams();

      final variantType = FieldMacro.getVariantType( fieldData, type, params );

      macro new gd.hl.Api.ArgumentData( $v{ name }, Variant_Type.$variantType );

    } ];


    Macro.registerSteps.push( macro gd.hl.Api.registerSignal(

      $v{ fieldData.classData.name },

      $v{ fieldData.name }, // TODO: should remove on_ prefix by default?

      $a{ arguments },

      $e{ fieldData.field.doc.nullTurn( _ -> macro $v{ _ }, () -> macro null ) }

    ) );

  }

}


class SignalMacro {

  static var counter = 0;

  static var kind = TDAbstract( macro : gd.Object, [ macro : gd.Object ], [ macro : gd.Object ] );


  public static function build() {

    final pos = Context.currentPos();


    var signal: String;

    var args: Array< { t: Type, opt: Bool, name: String } >;

    switch ( Context.getLocalType() ) {

      case TInst( _, [

        TInst( _.get() => { kind: KExpr( macro $v{ ( signalValue: String ) } ) }, _ ),

        TFun( argsValue, _ )

      ] ):

        signal = signalValue;

        args = argsValue;

    case _: throw false; };


    final emitFuncArgs = args.map( _ -> ( { name: _.name, type: _.t.toComplexType() }: FunctionArg ) );

    final emitCallArgs = [ macro $v{ signal } ].concat( args.map( _ -> macro $i{ _.name } ) );


    final fields = ( macro class {

      public extern inline function connect( target: gd.Object, method: gd.String, ?binds: gd.Array, ?flags: Int ): gd.Error

        return this.connect( $v{ signal }, target, method, binds, flags );

      public extern inline function disconnect( target: gd.Object, method: gd.String ): Void

        this.disconnect( $v{ signal }, target, method );

      @:op( _() ) public extern inline function emit(): Void

        this.emitSignal( $a{ emitCallArgs } );

    } ).fields;

    fields[ 2 ].kind = switch ( fields[ 2 ].kind ) {

      case FFun( func ): FFun( { args: emitFuncArgs, ret: func.ret, expr: func.expr } );

    case _: throw false; };


    final name = 'Signal${ counter++ }';

    final definition: TypeDefinition = {

      pos: pos,

      pack: [ 'gd', 'hl', 'Signal' ],

      isExtern: true,

      name: name,

      kind: kind,

      fields: fields,

    };

    Context.defineType( definition );


    return TPath( { pack: [ 'gd', 'hl' ], name: 'Signal', sub: name } );

  }

}

#end
