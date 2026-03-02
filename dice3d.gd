class_name Dice3D extends RigidBody3D

@export var stopthres_lin: float = 0.1
@export var stopthres_ang: float = 0.1
@export var time_to_rolldone: float = 1
@onready var col: CollisionShape3D = $CollisionShape3D
@onready var shape: MeshInstance3D = $MeshInstance3D
@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var stopthres_lin2 = stopthres_lin * stopthres_lin
@onready var stopthres_ang2 = stopthres_ang * stopthres_ang
var dragging: bool = false
var last_drag_pos: Vector3 = Vector3.ZERO
var drag_local_pos: Vector3 = Vector3.ZERO
var rolldone_timer: float = 0.0

signal rolldone(dice: Dice3D)
signal rollreset(dice: Dice3D)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	col.shape = shape.mesh.create_convex_shape()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not dragging and linear_velocity.length_squared() < stopthres_lin2 and angular_velocity.length_squared() < stopthres_ang2:
		if rolldone_timer < time_to_rolldone and rolldone_timer + delta >= time_to_rolldone:
			rolldone.emit(self)
		rolldone_timer += delta
	else:
		if rolldone_timer != 0:
			rollreset.emit(self)
		rolldone_timer = 0


func _physics_process(delta: float) -> void:
	if not dragging:
		return
	var hover_pos: Vector3 = last_drag_pos
	hover_pos.y = 3
	apply_force(2*(hover_pos - position)/delta, transform * drag_local_pos - position)
	linear_velocity *= pow(0.75, 60*delta);
	angular_velocity *= pow(0.75, 60*delta);
	

func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		last_drag_pos = event_position
		if event.pressed:
			drag_local_pos = global_transform.inverse() * event_position

	if event is InputEventMouseMotion:
		last_drag_pos = event_position

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT and dragging:
		dragging = false
	
