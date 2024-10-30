extends Node3D

@export var speed: float = 10.0  # Velocidad de movimiento del enemigo
@export var move_distance: float = 30.0  # Distancia que se moverá hacia adelante
@export var spawn_delay: float = randi_range(1,10)  # Tiempo antes de que aparezca el enemigo

@onready var SkeletonRogueAnim = $Skeleton_Rogue/AnimationPlayer

var health := 100
var destroyed := false
var spawn_timer: float = 0.0
var has_spawned: bool = false
var target_position: Vector3

# Cuando está listo, guarda la posición inicial
func _ready():
	SkeletonRogueAnim.play("Idle")
	
	target_position = position  # Calcula la posición objetivo

func _process(delta):
	if destroyed:
		return
	
	if !has_spawned:
		spawn_timer += delta
		if spawn_timer >= spawn_delay:
			has_spawned = true
			position =  position-(transform.basis.z.normalized() * move_distance)  # Mueve el enemigo a la posición objetivo
			SkeletonRogueAnim.play("Running_A")  # Inicia la animación de movimiento
		return
	
	# Mover al enemigo hacia adelante (en la dirección que mira)
	if position.distance_to(target_position) > 0.1:  # Solo se mueve si no ha llegado a la posición objetivo
		var direction = (target_position - position).normalized() #calcula la direccion desde la pposicion del enemigo hacia la del jugador
		position += direction * speed * delta  # Mover hacia la posición objetivo
		SkeletonRogueAnim.play("Running_A")  # Animación de movimiento
	else:
		SkeletonRogueAnim.play("Idle")  # Si ha llegado a la posición objetivo, reproducir animación de idle

# Tomar daño del jugador
func damage(amount):
	Audio.play("sounds/enemy_hurt.ogg")
	SkeletonRogueAnim.play("Hit_A")
	health -= amount #reduce la vida del enemigo
	if health <= 0 and !destroyed:
		destroy()
# Destruir al enemigo cuando se quede sin salud
func destroy():
	Audio.play("sounds/enemy_destroy.ogg")
	destroyed = true
	queue_free()
