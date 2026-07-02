extends RefCounted
class_name GameState

const HorseScript = preload("res://scripts/Horse.gd")

var coins: int = 500
var feed: int = 5
var horses: Array = []
var next_horse_id: int = 1

# Called when there is no save file or the save file cannot be read.
func setup_default_data() -> void:
	coins = 500
	feed = 5
	horses.clear()
	next_horse_id = 1

	add_horse(HorseScript.new(next_horse_id, "Brownie", 1, 0, 6, 6, 3, 80, 0, "brown", "no pattern", "Common"))
	add_horse(HorseScript.new(next_horse_id, "Snow", 1, 0, 5, 7, 4, 80, 0, "white", "no pattern", "Common"))
	add_horse(HorseScript.new(next_horse_id, "Shadow", 1, 0, 7, 5, 5, 85, 0, "black", "stripe", "Uncommon"))

func add_horse(horse) -> void:
	horses.append(horse)
	next_horse_id = max(next_horse_id, horse.id + 1)

func create_next_horse_id() -> int:
	var new_id := next_horse_id
	next_horse_id += 1
	return new_id

func get_horse(index: int):
	if index < 0 or index >= horses.size():
		return null
	return horses[index]

# SaveSystem uses this to write all important game data to one JSON object.
func to_dictionary() -> Dictionary:
	var horse_data: Array = []
	for horse in horses:
		horse_data.append(horse.to_dictionary())

	return {
		"coins": coins,
		"feed": feed,
		"horses": horse_data,
		"next_horse_id": next_horse_id
	}

# Replaces the current state with data loaded from save_game.json.
func load_from_dictionary(data: Dictionary) -> void:
	coins = int(data.get("coins", 500))
	feed = int(data.get("feed", 5))
	next_horse_id = int(data.get("next_horse_id", 1))
	horses.clear()

	var horse_data := data.get("horses", []) as Array
	for item in horse_data:
		if item is Dictionary:
			add_horse(HorseScript.from_dictionary(item))

	if horses.is_empty():
		setup_default_data()
