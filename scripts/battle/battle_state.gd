class_name BattleState

enum Phase { INTRO, PLAYER_TURN, FIGHT, ACT, ITEM, MERCY, ENEMY_TURN, WIN, LOSE, SPARED }

const VALID_TRANSITIONS := {
	Phase.INTRO: [Phase.PLAYER_TURN],
	Phase.PLAYER_TURN: [Phase.FIGHT, Phase.ACT, Phase.ITEM, Phase.MERCY, Phase.ENEMY_TURN],
	Phase.FIGHT: [Phase.ENEMY_TURN, Phase.WIN],
	Phase.ACT: [Phase.ENEMY_TURN],
	Phase.ITEM: [Phase.ENEMY_TURN],
	Phase.MERCY: [Phase.SPARED, Phase.ENEMY_TURN],
	Phase.ENEMY_TURN: [Phase.PLAYER_TURN, Phase.LOSE, Phase.WIN],
	Phase.WIN: [],
	Phase.LOSE: [],
	Phase.SPARED: [],
}

var phase: Phase = Phase.INTRO

func transition(new_phase: Phase) -> bool:
	if new_phase in VALID_TRANSITIONS[phase]:
		phase = new_phase
		return true
	return false
