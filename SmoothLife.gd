extends Node

const IMAGE_FORMAT := Image.FORMAT_RGBAF
const PAINT_RADIUS := 10
const INITIAL_COLOR := Color(0, 0, 0, 1)

@onready var texture_rect = $TextureRect as TextureRect

@export var run_simulation: bool
@export var inner_circle_radius: int
@export var outer_circle_radius: int
@export var birth_interval_1: float
@export var birth_interval_2: float
@export var death_interval_1: float
@export var death_interval_2: float
@export var alpha_n: float
@export var alpha_m: float

var rd: RenderingDevice
var pipeline: RID
var shader: RID
var output_texture: RID
var image: Image

func _ready():
	var window_size: Vector2i = DisplayServer.window_get_size()
	
	image = Image.create(window_size.x, window_size.y, false, IMAGE_FORMAT)
	image.fill(INITIAL_COLOR)
	texture_rect.texture.set_image(image)
	
	initialize_rendering()

func handle_mouse_input():
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_position: Vector2 = get_viewport().get_mouse_position()
		for x in range(-PAINT_RADIUS, PAINT_RADIUS):
			for y in range(-PAINT_RADIUS, PAINT_RADIUS):
				if x*x + y*y > PAINT_RADIUS*PAINT_RADIUS:
					continue
				var pixel_position := Vector2i(mouse_position) + Vector2i(x, y)
				image.set_pixel(pixel_position.x, pixel_position.y, Color(1.0, 1.0, 1.0, 1.0))
		texture_rect.texture.update(image)

func _process(_delta):
	handle_mouse_input()
	
	if !run_simulation:
		return
	
	var compute_list := rd.compute_list_begin()
		
	var texture_uniform := prepare_texture_uniform()
	var parameters_uniform := prepare_parameter_buffer()

	var uniform_set := rd.uniform_set_create([texture_uniform, parameters_uniform], shader, 0)

	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)

	dispatch_compute_shader(compute_list)

	update_image()

func initialize_rendering():
	rd = RenderingServer.create_local_rendering_device()
	var shader_file := load("res://SmoothLife.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)

func prepare_texture_uniform() -> RDUniform:
	var format := RDTextureFormat.new()
	format.width = image.get_width()
	format.height = image.get_height()
	format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	format.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	var view := RDTextureView.new()
	output_texture = rd.texture_create(format, view, [image.get_data()])
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = 0
	uniform.add_id(output_texture)
	return uniform

func prepare_parameter_buffer() -> RDUniform:
	var parameters := [inner_circle_radius, outer_circle_radius, birth_interval_1, birth_interval_2, death_interval_1, death_interval_2, alpha_n, alpha_m]
	var parameter_data := PackedByteArray(parameters)
	var buffer := rd.storage_buffer_create(parameter_data.size(), parameter_data)
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 1
	uniform.add_id(buffer)
	return uniform

func dispatch_compute_shader(compute_list: int):
	rd.compute_list_dispatch(compute_list, image.get_width(), image.get_height(), 1)
	rd.compute_list_end()
	rd.submit()
	rd.sync()

func update_image():
	var output_bytes : PackedByteArray = rd.texture_get_data(output_texture, 0)
	image = Image.create_from_data(image.get_width(), image.get_height(), false, IMAGE_FORMAT, output_bytes)
	texture_rect.texture.update(image)
