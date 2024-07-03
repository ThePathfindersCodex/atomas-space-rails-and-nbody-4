extends Node2D

@export var bigG=  50
var orbSceneTemplate = preload("res://Orb.tscn")
var display_step = 0.1
var max_distance_allowed = 20000	

func _ready():
	get_node("CanvasLayer/HSlider").set_value(0.25)
	$CanvasLayer/labelTimeScale.text = str(Engine.time_scale)

var totalDelta	= 0.0	
var gameTick = 0
func _process(delta):
	totalDelta += delta
	
	if gameTick < int(totalDelta):
		gameTick =  int(totalDelta)
		doGameTick()
		
	$CanvasLayer/labelTotalDelta.text = str(gameTick)

	if focus_node!=null and is_instance_valid(focus_node) :
		$Camera2D.position = focus_node.global_position	

func doGameTick():
	pass
func updateUI(_data):
	pass
	
var bypass_slider_signals = false

func _on_HSlider_value_changed(value):
	$CanvasLayer/labelTimeScale.text = str(value)
	Engine.time_scale = value

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var new_orb = orbSceneTemplate.instantiate()
			add_child(new_orb,true)
			new_orb.self_mass = 100
			new_orb.global_position = get_global_mouse_position()
			
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var new_orb = orbSceneTemplate.instantiate()
			add_child(new_orb,true)
			new_orb.self_mass = 100
			new_orb.global_position = get_global_mouse_position()
			new_orb.orbitalVelocity = new_orb.circle_orbit($Star.get_node("MassBody"), new_orb) + new_orb.circle_orbit($Star, new_orb)
#			new_orb.orbitalVelocity = new_orb.circle_orbit($Star, new_orb)

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoomIn()
	
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoomOut()

var zoomMinVal=0.020
var zoomMaxVal=.8
var zoomInterval=0.005
func dynamic_zoom_level(z):
	return remap(z,0,1,zoomMinVal,zoomMaxVal)
func dynamic_zoom_level_reverse(z):
	return remap(z,zoomMinVal,zoomMaxVal,0,1)
func zoomIn():
	if $Camera2D.zoom.x < zoomMaxVal:
		$Camera2D.zoom = $Camera2D.zoom + Vector2(zoomInterval,zoomInterval)
		$CanvasLayer/VSlider.set_value(dynamic_zoom_level_reverse($Camera2D.zoom.x))
func zoomOut():
	if $Camera2D.zoom.x > zoomMinVal+(zoomInterval-.01):
		$Camera2D.zoom = $Camera2D.zoom - Vector2(zoomInterval,zoomInterval)
		$CanvasLayer/VSlider.set_value(dynamic_zoom_level_reverse($Camera2D.zoom.x))
func _on_VSlider_value_changed(value):
	$Camera2D.zoom = Vector2(dynamic_zoom_level(value),dynamic_zoom_level(value))
	
var focus_name = 'Star'
@onready var focus_node = $Star
func _on_TabContainer_tab_changed(tab):
	focus_name =$CanvasLayer/LogPanel/TabContainer.get_child(tab).name
	
	if focus_name=='star':
		focus_node = $Star
	else:	
		# TODO fix this
		focus_node = $Star.get_node_or_null(NodePath(focus_name))
		if focus_node==null:
			for nd in $Star.get_children():
				for nd2 in nd.get_children():
					if nd2.name == focus_name:
						focus_node = nd2
						break
					for nd3 in nd2.get_children():
						if nd3.name == focus_name:
							focus_node = nd3
							break					
	#last check - at Game level
	if focus_node == null:
		focus_node = get_node_or_null(NodePath(focus_name))

var logMsgs = Array()
var logMaxMsgs = 10
func logMsg(msg,clear_first=false,tab='general'):
	
	if $CanvasLayer/LogPanel/TabContainer.get_node_or_null(NodePath(tab)) == null:
		var new_label = Label.new()
		new_label.name = tab
		new_label.text = msg
		new_label.add_theme_font_size_override("font_size", 12)
		$CanvasLayer/LogPanel/TabContainer.add_child(new_label)
		
		# TODO: use resources for simpler styling
		var new_button = Button.new()
		new_button.name = tab
		new_button.text = tab
		new_button.add_theme_font_size_override("font_size", 12)
		new_button.connect("pressed", Callable(self, "_on_Button_pressed").bind(tab))
		if "-traj" in tab:
			new_button.add_theme_color_override("font_color", Color.DIM_GRAY)
			new_button.add_theme_color_override("font_color_focus", Color.DIM_GRAY )
			new_button.add_theme_color_override("font_color_hover", Color.DIM_GRAY)
			new_button.alignment = MOUSE_BUTTON_LEFT
		elif "Orb" in tab:
			new_button.add_theme_color_override("font_color", Color.ORANGE_RED )			
			new_button.add_theme_color_override("font_color_focus", Color.ORANGE_RED )			
			new_button.add_theme_color_override("font_color_hover", Color.ORANGE_RED )
			new_button.alignment = MOUSE_BUTTON_LEFT	
		else:
			new_button.alignment = MOUSE_BUTTON_LEFT	
			
		$CanvasLayer/ObjectsPanel/VBoxContainer.add_child(new_button)
		
	else:
		if clear_first:
			logMsgs.clear()
		logMsgs.append(msg)
		if logMsgs.size() > logMaxMsgs:
			logMsgs.remove(0)
		$CanvasLayer/LogPanel/TabContainer.get_node(NodePath(tab)).text = "\n".join(PackedStringArray(logMsgs))

func removeTab(newName):
	if $CanvasLayer/LogPanel/TabContainer.get_node_or_null(NodePath(newName)) != null:
		$CanvasLayer/LogPanel/TabContainer.get_node(NodePath(newName)).queue_free()

	if $CanvasLayer/ObjectsPanel/VBoxContainer.get_node_or_null(NodePath(newName)) != null:
		$CanvasLayer/ObjectsPanel/VBoxContainer.get_node(NodePath(newName)).queue_free()


func _on_Game_draw():
	draw_arc(Vector2.ZERO, max_distance_allowed, 0, TAU, 1000, Color.RED,200)
	draw_arc(Vector2.ZERO, max_distance_allowed+10000, 0, TAU, 1000, Color.BLACK,20000)
	


func _on_Button_pressed(tab="star"):
	var found_idx=find_tab_index_by_name(tab)
	if found_idx >= 0:
		$CanvasLayer/LogPanel/TabContainer.set_current_tab(found_idx)

func find_tab_index_by_name(tab):
	for idx in $CanvasLayer/LogPanel/TabContainer.get_child_count():
		if $CanvasLayer/LogPanel/TabContainer.get_child(idx).name == tab:
				return idx


