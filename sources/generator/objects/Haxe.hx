package objects;

using StringTools;

import haxe.macro.Expr;

import sys.FileSystem;

using vhx.str.StringTools;

import vhx.macro.ExprTools.*;

import common.data.*;

using common.HaxeTools;


function writeObjectHaxe( objectTypes: Array< ObjectTypeData > ) {

  FileSystem.createDirectory( 'sources/lib/sources.objects/gd/hl' );

  final apiDefinition = dClass( { name: 'Objects' } );

  final eApi = macro gd.hl.Objects;

  final doConstructArgs = [ arg( 'doConstruct', tPath( 'Bool' ), { value: eBool( true ) } ) ];

  final doConstructSuper = macro super( false );

  for ( objectType in objectTypes ) {

    final type = objectType;

    final name = type.name.hx;

    final extended = type.parent.nil().map( _ -> tyPath( _.name.hx ) );

    final definition = dClass( {

      doc: type.doc,

      meta: [ meta( ':gd.native' ) ],

      name: name,

      extended: extended,

    } );


    // TODO: isSingleton


    if ( name == 'Object' ) {

      definition.meta!.push( geMeta( macro @:autoBuild( gd.hl.Macro.build() ) _ ) );

      definition.meta!.push( meta( ':keepSub' ) );

      definition.fields.push( gdField( macro class {

        @:keep private final ghData: hl.Abstract< 'gh_object_data' > = null;

      } ) );

    }


    for ( property in type.properties ) {

      property.defineIn( definition );

    }

    for ( constant in type.constants ) {

      constant.defineIn( definition );

    }


    {

      final access = [ type.isInstanciable ? APublic : APrivate ];

      final metas = type.isInstanciable ? [] : geMetas( macro @:allow( gd.hl.Objects.init ) _ );

      final name = 'new';

      final doConstruct = macro if ( doConstruct ) gd.hl.Api.constructBinding( this, $v{ type.name.gds } );

      final body = eBlock( extended.turn( () -> [ doConstructSuper, doConstruct ], () -> [ doConstruct ] ) );

      final field = fFun( name, doConstructArgs, null, { access: access, meta: metas, body: body } );

      definition.fields.push( field );

    }


    for ( method in type.methods ) {

      final name = method.name.hx;

      final apiName = '${ objectType.name.hx }_${ name }';

      final arguments = method.signature.slice( 1 );

      final args = arguments.map( _ -> _.hxArg() );

      final returns = method.signature[ 0 ].type.name.hx;

      final type = tPath( returns );

      {

        final metas = method.metas();

        final access = [ APublic, AStatic ];

        final apiArgs = [ arg( 'that', tPath( objectType.name.hx ) ) ].concat( args );

        if ( method.hasVarArg ) apiArgs.push( arg( 'pArgs', tPath( 'gd.hl.NativeArray', [ tPath( 'Variant' ) ] ) ) );

        final body = eThrow( 8 );

        final field = fFun( apiName, apiArgs, type, { meta: metas, access: access, body: body } );

        apiDefinition.fields.push( field );

      }

      {

        final doc = method.doc;

        final isVirtual = method.isVirtual;

        final isOverride = isVirtual && objectType.parent.iterByOne( _ -> _.parent ).any( _ -> _.methods.iter().any( _ -> _.name.hx == name ) );

        final access = [ APublic ];

        if ( ! isVirtual ) access.push( AInline );

        if ( isOverride ) access.push( AOverride );

        final callArgs = [ eIdent( 'this' ) ].concat( arguments.map( _ -> eIdent( _.name.hx ) ) );

        if ( method.hasVarArg ) {

          args.push( arg( '...pArgs', tPath( 'Variant' ) ) );

          callArgs.push( eIdent( 'pArgs' ) );

        }

        final call = eCall( eField( eApi, apiName ), callArgs );

        final body = returns == 'Void' ? call : eReturn( call );

        final field = fFun( name, args, type, { doc: doc, access: access, body: body } );

        definition.fields.push( field );

      }

    }


    if ( name != 'GlobalConstants' ) definition.output( 'objects' );

    for ( data in type.enums ) data.toDefinition().output( 'objects' );

  }

  {

    final types = objectTypes.filter( _ -> _.name.hx != 'GlobalConstants' );

    apiDefinition.fields.push( gdField( macro class {

      public static function init() {

        final constructors = new hl.NativeArray< Api.ConstructorBind >( $v{ types.length } );

        $b{ [ for ( index => type in types ) {

          macro constructors[ $v{ index } ] = new Api.ConstructorBind(

            $v{ type.name.gds },

            () -> $e{ eNew( tyPath( 'gd.${ type.name.hx }' ), [ eBool( false ) ] ) }

          );

        } ] }

        Api.bindConstructors( constructors );

      }

    } ) );

  }

  apiDefinition.output( 'objects', true );

}
