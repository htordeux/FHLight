local spells = jps.spells.paladin
local canDPS = jps.canDPS
local canHeal = jps.canHeal
local canAttack = jps.canAttack
local strfind = string.find
local UnitClass = UnitClass
local UnitChannelInfo = UnitChannelInfo
local GetSpellInfo = GetSpellInfo
local UnitAffectingCombat = UnitAffectingCombat
local UnitIsUnit = UnitIsUnit

----------------------------------------------------------------------------------------------------------------
-------------------------------------------------- ROTATION ----------------------------------------------------
----------------------------------------------------------------------------------------------------------------

jps.registerRotation("PALADIN","RETRIBUTION",function()

local spell = nil
local target = nil

local CountInRange, AvgHealthLoss, FriendUnit = jps.CountInRaidStatus(0.80)
local LowestUnit = jps.LowestImportantUnit()

local Tank,TankUnit = jps.findRaidTank() -- default "player"
local TankTarget = Tank.."target"
local playerIsTanking = false
if UnitIsUnit("player",Tank) then playerIsTanking = true end

local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
local ispvp = UnitIsPVP("player")

----------------------
-- TARGET ENEMY
----------------------

-- rangedTarget returns "target" by default, sometimes could be friend
local rangedTarget, EnemyUnit, TargetCount = jps.LowestTarget()

-- Config FOCUS with MOUSEOVER
if not jps.UnitExists("focus") and canAttack("mouseover") then
	-- set focus an enemy targeting you
    if UnitIsUnit("mouseovertarget","player") and not UnitIsUnit("target","mouseover") then
        jps.Macro("/focus mouseover") --print("Enemy DAMAGER|cff1eff00 "..name.." |cffffffffset as FOCUS")
    -- set focus an enemy in combat
    elseif canAttack("mouseover") and not UnitIsUnit("target","mouseover") then
        jps.Macro("/focus mouseover") --print("Enemy COMBAT|cff1eff00 "..name.." |cffffffffset as FOCUS")
    end
end

if jps.UnitExists("focus") and UnitIsUnit("target","focus") then
    jps.Macro("/clearfocus")
elseif jps.UnitExists("focus") and not canDPS("focus") then
    jps.Macro("/clearfocus")
end

if canDPS("target") then rangedTarget =  "target"
elseif canAttack(TankTarget) then rangedTarget = TankTarget
elseif canAttack("targettarget") then rangedTarget = "targettarget"
elseif canAttack("mouseover") then rangedTarget = "mouseover"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end

local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0

local playerIsTargeted = jps.playerIsTargeted()

------------------------
-- SPELL TABLE ---------
------------------------

-- Talents:
-- Tier 1: Execution Sentence, Final Verdict
-- Tier 2: The Fires of Justice, Zeal
-- Tier 3: Blinding Light
-- Tier 4: Blade of Wrath
-- Tier 5: Justicar's Vengeance, Word of Glory (in more healing needed)
-- Tier 6: Divine Steed (whatever talent really, but Divine Steed is awesome!)
-- Tier 7: Divine Purpose, Crusade

if not UnitCanAttack("player", "target") then return end

local spellTable = {

	-- "Chacun pour soi" 59752
	{ 59752, playerIsStun , "player" , "playerCC" },

    { spells.flashOfLight, jps.hp() < 0.40 and jps.buff(642), "player" }, -- "Bouclier divin" 642
    { spells.flashOfLight, jps.hp() < 0.40 and jps.buff(1022), "player" }, -- "Bénédiction de protection" 1022
    -- "Bouclier divin" 642 -- cd 5 min
    { spells.divineShield, jps.hp() < 0.40 , "player" },
   	-- "Bénédiction de protection" 1022
    { spells.blessingOfProtection, jps.hp() < 0.40 and not jps.buff(642) , "player" },
    { spells.blessingOfProtection, jps.hp("mouseover") < 0.40 and canHeal("mouseover") , "mouseover" },
     -- "Imposition des mains" 633 -- cd 10 min
    { spells.layOnHands, jps.hp() < 0.20 , "player" },	


    -- interrupts
	-- "Réprimandes" 96231
	{ spells.rebuke, jps.Interrupts and jps.ShouldKick(rangedTarget) , rangedTarget },
	-- "Marteau de la justice" 853
	{ spells.hammerOfJustice, jps.Interrupts and jps.IsCasting(rangedTarget) , rangedTarget },
	-- "Lumière aveuglante" 115750 -- 
    { spells.blindingLight, jps.Interrupts and jps.hasTalent(3,3) and jps.IsCasting(rangedTarget) , rangedTarget },
    -- "Repentir" 20066 -- Force la cible ennemie à plonger dans une transe méditative qui la stupéfie et lui inflige des dégâts d’un montant maximum de 25% de ses points de vie en 1 min
	{ spells.repentance, jps.Interrupts and jps.hasTalent(3,2) and jps.IsCasting(rangedTarget) , rangedTarget },

    -- "Bouclier du vengeur" 184662 -- 15 second damage absorption shield -- gives buff 184662
	{ spells.shieldOfVengeance,  jps.IncomingDamage("player") > jps.IncomingHeal("player") and jps.hp() < 0.80 , rangedTarget, "shieldOfVengeance" },
	{ spells.shieldOfVengeance,  jps.MultiTarget  },
    -- "Vengeance du justicier" 215661 "Justicar's Vengeance" -- jps.hasTalent(5,1) -- is only recommended for solo content -- 5 holypower
    -- "Vengeance du justicier" Deals 100% additional damage and healing when used against a stunned target.
    -- "Dessein divin" 223819 "Divine Purpose" buff -- Votre prochaine technique utilisant de la puissance sacrée est gratuite. 12 secondes
    { spells.justicarsVengeance, jps.hasTalent(7,1) and jps.buff(223819) , rangedTarget, "justicarsVengeance" },
    { spells.justicarsVengeance, jps.hasTalent(7,1) and jps.holyPower() == 5 and jps.hp() < 0.60 }, -- 5 holypower
    -- "Condamnation à mort" 213757 -- 3 holypower
	{ spells.executionSentence, jps.hasTalent(1,2) and jps.holyPower() == 5 and jps.myDebuff(spells.judgment) },
  
    -- "Eye for an Eye" 205191 "Oeil pour oeil" is the best choice for raiding
    -- "Oeil pour oeil" Réduit de 35% les dégâts physiques subis et contre-attaque instantanément les ennemis qui vous frappent en mêlée, ce qui leur inflige 170% points de dégâts physiques. Dure 10 sec
    -- "Word of Glory" 210191 "Mot de gloire" is best for dungeons
    -- "Mot de gloire" Vous rendez (900% of Spell power) points de vie à un maximum de 5 cibles alliées à moins de 15 mètres ainsi qu’à vous-même. 2 charges au maximum.

    -- "Purification des toxines" 213644
    { spells.cleanseToxins, jps.canDispel("player","Poison") , "player" },
    { spells.cleanseToxins, jps.canDispel("player","Disease") , "player" },

    -- "Eclair lumineux" 19750
    { spells.flashOfLight, jps.hp() < 0.60 and jps.castEverySeconds(19750, 4) , "player" , "flashOfLight_Timer" },
    { spells.flashOfLight, jps.hp() < 0.60 and not jps.myDebuff(spells.judgment) , "player" , "flashOfLight_Debuff" },

	-- "Jugement" 20271 -- duration 8 sec
    { spells.judgment, jps.holyPower() > 2 },
    -- "Crusade" 231895
	--{ spells.crusade, jps.holyPower() > 2 and jps.myDebuff(spells.judgment) and jps.myDebuffDuration(spells.judgment) > 4 , rangedTarget , "crusade" },
    -- "Courroux vengeur" 31884
	{ spells.avengingWrath, jps.holyPower() > 2 and jps.myDebuff(spells.judgment) and jps.myDebuffDuration(spells.judgment) > 4 , rangedTarget , "avengingWrath" },
    -- "Traînée de cendres" 205273
    { spells.wakeOfAshes  },
    -- ROTATION
    { "nested", jps.MultiTarget ,{
    	-- "Tempête divine" 53385 -- 3 holypower
    	{ spells.divineStorm, jps.myDebuff(spells.judgment) , rangedTarget , "divineStorm_MultiTarget" },
    	-- "Lumière aveuglante" 115750 -- jps.hasTalent(3,3)
    	{ spells.blindingLight, jps.hasTalent(3,3) , rangedTarget , "blindingLight_MultiTarget" },
    }},

    -- "Verdict du templier" 85256 -- 3 holypower
    { spells.templarsVerdict, jps.myDebuff(spells.judgment) , rangedTarget , "templarsVerdict_judgment" },
    { spells.templarsVerdict, jps.holyPower() == 5 , rangedTarget , "templarsVerdict_Power" },
	-- "Lame de justice" 184575 -- Génère 2 charge de puissance sacrée.
	{ spells.bladeOfJustice, jps.holyPower() < 4  },
    -- "Zèle" 217020 -- Remplace Frappe du croisé -- Génère 1 charge de puissance sacrée
    { spells.zeal, jps.holyPower() < 4 , rangedTarget , "zeal" },
	-- "Frappe du croisé" 35395 -- Génère 1 charge de puissance sacrée
    { spells.crusaderStrike, jps.holyPower() < 5  },

	-- "Jugement" 20271 -- duration 8 sec
    { spells.judgment  },
	-- "Lame de justice" 184575 -- Génère 2 charge de puissance sacrée.
	{ spells.bladeOfJustice  },
	{ spells.zeal , true, rangedTarget , "zeal" },
	-- "Frappe du croisé" 35395 -- Génère 1 charge de puissance sacrée
    { spells.crusaderStrike  },


}

    spell,target = parseSpellTable(spellTable)
    return spell,target
end, "Paladin Retribution")


-- "Flammes de justice" 209785 "The Fires of Justice" buff
-- "Flammes de justice" Le coût de votre prochaine technique de soins ou de dégâts utilisant de la puissance sacrée est réduit de 1 point. 15 secondes
-- "Divine Purpose" should only be taken for solo content or world questing.
-- "Crusade" For raiding and Mythic+ dungeons is the best choice.


jps.registerRotation("PALADIN","RETRIBUTION",function()

	local spell = nil
	local target = nil

local spellTable = {

    -- "Eclair lumineux" 19750
    { spells.flashOfLight, jps.hp() < 0.60 , "player" },
    -- "Purification des toxines" 213644
    { spells.cleanseToxins, jps.canDispel("player","Poison") , "player" },
    -- Buff
    { 203528, not jps.buff(203528) , "player" },
    { 203538, not jps.buff(203538) , "player" },
    { 203539, not jps.buff(203539) , "player" },


}

	local spell,target = parseSpellTable(spellTable)
	return spell,target

end,"OOC Paladin retribution",false,true)