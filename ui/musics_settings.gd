extends HBoxContainer

# these units are in decibel
@export_range(-60, 0) var min_volume: float 
@export_range(0, 60) var max_volume: float
@export_range(-30, 30) var default_volume: float
@export var start_on: bool


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HSlider.value = (default_volume - min_volume) / (max_volume - min_volume)
	$AudioStreamPlayer.volume_db = default_volume
	$AudioStreamPlayer.stream_paused = !start_on
	$SoundButton.button_pressed = !start_on
	


func _on_sound_button_toggled(toggled_on: bool) -> void:
	$AudioStreamPlayer.stream_paused = toggled_on


func _on_h_slider_value_changed(value: float) -> void:
	$AudioStreamPlayer.volume_db = lerp(min_volume, max_volume, value)
