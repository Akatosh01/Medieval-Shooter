extends Node3D

@export var player: Node3D
@export var speed: float = 2.0  # Velocidad de movimiento del enemigo
@export var spawn_delay: float = 3.0  # Tiempo antes de que aparezca el enemigo

@onready var raycast = $RayCast3D
@onready var SkeletonWarrior = $Skeleton_Warrior
@onready var SkeletonWarriorAnim = $Skeleton_Warrior/AnimationPlayer

var health := 1000
var destroyed := false
var spawn_timer: float = 1.0  # Temporizador para el spawn
var has_spawned: bool = false  # Bandera para controlar si ya ha aparecido
var target_position: Vector3
# Cuando esté listo, reproduce la animación de idle
func _ready():
	SkeletonWarrior.visible = false
	SkeletonWarriorAnim.play("Idle")
	
	
func _process(delta):
	if destroyed:
		return
	
	if !has_spawned:
		spawn_timer += delta
		if spawn_timer >= spawn_delay:
			SkeletonWarrior.visible = true
			SkeletonWarriorAnim.play("Spawn_Air")  # Reproduce animación idle al aparecer
			has_spawned = true  # Marcar que ya ha aparecido
			#position = position  # Establecer posición inicial (puedes cambiar esto si es necesario)
			target_position = player.position
		return  # Salir si no ha aparecido aún

	var player_pos = player.position
	player_pos.y = position.y  # Ignora la altura para mantener horizontalidad

	# Hacer que el nodo mire hacia el jugador
	self.look_at(player_pos, Vector3.UP, true)

	# Mover al enemigo hacia el jugador
	if position.distance_to(player_pos) > 1.0:  # Solo se mueve si está a más de 1 unidad
		var direction = (player_pos - position).normalized()
		position += direction * speed * delta  # Mover hacia el jugador
		SkeletonWarriorAnim.play("Running_A")  # Animación de movimiento
	else:
		attack_player()

# Función para atacar al jugador
func attack_player():
	raycast.force_raycast_update()

	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider.has_method("damage"):  # Si colisiona con el jugador
			Audio.play("sounds/enemy_attack.ogg")
			collider.damage(1)  # Aplicar daño al jugador
			SkeletonWarriorAnim.play("1H_Melee_Attack_Chop")  # Reproducir animación de ataque
		else:
			SkeletonWarriorAnim.play("Idle")  # Animación de reposo si no está atacando
	else:
		SkeletonWarriorAnim.play("Idle")  # Reproducir animación de idle si no está atacando

# Tomar daño del jugador
func damage(amount):
	Audio.play("sounds/enemy_hurt.ogg")
	SkeletonWarriorAnim.play("Hit_A")
	health -= amount

	if health <= 0 and !destroyed:
		destroy()

# Destruir al enemigo cuando se quede sin salud
func destroy():
	Audio.play("sounds/enemy_destroy.ogg")
	destroyed = true
	queue_free()
