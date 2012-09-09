spawnArea(-200, 200,	-200, 200,	-1000, -800)
spawnOrientation(0, 1, 0, 180)

avoidIntersections(false)
team(-1)

frigate(0, 0, 0, 0, 1, 0, 0)
asteroid(2,	850, 0, 0,	0, 1, 0, 0,	45)
asteroid(1,	74, 940, 200,	0, 1, 0, 0,	55)

station(800, 350, 230,	1, 1, 0, 0,	0.75)

team(-2)
frigate(3200, 600, -1200,	0, 1, 0, -40)
habitat(3000, 500, 200,	1, 0, 0, -30,	0.25)

avoidIntersections(true)
local radius = 4000
local count = 0
repeat
	local x, y, z = math.random(-radius, radius), math.random(-radius, radius), math.random(-radius, radius)
	
	local rx, ry, rz = math.random(-1, 1), math.random(-1, 1), math.random(-1, 1)
	if rz == 0 then
		rz = 1
	end
	local angle = math.random(0, 360)
	
	local scale = math.random(1, 15)
	
	local spawned = asteroid(math.random(1, 3),	x, y, z,	rx, ry, rz, angle,	scale)
	if spawned then
		count = count + 1
	end
until count > 600

-- All players are spawned in this last team, 0 is the free for all "team"
team(0)