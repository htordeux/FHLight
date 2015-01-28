


	dk = {}
	dk.spells = {}
	
	-- local function
	local function toSpellName(id)
		local name = GetSpellInfo(id)
		return name
	end

	-- BUFFS
	
	dk.spells["FrostFever"] = toSpellName(55095) -- Fièvre de givre
	dk.spells["BloodPlague"] = toSpellName(55078) -- Peste de sang
	
	-- "Icebound Fortitude" 48792 "Robustesse glaciale" -- Icebound Fortitude immune to Stun effects and reduce all damage taken by 20% for 8 sec.
	dk.spells["Icebound"] = toSpellName(48792)
	-- "BloodPresence" 48263 "Présence de sang" --  increasing Stamina by 20%, base armor by 30%, and reducing damage taken by 10%. Threat generation is significantly increased.
	dk.spells["BloodPresence"] = 48263
	-- "FrostPresence" 48266 "Présence de givre" -- Strengthens you with the presence of Frost, increasing Runic Power generation by 20%
	dk.spells["FrostPresence"] = 48266
	-- "Horn of Winter" 57330 "Cor de l’hiver" -- increasing attack power of all party and raid members within 100 yards by 10% for 1 hour.
	dk.spells["HornOfWinter"] = 57330
	-- "BloodCharge" 114851 "Charge sanglante -- 
	dk.spells["BloodCharge"] = toSpellName(114851) -- Charge sanglante
	-- "Killing Machine" 51124 "Machine à tuer" -- Vos attaques automatiques ont une chance de vous garantir un coup critique avec votre prochaine technique Anéantissement ou Frappe de givre.
	dk.spells["KillingMachine"] = toSpellName(51124)
	-- "Freezing Fog" 59052 "Brouillard Givrant" -- Your next Icy Touch or Howling Blast will consume no runes.
	dk.spells["FreezingFog"] = toSpellName(59052)
	-- "Strangulate" 47476 "Strangulation" -- Shadowy tendrils constrict an enemy's throat, silencing them for 5 sec.
	dk.spells["Strangulate"] = 47476 
	-- "Death and Decay" 43265 "Mort et decomposition" -- Corrupts the ground targeted by the Death Knight, causing Shadow damage over 10 sec to targets within the area
	dk.spells["DeathAndDecay"] = 43265
	-- "Unwavering Might" 126582 "Puissance inebranlable" -- Strength increased by 522 for 20 sec.
	dk.spells["UnwaveringMight"] = toSpellName(126582)
	

	-- SPELLS

	-- "Outbreak" 77575 "Poussée de fièvre" -- 30 yd range -- Instantly applies Blood Plague and Frost Fever to the target enemy.
	dk.spells["OutBreak"] = 77575
	-- "Faucheur d'âme" 130735 "Faucheur d’âme"
	dk.spells["SoulReaper"] = 130735
	-- "Howling Blast" 49184 "Rafale hurlante" -- 1 frost -- Frost damage to all other enemies within 10 yards, infecting all targets with Frost Fever.
	dk.spells["HowlingBlast"] = 49184
	-- "Plague Strike" 45462 "Frappe de peste" -- 1 Unholy -- infects the target with Blood Plague.
	dk.spells["PlagueStrike"] = 45462
	-- "Frost Strike" 49143 "Frappe de givre" -- 25 Runic Power
	dk.spells["FrostStrike"] = 49143
	-- "Obliterate" 49020 "Anéantissement" -- 1 Unholy, 1 Frost -- 45% de chances de permettre à votre prochaine Rafale hurlante ou votre prochain Toucher de glace de ne pas consommer de runes.
	dk.spells["Obliterate"] = 49020
	-- "Death Strike" 49998 "Frappe de Mort" -- 1 Impie, 1 Givre -- Focalise la puissance des ténèbres afin d’asséner un coup qui inflige 114% points de dégâts physiques et vous rend 1 points de vie.
	dk.spells["DeathStrike"] = 49998
	-- "Mind Freeze" 47528 "Gel de l'esprit" -- interrupting spellcasting and preventing any spell in that school from being cast for 4 sec.
	dk.spells["MindFreeze"] = 47528
	-- "Blood Boil" 50842 "Furoncle sanglant" -- Shadow damage to all enemies within 10 yards, and spreads your existing diseases from your target to all other enemies hit
	dk.spells["BloodBoil"] = 50842 
	-- "Pillar of Frost" 51271 "Pilier de givre" -- The power of Frost increases the Death Knight's Strength by 15%, and grants immunity to external movement effects such as knockbacks.  Lasts 20 sec.
	dk.spells["PillarOfFrost"] = 51271
	-- "Raise Ally" 61999 "Réanimation d'un allié"
	dk.spells["RaiseAlly"] = 61999 
	-- "Dark Simulacrum" 77606 "Sombre simulacre"
	dk.spells["DarkSimulacrum"] = 77606
	-- "Empower Rune Weapon" 47568 "Renforcer l'arme runique" -- immediately activating all your runes and generating 25 Runic Power.
	dk.spells["EmpowerRuneWeapon"] = 47568
	-- "Army of the Dead" 42650 "Armée des morts"
	dk.spells["ArmyoftheDead"] = 42650
	-- "Anti-Magic Shell" 48707 "Carapace anti-magie" -- Anti-Magic Shell for 5 sec, absorbing 75% of all magical damage
	dk.spells["AntiMagicShell"] = 48707

	-- SPELLS TALENTS
	
	-- "Plague Leech" 123693 "Parasite de peste" -- Consumes your Blood Plague and Frost Fever on the target to activate up to two random fully-depleted runes as Death Runes.
	dk.spells["PlagueLeech"] = 123693 
	-- "Death's Advance" 96268 "Avancée de la mort" -- vous bénéficiez d'un bonus de 30% à la vitesse de déplacement et on ne peut vous ralentir à une vitesse inférieure à 100% de votre vitesse de déplacement normale pendant 6 secondes.
	dk.spells["DeathAdvance"] = 96268
	-- "Blood Tap" 45529 "Drain sanglant" -- Every 15 Runic Power you spend will generate a Blood Charge. Max 12 charges. Blood Tap consumes 5 Blood Charges to activate a random fully-depleted rune as a Death Rune.
	dk.spells["BloodTap"] = 45529
	-- "Death Pact" 48743 "Pacte mortel" -- Heals the Death Knight for 50% of max health, and absorbs incoming healing equal to 25% of max health for 15 sec.
	dk.spells["DeathPact"] = 48743
	-- "Remorseless Winter" 108200 "Hiver impitoyable" -- Surrounds the Death Knight with a swirling tempest targets' movement speed by 15% for 3 sec, stacking up to 5 times
	dk.spells["RemorselessWinter"] = 108200
	-- "Death Siphon" 108196 "Siphon mortel" -- Deals (60.2064% of Attack power) Shadowfrost damage to an enemy, healing the Death Knight for 335% of damage dealt.
	dk.spells["DeathSiphon"] = 108196
	-- "Asphyxiate" 108194 "Asphyxier" -- étourdit pendant 5 s. La cible est réduite au silence.
	dk.spells["Asphyxiate"] = 108194
	-- "Unholy Blight" 115989 "Chancre impie" -- Insectes impies pendant 10 s. Ils piquent tous les ennemis à moins de 10 mètres, leur inoculant Peste de sang et Fièvre de givre.
	dk.spells["UnholyBlight"] = 115989
	-- "Anti-Magic Zone" 51052 "Zone anti-magie"
	dk.spells["AntiMagicZone"] = 51052
	-- "Defile" 152280 "Profanation" -- Remplace "Death and Decay" 43265 "Mort et decomposition"
	dk.spells["Defile"] = 152280
	
	
	dk.darkSimSpells = {
	-- pvp
	"Hex","Mind Control","Cyclone","Polymorph","Pyroblast","Tranquility","Divine Hymn","Ring of Frost","Entangling Roots",
	"Maléfice","Contrôle mental","Cyclone","Métamorphose","Explosion pyrotechnique","Tranquillité","Hymne divin","Anneau de givre","Sarments"
	}
	
--------------------------------
-- RUNES -----------------------
--------------------------------
	-- start, duration, runeReady = GetRuneCooldown(id)
	
	local GetRuneReady = function(id)
		local _,_,ready = GetRuneCooldown(id)
		if ready == true then return 1 end
		return 0
	end


	function dk.updateRune()
		local dr1 = GetRuneReady(1) -- 1 Leftmost -- blood rune or death rune
		local dr2 = GetRuneReady(2) -- 2 Second from left -- blood rune or death rune
		local ur1 = GetRuneReady(3) -- 3 Fifth from left (second from right) -- unholy rune
		local ur2 = GetRuneReady(4) -- 4 Sixth from left (rightmost) -- unholy rune
		local fr1 = GetRuneReady(5) -- 5 Third from left -- frost rune
		local fr2 = GetRuneReady(6) -- 6 Fourth from left -- frost rune
		
		local Dr = dr1 + dr2
		local Fr = fr1 + fr2
		local Ur = ur1 + ur2

		return Dr, Fr, Ur
	end

	local RuneType = { ["Dr"] = 2 , ["Fr"] = 2 , ["Ur"] = 2 }
	function dk.updateRuneType()
		local dr1 = GetRuneReady(1) -- 1 Leftmost -- blood rune or death rune
		local dr2 = GetRuneReady(2) -- 2 Second from left -- blood rune or death rune
		local ur1 = GetRuneReady(3) -- 3 Fifth from left (second from right) -- unholy rune
		local ur2 = GetRuneReady(4) -- 4 Sixth from left (rightmost) -- unholy rune
		local fr1 = GetRuneReady(5) -- 5 Third from left -- frost rune
		local fr2 = GetRuneReady(6) -- 6 Fourth from left -- frost rune

		local Dr = 0
		local Fr = 0
		local Ur = 0

		RuneType["Dr"] = dr1 + dr2
		RuneType["Fr"] = fr1 + fr2
		RuneType["Ur"] = ur1 + ur2
	end
	
	function dk.rune(name)
		return RuneType[name]
	end

--------------------------------
-- FUNCTIONS
--------------------------------

	function dk.shoulDarkSimUnit(unit)
		local darkSimSpell = false
		for index,spellName in pairs(dk.darkSimSpells) do
			if jps.IsCastingSpell(spellName, unit) then 
				darkSimSpell = true
			elseif jps.IsChannelingSpell(spellName, unit) then 
				darkSimSpell = true
			break end
		end
		return darkSimSpell
	end
	
	function dk.shouldDarkSimTarget()
		return dk.shoulDarkSimUnit("target")
	end
	
	function dk.shouldDarkSimFocus()
		return dk.shoulDarkSimUnit("focus")
	end

	function dk.canCastPlagueLeech(timeLeft)
		if jps.cooldown(dk.spells["OutBreak"]) > 0 then return false end
		if not jps.myDebuff(dk.spells["FrostFever"]) then return false end
		if not jps.myDebuff(dk.spells["BloodPlague"]) then return false end
		if jps.myDebuffDuration(dk.spells["FrostFever"]) <= timeLeft then
			return true
		end
		if jps.myDebuffDuration(dk.spells["BloodPlague"]) <= timeLeft then
			return true
		end
		return false
	end

	function dk.hasGhoul()
		if jps.Spec == "Unholy" then
			if UnitExists("pet") == nil then return false end
		else
			if select(1,GetTotemInfo(1)) == false then return false end
		end
		return true
	end

	function dk.totalAttackPower()
		local base, pos, neg = UnitAttackPower("player")
		return base + pos + neg
	end

	function dk.shouldRefreshDot(dotName, unit)
		if not unit then unit = "target" end
		local ap = dk.totalAttackPower()
		local crit = GetCritChance()
		local dmgBuff = dk.getDamageBuff()
		local mastery = GetMastery()
		local dotID = nil
		if type(dotName) == "number" then
			dotID = dotName
		else
			dotID = dk.spells[dotName]
		end
		local shouldRefresh = false
		if dk.currentDotStats[dotID] then
			if ap > dk.currentDotStats[dotID].ap then  shouldRefresh = true end
			if crit > dk.currentDotStats[dotID].crit then  shouldRefresh = true end
			if dmgBuff > dk.currentDotStats[dotID].dmgBuff then  shouldRefresh = true end
			if mastery > dk.currentDotStats[dotID].mastery then
				if jps.Spec == "Unholy" and dotID == 55095 then  shouldRefresh = true end
				if jps.Spec == "Frost" and dotID == 55078 then  shouldRefresh = true end
			end
		end
		if shouldRefresh == true then
			dk.currentDotStats[dotID].isStrong = true
		end
		return shouldRefresh
	end

	function dk.shouldExtendDot(dotName, unit)
		if not unit then unit = "target" end
		if not jps.buff(dotName, unit) then return false end -- we can't extend dots which are not available
		if type(dotName) == "number" then
			local spellId = dotName
		else
			local spellId = dk.spells[dotName] or nil
		end
		if not dk.shouldRefreshDot(spellID, unit) and dk.currentDotStats[spellID].isStrong then return true end -- extend current "strong" dot's
		return false
	end

	dk.dmgIncreaseBuffs = {
		{138002, 0.4}, --+40% jin rokh fluidity
		{140741, 1,0.1, "HARMFUL"},-- +100% +10% per stack - ji kun nitrument
		{57934, 0.15}, -- +15% - tricks
		{118977, 0.6},-- +60% - fearless
	}
	
	function dk.getDamageBuff()
		-- credits to kirk' dotTracker
    	local damageBuff = 1
		for i, buff in ipairs(dk.dmgIncreaseBuffs) do
			local filter = buff[4] or nil
	        hasBuff,_,_,stacks = UnitAura("player", buff[1], nil, filter)
	        if hasBuff then
	            damageBuff = damageBuff + buff[2] + (buff[2] * stacks)
	        end
	    end
	    return damageBuff
	end

	dk.currentDotStats = {}
	function dk.logDotDmg(...)
		local eventtype = select(2, ...)
		local srcName = select(5 , ...)
		local dotDmg = select(15, ...)
		local spellID = select(12, ...)
		local spellName = select(13, ...)

		if not eventtype then return end
		if spellID ~= dk.spells["FrostFever"] and spellID ~= dk.spells["BloodPlague"] then return end
		if eventtype == "SPELL_AURA_APPLIED" or eventtype == "SPELL_AURA_REFRESH" then
			if not dk.currentDotStats[spellID] then dk.currentDotStats[spellID] = {} end
			dk.currentDotStats[spellID].ap = dk.totalAttackPower()
			dk.currentDotStats[spellID].mastery = GetMastery()
			dk.currentDotStats[spellID].crit = GetCritChance() -- since 5.2 also in the dot snapshot
			dk.currentDotStats[spellID].dmgBuff = dk.getDamageBuff()
			dk.currentDotStats[spellID].isStrong = false

		end
		if eventtype == "SPELL_AURA_REMOVED" then
			if dk.currentDotStats[spellID] then
				dk.currentDotStats[spellID].ap = 0
				dk.currentDotStats[spellID].mastery = 0
				dk.currentDotStats[spellID].crit = 0
				dk.currentDotStats[spellID].dmgBuff = 0
				dk.currentDotStats[spellID].isStrong = false
			end
		end
	end
	jps.listener.registerEvent("COMBAT_LOG_EVENT_UNFILTERED", dk.logDotDmg)