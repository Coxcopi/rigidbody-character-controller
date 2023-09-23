extends RigidBody3D

@export var SENSITIVITY: float = 0.125	# Mouse sensitivity.
@export var ACCEL: float = 0.2	  # Speed smoothing. Smaller number means smoother transition.
@export var JUMP_FORCE: float = 27.5

@export var SPRINT_MULTIPLIER: float = 1.4
@export var SPEED: float = 15.0	  # Base speed.
@export var SLIDE_SPEED_MULTIPLIER: float = 2.0
@export var SLIDE_DECELL: float = 0.05	# Speed falloff while sliding. Smaller number means longer slide.
@export var CROUCH_SPEED_MULT: float = 0.5

@export var DEFAULT_FOV: float = 80

var current_speed := 0.0
var current_slide_speed := -0.5
var current_sprint_mult := 1.0

var is_sliding := false	# true if the character is sliding or crouching
var is_on_floor := false
var angular_rot := 0.0

var input := Vector3.ZERO

@onready var cam_pivot = $"Camera3D Pivot"
@onready var cam = $"Camera3D Pivot/Camera3D"
@onready var camera_position_default = $CameraPosition_Default
@onready var camera_position_slide = $CameraPosition_Slide
@onready var default_collider = $CollisionShape_Default
@onready var slide_collider = $CollisionShape_Slide
@onready var groundcheck = $GroundCheck
@onready var headcheck = $TopCheck

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam_pivot.position = camera_position_default.position
	cam.fov = DEFAULT_FOV
	
	change_slide_collisions(false)

func _input(event):
	if (event is InputEventMouseMotion):
		angular_rot = -event.relative.x * SENSITIVITY
		cam_pivot.rotate_x(deg_to_rad(-event.relative.y * SENSITIVITY))

func _integrate_forces(_state):
	
	is_on_floor = groundcheck.is_colliding()
	
	input.z = -(Input.get_action_strength("up") - Input.get_action_strength("down"))
	input.x = -(Input.get_action_strength("left") - Input.get_action_strength("right"))
	
	input = global_transform.basis * (input.normalized())
	
	current_speed = SPEED
	
	angular_velocity.y = angular_rot
	
	current_speed *= current_sprint_mult
	
	if (is_on_floor):
		if (Input.is_action_pressed("sprint")):
			current_sprint_mult = lerp(current_sprint_mult, SPRINT_MULTIPLIER, 0.5)
		else:
			current_sprint_mult = lerp(current_sprint_mult, 1.0, 0.5)
			
		if (Input.is_action_pressed("slide")):
			cam_pivot.position = lerp(cam_pivot.position, camera_position_slide.position, 0.2)
			
			if (!is_sliding):	# When the slide is initiated
				initiate_crouch_slide(current_speed)
			else:	# While sliding
				current_slide_speed = lerp(current_slide_speed, SPEED * CROUCH_SPEED_MULT, SLIDE_DECELL)
				current_speed = current_slide_speed
		else:
			if (is_sliding):
				cancel_slide()
	else:
		if (is_sliding):
			cancel_slide()
			
	if (!is_sliding):
		cam_pivot.position = lerp(cam_pivot.position, camera_position_default.position, 0.2)
	
	cam.fov = DEFAULT_FOV + (current_speed / SPEED) * 2
		
	linear_velocity.x = lerp(linear_velocity.x, input.x * current_speed, ACCEL)
	linear_velocity.z = lerp(linear_velocity.z, input.z * current_speed, ACCEL)
	
	if (Input.is_action_just_pressed("jump") and is_on_floor and !headcheck.is_colliding()):
		linear_velocity.y = JUMP_FORCE
	
	angular_rot = 0

func change_slide_collisions(is_now_sliding : bool) -> void:
	if (is_now_sliding):
		slide_collider.set_deferred("disabled", false)  
		default_collider.set_deferred("disabled", true)  
		headcheck.target_position.y = 2.0
	else:
		default_collider.set_deferred("disabled", false)
		slide_collider.set_deferred("disabled", true)  
		headcheck.target_position.y = 3.0

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
	# Prevents slide from stopping when touching the ceiling
	if (headcheck.is_colliding()):
		return
	change_slide_collisions(false)
	is_sliding = false
