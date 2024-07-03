extends Node2D
class_name Star

@export var self_mass = 50000

func getBigG():
	return get_parent().bigG
	
func logMsg(msg,clear_first=false,tab='star'):
	get_parent().logMsg(msg,clear_first,tab)

func updateUI(data):
	get_parent().updateUI(data)

var POINT_COUNT = 60
func _draw():
	logMsg(' ',true)
