extends Node2D
class_name Ellipse

@export var eccentricty:float = 0.0 # e
@export var semiMajorAxis:float = 0.0 # a
@export var enableDebugMsg=false

var center = Vector2.ZERO
var pivot = Vector2.ZERO
var semiMinorAxis:float=0.0
var majorAxis:float=0.0
var minorAxis:float=0.0
var fDistFromCenter=0.0
var focus1Pos=Vector2.ZERO
var focus2Pos=Vector2.ZERO
var v1=Vector2.ZERO
var v2=Vector2.ZERO
var v3=Vector2.ZERO
var v4=Vector2.ZERO

func logMsg(msg,clear_first=false,tab='ellipse'):
	get_parent().logMsg(msg,clear_first,tab)

func _ready():
	solve()

func solve():
	center = Vector2.ZERO
	
	majorAxis = semiMajorAxis*2
	semiMinorAxis = semiMajorAxis* sqrt(1-(eccentricty*eccentricty))
	minorAxis = semiMinorAxis*2

	v1=Vector2(-semiMajorAxis,0)
	v2=Vector2(0,semiMinorAxis)
	v3=Vector2(semiMajorAxis,0)
	v4=Vector2(0,-semiMinorAxis)

	fDistFromCenter = sqrt((semiMajorAxis*semiMajorAxis)-(semiMinorAxis*semiMinorAxis))
	focus1Pos = Vector2(-fDistFromCenter,0)
	focus2Pos = Vector2(fDistFromCenter,0)

	pivot = focus2Pos # TODO: this could be an export option on the Node - to anchor the node to a given point in the ellipse
#	pivot = focus1Pos
#	pivot = center 


var POINT_COUNT = 60
func _draw():
	draw_set_transform(-pivot,0,Vector2.ONE)
#	draw_circle(center,10.0,Color.white) # center

#	draw_circle(focus1Pos,20.0,Color.blue) # focus 1
#	draw_circle(focus2Pos,4.0,Color.red) # focus 2	
	
	draw_circle(v1,12.0,Color.RED) # v1
	draw_circle(v2,12.0,Color.BROWN) # v2
	draw_circle(v3,12.0,Color.GREEN) # v3
	draw_circle(v4,12.0,Color.PURPLE) # v4
	
	draw_set_transform(-pivot,0,Vector2(semiMajorAxis,semiMinorAxis))
	draw_arc(Vector2(0.0, 0.0), 1.0, 0.0, 2.0 * PI, POINT_COUNT, Color8(Color.WHITE.r8,Color.WHITE.g8,Color.WHITE.b8,30))
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	
	if enableDebugMsg:
		var solveStr = ''
		
		solveStr+='STATE\n'
		solveStr+='pos     '+str(position)+"\n"
		solveStr+='gpos    '+str(global_position)+"\n"
		solveStr+='rot     '+str(rotation)+"\n"
		solveStr+='rot deg '+str(rotation_degrees)+"\n"
		solveStr+='e       '+str(eccentricty)+"\n"
		solveStr+='a       '+str(semiMajorAxis)+"\n"
		solveStr+='b       '+str(semiMinorAxis)+"\n"
		solveStr+='\n'
		
		solveStr+='LOCAL\n'
		solveStr+='center  '+str(center)+"\n"
		solveStr+='pivot   '+str(pivot)+"\n"
		solveStr+='f1      '+str(focus1Pos)+"\n"
		solveStr+='f2      '+str(focus2Pos)+"\n"
		solveStr+='  v1    '+str(v1)+"\n"
		solveStr+='  v2    '+str(v2)+"\n"
		solveStr+='  v3    '+str(v3)+"\n"
		solveStr+='  v4    '+str(v4)+"\n"
		solveStr+='\n'
		
		solveStr+='GLOBAL\n'
		solveStr+='center  '+str(get_center())+"\n"
		solveStr+='pivot   '+str(get_pivot())+"\n"
		solveStr+='f1      '+str(get_focus1())+"\n"
		solveStr+='f2      '+str(get_focus2())+"\n"
		solveStr+='  v1    '+str(get_v1())+"\n"
		solveStr+='  v2    '+str(get_v2())+"\n"
		solveStr+='  v3    '+str(get_v3())+"\n"
		solveStr+='  v4    '+str(get_v4())+"\n"
		solveStr+='\n'
		
		logMsg(solveStr,true,name)
	
func get_center():
	return Transform2D(rotation,position) * (center-pivot)
func get_pivot():
	return position	
func get_focus1():
	return Transform2D(rotation,position) * (focus1Pos-pivot)
func get_focus2():
	return Transform2D(rotation,position) * (focus2Pos-pivot)
func get_v1():
	return Transform2D(rotation,position) * (v1-pivot)
func get_v2():
	return Transform2D(rotation,position) * (v2-pivot)
func get_v3():
	return Transform2D(rotation,position) * (v3-pivot)
func get_v4():
	return Transform2D(rotation,position) * (v4-pivot)
	
