extends RigidBody2D

#consts
const MAX_TORQUE:float = 6000.0
const MAX_HULL_INTEGRITY:float = 100.0
const MAX_POWER:float = 100.0
const MAX_OXYGEN:float = 100.0

#power costs values
#TODO: division by fps(60), replace with delta value
const LIGHTS_COST:float =  5.0/60.0
const HULL_REGEN_COST:float = 80.0
const HULL_REGEN_RATE:float = 5.0/60.0
const BOOST_COST:float = 10.0/60.0

#regen/decay rates
const OXYGEN_DECAY:float = 0.9
const POWER_REGEN: float = 50.0 / 60.0

#setgets
var hull_integrity: float = 100.0 setget set_hull_integrity, get_hull_integrity
var oxygen: float = 100.0 setget set_oxygen, get_oxygen
var power: float = 100.0 setget set_power, get_power

#save data for run
var depth = 0
var length = 0

#movement
var thrust : Vector2 = Vector2(0, 450)
var idle_thrust : Vector2 = Vector2(0, 70)
var torque : float = 0.0
var torque_acceleration: float = 300.0
var torque_decelleration: float = 100.0
var vel_modifier:Vector2 = Vector2(0,0)

var oxygen_decay_disabled: bool = false
var power_regen_disabled: bool = false
var hull_regen_on:bool = false
var lights_on: bool = false
var is_boosting: bool = false
var input_disabled:bool = false
var mouse_over:bool = false
var sub_dead:bool = false

var last_body = null
var last_velocity:Vector2 = Vector2(0,0)

signal depth_status(depth)
signal input_activated()
signal hull_status(hull_integrity)
signal oxygen_status(oxygen)
signal power_status(power)
signal heavy_damage(damage)
signal sub_destroyed

func _ready():
	add_to_group("player")
	spawn_state()

func _integrate_forces(_state):
	depth = Utilities.pixels_to_meters(global_position.y)
	emit_signal("depth_status", global_position.y)
	var mouse_position = get_global_mouse_position()
	var mouse_vector = mouse_position - position
	var rotation_dir = 0
	
	$Target.rotation = mouse_vector.angle() - rotation
	
	var l_dist = $Left.global_position.distance_to(mouse_position)
	var r_dist = $Right.global_position.distance_to(mouse_position)
	
	if not input_disabled:
		if l_dist<r_dist:
			rotation_dir = 1
		else:
			rotation_dir = -1
		
	if torque <= MAX_TORQUE and torque >= 0:
		torque += torque_acceleration
	
	#slowdown value, has arbitrary division number, consider offloading to variable
	var distance = $Nose.global_position.distance_to($Target/sprite.global_position)/200.0
	
	applied_torque = rotation_dir * torque * distance
	
	
	is_boosting = false
	applied_force = idle_thrust.rotated(rotation)
	$AnimatedSprite.speed_scale = 1
	$BoostBubbles.emitting = false
	$EngineExhaust.emitting = false
	$EngineNoise.pitch_scale = 1.0
	
	if Input.is_mouse_button_pressed(2) and not input_disabled:
		if power >= BOOST_COST/3:
			is_boosting = true
			$AnimatedSprite.speed_scale = 2
			$EngineNoise.pitch_scale = 1.2
			$BoostBubbles.emitting = true
			applied_force = -thrust.rotated(rotation)/3
			
			#detect colliding bodies
			var collision = get_colliding_bodies()

			#if a collision is detected, bounce the player back
			if collision:
				for a in collision:
					applied_force += ((a.position - position).normalized().rotated(rotation)*10)
		
			
	if Input.is_mouse_button_pressed(1) and not input_disabled:
		if power >= BOOST_COST:
			applied_force = thrust.rotated(rotation)
			is_boosting = true
			$AnimatedSprite.speed_scale = 2
			$BoostBubbles.emitting = true
			$EngineExhaust.emitting = true
			$EngineNoise.pitch_scale = 1.2



	if Input.is_mouse_button_pressed(3) and not input_disabled:
		TurnOnLights()
	
	if torque >=0:
		torque -= torque_decelleration
	elif torque<0:
		torque = 0
	
	applied_force += vel_modifier
	
	ProcessPower()
	
	CalcOutline()

	
func spawn_state():
	set_axis_velocity(Vector2(0,700))
	power_regen_disabled=false
	input_disabled = true
	$BoostBubbles.emitting = false
	$InputActivation.start()

func begin():
	self.hull_integrity = 100.0
	self.oxygen = 100.0
	self.power = 100.0
	depth = 0
	length = 0
	$OxygenTimer.start()
	$RunTimer.start()
	$SpeedTimer.start()

func TurnOnLights():
	if $AnimationPlayer.is_playing():
		return
	#$LightsSound.play()
	if lights_on==false:
		power_regen_disabled = true
		$PowerTimer.start()
	lights_on = !lights_on
	$AnimationPlayer.play("flicker")

func TriggerLights():
	$LeftBeamCone.enabled = !$LeftBeamCone.enabled
	$LeftBeamGlow.enabled = !$LeftBeamGlow.enabled
	$LeftBeamGlow2.enabled = !$LeftBeamGlow2.enabled
	$RightBeamCone.enabled = !$RightBeamCone.enabled
	$RightBeamGlow.enabled = !$RightBeamGlow.enabled
	$RightBeamGlow2.enabled = !$RightBeamGlow2.enabled
	$BackLight.enabled = !$BackLight.enabled
	
func CalcOutline():
	if mouse_over and hull_regen_on == false and power>=HULL_REGEN_COST and hull_integrity<MAX_HULL_INTEGRITY:
		$Sprite.material.set_shader_param("enabled", true)
		$Sprite.material.set_shader_param("outline_color", Color(1.0,0.42,0.0,1.0))
	else:
		$Sprite.material.set_shader_param("enabled", false)
		

func DestroySub():
	emit_signal("sub_destroyed")
	if depth>=int(game.deepest): game.deepest = depth
	if length>=int(game.longest): game.longest = length
	game.save_game()
	if not $DeathSound.playing:
		$DeathSound.play()
	sub_dead = true
	input_disabled=true
	
	if lights_on:
		TurnOnLights()
	
	$WindowGlow.enabled = false
	$Target.visible=false
	$BreathTimer.stop()
	$OxygenTimer.stop()

func TakeHullDamage(damage_amount):
	if sub_dead:
		return
	var new_integrity = self.hull_integrity - damage_amount
	var difference = self.hull_integrity - new_integrity
	self.hull_integrity = new_integrity
	if difference >= 10:
		if !$HeavyDamageSound.playing:
			$HeavyDamageSound.pitch_scale = 0.7 + randf()/3.0
			$HeavyDamageSound.play()
		emit_signal("heavy_damage", difference)
	if self.hull_integrity <= 0:
		self.hull_integrity = 0
		DestroySub()

func RegenPower():
	if self.power<MAX_POWER and not power_regen_disabled:
		self.power+=POWER_REGEN

func ProcessPower():
	if is_boosting:
		self.power -= BOOST_COST
		power_regen_disabled = true
		$PowerTimer.start()
	
	if lights_on:
		if power>LIGHTS_COST:
			self.power -= LIGHTS_COST
		else:
			TurnOnLights()
	
	if hull_regen_on:
		self.hull_integrity += HULL_REGEN_RATE
	
	RegenPower()

func ActivateHullRegen():
	print ("hull regen activated")
	if not $RepairSound.playing:
		$RepairSound.pitch_scale = 0.8 + (randf()/2)
		$RepairSound.play()
	$RegenTimer.wait_time = (10 - (self.power/5.0) * 2) + 0.1
	self.power = 0
	hull_regen_on = true
	$AquaBots.emitting = true
	$RegenTimer.start()
	$PowerTimer.start()

func _on_Sub_body_entered(body):
	
	if not body.is_in_group("obstacle"):
		return
		
	if not $DamageSound.playing:
		$DamageSound.play()
	
	if last_body == body:
		print("colliding too soon, returning")
		return
		
	var linear_velocity_length = linear_velocity.length()
	
	if last_velocity.length() > linear_velocity_length:
		linear_velocity_length = last_velocity.length()
	
	var kinetic_energy
	var torque_force
	
	if body.is_in_group("obstacle"):
		kinetic_energy= 0.1 * mass * pow(linear_velocity_length,1.4)
		torque_force = 0.5 * mass * pow(abs(angular_velocity),1.4) * 100
	else:
		return
	
	print ("kinetic energy: ", kinetic_energy )
	print ("torque: ", torque_force )
	kinetic_energy+=torque_force
	print ("combined energy: ", kinetic_energy)
	


	last_body = body
	$DamageTimer.start()
	
	var damage = kinetic_energy /25.0
	if damage>25: damage = 25
	print ("damage", damage)
	
	TakeHullDamage(damage)
		

func _on_InputActivation_timeout() -> void:
	emit_signal("input_activated")
	$EngineNoise.play()
	$AnimatedSprite.playing=true
	input_disabled = false

func _on_OxygenTimer_timeout():
	if oxygen_decay_disabled == true:
		return
	self.oxygen -= OXYGEN_DECAY
	
	var oxygen_time = oxygen/10.0
	if $BreathTimer.time_left>oxygen_time:
		$BreathTimer.wait_time = oxygen_time
		$BreathTimer.start()
	
	if self.oxygen<=0:
		self.oxygen = 0
		
		if power>OXYGEN_DECAY:
			self.power -= OXYGEN_DECAY * 4.0
			power_regen_disabled = true
			$PowerTimer.start()
		else:
			DestroySub()
	
func _on_PowerTimer_timeout() -> void:
	power_regen_disabled = false
#	if not $PowerRechargeSound.playing:
#		$PowerRechargeSound.pitch_scale = 0.8 + (randf()/2)
#		$PowerRechargeSound.play()

func _on_RegenTimer_timeout() -> void:
	hull_regen_on = false
	$AquaBots.emitting = false

func _on_DamageTimer_timeout() -> void:
	last_body = null

func _on_SpeedTimer_timeout() -> void:
	last_velocity = linear_velocity

func _on_BreathTimer_timeout() -> void:
	print("!!!!BREATH!!!!!")
	if not $BreathSound.playing:
		$BreathSound.pitch_scale = randf()/2.0 + 0.75
		$BreathSound.play()
	$BreathTimer.wait_time = oxygen/10.0
	$BreathTimer.start()

func _on_MouseArea_mouse_entered() -> void:
	mouse_over = true

func _on_MouseArea_mouse_exited() -> void:
	mouse_over = false


func _on_MouseArea_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			if hull_integrity < MAX_HULL_INTEGRITY and hull_regen_on == false: #and power>=HULL_REGEN_COST:
				ActivateHullRegen()
			else:
				print ("not enough power, already active or hull full")
				$AquabotsFailSound.play()


func _on_RunTimer_timeout() -> void:
	length += 1

###########################
#SETTERS AND GETTERS
###########################
func set_hull_integrity(new_value):
	if new_value >= MAX_HULL_INTEGRITY:
		new_value = MAX_HULL_INTEGRITY
	elif new_value <=0:
		new_value = 0
	hull_integrity = new_value
	emit_signal("hull_status", hull_integrity)
		
func get_hull_integrity():
	return hull_integrity
	
func set_oxygen(new_value):
	if new_value>MAX_OXYGEN:
		new_value=MAX_OXYGEN
	elif new_value <=0:
		new_value = 0
	oxygen = new_value
	emit_signal("oxygen_status", oxygen)
	
func get_oxygen():
	return oxygen
	
func set_power(new_value):
	if new_value>MAX_POWER:
		new_value = MAX_POWER
	elif new_value <=0:
		new_value = 0
	power = new_value
	emit_signal("power_status", power)
	
func get_power():
	return power

