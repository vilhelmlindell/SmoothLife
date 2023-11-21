extends TextureRect

@export var run_simulation: bool = false
@export var output_viewport: SubViewport

func _ready():
	pass

func _process(delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_position = get_global_mouse_position()
		texture.draw(get_canvas_item(), mouse_position, Color(0, 0, 0, 1))
		
	if run_simulation:
		var shader_material = ShaderMaterial.new()
		shader_material.shader = preload("res://smoothlife.gdshader")
		material = shader_material
	else:
		material = null
	pass

func _draw():
		texture = output_viewport.get_texture()
