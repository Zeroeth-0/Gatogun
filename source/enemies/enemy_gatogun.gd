# source/enemies/enemy_gatogun.gd
# Gatogun-specific enemy logic
extends BaseEnemy

# ==============================================================================
# EXPORTS
# ==============================================================================

## EnemyCombo label node. Assign in scene inspector.
@export var combo_label: RichTextLabel

## Tiempo de enfriamiento (cooldown) que debe pasar desde que salta "damage" 
## hasta que pueda volver a reaccionar a otro impacto.
@export var damage_cooldown: float = 0.5

# ==============================================================================
# INTERNAL STATE
# ==============================================================================

var _health:        float = 0.0
var _can_die:       bool  = false
var _can_shoot:     bool  = true
var _pulse_marked: bool  = false
var _by_bomb:       bool  = false
var _halved:        bool  = false
var _last_bullet:   bool  = false
var explosion_scale: float = 1.5
var score_count: float = 5.0
var spread: float = 20.0

var _emitter: BulletEmitter = null

var _hit_mat:   ShaderMaterial = null
var _hit_tween: Tween          = null

# === NODOS DE ANIMACIÓN Y COOLDOWN ===
@onready var _anim_player: AnimationPlayer = $Sprite2D/AnimationPlayer
var _damage_cd_timer: float = 0.0

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _on_ready() -> void:
	if data == null:
		push_error("EnemyGatogun '%s': EnemyData not assigned." % name)
		return
	
	match data.enemy_type:
		EnemyData.EnemyType.STD:
			_health = 16.0
			explosion_scale = 1.5
			score_count = 3.0
			spread = 50.0
		EnemyData.EnemyType.MID:
			_health = 100.0
			explosion_scale = 2.0
			score_count = 5.0
			spread = 80.0
		EnemyData.EnemyType.ELITE:
			_health = 160.0
			explosion_scale = 2.75
			score_count = 10.0
			spread = 100.0
	_emitter = get_node_or_null("Emitter")

	$Hitbox.add_to_group("Damage")

	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite and sprite.material is ShaderMaterial:
		_hit_mat = (sprite.material as ShaderMaterial).duplicate()
		sprite.material = _hit_mat
		_hit_mat.set_shader_parameter("breath_seed", randf_range(0.0, 100.0))
		_hit_mat.set_shader_parameter("time_offset",  randf() * 100.0)

	# Iniciar animación idle (direccional o genérica) y conectar señal
	if _anim_player:
		_play_anim("idle")
		
		# Conectamos la señal de fin de animación para regresar a "idle" de forma limpia
		if not _anim_player.animation_finished.is_connected(_on_animation_finished):
			_anim_player.animation_finished.connect(_on_animation_finished)

# ==============================================================================
# MAIN LOOP
# ==============================================================================

func _physics_process(_delta: float) -> void:
	if data == null:
		return

	tick_movement(GLOBAL.TICK)
	_check_cutoff()
	_check_charge_overlap(GLOBAL.TICK)
	_check_health_halving()

	# Consumir el cooldown de la animación de daño
	if _damage_cd_timer > 0.0:
		_damage_cd_timer -= GLOBAL.TICK
		if _damage_cd_timer < 0.0:
			_damage_cd_timer = 0.0

	if _hit_mat:
		_hit_mat.set_shader_parameter("custom_time", Time.get_ticks_msec() / 1000.0)

	_check_death()

# ==============================================================================
# ANIMATION HELPER & COOLDOWN SYSTEM
# ==============================================================================

## Obtiene el nombre real de la animación disponible buscando primero 
## la variante con sufijo (_left / _right) según handedness, y si no existe, la base.
func _get_anim_name(base_name: String) -> String:
	if _anim_player == null:
		return ""
	
	# 1. Intentar encontrar variante direccional (ej. "idle_left" o "damage_right")
	var suffix := "_left" if handedness == Handedness.LEFT else "_right"
	var directional_anim := base_name + suffix
	if _anim_player.has_animation(directional_anim):
		print("hey")
		return directional_anim

	# 2. Si no existe, recurrir a la animación estándar (ej. "idle" o "damage")
	if _anim_player.has_animation(base_name):
		return base_name

	return ""

## Reproduce la animación adaptada
func _play_anim(base_name: String) -> void:
	var anim := _get_anim_name(base_name)
	if not anim.is_empty():
		_anim_player.play(anim)

func _trigger_damage_animation() -> void:
	if _anim_player == null:
		return
	
	var damage_anim := _get_anim_name("damage")
	if damage_anim.is_empty():
		return
	
	# Si aún está en cooldown, ignoramos el impacto visual
	if _damage_cd_timer > 0.0:
		return
	
	# Reproducir animación de daño e iniciar el cooldown
	_anim_player.play(damage_anim)
	_damage_cd_timer = damage_cooldown

func _on_animation_finished(anim_name: StringName) -> void:
	# Cuando finalice cualquier animación de daño ("damage", "damage_left", "damage_right"),
	# volvemos al estado idle correspondiente
	if anim_name.begins_with("damage"):
		_play_anim("idle")

# ==============================================================================
# COMBAT
# ==============================================================================

func _check_cutoff() -> void:
	if position.y > data.cutoff_y:
		_set_can_shoot(false)

func _check_charge_overlap(tick: float) -> void:
	if not has_node("Hurtbox"): return
	for area in $Hurtbox.get_overlapping_areas():
		if area.is_in_group("Charge"):
			_pulse_marked = true
			_health -= tick * area.get("damage")
			_trigger_hit_flash()
			_trigger_damage_animation()

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

	var score_f := float(score_count)
	if _pulse_marked:
		score_f *= 1.1

	var revenge = data.drops_revenge \
		and (position.y < 300.0 or _pulse_marked) \
		and not _by_bomb \
		and GAME.DollStyle == GAME.DollEnum.SCORE

	EVENTS.enemy_killed.emit(EnemyKillData.new(
		EnemyData.EnemyType.keys()[data.enemy_type],
		global_position,
		explosion_scale,
		SCORE.combo,
		SCORE.mult,
		int(score_f),
		_pulse_marked,
		_by_bomb,
		_last_bullet,
		not INPUT.fireHold,
		revenge,
		data.drops_powerup,
		spread
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
			var dmg: float = area.get("damage") if "damage" in area else 1.0
			_health -= dmg
			
			if "BulletType" in area and "BulletEnum" in area:
				_last_bullet = (area.BulletType == area.BulletEnum.BURST)
			else:
				_last_bullet = false
				
		_trigger_hit_flash()
		_trigger_damage_animation()

	if area.is_in_group("Bomb"):
		_by_bomb  = true
		var dmg: float = area.get("damage") if "damage" in area else 200.0
		_health  -= dmg
		_trigger_damage_animation()

func _on_hurtbox_area_exited(area: Node) -> void:
	if area.is_in_group("Pulse"):
		_pulse_marked = false

func _on_hitbox_area_entered(area: Node) -> void:
	if area.is_in_group("Play"):
		_can_die = true

func _on_hitbox_area_exited(area: Node) -> void:
	if area.is_in_group("Free"):
		queue_free()
