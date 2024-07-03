extends Node2D
class_name Orb

@export var self_mass = 100.0
@export var orbitalVelocity=Vector2.ZERO

var pts_max = 500
var pts = PackedVector2Array()
var ptCtrMax = 5
var ptCtr = 0

var line2Dpath
var traj
var traj2
var traj3
var centerObj
var outerPlanetObj

func _ready():
	#move path LINE to top level game node
	line2Dpath = $line2Dpath
	remove_child(line2Dpath)
	get_parent().call_deferred("add_child",line2Dpath)

	#move path traj to top level game node
	traj = $Trajectory
	traj.name = name + '-traj' 
	remove_child(traj)
	get_parent().get_node('Star').call_deferred("add_child",traj)
	
	#move path traj2 to top level game node - TEST
	centerObj = get_parent().get_node('Star') #findBestCenter()
	traj2 = $Trajectory2
	traj2.name = name + '-traj2' 
	remove_child(traj2)
	centerObj.call_deferred("add_child",traj2)

	#move path traj3 to outer planet - TEST
	outerPlanetObj = get_parent().get_node('Star/MassBody2') #findBestCenter()
	traj3 = $Trajectory3
	traj3.name = name + '-traj3' 
	remove_child(traj3)
	outerPlanetObj.call_deferred("add_child",traj3)
	
func moveTraj2Center(newObjCenter):
	if (newObjCenter != centerObj):
		centerObj.remove_child(traj2)
		centerObj = newObjCenter # findBestCenter()
		centerObj.call_deferred("add_child",traj2)
		
func moveTraj3Center(newOuterPlanetCenter):
	if (newOuterPlanetCenter != outerPlanetObj):
		outerPlanetObj.remove_child(traj3)
		outerPlanetObj = newOuterPlanetCenter # findBestCenter()
		outerPlanetObj.call_deferred("add_child",traj3)		
		
func clean_queue_free():
	get_parent().removeTab(name)
	get_parent().removeTab(name + '-traj' )
	get_parent().removeTab(name + '-traj2' )
	get_parent().removeTab(name + '-traj3' )
	line2Dpath.queue_free()
	traj.queue_free()
	traj2.queue_free()
	traj3.queue_free()
	queue_free()
	
var lastDistanceToStar
func _process(_delta):
	# check for leaving star system
	lastDistanceToStar= global_position.distance_to(get_parent().get_node('Star').global_position)	
	if lastDistanceToStar > get_parent().max_distance_allowed:
		clean_queue_free()

	# store recent path
	ptCtr +=  1
	if ptCtr > ptCtrMax:
		ptCtr=0
		pts.append( global_position)
		if pts.size()> pts_max:
			pts.remove_at(0)
		line2Dpath.set_points(pts)
	
var localTime=0.0 
func _physics_process(delta):
	if delta>0:
		localTime += delta
		
		#update position first from half the delta
		global_position+=orbitalVelocity*(delta/2)

		#then update veloc
#		for b in get_tree().get_nodes_in_group("massive-single-test") :
		for b in get_tree().get_nodes_in_group("massive") :
			if b.name == name: # or !b is Star:
				continue

			var u = b.getBigG() * (self_mass + b.self_mass)
			var dist2 = position.distance_squared_to(b.global_position)
			var dir = position.direction_to(b.global_position).normalized()
			
			var accel = dir * u /  (dist2)
			orbitalVelocity += accel * (delta)
		
		#then update the position again with the other half of delta
		global_position+=orbitalVelocity*(delta/2)
#		global_position+=orbitalVelocity*(delta)

		lastDistanceToStar= global_position.distance_to(get_parent().get_node('Star').global_position)	

	# DEBUG STRING
		var solveStr = ''
		solveStr+='name    '+str(name)+"\n"
#		solveStr+='a       '+str(semiMajorAxis)+"\n"
		
		# TODO : test hyperbolic values
#		solveStr+='ah      '+str(  1/(2/r - pow(v,2)/u ) )+"\n"
#		solveStr+='bh      '+str( -1 * a * sqrt(pow(e,2)-1) )+"\n"
#		solveStr+='slr     '+str(a * (pow(e,2)-1) )+"\n"
#		solveStr+='hev     '+str( sqrt(-u/ a) )+"\n"
#		solveStr+='pd      '+str( -1 * a * (e-1) )+"\n"
		
	#	solveStr+='b       '+str(semiMinorAxis)+"\n"
#		solveStr+='e       '+str(eccentricty)+"\n"
#		solveStr+='w       '+str(w)+"\n"
#		solveStr+='argP    '+str(argPeri)+"\n"
		
#		solveStr+='f1      '+str(focus1Pos)+"\n"
#		solveStr+='f2      '+str(focus2Pos)+"\n"

#		solveStr+='apo     '+str(apoAp)+"\n"
#		solveStr+='peri    '+str(periAp)+"\n"
#		solveStr+='apoApDistFromF2     '+str(apoApDistFromF2)+"\n"
#		solveStr+='periApDistFromF2    '+str(periApDistFromF2)+"\n"
		
#		solveStr+='0        '+str(trueAnomaly)+"\n"
#		solveStr+='e0       '+str(eccentricAnomaly)+"\n"
#		solveStr+='m0       '+str(meanAnomaly)+"\n"
#		solveStr+='m0 n     '+str(meanAnomalyMotion)+"\n"
		solveStr+='oPos     '+str(position)+"\n"
		solveStr+='oPosGlob '+str(global_position)+"\n"
	
		solveStr+='oDist    '+str(lastDistanceToStar)+"\n"
		
		solveStr+='oVel     '+str(orbitalVelocity)+"\n"
	#	solveStr+='oVelf1 '+str(orbitalVelocityf1)+"\n"
	#	solveStr+='oVelf2 '+str(orbitalVelocityf2)+"\n"
	#	solveStr+='oVelNorm '+str(orbitalVelocityNormal)+"\n"
		solveStr+='oVelMag  '+str(orbitalVelocity.length())+"\n"
#		solveStr+='velEsc   '+str(escapeVelocityMag)+"\n"
		
#		solveStr+='oPeriod  '+str(orbitalPeriod)+"\n"
		solveStr+='mass1    '+str(self_mass)+"\n"
		solveStr+='mass2    '+str(get_parent().get_node('Star').self_mass)+"\n"
#		solveStr+='u        '+str(u)+"\n"
		solveStr+='G        '+str(get_parent().bigG)+"\n"
#		solveStr+='SOIr  	'+str(SOIsize)+"\n"
	#	solveStr+='N2D pos  '+str(position)+"\n"
#		solveStr+='scale    '+str($Sprite.scale)+"\n"
		
		logMsg(solveStr,true,name)	
	
		# possible orbit - star
		if traj.is_inside_tree():
			traj.orbitColor = Color8(Color.GREEN.r8,Color.GREEN.g8,Color.GREEN.b8,30)
			traj.position = Vector2.ZERO
			traj.mass = self_mass
			traj.mass2 = get_parent().get_node('Star').self_mass
			traj.setG(get_parent().get_node('Star').getBigG())
			traj.orbitalPosition = get_parent().get_node('Star').to_local(global_position)
			traj.orbitalVelocity = -1*orbitalVelocity
			traj.solveFromStateVectors()	
			traj.queue_redraw()	
			
		# possible orbit - around planet or moon
		if traj2.is_inside_tree():
			
			moveTraj2Center(findBestCenter())		
#			moveTraj2Center(get_parent().get_node('Star').get_node('MassBody'))		
			
			traj2.orbitColor = Color8(Color.YELLOW.r8,Color.YELLOW.g8,Color.YELLOW.b8,30)
			traj2.position = Vector2.ZERO
			traj2.mass = self_mass
			traj2.mass2 = centerObj.self_mass
#			traj2.mass2 = get_parent().get_node('Star').get_node('MassBody').self_mass
			traj2.setG(get_parent().get_node('Star').getBigG())
			traj2.orbitalPosition = centerObj.to_local(global_position)
#			traj2.orbitalPosition = get_parent().get_node('Star').get_node('MassBody').to_local(global_position)

			# TODO:  make dynamic - because orbital velocity stacks?
			traj2.orbitalVelocity = -1*orbitalVelocity + centerObj.orbitalVelocity
#			traj2.orbitalVelocity = -1*orbitalVelocity + get_parent().get_node('Star').get_node('MassBody').orbitalVelocity
			traj2.solveFromStateVectors()	
			traj2.queue_redraw()	

		# possible orbit - around planet or moon
		if traj3.is_inside_tree():
			
#			moveTraj3Center(findBestCenter())		
#			moveTraj2Center(get_parent().get_node('Star').get_node('MassBody'))		
			
			traj3.orbitColor = Color8(Color.ORANGE.r8,Color.ORANGE.g8,Color.ORANGE.b8,30)
			traj3.position = Vector2.ZERO
			traj3.mass = self_mass
			traj3.mass2 = outerPlanetObj.self_mass
#			traj3.mass2 = get_parent().get_node('Star').get_node('MassBody').self_mass
			traj3.setG(get_parent().get_node('Star').getBigG())
			traj3.orbitalPosition = outerPlanetObj.to_local(global_position)
#			traj3.orbitalPosition = get_parent().get_node('Star').get_node('MassBody').to_local(global_position)

			# TODO:  make dynamic - because orbital velocity stacks?
			traj3.orbitalVelocity = -1*orbitalVelocity + outerPlanetObj.orbitalVelocity
#			traj3.orbitalVelocity = -1*orbitalVelocity + get_parent().get_node('Star').get_node('MassBody').orbitalVelocity
			traj3.solveFromStateVectors()	
			traj3.queue_redraw()	

func findBestCenter():
	return get_parent().get_node('Star').get_node('MassBody')	
	# TODO:  make dynamic
#	for member in get_tree().get_nodes_in_group("massive"):
		# does orb intersect with the objects circle of influence? blue line
#		draw_arc(Vector2.ZERO, SOIsize, 0.0, 2.0 * PI, POINT_COUNT, Color8(Color.blue.r8,Color.blue.g8,Color.blue.b8,30))
		
func getBigG():
	return get_parent().bigG

func logMsg(msg,clear_first=false,tab='orb'):
	get_parent().logMsg(msg,clear_first,tab)

func circle_orbit(b1,b2):
#		print("sm  ",b1.mass)		
#		print("pm  ",b2.mass)		

		var direction = b2.global_position.direction_to(b1.global_position)
#		print(direction)

		var distance = b2.global_position.distance_to(b1.global_position)
#		print("dis  ",distance)		

		var dir_tangent=direction.orthogonal()
#		dir_tangent = dir_tangent # .rotated(deg2rad(30) )
#		print("tan  ",dir_tangent)
		
		var mag:float = circle_orbit_veloc(b1.self_mass,b2.self_mass,distance,b1.getBigG())
#		print("mag  ", mag)	

		var velo=dir_tangent * mag
#		print("velo ", velo)		

		return velo

func circle_orbit_veloc(m1,m2,d,g):
#		var bigG:float = 6.6743 * pow(10, -11)  # soo low
#		var bigG=  98
#		var bigG=  1
#		print("G   ", bigG)	
		var mag:float= sqrt(g * (m1 + m2)/d) 
#		print("mag  ", mag)		
#		var accf:float=(bigG*(m1+m2))/(d*d)  # not used currently
#		print("acc  ", accf)		
		return mag
