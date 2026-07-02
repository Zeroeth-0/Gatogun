# flow_manager.gd
# Autoload como: FLOW
extends Node

# ═══════════════════════════════════════════════════════════════════════
#  DEFINICIÓN DE NIVELES
# ═══════════════════════════════════════════════════════════════════════
const LEVELS: Array[Dictionary] = [
	{
		"scene_key":        "LEVEL_1",
		"level_name":       "STAGE 1",
		"wave_file":        "res://source/levels/test.txt",
		"midboss_path":     "",
		"boss_path":        "",
		"secret_boss_path": "",
	},
]

const CARAVAN_LEVEL: Dictionary = {
	"scene_key":        "CARAVAN",
	"level_name":       "CARAVAN",
	"wave_file":        "res://source/levels/caravan_test.txt",
	"midboss_path":     "",
	"boss_path":        "",
	"secret_boss_path": "",
}

const UI_SCENES: Dictionary = {
	"READY":      "res://scenes/UI/ready_label.tscn",
	"WARNING":    "",
	"BONUS":      "res://scenes/UI/bonus.tscn",
	"GAME_CLEAR": "",
}

var isCaravan: bool = false
var inCaravan: bool = false

# ═══════════════════════════════════════════════════════════════════════
#  FASES
# ═══════════════════════════════════════════════════════════════════════
enum Phase {
	IDLE, READY, INTRO, SECTION_A, MIDBOSS,
	SECTION_B, WARNING, BOSS, SECRET_BOSS,
	BONUS, TRANSITION, GAME_CLEAR
}

# ═══════════════════════════════════════════════════════════════════════
#  SEÑALES
# ═══════════════════════════════════════════════════════════════════════
signal phase_changed(phase: Phase)
signal resume_parsing
signal boss_spawned(boss, boss_type: String)
signal boss_bar_hide()

signal _marker_received(name: String)
signal _boss_died(boss_type: String)
signal _ui_dismissed(ui_id: String)

# ═══════════════════════════════════════════════════════════════════════
#  ESTADO INTERNO
# ═══════════════════════════════════════════════════════════════════════
var current_phase: Phase = Phase.IDLE
var current_level_index: int = 0
var _is_first_level: bool = false
var _secret_unlocked: bool = false
var _generation: int = 0

var medal_counter: int = 0
var missed: bool = false

# ═══════════════════════════════════════════════════════════════════════
#  API PÚBLICA
# ═══════════════════════════════════════════════════════════════════════
func begin_game() -> void:
	isCaravan           = false
	inCaravan           = false
	current_level_index = 0
	_is_first_level     = true
	_secret_unlocked    = false
	GAME.store(Vector2(10000, 10000), false)
	_load_level(0)

func begin_caravan() -> void:
	isCaravan           = true
	inCaravan           = true
	current_level_index = 0
	_is_first_level     = false
	_secret_unlocked    = false
	GAME.store(Vector2(10000, 10000), false)
	_load_caravan()

func unlock_secret() -> void:
	_secret_unlocked = true

func notify_marker(name: String) -> void:
	_marker_received.emit(name.to_upper().strip_edges())

func notify_boss_dead(boss_type: String) -> void:
	_boss_died.emit(boss_type.to_upper())

func notify_ui_done(ui_id: String) -> void:
	_ui_dismissed.emit(ui_id.to_upper())

func increase_medal_count() -> void:
	medal_counter += 1

func miss() -> void:
	missed = true

func restart_level() -> void:
	GAME.inGame      = false
	SCORE.reset()
	SCORE.reset_game_score()
	GAME.store(Vector2(10000, 10000), false)
	if isCaravan:
		_load_caravan()
	else:
		if current_level_index == 0: _is_first_level = true
		_load_level(current_level_index)

# ═══════════════════════════════════════════════════════════════════════
#  FLUJO PRINCIPAL
# ═══════════════════════════════════════════════════════════════════════
func _load_level(index: int) -> void:
	_generation += 1
	GLOBAL.change_scene(LEVELS[index].scene_key)

func _load_caravan() -> void:
	_generation += 1
	GLOBAL.change_scene(CARAVAN_LEVEL.scene_key)

func _on_parser_ready(parser: Node) -> void:
	await get_tree().process_frame
	if isCaravan:
		_run_caravan_data(CARAVAN_LEVEL, parser, _generation)
	else:
		_run_level(current_level_index, parser, _generation)

func _run_level(index: int, parser: Node, gen: int) -> void:
	_run_level_data(LEVELS[index], parser, gen)

func _run_level_data(data: Dictionary, parser: Node, gen: int) -> void:
	medal_counter = 0
	missed        = false

	# ── READY ──────────────────────────────────────────────────────────
	if _is_first_level:
		_set_phase(Phase.READY)
		await _show_ui("READY")
		if gen != _generation: return
		_is_first_level = false

	# ── INTRO ──────────────────────────────────────────────────────────
	_set_phase(Phase.INTRO)
	_show_stage_banner(data.level_name)
	GAME.spawn()
	if not is_instance_valid(parser):
		return
	parser.begin(data.wave_file)
	await _wait_for_marker("INTRO_END")
	if gen != _generation: return

	# ── SECCIÓN A ──────────────────────────────────────────────────────
	_set_phase(Phase.SECTION_A)
	await get_tree().process_frame
	if gen != _generation: return
	resume_parsing.emit()
	await _wait_for_marker("MIDBOSS")
	if gen != _generation: return

	# ── MIDBOSS ────────────────────────────────────────────────────────
	_set_phase(Phase.MIDBOSS)
	if data.midboss_path != "":
		_spawn_boss(data.midboss_path, "MIDBOSS")
		await _wait_for_boss_dead("MIDBOSS")
		if gen != _generation: return
		boss_bar_hide.emit()
	else:
		await _stub_boss("MIDBOSS")
		if gen != _generation: return
	await get_tree().process_frame
	if gen != _generation: return
	resume_parsing.emit()

	# ── SECCIÓN B ──────────────────────────────────────────────────────
	_set_phase(Phase.SECTION_B)
	await _wait_for_marker("BOSS")
	if gen != _generation: return

	# ── WARNING ────────────────────────────────────────────────────────
	_set_phase(Phase.WARNING)
	await _show_ui("WARNING")
	if gen != _generation: return

	# ── BOSS ───────────────────────────────────────────────────────────
	_set_phase(Phase.BOSS)
	if data.boss_path != "":
		_spawn_boss(data.boss_path, "BOSS")
		await _wait_for_boss_dead("BOSS")
		if gen != _generation: return
		boss_bar_hide.emit()
	else:
		await _stub_boss("BOSS")
		if gen != _generation: return

	# ── JEFE SECRETO ───────────────────────────────────────────────────
	if current_level_index == LEVELS.size() - 1 \
			and _secret_unlocked and data.secret_boss_path != "":
		_set_phase(Phase.SECRET_BOSS)
		_spawn_boss(data.secret_boss_path, "SECRET")
		await _wait_for_boss_dead("SECRET")
		if gen != _generation: return
		boss_bar_hide.emit()

	# ── BONUS ──────────────────────────────────────────────────────────
	_set_phase(Phase.BONUS)
	await _show_ui("BONUS")
	if gen != _generation: return

	# ── SIGUIENTE NIVEL O FIN ──────────────────────────────────────────
	if current_level_index < LEVELS.size() - 1:
		_set_phase(Phase.TRANSITION)
		await get_tree().create_timer(1.5).timeout
		if gen != _generation: return
		current_level_index += 1
		_load_level(current_level_index)
	else:
		_set_phase(Phase.GAME_CLEAR)
		await _show_ui("GAME_CLEAR")
		if gen != _generation: return
		_end_game()

func _run_caravan_data(data: Dictionary, parser: Node, gen: int) -> void:
	medal_counter = 0
	missed        = false

	# ── INTRO ──────────────────────────────────────────────────────────
	_set_phase(Phase.INTRO)
	_show_stage_banner(data.level_name)
	GAME.spawn()
	if not is_instance_valid(parser):
		return
	parser.begin(data.wave_file)
	await _wait_for_marker("INTRO_END")
	if gen != _generation: return

	# ── SECCIÓN ÚNICA ──────────────────────────────────────────────────
	_set_phase(Phase.SECTION_A)
	await get_tree().process_frame
	if gen != _generation: return
	resume_parsing.emit()
	await _wait_for_marker("LEVEL_END")
	if gen != _generation: return

	# ── BONUS Y FIN ────────────────────────────────────────────────────
	_set_phase(Phase.BONUS)
	await _show_ui("BONUS")
	if gen != _generation: return

	_set_phase(Phase.GAME_CLEAR)
	await _show_ui("GAME_CLEAR")
	if gen != _generation: return
	_end_game()

# ═══════════════════════════════════════════════════════════════════════
#  HELPERS DE ESPERA
# ═══════════════════════════════════════════════════════════════════════
func _wait_for_marker(name: String) -> void:
	while true:
		var received: String = await _marker_received
		if received == name: return

func _wait_for_boss_dead(boss_type: String) -> void:
	while true:
		var received: String = await _boss_died
		if received == boss_type: return

func _wait_for_ui(ui_id: String) -> void:
	while true:
		var received: String = await _ui_dismissed
		if received == ui_id: return

# ═══════════════════════════════════════════════════════════════════════
#  HELPERS DE JUEGO
# ═══════════════════════════════════════════════════════════════════════
func _set_phase(p: Phase) -> void:
	current_phase = p
	phase_changed.emit(p)
	print("═══ FASE: ", Phase.keys()[p], " ═══")

func _spawn_boss(path: String, boss_type: String) -> void:
	var scene: PackedScene = load(path)
	var boss = scene.instantiate()
	boss.set_meta("boss_type", boss_type)
	GLOBAL.add_to_game(boss)
	boss_spawned.emit(boss, boss_type)

func _show_stage_banner(level_name: String) -> void:
	print(">>> BANNER: ", level_name)

func _show_ui(ui_id: String) -> void:
	var path: String = UI_SCENES.get(ui_id, "")
	if path == "":
		print(">>> UI (stub): ", ui_id, " — sin escena, continuando...")
		return
	var scene: PackedScene = load(path)
	if not scene:
		push_error("FLOW: no se pudo cargar la escena UI: " + path)
		return
	var ui = scene.instantiate()
	GLOBAL.add_to_game(ui)
	await _wait_for_ui(ui_id)

func _end_game() -> void:
	pass

# ═══════════════════════════════════════════════════════════════════════
#  STUBS DE TEST — BORRAR BLOQUE ENTERO EN PRODUCCIÓN
# ═══════════════════════════════════════════════════════════════════════
func _stub_boss(boss_type: String) -> void:
	print(">>> BOSS (stub): ", boss_type, " — simulando muerte en 3s")
	await get_tree().create_timer(3.0).timeout
	notify_boss_dead(boss_type)
