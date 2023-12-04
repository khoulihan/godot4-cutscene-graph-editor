@tool
extends "res://addons/hyh.cutscene_graph/editor/controls/expressions/MoveableExpression.gd"


@onready var _value_edit = get_node("PanelContainer/MC/ExpressionContainer/Header/VariableValueEdit")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func configure():
	super()
	_value_edit.variable_type = type


func validate():
	if _value_edit.is_selecting_variable():
		if _value_edit.get_selected_variable() == null:
			_validation_warning.visible = true
			_validation_warning.tooltip_text = "You must select a variable, or enter a constant value."
			return "Variable not selected."
	_validation_warning.visible = false


func _on_variable_value_edit_value_changed():
	modified.emit()
