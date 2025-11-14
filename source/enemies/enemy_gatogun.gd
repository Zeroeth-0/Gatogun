extends "res://source/enemies/enemy.gd"

# === EXPORTS GENERALES ===
@export var medal: PackedScene = preload("res://scenes/items/medal.tscn")                           # Medalla que recompensa
@export var revengeBullet: PackedScene = preload("res://scenes/bullets/revenge_bullet.tscn")        # Balas que devuelve
@export var powerUp: PackedScene = preload("res://scenes/items/power_up.tscn")                      # Potenciador que recompensa
@export var comboLabel: RichTextLabel                                           # Etiqueta de pts
@export var cutoff: float = 450.0                                               # Zona libre de balas

# === ESTADO INTERNO ===
var canDie := false
var canShoot := true
var health: int
var lastBullet
var pulseMarked := false
var byBomb := false

# === FLUJO DE COMPORTAMIENTO ===
func _ready() -> void:
	match typeEnum:
		EnemyType.STD: health = 15
		EnemyType.MID: health = 50
		EnemyType.ELITE: health = 100
	
	if isGround: $Hurtbox.add_to_group("Ground")
	else: $Hitbox.add_to_group("Damage")

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
			health -= delta
	
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

# === MUERTE Y RECOMPENSAS ===
func _check_death() -> void:
	if health > 0: return
	SCORE.add_score(SCORE.combo)
	
	var playerPos = GAME.get_player()
	# Devuelve medallas si se mata a bocajarro o si el contador de medallas está activo
	if !byBomb and (position.distance_to(playerPos) < 200 or SCORE.medalCountdown > 0 or pulseMarked):
		_spawn_score(scoreCount, medal)
		if lastBullet and !SCORE.medalCountdown > 0 and !pulseMarked: SCORE.medalCountdown = 5
	# Devuelve balas de venganza si se mata alto en la pantalla
	if (position.y < 250 or pulseMarked) and !byBomb: _spawn_score(scoreCount, revengeBullet)
	if typeEnum == EnemyType.MID: _spawn_score(1, powerUp, true)
	
	# Enemigos élite cancelan todas las balas
	if typeEnum == EnemyType.ELITE:
		for bullet in get_tree().get_nodes_in_group("Enemy Bullet"):
			if bullet.has_method("cancel"): bullet.cancel()
	
	if pulseMarked:
		SCORE.increase_hot(5)
		SCORE.increase_combo(100)
	
	queue_free()

func _spawn_score(count: int, entity: PackedScene, center: bool = false) -> void:
	for i in count:
		var item = entity.instantiate()
		get_tree().current_scene.call_deferred("add_child", item)
		var spawnOffset = Vector2(randf_range(-size, size), 0) if !center else Vector2(0, 0)
		item.position = global_position + spawnOffset

# === COLISIONES ===
func _on_hurtbox_area_entered(area: Node) -> void:
	if area.is_in_group("Fire"):
		if comboLabel: comboLabel.show_combo()
		if canDie: health -= area.damage
		lastBullet = area.BulletType == area.BulletEnum.BURST
	if area.is_in_group("Player") and isGround:
		canShoot = false
	if area.is_in_group("Bomb"):
		byBomb = true
		health -= area.damage
	if area.is_in_group("Pulse"): pulseMarked = true

func _on_hurtbox_area_exited(area: Node) -> void:
	if area.is_in_group("Player") and isGround: canShoot = true
	if area.is_in_group("Pulse"): pulseMarked = false

func _on_hitbox_area_entered(area: Node) -> void:
	if area.is_in_group("Play"): canDie = true

func _on_hitbox_area_exited(area: Node) -> void:
	if area.is_in_group("Free"): queue_free()
