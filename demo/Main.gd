extends Node2D


func _ready():

  print( $node.hello( 3.2 ) )

  # $timer.connect( 'timeout', $node, 'hello' )
