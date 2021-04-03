package common.data;


class ClassTypeData extends TypeData {

  public var properties = new Array< PropertyData >();

  public var constants = new Array< ConstantData >();

  public var methods = new Array< MethodData >();

  public var enums = new Array< EnumData >();

  public var doc: Null< String >;


  public function new() {

    isPointer = true;

  }

}
