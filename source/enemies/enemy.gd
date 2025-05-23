extends CharacterBody2D

# === ENUMS DE COMPORTAMIENTO ===
enum MoveType { STRAIGHT, SINUSOIDAL, OSCILLATE, BREATH, BLOCK, CENTER, CURVE, CIRCULAR, TOWARDS_PLAYER, LEAVE, LEAVE_SIDE, DIAGONAL, STILL }
enum Direction { NORTH, WEST, SOUTH, EAST }
enum Handedness { LEFT, RIGHT }
enum EnemyType { STD, MID, ELITE }

# === EXPORTS GENERALES ===
@export var typeEnum: EnemyType = EnemyType.STD
@export var size := 20                                                          # Tamaño del enemigo
@export var intensity := 1                                                      # Intensidad de comportamiento
@export_range(0, 90, 15) var deviationAngle: int = 90                           # Cantidad de giro
@export var scrollFollow := false                                               # ¿Sigue el scroll?
@export var isGround := false                                                   # ¿Es enemigo de tierra?
@export var medal: PackedScene = preload("res://scenes/items/medal.tscn")                           # Medalla que recompensa
@export var revengeBullet: PackedScene = preload("res://scenes/bullets/revenge_bullet.tscn")        # Balas que devuelve
@export var powerUp: PackedScene = preload("res://scenes/items/power_up.tscn")                      # Potenciador que recompensa
@export var scoreCount: int = 1                                                 # Cantidad de items/balas devueltos
@export var directionEnum: Direction = Direction.SOUTH                          # Dirección general
@export var handedness: Handedness = Handedness.RIGHT                           # Mano dominante
@export var comboLabel: RichTextLabel                                           # Etiqueta de pts

# === MOVIMIENTOS POR ETAPAS ===
@export_category("CHILDHOOD")
@export var childhood: MoveType = MoveType.STRAIGHT                             # Tipo de comportamiento
@export var childDuration := 1.0                                                # Duración de etapa vital
@export var childSpeed := 100                                                   # Velocidad durante etapa vital
@export var adultInvert := false                                                # ¿Invertir mano dominante?

@export_category("ADULTHOOD")
@export var adulthood: MoveType = MoveType.STRAIGHT                             # Tipo de comportamiento
@export var adultDuration := 1.0                                                # Duración de etapa vital
@export var adultSpeed := 100                                                   # Velocidad durante etapa vital
@export var oldInvert := false                                                  # Invertir mano dominante?

@export_category("OLD AGE")
@export var oldAge: MoveType = MoveType.STRAIGHT                                # Tipo de comportamiento
@export var oldSpeed := 100                                                     # Velocidad durante etapa vital

# === ESTADO INTERNO ===
var currentStage := "childhood"
var stageTimer := 0.0
var speed := 200
var extraVel := Vector2.ZERO
var direction := Vector2.DOWN
var currentDirection := Vector2.ZERO
var hSide: int
var randSide: int
var canDie := false
var canShoot := true
var cantShoot := false
var health: int
var lastBullet
var pulseMarked := false
var pulseDamaged := false

var DIRECTION_MAP = {
	Direction.NORTH: Vector2.UP,
	Direction.SOUTH: Vector2.DOWN,
	Direction.WEST: Vector2.LEFT,
	Direction.EAST: Vector2.RIGHT
}

func _ready() -> void:
	match typeEnum:
		EnemyType.STD: health = 15
		EnemyType.MID: health = 50
		EnemyType.ELITE: health = 100
	direction = DIRECTION_MAP.get(directionEnum, Vector2.DOWN)
	currentDirection = direction
	stageTimer = 0.0
	hSide = -1 if handedness == Handedness.RIGHT else 1
	randSide = -1 if randi() % 2 == 0 else 1
	
	if isGround: $Hurtbox.add_to_group("Ground")
	else: $Hitbox.add_to_group("Damage")

# === PROCESO DE VIDA Y FASES ===
func _process(delta: float) -> void:
	_check_death()
	stageTimer += delta
	
	velocity = SCROLL.get_scroll() + extraVel if scrollFollow else extraVel
	
	# Pulse damage
	if pulseMarked and (INPUT.firing or INPUT.fireHold) and !pulseDamaged:
		health -= 15
		pulseDamaged = true
	
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

func _change_stage(nextStage: String, shouldInvert: bool) -> void:
	currentStage = nextStage
	stageTimer = 0.0
	currentDirection = direction
	if shouldInvert: hSide *= -1

# === MOVIMIENTO GENERAL ===
func apply_movement(moveType: MoveType, dur: float, delta: float) -> void:
	match moveType:
		MoveType.STRAIGHT: move_straight()
		MoveType.SINUSOIDAL: move_sinusoidal()
		MoveType.OSCILLATE: move_oscillate()
		MoveType.BREATH: move_breath()
		MoveType.BLOCK: move_block(delta)
		MoveType.CENTER: move_center(delta)
		MoveType.CURVE: move_curve(dur, delta)
		MoveType.CIRCULAR: move_circular(delta)
		MoveType.TOWARDS_PLAYER: move_towards_player()
		MoveType.LEAVE: move_leave()
		MoveType.LEAVE_SIDE: move_leave_side()
		MoveType.DIAGONAL: move_diagonal()
		MoveType.STILL: move_still()

# === MUERTE Y RECOMPENSAS ===
func _check_death() -> void:
	if health > 0: return
	SCORE.add_score(SCORE.combo)
	
	var playerPos = GAME.get_player()
	# Devuelve medallas si se mata a bocajarro o si el contador de medallas está activo
	if position.distance_to(playerPos) < 200 or SCORE.medalCountdown > 0 or pulseMarked:
		_spawn_score(scoreCount, medal)
		if lastBullet and !SCORE.medalCountdown > 0 and !pulseMarked: SCORE.medalCountdown = 5
	# Devuelve balas de venganza si se mata alto en la pantalla
	if position.y < 250 or pulseMarked: _spawn_score(scoreCount, revengeBullet)
	if typeEnum == EnemyType.MID: _spawn_score(1, powerUp, true)
	
	# Enemigos élite cancelan todas las balas
	if typeEnum == EnemyType.ELITE:
		for bullet in get_tree().get_nodes_in_group("Enemy Bullet"):
			if bullet.has_method("cancel"): bullet.cancel()
	
	if pulseMarked:
		SCORE.increase_fever(5)
		SCORE.increase_combo(100)
	
	queue_free()

func _spawn_score(count: int, entity: PackedScene, center: bool = false) -> void:
	for i in count:
		var item = entity.instantiate()
		get_tree().current_scene.call_deferred("add_child", item)
		var spawnOffset = Vector2(randf_range(-size, size), 0) if !center else Vector2(0, 0)
		item.position = global_position + spawnOffset

# === TIPOS DE MOVIMIENTO ===

func move_straight(): extraVel = direction * speed; move_and_slide()

func move_sinusoidal():
	var offset = sin(2.0 * stageTimer + PI / 2) * 50.0 * intensity * hSide
	var side = Vector2(-direction.y, direction.x)
	extraVel = direction * speed + side * offset
	move_and_slide()

func move_oscillate():
	var offset = sign(sin(2.0 * stageTimer + PI / 2)) * 50.0 * intensity * hSide
	var side = Vector2(-direction.y, direction.x)
	extraVel = direction * speed + side * offset
	move_and_slide()

func move_breath():
	var xOffset = cos(2.0 * stageTimer) * 15.0 * randSide
	var yOffset = sin(3.0 * stageTimer) * 7.0
	extraVel = Vector2(xOffset, yOffset) * intensity
	move_and_slide()

func move_block(delta: float):
	var playerPos = GAME.get_player()
	var dist = global_position.distance_to(playerPos)
	var followSpeed = clamp(1.0 / (dist * 0.05 + 0.5), 1.0, 3.0)
	
	if directionEnum in [Direction.NORTH, Direction.SOUTH]:
		global_position.x = lerp(global_position.x, playerPos.x, followSpeed * delta)
	else: global_position.y = lerp(global_position.y, playerPos.y, followSpeed * delta)

func move_center(delta: float):
	var center = get_viewport().get_visible_rect().size / 2
	var moveSpeed = 200
	
	if directionEnum in [Direction.NORTH, Direction.SOUTH]:
		var dx = center.x - global_position.x
		global_position.x += sign(dx) * moveSpeed * delta
		if abs(dx) < moveSpeed * delta: global_position.x = center.x
	else:
		var dy = center.y - global_position.y
		global_position.y += sign(dy) * moveSpeed * delta
		if abs(dy) < moveSpeed * delta: global_position.y = center.y

func move_curve(dur: float, delta: float):
	var rotSpeed = deg_to_rad(deviationAngle) / dur
	if abs(direction.angle_to(currentDirection)) < deg_to_rad(deviationAngle):
		direction = direction.rotated(rotSpeed * hSide * delta)
	extraVel = direction * speed
	move_and_slide()

func move_circular(delta: float):
	direction = direction.rotated(deg_to_rad(deviationAngle) * hSide * delta)
	extraVel = direction * speed
	move_and_slide()

func move_towards_player():
	scrollFollow = false
	direction = (GAME.get_player() - global_position).normalized()
	extraVel = direction * speed
	move_and_slide()

func move_leave():
	scrollFollow = false
	extraVel = -direction * speed
	move_and_slide()

func move_leave_side():
	scrollFollow = false
	var newDir
	match directionEnum:
		Direction.NORTH: newDir = Vector2(-hSide, 1)
		Direction.SOUTH: newDir = Vector2(-hSide, -1)
		Direction.WEST: newDir = Vector2(1, -hSide)
		Direction.EAST: newDir = Vector2(-1, -hSide)
	extraVel = newDir.normalized() * speed
	move_and_slide()

func move_diagonal():
	var newDir
	match directionEnum:
		Direction.NORTH: newDir = Vector2(-hSide * 1.5, -1)
		Direction.SOUTH: newDir = Vector2(-hSide * 2, 1)
		Direction.WEST: newDir = Vector2(-1, -hSide * 1.5)
		Direction.EAST: newDir = Vector2(1, -hSide * 1.5)
	extraVel = newDir.normalized() * speed
	move_and_slide()

func move_still():
	extraVel = Vector2.ZERO
	move_and_slide()

# === COLISIONES ===

func _on_hurtbox_area_entered(area: Node) -> void:
	if area.is_in_group("Fire"):
		if comboLabel: comboLabel.show_combo()
		if canDie: health -= area.damage
		lastBullet = area.isWide
	if area.is_in_group("Player") and isGround:
		canShoot = false
	if area.is_in_group("Bomb"): health -= area.damage
	if area.is_in_group("Pulse"): pulseMarked = true

func _on_hurtbox_area_exited(area: Node) -> void:
	if area.is_in_group("Player") and isGround: canShoot = true
	if area.is_in_group("Pulse"): pulseMarked = false

func _on_hitbox_area_entered(area: Node) -> void:
	if area.is_in_group("Play"): canDie = true

func _on_hitbox_area_exited(area: Node) -> void:
	if area.is_in_group("Free"): queue_free()
