extends KinematicBody2D

# Constants
const UP = Vector2(0, -1)
const GRAVITY = 20
const ACCELERATION = 50
const DAMAGE = 10
const MAX_SPEED_NORMAL = 350
const MAX_SPEED_POWERUP = 550
const MAX_JUMP_HEIGHT_NORMAL = -850
const MAX_JUMP_HEIGHT_POWERUP = -1000
const DROP_THRU_BIT = 1

# General Variables
var motion = Vector2()
export var knockback = 15000
export var knockup = 100
var hit = false
var max_speed = MAX_SPEED_NORMAL
var max_jump_height = -850

# Nodes Referencing
onready var body_sprite = $BodySprite
onready var head_sprite = $HeadSprite
onready var gun = $GunSprite
onready var animation = $AnimationPlayer
onready var screen_shake = $Camera/Screenshake
onready var damage_area = $DamageArea
onready var anim_eyes = $HeadSprite/AnimationEyes

# Referencing lifebar from HUD
onready var lifebar = get_tree().get_current_scene().get_node("HUD/Health/Lifebar")

func _ready() -> void:
	z_index = -2
	for powerup in get_parent().get_node("PowerUps").get_children():
		powerup.connect("player_entered", self, "_powerup")

func execute_animation() -> void: # Player's animation function
	if is_on_floor():
		if motion.x != 0:
			animation.play("run")
		else:
			animation.play("idle")
	else:
		if motion.y < 0:
			animation.play("jump")
		else:
			animation.play("fall")

func flip() -> void: # Flipping sprite function
	head_sprite.set_flip_h(get_global_mouse_position().x < global_position.x)
	
	if motion.x > 0:
		body_sprite.flip_h = false
	elif motion.x < 0:
		body_sprite.flip_h = true

func movement() -> void: # Player's movement function
	motion.y += GRAVITY
	var friction = false
	
	if Input.is_action_pressed("ui_down"):
		set_collision_mask_bit(DROP_THRU_BIT, false)
	
	if Input.is_action_pressed("ui_right"):
		motion.x = min(motion.x + ACCELERATION, max_speed)
	elif Input.is_action_pressed("ui_left"):
		motion.x = max(motion.x - ACCELERATION, -max_speed)
	else:
		motion.x = 0
		friction = true
	
	if is_on_floor():
		if Input.is_action_just_pressed("ui_up"):
			motion.y = max_jump_height
		if friction == true:
			motion.x = lerp(motion.x, 0, 0.2)
	else:
		if friction == true:
			motion.x = lerp(motion.x, 0, 0.05)
		if Input.is_action_just_released("ui_up") && motion.y < 0:
			motion.y = 0
	
	motion = move_and_slide(motion, UP)

func _physics_process(_delta: float) -> void: # Physics update
	movement()
	flip()
	execute_animation()

func _on_DamageArea_area_entered(area)  -> void:
	if area.is_in_group("hitbox") && !hit:
		take_damage()

func player_visible(value : bool) -> void:
	body_sprite.visible = value
	head_sprite.visible = value
	gun.visible = value

func take_damage() -> void:
	var knock_side = knockback * Global.hit_side
	motion.x -= lerp(motion.x, -knock_side, 0.1)
	#motion.y = lerp(0, -knockup, 0.6)
	motion = move_and_slide(motion, UP)
	hit = true
	blink()
	if lifebar != null:
		lifebar.damage(DAMAGE)	

func blink() -> void:
	anim_eyes.play("damage")
	player_visible(false)
	yield(get_tree().create_timer(0.05), "timeout")
	player_visible(true)
	yield(get_tree().create_timer(0.07), "timeout")
	player_visible(false)
	anim_eyes.play("blinking")
	for _i in range(6):
		yield(get_tree().create_timer(0.1), "timeout")
		player_visible(true)
		yield(get_tree().create_timer(0.1), "timeout")
		player_visible(false)
	player_visible(true)
	hit = false

func _powerup(type):
	match type:
		0: # Speed
			max_speed = MAX_SPEED_POWERUP
			yield(get_tree().create_timer(5), "timeout")
			max_speed = MAX_SPEED_NORMAL
		1: # Jump
			max_jump_height = MAX_JUMP_HEIGHT_POWERUP
			yield(get_tree().create_timer(5), "timeout")
			max_jump_height = MAX_JUMP_HEIGHT_NORMAL

func _on_DropPlataformArea_body_exited(_body):
	set_collision_mask_bit(DROP_THRU_BIT, true)
