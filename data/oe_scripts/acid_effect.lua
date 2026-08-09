
local time_increment = mods.multiverse.time_increment
local vter = mods.multiverse.vter
local userdata_table = mods.multiverse.userdata_table

local get_room_at_location = mods.oe.get_room_at_location
local xor = mods.oe.xor
local isPointInEllipse = mods.oe.isPointInEllipse
local worldToPlayerLocation = mods.oe.worldToPlayerLocation
local worldToEnemyLocation = mods.oe.worldToEnemyLocation
local get_distance = mods.oe.get_distance
local offset_point_in_direction = mods.oe.offset_point_in_direction
local get_point_local_offset = mods.oe.get_point_local_offset
local get_random_point_in_radius = mods.oe.get_random_point_in_radius
local normalise_angle = mods.oe.normalise_angle
local angle_diff = mods.oe.angle_diff
local get_angle_between_points = mods.oe.get_angle_between_points
local find_closest_slot = mods.oe.find_closest_slot

local acidTileAnim = Hyperspace.Animations:GetAnimation("oe_acid_tile2_anim")
acidTileAnim.position.x = -acidTileAnim.info.frameWidth/2
acidTileAnim.position.y = -acidTileAnim.info.frameHeight/2
acidTileAnim.tracker.loop = true
acidTileAnim:Start(true)
local acidWallAnim = Hyperspace.Animations:GetAnimation("oe_acid_wall_anim")
acidWallAnim.position.x = -acidWallAnim.info.frameWidth/2
acidWallAnim.position.y = -acidWallAnim.info.frameHeight/2
acidWallAnim.tracker.loop = true
acidWallAnim:Start(true)

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
	if shipManager.iShipId == 0 then
		acidTileAnim:Update()
		acidWallAnim:Update()
	end
end)

local acidBreachTimerMax = 5
local acidDoorTimerMax = 1
local acidStatus = {[0] = {}, [1] = {}}
script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
	local acidShip = acidStatus[shipManager.iShipId]
	local doorsDamage = {}
	for room in vter(shipManager.ship.vRoomList) do
		if acidShip[room.iRoomId] then
			local acidRoom = acidShip[room.iRoomId]
			--print("ACID ACTIVE: timer:"..acidRoom.timer.." breachTimer:"..acidRoom.breachTimer)
			acidRoom.timer = acidRoom.timer - Hyperspace.FPS.SpeedFactor/16
			acidRoom.doorTimer = acidRoom.doorTimer - Hyperspace.FPS.SpeedFactor/16
			acidRoom.breachTimer = acidRoom.breachTimer - Hyperspace.FPS.SpeedFactor/16
			if acidRoom.breachTimer <= 0 then
				shipManager.ship:BreachRandomHull(room.iRoomId)
				acidRoom.breachTimer = acidBreachTimerMax
			end
			if acidRoom.doorTimer <= 0 then
				doorsDamage[room.iRoomId] = true
				acidRoom.doorTimer = acidDoorTimerMax
			end
			if acidRoom.timer <= 0 then
				acidStatus[shipManager.iShipId][room.iRoomId] = nil
			end
		end
	end
	if #doorsDamage > 0 then
		for door in vter(shipManager.ship.vDoorList) do
			if (doorsDamage[door.iRoom1] or doorsDamage[door.iRoom2]) and not door.bOpen then
				--print("damage door:"..door.iDoorId)
				door:ApplyDamage(1)
			end
		end
	end
end)

script.on_internal_event(Defines.InternalEvents.JUMP_LEAVE, function(shipManager)
	acidStatus[1] = {}
end)

function mods.oe.acid.startAcid(shipId, roomId, time)
	if not acidStatus[shipId][roomId] then
		acidStatus[shipId][roomId] = {timer = time, breachTimer = acidBreachTimerMax - 0.1, doorTimer = acidDoorTimerMax - 0.1}
	else
		acidStatus[shipId][roomId].timer = acidStatus[shipId][roomId].timer + math.max(1, time/acidStatus[shipId][roomId].timer) * time
	end
end
local startAcid = mods.oe.acid.startAcid

script.on_render_event(Defines.RenderEvents.SHIP_BREACHES, function() end, function(ship) 
	local shipManager = Hyperspace.ships(ship.iShipId)
	local acidShip = acidStatus[shipManager.iShipId]
	for room in vter(shipManager.ship.vRoomList) do
		if acidShip[room.iRoomId] then
			local acidRoom = acidShip[room.iRoomId]
			local x = room.rect.x
			local y = room.rect.y
			local w = math.floor(room.rect.w/35)
			local h = math.floor(room.rect.h/35)
			local size = w * h
			--print("room:"..room.iRoomId.." gasLevel:"..gasLevel.." w:"..w.." h:"..h.." size:"..size)
			for i = 0, size - 1 do
				local xOff = x + (i%w) * 35
				local yOff = y + math.floor(i/w) * 35
				Graphics.CSurface.GL_PushMatrix()
				Graphics.CSurface.GL_Translate(xOff+18, yOff+18, 0)
				acidTileAnim:OnRender(0.5, Graphics.GL_Color(1, 1, 1, 1), false)
				Graphics.CSurface.GL_PopMatrix()
			end
			local opacity = 0.5 + ((acidBreachTimerMax - acidRoom.breachTimer)/(acidBreachTimerMax*2))
			-- top and bottom edge
			for i = 0, w - 1 do
				local xOff = x + i * 35
				Graphics.CSurface.GL_PushMatrix()
				Graphics.CSurface.GL_Translate(xOff+18, y+18, 0)
				acidWallAnim:OnRender(opacity, Graphics.GL_Color(1, 1, 1, 1), false)
				Graphics.CSurface.GL_PopMatrix()

				local yOff = y + (h-1) * 35
				Graphics.CSurface.GL_PushMatrix()
				Graphics.CSurface.GL_Translate(xOff+18, yOff+18, 0)
				Graphics.CSurface.GL_Rotate(180, 0, 0, 1)
				acidWallAnim:OnRender(opacity, Graphics.GL_Color(1, 1, 1, 1), false)
				Graphics.CSurface.GL_PopMatrix()
			end

			-- left and right edge
			for i = 0, h - 1 do
				local yOff = y + i * 35
				Graphics.CSurface.GL_PushMatrix()
				Graphics.CSurface.GL_Translate(x+18, yOff+18, 0)
				Graphics.CSurface.GL_Rotate(270, 0, 0, 1)
				acidWallAnim:OnRender(opacity, Graphics.GL_Color(1, 1, 1, 1), false)
				Graphics.CSurface.GL_PopMatrix()

				local xOff = x + (w-1) * 35
				Graphics.CSurface.GL_PushMatrix()
				Graphics.CSurface.GL_Translate(xOff+18, yOff+18, 0)
				Graphics.CSurface.GL_Rotate(90, 0, 0, 1)
				acidWallAnim:OnRender(opacity, Graphics.GL_Color(1, 1, 1, 1), false)
				Graphics.CSurface.GL_PopMatrix()
			end

		end
	end
end)

mods.oe.acid.acidCrewPower = {}
local acidCrewPower = mods.oe.acid.acidCrewPower
acidCrewPower["power_oe_acid_worker"] = true
acidCrewPower["power_oe_acid_soldier"] = true
--acidCrewPower["power_unique_oe_bill"] = true

script.on_internal_event(Defines.InternalEvents.ACTIVATE_POWER, function(power, shipManager)
	local crewmem = power.crew
	if acidCrewPower[power.def.name] then
		local ship = crewmem.currentShipId
		local room = crewmem.iRoomId
		startAcid(ship, room, 10)
	end
	return Defines.Chain.CONTINUE
end)

mods.oe.acid.acidicCrewStats = {}
local acidicCrewStats = mods.oe.acid.acidicCrewStats
acidicCrewStats["oe_acid_worker"] = {[Hyperspace.CrewStat.REPAIR_SPEED_MULTIPLIER] = {mult = 2}, [Hyperspace.CrewStat.ACTIVE_HEAL_AMOUNT] = {add = 2.4}}
acidicCrewStats["oe_acid_soldier"] = {[Hyperspace.CrewStat.REPAIR_SPEED_MULTIPLIER] = {mult = 2}, [Hyperspace.CrewStat.ACTIVE_HEAL_AMOUNT] = {add = 2.4}}
acidicCrewStats["unique_oe_bill"] = {[Hyperspace.CrewStat.REPAIR_SPEED_MULTIPLIER] = {mult = 2}, [Hyperspace.CrewStat.ACTIVE_HEAL_AMOUNT] = {add = 4.8}}

script.on_internal_event(Defines.InternalEvents.CALCULATE_STAT_POST, function(crewmem, stat, def, amount, value)
	if not (crewmem and crewmem.currentShipId and crewmem.iRoomId) then return Defines.Chain.CONTINUE, amount, value end
	if acidStatus[crewmem.currentShipId] and acidStatus[crewmem.currentShipId][crewmem.iRoomId] then
		local crewStat = acidicCrewStats[crewmem.type]
		if crewStat and crewStat[stat] then
			if crewStat[stat].mult then
				amount = amount * crewStat[stat].mult
			elseif crewStat[stat].add then
				amount = amount + crewStat[stat].add
			end
		elseif stat == Hyperspace.CrewStat.DAMAGE_MULTIPLIER and Hyperspace.ships.player:HasAugmentation("LAB_OE_ACID_COOLING") > 0 then
			amount = amount * 0.5
		end
	end	
	return Defines.Chain.CONTINUE, amount, value
end)

mods.oe.acid.acidWeapons = {}
local acidWeapons = mods.oe.acid.acidWeapons
acidWeapons["OE_LASER_ACID_1"] = 5
acidWeapons["OE_LASER_ACID_1_ELITE"] = 5
acidWeapons["OE_LASER_ACID_2"] = 5
acidWeapons["OE_LASER_ACID_2_ELITE"] = 5
acidWeapons["OE_LASER_ACID_3"] = 5
acidWeapons["OE_LASER_ACID_3_ELITE"] = 5
acidWeapons["OE_BEAM_ACID_1"] = 5
acidWeapons["OE_BEAM_ACID_1_ELITE"] = 5
acidWeapons["OE_ION_ACID_1"] = 5
acidWeapons["OE_ION_ACID_1_ELITE"] = 5
acidWeapons["OE_LASER_ACID_SUPER"] = 5
acidWeapons["OE_LASER_ACID_SUPER_ENEMY"] = 5

script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, function(shipManager, projectile, location, damage, shipFriendlyFire)
	if projectile and acidWeapons[projectile.extend.name] then
		local room = get_room_at_location(shipManager, location, true)
		startAcid(shipManager.iShipId, room, acidWeapons[projectile.extend.name])
	end
end)

script.on_internal_event(Defines.InternalEvents.DAMAGE_BEAM, function(shipManager, projectile, location, damage, realNewTile, beamHitType)
	if projectile and acidWeapons[projectile.extend.name] and beamHitType == Defines.BeamHit.NEW_ROOM then
		local room = get_room_at_location(shipManager, location, true)
		startAcid(shipManager.iShipId, room, acidWeapons[projectile.extend.name])
	end
end)