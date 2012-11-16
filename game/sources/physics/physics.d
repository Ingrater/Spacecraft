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
      debug 
      {
        FloatingPointControl fpctrl; 
        fpctrl.enableExceptions(FloatingPointControl.severeExceptions);
      }

      if(m_CVars.p_fixedTimestep > 0)
        timeDiff = cast(float)m_CVars.p_fixedTimestep;

      vec3 gravity = vec3(0, -9.81, 0);
      float secondDiff = timeDiff / 1000.0f;
      foreach(size_t objNum,objA; m_simulated.toArray())
      {
        objA.velocity += gravity * secondDiff;
        auto startPosition = objA.position;
        objA.position = startPosition + objA.velocity * secondDiff;

        float collisionRadius = objA.collision.boundingRadius + objA.velocity.length * secondDiff;
        vec3 boundOffset = vec3(collisionRadius, collisionRadius, collisionRadius);
        auto queryBox = AlignedBox(objA.position  - boundOffset, objA.position + boundOffset);
        auto query = m_octree.getObjectsInBox(queryBox);
        uint numCollisions = 0, numChecks = 0;

        //information about the collision that has been found
        float timeOfImpact = float.max;
        vec3 velocityDiffA, velocityDiffB;
        RigidBody objB;
        for(;!query.empty();query.popFront())
        {
          IGameObject colObj = query.front();
          if(colObj.physicsComponent !is null)
          {
            auto collidingRigidBody = static_cast!RigidBody(colObj.physicsComponent);
            if(collidingRigidBody is objA)
              continue;

            numChecks++;
            
            Ray[32] intersections = void;
            mat4 collidingRigidyBodyTransform = collidingRigidBody.transformTo(objA);
            size_t numIntersections = objA.collision.getIntersections(collidingRigidBody.collision, collidingRigidyBodyTransform, intersections);

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
                intersectionNormalOther = -(normalFindRay.dir.normalize());
              }

              float intersectionPosCurrent = -0.01f;
              vec3 intersectionNormalCurrent;
              if(!objA.collision.intersects(normalFindRay, mat4.Identity(), intersectionPosCurrent, intersectionNormalCurrent))
              {
                intersectionPosCurrent = 0.0f;
                intersectionNormalOther = normalFindRay.dir.normalize();
              }

              if(m_CVars.p_drawCollisionInfo > 0)
              {
                mat4 rotation = objA.rotation.toMat4();
                g_Env.renderer.drawArrow(objA.position + (rotation * normalFindRay.get(intersectionPosOther)), objA.position + (rotation * (normalFindRay.get(intersectionPosOther) + intersectionNormalOther)), vec4(1.0f, 0.0f, 0.0f, 1.0f));
                g_Env.renderer.drawArrow(objA.position + (rotation * normalFindRay.get(intersectionPosCurrent)), objA.position + (rotation * (normalFindRay.get(intersectionPosCurrent) + intersectionNormalCurrent)), vec4(0.0f, 0.0f, 1.0f, 1.0f));
                g_Env.renderer.drawArrow(objA.position + (rotation * normalFindRay.pos), objA.position + (rotation * normalFindRay.end), vec4(0.0f, 1.0f, 1.0f, 1.0f));
              }

              numCollisions++;
              if(m_CVars.p_drawCollisionGeometry > 0/* && numCollisions == 1 && objNum == 1*/)
              {
                collidingRigidBody.collision.debugDraw(collidingRigidBody.position, collidingRigidBody.rotation, g_Env.renderer);
                //collidingRigidBody.collision.debugDraw(collidingRigidyBodyTransform * objA.rotation.toMat4() * TranslationMatrix(objA.position.toVec3()) , g_Env.renderer, vec4(0.0f, 1.0f, 0.0f, 1.0f));
                //objA.collision.debugDraw(objA.rotation.toMat4() * TranslationMatrix(objA.position.toVec3()), g_Env.renderer, vec4(0.0f, 1.0f, 0.0f, 1.0f));
              }
              

              

              //Try finding the last point where they did not collide
              float noCollisionTime = 0.0f;
              float collisionTime = secondDiff;

              objA.position = startPosition;
              mat4 transform = collidingRigidBody.transformTo(objA);
              if(objA.collision.intersectsFast(collidingRigidBody.collision, transform))
              {
                //We have a intersection to resolve
                vec3 resolveDirection = objA.rotation.toMat4().transformDirection(-intersectionNormalCurrent);
                float searchPoint = 0.0f;
                float searchDelta = 1.0f;
                float stillSearchingMult = 2.0f;
                for(int i=0; i<10; i++)
                {
                  searchPoint += searchDelta;
                  objA.position = startPosition + resolveDirection * searchPoint;
                  transform = collidingRigidBody.transformTo(objA);
                  if(objA.collision.intersectsFast(collidingRigidBody.collision, transform))
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
                float inverseTotalMass = 1.0f / (objA.inverseMass + collidingRigidBody.inverseMass);
                float ratioA = inverseTotalMass * objA.inverseMass; //how much the first object will be affected by the intersection correction
                float ratioB = inverseTotalMass * collidingRigidBody.inverseMass; //how much the second object will be affected by the intersection correction
                objA.position = startPosition + resolveDirection * (searchPoint * ratioA);
                startPosition = objA.position;
                collidingRigidBody.position = collidingRigidBody.position + resolveDirection * (-searchPoint * ratioB);

                objB = null;
                timeOfImpact = 0.0f;
              }
              else
              {
                if(timeOfImpact > 0.0f)
                {
                  //Normal collision
                  for(int i=0; i<10; i++)
                  {
                    float searchDelta = (collisionTime - noCollisionTime) / 2.0f;
                    float searchTime = collisionTime - searchDelta;
                    objA.position = startPosition + objA.velocity * searchTime;
                    transform = collidingRigidBody.transformTo(objA);
                    if(objA.collision.intersectsFast(collidingRigidBody.collision, transform))
                    {
                      collisionTime = searchTime;
                    }
                    else
                    {
                      noCollisionTime = searchTime;
                    }
                  }
                  if(timeOfImpact > noCollisionTime)
                  {
                    timeOfImpact = noCollisionTime;
                    objB = collidingRigidBody;
                    //TODO real collision response
                   // velocityDiffA = (objA.velocity * -0.2) - objA.velocity; 
                    //velocityDiffB = vec3(0,0,0);

                    /*vec3 collisionNormal = (intersectionNormalCurrent - intersectionNormalOther).normalize();
                    float bounciness = 0.1f;
                    vec3 impulseDiff = (1.0f + bounciness) * collisionNormal * ((objA.velocity - objB.velocity).dot(collisionNormal)) / ( objA.inverseMass + objB.inverseMass );
                    velocityDiffA = -impulseDiff * objA.inverseMass;
                    velocityDiffB = impulseDiff * objB.inverseMass;*/
                  }
                }
              }
            }

            if(m_CVars.p_drawCollisionInfo > 0)
            {
              mat4 rotation = objA.rotation.toMat4();
              foreach(ref intersection; intersections[0..numIntersections])
              {
                g_Env.renderer.drawLine(objA.position + (rotation * intersection.pos), objA.position + (rotation * intersection.end), vec4(1.0f, 0.0f, 0.0f, 1.0f));
              }
            }
          }
        }

        if(objB !is null) //did we find a collision?
        {
          objA.position = startPosition + objA.velocity * timeOfImpact;
          objA.velocity += velocityDiffA;
          objB.velocity += velocityDiffB;
        }
        if(numCollisions > 0)
        {
          if(m_CVars.p_drawCollisionGeometry > 0)
          {
            objA.collision.debugDraw(objA.position, objA.rotation, g_Env.renderer);
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