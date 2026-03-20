extends "res://source/enemies/enemy.gd"

# === EXPORTS ===
@export var medal:         PackedScene = preload("res://scenes/items/medal.tscn")
@export var revengeBullet: PackedScene = preload("res://scenes/bullets/revenge_bullet.tscn")
@export var powerUp:       PackedScene = preload("res://scenes/items/power_up.tscn")
@export var explosion:     PackedScene = preload("res://scenes/vfx/explosion.tscn")
@export var comboLabel:    RichTextLabel
@export var cutoff:        float = 450.0

const MEDAL_RANGE: float = 250.0

# === ESTADO INTERNO ===
var canDie:       bool  = false
var canShoot:     bool  = true
var health:       float = 0.0
var lastBullet:   bool  = false
var pulseMarked:  bool  = false
var byBomb:       bool  = false
var halvedHealth: bool  = false
var emitter:      Node2D = null
var enemType:     String = ""
var explScale:    float  = 1.0
# scoreCount se convierte en float porque se multiplica por 1.1 en muerte por pulse.
# El export original es int, lo promovemos a float aquí para evitar errores de tipado.
var _scoreCount_f: float = 0.0

# === SHADER HIT ===
var _hit_tween:    Tween          = null
var _hit_material: ShaderMaterial = null

# ─────────────────────────────────────────────
func _ready() -> void:
	# breath_seed es puramente visual: randf() nativo está bien (no afecta jugabilidad).
	$Sprite2D.material.set_shader_parameter("breath_seed", randf_range(0.0, 100.0))

	if $Emitter: emitter = $Emitter

	match typeEnum:
		EnemyType.STD:
			health    = 16.0
			enemType  = "STD"
			explScale = 1.5
		EnemyType.MID:
			health    = 100.0
			enemType  = "MID"
			explScale = 2
		EnemyType.ELITE:
			health    = 160.0
			enemType  = "ELITE"
			explScale = 2.75

	_scoreCount_f = float(scoreCount)

	if isGround: $Hurtbox.add_to_group("Ground")
	else:        $Hitbox.add_to_group("Damage")

	# Duplicar material para que cada enemigo tenga su propio estado de shader.
	_hit_material = $Sprite2D.material as ShaderMaterial
	if _hit_material:
		_hit_material = _hit_material.duplicate()
		$Sprite2D.material = _hit_material
		# time_offset también es visual; randf() nativo correcto.
		_hit_material.set_shader_parameter("time_offset", randf() * 100.0)

# ─────────────────────────────────────────────
func _process(delta: float) -> void:
	_check_death()

	stageTimer += delta

	# Scroll y extraVel se gestionan en enemy._smooth_move().
	# Aquí solo bloqueamos el disparo al salir de pantalla.
	if position.y > cutoff:
		canShoot = false

	# Actualizar tiempo del shader de hit.
	if _hit_material:
		_hit_material.set_shader_parameter("custom_time", Time.get_ticks_msec() / 1000.0)

	# Daño por Charge (área de carga del jugador).
	for a in $Hurtbox.get_overlapping_areas():
		if a.is_in_group("Charge"):
			pulseMarked = true
			health -= delta * a.damage

	# Vulnerabilidad post-1er disparo: reduce vida a la mitad una sola vez.
	if emitter != null and not halvedHealth:
		var trigger_round: int = 1 if typeEnum != EnemyType.ELITE else 2
		if emitter.totalRounds >= trigger_round:
			health       *= 0.5
			halvedHealth  = true

	# Fases de movimiento.
	match currentStage:
		"childhood":
			speed = childSpeed
			if stageTimer > childDuration:
				_change_stage("adulthood", adultInvert)
			else:
				apply_movement(childhood, childDuration, delta)
		"adulthood":
			speed = adultSpeed
			if stageTimer > adultDuration:
				_change_stage("old_age", oldInvert)
			else:
				apply_movement(adulthood, adultDuration, delta)
		"old_age":
			speed = oldSpeed
			apply_movement(oldAge, adultDuration, delta)

# ─────────────────────────────────────────────
# HIT FLASH
# ─────────────────────────────────────────────
func trigger_hit_flash() -> void:
	if _hit_material == null: return
	if _hit_tween: _hit_tween.kill()

	_hit_material.set_shader_parameter("hit_effect", 1.0)
	_hit_tween = create_tween()
	_hit_tween.tween_method(
		func(val: float): _hit_material.set_shader_parameter("hit_effect", val),
		1.0, 0.0, 0.25
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

# ─────────────────────────────────────────────
# MUERTE Y RECOMPENSAS
# ─────────────────────────────────────────────
func _check_death() -> void:
	if health > 0.0: return

	# Explosión visual.
	var expl := explosion.instantiate()
	expl.global_position = global_position
	expl.scale *= explScale
	GLOBAL.add_to_game(expl)

	# Puntuación base
	var scoreVal = SCORE.combo * SCORE.mult
	SCORE.add_score(SCORE.combo if scoreVal > 2000 else 2000)
	_scoreCount_f = float(scoreCount) + float(RANK.rank)
	if pulseMarked: _scoreCount_f *= 1.1

	var player_pos := GAME.get_player()
	var near_player := position.distance_to(player_pos) < MEDAL_RANGE
	var medal_active := SCORE.medalCountdown > 0.0

	# Medallas: solo si no fue bomba y el jugador está cerca, hay medallas activas o hay pulse.
	if not byBomb and (near_player or medal_active or pulseMarked):
		_spawn_score(int(_scoreCount_f), medal)

		if lastBullet and not pulseMarked and not INPUT.fireHold:
			if not medal_active:
				# Primer kill limpio: arranca el contador de medallas.
				SCORE.medalCountdown = SCORE.MAX_MEDAL_COUNTDOWN
			else:
				# Kill limpio encadenado: prolonga el contador.
				SCORE.medalCountdown += 0.1

	# Revenge bullets al morir cerca de la parte superior o con pulse.
	if (position.y < 300.0 or pulseMarked) and not byBomb and RANK.rank > 0:
		_spawn_score(int(_scoreCount_f), revengeBullet)

	# Power-up al matar un MID (excepto con estilo STRONG).
	if typeEnum == EnemyType.MID and GAME.DollStyle != GAME.DollEnum.STRONG:
		_spawn_score(1, powerUp, true)

	# Los ELITE cancelan todas las balas enemigas activas al morir.
	if typeEnum == EnemyType.ELITE:
		for bullet in get_tree().get_nodes_in_group("Enemy Bullet"):
			if bullet.has_method("cancel"): bullet.cancel()

	# Bonus por pulse.
	if pulseMarked:
		SCORE.increase_hot(5)
		SCORE.increase_combo(100)
	
	if SCORE.hot <= 50: SCORE.hot = 50

	if comboLabel: comboLabel.free_label(enemType)
	queue_free()

func _spawn_score(count: int, entity: PackedScene, center: bool = false) -> void:
	for i in count:
		var item := entity.instantiate()
		GLOBAL.add_to_game(item, true)
		var offset := Vector2.ZERO
		if not center:
			# DRNG para determinismo en replay: la posición del drop es gameplay.
			offset = Vector2(DRNG.drandf_range(-float(size), float(size)), 0.0)
		item.position = global_position + offset

# ─────────────────────────────────────────────
# COLISIONES
# ─────────────────────────────────────────────
func _on_hurtbox_area_entered(area: Node) -> void:
	if area.is_in_group("Fire"):
		if comboLabel: comboLabel.show_combo()
		if canDie: health -= area.damage
		lastBullet = (area.BulletType == area.BulletEnum.BURST)
		trigger_hit_flash()
	if area.is_in_group("Player") and isGround:
		canShoot = false
	if area.is_in_group("Bomb"):
		byBomb  = true
		health -= area.damage

func _on_hurtbox_area_exited(area: Node) -> void:
	if area.is_in_group("Player") and isGround: canShoot = true
	if area.is_in_group("Pulse"):               pulseMarked = false

func _on_hitbox_area_entered(area: Node) -> void:
	if area.is_in_group("Play"): canDie = true

func _on_hitbox_area_exited(area: Node) -> void:
	if area.is_in_group("Free"): queue_free()
