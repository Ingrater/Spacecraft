module physics.physics;

import base.all;
import base.physics;
import physics.rigidbody; 
import physics.cvars;
import base.octree;
import thBase.container.vector;
import thBase.math3d.all;
import thBase.casts;
import thBase.math;
import thBase.logging;
import thBase.plugin;
import game.collision;

import std.math;

shared static this()
{
  g_Env.physicsPlugin = New!PhysicsPlugin();
}

shared static ~this()
{
  Delete(g_Env.physicsPlugin);
}

__gshared PhysicsSimulation g_simulation;

class PhysicsPlugin : IPhysicsPlugin
{
  public:
    @property override string name()
    {
      return "PhysicsPlugin";
    }

    override size_t GetScanRoots(ScanPair[] results)
    {
      if(results.length < 1)
        return 1;

      results[0] = ScanPair(cast(void*)&g_simulation, typeid(typeof(g_simulation)));
      return 1;
    }

    override bool isInPluginMemory(void* ptr)
    {
      return g_pluginAllocator.isInMemory(ptr);
    }

    override void* GetPluginAllocator()
    {
      return cast(void*)g_pluginAllocator;
    }

    override IPhysics CreatePhysics(Octree octree)
    {
      g_simulation = New!PhysicsSimulation(octree);
      return g_simulation;
    }

    override void DeletePhysics(IPhysics physics)
    {
      g_simulation = null;
      Delete(physics);
    }

    override IRigidBody CreateRigidBody(CollisionHull collision, float fInverseMass, InertiaTensorType inertiaTensor)
    {
      return New!RigidBody(collision, fInverseMass, inertiaTensor);
    }

    override void DeleteRigidBody(IRigidBody b)
    {
      Delete(b);
    }
}

class PhysicsSimulation : IPhysics
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

    override void AddSimulatedBody(IRigidBody obj)
    {
      auto b = static_cast!RigidBody(obj);
      assert(g_Env.physicsPlugin.isInPluginMemory(cast(void*)b));
      m_simulated ~= b;
      m_simulated.insertionSort((ref a, ref b){ return a.inverseResolveMass < b.inverseResolveMass; });
    }

    override void RemoveSimulatedBody(IRigidBody obj)
    {
      m_simulated.remove(static_cast!RigidBody(obj));
    }

    override void Simulate(float timeDiff)
    {
      debug 
      {
        FloatingPointControl fpctrl; 
        fpctrl.enableExceptions(FloatingPointControl.severeExceptions);
      }

      /*Triangle t1 = Triangle(vec3(1,1,-1), vec3(1,-1,1), vec3(1,-1,-1));
      Triangle t2 = Triangle(vec3(2.0999756,-0.92272949,-1), vec3(0.099975586, -0.92272949, -1), vec3(0.099975586,-0.92272949,1));
      Ray dummy;
      t1.intersects(t2, dummy);

      Ray should = Ray(vec3(1,-1,0),vec3(0,0,1));

      g_Env.renderer.drawLine(Position(should.pos), Position(should.end), vec4(0.0f, 0.0f, 1.0f, 1.0f));
      g_Env.renderer.drawLine(Position(dummy.pos), Position(dummy.end), vec4(1.0f, 0.0f, 0.0f, 1.0f));
      g_Env.renderer.drawLine(Position(t1.v0), Position(t1.v1), vec4(1.0f, 1.0f, 0.0f, 1.0f));
      g_Env.renderer.drawLine(Position(t1.v1), Position(t1.v2), vec4(1.0f, 1.0f, 0.0f, 1.0f));
      g_Env.renderer.drawLine(Position(t1.v2), Position(t1.v0), vec4(1.0f, 1.0f, 0.0f, 1.0f));

      g_Env.renderer.drawLine(Position(t2.v0), Position(t2.v1), vec4(0.5f, 1.0f, 0.0f, 1.0f));
      g_Env.renderer.drawLine(Position(t2.v1), Position(t2.v2), vec4(0.5f, 1.0f, 0.0f, 1.0f));
      g_Env.renderer.drawLine(Position(t2.v2), Position(t2.v0), vec4(0.5f, 1.0f, 0.0f, 1.0f));

      bool t = true;
      if(t)
        return;*/


      if(m_CVars.p_fixedTimestep > 0)
        timeDiff = cast(float)m_CVars.p_fixedTimestep;

      vec3 gravity = vec3(0, -9.81, 0);
      float secondDiff = timeDiff / 1000.0f;

      //apply constant forces and accelerations and set simulation time
      foreach(obj; m_simulated.toArray())
      {
        if(m_CVars.p_gravity > 0.0 && obj.inverseMass > 0.0f)
          obj.velocity += gravity * secondDiff;
        obj.remainingTime = secondDiff;
      }

      uint numIterations = cast(uint)m_CVars.p_iterations;
      float fCorrection = cast(float)m_CVars.p_correction;

      for(uint iteration=0; iteration < numIterations; iteration++)
      {
        foreach(size_t objNum,objA; m_simulated.toArray())
        {
          if(objA.remainingTime < FloatEpsilon || objA.inverseMass <= 0.0f)
            continue;

          //Update the position
          auto startPosition = objA.position;
          objA.position = startPosition + objA.velocity * objA.remainingTime;

          //Update the rotation
          auto startRotation = objA.rotation;
          mat3 currentRotationA = objA.rotation.toMat3();
          mat3 inverseIntertiaTensorWorldspaceA = currentRotationA * objA.inverseInertiaTensor * currentRotationA.Transpose();
          vec3 angularVelocityA = inverseIntertiaTensorWorldspaceA * objA.angularMomentum;
          objA.rotation = startRotation.Integrate(angularVelocityA, objA.remainingTime).normalize();

          //Compute the collision bounding box
          float collisionRadius = objA.collision.boundingRadius + objA.velocity.length * objA.remainingTime;
          vec3 boundOffset = vec3(collisionRadius, collisionRadius, collisionRadius);
          auto queryBox = AlignedBox(objA.position  - boundOffset, objA.position + boundOffset);
          auto query = m_octree.getObjectsInBox(queryBox);
          uint numCollisions = 0, numChecks = 0;

          //information about the collision that has been found
          float timeOfImpact = objA.remainingTime;
          vec3 newVelocityA, newVelocityB, newAngularMomentumA, newAngularMomentumB;
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
              Triangle[2][32] triangles = void;
              mat4 collidingRigidyBodyTransform = collidingRigidBody.transformTo(objA);
              size_t numIntersections = objA.collision.getIntersections(collidingRigidBody.collision, collidingRigidyBodyTransform, intersections, triangles);

              if(numIntersections > 0)
              {

                /*{
                  //objA.collision.debugDraw(Position(vec3(0,0,0)), objA.rotation, g_Env.renderer, vec4(0.0f, 1.0f, 0.0f, 1.0f));
                  //collidingRigidBody.collision.debugDraw(Position(collidingRigidyBodyTransform * vec3(0,0,0)), objA.rotation, g_Env.renderer, vec4(0.0f, 1.0f, 0.0f, 1.0f));
                  mat4 rotation = objA.rotation.toMat4();
                  size_t index = cast(size_t)m_CVars.p_debugNum;
                  g_Env.renderer.drawLine(Position(intersections[index].pos), Position(intersections[index].end), vec4(1.0f, 0.0f, 0.0f, 1.0f));
                  g_Env.renderer.drawLine(Position(triangles[index][0].v0), Position(triangles[index][0].v1), vec4(1.0f, 1.0f, 0.0f, 1.0f));
                  g_Env.renderer.drawLine(Position(triangles[index][0].v1), Position(triangles[index][0].v2), vec4(1.0f, 1.0f, 0.0f, 1.0f));
                  g_Env.renderer.drawLine(Position(triangles[index][0].v2), Position(triangles[index][0].v0), vec4(1.0f, 1.0f, 0.0f, 1.0f));

                  g_Env.renderer.drawLine(Position(triangles[index][1].v0), Position(triangles[index][1].v1), vec4(0.5f, 1.0f, 0.0f, 1.0f));
                  g_Env.renderer.drawLine(Position(triangles[index][1].v1), Position(triangles[index][1].v2), vec4(0.5f, 1.0f, 0.0f, 1.0f));
                  g_Env.renderer.drawLine(Position(triangles[index][1].v2), Position(triangles[index][1].v0), vec4(0.5f, 1.0f, 0.0f, 1.0f));
                }*/

                vec3 collisionPoint = intersections[0].pos + intersections[0].end;
                foreach(ref intersection; intersections[1..numIntersections])
                {
                  collisionPoint = collisionPoint + intersection.pos + intersection.end;
                }
                collisionPoint = collisionPoint * (1.0f / cast(float)(numIntersections * 2));

                Ray normalFindRay = Ray.CreateFromPoints(vec3(0,0,0), collisionPoint);
                normalFindRay.pos = normalFindRay.pos - (normalFindRay.dir * 0.1f);

                float intersectionPosOther = -0.01f;
                vec3 intersectionNormalOther;
                if(!collidingRigidBody.collision.intersects(normalFindRay, collidingRigidyBodyTransform, intersectionPosOther, intersectionNormalOther))
                {
                  //logInfo("normal fallback for objB");
                  intersectionPosOther = 0.0f;
                  intersectionNormalOther = -(normalFindRay.dir.normalize());

                  /*mat4 rotation = objA.rotation.toMat4();
                  g_Env.renderer.drawArrow(objA.position + (rotation * normalFindRay.pos), objA.position + (rotation * normalFindRay.end), vec4(0.0f, 1.0f, 1.0f, 1.0f));
                  collidingRigidBody.collision.debugDraw(collidingRigidBody.position, collidingRigidBody.rotation, g_Env.renderer, vec4(1.0f, 1.0f, 0.0f, 1.0f));
                  objA.collision.debugDraw(objA.position, objA.rotation, g_Env.renderer, vec4(0.5f, 1.0f, 0.0f, 1.0f));*/
                }

                float intersectionPosCurrent = -0.01f;
                vec3 intersectionNormalCurrent;
                if(!objA.collision.intersects(normalFindRay, mat4.Identity(), intersectionPosCurrent, intersectionNormalCurrent))
                {
                  //logInfo("normal fallback for objA");
                  intersectionPosCurrent = 0.0f;
                  intersectionNormalCurrent = normalFindRay.dir.normalize();
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
                float collisionTime = objA.remainingTime;

                objA.position = startPosition;
                mat4 transform = collidingRigidBody.transformTo(objA);
                {
                  //Normal collision
                  for(int i=0; i<5; i++)
                  {
                    float searchDelta = (collisionTime - noCollisionTime) / 2.0f;
                    float searchTime = collisionTime - searchDelta;
                    objA.position = startPosition + objA.velocity * searchTime;
                    objA.rotation = startRotation.Integrate(angularVelocityA, searchTime).normalize();
                    //objA.collision.debugDraw(objA.position, objA.rotation, g_Env.renderer, vec4(0.0f, 1.0f, 0.0f, 1.0f));
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
                  //logInfo("collisionTime: %f noCollisionTime: %f", collisionTime, noCollisionTime);
                  //if(noCollisionTime > -1.0f)
                  {
                    timeOfImpact = noCollisionTime;
                    objB = collidingRigidBody;
                    //logInfo("objA %x objB %x", cast(void*)objA, cast(void*)objB);


                    mat4 rotation = objA.rotation.toMat4();

                    vec3 collisionNormal = rotation.transformDirection((intersectionNormalOther).normalize());
                    
                    if(m_CVars.p_collisionResponse < 1.0)
                    {
                      //collision response without rotation
                      float bounciness = 0.5f;
                      float f = (1.0f + bounciness) * ((objA.velocity - objB.velocity).dot(collisionNormal)) / ( objA.inverseMass + objB.inverseMass );
                      vec3 impulseDiff = f * collisionNormal;
                      newVelocityA = (objA.velocity - (impulseDiff * objA.inverseMass)) * fCorrection;
                      newVelocityB = (objB.velocity + (impulseDiff * objB.inverseMass)) * fCorrection;

                      if(m_CVars.p_drawCollisionInfo > 0)
                      {
                      
                        g_Env.renderer.drawArrow(objA.position + (rotation * collisionPoint), objA.position + (rotation * (collisionPoint + collisionNormal)), vec4(1.0f, 1.0f, 1.0f, 1.0f));
                        g_Env.renderer.drawArrow(objA.position + (rotation * collisionPoint), objA.position + (rotation * (collisionPoint + impulseDiff)), vec4(0.0f, 0.0f, 0.0f, 1.0f));
                      }
                    }
                    else
                    {
                      //collision repsonse with rotation
                      mat3 currentRotationB = objB.rotation.toMat3();
                      mat3 inverseIntertiaTensorWorldspaceB = currentRotationB * objB.inverseInertiaTensor * currentRotationB.Transpose();
                      vec3 angularVelocityB = inverseIntertiaTensorWorldspaceB * objB.angularMomentum;
                      vec3 radiusA = (rotation * collisionPoint);
                      vec3 radiusB = radiusA + (objA.position - objB.position);
                      radiusA = -radiusA;
                      radiusB = -radiusB;
                      float bounciness = 0.5f;
                      float objectVelocityDiff = ((objA.velocity - objB.velocity).dot(collisionNormal));
                      float applicationPointVelocityA = angularVelocityA.dot(radiusA.cross(collisionNormal));
                      float applicationPointVelocityB = angularVelocityB.dot(radiusB.cross(collisionNormal));
                      float totalVelocityDiff = objectVelocityDiff + applicationPointVelocityA - applicationPointVelocityB;
                        
                      vec3 divisorA = (inverseIntertiaTensorWorldspaceA * radiusA.cross(collisionNormal)).cross(radiusA);
                      vec3 divisorB = (inverseIntertiaTensorWorldspaceB * radiusB.cross(collisionNormal)).cross(radiusB);
                      float f2 = -(1.0f + bounciness) * totalVelocityDiff / ( objA.inverseMass + objB.inverseMass + collisionNormal.dot(divisorA + divisorB));
                      vec3 impulseDiff2 = f2 * collisionNormal;
                      //logInfo("impulseDiff %s", impulseDiff2.f[]);
                      newVelocityA = (objA.velocity + (impulseDiff2 * objA.inverseMass)) * fCorrection;
                      newVelocityB = (objB.velocity - (impulseDiff2 * objB.inverseMass)) * fCorrection;
                      newAngularMomentumA = (objA.angularMomentum + radiusA.cross(impulseDiff2)) * fCorrection;
                      newAngularMomentumB = (objB.angularMomentum - radiusB.cross(impulseDiff2)) * fCorrection;

                      if(m_CVars.p_drawCollisionInfo > 0)
                      {
                        auto colPoint = objA.position + (rotation * collisionPoint);
                        g_Env.renderer.drawArrow(colPoint, colPoint + collisionNormal, vec4(1.0f, 1.0f, 1.0f, 1.0f));
                        g_Env.renderer.drawArrow(colPoint, colPoint + radiusA, vec4(1.0f, 0.5f, 0.0f, 1.0f));
                        g_Env.renderer.drawArrow(colPoint, colPoint + radiusB, vec4(1.0f, 0.5f, 0.0f, 1.0f));
                        g_Env.renderer.drawArrow(colPoint, colPoint + impulseDiff2, vec4(0.75f, 0.0f, 0.75f, 1.0f));
                      }
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
            if(timeOfImpact > FloatEpsilon)
            {
              objA.position = startPosition + objA.velocity * timeOfImpact;
              objA.rotation = startRotation.Integrate(angularVelocityA, timeOfImpact).normalize();
            }
            objA.velocity = newVelocityA;
            objB.velocity = newVelocityB;
            objA.angularMomentum = newAngularMomentumA;
            objB.angularMomentum = newAngularMomentumB;
            objA.remainingTime -= timeOfImpact;
          }
          else //no collision
          {
            objA.remainingTime = 0.0f;
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

        //Now resolve all intersections by doing shock propagation
        //First reset the resolve mass to the real mass
        foreach(obj; m_simulated.toArray())
        {
          obj.inverseResolveMass = obj.inverseMass;
        }

        uint resolveCount = 1;
        while(resolveCount > 0)
        {
          resolveCount = 0;

          foreach(robjA; m_simulated.toArray())
          {
            float collisionRadius = robjA.collision.boundingRadius + robjA.velocity.length * robjA.remainingTime;
            vec3 boundOffset = vec3(collisionRadius, collisionRadius, collisionRadius);
            auto queryBox = AlignedBox(robjA.position  - boundOffset, robjA.position + boundOffset);
            auto query = m_octree.getObjectsInBox(queryBox);
            uint numCollisions = 0, numChecks = 0;

            //information about the collision that has been found
            float timeOfImpact = float.max;
            vec3 newVelocityA, newVelocityB;
            RigidBody robjB;
            for(;!query.empty();query.popFront())
            {
              IGameObject colObj = query.front();
              if(colObj.physicsComponent !is null)
              {
                robjB = static_cast!RigidBody(colObj.physicsComponent);
                if(robjB is robjA)
                  continue;
                if(robjB.inverseResolveMass == 0.0f && robjA.inverseResolveMass == 0.0f)
                  continue;

                Ray[32] intersections = void;
                mat4 collidingRigidyBodyTransform = robjB.transformTo(robjA);
                size_t numIntersections = robjA.collision.getIntersections(robjB.collision, collidingRigidyBodyTransform, intersections);
              
                if(numIntersections > 0)
                {
                  vec3 collisionPoint = intersections[0].pos + intersections[0].end;
                  foreach(ref intersection; intersections[1..numIntersections])
                  {
                    collisionPoint = collisionPoint + intersection.pos + intersection.end;
                  }
                  collisionPoint = collisionPoint * (1.0f / cast(float)(numIntersections*2));

                  Ray normalFindRay = Ray.CreateFromPoints(vec3(0,0,0), collisionPoint);
                  if(normalFindRay.dir.length < FloatEpsilon && numIntersections >= 2)
                  {
                    auto p = Plane(intersections[0].pos, intersections[0].end, intersections[1].pos);
                    normalFindRay.dir = p.normal;
                    if(normalFindRay.dir.length < FloatEpsilon)
                      normalFindRay.dir = vec3(0,1,0);
                  }


                  float intersectionPosOther = -0.01f;
                  vec3 intersectionNormalOther;
                  if(!robjB.collision.intersects(normalFindRay, collidingRigidyBodyTransform, intersectionPosOther, intersectionNormalOther))
                  {
                    intersectionPosOther = 0.0f;
                    intersectionNormalOther = -(normalFindRay.dir.normalize());
                  }

                  float intersectionPosCurrent = -0.01f;
                  vec3 intersectionNormalCurrent;
                  if(!robjA.collision.intersects(normalFindRay, mat4.Identity(), intersectionPosCurrent, intersectionNormalCurrent))
                  {
                    intersectionPosCurrent = 0.0f;
                    intersectionNormalCurrent = normalFindRay.dir.normalize();
                  }
                  assert(intersectionNormalCurrent.length() > 0.1f);

                  if(m_CVars.p_drawCollisionInfo > 0)
                  {
                    mat4 rotation = robjA.rotation.toMat4();
                    g_Env.renderer.drawArrow(robjA.position + (rotation * normalFindRay.get(intersectionPosOther)), robjA.position + (rotation * (normalFindRay.get(intersectionPosOther) + intersectionNormalOther)), vec4(1.0f, 0.0f, 0.0f, 1.0f));
                    g_Env.renderer.drawArrow(robjA.position + (rotation * normalFindRay.get(intersectionPosCurrent)), robjA.position + (rotation * (normalFindRay.get(intersectionPosCurrent) + intersectionNormalCurrent)), vec4(0.0f, 0.0f, 1.0f, 1.0f));
                    g_Env.renderer.drawArrow(robjA.position + (rotation * normalFindRay.pos), robjA.position + (rotation * normalFindRay.end), vec4(0.0f, 1.0f, 1.0f, 1.0f));
                    robjB.collision.debugDraw(robjB.position, robjB.rotation, g_Env.renderer);
                  }

                  //We have a intersection to resolve
                  vec3 resolveDirection = robjA.rotation.toMat4().transformDirection(intersectionNormalCurrent);
                  float searchPoint = 0.0f;
                  float searchDelta = 1.0f;
                  float stillSearchingMult = 2.0f;
                  float noIntersectionTime = 0.0f;
                  auto startPosition = robjB.position;
                  for(int i=0; i<10; i++)
                  {
                    searchPoint += searchDelta;
                    robjB.position = startPosition + resolveDirection * searchPoint;
                    auto transform = robjB.transformTo(robjA);

                    Ray[32] testIntersections = void;
                    size_t numTestIntersections = robjA.collision.getIntersections(robjB.collision, transform, testIntersections);

                    if(m_CVars.p_drawCollisionInfo > 0 && i == 1)
                    {
                      mat4 rotation = robjA.rotation.toMat4();
                      foreach(ref intersection; testIntersections[0..numTestIntersections])
                      {
                        g_Env.renderer.drawLine(robjA.position + (rotation * intersection.pos), robjA.position + (rotation * intersection.end), vec4(1.0f, 0.0f, 0.0f, 1.0f));
                      }
                    }

                    if(numTestIntersections > 0)
                    {
                      //if(m_CVars.p_drawCollisionInfo > 0)
                        //robjB.collision.debugDraw(robjB.position, robjB.rotation, g_Env.renderer, vec4(1.0f, 1.0f, 0.0f, 1.0f));
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
                      //if(m_CVars.p_drawCollisionInfo > 0)
                        //robjB.collision.debugDraw(robjB.position, robjB.rotation, g_Env.renderer, vec4(0.0f, 1.0f, 1.0f, 1.0f));
                      //not intersecting anymore
                      noIntersectionTime = searchPoint;
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
                  if(noIntersectionTime == 0.0f)
                    noIntersectionTime = searchPoint;
                  float sum = (robjA.inverseResolveMass + robjB.inverseResolveMass);
                  noIntersectionTime += FloatEpsilon;
                  if(sum > 0.0f)
                  {
                    float inverseTotalMass = 1.0f / sum;
                    float ratioA = inverseTotalMass * robjA.inverseResolveMass; //how much the first object will be affected by the intersection correction
                    float ratioB = inverseTotalMass * robjB.inverseResolveMass; //how much the second object will be affected by the intersection correction
                    robjA.position = robjA.position + resolveDirection * (-noIntersectionTime * ratioA);
                    robjB.position = startPosition + resolveDirection * (noIntersectionTime * ratioB);
                    /*debug
                    {
                      auto transform = robjB.transformTo(robjA);
                      assert(!robjB.collision.intersectsFast(robjA.collision, transform));
                    }*/
                    //assign the new resolve mass
                    auto newResolveMass = min(robjA.inverseResolveMass, robjB.inverseResolveMass);
                    robjA.inverseResolveMass = newResolveMass;
                    robjB.inverseResolveMass = newResolveMass;
                    resolveCount++;
                    //logInfo("resloving %f", noIntersectionTime);
                  }
                }
              }
            }
          }
        }
      }
    }

    override void RegisterCVars(ConfigVarsBinding* storage)
    {
      foreach(m;__traits(allMembers,typeof(m_CVars))){
				storage.registerVariable(m,__traits(getMember,this.m_CVars,m));
			}
    }
}