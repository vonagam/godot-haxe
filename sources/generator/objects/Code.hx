package objects;

import sys.FileSystem;

using vhx.str.StringTools;

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

      final isVoid = returns.type.name.gdn == 'void';

      final hasArgs = arguments.length > 0;

      cCode << method.cSignature( returns, thated );

      cCode << '  STATIC_METHOD_BIND( bind, ${ type.name.gds }, ${ method.name.gds } )\n\n';

      for ( argument in arguments ) {

        cCode << argument.defaults.cDefaultsUse( argument );

      }

      if ( method.hasVarArg ) {

        final length = arguments.length;

        cCode << '  int size = ${ length } + p_args->size;\n\n';

        cCode << '  godot_variant **args = gdnative_core->godot_alloc( sizeof( godot_variant * ) * size );\n\n';

        if ( hasArgs ) {

          cCode << '  godot_variant named_args[ ${ length } ];\n\n';

          for ( index => argument in arguments ) {

            cCode << '  gdnative_core->godot_variant_new_${ argument.type.variant }( &named_args[ ${ index } ], ${ argument.name.gh }${ argument.type.unwrap } );\n\n';

          }

          cCode << '  for ( int i = 0; i < ${ length }; i++ ) args[ i ] = &named_args[ i ];\n\n';

        }

        cCode << '  for ( int i = 0; i < p_args->size; i++ ) args[ ${ length } + i ] = hl_aptr( p_args, gh_godot_variant * )[ i ]->value;\n\n';

        cCode << ( isVoid ? '  ' : '  ${ returns.gdnType() }gd_return = ' );

        cCode << 'gdnative_core->godot_method_bind_call( bind, that->data->owner, ( const godot_variant ** ) args, size, NULL );\n\n';

        if ( hasArgs ) {

          cCode << '  for ( int i = 0; i < ${ length }; i++ ) gdnative_core->godot_variant_destroy( args[ i ] );\n\n';

        }

        cCode << '  gdnative_core->godot_free( args );\n\n';

      } else {

        if ( ! isVoid ) {

          cCode << '  ${ returns.type.name.gdn } ${ returns.type.name.gdn == 'godot_object' ? '*' : '' }gd_return;';

          cCode << ' memset( &gd_return, 0, sizeof( gd_return ) );\n\n'; // TODO: godot... issues/34264

        }

        if ( hasArgs ) {

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

        cCode << '  gdnative_core->godot_method_bind_ptrcall( bind, that->data->owner, ';

        cCode << '${ hasArgs ? 'args' : 'NULL' }, ';

        cCode << '${ isVoid ? 'NULL' : '&gd_return' } );\n\n';

      }

      cCode << returns.type.ghReturn( returns );

      cCode << '}\n\n';

      cCode << method.primSignature( returns, thated );

      cCode << '\n';

    }

    for ( constant in type.constants ) {

      cCode << constant.cGetter( type );

    }

  }

  cCode >> 'objects.c';

}
