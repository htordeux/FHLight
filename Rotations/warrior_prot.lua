
jps.registerRotation("WARRIOR","PROTECTION",function()

	local spellTable =
	{
		{ warrior.spells["BattleShout"] ,	jps.hasAttackPowerBuff("player") , "player" },
		
		-- Defensive
		{ warrior.spells["BerserkerRage"] ,		not jps.buff("Berserker Rage","player") , "player" },
		{ "Shield Wall" ,			jps.hp() < 0.30 and jps.UseCDs, "player" },
		{ "Last Stand" ,			jps.hp() < 0.40 and jps.UseCDs, "player" },
		{ "Impending Victory" ,		jps.hp() < 0.70 and jps.UseCDs, "player" },
		{ "Shield Block" ,			jps.hp() < 0.80 , "player" },
		{ "Shield Barrier" ,		jps.hp() < 0.80 , "player" },
		{ "Enraged Regeneration" ,	(jps.buff("Berserker Rage","player") or jps.buff("enraged","player")) and jps.hp() < 0.80 , "player" },

		-- Interrupts
		{ "Pummel" ,			jps.ShouldKick("target") , "target" },
		{ "Pummel" ,			jps.ShouldKick("focus") , "focus" },
		{ "Spell Reflection" ,	UnitThreatSituation("player","target") == 3 and (UnitCastingInfo("target") or UnitChannelInfo("target")) , "target" },
		{ "Shield Slam" ,		jps.buff("Sword and Board") , "target" },

		-- Multitarget
		{ "Thunder Clap" ,		jps.MultiTarget , "target" },
		{ "Recklessness" ,		jps.UseCDs , "player" },
		{ "Heroic Strike" ,		jps.rage() > 70  and jps.buff("player", "Ultimatum") and jps.MultiTarget , "target" },

		-- Singletarget
		{ "Shield Slam" ,		},
		{ "Revenge" ,			},
		{ "Heroic Strike" ,		jps.buff("player", "Ultimatum") and not jps.MultiTarget , "target" },
		{ "Devastate" ,			jps.debuffStacks("Sunder Armor") < 3 , "target" },
		{ "Thunder Clap" ,		jps.IsSpellInRange("Thunder Clap","target") == true and not jps.debuff("Weakend Blows", "target") },
		{ "Heroic Throw" ,		},
		{ "Battle Shout",		jps.rage() < 100, "player" },
		{ "Heroic Strike" ,		jps.rage()>90  and not jps.MultiTarget, "target" },
		{ "Impending Victory" ,	jps.hp() < 0.85 , "target" },
		{ "Devastate" ,			}
	}

	local spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Default")