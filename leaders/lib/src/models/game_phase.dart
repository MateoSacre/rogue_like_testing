/// The two phases of a player's turn, plus a terminal state.
enum GamePhase {
  action,
  recruitment,
  gameOver;

  String get label {
    switch (this) {
      case GamePhase.action:
        return 'Action';
      case GamePhase.recruitment:
        return 'Recrutement';
      case GamePhase.gameOver:
        return 'Partie terminée';
    }
  }
}
