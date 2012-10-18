module physics.physics;

import base.all;
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
      float secondDiff = timeDiff / 1000.0f;
      foreach(obj; m_simulated[])
      {
        obj.velocity += gravity * secondDiff;
        auto nextPosition = obj.position + obj.velocity * secondDiff;

        float collisionRadius = obj.collision.boundingRadius;
        vec3 boundOffset = vec3(collisionRadius, collisionRadius, collisionRadius);
        auto queryBox = AlignedBox(nextPosition - boundOffset, nextPosition + boundOffset);
        auto query = m_octree.getObjectsInBox(queryBox);
        if(!query.empty())
        {
          g_Env.renderer.drawBox(queryBox, vec4(0.0f, 1.0f, 0.0f, 1.0f));
        }
        for(;!query.empty();query.popFront())
        {
          IGameObject colObj = query.front();
          if(colObj.physicsComponent !is null)
          {
            auto collidingRigidBody = static_cast!RigidBody(colObj.physicsComponent);
            Ray[32] intersections = void;
            size_t numIntersections = obj.collision.getIntersections(collidingRigidBody.collision, collidingRigidBody.transformTo(obj), intersections);

            {
              mat4 rotation = obj.rotation.toMat4();
              foreach(ref intersection; intersections[0..numIntersections])
              {
                g_Env.renderer.drawLine(obj.position + (rotation * intersection.pos), obj.position + (rotation * intersection.end), vec4(1.0f, 0.0f, 0.0f, 1.0f));
              }
            }
          }
        }

        obj.position = nextPosition;
      }
    }
}