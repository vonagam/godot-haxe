# godot-haxe

# About

This is a not-quite-working-yet integration of hashlink into godot.

This code is published to at least be a potential reference to somebody who may want to write the bindings themselves.

Three directions of work still needed:

1) Fix gc errors on library reload: Godot reloads library (terminates and initializes it again) quire often (for example on each focus of its editor) and seems like there is something in garbage collector code of hashlink that is not being cleaned up after termination that causes an exception (from this [line](https://github.com/HaxeFoundation/hashlink/blob/c2786410a0fc525edda88b266fee1158efc38f44/src/allocator.c#L203)).

2) Add haxe macros (for registering things mainly). I was focusing on c and generator parts until this point.

3) Signals things: registering, subscribing (with lambdas), triggering, waiting.

# Setup

Install `vhx` library in `sources/generator` folder. Get the code from [here](https://github.com/vonagam/vhx).

Then to build everything run `make`.

It will download some github repos into `inputs` folder and after first invocation should error saying that you need to compile hashlink located in `inputs/hashlink`.

After compiling hashlink run `make` again (it should not error after that).

To run editor or only a scene - `make demo_edit` and `make demo_run`. (It requires `GODOT_BIN` to be set.)

I am working on osx, so don't know if there are some problems with current workflow on windows or linux. If there are let me know. (`demo/gh.gdnlib` will need entries for those systems to work.)

# Info

Source code is divided into 3 parts:

- `sources/c` contains c code.

- `sources/generator` contains generator code that after running will produce glue code based on godot api into `sources/c/gen` and `sources/lib/gen`.

- `sources/lib` contains haxe code, right now there is not much there, but there in idea should be located code that will make integration more pleasant (various macros).

There is also `demo` folder, which is not actually a demo yet, but simply a simples project to test that things are working while developing.
