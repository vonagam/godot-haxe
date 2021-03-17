package object;

import sys.FileSystem;

import sys.io.File;

import common.Data;

import common.Code;

using common.Code.CodeTools;

import object.Data;


function writeObjectCode( objectTypes: Array< ObjectTypeData > ) {

  FileSystem.createDirectory( 'sources/c/gen' );

  final cCode = new Code();

  cCode << '#include "../macros.h"\n\n';

  cCode << '#include "./core.h"\n\n';

  cCode << '\n';

  final that = new ValueData().tap( _ -> { _.name.gh = 'that'; _.isPointer = true; } );

  final thated = [ that ];

  for ( type in objectTypes ) {

    that.type = type;

    cCode << '// ${ type.name.hx }\n\n';

    for ( method in type.methods ) {

      final returns = method.signature[ 0 ];

      final arguments = method.signature.slice( 1 );

      final thated = thated.concat( arguments );

      cCode << CodeTools.ghSignature( returns, method, thated );

      if ( returns.type.name.gdn != 'void' ) {

        cCode << '  ${ returns.type.name.gdn }${ returns.type.name.gdn == 'godot_object' ? '*' : '' } gd_return;\n\n';

      }

      if ( arguments.length > 0 ) {

        cCode << '  const void *args[] = { ${ arguments.map( _ ->

          '${ _.type.isPointer ? '' : '&' }${ _.name.gh }${ _.type.unwrap }'

        ).join( ', ' ) } };\n\n';

      }

      cCode << '  STATIC_METHOD_BIND( bind, ${ type.name.gds }, ${ method.name.gds } )\n\n';

      cCode << '  gdnative_core->godot_method_bind_ptrcall( bind, that->data->owner, ';

      cCode << '${ arguments.length == 0 ? 'NULL' : 'args' }, ';

      cCode << '${ returns.type.name.gdn == 'void' ? 'NULL' : '&gd_return' } );\n\n';

      cCode << returns.type.ghReturn( returns );

      cCode << '}\n\n';

      cCode << CodeTools.primSignature( returns, method, thated );

      cCode << '\n';

    }

  }

  File.saveContent( 'sources/c/gen/object.c', cCode );

}
