class_name ScoreKeeper
extends RefCounted
## Score for one run. Time is only one small factor: the score rewards finishing tasks, stopping
## sabotage, staying alive and staying healthy. Everything is shown to the player on the
## level-complete card, and the rank (S/A/B/C) comes from the share of the level's maximum.

const MULT := [1.0, 1.25, 1.5, 2.0] ## harder levels are worth more
const TASK_POINTS := 100
const FIX_POINTS := 150
const FIX_POINTS_BIG := 250
const FAIL_PENALTY := 100
const FAIL_PENALTY_BIG := 200
const DISRUPT_PENALTY := 50
const HEART_POINTS := 100
const NO_DEATH_BONUS := 300
const DEATH_PENALTY := 250
const TIME_BONUS_MAX := 300 ## only for finishing under par, and never a penalty for being slow

var level_totals: Array[int] = []
var level_ranks: Array[String] = []
var total := 0

var fixed := 0
var fixed_big := 0
var failed := 0
var failed_big := 0
var disrupts := 0
var deaths := 0


func new_run() -> void:
	level_totals.clear()
	level_ranks.clear()
	total = 0
	_clear_events()
	deaths = 0


func _clear_events() -> void:
	fixed = 0
	fixed_big = 0
	failed = 0
	failed_big = 0
	disrupts = 0


## retry = the level restarted after a death: events are replaced, deaths are remembered.
func start_level(retry: bool) -> void:
	_clear_events()
	if not retry:
		deaths = 0


func on_fixed(big: bool) -> void:
	if big:
		fixed_big += 1
	else:
		fixed += 1


func on_failed(big: bool) -> void:
	if big:
		failed_big += 1
	else:
		failed += 1


func on_disrupted() -> void:
	disrupts += 1


func on_death() -> void:
	deaths += 1


func mult(level: int) -> float:
	return MULT[clampi(level, 0, MULT.size() - 1)]


## Running score for the HUD (this level so far plus finished levels).
func live(level: int, tasks_done: int) -> int:
	return total + _events_points() + int(tasks_done * TASK_POINTS * mult(level))


func _events_points() -> int:
	return fixed * FIX_POINTS + fixed_big * FIX_POINTS_BIG - failed * FAIL_PENALTY - failed_big * FAIL_PENALTY_BIG - disrupts * DISRUPT_PENALTY - deaths * DEATH_PENALTY


## Final score of a level. sabotages = list of "big" flags for every sabotage the level could throw.
func finish_level(level: int, tasks_total: int, seconds: float, par: int, hearts: int, max_hearts: int, sabotages: Array) -> Dictionary:
	var m := mult(level)
	var lines: Array = []
	var pts := 0
	var task_pts := int(tasks_total * TASK_POINTS * m)
	lines.append(["Tasks finished (%d)" % tasks_total, task_pts])
	pts += task_pts
	if fixed + fixed_big > 0:
		var v := fixed * FIX_POINTS + fixed_big * FIX_POINTS_BIG
		lines.append(["Sabotage stopped in time (%d)" % (fixed + fixed_big), v])
		pts += v
	if failed + failed_big > 0:
		var v := -(failed * FAIL_PENALTY + failed_big * FAIL_PENALTY_BIG)
		lines.append(["Sabotage that hit you (%d)" % (failed + failed_big), v])
		pts += v
	if disrupts > 0:
		lines.append(["Tasks tampered with (%d)" % disrupts, -disrupts * DISRUPT_PENALTY])
		pts -= disrupts * DISRUPT_PENALTY
	var heart_pts := hearts * HEART_POINTS
	lines.append(["Hearts left (%d)" % hearts, heart_pts])
	pts += heart_pts
	if deaths == 0:
		lines.append(["No deaths", NO_DEATH_BONUS])
		pts += NO_DEATH_BONUS
	else:
		lines.append(["Deaths (%d)" % deaths, -deaths * DEATH_PENALTY])
		pts -= deaths * DEATH_PENALTY
	var time_pts := 0
	if par > 0 and seconds < par:
		time_pts = int(TIME_BONUS_MAX * (par - seconds) / float(par))
		lines.append(["Under par time", time_pts])
		pts += time_pts
	# the best possible score of this level, for the rank
	var best := task_pts + max_hearts * HEART_POINTS + NO_DEATH_BONUS + TIME_BONUS_MAX
	for big in sabotages:
		best += FIX_POINTS_BIG if big else FIX_POINTS
	pts = maxi(pts, 0)
	var ratio := float(pts) / float(maxi(best, 1))
	var rank := "C"
	if ratio >= 0.85:
		rank = "S"
	elif ratio >= 0.68:
		rank = "A"
	elif ratio >= 0.45:
		rank = "B"
	total += pts
	level_totals.append(pts)
	level_ranks.append(rank)
	return {"lines": lines, "score": pts, "rank": rank, "best": best}


## Overall rank from the average of the per-level ranks.
func overall_rank() -> String:
	if level_ranks.is_empty():
		return "C"
	var v := 0.0
	for r in level_ranks:
		v += {"S": 4.0, "A": 3.0, "B": 2.0, "C": 1.0}[r]
	v /= level_ranks.size()
	if v >= 3.6:
		return "S"
	if v >= 2.6:
		return "A"
	if v >= 1.6:
		return "B"
	return "C"
