package object;

using StringTools;

import haxe.macro.Expr;

import sys.FileSystem;

import sys.io.File;

using vhx.str.StringTools;

using vhx.iter.IterTools;

import vhx.macro.ExprTools.*;

import vhx.macro.Printer;

import common.Docs;

import common.Haxe;

import object.Data;


function writeObjectHaxe( objectTypes: Array< ObjectTypeData > ) {

  FileSystem.createDirectory( 'sources/lib/gen/object/godot' );

  final printer = new Printer( '  ' );

  final doConstructArgs = [ arg( 'doConstruct', tPath( 'Bool' ), { value: eBool( true ) } ) ];

  final doConstructSuper = macro super( false );

  for ( objectType in objectTypes ) {

    final type = objectType;

    final isGlobalConstants = type.name.gds == 'GlobalConstants';

    final docs = new ClassDocs( isGlobalConstants ? '@GlobalScope' : type.name.gds );

    final doc = docs.description();

    final name = type.name.hx;

    final metas = [ meta( ':using', [ macro godot.$name ] ) ];

    final extended = nil( type.parent ).map( _ -> tyPath( _.name.hx ) );

    final definition = dClass( name, [], { doc: doc, meta: metas, extended: extended } );


    if ( name == 'Object' ) {

      definition.fields.push( gdField( macro class {

        private final ghData: hl.Abstract< 'gh_object_data' > = null;

      } ) );

    }


    {

      final access = [ type.isInstanciable ? APublic : APrivate ];

      final metas = type.isInstanciable ? [] :  geMetas( macro @:allow( godot.GdHlTagsSetup.run ) _ );

      final name = 'new';

      final doConstruct = macro if ( doConstruct ) GdHl.constructBinding( this, $v{ type.name.gds } );

      final body = eBlock( extended.turn( () -> [ doConstructSuper, doConstruct ], () -> [ doConstruct ] ) );

      final field = fFun( name, doConstructArgs, null, { access: access, meta: metas, body: body } );

      definition.fields.push( field );

    }


    // isSingleton


    for ( method in type.methods ) {

      if ( method.isVirtual ) continue; // TODO:

      final docs = docs.methods().iter().find( _ -> _.name() == method.name.gds );

      final doc = docs.map( _ -> _.description() );

      final metas = [ meta( ':hlNative', [ 'gh', method.name.prim ] ) ];

      final access = [ APublic, AStatic ];

      final name = method.name.hx;

      final args = method.signature.map( _ -> arg( _.name.hx, tPath( _.type.name.hx ) ) );

      args[ 0 ] = arg( 'that', tPath( objectType.name.hx ) );

      final type = tPath( method.signature[ 0 ].type.name.hx );

      final body = eThrow( eInt( 8 ) );

      final field = fFun( name, args, type, { doc: doc, meta: metas, access: access, body: body } );

      definition.fields.push( field );

    }


    final definitions = [ definition ];

    if ( isGlobalConstants ) definitions.pop();


    for ( group => constants in docs.constants().iter().key( _ -> _.group() ).filter( _ -> _.key != '' ).toGroups() ) {

      if ( group.contains( '.' ) ) continue;

      final name = ( isGlobalConstants ? '' : type.name.hx ) + group;

      final definition = HaxeTools.makeEnum( name, constants.map( constant -> {

        name: constant.name(),

        value: constant.value(),

        doc: constant.description(),

      } ) );

      definitions.push( definition );

    }


    if ( name == 'Object' ) {

      final types = objectTypes.filter( _ -> _.name.hx != 'GlobalConstants' );

      definitions.push( macro class GdHlTagsSetup {

        public static function run() {

          final constructors = new hl.NativeArray< GdHl.GdHlBindingConstructor >( $v{ types.length } );

          $b{ [ for ( index => type in types ) {

            macro constructors[ $v{ index } ] = new GdHl.GdHlBindingConstructor(

              $v{ type.name.gds },

              () -> $e{ eNew( tyPath( type.name.hx ), [ eBool( false ) ] ) }

            );

          } ] }

          GdHl.bindingSetConstructors( constructors );

        }

      } );

    }


    final haxe = 'package godot;\n\n' + definitions.map( _ -> printer.printTypeDefinition( _ ) ).join( '\n\n' );

    File.saveContent( 'sources/lib/gen/object/godot/${ name }.hx', haxe );

  }

}
