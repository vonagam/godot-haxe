package core;

using StringTools;

import haxe.macro.Expr;

import sys.FileSystem;

import sys.io.File;

using vhx.iter.IterTools;

import vhx.macro.ExprTools.*;

import vhx.macro.Printer;

import common.Docs;

import common.Haxe;

import core.Data;

import core.Operator;

import core.Fix;


function writeCoreHaxe( coreTypes: Array< CoreTypeData > ) {

  FileSystem.createDirectory( 'sources/lib/gen/core/godot' );

  final printer = new Printer( '  ' );

  for ( coreType in coreTypes ) {

    final type = coreType;

    final docs = new ClassDocs( type.name.gds );

    final doc = docs.description();

    final name = type.name.hx;

    final real = tPath( 'hl.Abstract', [ eString( type.name.gh ) ] );

    final definition = dAbstract( name, real, [], { doc: doc } );


    for ( docs in docs.members() ) {

      final name = docs.name();

      final getter = type.methods.iter().find( _ -> _.name.gdn == 'get_${ name }' );

      if ( getter == null ) continue;

      final doc = docs.description();

      final setter = type.methods.iter().find( _ -> _.name.gdn == 'set_${ name }' );

      HaxeTools.addMemberFields( definition, name, getter, setter, -1, doc );

    }


    for ( method in type.methods ) {

      final isConstructor = method.name.hx == 'new' || method.name.gdn.startsWith( 'new_' );

      final docs = docs.methods().iter().find( _ -> _.name() == method.name.gdn );

      final doc = docs.map( _ -> _.description() );

      final metas = [ meta( ':hlNative', [ 'gh', method.name.prim ] ) ];

      addOperatorMeta( method, metas );

      final access = [ APublic ];

      if ( isConstructor && method.name.hx != 'new' ) access.push( AStatic );

      final name = method.name.hx;

      final args = method.signature.iter().skip( 2 ).map( _ -> arg( _.name.hx, tPath( _.type.name.hx ) ) ).toArray();

      final type = tPath( method.signature[ isConstructor ? 1 : 0 ].type.name.hx );

      final body = eThrow( eInt( 8 ) );

      final field = fFun( name, args, type, { doc: doc, meta: metas, access: access, body: body } );

      definition.fields.push( field );

    }


    final definitions = [ definition ];

    fixHaxe( coreType, definitions );


    final haxe = 'package godot;\n\n' + definitions.map( _ -> printer.printTypeDefinition( _ ) ).join( '\n\n' );

    File.saveContent( 'sources/lib/gen/core/godot/${ name }.hx', haxe );

  }

}
