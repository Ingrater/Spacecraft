module physics.physics;

import base.all;
import physics.rigidbody; 
import physics.cvars;
import base.octree;
import thBase.container.vector;
import thBase.math3d.all;
import thBase.casts;

import std.math;

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
      FloatingPointControl fpctrl; 
      fpctrl.enableExceptions(FloatingPointControl.severeExceptions);

      vec3 gravity = vec3(0, -9.81, 0);
      float secondDiff = timeDiff / 1000.0f;
      foreach(obj; m_simulated[])
      {
        obj.velocity += gravity * secondDiff;
        auto startPosition = obj.position;
        obj.position = startPosition + obj.velocity * secondDiff;

        float collisionRadius = obj.collision.boundingRadius + obj.velocity.length * secondDiff;
        vec3 boundOffset = vec3(collisionRadius, collisionRadius, collisionRadius);
        auto queryBox = AlignedBox(obj.position  - boundOffset, obj.position + boundOffset);
        auto query = m_octree.getObjectsInBox(queryBox);
        uint numCollisions = 0, numChecks = 0;
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
            mat4 collidingRigidyBodyTransform = collidingRigidBody.transformTo(obj);
            size_t numIntersections = obj.collision.getIntersections(collidingRigidBody.collision, collidingRigidyBodyTransform, intersections);

            if(numIntersections > 0)
            {
              vec3 collisionPoint = intersections[0].pos + intersections[0].end;
              foreach(ref intersection; intersections[1..numIntersections])
              {
                collisionPoint = collisionPoint + intersection.pos + intersection.end;
              }

              Ray normalFindRay = Ray.CreateFromPoints(vec3(0,0,0), collisionPoint);
              //normalFindRay.pos = normalFindRay.pos - (normalFindRay.dir * 0.01f);

              float intersectionPosOther = -0.01f;
              vec3 intersectionNormalOther;
              if(!collidingRigidBody.collision.intersects(normalFindRay, collidingRigidyBodyTransform, intersectionPosOther, intersectionNormalOther))
              {
                intersectionPosOther = 0.0f;
                intersectionNormalOther = -(normalFindRay.dir);
              }

              float intersectionPosCurrent = -0.01f;
              vec3 intersectionNormalCurrent;
              if(!obj.collision.intersects(normalFindRay, mat4.Identity(), intersectionPosCurrent, intersectionNormalCurrent))
              {
                intersectionPosCurrent = 0.0f;
                intersectionNormalOther = normalFindRay.dir;
              }

              if(m_CVars.p_drawCollisionInfo > 0)
              {
                mat4 rotation = obj.rotation.toMat4();
                g_Env.renderer.drawArrow(obj.position + (rotation * normalFindRay.get(intersectionPosOther)), obj.position + (rotation * (normalFindRay.get(intersectionPosOther) + intersectionNormalOther)), vec4(1.0f, 0.0f, 0.0f, 1.0f));
                g_Env.renderer.drawArrow(obj.position + (rotation * normalFindRay.get(intersectionPosCurrent)), obj.position + (rotation * (normalFindRay.get(intersectionPosCurrent) + intersectionNormalCurrent)), vec4(0.0f, 0.0f, 1.0f, 1.0f));
                g_Env.renderer.drawArrow(obj.position + (rotation * normalFindRay.pos), obj.position + (rotation * normalFindRay.end), vec4(0.0f, 1.0f, 1.0f, 1.0f));
              }

              if(m_CVars.p_drawCollisionGeometry > 0)
                collidingRigidBody.collision.debugDraw(collidingRigidBody.position, collidingRigidBody.rotation, g_Env.renderer);
              numCollisions++;

              

              //Try finding the last point where they did not collide
              float noCollisionTime = 0.0f;
              float collisionTime = secondDiff;

              obj.position = startPosition;
              mat4 transform = collidingRigidBody.transformTo(obj);
              if(obj.collision.intersectsFast(collidingRigidBody.collision, transform))
              {
                //We have a intersection to resolve
                vec3 resolveDirection = obj.rotation.toMat4().transformDirection(-intersectionNormalCurrent);
                float searchPoint = 0.0f;
                float searchDelta = 1.0f;
                float stillSearchingMult = 2.0f;
                for(int i=0; i<5; i++)
                {
                  searchPoint += searchDelta;
                  obj.position = startPosition + resolveDirection * searchPoint;
                  transform = collidingRigidBody.transformTo(obj);
                  if(obj.collision.intersectsFast(collidingRigidBody.collision, transform))
                  {
                    //still intersecting
                    if(searchDelta > 0.0f)
                    {
                      searchDelta *= stillSearchingMult;
                    }
                    else
                    {
                      searchDelta *= -0.5f;
                    }
                  }
                  else
                  {
                    //not intersecting anymore
                    stillSearchingMult = 0.5f;
                    if(searchDelta < 0.0f)
                    {
                      searchDelta *= 0.5f;
                    }
                    else
                    {
                      searchDelta *= -0.5f;
                    }
                  }
                }
                float inverseTotalMass = 1.0f / (obj.inverseMass + collidingRigidBody.inverseMass);
                float ratioA = inverseTotalMass * obj.inverseMass; //how much the first object will be affected by the intersection correction
                float ratioB = inverseTotalMass * collidingRigidBody.inverseMass; //how much the second object will be affected by the intersection correction
                obj.position = startPosition + resolveDirection * (searchPoint * ratioA);
                collidingRigidBody.position = collidingRigidBody.position + resolveDirection * (-searchPoint * ratioB);
              }
              else
              {
                //Normal collision
                for(int i=0; i<10; i++)
                {
                  float searchDelta = (collisionTime - noCollisionTime) / 2.0f;
                  float searchTime = collisionTime - searchDelta;
                  obj.position = startPosition + obj.velocity * searchTime;
                  transform = collidingRigidBody.transformTo(obj);
                  if(obj.collision.intersectsFast(collidingRigidBody.collision, transform))
                  {
                    collisionTime = searchTime;
                  }
                  else
                  {
                    noCollisionTime = searchTime;
                  }
                }
                obj.position = startPosition + obj.velocity * noCollisionTime;
                obj.velocity = vec3(0,0,0); //TODO real collision response
              }
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
        }
        if(numChecks > 0 && m_CVars.p_drawCollisionGeometry > 0)
        {
          g_Env.renderer.drawBox(queryBox, vec4(0.0f, 1.0f, 0.0f, 1.0f));
        }
      }
    }

    void RegisterCVars(ConfigVarsBinding* storage)
    {
      foreach(m;__traits(allMembers,typeof(m_CVars))){
				storage.registerVariable(m,__traits(getMember,this.m_CVars,m));
			}
    }
}