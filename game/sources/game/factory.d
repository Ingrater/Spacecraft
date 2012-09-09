module game.factory;

import base.game;
import game.game;

class GameFactory : IGameFactory {
public:
	override void Init(){
	}
	override IGameThread GetGame(){
		return New!GameSimulation();
	}

  override void DeleteGame(IGameThread game)
  {
    Delete(game);
  }
}

IGameFactory NewGameFactory(){
	return New!GameFactory();
}

void DeleteGameFactory(IGameFactory factory)
{
  Delete(factory);
}

