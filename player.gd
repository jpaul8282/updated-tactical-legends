# player.gd
extends CharacterBody2D
# Godot 4.x — Player core logic: movement, dash, heat, shooting, interaction

@export_category("Movement")
@export var walk_speed: float = 220.0
@export var accel: float = 2200.0
@export var friction: float = 1800.0
@export var jump_velocity: float = 460.0
@export var gravity: float = 1500.0

@export_category("Dash")
@export var dash_speed: float = 520.0
@export var dash_duration: float = 0.18
@export var dash_stamina_cost: float = 20.0

@export_category("Stamina / Resolve")
@export var max_stamina: float = 100.0
@export var stamina_recovery_per_sec: float = 18.0
@export var max_resolve: float = 100.0

@export_category("Heat")
@export var max_heat: float = 100.0
@export var heat_increase_rate: float = 6.0
@export var heat_decrease_rate: float = 10.0

@export_category("Shooting")
@export var glyph_scene: PackedScene
@export var fire_rate: float = 0.16 # seconds between shots

# runtime state
var velocity: Vector2 = Vector2.ZERO
var stamina: float
var resolve: float
var heat: float
var is_dashing: bool = false
var wanted_velocity_x: float = 0.0

onready var sprite: AnimatedSprite2D = $Sprite
onready var muzzle: Marker2D = $Muzzle
onready var shoot_timer: Timer = $ShootTimer
onready var dash_timer: Timer = $DashTimer
onready var interaction_area: Area2D = $InteractionArea

func _ready():
    stamina = max_stamina
    resolve = max_resolve
    heat = 0.0
    shoot_timer.wait_time = fire_rate
    shoot_timer.one_shot = false
    # connect timers
    if not shoot_timer.is_connected("timeout", Callable(self, "_on_ShootTimer_timeout")):
        shoot_timer.timeout.connect(_on_ShootTimer_timeout)
    if not dash_timer.is_connected("timeout", Callable(self, "_on_DashTimer_timeout")):
        dash_timer.timeout.connect(_on_DashTimer_timeout)
    # add player to players group for enemies to find
    add_to_group("players")
    # connect interaction area
    if not interaction_area.is_connected("body_entered", Callable(self, "_on_InteractionArea_body_entered")):
        interaction_area.body_entered.connect(_on_InteractionArea_body_entered)

func _physics_process(delta):
    handle_gravity(delta)
    handle_input(delta)
    apply_movement(delta)
    update_heat(delta)
    recover_stamina(delta)
    update_animation()

# --- INPUT / ACTIONS ---
func handle_input(delta):
    var left = Input.is_action_pressed("move_left")
    var right = Input.is_action_pressed("move_right")
    var dir = int(right) - int(left)
    wanted_velocity_x = dir * walk_speed

    # Jump
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = -jump_velocity

    # Dash
    if Input.is_action_just_pressed("dash") and stamina >= dash_stamina_cost and not is_dashing:
        start_dash(dir)

    # Shooting
    if Input.is_action_just_pressed("shoot"):
        attempt_shoot()
        if shoot_timer.is_stopped():
            shoot_timer.start()
    elif Input.is_action_just_released("shoot"):
        if not shoot_timer.is_stopped():
            shoot_timer.stop()

    # Interact (manual)
    if Input.is_action_just_pressed("interact"):
        # send a "try_interact" signal to all bodies inside InteractionArea
        for b in interaction_area.get_overlapping_bodies():
            if b and b.has_method("player_try_reboot"):
                b.player_try_reboot(self)

func start_dash(dir):
    var dash_dir = dir
    if dash_dir == 0:
        dash_dir = -1 if sprite.flip_h else 1
    is_dashing = true
    stamina = max(0.0, stamina - dash_stamina_cost)
    velocity.x = dash_dir * dash_speed
    dash_timer.start(dash_duration)
    if sprite.has_animation("dash"):
        sprite.play("dash")

func _on_DashTimer_timeout():
    is_dashing = false

# --- SHOOTING ---
func attempt_shoot():
    if glyph_scene == null:
        return
    spawn_glyph()

func _on_ShootTimer_timeout():
    spawn_glyph()

func spawn_glyph():
    if glyph_scene == null:
        return
    var aim_dir = get_aim_direction()
    if aim_dir == Vector2.ZERO:
        aim_dir = Vector2.RIGHT if not sprite.flip_h else Vector2.LEFT
    var glyph = glyph_scene.instantiate()
    glyph.global_position = muzzle.global_position
    glyph.setup(aim_dir, self)
    get_tree().current_scene.add_child(glyph)

func get_aim_direction() -> Vector2:
    # Mouse aim: prefer mouse if window has focus
    if get_viewport().get_mouse_position() != null:
        var mouse_world = get_global_mouse_position()
        var d = (mouse_world - muzzle.global_position)
        if d.length() > 6:
            return d.normalized()
    # fallback: facing direction
    return Vector2.ZERO

# --- MOVEMENT & PHYSICS ---
func handle_gravity(delta):
    if not is_on_floor():
        velocity.y += gravity * delta
    else:
        if velocity.y > 0:
            velocity.y = 0

func apply_movement(delta):
    if is_dashing:
        # slight drag
        velocity.x = lerp(velocity.x, 0, 6 * delta)
    else:
        # accelerate toward wanted velocity
        var diff = wanted_velocity_x - velocity.x
        var step = accel * delta
        if abs(diff) <= step:
            velocity.x = wanted_velocity_x
        else:
            velocity.x += sign(diff) * step
        # friction
        if abs(wanted_velocity_x) < 0.01 and is_on_floor():
            velocity.x = move_toward(velocity.x, 0, friction * delta)

    velocity = move_and_slide(velocity, Vector2.UP)
    # update facing
    if velocity.x > 6:
        sprite.flip_h = false
    elif velocity.x < -6:
        sprite.flip_h = true

func recover_stamina(delta):
    stamina = clamp(stamina + stamina_recovery_per_sec * delta, 0, max_stamina)

# --- HEAT & EFFECTS ---
func update_heat(delta):
    # Simplified: use Y position as "sun intensity": lower Y = higher heat (example)
    # Replace with environment queries for accurate behavior.
    var in_sun = true
    # If InteractionArea overlaps a node tagged "shade_zone" we'd consider not in sun (not implemented here)
    if in_sun:
        heat = clamp(heat + heat_increase_rate * delta, 0, max_heat)
    else:
        heat = clamp(heat - heat_decrease_rate * delta, 0, max_heat)
    if heat >= max_heat * 0.9:
        # TODO: apply hallucination effect (shader param)
        pass

# --- ANIMATION ---
func update_animation():
    if is_dashing:
        return
    if not is_on_floor():
        if velocity.y < 0:
            sprite.play("jump") if sprite.has_animation("jump") else sprite.play("idle")
        else:
            sprite.play("fall") if sprite.has_animation("fall") else sprite.play("idle")
    elif abs(velocity.x) > 10:
        sprite.play("run") if sprite.has_animation("run") else sprite.play("idle")
    else:
        sprite.play("idle")

# --- RESOLVE (health-like) ---
func add_resolve(amount: float):
    resolve = clamp(resolve + amount, 0, max_resolve)
    if resolve <= 0:
        on_resolve_depleted()

func on_resolve_depleted():
    # placeholder: inform level manager or trigger corruption mode
    print("Resolve depleted — trigger corruption")

# InteractionArea callback (optional)
func _on_InteractionArea_body_entered(body):
    # if the body is a VeinNode, try to interact automatically
    if body and body.has_method("player_try_reboot"):
        body.player_try_reboot(self)
