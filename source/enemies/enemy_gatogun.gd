extends "res://source/enemies/enemy.gd"

# === EXPORTS GENERALES ===
@export var medal: PackedScene = preload("res://scenes/items/medal.tscn")
@export var revengeBullet: PackedScene = preload("res://scenes/bullets/revenge_bullet.tscn")
@export var powerUp: PackedScene = preload("res://scenes/items/power_up.tscn")
@export var explosion: PackedScene = preload("res://scenes/vfx/explosion.tscn")
@export var comboLabel: RichTextLabel
@export var cutoff: float = 450.0

# === ESTADO INTERNO ===
var canDie := false
var canShoot := true
var health: float
var lastBullet
var pulseMarked := false
var byBomb := false
var halvedHealth := false
var emitter: Node2D = null
var enemType: String
var explScale: float

# === SHADER HIT ===
var _hit_tween: Tween
var _hit_material: ShaderMaterial

# === FLUJO DE COMPORTAMIENTO ===
func _ready() -> void:
	if $Emitter: emitter = $Emitter
	match typeEnum:
		EnemyType.STD:
			health = 16
			enemType = "STD"
			explScale = 1.25
		EnemyType.MID:
			health = 100
			enemType = "MID"
			explScale = 1.75
		EnemyType.ELITE:
			health = 160
			enemType = "ELITE"
			explScale = 2.5

	if isGround: $Hurtbox.add_to_group("Ground")
	else: $Hitbox.add_to_group("Damage")

	# Shader: guardar material y asignar offset aleatorio único por instancia
	_hit_material = $Sprite2D.material as ShaderMaterial
	if _hit_material:
		_hit_material = _hit_material.duplicate()                               # ← Clave: instancia propia del material
		$Sprite2D.material = _hit_material
		_hit_material.set_shader_parameter("time_offset", randf() * 100.0)

func _process(delta: float) -> void:
	_check_death()

	stageTimer += delta
	velocity = SCROLL.get_scroll() + extraVel if scrollFollow else extraVel
	if position.y > cutoff: canShoot = false

	# Charge
	var overlap = $Hurtbox.get_overlapping_areas()
	for a in overlap:
		if a.is_in_group("Charge"):
			pulseMarked = true
			health -= delta * a.damage

	# Vulnerabilidad post-1er disparo
	if emitter != null and !halvedHealth:
		match typeEnum:
			EnemyType.ELITE:
				if emitter.totalRounds == 2:
					health = health / 2
					halvedHealth = true
			_:
				if emitter.totalRounds == 1:
					health = health / 2
					halvedHealth = true

	match currentStage:
		"childhood":
			if stageTimer > childDuration: _change_stage("adulthood", adultInvert)
			else:
				speed = childSpeed
				apply_movement(childhood, childDuration, delta)
		"adulthood":
			if stageTimer > adultDuration: _change_stage("old_age", oldInvert)
			else:
				speed = adultSpeed
				apply_movement(adulthood, adultDuration, delta)
		"old_age":
			speed = oldSpeed
			apply_movement(oldAge, adultDuration, delta)

# === HIT FLASH ===
func trigger_hit_flash() -> void:
	if _hit_material == null:
		return
	if _hit_tween:
		_hit_tween.kill()

	_hit_material.set_shader_parameter("hit_effect", 1.0)

	_hit_tween = create_tween()
	_hit_tween.tween_method(
		func(val: float): _hit_material.set_shader_parameter("hit_effect", val),
		1.0, 0.0, 0.25
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

# === MUERTE Y RECOMPENSAS ===
func _check_death() -> void:
	if health > 0: return

	var explInstance = explosion.instantiate()
	explInstance.global_position = global_position
	explInstance.scale *= explScale
	GLOBAL.add_to_game(explInstance)

	SCORE.add_score(SCORE.combo)
	scoreCount += RANK.rank

	var playerPos = GAME.get_player()
	if pulseMarked: scoreCount *= 1.1
	if !byBomb and (position.distance_to(playerPos) < 250 or SCORE.medalCountdown > 0 or pulseMarked):
		_spawn_score(scoreCount, medal)
		if lastBullet and !SCORE.medalCountdown > 0 and !pulseMarked and !INPUT.fireHold:
			SCORE.medalCountdown = SCORE.MAX_MEDAL_COUNTDOWN
		elif lastBullet and !pulseMarked and !INPUT.fireHold: SCORE.medalCountdown += 0.1
	if (position.y < 300 or pulseMarked) and !byBomb: _spawn_score(scoreCount, revengeBullet)
	if typeEnum == EnemyType.MID and GAME.DollStyle != GAME.DollEnum.STRONG:
		_spawn_score(1, powerUp, true)

	if typeEnum == EnemyType.ELITE:
		for bullet in get_tree().get_nodes_in_group("Enemy Bullet"):
			if bullet.has_method("cancel"): bullet.cancel()

	if pulseMarked:
		SCORE.increase_hot(5)
		SCORE.increase_combo(100)

	if comboLabel: comboLabel.free_label(enemType)

	queue_free()

func _spawn_score(count: int, entity: PackedScene, center: bool = false) -> void:
	for i in count:
		var item = entity.instantiate()
		GLOBAL.add_to_game(item, true)
		var spawnOffset = Vector2(DRNG.drandf_range(-size, size), 0) if !center else Vector2(0, 0)
		item.position = global_position + spawnOffset

# === COLISIONES ===
func _on_hurtbox_area_entered(area: Node) -> void:
	if area.is_in_group("Fire"):
		if comboLabel: comboLabel.show_combo()
		if canDie: health -= area.damage
		lastBullet = area.BulletType == area.BulletEnum.BURST
		trigger_hit_flash()
	if area.is_in_group("Player") and isGround:
		canShoot = false
	if area.is_in_group("Bomb"):
		byBomb = true
		health -= area.damage

func _on_hurtbox_area_exited(area: Node) -> void:
	if area.is_in_group("Player") and isGround: canShoot = true
	if area.is_in_group("Pulse"): pulseMarked = false

func _on_hitbox_area_entered(area: Node) -> void:
	if area.is_in_group("Play"): canDie = true

func _on_hitbox_area_exited(area: Node) -> void:
	if area.is_in_group("Free"): queue_free()
