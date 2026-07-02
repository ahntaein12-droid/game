extends Control

const GameStateScript = preload("res://scripts/GameState.gd")
const RacingSystemScript = preload("res://scripts/RacingSystem.gd")
const BreedingSystemScript = preload("res://scripts/BreedingSystem.gd")
const SaveSystemScript = preload("res://scripts/SaveSystem.gd")

var stats_label: Label
var horse_list: ItemList
var detail_label: Label
var horse_preview: ColorRect
var message_label: Label
var feed_button: Button
var race_button: Button
var breed_button: Button
var buy_feed_button: Button
var save_button: Button
var load_button: Button

var state = GameStateScript.new()
var racing_system = RacingSystemScript.new()
var breeding_system = BreedingSystemScript.new()
var save_system = SaveSystemScript.new()
var selected_horse_index := 0

# Main owns the UI. Game logic stays in smaller system classes so it can grow later.
func _ready() -> void:
	_build_ui()
	_connect_buttons()
	var loaded := save_system.load_game(state)
	_refresh_all()
	_show_message("Loaded saved ranch." if loaded else "Started a new ranch.")

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 18)
	root_margin.add_theme_constant_override("margin_top", 18)
	root_margin.add_theme_constant_override("margin_right", 18)
	root_margin.add_theme_constant_override("margin_bottom", 18)
	add_child(root_margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 12)
	root_margin.add_child(root_vbox)

	var title_label := Label.new()
	title_label.text = "Tiny Horse Ranch"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 34)
	root_vbox.add_child(title_label)

	stats_label = Label.new()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 20)
	root_vbox.add_child(stats_label)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	root_vbox.add_child(content)

	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(330, 0)
	content.add_child(list_panel)

	var list_vbox := VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 8)
	list_panel.add_child(list_vbox)

	var list_title := Label.new()
	list_title.text = "My Horses"
	list_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list_title.add_theme_font_size_override("font_size", 22)
	list_vbox.add_child(list_title)

	horse_list = ItemList.new()
	horse_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	horse_list.allow_reselect = true
	list_vbox.add_child(horse_list)

	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(detail_panel)

	var detail_vbox := VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 10)
	detail_panel.add_child(detail_vbox)

	var detail_title := Label.new()
	detail_title.text = "Selected Horse"
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_title.add_theme_font_size_override("font_size", 22)
	detail_vbox.add_child(detail_title)

	horse_preview = ColorRect.new()
	horse_preview.custom_minimum_size = Vector2(0, 90)
	detail_vbox.add_child(horse_preview)

	detail_label = Label.new()
	detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	detail_label.add_theme_font_size_override("font_size", 18)
	detail_vbox.add_child(detail_label)

	var button_grid := GridContainer.new()
	button_grid.columns = 6
	button_grid.add_theme_constant_override("h_separation", 8)
	button_grid.add_theme_constant_override("v_separation", 8)
	root_vbox.add_child(button_grid)

	feed_button = _make_button("Feed Horse", button_grid)
	race_button = _make_button("Race", button_grid)
	breed_button = _make_button("Breed", button_grid)
	buy_feed_button = _make_button("Buy Feed", button_grid)
	save_button = _make_button("Save Game", button_grid)
	load_button = _make_button("Load Game", button_grid)

	message_label = Label.new()
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 16)
	root_vbox.add_child(message_label)

func _make_button(text: String, parent: Node) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(button)
	return button

func _connect_buttons() -> void:
	horse_list.item_selected.connect(_on_horse_selected)
	feed_button.pressed.connect(_on_feed_pressed)
	race_button.pressed.connect(_on_race_pressed)
	breed_button.pressed.connect(_on_breed_pressed)
	buy_feed_button.pressed.connect(_on_buy_feed_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)

func _on_horse_selected(index: int) -> void:
	selected_horse_index = index
	_refresh_detail()

# Button handlers validate resources, call the right system, then refresh the UI.
func _on_feed_pressed() -> void:
	var horse = _get_selected_horse()
	if horse == null:
		_show_message("Select a horse first.")
		return
	if state.feed <= 0:
		_show_message("Not enough feed.")
		return

	state.feed -= 1
	horse.feed()
	_show_message("%s enjoyed the feed. Condition +20, affection +1." % horse.name)
	_refresh_all()

func _on_buy_feed_pressed() -> void:
	if state.coins < 50:
		_show_message("Not enough coins.")
		return

	state.coins -= 50
	state.feed += 1
	_show_message("Bought 1 feed for 50 coins.")
	_refresh_all()

func _on_race_pressed() -> void:
	var horse = _get_selected_horse()
	if horse == null:
		_show_message("Select a horse first.")
		return

	var result := racing_system.run_race(horse)
	state.coins += int(result["coins"])
	var place_text := "%d%s" % [int(result["place"]), _placement_suffix(int(result["place"]))]
	var message := "%s finished %s! Score %d, +%d coins, +%d exp." % [
		horse.name,
		place_text,
		int(result["score"]),
		int(result["coins"]),
		int(result["exp"])
	]
	if bool(result["leveled_up"]):
		message += " Level up!"

	_show_message(message)
	_refresh_all()

func _on_breed_pressed() -> void:
	if state.horses.size() < 2:
		_show_message("Need at least two horses to breed.")
		return
	if state.coins < breeding_system.BREED_COST:
		_show_message("Not enough coins to breed.")
		return

	state.coins -= breeding_system.BREED_COST
	var parent_a = state.horses[0]
	var parent_b = state.horses[1]
	var new_id := state.create_next_horse_id()
	var foal = breeding_system.create_foal(parent_a, parent_b, new_id, new_id)
	state.add_horse(foal)
	selected_horse_index = state.horses.size() - 1
	_show_message("A new foal was born: %s [%s]!" % [foal.name, foal.rarity])
	_refresh_all()

func _on_save_pressed() -> void:
	if save_system.save_game(state):
		_show_message("Game saved.")
	else:
		_show_message("Save failed.")

func _on_load_pressed() -> void:
	var loaded := save_system.load_game(state)
	selected_horse_index = 0
	_refresh_all()
	_show_message("Game loaded." if loaded else "No save file found. Started default ranch.")

func _get_selected_horse():
	return state.get_horse(selected_horse_index)

func _refresh_all() -> void:
	_refresh_stats()
	_refresh_horse_list()
	_refresh_detail()

func _refresh_stats() -> void:
	stats_label.text = "Coins: %d | Feed: %d" % [state.coins, state.feed]

func _refresh_horse_list() -> void:
	horse_list.clear()
	for horse in state.horses:
		horse_list.add_item(horse.get_display_name())

	if not state.horses.is_empty():
		selected_horse_index = clampi(selected_horse_index, 0, state.horses.size() - 1)
		horse_list.select(selected_horse_index)

func _refresh_detail() -> void:
	var horse = _get_selected_horse()
	if horse == null:
		detail_label.text = "No horse selected."
		horse_preview.color = Color(0.25, 0.25, 0.25)
		return

	horse_preview.color = _color_from_name(horse.color)
	var lines := PackedStringArray([
		"Name: %s" % horse.name,
		"ID: %d" % horse.id,
		"Rarity: %s" % horse.rarity,
		"Level: %d" % horse.level,
		"EXP: %d / 100" % horse.exp,
		"Speed: %d" % horse.speed,
		"Stamina: %d" % horse.stamina,
		"Luck: %d" % horse.luck,
		"Condition: %d / 100" % horse.condition,
		"Affection: %d" % horse.affection,
		"Color: %s" % horse.color,
		"Pattern: %s" % horse.pattern
	])
	detail_label.text = "\n".join(lines)

func _show_message(text: String) -> void:
	message_label.text = text

func _placement_suffix(place: int) -> String:
	if place == 1:
		return "st"
	if place == 2:
		return "nd"
	if place == 3:
		return "rd"
	return "th"

func _color_from_name(color_name: String) -> Color:
	match color_name:
		"brown":
			return Color(0.45, 0.25, 0.12)
		"white":
			return Color(0.92, 0.92, 0.86)
		"black":
			return Color(0.08, 0.08, 0.09)
		"gray":
			return Color(0.45, 0.47, 0.50)
		"gold":
			return Color(0.95, 0.67, 0.18)
		"chestnut":
			return Color(0.60, 0.24, 0.10)
		_:
			return Color(0.50, 0.35, 0.20)
