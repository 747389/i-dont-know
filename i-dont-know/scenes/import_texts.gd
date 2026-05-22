extends Node3D

@export var heightmap_texture: Texture2D
var scale_height: float = 500.0

func _ready() -> void:
	if heightmap_texture:
		print_heights()

func print_heights() -> void:
	var img: Image = heightmap_texture.get_image()
	var size_x: int = img.get_width()
	var size_y: int = img.get_height()
	
	for y in range(size_y):
		for x in range(size_x):
			var pixel_color: Color = img.get_pixel(x, y)
			var val: float = pixel_color.r * scale_height
			print("[%d, %d]\t%.1f" % [x, y, val])
