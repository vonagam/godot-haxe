#ifndef GH_CORE_WRAPPER_H
#define GH_CORE_WRAPPER_H


// wrapper for godot'c core types with finalizers

typedef struct gh_core_wrapper {

  void ( *hl_finalize )( struct gh_core_wrapper * ); // adapter, simply passes value to gd_finalize

  void ( *gd_finalize )( void * );

  void *value;

} gh_core_wrapper;

gh_core_wrapper *gh_core_wrapper_alloc( int size, void *finalizer );


#endif
