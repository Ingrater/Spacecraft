module physics.rigidbody;

import base.physics;
import thBase.math3d.all;
import game.collision;

class RigidBody : IRigidBody
{
  CollisionHull m_collision;
  float m_inverseMass;
  mat3  m_inverseIntertiaTensor;

  public:
    float remainingTime;
    float inverseResolveMass;

    @property float inverseMass() const
    {
      return m_inverseMass;
    }

    @property ref const(mat3) inverseIntertiaTensor() const
    {
      return m_inverseIntertiaTensor;
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
    this(CollisionHull collision, float fInverseMass, IntertiaTensorType intertiaTensor)
    {
      m_collision = collision;
      m_inverseMass = fInverseMass;
      inverseResolveMass = fInverseMass;
      rotation = Quaternion(vec3(1,0,0), 0);
      velocity = vec3(0,0,0);
      angularMomentum = vec3(0,0,0);

      final switch(intertiaTensor)
      {
        case IntertiaTensorType.fixed:
          m_inverseIntertiaTensor.f[0..9] = 0.0f;
          break;
        case IntertiaTensorType.box:
          vec3 size = m_collision.maxBounds - m_collision.minBounds;
          vec3 squaredSize = size * size;
          float massFactor = 12.0f / m_inverseMass;
          m_inverseIntertiaTensor.f[0..9] = 0.0f;
          m_inverseIntertiaTensor.f[0] = massFactor * (squaredSize.y + squaredSize.z);
          m_inverseIntertiaTensor.f[4] = massFactor * (squaredSize.x + squaredSize.z);
          m_inverseIntertiaTensor.f[8] = massFactor * (squaredSize.x + squaredSize.y);
          m_inverseIntertiaTensor = m_inverseIntertiaTensor.Inverse();
          break;
        case IntertiaTensorType.sphere:
          m_inverseIntertiaTensor.f[0..9] = 0.0f;
          float radiusSquare = maxBounds.x * maxBounds.x;
          float massFactor = 2.0f / 5.0f / m_inverseMass;
          float c = massFactor * radiusSquare;
          m_inverseIntertiaTensor.f[0] = c;
          m_inverseIntertiaTensor.f[4] = c;
          m_inverseIntertiaTensor.f[8] = c;
          m_inverseIntertiaTensor = m_inverseIntertiaTensor.Inverse();
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