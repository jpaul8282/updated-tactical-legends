# sand_murmur.gd
extends CharacterBody2D
# Small swarm enemy that chases player and splits when hit by non-piercing glyphs

@export var speed: float = 90.0
@export var max_health: int = 12
@export var split_on_hit: bool = true
@export var split_count: int = 2
@export var detection_radius: float = 220.0
@export var min_scale_on_split: float = 0.6

var health: int
var target: Node2D = null

onready var sprite: AnimatedSprite2D = $Sprite
onready var split_timer: Timer = $SplitCooldownTimer

func _ready():
    health = max_health
    add_to_group("enemies")
    split_timer.one_shot = true
    split_timer.wait_time = 0.25

func _physics_process(delta):
    acquire_target()
    if target:
        var dir = (target.global_position - global_position).normalized()
        velocity = dir * speed
    else:
        velocity = Vector2.ZERO
    velocity = move_and_slide(velocity, Vector2.UP)
    # basic animation switching
    if velocity.length() > 6:
        sprite.play("run") if sprite.has_animation("run") else sprite.play("idle")
    else:
        sprite.play("idle")

func apply_damage(amount: int, source: Node) -> void:
    health -= amount
    # if hit by piercing projectile, we still take damage but splitting might be different
    if health <= 0:
        die()
        return
    # trigger split (but cooldown)
    if split_on_hit and not split_timer.is_stopped():
        return
    if split_on_hit:
        split_timer.start()
        split_into_snippets()

func split_into_snippets():
    var scene_path = "res://SandMurmur.tscn"
    var base_scene: PackedScene = preload(scene_path)
    for i in range(split_count):
        var inst = base_scene.instantiate()
        inst.global_position = global_position + Vector2(randf_range(-8,8), randf_range(-8,8))
        inst.scale = self.scale * min_scale_on_split
        inst.max_health = max(3, int(max_health * 0.45))
        # small nudge so they fly outward
        if inst.has_method("velocity"):
            inst.velocity = Vector2(randf_range(-30,30), randf_range(-10,10))
        get_tree().current_scene.add_child(inst)

func die():
    # add VFX, drop etc.
    queue_free()

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
