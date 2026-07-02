extends RefCounted
class_name SaveSystem

const SAVE_PATH := "user://save_game.json"

# user:// points to Godot's per-user app data folder, not the project folder.
func save_game(state) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false

	var json_text := JSON.stringify(state.to_dictionary(), "\t")
	file.store_string(json_text)
	return true

func load_game(state) -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		state.setup_default_data()
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		state.setup_default_data()
		return false

	var json_text := file.get_as_text()
	var parsed = JSON.parse_string(json_text)
	if parsed is Dictionary:
		state.load_from_dictionary(parsed)
		return true

	state.setup_default_data()
	return false
