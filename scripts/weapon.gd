extends Resource
class_name Weapon  # Define el nombre de clase como 'Weapon' para facilitar su uso en el editor

# Model and visual properties
@export_subgroup("Model")  # Agrupa las siguientes variables bajo el grupo "Model" en el inspector
@export var model: PackedScene  # El modelo 3D del arma, definido como una escena empaquetada
@export var position: Vector3  # La posición en pantalla del modelo del arma
@export var rotation: Vector3  # La rotación en pantalla del modelo del arma
@export var muzzle_position: Vector3  # La posición en pantalla del destello del cañón al disparar

# Weapon properties (for firing)
@export_subgroup("Properties")  # Agrupa las siguientes variables bajo el grupo "Properties"
@export_range(0.1, 1) var cooldown: float = 0.1  # El tiempo de enfriamiento entre disparos, define la cadencia de fuego
@export_range(1, 200) var max_distance: int = 200  # La distancia máxima de disparo
@export_range(0, 100) var damage: float = 25  # La cantidad de daño que inflige cada disparo
@export_range(0, 5) var spread: float = 0  # El rango de dispersión del disparo (precisión del arma)
@export_range(1, 5) var shot_count: int = 1  # La cantidad de disparos que realiza el arma en una sola acción
@export_range(0, 50) var knockback: int = 20  # La cantidad de retroceso al disparar (impacto visual y en personaje)

# Sound properties
@export_subgroup("Sounds")  # Agrupa las siguientes variables bajo el grupo "Sounds"
@export var sound_shoot: String  # La ruta del sonido de disparo del arma

# Crosshair properties
@export_subgroup("Crosshair")  # Agrupa las siguientes variables bajo el grupo "Crosshair"
@export var crosshair: Texture2D  # La imagen de la mira que se muestra en pantalla
