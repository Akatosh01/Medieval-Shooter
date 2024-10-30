extends Control

func _on_credits_mouse_entered() -> void:
	var sonido_click = get_tree().get_nodes_in_group("Sonidos")[0].get_node("click")
	if sonido_click:
		sonido_click.play()

func _on_quit_mouse_entered() -> void:
	var sonido_click = get_tree().get_nodes_in_group("Sonidos")[0].get_node("click")
	if sonido_click:
		sonido_click.play()


func _on_play_mouse_entered() -> void:
	var sonido_click = get_tree().get_nodes_in_group("Sonidos")[0].get_node("click")
	if sonido_click:
		sonido_click.play()


func _on_credits_pressed():
	get_tree().change_scene_to_file("res://Creditos/Creditos.tscn")  

func _on_quit_pressed() -> void:
	get_tree().quit()
	
func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
