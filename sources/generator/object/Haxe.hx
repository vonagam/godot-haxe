package object;

using StringTools;

import haxe.macro.Expr;

import sys.FileSystem;

using vhx.str.StringTools;

import vhx.macro.ExprTools.*;

import common.data.*;

using common.HaxeTools;

import object.Api;


function writeObjectHaxe( objectTypes: Array< ObjectTypeData > ) {

  FileSystem.createDirectory( 'sources/lib/sources/gd/hl' );

  Api.writeApiHaxe( objectTypes );

  final apiDefinition = dClass( { isExtern: true, name: 'ObjectsApi' } );

  final eApi = macro gd.hl.ObjectsApi;

  final doConstructArgs = [ arg( 'doConstruct', tPath( 'Bool' ), { value: eBool( true ) } ) ];

  final doConstructSuper = macro super( false );

  for ( objectType in objectTypes ) {

    final type = objectType;

    final name = type.name.hx;

    final extended = type.parent.nil().map( _ -> tyPath( _.name.hx ) );

    final definition = dClass( {

      doc: type.doc,

      name: name,

      extended: extended,

    } );


    // TODO: isSingleton


    if ( name == 'Object' ) {

      definition.fields.push( gdField( macro class {

        private final ghData: hl.Abstract< 'gh_object_data' > = null;

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

      final metas = type.isInstanciable ? [] : geMetas( macro @:allow( gd.hl.InitApi.init ) _ );

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

        final access = [ AStatic ];

        final apiArgs = [ arg( 'that', tPath( objectType.name.hx ) ) ].concat( args );

        if ( method.hasVarArg ) apiArgs.push( arg( 'pArgs', tPath( 'hl.NativeArray', [ tParam( 'gd.Variant' ) ] ) ) );

        final field = fFun( apiName, apiArgs, type, { meta: metas, access: access } );

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

          callArgs.push( eIdent( 'args' ) );

        }

        final call = eCall( eField( eApi, apiName ), callArgs );

        var body = returns == 'Void' ? call : eReturn( call );

        if ( method.hasVarArg ) {

          body = macro {

            final args = new hl.NativeArray< Variant >( pArgs.length );

            for ( index => arg in pArgs ) args[ index ] = arg;

            $e{ body }

          };

        }

        final field = fFun( name, args, type, { doc: doc, access: access, body: body } );

        definition.fields.push( field );

      }

    }


    if ( name != 'GlobalConstants' ) definition.output();

    for ( data in type.enums ) data.toDefinition().output();

  }

  apiDefinition.output( true );

}
