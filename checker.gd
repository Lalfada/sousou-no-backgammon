extends Node2D

var is_white : bool = true
var tile_id: int = -1


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	material = preload("res://checker_shader_material.tres").duplicate()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_white() -> void:
	is_white = true
	$WhiteLook.visible = true
	$BlackLook.visible = false
	
func set_black() -> void:
	is_white = false
	$WhiteLook.visible = false
	$BlackLook.visible = true

func get_active_sprite() -> Sprite2D:
	return $WhiteLook if is_white else $BlackLook
	
func set_glow(t: int) -> void:
	material.set_shader_parameter("glow", t)
	
func start_glow() -> void:
	set_glow(1.0)
	
func stop_glow() -> void:
	set_glow(0.0)
	
func set_id(new_id: int) -> void:
	tile_id = new_id
	
func get_id() -> int:
	return tile_id
