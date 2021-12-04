extends RigidBody

export(float) var SENSIVITIVY = 0.025	# Mouse sensitivity.
export(float) var ACCEL = 0.3	# Speed smoothing. Smaller number means smoother transition.
export(float) var JUMP_FORCE = 27.5

export(float) var SPRINT_MULTIPLIER = 1.4
export(float) var SPEED = 15.0	# Base speed.
export(float) var SLIDE_SPEED_MULTIPLIER = 2.0
export(float) var SLIDE_DECELL = 0.05	# Speed falloff while sliding. Smaller number means longer slide.
export(float) var CROUCH_SPEED_MULT = 0.5

export(float) var DEFAULT_FOV = 80

var current_speed := 0.0
var current_slide_speed := 0.0
var current_sprint_mult := 1.0

var is_sliding := false	# true if the character is sliding or crouching
var is_on_floor := false
var angular_rot := 0.0

var input := Vector3.ZERO

onready var cam_pivot = $"Camera Pivot"
onready var cam = $"Camera Pivot/Camera"
onready var camera_position_default = $CameraPosition_Default
onready var camera_position_slide = $CameraPosition_Slide
onready var default_collider = $CollisionShape_Default
onready var slide_collider = $CollisionShape_Slide
onready var groundcheck = $GroundCheck

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam_pivot.translation = camera_position_default.translation
	cam.fov = DEFAULT_FOV
	
	slide_collider.disabled = true
	default_collider.disabled = false

func _input(event):
	if (event is InputEventMouseMotion):
		angular_rot = -event.relative.x * SENSIVITIVY
		cam_pivot.rotate_x(deg2rad(-event.relative.y * SENSIVITIVY))

func _integrate_forces(state):
	
	is_on_floor = groundcheck.is_colliding()
	
	input.z = -(Input.get_action_strength("up") - Input.get_action_strength("down"))
	input.x = -(Input.get_action_strength("left") - Input.get_action_strength("right"))
	
	input = global_transform.basis.xform(input.normalized())
	
	current_speed = SPEED
	
	angular_velocity.y = angular_rot
	
	current_speed *= current_sprint_mult
	
	if (is_on_floor):
		if (Input.is_action_pressed("sprint")):
			current_sprint_mult = lerp(current_sprint_mult, SPRINT_MULTIPLIER, 0.5)
		else:
			current_sprint_mult = lerp(current_sprint_mult, 1.0, 0.5)
			
		if (Input.is_action_pressed("slide")):
			cam_pivot.translation = lerp(cam_pivot.translation, camera_position_slide.translation, 0.2)
			
			if (!is_sliding):	# When the slide is initiated
				initiate_crouch_slide(current_speed)
			else:	# While sliding
				current_slide_speed = lerp(current_slide_speed, SPEED * CROUCH_SPEED_MULT, SLIDE_DECELL)
				current_speed = current_slide_speed
		else:
			cam_pivot.translation = lerp(cam_pivot.translation, camera_position_default.translation, 0.2)
			if (is_sliding):
				cancel_slide()
	else:
		if (is_sliding):
			cancel_slide()
	
	cam.fov = DEFAULT_FOV + (current_speed / SPEED) * 2
		
	linear_velocity.x = lerp(linear_velocity.x, input.x * current_speed, ACCEL)
	linear_velocity.z = lerp(linear_velocity.z, input.z * current_speed, ACCEL)
	
	if (Input.is_action_just_pressed("jump") and is_on_floor):
		linear_velocity.y = JUMP_FORCE
	
	angular_rot = 0

func change_slide_collisions(is_now_sliding : bool) -> void:
	if (is_now_sliding):
		slide_collider.disabled = false
		default_collider.disabled = true
	else:
		default_collider.disabled = false
		slide_collider.disabled = true

# Initiate crouch or slide dependent on input_speed
func initiate_crouch_slide(input_speed : float) -> void:
	change_slide_collisions(true)
	if (input_speed > SPEED):
		current_slide_speed = input_speed * SLIDE_SPEED_MULTIPLIER
	else:
		current_slide_speed = SPEED * CROUCH_SPEED_MULT
	is_sliding = true

# Stop crouching or sliding
func cancel_slide() -> void:
	change_slide_collisions(false)
	is_sliding = false
