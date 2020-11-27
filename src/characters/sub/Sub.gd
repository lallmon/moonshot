extends RigidBody2D

#consts
const MAX_TORQUE:float = 6000.0
const MAX_HULL_INTEGRITY:float = 100.0
const MAX_POWER:float = 100.0
const MAX_OXYGEN:float = 100.0

#power costs values
#TODO: division by fps(60), replace with delta value
const LIGHTS_COST:float =  5.0/60.0
const HULL_REGEN_COST:float = 10.0/60.0
const HULL_REGEN_RATE:float = 5.0/60.0
const BOOST_COST:float = 15.0/60.0

#setgets
var hull_integrity: float = 100.0 setget set_hull_integrity, get_hull_integrity
var oxygen: float = 100.0 setget set_oxygen, get_oxygen
var power: float = 100.0 setget set_power, get_power

#movement
var thrust : Vector2 = Vector2(0, 350)
var idle_thrust : Vector2 = Vector2(0, 70)
var torque : float = 0.0
var torque_acceleration: float = 100.0
var torque_decelleration: float = 50.0
var vel_modifier:Vector2 = Vector2(0,0)

#regen/decay rates
var oxygen_decay:float = 1.0
var power_regen: float = 20.0 / 60.0

var oxygen_decay_disabled: bool = false
var power_regen_disabled: bool = false
var lights_on: bool = false
var input_disabled:bool = false
var sub_dead:bool = false

signal depth_status(depth)
signal hull_status(hull_integrity)
signal oxygen_status(oxygen)
signal power_status(power)
signal heavy_damage(damage)
signal sub_destroyed

func _ready():
	add_to_group("player")
	$OxygenTimer.connect("timeout", self, "_on_Oxygen_timeout")
	spawn_state()

func _integrate_forces(_state):
	var mouse_position = get_global_mouse_position()
	var mouse_vector = mouse_position - position
	var rotation_dir = 0
	
	$Target.rotation = mouse_vector.angle() - rotation
	
	var l_dist = $Left.global_position.distance_to(mouse_position)
	var r_dist = $Right.global_position.distance_to(mouse_position)
	
	if Input.is_mouse_button_pressed(1) or Input.is_mouse_button_pressed(2):
		if Input.is_mouse_button_pressed(1) and not input_disabled:
			
			applied_force = -idle_thrust.rotated(rotation)
			
			#detect colliding bodies
			var collision = get_colliding_bodies()

			#if a collision is detected, bounce the player back
			if collision:
				for a in collision:
					applied_force += ((a.position - position).normalized().rotated(rotation)*10)
			
			if l_dist<r_dist:
				rotation_dir = 1
			else:
				rotation_dir = -1
			
			if torque <= MAX_TORQUE and torque >= 0:
				torque += torque_acceleration
#
			torque -= torque_decelleration
			applied_torque = rotation_dir * torque
			
		if Input.is_mouse_button_pressed(2) and not input_disabled:
			applied_force = thrust.rotated(rotation)
			$AnimatedSprite.speed_scale = 2
			$BoostBubbles.emitting = true
			$EngineNoise.pitch_scale = 1.2
			applied_torque = lerp(applied_torque, 0, 0.5)

	else:
		applied_force = idle_thrust.rotated(rotation)
		applied_torque = lerp(applied_torque, 0, 0.5)
		$AnimatedSprite.speed_scale = 1
		$BoostBubbles.emitting = false
		$EngineNoise.pitch_scale = 1.0

	if Input.is_mouse_button_pressed(3) and not input_disabled:
		TurnOnLights()
			
	applied_force += vel_modifier
	
func spawn_state():
	set_axis_velocity(Vector2(0,700))
	input_disabled = true
	$BoostBubbles.emitting = false
	$InputActivation.start()
	$OxygenTimer.start()

func TurnOnLights():
	if $AnimationPlayer.is_playing():
		return
	$AnimationPlayer.play("flicker")

func TriggerLights():
	$LeftBeamCone.enabled = !$LeftBeamCone.enabled
	$LeftBeamGlow.enabled = !$LeftBeamGlow.enabled
	$LeftBeamGlow2.enabled = !$LeftBeamGlow2.enabled
	$RightBeamCone.enabled = !$RightBeamCone.enabled
	$RightBeamGlow.enabled = !$RightBeamGlow.enabled
	$RightBeamGlow2.enabled = !$RightBeamGlow2.enabled
	$BackLight.enabled = !$BackLight.enabled

func DestroySub():
	emit_signal("sub_destroyed")
	input_disabled=true

func TakeHullDamage(damage_amount):
	var new_integrity = self.hull_integrity - damage_amount
	var difference = self.hull_integrity - new_integrity
	self.hull_integrity = new_integrity
	if difference >= 5:
		emit_signal("heavy_damage", difference)
	if self.hull_integrity <= 0:
		self.hull_integrity = 0
		DestroySub()

func _on_Sub_body_entered(body):
	var velocity_force = linear_velocity.length()
	var torque_force = angular_velocity
	print ("velocity: ", velocity_force )
	print ("torque: ", torque_force )
	if velocity_force>= 80:
		TakeHullDamage(body.damage * velocity_force/200)
		TakeHullDamage(body.damage * abs(torque_force))
		
func _on_Oxygen_timeout():
	self.oxygen -= oxygen_decay
	if self.oxygen<=0:
		self.oxygen = 0
		DestroySub()

func _on_InputActivation_timeout() -> void:
	$EngineNoise.play()
	$AnimatedSprite.playing=true
	input_disabled = false

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
