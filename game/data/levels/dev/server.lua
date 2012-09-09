spawnArea(-700, 700,	-100, 100,	-700, 700)
spawnOrientation(0, 1, 0, 0)

avoidIntersections(false)
team(-1)

for i = 0, 0 do
	frigate(i * -300, 0, 0, 0, 1, 0, 0)
end

station(500, 0, 0, 0, 1, 0, 0, 0.75)
habitat(5000, 500, 200, 1, 0, 0, 0, 0.25)

avoidIntersections(true)
local asteroid_count, belt_radius = 300, 1500
local asteroid_distance = math.pi * 2 * belt_radius / asteroid_count
for i = 1, asteroid_count do
	local rad = 2 * math.pi * i / asteroid_count
	local x, y, z = math.sin(rad), 0, math.cos(rad)
	x = x * belt_radius + math.random(-asteroid_distance, asteroid_distance)
	y = y * belt_radius + math.random(-asteroid_distance, asteroid_distance)
	z = z * belt_radius + math.random(-asteroid_distance, asteroid_distance)
	
	rx, ry, rz = math.random(-1, 1), math.random(-1, 1), math.random(-1, 1)
	if rz == 0 then
		rz = 1
	end
	angle = math.random(0, 360)
	
	asteroid(math.random(1, 3), x, y, z, rx, ry, rz, angle, math.random(1, 2))
end

team(0)