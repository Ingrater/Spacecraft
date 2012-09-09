spawnArea(-1500, -100,	-200, 200,	-3000, -2500)
spawnOrientation(0, 1, 0, 180)

-- spawn the atack squad of frigates
avoidIntersections(true)
team(2)

local count = 0
repeat
	local x, y, z = math.random(-2000, 2000), math.random(-500, 500), math.random(2000, 2500)
	local spawned = frigate(x, y, z,	0, 1, 0, 0)
	if spawned then
		count = count + 1
	end
until count >= 5

-- spawn the defending party
team(1)

avoidIntersections(false)
habitat(5000, 500, -2500,	0, 0, 1, 20,	0.25)

local count = 0
repeat
	local x, y, z = -1500 * count, math.random(-300, 300), -2000 + 1000 * count
	local spawned = frigate(x, y, z,	0, 1, 0, 180 + count * 30)
	if spawned then
		count = count + 1
	end
until count >= 2

-- spawn the asteroids
avoidIntersections(true)
local count = 0
repeat
	local x, y, z = math.random(-4000, 4000), math.random(-4000, 4000), math.random(-7000, 3000)
	
	local rx, ry, rz = math.random(-1, 1), math.random(-1, 1), math.random(-1, 1)
	if rz == 0 then
		rz = 1
	end
	local angle = math.random(0, 360)
	
	local scale = math.random(1, 30)
	
	local spawned = asteroid(math.random(1, 3),	x, y, z,	rx, ry, rz, angle,	scale)
	if spawned then
		count = count + 1
	end
until count > 600

-- players should defend the habitat
team(1)