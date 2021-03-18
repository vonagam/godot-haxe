all: hdll demo


hdll: outputs/gh.hdll

outputs/gh.hdll: $(shell find sources/c -name "*.c") sources/c/gen/core.c Sconstruct inputs

	@mkdir -p outputs

	@scons

	@touch $@

#

sources/c/gen/core.c: $(shell find sources/generator -name "*.hx") sources/generator/run.hxml inputs

	@make generate

#

generate:

	@cd sources/generator && haxe run.hxml

#


define check_env

	@test ${$1} || ( echo "$1 is not set"; exit 1 )

endef

demo_edit: demo; $(call check_env,GODOT_BIN) @cd demo && ${GODOT_BIN} --editor

demo_run: demo; $(call check_env,GODOT_BIN) @cd demo && ${GODOT_BIN}

demo: demo/libhl.dylib demo/gh.hdll demo/hlboot.dat

demo/libhl.dylib: inputs/hashlink/libhl.dylib ; @cp $< $@

demo/gh.hdll: outputs/gh.hdll ; @cp $< $@

demo/hlboot.dat: $(shell find sources/lib -name "*.hx") $(shell find demo -name "*.hx") demo/build.hxml

	@cd demo && haxe build.hxml

#


define clone_git

  @mkdir -p $1

  @cd $1 && git init

  @cd $1 && git remote add origin git@github.com:$2.git

	@cd $1 && git fetch --depth 1 origin $(if $3,$3,master)

  @cd $1 && git checkout FETCH_HEAD

endef

inputs: inputs/hashlink inputs/godot inputs/godot_headers inputs/hashlink/libhl.dylib

inputs/godot_headers: ; $(call clone_git,$@,godotengine/godot_headers,3.2)

inputs/godot: ; $(call clone_git,$@,godotengine/godot,3.2)

inputs/hashlink: ; $(call clone_git,$@,HaxeFoundation/hashlink)

inputs/hashlink/libhl.dylib:

	$(error hashlink in inputs folder needs to be compiled, instructions can be found in its readme)

#


clean:

	@rm -rf outputs

	@rm -rf sources/c/gen

	@rm -rf sources/lib/gen

	@rm -f demo/gh.hdll demo/hlboot.dat

#

reset: clean

	@rm -rf inputs

	@rm -f demo/libhl.dylib

#


.PHONY: all hdll generate demo_edit demo_run clean reset
