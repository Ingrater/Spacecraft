cvars.p_drawCollisionGeometry = 1
cvars.p_drawCollisionInfo = 1
cvars.p_iterations = 1
cvars.p_collisionResponse = 1
--spawnBox(0,0,0, 1/0.1)
--spawnBox(2.1,0,0, 1/0.1)
--spawnBox(-2.1,0,0, 1/0.1)
--spawnBox(-1.1,2,0, 1/0.1)
--spawnBox(1.1,2,0, 1/0.1)

INERTIA_TENSOR_FIXED = 0
INERTIA_TENSOR_BOX = 1
INERTIA_TENSOR_SPHERE = 2

function plane()
  spawnPlane(0,-1,0, 0)
end

function stack(height)
  for i=1,height do
    spawnBox(0, 4 + i * 3, 0.01 * i, 1/1)
  end
end

function diagonalStack()
  spawnBox(-0.2, 4, 0, 1/1, INERTIA_TENSOR_BOX)
  spawnBox(0.05, 7, 0.9, 1/1, INERTIA_TENSOR_BOX)
  spawnBox(0.3, 10, 2.1, 1/1, INERTIA_TENSOR_BOX)
end

function pyramid()
  spawnBox(0,3,0, 1/1, INERTIA_TENSOR_BOX)
  spawnBox(2.1,3,0, 1/1, INERTIA_TENSOR_BOX)
  spawnBox(-2.1,3,0, 1/1, INERTIA_TENSOR_BOX)
  spawnBox(-1.1,6,0, 1/1, INERTIA_TENSOR_BOX)
  spawnBox(1.1,6,0, 1/1, INERTIA_TENSOR_BOX)	
  spawnBox(0,9,0, 1/1, INERTIA_TENSOR_BOX)
  spawnBox(0.01,40,0.01, 1/1, INERTIA_TENSOR_BOX)
end

function emptyWorld()
  resetWorld()
  cvars.p_gravity = 9.81
  spawnPlane(0,-2,0, 0, INERTIA_TENSOR_FIXED)
end

function rotatedChest(angel)
  local chestId = spawnBox(0,3,0, 1/1, INERTIA_TENSOR_BOX)
  rotate(chestId, 1,0,0, angel)
end

function oneChest()
   spawnBox(0,3,0, 1/1, INERTIA_TENSOR_BOX)
end

function throwChest()
  local boxId = spawnBox(0,3,10, 1/10, INERTIA_TENSOR_BOX)
  setVelocity(boxId, 0,0,-20)
end

function rotatedStack()
  local chest1Id = spawnBox(0, 4, 0, 1/1, INERTIA_TENSOR_BOX)
  local chest2Id = spawnBox(0.01, 7, 0.01, 1/1, INERTIA_TENSOR_BOX)
  rotate(chest1Id, 1,0,0,-25)
  rotate(chest2Id, 0,0,1,15)
end

function slope(angel)
  local plane2Id = spawnPlane(0,0,0,0, INERTIA_TENSOR_FIXED)
  rotate(plane2Id, 1, 0, 0, angel)
end

function test1()
  emptyWorld()
  rotatedStack()
end

function test2()
  emptyWorld()
  oneChest()
  slope(-30)
end

function test3()
  emptyWorld()
  pyramid()
end

--intersection test 1
function test4()
  emptyWorld()
  spawnBox(0,1,0,1/1, INERTIA_TENSOR_BOX)
  spawnBox(0.01,1.6,0.01,1/1, INERTIA_TENSOR_BOX)
end

--intersection test 2
function test5()
  emptyWorld()
  spawnBox(0,0.5,0,1/1, INERTIA_TENSOR_BOX)
  spawnBox(0.01,1.5,0,1/1, INERTIA_TENSOR_BOX)
  spawnBox(-0.01,2.5,0,1/1, INERTIA_TENSOR_BOX)
end

function test6()
  emptyWorld()
  slope(-30)
  local chestId = spawnBox(0,11,-10, 1/1, INERTIA_TENSOR_BOX)
  rotate(chestId, 1,0,0, -30)
end

function test7()
  emptyWorld()
  cvars.p_gravity = 0
  spawnBox(0,3,0, 1/1, INERTIA_TENSOR_BOX)
  local boxId = spawnBox(0, 3.01, 3, 1/1, INERTIA_TENSOR_BOX)
  setVelocity(boxId, 0,0,-10)
end

function test8()
  emptyWorld()
  stack(2)
end

function test9()
  emptyWorld()
  spawnBox(0,3,0, 1/1, INERTIA_TENSOR_BOX)
  spawnBox(-1.1,6,0, 1/1, INERTIA_TENSOR_BOX)  
end

function test10()
  emptyWorld()
  local box1 = spawnBox(0.00000000, 0.10174561, 0.00000000, 1/1, INERTIA_TENSOR_BOX)
  setVelocity(box1, 0.00000000, 2.7195253, 0.00000000)
  local box2 = spawnBox(-1.09998, 2.5633545, 0, 1/1, INERTIA_TENSOR_BOX)
  setVelocity(box2, 0.00000000, -8.1197395, 0.00000000, INERTIA_TENSOR_BOX)
end

function test11()
  emptyWorld()
  stack(3)
end

--intersection test 3
function test12()
  emptyWorld()
  spawnBox(0,-0.1,0,1/1, INERTIA_TENSOR_BOX)
  spawnBox(0.01,1.8,0,1/1, INERTIA_TENSOR_BOX)
  spawnBox(-0.01,3.7,0,1/1, INERTIA_TENSOR_BOX)
end

--rotation test
function test13()
  emptyWorld()
  --cvars.p_gravity = 0
  local boxId = spawnBox(0,3,0,1/1, INERTIA_TENSOR_BOX)
  setAngularMomentum(boxId, 0,0,0.001)
end

test13()


