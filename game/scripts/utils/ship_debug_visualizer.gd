## Debug visualization for ship physics.
## Shows velocity vectors, thrust vectors, trajectory prediction, etc.
class_name ShipDebugVisualizer
extends Node3D

# -----------------------------------------------------------------------------
# Exports
# -----------------------------------------------------------------------------

@export_group("Target")
## The ship to visualize
@export var target_ship: RigidBody3D

@export_group("Visualization Options")
## Show velocity vector
@export var show_velocity: bool = true

## Show thrust vector
@export var show_thrust: bool = true

## Show trajectory prediction
@export var show_trajectory: bool = true

## Show orientation axes
@export var show_axes: bool = true

## Show collision shape
@export var show_collision: bool = false

@export_group("Vector Scales")
## Scale for velocity vector (visual length per m/s)
@export var velocity_scale: float = 0.1

## Scale for thrust vector
@export var thrust_scale: float = 0.001

## Length of orientation axes in meters
@export var axes_length: float = 5.0

@export_group("Trajectory Prediction")
## Number of trajectory points to predict
@export var trajectory_points: int = 50

## Time step between trajectory points (seconds)
@export var trajectory_step: float = 0.2

@export_group("Colors")
@export var velocity_color: Color = Color.CYAN
@export var thrust_color: Color = Color.ORANGE
@export var trajectory_color: Color = Color.GREEN
@export var axis_x_color: Color = Color.RED
@export var axis_y_color: Color = Color.GREEN
@export var axis_z_color: Color = Color.BLUE

# -----------------------------------------------------------------------------
# State
# -----------------------------------------------------------------------------

var _velocity_line: MeshInstance3D
var _thrust_line: MeshInstance3D
var _trajectory_line: MeshInstance3D
var _axis_x_line: MeshInstance3D
var _axis_y_line: MeshInstance3D
var _axis_z_line: MeshInstance3D

var _immediate_mesh: ImmediateMesh
var _material: StandardMaterial3D

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------

func _ready() -> void:
	_setup_visualization()


func _process(_delta: float) -> void:
	if not target_ship:
		return

	if show_velocity:
		_draw_velocity_vector()

	if show_thrust:
		_draw_thrust_vector()

	if show_trajectory:
		_draw_trajectory_prediction()

	if show_axes:
		_draw_orientation_axes()

# -----------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------

func _setup_visualization() -> void:
	# Create material
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.vertex_color_use_as_albedo = true

	# Create mesh for drawing
	_immediate_mesh = ImmediateMesh.new()

	# Create mesh instance
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _immediate_mesh
	mesh_instance.material_override = _material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_instance)

# -----------------------------------------------------------------------------
# Drawing Functions
# -----------------------------------------------------------------------------

func _draw_velocity_vector() -> void:
	if not target_ship:
		return

	var velocity := target_ship.linear_velocity
	if velocity.length_squared() < 0.1:
		return

	var start := target_ship.global_position
	var end := start + velocity * velocity_scale

	_draw_arrow(start, end, velocity_color)


func _draw_thrust_vector() -> void:
	if not target_ship or not target_ship is ShipBase:
		return

	var ship := target_ship as ShipBase
	if ship.thrust_input.is_zero_approx():
		return

	# Calculate thrust force
	var thrust_force := Vector3.ZERO
	thrust_force.z = -ship.thrust_input.z * ship.thrust_main
	thrust_force.x = ship.thrust_input.x * ship.thrust_maneuver
	thrust_force.y = ship.thrust_input.y * ship.thrust_maneuver

	if ship.is_boosting:
		thrust_force *= ship.boost_multiplier

	# Transform to world space
	var world_thrust := ship.global_transform.basis * thrust_force

	var start := ship.global_position
	var end := start + world_thrust * thrust_scale

	_draw_arrow(start, end, thrust_color)


func _draw_trajectory_prediction() -> void:
	if not target_ship:
		return

	var points: PackedVector3Array = []
	var pos := target_ship.global_position
	var vel := target_ship.linear_velocity

	# Simple ballistic trajectory (no thrust)
	for i in trajectory_points:
		points.append(pos)
		pos += vel * trajectory_step

	_draw_line_strip(points, trajectory_color)


func _draw_orientation_axes() -> void:
	if not target_ship:
		return

	var origin := target_ship.global_position
	var basis := target_ship.global_transform.basis

	# X axis (right) - Red
	_draw_line(origin, origin + basis.x * axes_length, axis_x_color)

	# Y axis (up) - Green
	_draw_line(origin, origin + basis.y * axes_length, axis_y_color)

	# Z axis (back) - Blue (forward is -Z)
	_draw_line(origin, origin + basis.z * axes_length, axis_z_color)

# -----------------------------------------------------------------------------
# Primitive Drawing
# -----------------------------------------------------------------------------

func _draw_line(from: Vector3, to: Vector3, color: Color) -> void:
	_immediate_mesh.clear_surfaces()
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	_immediate_mesh.surface_set_color(color)
	_immediate_mesh.surface_add_vertex(from)
	_immediate_mesh.surface_add_vertex(to)

	_immediate_mesh.surface_end()


func _draw_line_strip(points: PackedVector3Array, color: Color) -> void:
	if points.size() < 2:
		return

	_immediate_mesh.clear_surfaces()
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	_immediate_mesh.surface_set_color(color)
	for point in points:
		_immediate_mesh.surface_add_vertex(point)

	_immediate_mesh.surface_end()


func _draw_arrow(from: Vector3, to: Vector3, color: Color) -> void:
	# Draw main line
	_immediate_mesh.clear_surfaces()
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	_immediate_mesh.surface_set_color(color)
	_immediate_mesh.surface_add_vertex(from)
	_immediate_mesh.surface_add_vertex(to)

	# Draw arrowhead
	var direction := (to - from).normalized()
	var perpendicular := Vector3.UP.cross(direction).normalized()
	if perpendicular.length_squared() < 0.1:
		perpendicular = Vector3.RIGHT.cross(direction).normalized()

	var arrow_size := (to - from).length() * 0.1
	var arrow_base := to - direction * arrow_size

	# Two lines for arrowhead
	var side1 := arrow_base + perpendicular * arrow_size * 0.5
	var side2 := arrow_base - perpendicular * arrow_size * 0.5

	_immediate_mesh.surface_add_vertex(to)
	_immediate_mesh.surface_add_vertex(side1)
	_immediate_mesh.surface_add_vertex(to)
	_immediate_mesh.surface_add_vertex(side2)

	_immediate_mesh.surface_end()

# -----------------------------------------------------------------------------
# Public Interface
# -----------------------------------------------------------------------------

## Toggle visualization on/off
func set_visualization_enabled(enabled: bool) -> void:
	visible = enabled


## Set which visualizations to show
func set_options(velocity: bool, thrust: bool, trajectory: bool, axes: bool) -> void:
	show_velocity = velocity
	show_thrust = thrust
	show_trajectory = trajectory
	show_axes = axes
