package common;

import common.Data;


function getPrimitiveTypes(): Array< PrimitiveTypeData > {

  // TODO: what is proper unsigned of: char, uint8_t, uint32_t, uint64_t ???

  final types = new Array< PrimitiveTypeData >();


  types.push( new PrimitiveTypeData().tap( ( data ) -> {

    data.name.gds = 'void';

    data.name.gdn = 'void';

    data.name.gh = 'void';

    data.name.hx = 'Void';

    data.name.prim = '_VOID';

  } ) );

  types.push( new PrimitiveTypeData().tap( ( data ) -> {

    data.name.gdn = 'uint8_t';

    data.name.gh = 'uint8_t';

    data.name.hx = 'hl.UI8';

    data.name.prim = '_I8';

  } ) );

  types.push( new PrimitiveTypeData().tap( ( data ) -> {

    data.name.gds = 'int';

    data.name.gdn = 'godot_int';

    data.name.gh = 'int';

    data.name.hx = 'Int';

    data.name.prim = '_I32';

  } ) );

  types.push( new PrimitiveTypeData().tap( ( data ) -> {

    data.name.gdn = 'uint32_t';

    data.name.gh = 'int64_t';

    data.name.hx = 'hl.I64';

    data.name.prim = '_I64';

  } ) );

  types.push( new PrimitiveTypeData().tap( ( data ) -> {

    data.name.gdn = 'int64_t';

    data.name.gh = 'int64_t';

    data.name.hx = 'hl.I64';

    data.name.prim = '_I64';

  } ) );

  types.push( new PrimitiveTypeData().tap( ( data ) -> {

    data.name.gdn = 'uint64_t';

    data.name.gh = 'int64_t';

    data.name.hx = 'hl.I64';

    data.name.prim = '_I64';

  } ) );

  types.push( new PrimitiveTypeData().tap( ( data ) -> {

    data.name.gds = 'bool';

    data.name.gdn = 'godot_bool';

    data.name.gh = 'bool';

    data.name.hx = 'Bool';

    data.name.prim = '_BOOL';

  } ) );

  types.push( new PrimitiveTypeData().tap( ( data ) -> {

    data.name.gds = 'float';

    data.name.gdn = 'godot_real';

    data.name.gh = 'float';

    data.name.hx = 'hl.F32';

    data.name.prim = '_F32';

  } ) );

  types.push( new PrimitiveTypeData().tap( ( data ) -> {

    data.name.gdn = 'double';

    data.name.gh = 'double';

    data.name.hx = 'Float';

    data.name.prim = '_F64';

  } ) );


  types.push( new PrimitiveTypeData().tap( ( data ) -> {

    data.name.gdn = 'godot_vector3_axis';

    data.name.gh = 'godot_vector3_axis';

    data.name.hx = 'godot.Vector3.Axis';

    data.name.prim = '_I32';

  } ) );

  types.push( new PrimitiveTypeData().tap( ( data ) -> {

    data.name.gdn = 'godot_variant_type';

    data.name.gh = 'godot_variant_type';

    data.name.hx = 'godot.Variant.Type';

    data.name.prim = '_I32';

  } ) );


  return types;

}
