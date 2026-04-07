# source/enemies/enemy_gatogun.gd
# Gatogun-specific enemy logic
extends BaseEnemy

# ==============================================================================
# EXPORTS
# ==============================================================================

## EnemyCombo label node. Assign in scene inspector.
@export var combo_label: RichTextLabel

# ==============================================================================
# INTERNAL STATE
# ==============================================================================

var _health:       float = 0.0
var _can_die:      bool  = false
var _can_shoot:    bool  = true
var _pulse_marked: bool  = false
var _by_bomb:      bool  = false
var _halved:       bool  = false
var _last_bullet:  bool  = false

var _emitter: BulletEmitter = null

var _hit_mat:   ShaderMaterial = null
var _hit_tween: Tween          = null

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _on_ready() -> void:
	if data == null:
		push_error("EnemyGatogun '%s': EnemyData not assigned." % name)
		return

	_health  = data.base_health
	_emitter = get_node_or_null("Emitter")

	$Hitbox.add_to_group("Damage")

	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite and sprite.material is ShaderMaterial:
		_hit_mat = (sprite.material as ShaderMaterial).duplicate()
		sprite.material = _hit_mat
		_hit_mat.set_shader_parameter("breath_seed", randf_range(0.0, 100.0))
		_hit_mat.set_shader_parameter("time_offset",  randf() * 100.0)

# ==============================================================================
# MAIN LOOP
# ==============================================================================

func _process(delta: float) -> void:
	if data == null:
		return

	tick_movement(delta)
	_check_cutoff()
	_check_charge_overlap(delta)
	_check_health_halving()

	if _hit_mat:
		_hit_mat.set_shader_parameter("custom_time",
			Time.get_ticks_msec() / 1000.0)

	_check_death()

# ==============================================================================
# COMBAT
# ==============================================================================

func _check_cutoff() -> void:
	if position.y > data.cutoff_y:
		_set_can_shoot(false)

func _check_charge_overlap(delta: float) -> void:
	for area in $Hurtbox.get_overlapping_areas():
		if area.is_in_group("Charge"):
			_pulse_marked = true
			_health -= delta * area.damage

func _check_health_halving() -> void:
	if _emitter == null or _halved:
		return
	if _emitter.total_rounds >= data.halving_trigger_round:
		_health *= 0.5
		_halved  = true

func _set_can_shoot(value: bool) -> void:
	_can_shoot = value
	if _emitter:
		_emitter.can_shoot = value

# ==============================================================================
# DEATH
# ==============================================================================

func _check_death() -> void:
	if _health > 0.0:
		return

	var score_f := float(data.score_count) + float(RANK.rank)
	if _pulse_marked:
		score_f *= 1.1

	var revenge := data.drops_revenge \
		and (position.y < 300.0 or _pulse_marked) \
		and not _by_bomb \
		and RANK.rank > 0

	EVENTS.enemy_killed.emit(EnemyKillData.new(
		EnemyData.EnemyType.keys()[data.enemy_type],
		global_position,
		data.explosion_scale,
		SCORE.combo,
		SCORE.mult,
		RANK.rank,
		int(score_f),
		_pulse_marked,
		_by_bomb,
		_last_bullet,
		not INPUT.fireHold,
		revenge,
		data.drops_powerup
	))

	if combo_label:
		combo_label.free_label(EnemyData.EnemyType.keys()[data.enemy_type])

	queue_free()

# ==============================================================================
# HIT FLASH
# ==============================================================================

func _trigger_hit_flash() -> void:
	if _hit_mat == null:
		return
	if _hit_tween:
		_hit_tween.kill()
	_hit_mat.set_shader_parameter("hit_effect", 1.0)
	_hit_tween = create_tween()
	_hit_tween.tween_method(
		func(v: float) -> void: _hit_mat.set_shader_parameter("hit_effect", v),
		1.0, 0.0, 0.25
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

# ==============================================================================
# AREA SIGNALS
# ==============================================================================

func _on_hurtbox_area_entered(area: Node) -> void:
	if area.is_in_group("Fire"):
		if combo_label:
			combo_label.show_combo()
		if _can_die:
			_health      -= area.damage
			_last_bullet  = (area.BulletType == area.BulletEnum.BURST)
		_trigger_hit_flash()

	if area.is_in_group("Bomb"):
		_by_bomb  = true
		_health  -= area.damage

func _on_hurtbox_area_exited(area: Node) -> void:
	if area.is_in_group("Pulse"):
		_pulse_marked = false

func _on_hitbox_area_entered(area: Node) -> void:
	if area.is_in_group("Play"):
		_can_die = true

func _on_hitbox_area_exited(area: Node) -> void:
	if area.is_in_group("Free"):
		queue_free()
