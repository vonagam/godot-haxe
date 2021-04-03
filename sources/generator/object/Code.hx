package object;

import sys.FileSystem;

import common.data.*;

import common.Code;


function writeObjectCode( objectTypes: Array< ObjectTypeData > ) {

  FileSystem.createDirectory( 'sources/c/gen' );

  final cCode = new Code();

  cCode << '#include "../macros.h"\n\n';

  cCode << '#include "./core.h"\n\n';

  cCode << '#include "../defaults.h"\n\n';

  cCode << '\n';


  final defaults = ConstantData.collectDefaults( objectTypes );

  cCode << ConstantData.cDefaultsInit( defaults );


  final that = new ValueData().tap( _ -> { _.name.gh = 'that'; _.isPointer = true; } );

  final thated = [ that ];

  for ( type in objectTypes ) {

    that.type = type;

    cCode << '// ${ type.name.hx }\n\n';

    for ( method in type.methods ) {

      final returns = method.signature[ 0 ];

      final arguments = method.signature.slice( 1 );

      final thated = thated.concat( arguments );

      cCode << method.cSignature( returns, thated );

      for ( argument in arguments ) {

        cCode << argument.defaults.cDefaultsUse( argument );

      }

      if ( returns.type.name.gdn != 'void' ) {

        cCode << '  ${ returns.type.name.gdn }${ returns.type.name.gdn == 'godot_object' ? '*' : '' } gd_return;';

        cCode << ' memset( &gd_return, 0, sizeof( gd_return ) );\n\n'; // TODO: godot... issues/34264

      }

      if ( arguments.length > 0 ) {

        cCode << '  const void *args[] = { ${

          arguments.map( _ -> {

            final arg = '${ _.type.isPointer ? '' : '&' }${ _.name.gh }${ _.type.unwrap }';

            if ( _.defaults != null && _.defaults.value == 'null' && _.type.unwrap != '' ) {

              return '${ _.name.gh } == NULL ? NULL : ${ arg }';

            }

            return arg;

          } ).join( ', ' )

        } };\n\n';

      }

      cCode << '  STATIC_METHOD_BIND( bind, ${ type.name.gds }, ${ method.name.gds } )\n\n';

      cCode << '  gdnative_core->godot_method_bind_ptrcall( bind, that->data->owner, ';

      cCode << '${ arguments.length == 0 ? 'NULL' : 'args' }, ';

      cCode << '${ returns.type.name.gdn == 'void' ? 'NULL' : '&gd_return' } );\n\n';

      cCode << returns.type.ghReturn( returns );

      cCode << '}\n\n';

      cCode << method.primSignature( returns, thated );

      cCode << '\n';

    }

    for ( constant in type.constants ) {

      cCode << constant.cGetter( type );

    }

  }

  cCode >> 'object.c';

}
