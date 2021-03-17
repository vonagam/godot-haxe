package core;

using StringTools;

using vhx.str.StringTools;

using vhx.iter.IterTools;

import vhx.macro.ExprTools;

import vhx.macro.ExprTools.*;

import common.Data;


private final operators = [

  'equal' => { expr: macro _ == _, rename: 'is_equal' },

  'less' => { expr: macro _ < _, rename: 'is_less' },

  'index' => { expr: macro [], rename: 'get_index' },

  'add' => { expr: macro _ + _, rename: 'do_add' },

  'plus' => { expr: macro _ + _, rename: 'do_add' },

  'subtract' => { expr: macro _ - _, rename: 'do_subtract' },

  'multiply' => { expr: macro _ * _, rename: 'do_multiply' },

  'divide' => { expr: macro _ / _, rename: 'do_divide' },

  'neg' => { expr: macro ! _, rename: 'get_neg' },

];


function changeOperatorName( method: MethodData ) {

  if ( ! method.name.gdn.startsWith( 'operator_' ) ) return;

  final found = operators.iterEntries().find( _ -> method.name.gdn.startsWith( 'operator_' + _.key ) );

  if ( found.isNull ) throw new haxe.Exception( 'Unknown operator method ${ method.name.gdn }.' );

  final op = found!;

  method.name.op = op.key;

  method.name.hx = method.name.gdn.replace( 'operator_' + op.key, op.value.rename ).toCamelCase();

  method.name.prim = method.name.prim.replace( 'operator_' + op.key, op.value.rename );

}

function addOperatorMeta( method: MethodData, metas: ToMetadata ) {

  if ( method.name.op == '' ) return;

  metas.push( meta( ':op', [ operators[ method.name.op ].expr ] ) );

}
