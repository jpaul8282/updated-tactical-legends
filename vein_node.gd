# vein_node.gd
extends Area2D
# Vein Node: player interaction and reboot logic

@export var reboot_time: float = 3.0
@export var required_fragments: int = 3
@export var is_active: bool = false
@export var reboot_effect_scene: PackedScene

# animation names (optional)
@export var active_anim: String = "active"
@export var idle_anim: String = "idle"
@export var progress_anim: String = "reboot"

onready var anim: AnimatedSprite2D = $AnimatedSprite2D
onready var reboot_timer: Timer = $RebootTimer

func _ready():
    reboot_timer.one_shot = true
    reboot_timer.wait_time = reboot_time
    if not is_connected("body_entered", Callable(self, "_on_body_entered")):
        body_entered.connect(_on_body_entered)
    if anim:
        anim.play(idle_anim) if anim.has_animation(idle_anim) else null

# Called when a body enters (player)
func _on_body_entered(body):
    if is_active:
        return
    if not body.is_in_group("players"):
        return
    # Attempt to auto-reboot if player has resources
    if player_has_resources(body):
        # start reboot progress
        reboot_timer.start()
        if anim and anim.has_animation(progress_anim):
            anim.play(progress_anim)
        # lock player control? optional: call a method on player to disable actions
        # connect timeout
        if not reboot_timer.is_connected("timeout", Callable(self, "_on_RebootTimer_timeout")):
            reboot_timer.timeout.connect(_on_RebootTimer_timeout)

# Alternate manual interaction method (used by player's interact action)
func player_try_reboot(player):
    if is_active:
        return false
    if not player_has_resources(player):
        # optionally show UI hint (insufficient fragments)
        return false
    reboot_timer.start()
    if anim and anim.has_animation(progress_anim):
        anim.play(progress_anim)
    if not reboot_timer.is_connected("timeout", Callable(self, "_on_RebootTimer_timeout")):
        reboot_timer.timeout.connect(_on_RebootTimer_timeout)
    return true

func _on_RebootTimer_timeout():
    perform_reboot()

func perform_reboot():
    is_active = true
    if anim and anim.has_animation(active_anim):
        anim.play(active_anim)
    if reboot_effect_scene:
        var fx = reboot_effect_scene.instantiate()
        fx.global_position = global_position
        get_tree().current_scene.add_child(fx)
    # heal nearby players
    heal_nearby_players()
    # emit a signal if other systems want to know (optional)
    if has_signal("vein_rebooted"):
        emit_signal("vein_rebooted", self)

func player_has_resources(player) -> bool:
    # Expected convention: player has method `consume_fragments(count)` that returns true if consumed
    if player.has_method("consume_fragments"):
        return player.consume_fragments(required_fragments)
    # If no method present on player, assume success for prototyping
    return true

func heal_nearby_players():
    var radius = 120.0
    for p in get_tree().get_nodes_in_group("players"):
        if p is Node2D and p.global_position.distance_to(global_position) <= radius:
            if p.has_method("add_resolve"):
                p.add_resolve(12)
