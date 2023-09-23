@tool
extends Node3D

var text := "Text": set = set_text
var text_size := 1.0: set = set_text_size
var font: Font: set = set_font
var align := 0: set = set_align

var color := Color(0.6, 0.6, 0.6): set = set_color
var metallic := 0.0: set = set_metallic
var roughness := 0.5: set = set_roughness
var emission_strength := 0.0: set = set_emission_strength
var emission_color := Color(1.0, 1.0, 1.0): set = set_emission_color

var extrude := 0.0: set = set_extrude
var max_steps := 256: set = set_max_steps
var step_size := 1.0: set = set_step_size


var label: Label
var viewport: SubViewport
var proxy: MeshInstance3D
var material: ShaderMaterial


func _get_property_list() -> Array:
	var properties := [
		{name="Label3D", type=TYPE_NIL, usage=PROPERTY_USAGE_CATEGORY},
		{name="text", type=TYPE_STRING, hint=PROPERTY_HINT_MULTILINE_TEXT},
		{name="text_size", type=TYPE_FLOAT},
		{name="font", type=TYPE_OBJECT, hint=PROPERTY_HINT_RESOURCE_TYPE, hint_string="Font"},
		{name="align", type=TYPE_INT, hint=PROPERTY_HINT_ENUM, hint_string="Left,Right,Center,Fill"},

		{name="Material", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP},
		{name="color", type=TYPE_COLOR, hint=PROPERTY_HINT_COLOR_NO_ALPHA},
		{name="metallic", type=TYPE_FLOAT, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
		{name="roughness", type=TYPE_FLOAT, hint=PROPERTY_HINT_RANGE, hint_string="0,1,0.01"},
		{name="emission_color", type=TYPE_COLOR, hint=PROPERTY_HINT_COLOR_NO_ALPHA},
		{name="emission_strength", type=TYPE_FLOAT, hint=PROPERTY_HINT_RANGE, hint_string="0,16,0.01,or_greater"},

		{name="Extrusion", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP},
		{name="extrude", type=TYPE_FLOAT},
		{name="max_steps", type=TYPE_INT},
		{name="step_size", type=TYPE_FLOAT},
	]
	return properties


func _ready() -> void:
	for i in range(get_child_count()):
		remove_child(get_child(0))

	viewport = preload("text_viewport.tscn").instantiate()
	label = viewport.get_node("Label")
	add_child(viewport)

	proxy = MeshInstance3D.new()
	proxy.mesh = BoxMesh.new()
	proxy.material_override = preload("label_3d.material").duplicate()
	material = proxy.material_override
	
	var view_texture: ViewportTexture = viewport.get_texture()
	material.set_shader_parameter("text", view_texture)
	add_child(proxy)

	set_text(text)
	set_font(font)
	set_align(align)
	set_text_size(text_size)

	set_color(color)
	set_metallic(metallic)
	set_roughness(roughness)
	set_emission_color(emission_color)
	set_emission_strength(emission_strength)

	set_extrude(extrude)
	set_max_steps(max_steps)
	set_step_size(step_size)


func set_text(value: String) -> void:
	text = value
	if label:
		label.text = text
		label.size = Vector2()
		label.force_update_transform()
		
		var size: Vector2 = label.size
		viewport.size = size
		
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		await get_tree().idle_frame
		
		label.size = Vector2()
		label.force_update_transform()
		
		size = label.size
		viewport.size = size
		
		await get_tree().idle_frame
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		
		proxy.scale.x = size.x * text_size / 200.0
		proxy.scale.y = size.y * text_size / 200.0


func set_text_size(value: float) -> void:
	text_size = max(value, 0.001)
	if label:
		var size: Vector2 = label.size
		if proxy:
			proxy.scale.x = size.x * text_size / 200.0
			proxy.scale.y = size.y * text_size / 200.0


func set_extrude(value: float) -> void:
	extrude = max(value, 0)
	if proxy:
		proxy.scale.z = extrude if extrude != 0 else 1
		material.set_shader_parameter("extrude", extrude != 0)
		
		if extrude == 0 and proxy.mesh is BoxMesh:
			proxy.mesh = QuadMesh.new()
			proxy.mesh.size = Vector2(2, 2)
		elif proxy.mesh is QuadMesh:
			proxy.mesh = BoxMesh.new()


func set_font(value: Font) -> void:
	font = value
	if label:
		if font:
			label.add_theme_font_override("font", font)
		else:
			label.add_theme_font_override("font", preload("default_font.tres"))
		set_text(text)


func set_align(value: int) -> void:
	align = value
	if label:
		match align:
			0:
				label.align = Label.ALIGN_LEFT
			1:
				label.align = Label.ALIGN_RIGHT
			2:
				label.align = Label.ALIGNMENT_CENTER
			3:
				label.align = Label.ALIGN_FILL
			_:
				printerr("Invalid align value set for %s!" % self)
	
	set_text(text)


func set_color(value: Color) -> void:
	color = value
	if material:
		material.set_shader_parameter("albedo", color)


func set_metallic(value: float) -> void:
	metallic = value
	if material:
		material.set_shader_parameter("metallic", metallic)


func set_roughness(value: float) -> void:
	roughness = value
	if material:
		material.set_shader_parameter("roughness", roughness)


func set_emission_color(value: Color) -> void:
	emission_color = value
	if material:
		material.set_shader_parameter("emission", emission_color * emission_strength)


func set_emission_strength(value: float) -> void:
	emission_strength = value
	print(emission_color * emission_strength)
	if material:
		material.set_shader_parameter("emission", emission_color * emission_strength)


func set_max_steps(value: int) -> void:
	max_steps = max(value, 8)
	if material:
		material.set_shader_parameter("maxSteps", max_steps)


func set_step_size(value: float) -> void:
	step_size = max(value, 0.001)
	if material:
		material.set_shader_parameter("stepSize", step_size)
