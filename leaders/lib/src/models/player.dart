/// The two players in a game of Leaders.
enum PlayerId {
  one,
  two;

  PlayerId get opponent => this == PlayerId.one ? PlayerId.two : PlayerId.one;

  String get label => this == PlayerId.one ? 'Joueur 1' : 'Joueur 2';
}
