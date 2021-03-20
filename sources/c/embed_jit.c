#include <main.c>

#include "./embed_jit.h"


// main from hashlink's main.c splitted into three parts


main_context ctx;

enum {

  nothing_done,

  global_init_done,

  register_thread_done,

  load_code_done,

  module_alloc_done,

  module_init_done,

  code_free_done,

  call_done,

} stage = nothing_done;


// prepare

void gh_embed_jit_init() {

  stage = nothing_done;


  hl_global_init();

  stage = global_init_done;


  hl_register_thread( &ctx );

  stage = register_thread_done;


  pchar *file = PSTR( "hlboot.dat" );

  hl_sys_init( NULL, 0, file );

  char *error_msg = NULL;

  ctx.file = file;

  ctx.code = load_code( file, &error_msg, true );

  if ( error_msg ) printf( "%s\n", error_msg );

  if ( ! ctx.code ) { gh_embed_jit_free(); return; }

  stage = load_code_done;


  ctx.m = hl_module_alloc( ctx.code );

  if ( ! ctx.m ) { gh_embed_jit_free(); return; }

  stage = module_alloc_done;


  int status = hl_module_init( ctx.m, false );

  if ( ! status ) { gh_embed_jit_free(); return; }

  stage = module_init_done;


  hl_code_free( ctx.code );

  stage = code_free_done;

}


// start

void gh_embed_jit_main() {

  if ( stage != code_free_done ) return;


  vclosure cl;

  cl.t = ctx.code->functions[ ctx.m->functions_indexes[ ctx.m->code->entrypoint ] ].type;

  cl.fun = ctx.m->functions_ptrs[ ctx.m->code->entrypoint ];

  cl.hasValue = 0;


  bool isExc = false;

  ctx.ret = hl_dyn_call_safe( &cl, NULL, 0, &isExc );

  stage = call_done;


  if ( isExc ) {

    varray *a = hl_exception_stack();

    uprintf( USTR( "Uncaught exception: %s\n" ), hl_to_string( ctx.ret ) );

    for ( int i = 0; i < a->size; i++ ) {

      uprintf( USTR( "Called from %s\n" ), hl_aptr( a, uchar* )[ i ] );

    }

    gh_embed_jit_free();

  }

}


// free

void gh_embed_jit_free() {

  if ( stage < code_free_done && stage >= load_code_done ) hl_code_free( ctx.code );

  if ( stage >= module_alloc_done ) hl_module_free( ctx.m );

  if ( stage >= load_code_done ) hl_free( &ctx.code->alloc );

  if ( stage >= register_thread_done ) hl_unregister_thread();

  if ( stage >= global_init_done ) hl_global_free();

  if ( stage >= global_init_done ) hl_gc_major(); // to free memory on godot side too by invoking finalizers

  stage = nothing_done;

}
