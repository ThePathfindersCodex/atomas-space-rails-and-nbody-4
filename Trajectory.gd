extends Node2D
class_name Trajectory

# big help from:   
#		https://janus.astro.umd.edu/cgi-bin/orbits/orbview.pl
#		https://scriptverse.academy/tutorials/c-program-newton-raphson.html
#		https://searchcode.com/codesearch/view/56537037/
# 		https://elainecoe.github.io/orbital-mechanics-calculator/formulas.html
#		https://orbital-mechanics.space/classical-orbital-elements/orbital-elements-and-the-state-vector.html
#		https://downloads.rene-schwarz.com/download/M002-Cartesian_State_Vectors_to_Keplerian_Orbit_Elements.pdf
#		https://www.sciencedirect.com/topics/engineering/orbit-formula

var bigG=  0
func getBigG():
	bigG=  get_parent().getBigG()
	return bigG
func get_mass2():
	mass2 =get_parent().self_mass 
	return mass2
@export var mass = 100
@onready var mass2 = get_mass2() # TODO: this should come from a parent

# ORBIT DEF
@export var epoch:float = 0.0 # T
@export var eccentricty:float = 0.0 # e
@export var semiMajorAxis:float = 0.0 # a
@export var argPeri:float = 0.0 # W or ARGP
@export var trueAnomaly:float = 0.0 # v or 0 or f at T=0
@export var orbitCounterClockwise:bool=true

#CALCED VALUES
@onready var u = getBigG() * (mass+mass2)
var semiMinorAxis:float=0.0
var majorAxis:float=0.0
var minorAxis:float=0.0
var fDistFromC=0.0
var focus1Pos=Vector2.ZERO
var focus2Pos=Vector2.ZERO
var v1=Vector2.ZERO
var v2=Vector2.ZERO
var v3=Vector2.ZERO
var v4=Vector2.ZERO
var periAp=Vector2.ZERO
var apoAp=Vector2.ZERO
var periApDistFromF2=0.0
var apoApDistFromF2=0.0
var pprime1=Vector2.ZERO
var pprime2=Vector2.ZERO
var eccentricAnomaly=0.0
var meanAnomaly=0.0
var meanAnomalyMotion=0.0
var orbitalPeriod=0.0
var orbitalDistance=0.0
var orbitalPosition=Vector2.ZERO
var orbitalPositionGlobal=Vector2.ZERO

var orbitalVelocityMag=0.0
var orbitalVelocity=Vector2.ZERO
var orbitalVelocityf1=Vector2.ZERO
var orbitalVelocityf2=Vector2.ZERO
var orbitalVelocityNormal=Vector2.ZERO

@export var orbitColor:Color=Color8(Color.WHITE.r8,Color.WHITE.g8,Color.WHITE.b8,30)

func _ready():
#	solveFromTrue()	
#	queue_redraw()
	pass
	
func setG(newBigG):
	bigG=  newBigG
	u = bigG * (mass+mass2)	
	# TODO: need to resolve? not common to change G

func logMsg(msg,clear_first=false,tab='star'):
	if get_parent() != null:
		get_parent().logMsg(msg,clear_first,tab)

func updateUI(data):
	if get_parent() != null:
		get_parent().updateUI(data)

# ###########################################################################################################
# ###########################################################################################################
# ###########################################################################################################

func solveFromStateVectors():
	var tmporbitalPosition = Vector3(orbitalPosition.x, orbitalPosition.y,0)
	var tmporbitalVelocity = Vector3(orbitalVelocity.x, orbitalVelocity.y,0)
	
#Step 1—Position and Velocity Magnitudes
	var r = tmporbitalPosition.length()
	var vel = tmporbitalVelocity.length()
	var velr = (tmporbitalPosition/r).dot(tmporbitalVelocity)
	var _velp = sqrt((vel*vel) - (velr*velr))
#	print(r)
#	print(vel)
#	print(velr)
#	print(velp)

#Step 2—Orbital Angular Momentum + SemiMajor Axis
	var hvec = tmporbitalPosition.cross(tmporbitalVelocity)
	
#	var h=hvec.length()
	var _h=Vector2(hvec.x,hvec.y).length()
	
#	print(hvec)
#	print(h) # ANG MOMENTUM
#	var a = (u*r) / ( (2*u) - (r*vel*vel) )
	var specE = ( (vel*vel)/2  ) - ( u/r ) # SPECIFIC ORBIT ENERGY

	var a = -1 * (  u / (2*specE) ) # SEMI MAJOR AXIS
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
#	var w = atan2(evec.y,evec.x)
#	if !orbitCounterClockwise:
#		w = (2*PI)-w
		
#	var w = global_position.direction_to(to_global(periAp)).angle()	
#	if w < 0:
##		print(w)
#		w = (2 * PI) + w
		
	var w = atan2(evec.y,evec.x)
	
#	w = acos(evec.x/ e )
#
#	var K = Vector3(0, 0, 0)
#	var N_vec = K.cross(hvec)
#	var N = N_vec.length()		
#	if N>0:
#		w = acos(N_vec.dot(Vector3.ONE)/N);
#	if evec.z < 0:
#		w = (2 * PI) - acos(N_vec.dot(evec) / (N * e))
#	else:
#		w =            acos(N_vec.dot(evec) / (N * e))
	
#	print(K)
#	print(N_vec)
#	print(N)
#	print(w)
#	print(rad2deg(w)) # ARG OF PERI - even though not really defined at equator - consider periaps as ascending node
#	print()

	
#Step 7—True Anomaly
	var v=0.0
	if velr < 0:
		v = (2 * PI) - acos(evec.dot(tmporbitalPosition) / (e * r))
	else:
		v = acos(evec.dot(tmporbitalPosition) / (e * r)) # TODO: fix all this WTF
	if is_nan(v):
		v=0
		# print('WARNING - v is NAN')
#	print(rad2deg(v)) # TRUE ANOM
#	print()
	
	
# TRAJECTORY SHAPE
	var _q
	if is_equal_approx(e,0):
#		print('CIRCLE ORBIT')
		pass
	elif e < 1:
#		print('CLOSED ELLIPTICAL ORBIT')
		pass
	elif is_equal_approx(e,1):
		
		#
		#
		# TODO 
		# if angular momementum = 0 then RADIAL orbit
		# OTHERWISE is PARABOLIC
		#
		#		
		
		#print('WARNING: PARABOLIC ORBIT') 
		a=0

		# https://www.bogan.ca/orbits/kepler/orbteqtn.html
		# Note 2: The Parabolic Orbit is very long stretched Elliptical Orbit and cannot be characterized by a semi-major axis or eccentricity. 
		# It is determined only by its periapsis distance from the central body
#		q = periApDistFromF2
#		orbitalDistance = r = 2q/[1 + cos(θ)]
		_q = (r*(1+cos(v)))/2
#		print(_q)
		
	elif e >1:
		#print('WARNING: HYPERBOLIC ORBIT')
		_q = a* (1 - e)
#		print(_q)


#FINAL - SET ELEMENTS	
	semiMajorAxis = a
	eccentricty = e
	argPeri = rad_to_deg(w)
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
	solveFromTrue()
	

# ###########################################################################################################
# ###########################################################################################################
# ###########################################################################################################

func solveFromTrue(bypass_signals=false):
	if !is_inside_tree():
		pass
		
	var yQuad = 1
	if trueAnomaly <= 0.0:
		yQuad*=-1
		
	majorAxis = semiMajorAxis*2
	semiMinorAxis = semiMajorAxis* sqrt(1-(eccentricty*eccentricty))
	minorAxis = semiMinorAxis*2

	v1=Vector2(-semiMajorAxis,0)
	v2=Vector2(0,semiMinorAxis)
	v3=Vector2(semiMajorAxis,0)
	v4=Vector2(0,-semiMinorAxis)

	fDistFromC = sqrt((semiMajorAxis*semiMajorAxis)-(semiMinorAxis*semiMinorAxis))
	focus1Pos = Vector2(-fDistFromC,0)
	focus2Pos = Vector2(fDistFromC,0)

	orbitalPeriod=2*PI*sqrt((semiMajorAxis*semiMajorAxis*semiMajorAxis)/u) 
	if is_equal_approx(orbitalPeriod,0):
#		get_parent().logMsg("ERR - orbitalPeriod is 0",true,name) # hack for para / hyper
#		return
		meanAnomalyMotion = 0 # hack
	else:
		meanAnomalyMotion = (2*PI) / orbitalPeriod
	
	# hack to fix parabolic divide by zero
	if !is_equal_approx(eccentricty,1) && (1+eccentricty*cos(deg_to_rad(trueAnomaly))) !=0:
		orbitalDistance=semiMajorAxis*((1-(pow(eccentricty,2)))/(1+eccentricty*cos(deg_to_rad(trueAnomaly))))  
	else:
		orbitalDistance=semiMajorAxis
		
	orbitalPosition.x=orbitalDistance*cos(deg_to_rad(trueAnomaly)) 
	orbitalPosition.y=-orbitalDistance*sin(deg_to_rad(trueAnomaly))
	
	if is_inside_tree():
		orbitalPositionGlobal = to_global(orbitalPosition)
	else:
		orbitalPositionGlobal = orbitalPosition
	
	if(orbitalDistance> 0 and semiMajorAxis>0):
		orbitalVelocityMag = sqrt(u * (  (2/orbitalDistance)-(1/semiMajorAxis)  )) # vis viva equation.

	var y2 = sqrt( pow(semiMajorAxis,2) - pow(-focus1Pos.x+orbitalPosition.x,2) )
	var y1 = -y2
	pprime1=Vector2(-focus1Pos.x+orbitalPosition.x, y1)
	pprime2=Vector2(-focus1Pos.x+orbitalPosition.x, y2)

	orbitalVelocityf1 = orbitalPosition.direction_to(focus1Pos+focus1Pos) *75
	orbitalVelocityf2 = orbitalPosition.direction_to(Vector2.ZERO) *75
	orbitalVelocityNormal = (orbitalVelocityf1+orbitalVelocityf2).normalized() *75
	if !orbitCounterClockwise:
		orbitalVelocity = orbitalVelocityNormal.normalized().orthogonal() *orbitalVelocityMag
	else:
		orbitalVelocity = orbitalVelocityNormal.normalized().orthogonal().orthogonal().orthogonal() *orbitalVelocityMag

	periAp=v3
	apoAp=v1
	periApDistFromF2 = focus2Pos.distance_to(periAp)
	apoApDistFromF2 = focus2Pos.distance_to(apoAp)

	eccentricAnomaly=rad_to_deg(pprime2.angle_to_point(Vector2.ZERO) ) * yQuad
	meanAnomaly=rad_to_deg(deg_to_rad(eccentricAnomaly)-(eccentricty*sin(deg_to_rad(eccentricAnomaly))))

	var solveStr = ''
	solveStr+='t       '+str(epoch)+"\n"
	solveStr+='a       '+str(semiMajorAxis)+"\n"
	solveStr+='b       '+str(semiMinorAxis)+"\n"
	solveStr+='e       '+str(eccentricty)+"\n"
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
	solveStr+='oPos     '+str(orbitalPosition)+"\n"
	solveStr+='oPosGlob '+str(orbitalPositionGlobal)+"\n"
	
	solveStr+='oDist    '+str(orbitalDistance)+"\n"
	solveStr+='oVelMag  '+str(orbitalVelocityMag)+"\n"
	solveStr+='oVel     '+str(orbitalVelocity)+"\n"
#	solveStr+='oVelf1 '+str(orbitalVelocityf1)+"\n"
#	solveStr+='oVelf2 '+str(orbitalVelocityf2)+"\n"
	solveStr+='oVelNorm '+str(orbitalVelocityNormal)+"\n"
	solveStr+='oPeriod  '+str(orbitalPeriod)+"\n"
	solveStr+='mass1    '+str(mass)+"\n"
	solveStr+='mass2    '+str(mass2)+"\n"
	solveStr+='u        '+str(u)+"\n"
	solveStr+='G        '+str(bigG)+"\n"
	solveStr+='N2D pos  '+str(position)+"\n"
	solveStr+='N2D rot  '+str(rotation_degrees)+"\n"
	
	logMsg(solveStr,true,name)
	
	if !bypass_signals:
		updateUI(self)

# ###########################################################################################################
# ###########################################################################################################
# ###########################################################################################################

var POINT_COUNT = 60
func _draw():
	# TODO : test hyperbolic values
#	solveStr+='ah      '+str(  1/(2/r - pow(v,2)/u ) )+"\n"
#	solveStr+='bh      '+str( -1 * a * sqrt(pow(e,2)-1) )+"\n"
#	solveStr+='slr     '+str(a * (pow(e,2)-1) )+"\n"
#	solveStr+='hev     '+str( sqrt(-u/ a) )+"\n"
#	solveStr+='pd      '+str( -1 * a * (e-1) )+"\n"	

#	draw_arc(Vector2(0,0), orbitalDistance, 0.0, 2.0 * PI, POINT_COUNT, Color.red) # orbit distance	circle			

	draw_set_transform(focus1Pos,0,Vector2.ONE)
#	draw_circle(Vector2(0,0),20.0,Color.white) # center
#	draw_arc(Vector2(0.0, 0.0), semiMajorAxis, 0.0, 2.0 * PI, POINT_COUNT, Color.green) # ref circle
	
#	draw_circle(focus1Pos,20.0,Color.blue) # focus 1
	draw_circle(focus2Pos,20.0,Color.RED) # focus 2	
#
#	draw_circle(pprime1,10.0,Color.fuchsia) # ref circle p1
#	draw_circle(pprime2,10.0,Color.yellow) # ref circle p2
	
	draw_circle(v1,4.0,Color.RED) # v1 # apoAp
	draw_circle(v2,4.0,Color.BROWN) # v2
	draw_circle(v3,4.0,Color.GREEN) # v3 # periAp
	draw_circle(v4,4.0,Color.YELLOW) # v4
	
	draw_set_transform(focus1Pos,0,Vector2(semiMajorAxis,semiMinorAxis))
	draw_arc(Vector2(0.0, 0.0), 1.0, 0.0, 2.0 * PI, POINT_COUNT, orbitColor)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

	draw_line(orbitalPosition,orbitalPosition+orbitalVelocity,Color.GREEN,2.0) # veloc
	
#	draw_line(orbitalPosition,orbitalPosition+orbitalVelocityf1,Color.blue,1.0)  
#	draw_line(orbitalPosition,orbitalPosition+orbitalVelocityf2,Color.red,1.0)  
	
	draw_line(orbitalPosition,orbitalPosition+orbitalVelocityNormal,Color.CYAN,1.0) # veloc norm

#	draw_circle( focus1Pos+v3  ,50.0,Color.white) # TMP CIRCLE
	
	#rotate sprite towards star
#	$Sprite.rotation= orbitalVelocityf2.angle() + deg2rad(120)
	
	#position node
#	$Sprite.position = orbitalPosition
#	$LightOccluder2D.position = orbitalPosition
	
	#rotate to match argPeri
	rotation_degrees=argPeri
	
