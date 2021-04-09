import core.Get;

import objects.Get;

import core.Code;

import objects.Code;

import core.Haxe;

import objects.Haxe;


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
