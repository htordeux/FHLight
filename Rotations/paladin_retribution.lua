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

local playerAggro = jps.FriendAggro("player")
local playerIsStun = jps.StunEvents(2) -- return true/false ONLY FOR PLAYER -- "ROOT" was removed of Stuntype
-- {"STUN_MECHANIC","STUN","FEAR","CHARM","CONFUSE","PACIFY","SILENCE","PACIFYSILENCE"}
local playerIsInterrupt = jps.InterruptEvents() -- return true/false ONLY FOR PLAYER
local playerWasControl = jps.ControlEvents() -- return true/false Player was interrupt or stun 2 sec ago ONLY FOR PLAYER
local Tank,TankUnit = jps.findTankInRaid() -- default "focus"
local TankTarget = "target"
if UnitCanAssist("player",Tank) then TankTarget = Tank.."target" end
local TankThreat = jps.findThreatInRaid()
local playerIsTanking = false
if UnitIsUnit("player",TankThreat) then playerIsTanking = true end

local inMelee = jps.IsSpellInRange(spells.bloodthirst,"target")
local inRanged = jps.IsSpellInRange(57755,"target") -- "Heroic Throw" 57755 "Lancer héroïque"

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
elseif canDPS(TankTarget) then rangedTarget = TankTarget
elseif canDPS("targettarget") then rangedTarget = "targettarget"
elseif canAttack("mouseover") then rangedTarget = "mouseover"
end
if canDPS(rangedTarget) then jps.Macro("/target "..rangedTarget) end
local TargetMoving = select(1,GetUnitSpeed(rangedTarget)) > 0

local PlayerBossDebuff = jps.BossDebuff("player")
if jps.hp("player") < 0.20 then CreateMessage("LOW HEALTH!")
elseif PlayerBossDebuff then CreateMessage("BOSS DEBUFF!") end

local damageIncoming = jps.IncomingDamage() - jps.IncomingHeal()
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

	{ 59752, playerIsStun , "player" , "playerCC" },
    -- "Bouclier divin" 642 -- cd 5 min
    { spells.divineShield, jps.hp() < 0.40 , "player" },
    -- "Imposition des mains" 633 -- cd 10 min
    { spells.layOnHands, jps.hp() < 0.20 , "player" }, 

    -- interrupts
	-- "Réprimandes" 96231
	{ spells.rebuke, jps.ShouldKick(rangedTarget) },
	-- "Marteau de la justice" 853
	{ spells.hammerOfJustice, jps.IsCasting(rangedTarget) },
	-- "Lumière aveuglante" 115750 -- jps.hasTalent(3,3)
    { spells.blindingLight, jps.IsCasting(rangedTarget) },

    { spells.flashOfLight, jps.hp() < 0.40 and jps.buff(642), "player" },
    { spells.flashOfLight, jps.hp() < 0.40 and jps.buff(1022), "player" },

   	-- "Bénédiction de protection" 1022
    { spells.blessingOfProtection, jps.hp() < 0.40  , "player" },
    { spells.blessingOfProtection, jps.hp("mouseover") < 0.40 and canHeal("mouseover") , "mouseover" },

   
    -- "Bouclier du vengeur" 184662 -- 15 second damage absorption shield -- gives buff 184662
	{ shieldOfVengeance,  damageIncoming > 0 },
    -- "Vengeance du justicier" 215661 "Justicar's Vengeance" -- jps.hasTalent(5,1) -- is only recommended for solo content -- 5 holypower
    -- "Vengeance du justicier" Deals 100% additional damage and healing when used against a stunned target.
    -- "Dessein divin" 223819 "Divine Purpose" buff -- Votre prochaine technique utilisant de la puissance sacrée est gratuite. 12 secondes
    { spells.justicarsVengeance, jps.hasTalent(7,1) and jps.buff(223819) },
  
    -- "Eye for an Eye" 205191 "Oeil pour oeil" is the best choice for raiding
    -- "Oeil pour oeil" Réduit de 35% les dégâts physiques subis et contre-attaque instantanément les ennemis qui vous frappent en mêlée, ce qui leur inflige 170% points de dégâts physiques. Dure 10 sec
    -- "Word of Glory" 210191 "Mot de gloire" is best for dungeons
    -- "Mot de gloire" Vous rendez (900% of Spell power) points de vie à un maximum de 5 cibles alliées à moins de 15 mètres ainsi qu’à vous-même. 2 charges au maximum.

    -- "Purification des toxines" 213644
    { spells.cleanseToxins, jps.canDispel("player","Poison") , "player" },
    { spells.cleanseToxins, jps.canDispel("player","Disease") , "player" },

    -- "Eclair lumineux" 19750
    { spells.flashOfLight, jps.hp() < 0.60 and jps.castEverySeconds(19750, 4) , "player" },
    { spells.flashOfLight, jps.hp() < 0.60 and not jps.myDebuff(spells.judgment) and jps.cooldown(spells.judgment) > 0 , "player" },

	-- "Jugement" 20271 -- duration 8 sec
    { spells.judgment, jps.holyPower() > 2 }, 
    -- "Courroux vengeur" 31884
	{ spells.avengingWrath, jps.cooldown(spells.judgment) == 0 and jps.holyPower() > 2 },
    -- "Traînée de cendres" 205273
    { spells.wakeOfAshes  },
    -- ROTATION
    { "nested", jps.MultiTarget ,{
    	-- "Tempête divine" 53385 -- 3 holypower
    	{ spells.divineStorm, jps.myDebuff(spells.judgment) , rangedTarget , "divineStorm_MultiTarget" },
    	-- "Lumière aveuglante" 115750 -- jps.hasTalent(3,3)
    	{ spells.blindingLight, true , rangedTarget , "blindingLight_MultiTarget" },
    }},

	{ spells.bladeOfJustice, jps.holyPower() < 3  },
    { spells.crusaderStrike, jps.spellCharges(35395) == 2 and jps.holyPower() < 5 },
    { spells.crusaderStrike, jps.holyPower() < 3  },
    -- "Condamnation à mort" 213757
	{ spells.executionSentence, jps.hasTalent(1,2) and jps.holyPower() == 5 and jps.myDebuff(spells.judgment) },
    -- "Verdict du templier" 85256
    { spells.templarsVerdict, jps.myDebuff(spells.judgment) },
    { spells.templarsVerdict, jps.holyPower() == 5 },

	-- "Jugement" 20271 -- duration 8 sec
    { spells.judgment  },
	-- "Lame de justice" 184575 -- Génère 2 charge de puissance sacrée.
	{ spells.bladeOfJustice  },
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