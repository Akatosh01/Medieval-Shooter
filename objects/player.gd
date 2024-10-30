extends CharacterBody3D # Extiende de CharacterBody3D, ideal para personajes en 3D con control de movimiento incorporado

@export_subgroup("Properties") # Agrupa las propiedades de movimiento en el editor
@export var movement_speed = 5 # Velocidad de movimiento del personaje
@export var jump_strength = 8 # Fuerza del salto del personaje

@export_subgroup("Weapons") # Agrupa las propiedades de armas en el editor
@export var weapons: Array[Weapon] = [] # Lista de armas disponibles para el personaje

var weapon: Weapon # Almacena el arma actual del personaje
var weapon_index := 0 # Índice del arma actualmente equipada

var mouse_sensitivity = 700 # Sensibilidad del ratón para la cámara
var gamepad_sensitivity := 0.075 # Sensibilidad del gamepad para la cámara

var mouse_captured := true # Controla si el ratón está capturado para mover la cámara

var movement_velocity: Vector3 # Almacena la velocidad de movimiento
var rotation_target: Vector3 # Objetivo de rotación para la cámara

var input_mouse: Vector2 # Movimiento relativo del ratón para rotación

var health:int = 50 # Salud inicial del personaje
var gravity := 0.0 # Controla la gravedad actual en el salto

var previously_floored := false # Controla si el personaje estaba en el suelo en el cuadro anterior

var jump_single := true # Controla si se permite un salto simple
var jump_double := true # Controla si se permite un salto doble

var container_offset = Vector3(1.2, -1.1, -2.75) # Posición inicial del arma en relación al personaje

var tween:Tween # Tween para animar el cambio de arma

signal health_updated # Señal para actualizar la salud en la interfaz de usuario

@onready var camera = $Head/Camera # Nodo de la cámara en la escena del personaje
@onready var raycast = $Head/Camera/RayCast # Nodo de RayCast para detectar impactos
@onready var muzzle = $Head/Camera/SubViewportContainer/SubViewport/CameraItem/Muzzle # Nodo de la "boca" del arma
@onready var container = $Head/Camera/SubViewportContainer/SubViewport/CameraItem/Container # Contenedor del modelo del arma
@onready var sound_footsteps = $SoundFootsteps # Nodo de audio para los sonidos de pasos
@onready var blaster_cooldown = $Cooldown # Nodo de cooldown para el disparo

@export var crosshair:TextureRect # Textura del crosshair en pantalla

# Funciones principales

func _ready():
	# Captura el ratón para el control de la cámara
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	weapon = weapons[weapon_index] # Selecciona el arma inicial
	initiate_change_weapon(weapon_index) # Inicia la animación de cambio de arma

func _physics_process(delta):
	# Llamada a las funciones principales para control y gravedad
	handle_controls(delta)
	handle_gravity(delta)
	
	# Movimiento del personaje
	var applied_velocity: Vector3
	movement_velocity = transform.basis * movement_velocity # Calcula el movimiento hacia adelante
	applied_velocity = velocity.lerp(movement_velocity, delta * 10) # Suaviza la velocidad
	applied_velocity.y = -gravity # Aplica la gravedad en el eje Y
	velocity = applied_velocity
	move_and_slide() # Aplica movimiento y deslizamiento en la física
	
	# Rotación de la cámara
	camera.rotation.z = lerp_angle(camera.rotation.z, -input_mouse.x * 25 * delta, delta * 5)
	camera.rotation.x = lerp_angle(camera.rotation.x, rotation_target.x, delta * 25)
	rotation.y = lerp_angle(rotation.y, rotation_target.y, delta * 25)
	container.position = lerp(container.position, container_offset - (basis.inverse() * applied_velocity / 30), delta * 10)
	
	# Sonido de movimiento
	sound_footsteps.stream_paused = true
	if is_on_floor():
		if abs(velocity.x) > 1 or abs(velocity.z) > 1:
			sound_footsteps.stream_paused = false # Activa sonido de pasos
	
	# Aterrizaje después de un salto o caída
	camera.position.y = lerp(camera.position.y, 0.0, delta * 5)
	if is_on_floor() and gravity > 1 and !previously_floored:
		Audio.play("sounds/land.ogg") # Reproduce sonido de aterrizaje
		camera.position.y = -0.1
	previously_floored = is_on_floor()
	
	# Reinicia la escena si el personaje cae
	if position.y < -10:
		get_tree().reload_current_scene()

# Movimiento del ratón

func _input(event):
	if event is InputEventMouseMotion and mouse_captured:
		input_mouse = event.relative / mouse_sensitivity
		rotation_target.y -= event.relative.x / mouse_sensitivity
		rotation_target.x -= event.relative.y / mouse_sensitivity

# Control del movimiento

func handle_controls(_delta):
	# Captura y libera el ratón con controles específicos
	if Input.is_action_just_pressed("mouse_capture"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_captured = true
	if Input.is_action_just_pressed("mouse_capture_exit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_captured = false
		input_mouse = Vector2.ZERO
	
	# Rotación de la cámara basada en controles del gamepad
	var rotation_input := Input.get_vector("camera_right", "camera_left", "camera_down", "camera_up")
	rotation_target -= Vector3(-rotation_input.y, -rotation_input.x, 0).limit_length(1.0) * gamepad_sensitivity
	rotation_target.x = clamp(rotation_target.x, deg_to_rad(-90), deg_to_rad(90))
	
	# Disparo de armas y salto
	action_shoot()
	if Input.is_action_just_pressed("jump"):
		if jump_single or jump_double:
			Audio.play("sounds/jump_a.ogg, sounds/jump_b.ogg, sounds/jump_c.ogg")
		if jump_double:
			gravity = -jump_strength
			jump_double = false
		if(jump_single): action_jump()
	
	# Cambio de armas
	action_weapon_toggle()

# Control de la gravedad

func handle_gravity(delta):
	gravity += 20 * delta
	if gravity > 0 and is_on_floor():
		jump_single = true
		gravity = 0

# Acción de salto

func action_jump():
	gravity = -jump_strength
	jump_single = false
	jump_double = true

# Acción de disparo

func action_shoot():
	if Input.is_action_pressed("shoot"):
		if !blaster_cooldown.is_stopped(): return # Si el disparo está en cooldown, no dispara
		Audio.play(weapon.sound_shoot) # Reproduce sonido de disparo
		container.position.z += 0.25 # Retroceso del arma
		camera.rotation.x += 0.025 # Retroceso de la cámara
		movement_velocity += Vector3(0, 0, 0) # Retroceso del personaje
		muzzle.play("default") # Efecto de flash del disparo
		muzzle.rotation_degrees.z = randf_range(-45, 45)
		muzzle.scale = Vector3.ONE * randf_range(0.40, 0.75)
		muzzle.position = container.position - weapon.muzzle_position
		blaster_cooldown.start(weapon.cooldown) # Inicia el cooldown del arma
		
		# Lógica para raycast y detección de impactos
		for n in weapon.shot_count:
			raycast.target_position.x = randf_range(-weapon.spread, weapon.spread)
			raycast.target_position.y = randf_range(-weapon.spread, weapon.spread)
			raycast.force_raycast_update()
			if !raycast.is_colliding(): continue
			var collider = raycast.get_collider()
			if collider.has_method("damage"):
				collider.damage(weapon.damage)
			var impact = preload("res://objects/impact.tscn")
			var impact_instance = impact.instantiate()
			impact_instance.play("shot")
			get_tree().root.add_child(impact_instance)
			impact_instance.position = raycast.get_collision_point() + (raycast.get_collision_normal() / 10)
			impact_instance.look_at(camera.global_transform.origin, Vector3.UP, true)

# Cambia entre las armas disponibles

func action_weapon_toggle():
	if Input.is_action_just_pressed("weapon_toggle"):
		weapon_index = wrap(weapon_index + 1, 0, weapons.size())
		initiate_change_weapon(weapon_index)
		Audio.play("sounds/weapon_change.ogg")

# Inicia la animación de cambio de arma

func initiate_change_weapon(index):
	weapon_index = index
	tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(container, "position", container_offset - Vector3(0, 1, 0), 0.1)
	tween.tween_callback(change_weapon)

# Cambia el modelo del arma

func change_weapon():
	weapon = weapons[weapon_index]
	for n in container.get_children():
		container.remove_child(n)
	var weapon_model = weapon.model.instantiate()
	container.add_child(weapon_model)
	weapon_model.position = weapon.position
	weapon_model.rotation_degrees = weapon.rotation
	for child in weapon_model.find_children("*", "MeshInstance3D"):
		child.layers = 2
	raycast.target_position = Vector3(0, 0, -250)
	crosshair.texture = weapon.crosshair

# Daño al personaje

func damage(amount):
	health -= amount
	health_updated.emit(health) # Emite la señal de actualización de salud
	if health < 0:
		get_tree().reload_current_scene() # Reinicia la escena al quedarse sin salud
