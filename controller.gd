extends Node3D

@onready var control_root = $"Control"

@export var d20: PackedScene


func _ready() -> void:
	_add_die(0)
	

func _add_die(index: int):
	print('adding die %s' % index)
	if index == 0:
		var die: Node3D = d20.instantiate()
		die.position = Vector3(0, 10, 0)
		self.add_child(die)
		die.connect('picked', _die_picked)
		die.connect('released', _die_released)


func _die_picked():
	control_root.visible = false
	
	
func _die_released():
	control_root.visible = true
