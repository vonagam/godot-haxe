package object;

import common.Data;


class ObjectTypeData extends GodotTypeData {

  public var parent: Null< ObjectTypeData > = null;

  public var isInstanciable = false;

  public var isSingleton = false;

  public var properties = new Array< PropertyData >();

  public var signals = new Array< SignalData >();

  public var enums = new Array< EnumData >();


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


@:using( vhx.flow.FlowTools )

class PropertyData {

  var name = new NameData();

  var type: TypeData;

  var getter: Null< MethodData >;

  var setter: Null< MethodData >;

  var index = -1;


  public function new() {}

}


@:using( vhx.flow.FlowTools )

class SignalData {

  var name = new NameData();

  var arguments = new Array< ValueData >();


  public function new() {}

}


@:using( vhx.flow.FlowTools )

class EnumData {

  var name = new NameData();

  var values = new Array< { name: NameData, value: Int } >();


  public function new() {}

}
