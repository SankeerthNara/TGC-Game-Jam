extends SceneTree
## Headless model and beam solver checks.
## Run from the repository root with:
##   godot --headless --path new-game-project --script res://tests/model_solver_test.gd

var failures: Array[String] = []


func _init() -> void:
	_test_reflection_tables()
	_test_lying_rule()
	_test_bend_rule()
	_test_panel_swaps()
	_test_target_status_and_flip()
	if failures.is_empty():
		print("MODEL/SOLVER TESTS: OK")
	else:
		for failure in failures:
			push_error(failure)
		print("MODEL/SOLVER TESTS: FAILED (%d)" % failures.size())
	quit(1 if not failures.is_empty() else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _model(cells: Array[String], panel_size: Vector2i, layout: Vector2i, rule := "normal") -> PageModel:
	return PageModel.from_data({
		"panel_size": [panel_size.x, panel_size.y],
		"layout": [layout.x, layout.y],
		"rule": rule,
		"cells": cells,
	})


func _test_reflection_tables() -> void:
	var m := _model(["."], Vector2i(1, 1), Vector2i(1, 1))
	for direction in 4:
		_check(BeamSolver.reflect(m, PageModel.Kind.MIRROR_SLASH, direction) == BeamSolver.SLASH_REFLECT[direction], "slash reflection direction %d" % direction)
		_check(BeamSolver.reflect(m, PageModel.Kind.MIRROR_BACK, direction) == BeamSolver.BACK_REFLECT[direction], "backslash reflection direction %d" % direction)


func _test_lying_rule() -> void:
	var m := _model(["."], Vector2i(1, 1), Vector2i(1, 1), "lying")
	for direction in 4:
		_check(BeamSolver.reflect(m, PageModel.Kind.MIRROR_SLASH, direction) == BeamSolver.BACK_REFLECT[direction], "lying rule reverses slash at direction %d" % direction)
		_check(BeamSolver.reflect(m, PageModel.Kind.MIRROR_BACK, direction) == BeamSolver.SLASH_REFLECT[direction], "lying rule reverses backslash at direction %d" % direction)


func _test_bend_rule() -> void:
	var m := _model([">...", "..T."], Vector2i(2, 2), Vector2i(2, 1), "bend")
	var bend_trace := BeamSolver.trace(m)
	_check(bend_trace["lit"].has(m.index_of(Vector2i(2, 1))), "bend turns clockwise after crossing into a panel")
	m.rule = PageModel.Rule.NORMAL
	var normal_trace := BeamSolver.trace(m)
	_check(not normal_trace["lit"].has(m.index_of(Vector2i(2, 1))), "normal rule does not bend at a panel boundary")


func _test_panel_swaps() -> void:
	var m := _model([">..v", "T..X"], Vector2i(2, 2), Vector2i(2, 1))
	var before_a := m.panel_origin(0)
	var before_b := m.panel_origin(1)
	var kind_a := m.kind[m.index_of(before_a)]
	var dir_a := m.dir[m.index_of(before_a)]
	var kind_b := m.kind[m.index_of(before_b)]
	var dir_b := m.dir[m.index_of(before_b)]
	_check(m.swap_panels(0, 1), "unlocked distinct panels swap")
	_check(m.kind[m.index_of(before_a)] == kind_b and m.dir[m.index_of(before_a)] == dir_b, "swap moves panel cell kinds and emitter directions")
	_check(m.kind[m.index_of(before_b)] == kind_a and m.dir[m.index_of(before_b)] == dir_a, "swap moves both panels")
	_check(m.moves == 1, "successful panel swap increments move count")
	_check(not m.swap_panels(0, 0), "same-panel swap is rejected")
	m.locked.append(1)
	_check(not m.swap_panels(0, 1), "swap with a locked panel is rejected")
	_check(m.moves == 1, "rejected swaps do not increment move count")


func _test_target_status_and_flip() -> void:
	var m := _model(["T.X"], Vector2i(3, 1), Vector2i(1, 1))
	var lit_good := {0: true}
	var before := m.status({"lit": lit_good})
	_check(before["good_total"] == 1 and before["good_lit"] == 1 and before["bad_lit"] == 0 and before["solved"], "lit good target with unlit bad target solves the page")
	m.flipped = true
	var after := m.status({"lit": lit_good})
	_check(after["good_total"] == 1 and after["good_lit"] == 0 and after["bad_lit"] == 1 and not after["solved"], "target flip swaps good and bad status")
