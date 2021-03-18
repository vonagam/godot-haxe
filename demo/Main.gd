extends Node2D


func _ready():

  print( $node.hello( 3.2 ) )

  print( $node.prop )

  $node.prop = 44

  print( $node.prop )

  # $timer.connect( 'timeout', $node, 'hello' )
