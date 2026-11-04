extends RefCounted
## Sample runtime code. Replace it with your add-on's own logic.
## Functions that take the random number generator as an argument are easy to
## test from the command line.


## Roll `count` dice with `sides` sides each.
static func roll(rng: RandomNumberGenerator, sides: int, count: int) -> Array[int]:
	var results: Array[int] = []
	for _i: int in count:
		results.append(rng.randi_range(1, sides))
	return results
