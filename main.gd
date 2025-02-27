extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	var mode := DisplayServer.window_get_mode()
	var is_window: bool = mode != DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if is_window else DisplayServer.WINDOW_MODE_WINDOWED)
	
	var project_window_size: Vector2 = Vector2(\
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
		)

	var window_size: Vector2 = DisplayServer.window_get_size()
	
	#$Board.scale = Vector2(window_size.x / project_window_size.x,\
		#window_size.y / project_window_size.y)
	$Board.update_graphics()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
