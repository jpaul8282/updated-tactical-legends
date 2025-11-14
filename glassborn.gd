# glassborn.gd
extends CharacterBody2D
# Mid-tier enemy: chases player, performs leap attack, spawns shards on death

@export var speed: float = 100.0
@export var leap_speed: float = 460.0
@export var leap_cooldown: float = 2.0
@export var max_health: int = 40
@export var shard_scene: PackedScene
@export var shard_count_on_death: int = 6
@export var detection_radius: float = 380.0

var health: int
var target: Node2D = null
var can_leap: bool = true

onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
onready var leap_timer: Timer = $LeapCooldown

func _ready():
    health = max_health
    add_to_group("enemies")
    leap_timer.one_shot = true
    leap_timer.wait_time = leap_cooldown
    if not leap_timer.is_connected("timeout", Callable(self, "_on_LeapCooldown_timeout")):
        leap_timer.timeout.connect(_on_LeapCooldown_timeout)

func _physics_process(delta):
    acquire_target()
    if target:
        var dist = global_position.distance_to(target.global_position)
        if dist <= 140 and can_leap:
            do_leap_towards(target.global_position)
        else:
            # chase
            var dir = (target.global_position - global_position).normalized()
            velocity = dir * speed
            velocity = move_and_slide(velocity, Vector2.UP)
    else:
        velocity = Vector2.ZERO

    # animation
    if velocity.length() > 6:
        sprite.play("run") if sprite.has_animation("run") else sprite.play("idle")
    else:
        sprite.play("idle")

func do_leap_towards(dest: Vector2):
    can_leap = false
    var dir = (dest - global_position).normalized()
    # small impulse style leap: we simulate by setting velocity briefly
    velocity = dir * leap_speed
    # perform movement for a single physics frame as jump impulse then let physics continue
    move_and_slide(velocity, Vector2.UP)
    leap_timer.start()

func _on_LeapCooldown_timeout():
    can_leap = true

func apply_damage(amount: int, source: Node) -> void:
    health -= amount
    if health <= 0:
        die()

func die():
    spawn_shards()
    queue_free()

func spawn_shards():
    if shard_scene == null:
        return
    for i in range(shard_count_on_death):
        var s = shard_scene.instantiate()
        s.global_position = global_position + Vector2(randf_range(-8,8), randf_range(-8,8))
        # if shard has init_velocity
        if s.has_method("init_velocity"):
            var v = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized() * randf_range(120,260)
            s.init_velocity(v)
        get_tree().current_scene.add_child(s)

func acquire_target():
    var best: Node2D = null
    var best_d = detection_radius
    for p in get_tree().get_nodes_in_group("players"):
        if not p is Node2D:
            continue
        var d = global_position.distance_to(p.global_position)
        if d < best_d:
            best_d = d
            best = p
    target = best

func randf_range(a: float, b: float) -> float:
    return a + randf() * (b - a)
