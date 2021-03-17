package core;

using StringTools;

import sys.FileSystem;

import sys.io.File;

using vhx.iter.IterTools;

import common.Code;

using common.Code.CodeTools;

import core.Data;


function writeCoreCode( coreTypes: Array< CoreTypeData > ) {

  FileSystem.createDirectory( 'sources/c/gen' );


  final hCode = new Code();

  hCode << '#ifndef GODOT_HL_GEN_CORE\n';

  hCode << '#define GODOT_HL_GEN_CORE\n\n';

  hCode << '#include <hl.h>\n\n';

  hCode << '#include "../gdnative.h"\n\n';

  hCode << '#include "../core_wrapper.h"\n\n';

  hCode << '#include "../object.h"\n\n';

  hCode << '\n';

  for ( type in coreTypes ) hCode << 'typedef ${ type.name.c } ${ type.name.gh };\n\n';

  hCode << '\n';

  for ( type in coreTypes ) hCode << '#define ${ type.name.prim } _ABSTRACT( ${ type.name.gh } )\n\n';

  hCode << '\n';

  hCode << '#endif\n';

  File.saveContent( 'sources/c/gen/core.h', hCode );


  final cCode = new Code();

  cCode << '#include "../macros.h"\n\n';

  cCode << '#include "./core.h"\n\n';

  cCode << '\n';

  for ( type in coreTypes ) {

    cCode << '// ${ type.name.hx }\n\n';

    for ( method in type.methods ) {

      final isConstructor = method.name.hx == 'new' || method.name.gdn.startsWith( 'new_' );

      final returns = method.signature[ isConstructor ? 1 : 0 ];

      final arguments = method.signature.slice( isConstructor ? 2 : 1 );

      cCode << CodeTools.ghSignature( returns, method, arguments );

      final call = '${ method.callee }( ${ method.signature.iter().skip( 1 ).map( _ -> _.ghUnwrap() ).join( ', ' ) } )';

      if ( isConstructor ) {

        cCode << '  ${ returns.ghVariable() } = ${ cast( returns.type, CoreTypeData ).allocate };\n\n';

        cCode << '  ${ call };\n\n';

        cCode << '  return ${ returns.name.gh };\n\n';

      } else if ( returns.isPointer == returns.type.isPointer && returns.type.unwrap == '' ) {

        cCode << '  ${ returns.type.name.gh == 'void' ? '' : 'return ' }${ call };\n\n';

      } else {

        cCode << '  ${ returns.gdnType() }gd_return = ${ call };\n\n';

        cCode << returns.type.ghReturn( returns );

      }

      cCode << '}\n\n';

      cCode << CodeTools.primSignature( returns, method, arguments );

      cCode << '\n';

    }

  }

  File.saveContent( 'sources/c/gen/core.c', cCode );

}
