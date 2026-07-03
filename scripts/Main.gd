extends Control

const SAVE_PATH := "user://save_game.json"
const BREED_COST := 150
const FEED_COST := 50
const COLORS := ["brown", "white", "black", "gray", "gold", "chestnut"]
const PATTERNS := ["no pattern", "stripe", "spots", "star", "socks"]
const RARITIES := ["Common", "Uncommon", "Rare", "Epic", "Legendary"]

@onready var stats_label: Label = $RootMargin/Root/StatsLabel
@onready var horse_list: ItemList = $RootMargin/Root/Content/ListPanel/ListBox/HorseList
@onready var detail_label: Label = $RootMargin/Root/Content/DetailPanel/DetailBox/DetailLabel
@onready var message_label: Label = $RootMargin/Root/MessageLabel
@onready var feed_button: Button = $RootMargin/Root/ButtonRow/FeedButton
@onready var buy_feed_button: Button = $RootMargin/Root/ButtonRow/BuyFeedButton
@onready var race_button: Button = $RootMargin/Root/ButtonRow/RaceButton
@onready var breed_button: Button = $RootMargin/Root/ButtonRow/BreedButton
@onready var save_button: Button = $RootMargin/Root/ButtonRow/SaveButton
@onready var load_button: Button = $RootMargin/Root/ButtonRow/LoadButton
@onready var collection_button: Button = $RootMargin/Root/ButtonRow/CollectionButton
@onready var parent_a_option: OptionButton = $RootMargin/Root/BreedingPanel/BreedingBox/ParentAOption
@onready var parent_b_option: OptionButton = $RootMargin/Root/BreedingPanel/BreedingBox/ParentBOption
@onready var collection_panel: PanelContainer = $RootMargin/Root/CollectionPanel
@onready var collection_summary_label: Label = $RootMargin/Root/CollectionPanel/CollectionBox/CollectionSummaryLabel
@onready var collection_horse_list_label: Label = $RootMargin/Root/CollectionPanel/CollectionBox/CollectionScroll/CollectionHorseListLabel
@onready var collection_close_button: Button = $RootMargin/Root/CollectionPanel/CollectionBox/CollectionCloseButton

var coins := 500
var feed := 5
var horses: Array = []
var next_horse_id := 1
var selected_horse_index := 0
var selected_parent_a_id := -1
var selected_parent_b_id := -1
var is_refreshing_parent_options := false
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	connect_signals()
	if FileAccess.file_exists(SAVE_PATH):
		load_game_data()
	else:
		setup_default_data()
		show_message("Started a new ranch.")
	refresh_all()

func connect_signals() -> void:
	print("Connecting Tiny Horse Ranch UI signals")
	prepare_button(feed_button)
	prepare_button(buy_feed_button)
	prepare_button(race_button)
	prepare_button(breed_button)
	prepare_button(save_button)
	prepare_button(load_button)
	prepare_button(collection_button)
	prepare_button(collection_close_button)
	horse_list.item_selected.connect(Callable(self, "_on_horse_selected"))
	parent_a_option.item_selected.connect(Callable(self, "_on_parent_a_selected"))
	parent_b_option.item_selected.connect(Callable(self, "_on_parent_b_selected"))
	feed_button.pressed.connect(Callable(self, "_on_feed_pressed"))
	buy_feed_button.pressed.connect(Callable(self, "_on_buy_feed_pressed"))
	race_button.pressed.connect(Callable(self, "_on_race_pressed"))
	breed_button.pressed.connect(Callable(self, "_on_breed_pressed"))
	save_button.pressed.connect(Callable(self, "_on_save_pressed"))
	load_button.pressed.connect(Callable(self, "_on_load_pressed"))
	collection_button.pressed.connect(Callable(self, "_on_collection_pressed"))
	collection_close_button.pressed.connect(Callable(self, "_on_collection_close_pressed"))
	print("Button signals connected")

func prepare_button(button: Button) -> void:
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F:
				_on_feed_pressed()
			KEY_B:
				_on_buy_feed_pressed()
			KEY_R:
				_on_race_pressed()
			KEY_G:
				_on_breed_pressed()
			KEY_S:
				_on_save_pressed()
			KEY_L:
				_on_load_pressed()
			KEY_C:
				_on_collection_pressed()
			_:
				return
		get_viewport().set_input_as_handled()

func setup_default_data() -> void:
	coins = 500
	feed = 5
	horses.clear()
	next_horse_id = 1
	add_horse(make_horse("Brownie", "Common", "brown", "no pattern", 7, 5, 3))
	add_horse(make_horse("Snow", "Common", "white", "no pattern", 4, 8, 4))
	add_horse(make_horse("Shadow", "Uncommon", "black", "stripe", 8, 6, 5))
	selected_horse_index = 0
	selected_parent_a_id = int(horses[0]["id"])
	selected_parent_b_id = int(horses[1]["id"])

func make_horse(name: String, rarity: String, color: String, pattern: String, speed: int, stamina: int, luck: int) -> Dictionary:
	var horse := {
		"id": next_horse_id,
		"name": name,
		"level": 1,
		"exp": 0,
		"speed": speed,
		"stamina": stamina,
		"luck": luck,
		"condition": 80,
		"affection": 0,
		"color": color,
		"pattern": pattern,
		"rarity": rarity
	}
	next_horse_id += 1
	return horse

func add_horse(horse: Dictionary) -> void:
	horses.append(horse)
	next_horse_id = max(next_horse_id, int(horse.get("id", 0)) + 1)

func _on_horse_selected(index: int) -> void:
	print("Horse selected: ", index)
	selected_horse_index = index
	refresh_detail()
	show_message("Selected %s." % str(get_selected_horse().get("name", "horse")))

func _on_parent_a_selected(index: int) -> void:
	if is_refreshing_parent_options:
		return
	selected_parent_a_id = get_parent_option_horse_id(parent_a_option, index)
	if selected_parent_a_id == selected_parent_b_id:
		selected_parent_b_id = find_different_horse_id(selected_parent_a_id)
	refresh_parent_options()

func _on_parent_b_selected(index: int) -> void:
	if is_refreshing_parent_options:
		return
	selected_parent_b_id = get_parent_option_horse_id(parent_b_option, index)
	if selected_parent_b_id == selected_parent_a_id:
		selected_parent_a_id = find_different_horse_id(selected_parent_b_id)
	refresh_parent_options()

func _on_feed_pressed() -> void:
	print("Feed button pressed")
	var horse := get_selected_horse()
	if horse.is_empty():
		show_message("Select a horse first.")
		print("Feed failed: no horse selected")
		return
	if feed <= 0:
		show_message("Not enough feed.")
		print("Feed failed: not enough feed")
		return

	feed -= 1
	horse["condition"] = min(100, int(horse["condition"]) + 20)
	horse["affection"] = int(horse["affection"]) + 1
	horses[selected_horse_index] = horse
	show_message("Fed %s." % str(horse["name"]))
	print("Fed %s. Feed is now %d." % [str(horse["name"]), feed])
	update_ui()

func _on_buy_feed_pressed() -> void:
	print("Buy Feed button pressed")
	if coins < FEED_COST:
		show_message("Not enough coins.")
		print("Buy Feed failed: not enough coins")
		return

	coins -= FEED_COST
	feed += 1
	show_message("Bought 1 feed.")
	print("Bought 1 feed. Coins: %d, Feed: %d." % [coins, feed])
	update_ui()

func _on_race_pressed() -> void:
	print("Race button pressed")
	var horse := get_selected_horse()
	if horse.is_empty():
		show_message("Select a horse first.")
		print("Race failed: no horse selected")
		return

	var condition_bonus := int(float(horse["condition"]) / 10.0)
	var score := int(horse["speed"]) * 2 + int(horse["stamina"]) + int(horse["luck"]) + rng.randi_range(0, 20) + condition_bonus
	var place := get_race_place(score)
	var reward := get_race_reward(place)

	coins += int(reward["coins"])
	horse["exp"] = int(horse["exp"]) + int(reward["exp"])
	horse["condition"] = max(0, int(horse["condition"]) - 15)

	var level_text := ""
	if int(horse["exp"]) >= 100:
		horse["level"] = int(horse["level"]) + 1
		horse["exp"] = 0
		var stat_index := rng.randi_range(0, 2)
		if stat_index == 0:
			horse["speed"] = int(horse["speed"]) + 1
			level_text = " Level up: speed +1."
		elif stat_index == 1:
			horse["stamina"] = int(horse["stamina"]) + 1
			level_text = " Level up: stamina +1."
		else:
			horse["luck"] = int(horse["luck"]) + 1
			level_text = " Level up: luck +1."

	horses[selected_horse_index] = horse
	show_message("%s finished %s and earned %d coins.%s" % [
		str(horse["name"]),
		get_place_text(place),
		int(reward["coins"]),
		level_text
	])
	print("%s race score %d, place %s, earned %d coins." % [
		str(horse["name"]),
		score,
		get_place_text(place),
		int(reward["coins"])
	])
	update_ui()

func _on_breed_pressed() -> void:
	print("Breed button pressed")
	if horses.size() < 2:
		show_message("Need at least two horses to breed.")
		print("Breed failed: not enough horses")
		return
	if coins < BREED_COST:
		show_message("Not enough coins to breed.")
		print("Breed failed: not enough coins")
		return

	var parent_a := get_horse_by_id(selected_parent_a_id)
	var parent_b := get_horse_by_id(selected_parent_b_id)
	if parent_a.is_empty() or parent_b.is_empty():
		show_message("Select two horses to breed.")
		print("Breed failed: missing parent selection")
		return
	if int(parent_a["id"]) == int(parent_b["id"]):
		show_message("Please select two different horses.")
		print("Breed failed: same parent selected")
		return

	coins -= BREED_COST
	var foal := make_foal(parent_a, parent_b)
	add_horse(foal)
	selected_horse_index = horses.size() - 1
	show_message(get_foal_message(foal))
	print("A new foal was born: %s. Coins: %d." % [str(foal["name"]), coins])
	update_ui()

func _on_save_pressed() -> void:
	print("Save button pressed")
	save_game_data()

func _on_load_pressed() -> void:
	print("Load button pressed")
	load_game_data()
	update_ui()

func _on_collection_pressed() -> void:
	print("Collection opened")
	collection_panel.visible = true
	update_collection_ui()
	show_message("Collection opened.")

func _on_collection_close_pressed() -> void:
	print("Collection closed")
	collection_panel.visible = false
	show_message("Collection closed.")

func get_selected_horse() -> Dictionary:
	if selected_horse_index < 0 or selected_horse_index >= horses.size():
		return {}
	return horses[selected_horse_index]

func get_horse_by_id(horse_id: int) -> Dictionary:
	for horse in horses:
		if horse is Dictionary and int(horse.get("id", -1)) == horse_id:
			return horse as Dictionary
	return {}

func get_parent_option_horse_id(option: OptionButton, index: int) -> int:
	if index < 0 or index >= option.get_item_count():
		return -1
	return int(option.get_item_metadata(index))

func find_different_horse_id(horse_id: int) -> int:
	for horse in horses:
		if not (horse is Dictionary):
			continue
		var candidate_id := int(horse.get("id", -1))
		if candidate_id != horse_id:
			return candidate_id
	return -1

func make_foal(parent_a: Dictionary, parent_b: Dictionary) -> Dictionary:
	var foal_id := next_horse_id
	return {
		"id": foal_id,
		"name": "Foal%d" % foal_id,
		"level": 1,
		"exp": 0,
		"speed": mixed_stat(int(parent_a["speed"]), int(parent_b["speed"])),
		"stamina": mixed_stat(int(parent_a["stamina"]), int(parent_b["stamina"])),
		"luck": mixed_stat(int(parent_a["luck"]), int(parent_b["luck"])),
		"condition": 80,
		"affection": 0,
		"color": inherited_trait(str(parent_a["color"]), str(parent_b["color"]), COLORS, 0.15),
		"pattern": inherited_trait(str(parent_a["pattern"]), str(parent_b["pattern"]), PATTERNS, 0.20),
		"rarity": random_rarity()
	}

func mixed_stat(a: int, b: int) -> int:
	var average := int(round(float(a + b) / 2.0))
	return max(1, average + rng.randi_range(-2, 2))

func inherited_trait(a: String, b: String, options: Array, mutation_chance: float) -> String:
	if rng.randf() < mutation_chance:
		return str(options[rng.randi_range(0, options.size() - 1)])
	return a if rng.randf() < 0.5 else b

func random_rarity() -> String:
	var roll := rng.randf()
	if roll < 0.02:
		return "Legendary"
	if roll < 0.08:
		return "Epic"
	if roll < 0.20:
		return "Rare"
	if roll < 0.45:
		return "Uncommon"
	return "Common"

func get_foal_message(foal: Dictionary) -> String:
	return "A new foal was born: %s | Color: %s | Pattern: %s | Rarity: %s | Speed: %d | Stamina: %d | Luck: %d" % [
		str(foal["name"]),
		str(foal["color"]),
		str(foal["pattern"]),
		str(foal["rarity"]),
		int(foal["speed"]),
		int(foal["stamina"]),
		int(foal["luck"])
	]

func get_race_place(score: int) -> int:
	if score >= 40:
		return 1
	if score >= 32:
		return 2
	if score >= 24:
		return 3
	return 4

func get_race_reward(place: int) -> Dictionary:
	if place == 1:
		return {"coins": 200, "exp": 30}
	if place == 2:
		return {"coins": 120, "exp": 20}
	if place == 3:
		return {"coins": 70, "exp": 10}
	return {"coins": 30, "exp": 5}

func get_place_text(place: int) -> String:
	if place == 1:
		return "1st"
	if place == 2:
		return "2nd"
	if place == 3:
		return "3rd"
	return "with a participation prize"

func save_game_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		show_message("Save failed.")
		print("Save failed.")
		return

	file.store_string(JSON.stringify({
		"coins": coins,
		"feed": feed,
		"horses": horses,
		"next_horse_id": next_horse_id
	}, "\t"))
	show_message("Game saved.")
	print("Game saved to %s." % SAVE_PATH)

func load_game_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		setup_default_data()
		show_message("No save file found. Started default ranch.")
		print("No save file found. Started default ranch.")
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		setup_default_data()
		show_message("Load failed. Started default ranch.")
		print("Load failed. Started default ranch.")
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		setup_default_data()
		show_message("Save file is invalid. Started default ranch.")
		print("Save file is invalid. Started default ranch.")
		return

	coins = int(parsed.get("coins", 500))
	feed = int(parsed.get("feed", 5))
	next_horse_id = int(parsed.get("next_horse_id", 1))
	var loaded_horses = parsed.get("horses", [])
	if loaded_horses is Array:
		horses = loaded_horses
	else:
		horses = []
	if horses.is_empty():
		setup_default_data()
	selected_horse_index = 0
	reset_parent_selection()
	show_message("Game loaded.")
	print("Game loaded from %s." % SAVE_PATH)

func refresh_all() -> void:
	update_ui()

func update_ui() -> void:
	refresh_stats()
	refresh_horse_list()
	refresh_parent_options()
	refresh_detail()
	if collection_panel.visible:
		update_collection_ui()

func refresh_stats() -> void:
	stats_label.text = "Coins: %d | Feed: %d" % [coins, feed]

func refresh_horse_list() -> void:
	horse_list.clear()
	for horse in horses:
		horse_list.add_item("%s Lv.%d [%s]" % [
			str(horse.get("name", "Horse")),
			int(horse.get("level", 1)),
			str(horse.get("rarity", "Common"))
		])

	if horses.is_empty():
		selected_horse_index = -1
		return

	selected_horse_index = clampi(selected_horse_index, 0, horses.size() - 1)
	horse_list.select(selected_horse_index)

func refresh_parent_options() -> void:
	is_refreshing_parent_options = true
	ensure_parent_selection()
	fill_parent_option(parent_a_option, selected_parent_a_id)
	fill_parent_option(parent_b_option, selected_parent_b_id)
	is_refreshing_parent_options = false

func ensure_parent_selection() -> void:
	if horses.is_empty():
		selected_parent_a_id = -1
		selected_parent_b_id = -1
		return

	if get_horse_by_id(selected_parent_a_id).is_empty():
		selected_parent_a_id = int(horses[0].get("id", -1))
	if horses.size() == 1:
		selected_parent_b_id = -1
		return
	if get_horse_by_id(selected_parent_b_id).is_empty() or selected_parent_b_id == selected_parent_a_id:
		selected_parent_b_id = find_different_horse_id(selected_parent_a_id)

func reset_parent_selection() -> void:
	if horses.is_empty():
		selected_parent_a_id = -1
		selected_parent_b_id = -1
		return
	selected_parent_a_id = int(horses[0].get("id", -1))
	selected_parent_b_id = find_different_horse_id(selected_parent_a_id)

func fill_parent_option(option: OptionButton, selected_id: int) -> void:
	option.clear()
	for horse in horses:
		option.add_item("%s Lv.%d [%s]" % [
			str(horse.get("name", "Horse")),
			int(horse.get("level", 1)),
			str(horse.get("rarity", "Common"))
		])
		option.set_item_metadata(option.get_item_count() - 1, int(horse.get("id", -1)))

	if option.get_item_count() == 0:
		option.disabled = true
		return

	option.disabled = false
	for index in range(option.get_item_count()):
		if get_parent_option_horse_id(option, index) == selected_id:
			option.select(index)
			return
	option.select(0)

func update_collection_ui() -> void:
	var rarity_counts := get_rarity_counts()
	var discovered_colors := get_discovered_colors()
	var discovered_patterns := get_discovered_patterns()
	var summary_lines := PackedStringArray([
		"Total horses: %d" % horses.size(),
		"Colors: %s" % format_discovered_list(discovered_colors),
		"Patterns: %s" % format_discovered_list(discovered_patterns),
		"Rarity counts:"
	])

	for rarity in RARITIES:
		summary_lines.append("%s: %d" % [rarity, int(rarity_counts.get(rarity, 0))])
	collection_summary_label.text = "\n".join(summary_lines)

	var horse_lines := PackedStringArray()
	for horse in horses:
		if not (horse is Dictionary):
			continue
		horse_lines.append("%s | %s | %s | %s" % [
			str(horse.get("name", "Horse")),
			str(horse.get("rarity", "Common")),
			str(horse.get("color", "unknown")),
			str(horse.get("pattern", "unknown"))
		])

	if horse_lines.is_empty():
		collection_horse_list_label.text = "No horses."
	else:
		collection_horse_list_label.text = "\n".join(horse_lines)

func get_rarity_counts() -> Dictionary:
	var counts := {}
	for rarity in RARITIES:
		counts[rarity] = 0

	for horse in horses:
		if not (horse is Dictionary):
			continue
		var horse_rarity := str(horse.get("rarity", "Common"))
		if not counts.has(horse_rarity):
			counts[horse_rarity] = 0
		counts[horse_rarity] = int(counts[horse_rarity]) + 1
	return counts

func get_discovered_colors() -> Array:
	var discovered := {}
	for horse in horses:
		if horse is Dictionary:
			discovered[str(horse.get("color", "unknown"))] = true

	var colors := []
	for color in discovered.keys():
		colors.append(str(color))
	colors.sort()
	return colors

func get_discovered_patterns() -> Array:
	var discovered := {}
	for horse in horses:
		if horse is Dictionary:
			discovered[str(horse.get("pattern", "unknown"))] = true

	var patterns := []
	for pattern in discovered.keys():
		patterns.append(str(pattern))
	patterns.sort()
	return patterns

func format_discovered_list(items: Array) -> String:
	if items.is_empty():
		return "None"
	var text_items := PackedStringArray()
	for item in items:
		text_items.append(str(item))
	return ", ".join(text_items)

func refresh_detail() -> void:
	var horse := get_selected_horse()
	if horse.is_empty():
		detail_label.text = "No horse selected."
		return

	var lines := PackedStringArray([
		"ID: %d" % int(horse["id"]),
		"Name: %s" % str(horse["name"]),
		"Rarity: %s" % str(horse["rarity"]),
		"Level: %d" % int(horse["level"]),
		"EXP: %d / 100" % int(horse["exp"]),
		"Speed: %d" % int(horse["speed"]),
		"Stamina: %d" % int(horse["stamina"]),
		"Luck: %d" % int(horse["luck"]),
		"Condition: %d / 100" % int(horse["condition"]),
		"Affection: %d" % int(horse["affection"]),
		"Color: %s" % str(horse["color"]),
		"Pattern: %s" % str(horse["pattern"])
	])
	detail_label.text = "\n".join(lines)

func show_message(text: String) -> void:
	message_label.text = text
