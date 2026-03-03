class_name Dice3D extends RigidBody3D

signal picked()
signal released()

@export var stopthres_lin: float = 0.1
@export var stopthres_ang: float = 0.1
@export var time_to_rolldone: float = 1
@export var hover_height: float = 6
@export var release_spin_kick_amp: float = 10;

@onready var col: CollisionShape3D = $CollisionShape3D
@onready var shape: MeshInstance3D = $MeshInstance3D
@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var stopthres_lin2 = stopthres_lin * stopthres_lin
@onready var stopthres_ang2 = stopthres_ang * stopthres_ang

var dragging: bool = false
var last_drag_pos: Vector3 = Vector3.ZERO
var last_drag_orig: Vector3 = Vector3.ZERO
var last_drag_step: Vector3 = Vector3.ZERO
var drag_local_pos: Vector3 = Vector3.ZERO
var rolldone_timer: float = 0.0
var dragging_dice: Array[Dice3D] = []
var dragging_dice_rid: Array[RID] = []
var dragging_dice_pos: Array[Vector3] = []

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
	var hover_pos: Vector3 = (last_drag_pos - last_drag_orig) * ((last_drag_orig.y - hover_height)/(last_drag_orig.y-last_drag_pos.y)) + last_drag_orig
	apply_force(2*(hover_pos - position)/delta, transform * drag_local_pos - position)
	linear_velocity *= pow(0.75, 60*delta);
	angular_velocity *= pow(0.75, 60*delta);
	

func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int, main: bool = true, nonmain_sample_pos: Vector3 = Vector3.ZERO) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed\
			or not main and not dragging and event is InputEventMouse and event.button_mask & MOUSE_BUTTON_LEFT:
		dragging = true
		last_drag_pos = event_position
		last_drag_orig = camera.position
		last_drag_step = Vector3.ZERO
		if main:
			drag_local_pos = global_transform.inverse() * event_position
		else:
			drag_local_pos = global_transform.inverse() * nonmain_sample_pos
		
		dragging_dice.clear()
		dragging_dice_rid.clear()
		dragging_dice_pos.clear()
		dragging_dice.append(self)
		dragging_dice_rid.append(get_rid())
		dragging_dice_pos.append(drag_local_pos)
		
		if main:
			picked.emit()
	
	if main and dragging and event is InputEventMouse:
		var orig: Vector3 = camera.project_ray_origin(event.position)
		var dir: Vector3 = camera.project_ray_normal(event.position)
		
		for i in range(16):
			var rayinfo: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(orig, orig + 100*dir, 2, dragging_dice_rid)
			var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(rayinfo)
			if len(result) == 0:
				break
			dragging_dice.append(result['collider'])
			dragging_dice_rid.append(result['rid'])
			dragging_dice_pos.append(result['position'])
	
	if main and len(dragging_dice) > 0:
		for i in range(len(dragging_dice)-1):
			dragging_dice[i+1]._input_event(camera, event, event_position, normal, 0, false, dragging_dice_pos[i+1])
		
	# release
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_release()

	if event is InputEventMouseMotion:
		last_drag_step = event_position - last_drag_pos
		last_drag_pos = event_position
		last_drag_orig = camera.position

func _release() -> void:
	if not dragging:
		return
	dragging = false
	dragging_dice.clear()
	dragging_dice_rid.clear()
	dragging_dice_pos.clear()
	if release_spin_kick_amp > 0:
		var axis = Vector3.UP.cross(last_drag_step)
		angular_velocity += axis * release_spin_kick_amp
	released.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT and dragging:
		_release()
	
