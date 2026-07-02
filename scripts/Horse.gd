extends RefCounted
class_name Horse

const RARITIES: Array[String] = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]

var id: int
var name: String
var level: int
var exp: int
var speed: int
var stamina: int
var luck: int
var condition: int
var affection: int
var color: String
var pattern: String
var rarity: String

# Horse is a plain data object. Systems change this data, and SaveSystem writes it to JSON.
func _init(
	_id: int = 0,
	_name: String = "Horse",
	_level: int = 1,
	_exp: int = 0,
	_speed: int = 5,
	_stamina: int = 5,
	_luck: int = 5,
	_condition: int = 80,
	_affection: int = 0,
	_color: String = "brown",
	_pattern: String = "no pattern",
	_rarity: String = "Common"
) -> void:
	id = _id
	name = _name
	level = _level
	exp = _exp
	speed = _speed
	stamina = _stamina
	luck = _luck
	condition = clampi(_condition, 0, 100)
	affection = _affection
	color = _color
	pattern = _pattern
	rarity = _rarity

func feed() -> void:
	condition = clampi(condition + 20, 0, 100)
	affection += 1

# Returns true when the horse levels up. The caller can use that for a message.
func add_exp(amount: int, rng: RandomNumberGenerator) -> bool:
	exp += amount
	if exp < 100:
		return false

	level += 1
	exp = 0
	var stat_index := rng.randi_range(0, 2)
	if stat_index == 0:
		speed += 1
	elif stat_index == 1:
		stamina += 1
	else:
		luck += 1
	return true

func get_display_name() -> String:
	return "%s Lv.%d [%s]" % [name, level, rarity]

func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"level": level,
		"exp": exp,
		"speed": speed,
		"stamina": stamina,
		"luck": luck,
		"condition": condition,
		"affection": affection,
		"color": color,
		"pattern": pattern,
		"rarity": rarity
	}

# JSON data comes back as a Dictionary, so this rebuilds a Horse instance from it.
static func from_dictionary(data: Dictionary) -> Horse:
	return Horse.new(
		int(data.get("id", 0)),
		str(data.get("name", "Horse")),
		int(data.get("level", 1)),
		int(data.get("exp", 0)),
		int(data.get("speed", 5)),
		int(data.get("stamina", 5)),
		int(data.get("luck", 5)),
		int(data.get("condition", 80)),
		int(data.get("affection", 0)),
		str(data.get("color", "brown")),
		str(data.get("pattern", "no pattern")),
		str(data.get("rarity", "Common"))
	)
