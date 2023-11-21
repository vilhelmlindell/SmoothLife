extends Node

@onready var texture_rect = $TextureRect as TextureRect

var rd: RenderingDevice
var pipeline: RID
var shader: RID

var texture: ImageTexture
var image: Image

func _ready():
	initialize_rendering()

func _process(_delta):
	texture = texture_rect.texture
	image = texture.get_image()

	var input_buffer = prepare_input_buffer()

	dispatch_compute_shader()

	update_texture(input_buffer)

func initialize_rendering():
	rd = RenderingServer.create_local_rendering_device()
	var shader_file := load("res://SmoothLife.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)

func prepare_input_buffer() -> RID:
	var input_bytes: PackedByteArray = image.get_data()
	var buffer := rd.storage_buffer_create(input_bytes.size(), input_bytes)

	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 0
	uniform.add_id(buffer)
	var uniform_set := rd.uniform_set_create([uniform], shader, 0)

	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)

	return buffer

func dispatch_compute_shader():
	var compute_list := rd.compute_list_begin()
	rd.compute_list_dispatch(compute_list, 5, 1, 1)
	rd.compute_list_end()
	rd.submit()
	rd.sync()

func update_texture(buffer: RID):
	var output_bytes := rd.buffer_get_data(buffer)
	var format := image.get_format()
	var output_image := Image.create_from_data(texture.get_width(), texture.get_height(), false, format, output_bytes)
	texture_rect.texture = ImageTexture.create_from_image(output_image)
