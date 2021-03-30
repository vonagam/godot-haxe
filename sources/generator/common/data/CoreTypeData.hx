package common.data;


class CoreTypeData extends ClassTypeData {

  public var index: Int;

  public var allocate: String;


  public function new() { super(); }


  override public function ghReturn( returns: ValueData ) {

    return (

      '  ${ name.gh } *hl_return = ${ allocate };\n\n' +

      '  memcpy( hl_return${ unwrap }, ${ returns.isPointer ? '' : '&' }gd_return, sizeof( ${ name.gdn } ) );\n\n' +

      '  return hl_return;\n\n'

    );

  }

}
