package common.data;


class ObjectTypeData extends ClassTypeData {

  public var parent: Null< ObjectTypeData > = null;

  public var isInstanciable = false;

  public var isSingleton = false;

  public var signals = new Array< SignalData >();


  public function new() {

    super();

    name.gdn = 'godot_object';

    name.gh = 'gh_object';

    name.prim = '_GH_OBJECT';

    unwrap = '->data->owner';

  }


  override public function ghReturn( returns: ValueData ) {

    return '  return gh_object_get( gd_return );\n\n';

  }

}


class ObjectTypeDataTools {

  public static function getObjectType() {

    return new ObjectTypeData().tap( _ -> {

      _.name.gdn = 'godot_object';

      _.name.gds = 'Object';

      _.name.hx = 'Object';

      _.isInstanciable = true;

    } );

  }

}
