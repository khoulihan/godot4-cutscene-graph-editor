@tool
extends "GraphNodeBase.gd"

enum VariableScope {
	SCOPE_TRANSIENT,
	SCOPE_CUTSCENE,
	SCOPE_LOCAL,
	SCOPE_GLOBAL
}

# These match the Variant.Type enum... which I could not reference directly
# for some reason. Anyway we only need a few of them.
enum VariableType {
	TYPE_BOOL = 1,
	TYPE_INT = 2,
	TYPE_FLOAT = 3,
	TYPE_STRING = 4
}

@export var scope: VariableScope
@export var variable: String
@export var variable_type: VariableType

var value_expression

# This is used only for recreating the node state in the editor
@export var size: Vector2


# This is necessary to ensure that "value" is saved to the resource
func _get_property_list():
	var properties = []
	properties.append({
		"name": "value_expression",
		"type": null,
		"usage": PROPERTY_USAGE_STORAGE,
	})
	return properties


func get_value_expression():
	return value_expression


func set_value_expression(val):
	value_expression = val


func _init():
	super._init()
	if variable_type == null:
		variable_type = VariableType.TYPE_STRING
	elif variable_type == 0:
		variable_type = VariableType.TYPE_BOOL
