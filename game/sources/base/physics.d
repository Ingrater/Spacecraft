module base.physics;

import base.octree;
import base.script;
import thBase.plugin;
import thBase.math3d.all;
import game.collision;

enum IntertiaTensorType
{
  fixed = 0,
  box = 1,
  sphere = 2
}

abstract class IRigidBody
{
public:
  Position position;
  Quaternion rotation;
  vec3 velocity;
  vec3 angularMomentum;
}

interface IPhysicsPlugin : IPlugin
{
  alias IPlugin.name name;

  IPhysics CreatePhysics(Octree octree);
  void DeletePhysics(IPhysics physics);

  IRigidBody CreateRigidBody(CollisionHull collision, float fInverseMass, IntertiaTensorType intertiaTensor);
  void DeleteRigidBody(IRigidBody b);
}

interface IPhysics
{
  void AddSimulatedBody(IRigidBody obj);
  void RemoveSimulatedBody(IRigidBody obj);
  void Simulate(float timeDiff);
  void RegisterCVars(ConfigVarsBinding* storage);
}