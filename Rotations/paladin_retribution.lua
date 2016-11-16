
local spells = jps.spells.paladin
local canDPS = jps.canDPS
local canHeal = jps.canHeal
local canAttack = jps.canAttack
local strfind = string.find
local UnitClass = UnitClass
local UnitAffectingCombat = UnitAffectingCombat
local GetSpellInfo = GetSpellInfo
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
if jps.hp("player") < 0.25 then CreateMessage("LOW HEALTH!")
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
-- Tier 6: Divine Steed (whatever talent really, but c'mon Divine Steed is awesome!)
-- Tier 7: Divine Purpose, Crusade

if not UnitCanAttack("player", "target") then return end

local spellTable = {

	-- interrupts
	-- "Réprimandes" 96231
	{ spells.rebuke, jps.IsCasting(rangedTarget) },
	-- "Marteau de la justice" 853
	{ spells.hammerOfJustice, jps.ShouldKick(rangedTarget) },
	{ spells.hammerOfJustice, jps.IsCasting(rangedTarget) },

    -- "Vengeance du justicier" 215661 -- jps.hasTalent(5,1) -- is only recommended for solo content
	-- Eye for an Eye 205191 is the best choice for raiding
	-- Word of Glory 210191 is best for dungeons
	{ spells.justicarsVengeance, jps.buff(spells.divinePurpose) },
    -- "Imposition des mains" 633 -- cd 10 min
    { spells.layOnHands, jps.hp() < 0.20 , "player" },
    -- "Bouclier divin" 642 -- cd 5 min
    { spells.divineShield, jps.hp() < 0.40 , "player" },
	-- "Eclair lumineux" 19750
    { spells.flashOfLight, jps.hp() < 0.60 and jps.castEverySeconds(19750, 4) , "player" },
    { spells.flashOfLight, jps.hp() < 0.60 and not jps.myDebuff(spells.judgment) and jps.cooldown(spells.judgment) > 0 , "player" },

	-- "Courroux vengeur" 31884
	{ spells.avengingWrath, jps.myDebuffDuration(spells.judgment) > 6 },
	-- "Bouclier du vengeur" 184662 -- 15 second damage absorption shield
	{ shieldOfVengeance },
    -- "Traînée de cendres" 205273
    { spells.wakeOfAshes },
	
	
	-- ROTATION
	-- "Tempête divine" 53385
    { spells.divineStorm, jps.MultiTarget and jps.myDebuff(spells.judgment) },
    -- "Lumière aveuglante" 115750 -- jps.hasTalent(3,3)
    { spells.divineStorm, jps.MultiTarget },
	-- "Lame de justice" 184575 --Génère 2 charge de puissance sacrée.
	{ spells.bladeOfJustice  },
	-- "Frappe du croisé" 35395 -- Génère 1 charge de puissance sacrée
    { spells.crusaderStrike  },
	-- "Jugement" 20271 -- 8 sec
    { spells.judgment  },
    -- "Verdict du templier" 85256
    { spells.templarsVerdict, jps.myDebuff(spells.judgment) },



	-- "Condamnation à mort" 213757 -- jps.hasTalent(1,2)
	{spells.executionSentence, jps.holyPower() > 4 and jps.myDebuff(spells.judgment) },


}

	spell,target = parseSpellTable(spellTable)
	return spell,target
end, "Paladin Retribution")

-- Charge > Bloodthirst > Raging Blow > Furious Slash > Blood thirst > Dragon Roar > Avatar+Battlecry > Rampage

-- Rage Management --
-- Bloodthirst generating 10
-- Raging Blow generating 5
-- Rampage to activate Enrage
-- Execute on targets under 20% for extremely high damage.