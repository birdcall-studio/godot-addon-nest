extends "res://tests/support/test_case.gd"
## Sample tests. To add your own, copy this file to tests/test_<area>.gd.

const Dice := preload("res://addons/my_addon/core/dice.gd")


func test_roll_returns_requested_count() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	check(Dice.roll(rng, 6, 4).size() == 4, "should roll 4 dice")


func test_roll_stays_in_range() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for value: int in Dice.roll(rng, 6, 200):
		check(value >= 1 and value <= 6, "die out of range: %d" % value)


func test_same_seed_gives_same_roll() -> void:
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 42
	b.seed = 42
	check(Dice.roll(a, 6, 5) == Dice.roll(b, 6, 5), "same seed should repeat")
