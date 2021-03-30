package core;

using StringTools;

import haxe.macro.Expr;

import sys.FileSystem;

using vhx.str.StringTools;

import vhx.macro.ExprTools.*;

import common.data.*;

using common.HaxeTools;

import core.Operator;

import core.Fix;


function writeCoreHaxe( coreTypes: Array< CoreTypeData > ) {

  FileSystem.createDirectory( 'sources/lib/sources/gd' );

  for ( type in coreTypes ) {

    final definition = dAbstract( {

      doc: type.doc,

      name: type.name.hx,

      type: tPath( 'hl.Abstract', [ eString( type.name.gh ) ] ),

    } );


    for ( property in type.properties ) {

      property.defineIn( definition );

    }


    for ( method in type.methods ) {

      final doc = method.doc;

      final metas = method.metas();

      addOperatorMeta( method, metas );

      final isConstructor = method.isConstructor();

      final access = [ APublic ];

      if ( isConstructor && method.name.hx != 'new' ) access.push( AStatic );

      final name = method.name.hx;

      final args = method.signature.iter().skip( 2 ).map( _ -> _.hxArg() ).toArray();

      final type = tPath( method.signature[ isConstructor ? 1 : 0 ].type.name.hx );

      final body = eThrow( eInt( 8 ) );

      final field = fFun( name, args, type, { doc: doc, meta: metas, access: access, body: body } );

      definition.fields.push( field );

    }


    fixHaxe( type, definition );

    definition.output();

    for ( data in type.enums ) data.toDefinition().output();

  }

}
