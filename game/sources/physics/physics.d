module physics.physics;

import base.all;
import physics.rigidbody; 
import physics.cvars;
import base.octree;
import thBase.container.vector;
import thBase.math3d.all;
import thBase.casts;

class PhysicsSimulation
{
  private:
    Vector!RigidBody m_simulated;
    Octree m_octree;
    CVars m_CVars;

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
        uint numCollisions = 0, numChecks = 0;
        vec3 collisionPoint;
        float divisor = 0.0f;
        for(;!query.empty();query.popFront())
        {
          IGameObject colObj = query.front();
          if(colObj.physicsComponent !is null)
          {
            auto collidingRigidBody = static_cast!RigidBody(colObj.physicsComponent);
            if(collidingRigidBody is obj)
              continue;

            numChecks++;
            
            Ray[32] intersections = void;
            size_t numIntersections = obj.collision.getIntersections(collidingRigidBody.collision, collidingRigidBody.transformTo(obj), intersections);

            if(numIntersections > 0)
            {
              divisor += cast(float)(numIntersections * 2);
              if(numCollisions == 0)
              {
                collisionPoint = intersections[0].pos + intersections[0].end;
                foreach(ref intersection; intersections[1..numIntersections])
                {
                  collisionPoint = collisionPoint + intersection.pos + intersection.end;
                }
              }
              else
              {
                foreach(ref intersection; intersections[0..numIntersections])
                {
                  collisionPoint = collisionPoint + intersection.pos + intersection.end;
                }
              }
              if(m_CVars.p_drawCollisionGeometry > 0)
                collidingRigidBody.collision.debugDraw(collidingRigidBody.position, collidingRigidBody.rotation, g_Env.renderer);
              numCollisions++;
            }

            if(m_CVars.p_drawCollisionInfo > 0)
            {
              mat4 rotation = obj.rotation.toMat4();
              foreach(ref intersection; intersections[0..numIntersections])
              {
                g_Env.renderer.drawLine(obj.position + (rotation * intersection.pos), obj.position + (rotation * intersection.end), vec4(1.0f, 0.0f, 0.0f, 1.0f));
              }
            }
          }
        }
        if(numCollisions > 0)
        {
          if(m_CVars.p_drawCollisionGeometry > 0)
          {
            obj.collision.debugDraw(obj.position, obj.rotation, g_Env.renderer);
          }
          collisionPoint = collisionPoint * (1.0f / divisor);
          if(m_CVars.p_drawCollisionInfo > 0)
          {
            mat4 rotation = obj.rotation.toMat4();
            g_Env.renderer.drawLine(obj.position + (rotation * collisionPoint), obj.position + (rotation * collisionPoint) - obj.velocity);
          }
        }
        if(numChecks > 0 && m_CVars.p_drawCollisionGeometry > 0)
        {
          g_Env.renderer.drawBox(queryBox, vec4(0.0f, 1.0f, 0.0f, 1.0f));
        }

        obj.position = nextPosition;
      }
    }

    void RegisterCVars(ConfigVarsBinding* storage)
    {
      foreach(m;__traits(allMembers,typeof(m_CVars))){
				storage.registerVariable(m,__traits(getMember,this.m_CVars,m));
			}
    }
}