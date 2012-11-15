cvars.p_drawCollisionGeometry = 0
cvars.p_drawCollisionInfo = 0
--spawnBox(0,0,0, 1/0.1)
--spawnBox(2.1,0,0, 1/0.1)
--spawnBox(-2.1,0,0, 1/0.1)
--spawnBox(-1.1,2,0, 1/0.1)
--spawnBox(1.1,2,0, 1/0.1)

function stack4()
  spawnBox(0, 4, 0, 1/1)
  spawnBox(0.01, 7, 0.01, 1/1)
  spawnBox(0., 10, 0, 1/1)
  spawnBox(0.01, 13, 0.01, 1/1)
end

function diagonalStack()
  spawnBox(-0.2, 4, 0, 1/1)
  spawnBox(0.05, 7, 0.9, 1/1)
  spawnBox(0.3, 10, 2.1, 1/1)
end

function pyramid()
  spawnBox(0,3,0, 1/1)
  spawnBox(2.1,3,0, 1/1)
  spawnBox(-2.1,3,0, 1/1)
  spawnBox(-1.1,6,0, 1/1)
  spawnBox(1.1,6,0, 1/1)	
  spawnBox(0,9,0, 1/1)
  spawnBox(0.01,40,0.01, 1/1)
end

function rotatedChest()
  local chestId = spawnBox(0,3,0, 1/1)
  rotate(chestId, 1,0,0, -15)
end

function oneChest()
   spawnBox(0,3,0, 1/1)
end

function rotatedStack()
  local chest1Id = spawnBox(0, 4, 0, 1/1)
  local chest2Id = spawnBox(0.01, 7, 0.01, 1/1)
  rotate(chest1Id, 1,0,0,-25)
  rotate(chest2Id, 0,0,1,15)
end

function slope(angel)
  local plane2Id = spawnPlane(0,0,0,0)
  rotate(plane2Id, 1, 0, 0, angel)
end

function test1()
  rotatedStack()
  spawnPlane(0,-1,0, 0)
end

function test2()
  oneChest()
  slope(-30)
  spawnPlane(0,-1,0, 0)
end

function test3()
  pyramid()
  spawnPlane(0,-1,0, 0)
end

test3()


