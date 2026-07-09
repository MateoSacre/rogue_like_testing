/// Every character kind in the game, including the [leader] (which is not part
/// of the draftable river) and the 18 recruitable champions.
///
/// Several entries are placeholders / stubs whose precise box rules are not yet
/// available (see [CharacterMeta.isStub]); they participate in the river and can
/// be recruited, but expose no special behaviour beyond normal movement.
enum CharacterType {
  leader,
  // --- Fully specified champions ---
  illusionniste,
  lanceGrappin,
  rodeuse,
  tavernier,
  manipulatrice,
  archere,
  assassin,
  geolier,
  protecteur,
  cogneur,
  vizir,
  sauteur,
  // --- Partially specified (stub) champions ---
  gardeRoyal,
  // --- Generic placeholders to fill the 18-champion pool (TODO: real rules) ---
  recrueA,
  recrueB,
  recrueC,
  recrueD,
  recrueE,
}

/// Static gameplay metadata for a [CharacterType].
class CharacterMeta {
  final String displayName;

  /// Short label drawn inside the piece token in the UI.
  final String token;

  /// Identifier of the active [Ability] this character can use, or null if it
  /// has none (passive characters and plain placeholders).
  final String? activeAbilityId;

  /// Whether the character can perform a normal "move to an adjacent empty cell"
  /// action. False for characters whose movement is entirely special (their
  /// ability *is* their movement).
  final bool hasNormalMove;

  /// Whether the character has an always-on passive effect handled by the engine
  /// (victory modifiers, blocking, range bonuses…).
  final bool isPassive;

  /// True when the rules for this character are not yet fully known.
  final bool isStub;

  const CharacterMeta({
    required this.displayName,
    required this.token,
    this.activeAbilityId,
    this.hasNormalMove = true,
    this.isPassive = false,
    this.isStub = false,
  });
}

const Map<CharacterType, CharacterMeta> kCharacterMeta = {
  CharacterType.leader: CharacterMeta(displayName: 'Leader', token: '★'),

  CharacterType.illusionniste: CharacterMeta(
    displayName: 'Illusionniste',
    token: 'Il',
    activeAbilityId: 'illusionniste',
    hasNormalMove: false,
  ),
  CharacterType.lanceGrappin: CharacterMeta(
    displayName: 'Lance-grappin',
    token: 'LG',
    activeAbilityId: 'lance_grappin',
    hasNormalMove: false,
  ),
  CharacterType.rodeuse: CharacterMeta(
    displayName: 'Rôdeuse',
    token: 'Rô',
    activeAbilityId: 'rodeuse',
    hasNormalMove: false,
  ),
  CharacterType.tavernier: CharacterMeta(
    displayName: 'Tavernier',
    token: 'Ta',
    activeAbilityId: 'tavernier',
  ),
  CharacterType.manipulatrice: CharacterMeta(
    displayName: 'Manipulatrice',
    token: 'Ma',
    activeAbilityId: 'manipulatrice',
  ),
  CharacterType.archere: CharacterMeta(
    displayName: 'Archère',
    token: 'Ar',
    isPassive: true,
  ),
  CharacterType.assassin: CharacterMeta(
    displayName: 'Assassin',
    token: 'As',
    isPassive: true,
  ),
  CharacterType.geolier: CharacterMeta(
    displayName: 'Geôlier',
    token: 'Ge',
    isPassive: true,
  ),
  CharacterType.protecteur: CharacterMeta(
    displayName: 'Protecteur',
    token: 'Pr',
    isPassive: true,
  ),
  CharacterType.cogneur: CharacterMeta(
    displayName: 'Cogneur',
    token: 'Co',
    activeAbilityId: 'cogneur',
  ),
  CharacterType.vizir: CharacterMeta(
    displayName: 'Vizir',
    token: 'Vi',
    isPassive: true,
  ),
  CharacterType.sauteur: CharacterMeta(
    displayName: 'Sauteur',
    token: 'Sa',
    activeAbilityId: 'sauteur',
  ),

  CharacterType.gardeRoyal: CharacterMeta(
    displayName: 'Garde Royal',
    token: 'GR',
    isPassive: true,
    isStub: true,
  ),

  CharacterType.recrueA:
      CharacterMeta(displayName: 'Recrue A', token: 'A', isStub: true),
  CharacterType.recrueB:
      CharacterMeta(displayName: 'Recrue B', token: 'B', isStub: true),
  CharacterType.recrueC:
      CharacterMeta(displayName: 'Recrue C', token: 'C', isStub: true),
  CharacterType.recrueD:
      CharacterMeta(displayName: 'Recrue D', token: 'D', isStub: true),
  CharacterType.recrueE:
      CharacterMeta(displayName: 'Recrue E', token: 'E', isStub: true),
};

extension CharacterTypeMeta on CharacterType {
  CharacterMeta get meta => kCharacterMeta[this]!;
  String get displayName => meta.displayName;
  String get token => meta.token;
  String? get activeAbilityId => meta.activeAbilityId;
  bool get hasNormalMove => meta.hasNormalMove;
  bool get isPassive => meta.isPassive;
  bool get isStub => meta.isStub;

  /// The 18 recruitable champions (everything except [CharacterType.leader]).
  static List<CharacterType> get champions =>
      CharacterType.values.where((c) => c != CharacterType.leader).toList();
}
