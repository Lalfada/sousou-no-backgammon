extends GPUParticles2D

@export var purple_gradient: GradientTexture1D
@export var purple_trail: Color
@export var red_colors: GradientTexture1D
@export var red_trail: Color


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_purple()
	
	
func set_red() -> void:
	set_colors(red_colors, red_trail)
	
func set_purple() -> void:
	set_colors(purple_gradient, purple_trail)

func set_colors(gradient: GradientTexture1D, trail: Color) -> void:
	process_material.color_ramp = gradient
	$TrailParticles.process_material.color = trail
