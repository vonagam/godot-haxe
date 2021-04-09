package gd.hl;

#if macro

import Array;

import String;

using Lambda;

using StringTools;

import haxe.macro.Context;

import haxe.macro.Expr;

import haxe.macro.Type;


typedef GdParams = Array< Expr >;

typedef ClassInfo = {

  classType: ClassType,

  typePath: TypePath,

  complexType: ComplexType,

  gdParams: GdParams,

  gdName: String,

}

typedef FieldInfo = {

  classInfo: ClassInfo,

  field: Field,

  gdParams: GdParams,

  gdName: String,

}

#end


class Macro {

  #if macro

  static final registerSteps = new Array< Expr >();

  static var variantType: Type;

  static var objectType: Type;

  #end


  public static macro function register() {

    return macro $b{ registerSteps };

  }


  #if macro

  public static function build(): Array< Field > {

    final classType = Context.getLocalClass().get();

    if ( isClassGdNative( classType ) ) return null;


    if ( variantType == null ) {

      variantType = Context.resolveType( TPath( { pack: [ 'gd' ], name: 'Variant' } ), Context.currentPos() );

      objectType = Context.resolveType( TPath( { pack: [ 'gd' ], name: 'Object' } ), Context.currentPos() );

    }


    final classInfo: ClassInfo = {

      final typePath = getClassTypePath( classType );

      final complexType = TPath( typePath );

      final gdParams = getClassGdParams( classType );

      final gdName = getGdName( classType.name, gdParams );

      { classType: classType, typePath: typePath, complexType: complexType, gdParams: gdParams, gdName: gdName };

    };

    registerClass( classInfo );


    final fields = Context.getBuildFields();

    for ( field in fields ) {

      if ( field.name == 'new' ) throw 'Cannot have a constructor in godot class. Use godot hooks.';

      final gdParams = getGdParams( field.meta );

      if ( gdParams == null ) continue;

      field.access = or( field.access, [] );

      final fieldInfo: FieldInfo = {

        final gdName = getGdName( field.name, gdParams );

        { classInfo: classInfo, field: field, gdParams: gdParams, gdName: gdName };

      };

      registerField( fieldInfo );

    }


    final constructor = {

      final classGdName = classInfo.gdName;

      final ownerGdName = getOwnerGdName( classType );

      ( macro class {

        public function new( doConstruct: Bool = true ) {

          super( false );

          if ( doConstruct ) gd.hl.Api.constructScript( this, $v{ ownerGdName }, $v{ classGdName } );

        }

      } ).fields[ 0 ];

    };

    fields.push( constructor );


    return fields;

  }


  static inline function or< T >( value: Null< T >, fallback: T ): T {

    return value != null ? value : fallback;

  }


  static function getGdParams( metas: Null< Metadata > ) {

    if ( metas != null ) for ( meta in metas ) if ( meta.name == ':gd' ) return or( meta.params, [] );

    return null;

  }

  static function getGdName( name: String, gdParams: Null< GdParams > ) {

    if ( gdParams == null ) return name;

    for ( param in gdParams ) switch ( param ) {

      case macro name( $e{ { expr: EConst( CIdent( name ) | CString( name ) ) } } ): return name;

    case _: }

    return name;

  }


  static function getClassTypePath( classType: ClassType ): TypePath {

    return classType.name == classType.module

      ? { pack: classType.pack, name: classType.name }

      : { pack: classType.pack, name: classType.module, sub: classType.name };

  }

  static function isClassGdNative( classType: ClassType ) {

    return classType.meta.has( ':gd.native' );

  }

  static function getClassGdParams( classType: ClassType ) {

    return or( getGdParams( classType.meta.get() ), [] );

  }

  static function getParentGdName( classType: ClassType ) {

    final classParent = classType.superClass.t.get();

    return getGdName( classParent.name, getClassGdParams( classParent ) );

  }

  static function getOwnerGdName( classType: ClassType ) {

    while ( true ) {

      classType = classType.superClass.t.get();

      if ( isClassGdNative( classType ) ) return classType.name;

    }

  }

  static function getClassConstruct( typePath: TypePath ) {

    return macro () -> new $typePath( false );

  }

  static function isClassTool( gdParams: GdParams ) {

    return gdParams.exists( _ -> switch ( _ ) {

      case macro tool: true;

      case _: false;

    } );

  }

  static function registerClass( classInfo: ClassInfo ) {

    final classGdName = classInfo.gdName;

    final parentGdName = getParentGdName( classInfo.classType );

    final construct = getClassConstruct( classInfo.typePath );

    final isTool = isClassTool( classInfo.gdParams );

    final doc = classInfo.classType.doc;

    registerSteps.push( macro gd.hl.Api.registerClass(

      $v{ classGdName },

      $v{ parentGdName },

      $e{ construct },

      $v{ isTool },

      $e{ doc == null ? macro null : macro $v{ doc } }

    ) );

  }


  static function getFieldRpcMode( gdParams: GdParams ) {

    for ( param in gdParams ) switch ( param ) {

      case macro rpc( $e{ { expr: EConst( CIdent( mode ) | CString( mode ) ) } } ): return mode.toUpperCase();

    case _: }

    return 'DISABLED';

  }

  static function isFieldRegistered( fieldInfo: FieldInfo ) {

    final field = fieldInfo.field;

    if ( ! field.access.contains( AOverride ) ) return false;

    var fieldOwner = fieldInfo.classInfo.classType;

    while ( true ) {

      fieldOwner = fieldOwner.superClass.t.get();

      final foundField = fieldOwner.fields.get().find( _ -> _.name == field.name );

      if ( foundField == null ) continue;

      final isRegistered = getGdParams( foundField.meta.get() ) != null;

      if ( isRegistered ) return true;

      final foundOverride = fieldOwner.overrides.find( _ -> _.get().name == field.name );

      if ( foundOverride != null ) continue;

      final isNative = isClassGdNative( fieldOwner );

      return ! isNative;

    }

  }

  static function registerField( fieldInfo: FieldInfo ) {

    final field = fieldInfo.field;

    if ( ! field.access.contains( APublic ) ) {

      field.access.push( APublic );

    }

    if ( isFieldRegistered( fieldInfo ) ) {

      if ( fieldInfo.gdParams.length > 0 ) throw "Cannot customisze field registration during override.";

      return;

    }

    switch ( field.kind ) {

      case FFun( func ): registerMethod( fieldInfo, func );

      case FVar( type, expr ): registerProperty( fieldInfo, true, true, type, expr );

      case FProp( get, set, type, expr ): registerProperty( fieldInfo, get != 'null' && get != 'never', set != 'null' && set != 'never', type, expr );

    }

  }


  static function registerMethod( fieldInfo: FieldInfo, func: Function ) {

    if ( func.ret == null ) throw "Cannot register a method with an unspecified return type.";

    if ( func.args.exists( _ -> _.type == null ) ) throw "Cannot register a method with an unspecified argument type.";

    final classGdName = fieldInfo.classInfo.gdName;

    final fieldGdName = fieldInfo.gdName;

    final method = {

      final arguments = [ for ( index => arg in func.args )

        arg.opt == true

          ? macro args[ $v{ index } ]

          : macro args.length > $v{ index } ? args[ $v{ index } ] : null

      ];

      final classComplexType = fieldInfo.classInfo.complexType;

      final fieldName = fieldInfo.field.name;

      final call = macro ( instance: $classComplexType ).$fieldName( $a{ arguments } );

      final body = func.ret.match( macro : Void )

        ? macro { $call; return gd.Variant.newNil(); }

        : macro return $call;

      macro function( instance: Any, args: hl.NativeArray< gd.Variant > ): gd.Variant $body;

    };

    final rpcMode = getFieldRpcMode( fieldInfo.gdParams );

    final doc = fieldInfo.field.doc;

    registerSteps.push( macro gd.hl.Api.registerMethod(

      $v{ classGdName },

      $v{ fieldGdName },

      $e{ method },

      gd.MultiplayerAPI_RPCMode.$rpcMode,

      $e{ doc == null ? macro null : macro $v{ doc } }

    ) );

  }


  static function getPropertyGdType( fieldInfo: FieldInfo, type: Type ) {

    for ( param in fieldInfo.gdParams ) switch ( param ) {

      case macro type( $e{ { expr: EConst( CIdent( name ) | CString( name ) ) } } ): switch ( name ) {

        case 'null': return 'NIL';

        case 'Bool': return 'BOOL';

        case 'UInt' | 'Int': return 'INT';

        case 'Float' | 'Single': return 'REAL';

        case 'String': return 'STRING';

        case _: type = Context.resolveType( TPath( { pack: [ 'gd' ], name: name } ), fieldInfo.field.pos );

      }

    case _: }

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

          case TInst( _.get() => { kind: KExpr( { expr: EConst( CString( name ) ) } ) }, _ ):

            if ( name == 'gh_godot_variant' ) return 'NIL'; // TODO: right?

            if ( pattern.match( name ) ) return pattern.replace( name, '' ).toUpperCase();

        case _: }

        case { name: 'String', pack: [] }: return 'STRING';

        case _: if ( Context.unify( type, objectType ) ) return 'OBJECT';

      }

    case _: }

    throw 'Cannot determine variant type for property "${ fieldInfo.field.name }".';

  }

  static function registerProperty( fieldInfo: FieldInfo, hasGet: Bool, hasSet: Bool, complexType: Null< ComplexType >, expr: Null< Expr > ) {

    if ( complexType == null ) throw "Cannot register a property with an unspecified type.";

    final classGdName = fieldInfo.classInfo.gdName;

    final fieldGdName = fieldInfo.gdName;


    final type = Context.resolveType( complexType, fieldInfo.field.pos );

    final gdType = getPropertyGdType( fieldInfo, type );


    final isObject = gdType == 'OBJECT';

    final classComplexType = fieldInfo.classInfo.complexType;

    final fieldName = fieldInfo.field.name;


    var getter = macro null;

    if ( hasGet ) {

      if ( ! isObject && ! Context.unify( type, variantType ) ) throw "Cannot register a property that cannot be cast tp Variant.";

      getter = macro function( instance: Any ): gd.Variant return ( instance: $classComplexType ).$fieldName;

    }


    var setter = macro null;

    if ( hasSet ) {

      if ( ! isObject && ! Context.unify( variantType, type ) ) throw "Cannot register a property that cannot be cast from Variant.";

      final value = isObject ? macro ( ( value.asObject(): Any ): $complexType ) : macro value;

      setter = macro function( instance: Any, value: gd.Variant ): Void ( instance: $classComplexType ).$fieldName = $value;

    }


    final defaultValue = expr != null ? macro ( ( $expr: $complexType ): gd.Variant ) : macro null;

    final rpcMode = getFieldRpcMode( fieldInfo.gdParams );

    final doc = fieldInfo.field.doc;

    registerSteps.push( macro gd.hl.Api.registerProperty(

      $v{ classGdName },

      $v{ fieldGdName },

      $e{ getter }, // TODO: get() param

      $e{ setter }, // TODO: set() param

      Variant_Type.$gdType,

      $e{ defaultValue },

      PropertyUsageFlags.DEFAULT | PropertyUsageFlags.SCRIPT_VARIABLE, // TODO: usage() param

      PropertyHint.NONE, // TODO: hint() param, add missing property hints to enum

      "",

      gd.MultiplayerAPI_RPCMode.$rpcMode,

      $e{ doc == null ? macro null : macro $v{ doc } }

    ) );

  }

  #end

}
