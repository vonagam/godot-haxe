package common;


@:using( vhx.flow.FlowTools )

class NameData {

  public var gds = '';

  public var gdn = '';

  public var c = '';

  public var gh = '';

  public var hx = '';

  public var prim = '';

  public var op = '';


  public function new() {}

}


@:using( vhx.flow.FlowTools )

class TypeData {

  public var name = new NameData();

  public var isPointer = false;

  public var unwrap = '';


  public function ghReturn( returns: ValueData )

    return '';

}


class PrimitiveTypeData extends TypeData {

  public function new() {}


  override public function ghReturn( returns: ValueData )

    return name.hx == 'Void' ? '' : '  return gd_return;\n\n';

}


class GodotTypeData extends TypeData {

  public var methods = new Array< MethodData >();


  public function new() {

    isPointer = true;

  }

}


@:using( vhx.flow.FlowTools )

class ValueData {

  public var name = new NameData();

  public var type: TypeData;

  public var isPointer = false;


  public function new() {}

}


@:using( vhx.flow.FlowTools )

class MethodData {

  public var name = new NameData();

  public var isVirtual = false;

  public var signature = new Array< ValueData >();

  public var callee = '';


  public function new() {}

}
