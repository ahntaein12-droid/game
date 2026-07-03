extends RefCounted
class_name RacingSystem

var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

# Calculates one automatic race and applies exp/condition changes to the horse.
func run_race(horse) -> Dictionary:
	var condition_bonus := int(horse.condition / 10.0)
	var score: int = horse.speed * 2 + horse.stamina + horse.luck + rng.randi_range(0, 20) + condition_bonus
	var place := _score_to_place(score)
	var reward := _reward_for_place(place)

	horse.condition = max(0, horse.condition - 15)
	var leveled_up: bool = horse.add_exp(int(reward["exp"]), rng)

	return {
		"score": score,
		"place": place,
		"coins": int(reward["coins"]),
		"exp": int(reward["exp"]),
		"leveled_up": leveled_up
	}

func _score_to_place(score: int) -> int:
	if score >= 38:
		return 1
	if score >= 30:
		return 2
	if score >= 22:
		return 3
	return 4

func _reward_for_place(place: int) -> Dictionary:
	match place:
		1:
			return {"coins": 200, "exp": 30}
		2:
			return {"coins": 120, "exp": 20}
		3:
			return {"coins": 70, "exp": 10}
		_:
			return {"coins": 30, "exp": 5}
