# source/player/player.gd
extends CharacterBody2D

# ==============================================================================
# EXPORTS
# ==============================================================================

@export var sprite: Sprite2D
@export var bomb: PackedScene
@export var hitbox: Node2D

@export_category("Movement")
@export_range(150, 400, 50) var speed_focus: int = 200
@export_range(150, 400, 50) var speed_normal: int = 350
@export var screen_margin: int = 16

# ==============================================================================
# INTERNAL STATE
# ==============================================================================

var playable:           bool    = false
var can_die:            bool    = true
var shielded:           bool    = false
var bombCount:          int     = 2
var maxBombs:           int     = 4
var lastMoveDirection:  Vector2 = Vector2.DOWN

var _go_point:          Vector2 = Vector2.ZERO
var _shield_timer:      float   = 0.0

@onready var _hitbox_mat: ShaderMaterial = $HitboxIcon.material

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	add_to_group("Player")
	playable  = false
	_go_point = GAME.goPoint
	_setup_doll_style()
	EVENTS.player_spawned.emit(self)

func _exit_tree() -> void:
	CAMERA.tracked_nodes.erase(self)

# ==============================================================================
# DOLL SETUP
# ==============================================================================

func _setup_doll_style() -> void:
	match GAME.DollStyle:
		GAME.DollEnum.SPEED:
			maxBombs  = 4
			bombCount = 2
		GAME.DollEnum.STRONG:
			maxBombs  = 2
			bombCount = 1
		GAME.DollEnum.NEWBIE:
			maxBombs  = 6
			bombCount = 3
		GAME.DollEnum.CARAVAN:
			maxBombs  = 0
			bombCount = 0

# ==============================================================================
# MAIN LOOP
# ==============================================================================

func _process(delta: float) -> void:
	_tick_shield(delta)

	if playable:
		_handle_movement()
		_clamp_to_screen(get_viewport().get_visible_rect().size)
		_handle_bomb_input()
		_update_speed_by_style()
		_update_hitbox_visibility(delta)
	else:
		_auto_move_to_go_point()
		_ensure_shield_on_entry()

	var input_dir := Vector2(INPUT.xAxis, INPUT.yAxis).normalized()
	if input_dir.length_squared() > 0.01:
		lastMoveDirection = input_dir

	# Sync with GAME so HUD and other systems read current values
	GAME.bombCount = bombCount
	GAME.maxBombs  = maxBombs

# ==============================================================================
# MOVEMENT
# ==============================================================================

func _auto_move_to_go_point() -> void:
	var to_target := (_go_point - position).normalized()
	velocity = to_target * speed_normal
	move_and_slide()
	if position.distance_to(_go_point) < 5.0:
		playable = true

func _handle_movement() -> void:
	var dir := Vector2(INPUT.xAxis, INPUT.yAxis)
	velocity = dir.normalized() * _current_speed()
	move_and_slide()

func _current_speed() -> int:
	match GAME.DollStyle:
		GAME.DollEnum.SPEED, GAME.DollEnum.CARAVAN:
			return speed_focus if INPUT.fireHold else speed_normal
	return speed_focus if INPUT.fireHold else speed_normal

func _clamp_to_screen(screen_size: Vector2) -> void:
	position.x = clamp(position.x, screen_margin, screen_size.x - screen_margin)
	position.y = clamp(position.y, screen_margin, screen_size.y - screen_margin)

func _update_speed_by_style() -> void:
	# Speed and Caravan are faster when not focusing
	match GAME.DollStyle:
		GAME.DollEnum.SPEED, GAME.DollEnum.CARAVAN:
			speed_focus  = 200
			speed_normal = 350
		_:
			speed_focus  = 150
			speed_normal = 300

# ==============================================================================
# HITBOX ICON
# ==============================================================================

func _update_hitbox_visibility(delta: float) -> void:
	if _hitbox_mat == null: return
	var target := 1.0 if INPUT.fireHold else 0.0
	var current: float = _hitbox_mat.get_shader_parameter("visible_amount")
	_hitbox_mat.set_shader_parameter("visible_amount",
		move_toward(current, target, delta * 8.0))

# ==============================================================================
# BOMB
# ==============================================================================

func _handle_bomb_input() -> void:
	if Input.is_action_just_pressed("B") and bombCount > 0 and can_die: _use_bomb()

func _use_bomb() -> void:
	var b := bomb.instantiate()
	b.position = Vector2(340, 1200)
	b.set_dir(Vector2.UP, 0)
	GLOBAL.add_to_game(b, true)
	bombCount -= 1
	
	# Clear player bullets
	for bullet in get_tree().get_nodes_in_group("Fire"): bullet.queue_free()
	
	activate_shield(3.0)
	SCORE.reset()
	FLOW.miss()
	EVENTS.bomb_used.emit(global_position, bombCount)

# ==============================================================================
# SHIELD
# ==============================================================================

func _ensure_shield_on_entry() -> void:
	if not shielded:
		shielded = true
		activate_shield(2.5)

func activate_shield(duration: float) -> void:
	can_die       = false
	_shield_timer = duration
	if sprite: sprite.modulate = Color.RED
	EVENTS.shield_active.emit(true, duration)

func _tick_shield(delta: float) -> void:
	if _shield_timer <= 0.0: return
	_shield_timer -= delta
	
	if _shield_timer <= 0.0:
		can_die = true
		if sprite:
			sprite.visible  = true
			sprite.modulate = Color.GREEN
		EVENTS.shield_active.emit(false, 0.0)

# ==============================================================================
# COLLISION
# ==============================================================================

func _on_hurtbox_area_entered(area: Node) -> void:
	if not can_die: return
	if area.is_in_group("Damage"): _take_hit()

func _take_hit() -> void:
	FLOW.miss()
	if GAME.DollStyle == GAME.DollEnum.NEWBIE and bombCount > 0:
		_use_bomb()
		return
	GAME.lives  -= 1
	EVENTS.player_died.emit(global_position)
	EVENTS.lives_flow.emit(GAME.lives)
	GAME.store(global_position, false)
	for b in get_tree().get_nodes_in_group("Enemy Bullet"):
		if b.has_method("remove"): b.remove()
	queue_free()

func _on_hurtbox_area_exited(area: Node) -> void:
	if area.is_in_group("Ground"): area.get_parent().can_shoot = true
