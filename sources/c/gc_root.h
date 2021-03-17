#ifndef GH_GC_ROOT_H
#define GH_GC_ROOT_H


typedef void ** gh_gc_root;

gh_gc_root gh_gc_root_alloc( void *value );

void gh_gc_root_free( gh_gc_root root );


#endif
