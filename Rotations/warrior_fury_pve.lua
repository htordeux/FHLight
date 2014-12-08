
--This Rotation requires Glyph of Unending Rage. Shouldn't be used at lower levels

jps.registerStaticTable("WARRIOR","FURY",
	{
-- Interrupts
		-- "Pummel" 6552 "Volée de coups"
		{ 6552, 'jps.ShouldKick()' , warrior.rangedTarget , "Pummel" },
		{warrior.spells["Pummel"],'jps.ShouldKick()'},
		{warrior.spells["Pummel"],'jps.ShouldKick("focus")', "focus"},
		{warrior.spells["DisruptingShout"],'jps.ShouldKick()'},
		{warrior.spells["DisruptingShout"],'jps.ShouldKick("focus")', "focus"},
		
-- Cooldowns and Utility
		{warrior.spells["ImpendingVictory"],'jps.buff("Victorious") and jps.rage() >= 10 and jps.hp("player") < 0.8', warrior.rangedTarget },
		-- "Victory Rush" 34428 "Ivresse de la victoire" -- buff "Victorious" 32216 "Victorieux"
		{warrior.spells["VictoryRush"],'jps.buff(32216) and jps.rage() >= 10 and jps.hp("player") < 0.8', warrior.rangedTarget },
		{warrior.spells["Recklessness"],'jps.UseCDs and jps.debuffDuration( 86346) >= 5', warrior.rangedTarget },
		{warrior.spells["Recklessness"],'jps.UseCDs and jps.cooldown( 86346) == 0', warrior.rangedTarget },
		{warrior.spells["SkullBanner"],'jps.UseCDs and jps.debuffDuration( 86346) >= 5', warrior.rangedTarget }, 
		{warrior.spells["SkullBanner"],'jps.UseCDs and jps.cooldown( 86346) == 0', warrior.rangedTarget }, 
		
		{warrior.spells["BerserkerRage"],'jps.debuffDuration( 86346) > 0 and not jps.buff("Berserker Rage","player")', warrior.rangedTarget },
		{warrior.spells["Bloodbath"],'jps.UseCDs'},
		
		{ jps.getDPSRacial(),'jps.UseCDs and jps.debuffDuration( 86346) >= 5'},
		{ jps.useTrinket(0),'jps.useTrinket(0) ~= "" and jps.UseCDs and jps.debuffDuration( 86346) >= 5'},
		{ jps.useTrinket(1),'jps.useTrinket(1) ~= "" and jps.UseCDs and jps.debuffDuration( 86346) >= 5'},
		{ jps.useSynapseSprings() ,'jps.useSynapseSprings() ~= "" and jps.UseCDs and jps.debuffDuration( 86346) >= 5'},
		-- Requires herbalism
		{warrior.spells["Lifeblood"],'jps.UseCDs and jps.debuffDuration( 86346) >= 5'},
		
		-- AoE Rotation
		-- "Raging Blow" 85288 "Coup déchaîné" -- buff Raging Blow! 131116
		
		{warrior.spells["Whirlwind"],'jps.MultiTarget and jps.buffStacks(12950) < 3 and jps.rage() >= 30', warrior.rangedTarget },
		{warrior.spells["ColossusSmash"],'jps.MultiTarget', warrior.rangedTarget },
		{warrior.spells["Bloodthirst"],'jps.MultiTarget', warrior.rangedTarget },
		{warrior.spells["Cleave"],'jps.MultiTarget and jps.cooldown( 86346) >= 3 and jps.rage() > 105', warrior.rangedTarget },
		{warrior.spells["RagingBlow"],'jps.MultiTarget and jps.buff("131116") and jps.buffStacks ("131116") == 2 and jps.cooldown( 86346) >= 3 and jps.buffStacks(12950) == 3', warrior.rangedTarget },
		{warrior.spells["RagingBlow"],'jps.MultiTarget and jps.buff("131116") and jps.buffStacks ("131116") == 1 and jps.cooldown( 86346) >= 3 and jps.buffStacks(12950) == 3', warrior.rangedTarget },
		{warrior.spells["Bladestorm"],'jps.MultiTarget and IsShiftKeyDown() ~= nil'},
		
		-- Colossus Smash Rotation
		
		{warrior.spells["Bloodthirst"],'jps.myDebuff( 86346,"target")', warrior.rangedTarget },
		{warrior.spells["Execute"],'jps.rage() >= 30 and jps.hp("target") < 0.2 and jps.myDebuff( 86346,"target")', warrior.rangedTarget}, 
		{warrior.spells["Raging Blow"],'jps.buff("131116") and jps.rage() >= 10 and jps.myDebuff( 86346,"target")', warrior.rangedTarget },
		{warrior.spells["WildStrike"],'jps.buff("Bloodsurge") and jps.myDebuff( 86346,"target")', warrior.rangedTarget },
		{warrior.spells["HeroicStrike"],'jps.hp("target") > 0.2 and jps.rage() >= 30 and jps.myDebuff( 86346,"target")', warrior.rangedTarget },
		
		-- Normal Rotation
		
		{warrior.spells["ColossusSmash"],'jps.rage() >= 100', warrior.rangedTarget },
		{warrior.spells["Bloodthirst"],'onCD', warrior.rangedTarget},
		{warrior.spells["HeroicStrike"],'jps.cooldown( 86346) >= 3 and jps.rage() > 105', warrior.rangedTarget },
		{warrior.spells["RagingBlow"],'jps.rage() >= 10 and jps.buff("131116") and jps.buffStacks ("131116") == 2 and jps.cooldown( 86346) >= 3', warrior.rangedTarget },
		{warrior.spells["WildStrike"],'jps.buff("Bloodsurge")', warrior.rangedTarget },
		{warrior.spells["DragonRoar"],'(CheckInteractDistance(warrior.rangedTarget(), 3) == 1)', warrior.rangedTarget },
		{warrior.spells["RagingBlow"],'jps.buff("131116") and jps.buffStacks ("131116") == 1 and jps.cooldown( 86346) >= 3 and jps.rage() >= 10', warrior.rangedTarget },
		{warrior.spells["BattleShout"],'jps.rage() <= 20 and jps.cooldown( 86346) < 3 ', "player" },
		{warrior.spells["BattleShout"],'jps.rage() <= 20 and jps.debuffDuration( 86346) < 6' , "player"},
		{warrior.spells["WildStrike"],'jps.rage() > 106 and jps.cooldown( 86346) >= 3', warrior.rangedTarget },
	}
,"Default PvE" , true, false)