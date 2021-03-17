#include <hl.h>

#include "./core_wrapper.h"

#include "./gdnative.h"


// free core wrapper (used as hl_finalize)

static void gh_core_wrapper_free( gh_core_wrapper *wrapper ) {

  if ( wrapper->value == NULL ) return;

  wrapper->gd_finalize( wrapper->value );

  gdnative_core->godot_free( wrapper->value );

}

// allocate core wrapper

gh_core_wrapper *gh_core_wrapper_alloc( int size, void *gd_finalize ) {

  gh_core_wrapper *wrapper = hl_gc_alloc_finalizer( sizeof( void * ) * 3 );

  wrapper->hl_finalize = &gh_core_wrapper_free;

  wrapper->gd_finalize = gd_finalize;

  wrapper->value = gdnative_core->godot_alloc( size );

  return wrapper;

}
