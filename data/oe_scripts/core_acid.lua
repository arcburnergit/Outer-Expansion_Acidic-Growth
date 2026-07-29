local mod_name = "Outer Expansion: Acidic Growth"
if not mods.oe then
	error("Outer Expansion: Core not detected, please ensure it is present in the mod list and patched before "..mod_name.."!")
else
	mods.oe.acid = {}
end

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

script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
	if weapon.blueprint then
		if weapon.blueprint.name == "OE_LASER_ACID_SUPER" or weapon.blueprint.name == "OE_LASER_ACID_SUPER_ENEMY" then
			local shipManager = Hyperspace.ships(1-projectile.ownerId)
			for system in vter(shipManager.vSystemList) do
				local roomId = system.roomId
				local roomLoc = shipManager:GetRoomCenter(roomId)

				local spaceManager = Hyperspace.App.world.space
				local laser = spaceManager:CreateLaserBlast(
					weapon.blueprint,
					projectile.position,
					projectile.currentSpace,
					projectile.ownerId,
					roomLoc,
					projectile.destinationSpace,
					projectile.heading)
				laser.entryAngle = projectile.entryAngle
			end
			projectile:Kill()
		end
	end
end)

script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, function(shipManager, projectile, location, damage, shipFriendlyFire)
	if projectile and (projectile.extend.name == "OE_LASER_ACID_BOSS" or projectile.extend.name == "OE_LASER_ACID_BOSS_CHAOS") then
		local blueprint = Hyperspace.Blueprints:GetWeaponBlueprint(projectile.extend.name.."_PROJ")
		for roomId, roomPos in pairs(get_adjacent_rooms(shipManager.iShipId, get_room_at_location(shipManager, location, false), false)) do
			local spaceManager = Hyperspace.App.world.space
			local laser = spaceManager:CreateLaserBlast(
				blueprint,
				projectile.position,
				projectile.currentSpace,
				projectile.ownerId,
				roomPos,
				projectile.destinationSpace,
				projectile.heading)
		end
	end
end)


script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
	if shipManager:HasAugmentation("OE_ACID_O2SYS") > 0 and shipManager:HasSystem(2) and not Hyperspace.App.menu.shipBuilder.bOpen then
		local oxygen = shipManager.oxygenSystem
		local refill = oxygen:GetRefillSpeed()

		--print("refill speed: "..tostring(refill))
		local shipGraph = Hyperspace.ShipGraph.GetShipInfo(shipManager.iShipId)
		local wipe_p = false
		if not Hyperspace.Global.GetInstance():GetCApp().world.bStartedGame then
			wipe_p = true
		end
		if refill > 0 then
			for id = 0, shipGraph:RoomCount() - 1, 1 do
				--local id = room.iRoomId
				--print(id)
				oxygen:ModifyRoomOxygen(id, (-1*refill) - (5*(Hyperspace.FPS.SpeedFactor/16)))
				if wipe_p then
					oxygen:EmptyOxygen(id)
				end
			end
		end
	elseif shipManager:HasAugmentation("OE_ACID_O2SYS_ENEMY") > 0 and shipManager:HasSystem(2) and not Hyperspace.App.menu.shipBuilder.bOpen then
		local oxygen = shipManager.oxygenSystem
		local refill = oxygen:GetRefillSpeed()
		--print("refill speed: "..tostring(refill))
		local shipGraph = Hyperspace.ShipGraph.GetShipInfo(shipManager.iShipId)
		local wipe_e = false
		if refill > 0 then
			for id = 0, shipGraph:RoomCount() - 1, 1 do
				--local id = room.iRoomId
				--print(id)
				oxygen:ModifyRoomOxygen(id, (-1*refill) - (2*(Hyperspace.FPS.SpeedFactor/16)))
			end
		end
	end
end)