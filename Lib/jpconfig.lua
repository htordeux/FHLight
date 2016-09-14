
function jps_VARIABLES_LOADED()
	if jps.ResetDB then 
		jpsDB = {}
		collectgarbage("collect")
	end
	if not jpsDB then
		jpsDB = {}
	end
	if not jpsDB[jpsRealm] then
		jpsDB[jpsRealm] = {}
	end
	if not jpsDB[jpsRealm][jpsName] then
		write("Initializing new character names")
		jpsDB[jpsRealm][jpsName] = {}
		jpsDB[jpsRealm][jpsName].Enabled = true
		jpsDB[jpsRealm][jpsName].FaceTarget = false
		jpsDB[jpsRealm][jpsName].UseCDs = false
		jpsDB[jpsRealm][jpsName].MultiTarget = false
		jpsDB[jpsRealm][jpsName].Interrupts = false
		jpsDB[jpsRealm][jpsName].Defensive = false
		jpsDB[jpsRealm][jpsName].PvP = false
		jpsDB[jpsRealm][jpsName].ExtraButtons = true
	end

	jps_LOAD_PROFILE()
	jps_SAVE_PROFILE()
	jps_variablesLoaded = true
end

---------------------------
-- LOAD_PROFILE
---------------------------
function jps_LOAD_PROFILE() 
	for saveVar,value in pairs( jpsDB[jpsRealm][jpsName] ) do
		jps[saveVar] = value
	end

	jps.gui_toggleEnabled( jps.Enabled )
	jps.gui_toggleRot(jps.FaceTarget)
	jps.gui_toggleCDs( jps.UseCDs )
	jps.gui_toggleMulti( jps.MultiTarget )
	jps.gui_toggleInt(jps.Interrupts)
	jps.gui_toggleDef(jps.Defensive)
	jps.gui_toggleToggles( jps.ExtraButtons )
	jps.gui_setToggleDir( "right" )
	jps.togglePvP( jps.PvP )
	jps.resize( 36 )
end

---------------------------
-- SAVE_PROFILE
---------------------------

function jps_SAVE_PROFILE()
	for varName, _ in pairs( jpsDB[jpsRealm][jpsName] ) do
		jpsDB[jpsRealm][jpsName][varName] = jps[varName]
	end
end