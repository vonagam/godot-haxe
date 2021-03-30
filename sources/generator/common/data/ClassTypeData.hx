package common.data;


class ClassTypeData extends TypeData {

  public var properties = new Array< PropertyData >();

  public var methods = new Array< MethodData >();

  public var enums = new Array< EnumData >();

  public var doc: Null< String >;

  // TODO: constants


  public function new() {

    isPointer = true;

  }

}
