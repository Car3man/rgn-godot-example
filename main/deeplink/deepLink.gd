extends Node

func _ready():
	if (Engine.has_singleton("GodotIAC") and OS.get_name() == "Android"):
		var godotIAC = Engine.get_singleton("GodotIAC")
		godotIAC.start()
