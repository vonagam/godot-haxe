#include "./defaults.h"

#include "./gdnative.h"


varray *gh_defaults = NULL;


void gh_defaults_free() {

  hl_remove_root( &gh_defaults );

  gh_defaults = NULL;

}
