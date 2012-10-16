module physics.physics;

import physics.rigidbody; 
import base.octree;
import thBase.container.vector;
import thBase.math3d.all;
import thBase.casts;

class PhysicsSimulation
{
  private:
    Vector!RigidBody m_simulated;
    Octree m_octree;

  public:
    this(Octree octree)
    {
      m_simulated = New!(typeof(m_simulated))();
      m_octree = octree;
    }

    ~this()
    {
      Delete(m_simulated);
    }

    void AddSimulatedBody(RigidBody obj)
    {
      m_simulated ~= obj;
    }

    void RemoveSimulatedBody(RigidBody obj)
    {
      m_simulated.remove(obj);
    }

    void Simulate(float timeDiff)
    {
      vec3 gravity = vec3(0, -9.81, 0);
      foreach(obj; m_simulated[])
      {
        obj.velocity += gravity * timeDiff;
        obj.position = obj.position + obj.velocity * timeDiff;
      }
    }
}