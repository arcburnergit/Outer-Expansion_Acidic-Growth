
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

local nebulaClouds = {}

local rows = 4
local columns = 5

local xJump = 350
local yJump = 230

local minScale = 1.5
local maxScaleRandom = 2
local scaleIncrease = 0.25

local lifeTime = 10
local fadeInTime = 1
local fadeOutTime = 1

local minOpacity = 0.9
local maxOpacity = 1

local imageString = "stars_acid/nebula_large_c.png"
local eventString = "NEBULA_ACIDIC"
local playerVar = "oe_acidic_nebula"

local warningString = "warnings/danger_oe_acidic.png"
mods.multiverse.register_environment("oe_acidic_nebula", playerVar, warningString)

--[[local warningImage = Hyperspace.Resources:CreateImagePrimitiveString(warningString, 0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
local warningX = 660
local warningY = 72
local warningSizeX = 60
local warningSizeY = 58
local warningText = "You're inside an Acidic nebula. Your sensors will not function and your empty rooms will be slowly breached at random by the Acidic clouds."
]]
local initialPosX = (math.random() * 131072) % 131 - 65
local initialPosY = (math.random() * 131072) % 81 - 40

for k = 1,(rows * columns),1 do
	nebulaClouds[k] = {x = 0, y = 0, scale = 1, timerScale = 0, opacity = 1, revOp = 0, fade = 0, exists = 1}
	nebulaClouds[k+(rows * columns)] = {x = 0, y = 0, scale = 1, timerScale = 0, opacity = 1, revOp = 0, fade = 0, exists = 0}
	local cloud = nebulaClouds[k]

	cloud.x = xJump * ((k - 1) % columns)
	cloud.y = yJump * math.floor((k-1)/columns)

	cloud.scale = (math.random() * (maxScaleRandom - minScale)) + minScale
	cloud.timerScale = math.random() * lifeTime

	cloud.opacity = (math.random() * (maxOpacity - minOpacity)) + minOpacity
	cloud.revOp = math.random(0,1)
end

script.on_internal_event(Defines.InternalEvents.PRE_CREATE_CHOICEBOX, function(event)
	if string.sub(event.eventName, 0, string.len(eventString)) == eventString and Hyperspace.playerVariables[playerVar] == 0 then
		Hyperspace.playerVariables[playerVar] = 1
		initialPosX = (math.random() * 131072) % 131 - 65
		initialPosY = (math.random() * 131072) % 81 - 40
	end
end)

script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
	Hyperspace.playerVariables[playerVar] = 0
end)

local function createCloud(x, y)
	local cloudTemp = {x = 0, y = 0, scale = 1.5, timerScale = 0, opacity = 1, revOp = 0, fade = 0, exists = 1}
	cloudTemp.x = x
	cloudTemp.y = y

	cloudTemp.scale = (math.random() * (maxScaleRandom - minScale)) + minScale
	cloudTemp.timerScale = 0

	cloudTemp.opacity = 0.05
	cloudTemp.revOp = math.random(0,1)
	return cloudTemp
end
local cloudImageTemp = Hyperspace.Resources:CreateImagePrimitiveString(imageString, -256, -200, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
script.on_render_event(Defines.RenderEvents.LAYER_FOREGROUND, function() 
	if Hyperspace.Global.GetInstance():GetCApp().world.bStartedGame and Hyperspace.playerVariables[playerVar] == 1 and Hyperspace.Settings.lowend == false then
		for k, cloud in ipairs(nebulaClouds) do
			if cloud.exists == 1 then
				local commandGui = Hyperspace.Global.GetInstance():GetCApp().gui
				--local cloudImageTemp = Hyperspace.Resources:CreateImagePrimitiveString(imageString, -256, -200, 0, Graphics.GL_Color(1, 1, 1, 1), cloud.opacity, false)
				
				Graphics.CSurface.GL_PushMatrix()
				Graphics.CSurface.GL_Translate((cloud.x + initialPosX),(cloud.y + initialPosX),0)
				Graphics.CSurface.GL_Scale(cloud.scale,cloud.scale,0)

				if (commandGui.bPaused or commandGui.event_pause) then
					Graphics.CSurface.GL_SetColorTint(Graphics.GL_Color(0.5, 0.5, 0.5, 1))
				end
				Graphics.CSurface.GL_RenderPrimitiveWithAlpha(cloudImageTemp, clour.opacity)
				Graphics.CSurface.GL_RemoveColorTint()
				Graphics.CSurface.GL_PopMatrix()

				if not (commandGui.bPaused or commandGui.event_pause) then
					cloud.timerScale = cloud.timerScale + (Hyperspace.FPS.SpeedFactor/16)
					cloud.scale = cloud.scale + ((scaleIncrease/lifeTime) * (Hyperspace.FPS.SpeedFactor/16))
					if cloud.timerScale >= lifeTime then
						cloud.exists = 0
					end

					if cloud.timerScale >= (lifeTime - fadeOutTime) then
						cloud.opacity = math.max(cloud.opacity - (0.95 * (Hyperspace.FPS.SpeedFactor/16)), 0.05)
						if cloud.fade == 0 then
							cloud.fade = 1
							for k2, cloudNew in ipairs(nebulaClouds) do
								if cloudNew.exists == 0 then
									nebulaClouds[k2] = createCloud(cloud.x, cloud.y)
									break
								end
							end
						end
					elseif cloud.timerScale < fadeInTime then
						cloud.opacity = math.min(cloud.opacity + (0.95 * (Hyperspace.FPS.SpeedFactor/16)), 1)

					elseif cloud.revOp == 0 then
						cloud.opacity = math.min(cloud.opacity + (0.1 * (Hyperspace.FPS.SpeedFactor/16)), 1)
						if cloud.opacity >= 1 then
							cloud.revOp = 1
						end
					else
						cloud.opacity = cloud.opacity - (0.1 * (Hyperspace.FPS.SpeedFactor/16))
						if cloud.opacity <= 0.9 then
							cloud.revOp = 0
						end
					end
				end
			end
		end
	end
end, function() end)

local startAcid = mods.oe.acid.startAcid

function acidTrigger()
	if Hyperspace.ships.player then
		Hyperspace.Sounds:PlaySoundMix("cultivatorSpore", -1, false)
		local roomPos = Hyperspace.ships.player:GetRandomRoomCenter()
		local room = get_room_at_location(Hyperspace.ships.player, roomPos, false)
		startAcid(0, room, 5)
	end
	if Hyperspace.ships.enemy then
		Hyperspace.Sounds:PlaySoundMix("cultivatorSpore", -1, false)
		local roomPos = Hyperspace.ships.enemy:GetRandomRoomCenter()
		local room = get_room_at_location(Hyperspace.ships.enemy, roomPos, false)
		startAcid(1, room, 5)
	end
end

local acidTimer = 10
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
	local commandGui = Hyperspace.Global.GetInstance():GetCApp().gui
	if Hyperspace.playerVariables[playerVar] == 1 and not (commandGui.bPaused or commandGui.event_pause or commandGui.menu_pause or commandGui.bAutoPaused or commandGui.touch_pause) then
		acidTimer = acidTimer - time_increment(true)
		if acidTimer <= 0 then
			acidTimer = 10 + math.random(0, 5)
			acidTrigger()
		end
	end
end)