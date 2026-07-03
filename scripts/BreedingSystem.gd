extends RefCounted
class_name BreedingSystem

const HorseScript = preload("res://scripts/Horse.gd")

const BREED_COST := 150
const COLORS: Array[String] = ["brown", "white", "black", "gray", "gold", "chestnut"]
const PATTERNS: Array[String] = ["no pattern", "stripe", "spots", "star", "socks"]

var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

# The prototype uses the first two horses as parents. UI parent selection can be added later.
func create_foal(parent_a, parent_b, new_id: int, foal_number: int):
	var foal_name := "Foal%d" % foal_number
	var speed := _mixed_stat(parent_a.speed, parent_b.speed)
	var stamina := _mixed_stat(parent_a.stamina, parent_b.stamina)
	var luck := _mixed_stat(parent_a.luck, parent_b.luck)
	var color := _inherit_trait(parent_a.color, parent_b.color, COLORS, 0.15)
	var pattern := _inherit_trait(parent_a.pattern, parent_b.pattern, PATTERNS, 0.20)
	var rarity := _roll_rarity(parent_a.rarity, parent_b.rarity)

	return HorseScript.new(new_id, foal_name, 1, 0, speed, stamina, luck, 75, 0, color, pattern, rarity)

func _mixed_stat(a: int, b: int) -> int:
	var average := int(round((a + b) / 2.0))
	return max(1, average + rng.randi_range(-2, 2))

# Most foals inherit a parent trait; sometimes they mutate into a new color or pattern.
func _inherit_trait(a: String, b: String, options: Array[String], mutation_chance: float) -> String:
	if rng.randf() < mutation_chance:
		return options[rng.randi_range(0, options.size() - 1)]
	return a if rng.randf() < 0.5 else b

func _roll_rarity(rarity_a: String, rarity_b: String) -> String:
	var base_rank: int = max(HorseScript.RARITIES.find(rarity_a), HorseScript.RARITIES.find(rarity_b))
	base_rank = max(base_rank, 0)
	var roll := rng.randf()

	# Better parents raise the starting point; small chances can move rarity up or down.
	if roll < 0.08:
		base_rank += 2
	elif roll < 0.28:
		base_rank += 1
	elif roll > 0.90:
		base_rank -= 1

	return HorseScript.RARITIES[clampi(base_rank, 0, HorseScript.RARITIES.size() - 1)]
