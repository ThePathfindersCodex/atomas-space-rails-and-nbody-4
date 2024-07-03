extends Node2D
class_name MassBody

@export var self_mass = 100.0
@export var orbitalVelocity=Vector2.ZERO

var parent_body = null

var semiMajorAxis=0.0
var eccentricty=0.0
var argPeri=0.0
var trueAnomaly=0.0

var eccentricAnomaly=0.0
var meanAnomaly=0.0
var pprime1=Vector2.ZERO
var pprime2=Vector2.ZERO

var orbitalVelocityf1 =Vector2.ZERO
var orbitalVelocityf2 =Vector2.ZERO
var orbitalVelocityNormal =Vector2.ZERO
var escapeVelocityMag=0.0
var focus1Pos=Vector2.ZERO
var focus2Pos=Vector2.ZERO
var periAp=Vector2.ZERO
var apoAp=Vector2.ZERO
var periApDistFromF2=0.0
var apoApDistFromF2=0.0

var ellipse=null

var SOIsize=0.0

func _ready():
	set_parent_mass(get_parent())
	solveFromStateVectors()
	
func set_parent_mass(node):
	parent_body=node
	
	#detach ellipse and move it to 0,0 on parent
	ellipse = $Ellipse
	ellipse.name = ellipse.name+'-'+self.name
	remove_child(ellipse)
	print('ADDING ', ellipse.name, ' TO ', parent_body.name)
	parent_body.call_deferred("add_child",ellipse)	

func updateUI(data):
	get_parent().updateUI(data)

var localTime=0.0 
func _physics_process(delta):
	if delta>0:
		localTime += delta
		
		#update position first from half the delta
		global_position+=orbitalVelocity*(delta/2)

		#then update veloc
		var u = parent_body.getBigG() * (self_mass + parent_body.self_mass)
		var dist2 = position.distance_squared_to(ellipse.get_focus2())
		var dir = position.direction_to(ellipse.get_focus2()).normalized()
		var accel = dir * u /  (dist2)
		orbitalVelocity += accel * (delta)
		
		#then update the position again with the other half of delta
		global_position+=orbitalVelocity*(delta/2)

		# solve and redraw
		solveFromStateVectors()
		redraw()
		
		# update ui
		var data = {
			"name":name,
			"semiMajorAxis":semiMajorAxis,
			"trueAnomaly":trueAnomaly,
			"eccentricAnomaly":eccentricAnomaly,
			"meanAnomaly":meanAnomaly,
			"eccentricty":eccentricty,
			"argPeri":argPeri,
			"bigG":parent_body.getBigG()
		}
		updateUI(data)
		
func redraw():
	
	var a = 2
	var b = 10000
	var c = 0
	var newscale = ((log(self_mass+1)/(log(b)+1))*a)+c
	$Sprite2D.scale=Vector2(newscale,newscale)
	$LightOccluder2D.scale=Vector2(newscale,newscale)
	
	#rotate sprite towards star - fake lighting effect -  TODO: fix this?
	$Sprite2D.rotation= orbitalVelocityf2.angle() + deg_to_rad(120)	
	if ! parent_body is Star:
		$Sprite2D.rotation = parent_body.orbitalVelocityf2.angle() + deg_to_rad(120)	
		
		var tmpStar = parent_body
		while !tmpStar.get_parent() is Star:
			tmpStar = tmpStar.get_parent()
			$Sprite2D.rotation = tmpStar.orbitalVelocityf2.angle() + deg_to_rad(120)	
	
	# REDRAW	
	ellipse.queue_redraw()
	queue_redraw()
	parent_body.queue_redraw()

func getBigG():
	return get_parent().getBigG()

func getGravU():
	return parent_body.getBigG() * (self_mass + parent_body.self_mass)

func solveFromStateVectors():
	var u = getGravU()
	
	var tmporbitalPosition = Vector3(position.x, position.y,0)
	var tmporbitalVelocity = Vector3(orbitalVelocity.x, orbitalVelocity.y,0)
	#	print(tmporbitalPosition)
	#	print(tmporbitalVelocity)

#Step 1—Position and Velocity Magnitudes
	var r = tmporbitalPosition.length()
	var vel = tmporbitalVelocity.length()
	var velr = (tmporbitalPosition/r).dot(tmporbitalVelocity)
	var _velp = sqrt((vel*vel) - (velr*velr))
	#	print(r)
	#	print(vel)
	#	print(velr)
	#	print(velp)

#Step 2—Orbital Angular Momentum & SemiMajor Axis
	var hvec = tmporbitalPosition.cross(tmporbitalVelocity)
	var _h=hvec.length()
	#	print(hvec)
	#	print(h) # ANG MOMENTUM
	
	#	var a = (u*r) / ( (2*u) - (r*vel*vel) )
	var specE = ( (vel*vel)/2  ) - ( u/r ) # SPECIFIC ORBIT ENERGY
	var a = -1 * (  u / (2*specE) )  # SEMI MAJOR AXIS
	#	print(a)

##Step 3—Inclination
	# i = incliniation
	
##Step 4—Right Ascension of the Ascending Node
	# Omega = longitude of asc node

#Step 5—Eccentricity
	var evec=tmporbitalVelocity.cross(hvec) / u - tmporbitalPosition / r
	var e=evec.length()
	#	print(evec)
	#	print(e) # ECCENTRICTY
		
#Step 6—Argument of Periapsis       # TODO: fix all this WTF	
	var w = atan2(evec.y,evec.x)
	#	print(w)
	
#Step 7—True Anomaly
	var v=0.0
	if velr < 0:
		v = (2 * PI) - acos(evec.dot(tmporbitalPosition) / (e * r))
	else:
		v = acos(evec.dot(tmporbitalPosition) / (e * r)) # TODO: fix all this WTF
	if is_nan(v):
		v=0
	#	print(rad2deg(v)) # TRUE ANOM
	#	print()
		
#FINAL - SET PRIMARY ELEMENTS	
	semiMajorAxis = a
	eccentricty = e
	argPeri = rad_to_deg(w)
	#	rotation=w
	#	trueAnomaly
	if v <= PI:
		trueAnomaly = rad_to_deg(v)
	else:
		trueAnomaly = rad_to_deg(v-(2*PI))

	#	print(semiMajorAxis)
	#	print(eccentricty)
	#	print(argPeri)
	#	print(trueAnomaly)
	#	print(180-trueAnomaly)
	#	print()
		
# MORE ORBITAL VALUES
	var orbitalPeriod = 2*PI*sqrt((semiMajorAxis*semiMajorAxis*semiMajorAxis)/u) 
	var orbitalDistance = semiMajorAxis*((1-(pow(eccentricty,2)))/(1+eccentricty*cos(deg_to_rad(trueAnomaly))))
	var meanAnomalyMotion = (2*PI) / orbitalPeriod
	eccentricAnomaly = rad_to_deg(2*atan( sqrt( (1-e)/(1+e) ) * tan(deg_to_rad(trueAnomaly)/2) ) )
	meanAnomaly=rad_to_deg(deg_to_rad(eccentricAnomaly)-(eccentricty*sin(deg_to_rad(eccentricAnomaly))))

	# SOI
	#	SOIsize=  semiMajorAxis* pow(self_mass/parent_body.self_mass,2/5)  
	SOIsize=  orbitalDistance * pow(self_mass/parent_body.self_mass,2.0/5.0) * .6
	
	
# CALC ORBIT ELLIPSE - TODO hyperb and esc vel, etc	
	escapeVelocityMag=sqrt( 2 * getBigG() * parent_body.self_mass / r )
	if vel<escapeVelocityMag:
		# ELLIPSE
		ellipse.global_position = parent_body.global_position
		ellipse.semiMajorAxis = semiMajorAxis
		ellipse.eccentricty = eccentricty
		ellipse.rotation = (2*PI)+w
		ellipse.solve()

		# VELOC AND NORMALS
		orbitalVelocityf1 = position.direction_to(ellipse.get_focus1()) *100 * $Sprite2D.scale.x
		orbitalVelocityf2 = position.direction_to(ellipse.get_focus2()) *100 * $Sprite2D.scale.x
		orbitalVelocityNormal = (orbitalVelocityf1+orbitalVelocityf2).normalized() *100 * $Sprite2D.scale.x

		# ELLIPSE FOCI
		focus1Pos = ellipse.get_focus1()
		focus2Pos = ellipse.get_focus2()

		# APSIS
		periAp=ellipse.get_v3()
		apoAp=ellipse.get_v1()
		periApDistFromF2 = ellipse.get_focus2().distance_to(periAp)
		apoApDistFromF2 = ellipse.get_focus2().distance_to(apoAp)
	else:
		# HYPER/PARA
		orbitalVelocityf1=Vector2.ZERO
		orbitalVelocityf2=Vector2.ZERO
		orbitalVelocityNormal=Vector2.ZERO
		focus1Pos=Vector2.ZERO
		focus2Pos=Vector2.ZERO
		periAp=Vector2.ZERO
		apoAp=Vector2.ZERO
		periApDistFromF2=0.0
		apoApDistFromF2=0.0

# DEBUG STRING
	var solveStr = ''
	#	solveStr+='t       '+str(epoch)+"\n"
	solveStr+='a       '+str(semiMajorAxis)+"\n"
	
	# TODO : test hyperbolic values
	solveStr+='ah      '+str(  1/(2/r - pow(v,2)/u ) )+"\n"
	solveStr+='bh      '+str( -1 * a * sqrt(pow(e,2)-1) )+"\n"
	solveStr+='slr     '+str(a * (pow(e,2)-1) )+"\n"
	solveStr+='hev     '+str( sqrt(-u/ a) )+"\n"
	solveStr+='pd      '+str( -1 * a * (e-1) )+"\n"
	
	#	solveStr+='b       '+str(semiMinorAxis)+"\n"
	solveStr+='e       '+str(eccentricty)+"\n"
	solveStr+='w       '+str(w)+"\n"
	solveStr+='argP    '+str(argPeri)+"\n"
	
	solveStr+='f1      '+str(focus1Pos)+"\n"
	solveStr+='f2      '+str(focus2Pos)+"\n"

	solveStr+='apo     '+str(apoAp)+"\n"
	solveStr+='peri    '+str(periAp)+"\n"
	solveStr+='apoApDistFromF2     '+str(apoApDistFromF2)+"\n"
	solveStr+='periApDistFromF2    '+str(periApDistFromF2)+"\n"
	
	solveStr+='0        '+str(trueAnomaly)+"\n"
	solveStr+='e0       '+str(eccentricAnomaly)+"\n"
	solveStr+='m0       '+str(meanAnomaly)+"\n"
	solveStr+='m0 n     '+str(meanAnomalyMotion)+"\n"
	solveStr+='oPos     '+str(position)+"\n"
	
	solveStr+='oDist    '+str(orbitalDistance)+"\n"
	
	solveStr+='oVel     '+str(orbitalVelocity)+"\n"
	#	solveStr+='oVelf1 '+str(orbitalVelocityf1)+"\n"
	#	solveStr+='oVelf2 '+str(orbitalVelocityf2)+"\n"
	#	solveStr+='oVelNorm '+str(orbitalVelocityNormal)+"\n"
	solveStr+='oVelMag  '+str(orbitalVelocity.length())+"\n"
	solveStr+='velEsc   '+str(escapeVelocityMag)+"\n"
	
	solveStr+='oPeriod  '+str(orbitalPeriod)+"\n"
	solveStr+='mass1    '+str(self_mass)+"\n"
	solveStr+='mass2    '+str(parent_body.self_mass)+"\n"
	solveStr+='u        '+str(u)+"\n"
	solveStr+='G        '+str(parent_body.getBigG())+"\n"
	solveStr+='SOIr  	'+str(SOIsize)+"\n"
	#	solveStr+='N2D pos  '+str(position)+"\n"
	solveStr+='scale    '+str($Sprite2D.scale)+"\n"
	
	logMsg(solveStr,true,name)		

func logMsg(msg,clear_first=false,tab='massbody'):
	get_parent().logMsg(msg,clear_first,tab)

var POINT_COUNT = 60
func _draw():
	draw_line(Vector2.ZERO,orbitalVelocityf1,Color.BLUE,1)
	draw_line(Vector2.ZERO,orbitalVelocityf2,Color.RED,1)
	draw_line(Vector2.ZERO,orbitalVelocityNormal,Color.CYAN,1)
	
	draw_line(Vector2.ZERO,orbitalVelocity * 5  ,Color.GREEN,2.0) # veloc
	
	draw_circle(periAp-position,4.0,Color.GREEN)
	draw_circle(apoAp-position,4.0,Color.RED)
	
	draw_arc(Vector2.ZERO, SOIsize, 0.0, 2.0 * PI, POINT_COUNT, Color8(Color.BLUE.r8,Color.BLUE.g8,Color.BLUE.b8,30))
