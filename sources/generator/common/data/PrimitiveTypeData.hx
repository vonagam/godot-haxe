package common.data;


class PrimitiveTypeData extends TypeData {

  public function new() {}


  override public function ghReturn( returns: ValueData )

    return name.hx == 'Void' ? '' : '  return gd_return;\n\n';

}


class PrimitiveTypeDataTools {

  public static function getPrimitiveTypes() {

    // TODO: someday use proper things for char, unsigned and 64

    return [

      new PrimitiveTypeData().tap( _ -> {

        _.name.gds = 'void';

        _.name.gdn = 'void';

        _.name.gh = 'void';

        _.name.hx = 'Void';

        _.name.prim = '_VOID';

      } ),

      new PrimitiveTypeData().tap( _ -> {

        _.name.gdn = 'uint8_t';

        _.name.gh = 'uint8_t';

        _.name.hlv = 'ui8';

        _.name.hx = 'hl.UI8';

        _.name.prim = '_I8';

        _.variant = 'uint';

      } ),

      new PrimitiveTypeData().tap( _ -> {

        _.name.gds = 'int';

        _.name.gdn = 'godot_int';

        _.name.gh = 'int';

        _.name.hlv = 'i';

        _.name.hx = 'Int';

        _.name.prim = '_I32';

        _.variant = 'int';

      } ),

      new PrimitiveTypeData().tap( _ -> {

        _.name.gdn = 'uint32_t';

        _.name.gh = 'uint32_t';

        _.name.hlv = 'i';

        _.name.hx = 'UInt';

        _.name.prim = '_I32';

        _.variant = 'uint';

      } ),

      new PrimitiveTypeData().tap( _ -> {

        _.name.gdn = 'int64_t';

        _.name.gh = 'int';

        _.name.hlv = 'i';

        _.name.hx = 'Int';

        _.name.prim = '_I32';

        _.variant = 'int';

      } ),

      new PrimitiveTypeData().tap( _ -> {

        _.name.gdn = 'uint64_t';

        _.name.gh = 'uint32_t';

        _.name.hlv = 'i';

        _.name.hx = 'UInt';

        _.name.prim = '_I32';

        _.variant = 'uint';

      } ),

      new PrimitiveTypeData().tap( _ -> {

        _.name.gds = 'bool';

        _.name.gdn = 'godot_bool';

        _.name.gh = 'bool';

        _.name.hlv = 'b';

        _.name.hx = 'Bool';

        _.name.prim = '_BOOL';

        _.variant = 'bool';

      } ),

      new PrimitiveTypeData().tap( _ -> {

        _.name.gds = 'float';

        _.name.gdn = 'godot_real';

        _.name.gh = 'float';

        _.name.hlv = 'f';

        _.name.hx = 'hl.F32';

        _.name.prim = '_F32';

        _.variant = 'real';

      } ),

      new PrimitiveTypeData().tap( _ -> {

        _.name.gdn = 'double';

        _.name.gh = 'double';

        _.name.hlv = 'd';

        _.name.hx = 'Float';

        _.name.prim = '_F64';

        _.variant = 'real';

      } ),


      new PrimitiveTypeData().tap( _ -> {

        _.name.gdn = 'godot_vector3_axis';

        _.name.gh = 'godot_vector3_axis';

        _.name.hlv = 'i';

        _.name.hx = 'Vector3_Axis';

        _.name.prim = '_I32';

        _.variant = 'int';

      } ),

      new PrimitiveTypeData().tap( _ -> {

        _.name.gdn = 'godot_variant_type';

        _.name.gh = 'godot_variant_type';

        _.name.hlv = 'i';

        _.name.hx = 'Variant_Type';

        _.name.prim = '_I32';

        _.variant = 'int';

      } ),

    ];

  }

}
