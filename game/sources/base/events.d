module base.events;

public import base.net;

struct EventId
{
  ubyte id;

  alias id this;

  this(ubyte id)
  {
    this.id = id;
  }

  string toString()()
  {
    static assert(0, "not convertible");
  }
}

interface IEvent : ISerializeable {
	void call();
  string description();
}
