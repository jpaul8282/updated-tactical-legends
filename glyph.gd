# glyph.gd
extends Area2D
# Generic glyph projectile: supports piercing, homing, basic damage on contact

@export var speed: float = 520.0
@export var lifetime: float = 3.0
@export var damage: int = 12
@export var piercing: bool = false
@export var homing: bool = false
@export var homing_strength: float = 6.0
@export var rotation_speed: float = 0.0 # optional visual rotation

var direction: Vector2 = Vector2.RIGHT
var owner: Node = null
var life_timer: Timer

onready var life_t: Timer = $LifeTimer

func _ready():
    life_t.wait_time = lifetime
    life_t.one_shot = true
    life_t.start()
    if not life_t.is_connected("timeout", Callable(self, "_on_LifeTimer_timeout")):
        life_t.timeout.connect(_on_LifeTimer_timeout)
    connect("area_entered", Callable(self, "_on_area_entered"))

func setup(aim_dir: Vector2, owner_node: Node) -> void:
    direction = aim_dir.normalized() if aim_dir.length() > 0 else Vector2.RIGHT
    owner = owner_node
    rotation = direction.angle()

func _process(delta):
    if homing:
        var target = find_nearest_enemy(400)
        if target:
            var to_target = (target.global_position - global_position).normalized()
            direction = direction.lerp(to_target, homing_strength * delta).normalized()
            rotation = direction.angle()
    global_position += direction * speed * delta
    if rotation_speed != 0:
        rotation += rotation_speed * delta

func _on_LifeTimer_timeout():
    queue_free()

func _on_area_entered(area: Area2D):
    # Ignore collisions with owner and their children
    if owner and (area == owner or area.is_in_group(owner.name)):
        return
    # Damage enemies (they should implement apply_damage(amount, source))
    if area.get_parent() and area.get_parent().has_method("apply_damage"):
        area.get_parent().apply_damage(damage, owner)
        spawn_impact_vfx()
        if not piercing:
            queue_free()
        return
    # If the collided object itself has apply_damage()
    if area.has_method("apply_damage"):
        area.apply_damage(damage, owner)
        spawn_impact_vfx()
        if not piercing:
            queue_free()
        return
    # otherwise, hit environment
    spawn_impact_vfx()
    if not piercing:
        queue_free()

func spawn_impact_vfx():
    # placeholder — add particles / sound spawn
    pass

func find_nearest_enemy(radius: float) -> Node2D:
    var best: Node2D = null
    var best_d = radius
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if not enemy is Node2D:
            continue
        var d = global_position.distance_to(enemy.global_position)
        if d < best_d:
            best_d = d
            best = enemy
    return best
