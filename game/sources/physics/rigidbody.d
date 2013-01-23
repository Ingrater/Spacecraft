module physics.rigidbody;

import base.physics;
import thBase.math3d.all;
import game.collision;

class RigidBody : IRigidBody
{
  CollisionHull m_collision;
  float m_inverseMass;
  mat3  m_inverseInertiaTensor;

  public:
    float remainingTime;
    float inverseResolveMass;

    @property float inverseMass() const
    {
      return m_inverseMass;
    }

    @property ref const(mat3) inverseInertiaTensor() const
    {
      return m_inverseInertiaTensor;
    }

    @property const(CollisionHull) collision() const
    {
      return m_collision;
    }

    /**
     * Constructor
     * Params:
     *  collsion = the collision mesh to use
     */
    this(CollisionHull collision, float fInverseMass, InertiaTensorType inertiaTensor)
    {
      m_collision = collision;
      m_inverseMass = fInverseMass;
      inverseResolveMass = fInverseMass;
      rotation = Quaternion(vec3(1,0,0), 0);
      velocity = vec3(0,0,0);
      angularMomentum = vec3(0,0,0);

      final switch(inertiaTensor)
      {
        case InertiaTensorType.fixed:
          m_inverseInertiaTensor.f[0..9] = 0.0f;
          break;
        case InertiaTensorType.box:
          vec3 size = m_collision.maxBounds - m_collision.minBounds;
          vec3 squaredSize = size * size;
          float massFactor = 1.0f / (12.0f * m_inverseMass);
          m_inverseInertiaTensor.f[0..9] = 0.0f;
          m_inverseInertiaTensor.f[0] = 1.0f / (massFactor * (squaredSize.y + squaredSize.z));
          m_inverseInertiaTensor.f[4] = 1.0f / (massFactor * (squaredSize.x + squaredSize.z));
          m_inverseInertiaTensor.f[8] = 1.0f / (massFactor * (squaredSize.x + squaredSize.y));
          //m_inverseInertiaTensor = m_inverseInertiaTensor.Inverse();
          break;
        case InertiaTensorType.sphere:
          m_inverseInertiaTensor.f[0..9] = 0.0f;
          float radiusSquare = m_collision.maxBounds.x * m_collision.maxBounds.x;
          float massFactor = 2.0f / 5.0f / m_inverseMass;
          float c = massFactor * radiusSquare;
          m_inverseInertiaTensor.f[0] = c;
          m_inverseInertiaTensor.f[4] = c;
          m_inverseInertiaTensor.f[8] = c;
          m_inverseInertiaTensor = m_inverseInertiaTensor.Inverse();
          break;
      }
    }

    /**
     * returns the transformation that will transform this
     * rigid body into the model space of another rigid body
     */
    mat4 transformTo(RigidBody other)
    {
      return this.rotation.toMat4() * TranslationMatrix(this.position - other.position) * other.rotation.toMat4().Transpose();
    }
}