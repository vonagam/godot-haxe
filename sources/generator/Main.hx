import core.Get;

import object.Get;

import core.Code;

import object.Code;

import core.Haxe;

import object.Haxe;


function main() {

  Sys.setCwd( '../../' );

  final primitiveTypes = common.data.PrimitiveTypeData.PrimitiveTypeDataTools.getPrimitiveTypes();

  final objectType = common.data.ObjectTypeData.ObjectTypeDataTools.getObjectType();

  final coreTypes = getCoreTypes( primitiveTypes, objectType );

  final objectTypes = getObjectTypes( primitiveTypes, objectType, coreTypes );

  writeCoreCode( coreTypes );

  writeCoreHaxe( coreTypes );

  writeObjectCode( objectTypes );

  writeObjectHaxe( objectTypes );

}
