import common.Get;

import core.Get;

import object.Get;

import core.Code;

import core.Haxe;

import object.Code;

import object.Haxe;


function main() {

  Sys.setCwd( '../../' );

  final primitiveTypes = getPrimitiveTypes();

  final objectType = getObjectType();

  final coreTypes = getCoreTypes( primitiveTypes, objectType );

  final objectTypes = getObjectTypes( primitiveTypes, objectType, coreTypes );

  writeCoreCode( coreTypes );

  writeCoreHaxe( coreTypes );

  writeObjectCode( objectTypes );

  writeObjectHaxe( objectTypes );

}
