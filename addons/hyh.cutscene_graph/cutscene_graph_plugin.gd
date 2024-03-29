@tool
extends EditorPlugin

const Logging = preload("utility/Logging.gd")
const CutsceneGraphEditor = preload("editor/CutsceneGraphEditor.tscn")
const Cutscene = preload("editor/Cutscene.gd")
const GraphTypeEditDialog = preload("editor/graph_types_edit/GraphTypeEditDialog.tscn")
const GraphTypeEditDialogClass = preload("editor/graph_types_edit/GraphTypeEditDialog.gd")
const DialogueTypesEditDialog = preload("editor/dialogue_types_edit/DialogueTypesEditDialog.tscn")
const DialogueTypesEditDialogClass = preload("editor/dialogue_types_edit/DialogueTypesEditDialog.gd")
const ChoiceTypesEditDialog = preload("editor/choice_types_edit/ChoiceTypesEditDialog.tscn")
const ChoiceTypesEditDialogClass = preload("editor/choice_types_edit/ChoiceTypesEditDialog.gd")
const PropertyDefinitionEditDialog = preload("editor/property_definition_edit/PropertyDefinitionEditDialog.tscn")
const PropertyDefinitionEditDialogClass = preload("editor/property_definition_edit/PropertyDefinitionEditDialog.gd")
#const CutsceneGraph = preload("resources/CutsceneGraph.gd")
const CustomPropertyInspectorPlugin = preload("editor/inspector/custom_property_edit/CustomPropertyInspectorPlugin.gd")


var editor_host
var editor
var editor_button
var expand_button
var menu
var _custom_inspector : CustomPropertyInspectorPlugin

var _current_graph_is_in_scene

var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)


enum ToolMenuItems {
	EDIT_GRAPH_TYPES,
	EDIT_DIALOGUE_TYPES,
	EDIT_CHOICE_TYPES,
	EDIT_PROPERTY_DEFINITIONS,
}


func _enter_tree():
	#add_custom_type("CutsceneGraph", "Resource", preload("resources/CutsceneGraph.gd"), preload("icon_graph_node.svg"))
	#add_custom_type("Character", "Resource", preload("resources/Character.gd"), preload("icon_sprite.svg"))
	#add_custom_type("CharacterVariant", "Resource", preload("resources/CharacterVariant.gd"), preload("icon_texture_rect.svg"))
	# TODO: Need a new icon for these - should be white at the very least, like other Node-derived types
	add_custom_type("CutsceneController", "Node", preload("editor/CutsceneController.gd"), preload("icons/icon_cutscene_controller.svg"))
	add_custom_type("Cutscene", "Node", preload("editor/Cutscene.gd"), preload("icons/icon_chat.svg"))
	add_custom_type("CutsceneVariableStore", "Node", preload("editor/CutsceneVariableStore.gd"), preload("icons/icon_datastore.svg"))
	
	# Add inspector plugins
	_custom_inspector = CustomPropertyInspectorPlugin.new()
	add_inspector_plugin(_custom_inspector)
	
	# Check if the settings exist, and create some defaults if necessary
	_create_default_project_settings()
	
	_create_editor_host()
	_create_menu()


func _create_default_project_settings():
	if not ProjectSettings.has_setting("cutscene_graph_editor/graph_types"):
		ProjectSettings.set_setting(
			"cutscene_graph_editor/graph_types",
			[
				{
					"name": "dialogue",
					"split_dialogue": true,
					"default": true
				},
				{
					"name": "cutscene",
					"split_dialogue": true,
					"default": false
				}
			]
		)
	if not ProjectSettings.has_setting("cutscene_graph_editor/dialogue_types"):
		ProjectSettings.set_setting(
			"cutscene_graph_editor/dialogue_types",
			[
				{
					"name": "dialogue",
					"split_dialogue": null,
					"involves_character": true,
					"allowed_in_graph_types": [
						"dialogue",
						"cutscene",
					],
					"default_in_graph_types": [
						"dialogue",
						"cutscene",
					],
				},
				{
					"name": "narration",
					"split_dialogue": null,
					"involves_character": false,
					"allowed_in_graph_types": [
						"dialogue",
						"cutscene",
					],
					"default_in_graph_types": [],
				},
			]
		)
	if not ProjectSettings.has_setting("cutscene_graph_editor/choice_types"):
		ProjectSettings.set_setting(
			"cutscene_graph_editor/choice_types",
			[
				{
					"name": "choice",
					"include_dialogue": false,
					"skip_for_repeat": false,
					"allowed_in_graph_types": [
						"dialogue",
						"cutscene",
					],
					"default_in_graph_types": [],
				},
				{
					"name": "choice_with_dialogue",
					"include_dialogue": true,
					"skip_for_repeat": false,
					"allowed_in_graph_types": [
						"dialogue",
						"cutscene",
					],
					"default_in_graph_types": [
						"dialogue",
						"cutscene",
					],
				},
			]
		)
	ProjectSettings.save()


func _create_editor_host():
	Logger.debug("Creating host...")
	editor_host = preload("editor/CutsceneGraphEditorHost.tscn").instantiate()
	editor_button = add_control_to_bottom_panel(editor_host, _get_plugin_name())
	_get_editor()
	
	var button_parent = editor_button.get_parent().get_parent()
	# Caution: this method of obtaining the expand button could break at any time
	expand_button = button_parent.get_child(button_parent.get_child_count() - 1)


func _get_editor():
	Logger.debug("Getting editor from host...")
	editor = editor_host.editor
	editor.save_requested.connect(
		_save_requested
	)
	editor_host.expand_button_toggled.connect(
		_editor_expand_button_toggled
	)
	editor.display_filesystem_path_requested.connect(
		_display_filesystem_path_requested
	)
	editor.graph_edited.connect(
		_graph_edited
	)
	editor.current_graph_modified.connect(
		_current_graph_modified
	)
	#editor_host.ready.disconnect(_get_editor)
	return editor


func _graph_edited(graph):
	get_editor_interface().edit_resource(graph)


func _current_graph_modified():
	if _current_graph_is_in_scene:
		# This is not available until 4.1
		# I don't see a way to do this in earlier versions.
		var interface = get_editor_interface()
		if interface.has_method("mark_scene_as_unsaved"):
			get_editor_interface().mark_scene_as_unsaved()


func _display_filesystem_path_requested(path):
	Logger.debug("Navigating to path %s" % path)
	get_editor_interface().get_file_system_dock().navigate_to_path(path)


func _editor_expand_button_toggled(button_pressed):
	get_editor_interface().distraction_free_mode = button_pressed
	expand_button.set_pressed(button_pressed)


func _create_menu():
	menu = PopupMenu.new()
	menu.add_item("Edit Graph Types...", ToolMenuItems.EDIT_GRAPH_TYPES)
	menu.add_item("Edit Dialogue Types...", ToolMenuItems.EDIT_DIALOGUE_TYPES)
	menu.add_item("Edit Choice Types...", ToolMenuItems.EDIT_CHOICE_TYPES)
	menu.add_item("Edit Property Definitions...", ToolMenuItems.EDIT_PROPERTY_DEFINITIONS)
	menu.id_pressed.connect(_tool_menu_item_selected)
	
	add_tool_submenu_item("Cutscene Graph Editor", menu)


func _tool_menu_item_selected(id):
	match id:
		ToolMenuItems.EDIT_GRAPH_TYPES:
			_show_edit_graph_types_dialog()
		ToolMenuItems.EDIT_DIALOGUE_TYPES:
			_show_edit_dialogue_types_dialog()
		ToolMenuItems.EDIT_CHOICE_TYPES:
			_show_edit_choice_types_dialog()
		ToolMenuItems.EDIT_PROPERTY_DEFINITIONS:
			_show_edit_property_definitions_dialog()


func _show_edit_graph_types_dialog():
	var dialog = GraphTypeEditDialog.instantiate()
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	self.add_child(dialog)
	dialog.popup()
	await (dialog as GraphTypeEditDialogClass).closing
	dialog.hide()
	dialog.queue_free()


func _show_edit_dialogue_types_dialog():
	var dialog = DialogueTypesEditDialog.instantiate()
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	self.add_child(dialog)
	dialog.popup()
	await (dialog as DialogueTypesEditDialogClass).closing
	dialog.hide()
	dialog.queue_free()


func _show_edit_choice_types_dialog():
	var dialog = ChoiceTypesEditDialog.instantiate()
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	self.add_child(dialog)
	dialog.popup()
	await (dialog as ChoiceTypesEditDialogClass).closing
	dialog.hide()
	dialog.queue_free()


func _show_edit_property_definitions_dialog():
	var dialog = PropertyDefinitionEditDialog.instantiate()
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	self.add_child(dialog)
	dialog.popup()
	await (dialog as PropertyDefinitionEditDialogClass).closing
	dialog.hide()
	dialog.queue_free()


# Not sure the cause of this issue, but the editor member is being cleared after
# the first time the project is run. The control is still present in Godot, but
# finding it again isn't enough because that has a bunch of references cleared as
# well. However, finding it and recreating it gets around the issue.
# TODO: Need to determine if this is still required in Godot 4
func _reacquire_editor():
	Logger.debug("Reacquiring graph editor")
	var root = get_editor_interface().get_base_control()
	var node_stack = [] + root.get_children()
	while !node_stack.is_empty():
		var current = node_stack.pop_back()
		if current.name == "CutsceneGraphEditorHost":
			editor_host = current
			editor = editor_host.editor
			node_stack.clear()
		else:
			node_stack = node_stack + current.get_children()
	if editor_host == null:
		Logger.error("Editor not found")
	else:
		Logger.debug("Editor reacquired")
		remove_control_from_bottom_panel(editor_host)
		if editor_host != null:
			editor_host.free()
			editor = null
		_create_editor_host()


func _apply_changes():
	if editor != null:
		editor.perform_save()


func clear():
	if editor != null:
		_request_clear()


func _save_requested(object, path):
	if path != "" and object.resource_path != "":
		Logger.debug("Save requested to path %s" % path)
		Logger.debug("Resource.resource_path is %s" % object.resource_path)
		ResourceSaver.save(object, path)
	else:
		Logger.warn("Save requested but no resource path is available.")
	# Not sure if/why this was necessary?
	#ResourceLoader.load(path)


func _exit_tree():
	#remove_custom_type("CutsceneGraph")
	#remove_custom_type("Character")
	#remove_custom_type("CharacterVariant")
	remove_custom_type("CutsceneController")
	remove_custom_type("Cutscene")
	remove_custom_type("CutsceneVariableStore")
	remove_inspector_plugin(_custom_inspector)
	if editor != null:
		editor_host.expand_button_toggled.disconnect(
			_editor_expand_button_toggled
		)
		editor.save_requested.disconnect(
			_save_requested
		)
		editor.graph_edited.disconnect(_graph_edited)
		editor.current_graph_modified.disconnect(
			_current_graph_modified
		)
	remove_control_from_bottom_panel(editor_host)
	menu.id_pressed.disconnect(_tool_menu_item_selected)
	remove_tool_menu_item("Cutscene Graph Editor")
	if editor_host != null:
		editor_host.free()
		editor = null


func _get_plugin_name():
	return "Cutscene Graph"


func _get_plugin_icon():
	return preload("icons/icon_chat.svg")


func handles(object: Object) -> bool:
	return (object is CutsceneGraph or object is Cutscene)


func _handles(object: Object) -> bool:
	return handles(object)


func _make_visible(visible):
	if visible:
		make_bottom_panel_item_visible(editor_host)


func _edit(object):
	var graph
	if object is Cutscene:
		graph = object.cutscene
		_current_graph_is_in_scene = true
	else:
		graph = object
		_current_graph_is_in_scene = false
	if graph != null:
		var current_resource_path = graph.resource_path
		call_deferred("_request_edit", graph, current_resource_path)
	else:
		call_deferred("_request_clear")


func _request_edit(object, current_resource_path):
	if editor_host == null:
		_reacquire_editor()
	#if editor != null:
	editor.edit_graph(object, current_resource_path)


func _request_clear():
	Logger.debug("Clearing graph editor...")
	editor.clear()
