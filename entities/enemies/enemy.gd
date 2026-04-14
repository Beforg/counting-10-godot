extends CharacterBody2D

enum State { HIDDEN, STALKING, HUNTING }
var current_state: State = State.HIDDEN

@export var stalk_speed: float = 60.0
@export var hunt_speed: float = 280.0
@export var base_light_radius: float = 25.0

@export var player: Node2D

func _physics_process(delta: float) -> void:
	if player != null and player.get("torch") != null:
		var light = player.torch.texture_scale
		var distance = global_position.distance_to(player.global_position)
		
		# Calculamos onde termina a luz (80% para ele ficar na penumbra escura)
		var current_safe_zone = base_light_radius * light * 0.8
		
		if light > 5:
			current_state = State.HIDDEN
		elif light > 3: # Enquanto houver o mínimo de luz, ele tem medo
			current_state = State.STALKING
		else:
			current_state = State.HUNTING
			current_safe_zone = 0.0 # Luz apagou de vez, ele perde o medo!
			
		# --- A AÇÃO ---
		match current_state:
			
			State.HIDDEN:
				visible = false
				velocity = Vector2.ZERO
				move_and_slide()
				
			State.STALKING:
				visible = true
				var dir = global_position.direction_to(player.global_position)
				
				# Respeita a parede de luz
				if distance > current_safe_zone:
					# Está no escuro, anda na sua direção
					velocity = dir * stalk_speed
				elif distance < current_safe_zone - 10.0:
					# Jogador andou pra cima dele: recua assustado para as sombras
					velocity = -dir * (stalk_speed * 0.8)
				else:
					# Exatamente na borda: Fica parado te observando
					velocity = Vector2.ZERO 
				
				move_and_slide()
				
			State.HUNTING:
				visible = true
				
				# O BOTE
				if distance > 600.0:
					teleport_near_player(current_safe_zone)
				
				# Corre pra matar
				if distance > 15.0:
					var dir = global_position.direction_to(player.global_position)
					velocity = dir * hunt_speed
					move_and_slide()
				else:
					get_tree().reload_current_scene() # Game Over

# Função de teleporte atualizada
func teleport_near_player(safe_zone: float) -> void:
	var random_angle = randf() * TAU 
	
	# Ele vai surgir
	# depois da parede de luz, o que for maior. Isso garante que ele nunca caia na parte iluminada.
	var spawn_distance = max(400.0, safe_zone + 50.0)
	
	var offset = Vector2(cos(random_angle), sin(random_angle)) * spawn_distance
	global_position = player.global_position + offset
