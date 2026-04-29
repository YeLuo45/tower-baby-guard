extends Node2D

## Tower Placer - manages tower placement grid and validation

signal tower_placed(tower: Node2D, position: Vector2)
signal placement_invalid(reason: String)

var occupied_cells: Dictionary = {}

func _ready() -> void:
	pass

func is_cell_occupied(cell_pos: Vector2) -> bool:
	return occupied_cells.has(cell_pos)

func occupy_cell(cell_pos: Vector2) -> void:
	occupied_cells[cell_pos] = true

func free_cell(cell_pos: Vector2) -> void:
	occupied_cells.erase(cell_pos)

func get_occupied_cells() -> Dictionary:
	return occupied_cells.duplicate()
