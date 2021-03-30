package core;

using StringTools;

import sys.FileSystem;

import common.data.*;

import common.Code;


function writeCoreCode( coreTypes: Array< CoreTypeData > ) {

  FileSystem.createDirectory( 'sources/c/gen' );


  final hCode = new Code();

  hCode << '#ifndef GH_GEN_CORE_H\n';

  hCode << '#define GH_GEN_CORE_H\n\n';

  hCode << '#include <hl.h>\n\n';

  hCode << '#include "../gdnative.h"\n\n';

  hCode << '#include "../core_wrapper.h"\n\n';

  hCode << '#include "../object.h"\n\n';

  hCode << '\n';

  for ( type in coreTypes ) hCode << 'typedef ${ type.name.c } ${ type.name.gh };\n\n';

  hCode << '\n';

  for ( type in coreTypes ) hCode << '#define ${ type.name.prim } _ABSTRACT( ${ type.name.gh } )\n\n';

  hCode << '\n';


  final cCode = new Code();

  cCode << '#include "../macros.h"\n\n';

  cCode << '#include "./core.h"\n\n';

  cCode << '\n';

  for ( type in coreTypes ) {

    cCode << '// ${ type.name.hx }\n\n';

    for ( method in type.methods ) {

      final isConstructor = method.isConstructor();

      final returns = method.signature[ isConstructor ? 1 : 0 ];

      final arguments = method.signature.slice( isConstructor ? 2 : 1 );

      cCode << method.cSignature( returns, arguments );

      final call = '${ method.callee }( ${ method.signature.iter().skip( 1 ).map( _ -> _.ghUnwrap() ).join( ', ' ) } )';

      if ( isConstructor ) {

        hCode << method.hSignature( returns, arguments );

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

      cCode << method.primSignature( returns, arguments );

      cCode << '\n';

    }

  }


  hCode << '#endif\n';

  hCode >> 'core.h';

  cCode >> 'core.c';

}
