-----------------------
-- TIME TO DIE
-----------------------

-- timetodie
local timeToDieAlgorithm = "LeastSquared"  --  WeightedLeastSquares , LeastSquared , InitialMidpoints
local maxTDDLifetime = 30 -- resetting time to die if there was no hp change withing 30 seconds
jps.TimeToDieData = {}
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitGUID = UnitGUID

updateTimeToDie = function(elapsed, unit) -- jps.registerOnUpdate(updateTimeToDie) on jpevents.lua
	if not unit then
		updateTimeToDie(elapsed, "target")
		updateTimeToDie(elapsed, "focus")
		updateTimeToDie(elapsed, "player")
		return
	end
	if not UnitExists(unit) then return end

	local unitGuid = UnitGUID(unit)
	local health = UnitHealth(unit)

	if health == UnitHealthMax(unit) or health == 0 then
		jps.TimeToDieData[unitGuid] = nil
		return
	end

	local time = GetTime()

	jps.TimeToDieData[unitGuid] = timeToDieFunctions[timeToDieAlgorithm][0](jps.TimeToDieData[unitGuid],health,time)
	if jps.TimeToDieData[unitGuid] then
		if jps.TimeToDieData[unitGuid]["timeSinceNoChange"] >= maxTDDLifetime then
			jps.TimeToDieData[unitGuid] = nil
		end
	end
end

-- Time To Die Algorithms
timeToDieFunctions = {}
timeToDieFunctions["InitialMidpoints"] = { 
	[0] = function(dataset, health, time)
		if not dataset or not dataset.health0 then
			dataset = {}
			dataset.time0, dataset.health0 = time, health
			dataset.mhealth, dataset.mtime = time, health
			dataset.health = health
			dataset.timeSinceChange = 0
			dataset.timeSinceNoChange = 0
			dataset.timestamp = time
		else
			dataset.timeSinceLastChange = time - dataset.timestamp
			dataset.timestamp = time
			dataset.healthChange = dataset.health - health 
			dataset.health = health
			if dataset.healthChange <= 1 then
				dataset.timeSinceNoChange = dataset.timeSinceNoChange + dataset.timeSinceLastChange
			else
				dataset.timeSinceNoChange = 0 
			end
			dataset.mhealth = (dataset.mhealth + health) * .5
			dataset.mtime = (dataset.mtime + time) * .5
			if dataset.mhealth > dataset.health0 then
				return nil
			end
		end
		return dataset
	end,
	[1] = function(dataset, health, time)
		if not dataset or not dataset.health0 then
			return nil
		else
			return health * (dataset.time0 - dataset.mtime) / (dataset.mhealth - dataset.health0)
		end
	end 
}
timeToDieFunctions["LeastSquared"] = { 
	[0] = function(dataset, health, time)	
		if not dataset or not dataset.n then
			dataset = {}
			dataset.n = 1
			dataset.time0, dataset.health0 = time, health
			dataset.mhealth = time * health
			dataset.mtime = time * time
			dataset.health = health
			dataset.timeSinceChange = 0
			dataset.timeSinceNoChange = 0
			dataset.timestamp = time
		else
			dataset.n = dataset.n + 1
			dataset.timeSinceLastChange = time - dataset.timestamp
			dataset.timestamp = time
			dataset.healthChange = dataset.health - health 
			dataset.health = health
			if dataset.healthChange <= 1 then
				dataset.timeSinceNoChange = dataset.timeSinceNoChange + dataset.timeSinceLastChange
			else
				dataset.timeSinceNoChange = 0 
			end
			dataset.time0 = dataset.time0 + time
			dataset.health0 = dataset.health0 + health
			dataset.mhealth = dataset.mhealth + time * health
			dataset.mtime = dataset.mtime + time * time
			local timeToDie = timeToDieFunctions["LeastSquared"][1](dataset,health,time)
			if not timeToDie then
				return nil
			end
		end
		return dataset
	end,
	[1] = function(dataset, health, time)
		if not dataset or not dataset.n then
			return nil
		else
			local num = (dataset.health0 * dataset.time0 - dataset.mhealth * dataset.n)
			if num == 0 then return nil end
			local timeToDie = (dataset.health0 * dataset.mtime - dataset.mhealth * dataset.time0) / (num) - time
			if timeToDie < 0 then
				return nil
			else
				return timeToDie
			end
		end
	end 
}
timeToDieFunctions["WeightedLeastSquares"] = { 
	[0] = function(dataset, health, time)	
		if not dataset or not dataset.health0 then
			dataset = {}
			dataset.time0, dataset.health0 = time, health
			dataset.mhealth = time * health
			dataset.mtime = time * time
			dataset.health = health
			dataset.timeSinceChange = 0
			dataset.timeSinceNoChange = 0
			dataset.timestamp = time
		else
			dataset.timeSinceLastChange = time - dataset.timestamp
			dataset.timestamp = time
			dataset.healthChange = dataset.health - health 
			dataset.health = health
			if dataset.healthChange <= 1 then
				dataset.timeSinceNoChange = dataset.timeSinceNoChange + dataset.timeSinceLastChange
			else
				dataset.timeSinceNoChange = 0 
			end
			dataset.time0 = (dataset.time0 + time) * .5
			dataset.health0 = (dataset.health0 + health) * .5
			dataset.mhealth = (dataset.mhealth + time * health) * .5
			dataset.mtime = (dataset.mtime + time * time) * .5
			local timeToDie = timeToDieFunctions["WeightedLeastSquares"][1](dataset,health,time)
			if not timeToDie then
				return nil
			end
		end
		return dataset
	end,
	[1] = function(dataset, health, time)
		if not dataset or not dataset.health0 then
			return nil
		else
			local num = (dataset.time0 * dataset.health0 - dataset.mhealth)
			if num == 0 then return nil end
			local timeToDie = (dataset.mtime * dataset.health0 - dataset.time0 * dataset.mhealth) / (num) - time
			if timeToDie < 0 then
				return nil
			else
				return timeToDie
			end
		end
	end 
}

-- Based on Health Loss
jps.TimeToDie = function(unit, percent)
	local unitGuid = UnitGUID(unit)
	local health_unit = UnitHealth(unit)
	local timetodie = 60 -- e.g. 60 seconds
	local time = GetTime()
	local timeToDie = timeToDieFunctions[timeToDieAlgorithm][1](jps.TimeToDieData[unitGuid],health_unit,time)
	
	if percent ~= nil and timeToDie ~= nil then
		curPercent = health_unit/UnitHealthMax(unit)
		if curPercent > percent then
			timeToDie = (curPercent-percent)/(curPercent/timeToDie)
		else
			timeToDie = 0
		end
	end
	if timeToDie ~= nil then return math.ceil(timeToDie) else return 60 end
end
