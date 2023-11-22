extends Node

const IMAGE_FORMAT := Image.FORMAT_RGBAF

@onready var texture_rect = $TextureRect as TextureRect

@export var run_simulation: bool
@export var inner_circle_radius: int
@export var outer_circle_radius: int

var rd: RenderingDevice
var pipeline: RID
var shader: RID
var output_texture: RID

var texture: ImageTexture
var image: Image

func _ready():
	var window_size: Vector2i = DisplayServer.window_get_size()
	
	image = Image.create(window_size.x, window_size.y, false, Image.FORMAT_RGBAF)
	image.fill(Color(0, 0, 0, 1))
	texture_rect.texture.set_image(image)
	
	initialize_rendering()

func _process(delta):
	texture = texture_rect.texture
	image = texture.get_image()
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_position := get_viewport().get_mouse_position()
		var paint_radius := 10
		for x in range(-paint_radius, paint_radius):
			for y in range(-paint_radius, paint_radius):
				if x*x + y*y > paint_radius*paint_radius:
					continue
				var pixel_position := mouse_position + Vector2(x, y)
				image.set_pixel(pixel_position.x, pixel_position.y, Color(1, 1, 1, 1))
		texture_rect.texture.update(image)
		
	if !run_simulation:
		return
	
	var compute_list := rd.compute_list_begin()
		
	prepare_texture_uniform(compute_list)

	dispatch_compute_shader(compute_list)

	update_texture()

func initialize_rendering():
	rd = RenderingServer.create_local_rendering_device()
	var shader_file := load("res://SmoothLife.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)

func prepare_texture_uniform(compute_list: int):
	var format := RDTextureFormat.new()
	format.width = texture.get_width()
	format.height = texture.get_height()
	format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	format.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	var view := RDTextureView.new()
	output_texture = rd.texture_create(format, view, [image.get_data()])
	var output_tex_uniform := RDUniform.new()
	output_tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	output_tex_uniform.binding = 0
	output_tex_uniform.add_id(output_texture)
	
	var uniform_set := rd.uniform_set_create([output_tex_uniform], shader, 0)

	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)\

func prepare_parameter_buffer():
	var parameter_data = PackedByteArray([inner_circle_radius, outer_circle_radius])
	var buffer := rd.uniform_buffer_create(parameter_data.size(), parameter_data)

func dispatch_compute_shader(compute_list: int):
	rd.compute_list_dispatch(compute_list, texture.get_width(), texture.get_height(), 1)
	rd.compute_list_end()
	rd.submit()
	rd.sync()

func update_texture():
	var output_bytes : PackedByteArray = rd.texture_get_data(output_texture, 0)
	image = Image.create_from_data(texture.get_width(), texture.get_height(), false, Image.FORMAT_RGBAF, output_bytes)
	texture_rect.texture.update(image)
