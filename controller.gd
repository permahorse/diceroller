extends Node3D

@onready var control_root = $"Control"

@export var d20: PackedScene
@export var d12: PackedScene
@export var d8: PackedScene
@export var d6: PackedScene
@export var d4: PackedScene


var dice: Array[Node3D] = []


func _ready() -> void:
	_add_die(0)
	

func _add_die(index: int):
	print('adding die %s' % index)
	var die: Node3D
	if index == 0:
		die = d20.instantiate()
	elif index == 1:
		die = d12.instantiate()
	elif index == 2:
		die = d8.instantiate()
	elif index == 3:
		die = d6.instantiate()
	elif index == 4:
		die = d4.instantiate()
	else:
		return
	die.position = Vector3(0, 10, 0)
	self.add_child(die)
	dice.append(die)
	die.connect('picked', _die_picked)
	die.connect('released', _die_released)

func clear():
	for die in dice:
		die.queue_free()
	dice.clear()


func _die_picked():
	control_root.visible = false
	
	
func _die_released():
	control_root.visible = true
