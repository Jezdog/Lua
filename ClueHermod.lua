--[[
# Script Name:  CluesEditedHermod
# Description:  <Hermod Farming>
# Instructions: start at war retreat with last preset loaded
# Autor:        Clue (Edited by jezza)
# Version:      <1.1>
# Datum:        <10/4/2024" (MM/DD/YYYY)
# CONFIGURE LINE 20 TO UR KEYBIND!!@!@!@@@!@!@!@!@!@!!@!@!@!@!@!@!@!@!@!@!!@!@!@!@!@!@!@!@!@!@!@!@!@!@!@!@!
# IF YOU WANT TO CHANGE EXTREMES TO OVERLOADS, (55324, 55326, 55328, 55330) CHANGE THESE TO OVERLOAD #LINE 313
--]]

-- imports
local UTILS = require("utils")
local API = require("api")
local MAX_IDLE_TIME_MINUTES = 6
local startTime, afk = os.time(), os.time()
local fail = 0
local CurrentState = 0
local PID = 127143
local maxDistance = 2

API.SetDrawLogs(true)

local States = {
    Bank = 0,
    BossLobby = 1,
    BossFight = 2
}

local Locations = {
    WarRetreat = {x1 = 3279, x2 = 3309, y1 = 10113, y2 = 10143},
    BossLobby = {x1= 850, x2 = 870, y1 = 1730, y2 = 1750}
}

local IDS = {
    Bank = 114750,
    Altar = 114748,
    Hermod = 30163,
    Minions = 30164,
    RightPortal = 127138,
    BossBarrier = 127142,
}

local BuffBar = {
    necromancy = 30831,
	PrayerRenewal = 14695,
}

local Names = {
    Shark = "Shark"
}

local ABs = {
    Surge = API.GetABs_name1("Surge"),
    WarRetreat = API.GetABs_name1("War's Retreat Teleport"),
    necromancy = API.GetABs_name1("Protect from Necromancy"),
    EatFood = API.GetABs_name1("Eat Food"),
}

local LootTable = {
    989, --crystal key 
	55191, -- hermodic plate 
    42954, -- onyx dust  
    55216, -- animated drumsticks  
    55673, -- hermod pet 
    52946, -- small bladed Orichalcite
    7937, -- pure essence
    55628, -- memento
    1632, -- dragonstone
    53504, --tiny blade necronium
    47283, -- rune blade
    55630, --memento
	54018, -- elemental anima stone 
    12176, -- spirit weed seed      
    48768, -- carambola seed
    44811, -- necrite stone spirit 
    44813, -- banite stone spirit
	}

-- helper functions

local function AtLocation(loc) 
    return API.PInArea21(loc.x1, loc.x2, loc.y1, loc.y2)
end

local function updateState() 
    if not API.ReadPlayerMovin() then 
        if AtLocation(Locations.WarRetreat) then 
            CurrentState = States.Bank
            return
        end

        if AtLocation(Locations.BossLobby) then 
            CurrentState = States.BossLobby
            return
        end
    end
end


local function idleCheck()
    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((MAX_IDLE_TIME_MINUTES * 60) * 1.0, (MAX_IDLE_TIME_MINUTES * 60) * 1.5)

    if timeDiff > randomTime then
        API.PIdle2()
        updateState()
        afk = os.time()
        return true
    end
end

local function gameStateChecks()
    local gameState = API.GetGameState2()
    if (gameState ~= 3) then
        API.logDebug('Not ingame with state:', gameState)
        API.Write_LoopyLoop(false)
        return
    end
end

local function TeleportWarRetreat()  
    if API.InvItemcount_String(Names.Shark) < 5 or API.GetPrayPrecent() < 60 then
        if ABs.WarRetreat.id ~= 0 and ABs.WarRetreat.enabled then
            API.DoAction_Ability_Direct(ABs.WarRetreat, 1, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(2000,1000,2000)
            API.WaitUntilMovingandAnimEnds()
		end	
    end
end

local function Isnecromancy() 
    local soul = API.Buffbar_GetIDstatus(BuffBar.necromancy, false)
    return soul.found
end

local function praynecromancy() 
    if not Isnecromancy() then 
        API.DoAction_Ability_Direct(ABs.necromancy, 1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(600,0,0)
    end
end

local function IsHermodAlive() 
    local hermod = API.GetAllObjArray1({IDS.Hermod}, 50, {1})[1]
    if hermod ~= nil then 
        return true
    end

    return false
end

local function isportalInterfaceOpen() 
    return API.VB_FindPSett(2874, 1, 0).state == 18
end

local function openLootWindow()
    if not API.LootWindowOpen_2() then
        print("loot window not open")
        result = API.GetAllObjArray1(LootTable ,50,{3})
        for _, obj in ipairs(result) do 
            if obj ~= nil then
                print("found anima")
                API.KeyboardPress('A', 60, 100)
                API.RandomSleep2(1000,500,1000)
			if obj ~= nil then
			    API.RandomSleep2(700,200,700)
			    API.DoAction_Loot_w(LootTable, 30, API.PlayerCoordfloat(), 30)
				    API.WaitUntilMovingEnds()
					    API.RandomSleep2( 800, 300, 1000 )
						
				
				end
            end
        end
    end
end

local function deactivatenecromancy() 
    if Isnecromancy() then 
        API.DoAction_Ability_Direct(ABs.necromancy, 1, API.OFF_ACT_GeneralInterface_route)
    end
end

local function needBank() 
    return API.InvItemcount_String(Names.Shark) < 5 or API.GetPrayPrecent() < 60
end

local function healthCheck()
    local hp = API.GetHPrecent()
    if hp < 60 then
        if ABs.EatFood.id ~= 0 and ABs.EatFood.enabled then
            print("Eating")
            API.DoAction_Ability_Direct(ABs.EatFood, 1, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(600, 600, 600)
        end
        elseif hp < 20 or API.InvItemcount_String(Names.Shark) < 3 then
            print("Teleporting out")
			deactivatenecromancy()
            API.DoAction_Ability("War's Retreat Teleport", 1, API.OFF_ACT_GeneralInterface_route)
            CurrentState = States.Bank
            API.RandomSleep2(3000, 1000, 3000)
    end
end

local function loadLastPreset() 
    API.DoAction_Object_string1(0x33,API.OFF_ACT_GeneralObject_route3,{ "Bank chest" },50, true)
end

-- script function

local function loot() 
    openLootWindow()
	

    if API.LootWindowOpen_2() and (API.LootWindow_GetData()[1].itemid1 > 0) then
        print("First Loot All Attempt")
        API.DoAction_LootAll_Button()
        API.RandomSleep2(1000, 250, 250)
        API.RandomSleep2(600,100,300)
			if not API.InvItemFound1(385,SHARK) then
				CurrentState = States.Bank
				    deactivatenecromancy()
				    API.DoAction_Ability("War's Retreat Teleport", 1, API.OFF_ACT_GeneralInterface_route)
                    API.RandomSleep2(3000, 1000, 2000)
			elseif API.InvItemcount_String(Names.Shark) < 4 then
				CurrentState = States.Bank
				    deactivatenecromancy()
                    API.DoAction_Ability("War's Retreat Teleport", 1, API.OFF_ACT_GeneralInterface_route)
                    API.RandomSleep2(3000, 1000, 2000)				
            end
    end
end	
		

local function isFightingMinion() 
    local id = API.Local_PlayerInterActingWith_Id()
    if id == IDS.Minions then 
        return true
    end

    return false
end

local function WarRetreatMagic()
    if needBank() then
        fail = fail + 1
        if fail > 3 then 
            API.Write_LoopyLoop(false)
        end

        API.RandomSleep2(600,0,0)
        if API.GetPrayPrecent() < 90 then 
            -- Altar
            API.DoAction_Object1(0x3d,API.OFF_ACT_GeneralObject_route0,{IDS.Altar} ,50)
            API.RandomSleep2(600,200,600)
            API.WaitUntilMovingandAnimEnds()
            API.RandomSleep2(500,200,600)
        end

        loadLastPreset()
        API.RandomSleep2(600,0,0)
        API.WaitUntilMovingEnds()

    else
        fail = 0
        API.DoAction_Object1(0x39, API.OFF_ACT_GeneralObject_route0, {IDS.RightPortal}, 50)
        API.RandomSleep2(600, 500, 600)
        CurrentState = States.BossLobby
        API.WaitUntilMovingEnds()
    end
end

-- Function to check if a game object is within a certain distance
    function isObjectWithinDistance()
    local POS = API.PlayerCoord()
    local playerCoord = API.PlayerCoord()
    local foundObject = API.FindObjCheck_1(24731, 3, 1, FALSE, 0, Enter)
        if foundObject ~= nil then
            local objectCoord = foundObject.tile
            local distance = math.sqrt((playerCoord.x - objectCoord.x)^2 + (playerCoord.y - objectCoord.y)^2)
            return distance <= 2
        end
    end		

local function BossLobby()
UTILS.randomSleep(1500)
    if isportalInterfaceOpen() and not API.ReadPlayerMovin2() then
        API.DoAction_Interface(0x24,0xffffffff,1,1591,60,-1,API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(400, 600, 1400)
        CurrentState = States.BossFight
	else  
	if isportalInterfaceOpen() then
	    API.DoAction_Interface(0x24,0xffffffff,1,1591,60,-1,API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(400, 600, 1400)
        CurrentState = States.BossFight
	
    else
        API.DoAction_Object1(0x39, API.OFF_ACT_GeneralObject_route0, {IDS.BossBarrier}, 50)
        API.RandomSleep2(1000, 600, 400)
        API.WaitUntilMovingEnds()
				if isObjectWithinDistance then	
						      if isportalInterfaceOpen() and not API.ReadPlayerMovin2() then
                                  API.DoAction_Interface(0x24,0xffffffff,1,1591,60,-1,API.OFF_ACT_GeneralInterface_route)
								  CurrentState = States.BossFight
                                  API.RandomSleep2(2200, 600, 1400)
								  UTILS.countTicks(1)
								  local POS = API.PlayerCoord()
                        API.DoAction_Tile(WPOINT.new(POS.x + math.random(1, 3), POS.y + math.random(11, 15), POS.z))   -- move to randomized spot
                        UTILS.countTicks(1)
                        UTILS.randomSleep(1500)	
				else BossLobby()			
                end
	end			
    end
        end
end		

local function BossFight()
    local minion = API.GetAllObjArray1({IDS.Minions}, 50, {1})[1]
	local POS = API.PlayerCoord()
	local obj = {30163}
    local hasPrayerRenewal = false
    local PrayerRenewal = { 33186, 33184, 33182, 33180, 33178, 33176 }
    local extremen = { 55324, 55326, 55328, 55330 }
    local invContains2 = { 33186, 33184, 33182, 33180, 33178, 33176 }
    local cooldown = (API.Buffbar_GetIDstatus(BuffBar.PrayerRenewal, false).id > 0)
    local range = 15
    local types = {1}  API.RandomSleep2(800, 300, 500)
    local objects = API.GetAllObjArrayInteract(obj, range, types)
	    if objects then
        for _, object in ipairs(objects) do
        if object.Id == 30163 then
          if object.Anim == 21650 then
            API.DoAction_Tile(WPOINT.new(POS.x + math.random(2, 3), POS.y + math.random(2, 3), POS.z))
			    API.RandomSleep2(1800, 600, 800)
			API.DoAction_Tile(WPOINT.new(POS.x + math.random(-2, -1), POS.y + math.random(-2, -1), POS.z))
			API.RandomSleep2(1100, 700, 1200)
			API.DoAction_NPC(0x2a,API.OFF_ACT_AttackNPC_route, {IDS.Hermod}, 50)
			API.RandomSleep2(1500, 500, 600)
		end
		
        if minion ~= nil and not isFightingMinion() then 
        API.DoAction_NPC(0x2a,API.OFF_ACT_AttackNPC_route, {IDS.Minions}, 50)
        end
		
		print (cooldown)
		print ("1")
		
            if cooldown == false then
            for _, itemId in ipairs(PrayerRenewal) do
            if API.InvItemcount_1(itemId) > 0 then
                hasPrayerRenewal = true		   
		
		
        elseif hasPrayerRenewal == true then
	        print (Drinking)
            API.RandomSleep2(300, 200, 400)
            API.DoAction_Inventory2(PrayerRenewal, 0, 1, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(1300, 500, 400)
	        API.DoAction_Inventory2(extremen, 0, 1, API.OFF_ACT_GeneralInterface_route)
		 return
		    end
		end 	
		
		

    if minion == nil then 
        local id = API.Local_PlayerInterActingWith_Id()
        if id ~= IDS.Hermod then
            praynecromancy()		
            API.DoAction_NPC(0x2a,API.OFF_ACT_AttackNPC_route, {IDS.Hermod}, 50)
            return
		end	
		end
	end
		 end 
    end
  end
end  


while API.Read_LoopyLoop() do
    praynecromancy() 
    API.DoRandomEvents()
	idleCheck()
    gameStateChecks()
    if CurrentState == States.Bank and not API.ReadPlayerMovin() then 
        if not AtLocation(Locations.WarRetreat) then 
            TeleportWarRetreat()
        end
        WarRetreatMagic()
    end

    if CurrentState == States.BossLobby and not API.ReadPlayerMovin() then 
        if not AtLocation(Locations.BossLobby) then 
            TeleportWarRetreat()
            CurrentState = States.Bank
            return
        end

        BossLobby()
    end

    if CurrentState == States.BossFight then	
        if IsHermodAlive() then 
            healthCheck()
            BossFight()
        else
            loot()			
        end
    end
    API.RandomSleep2(600,400,100)
end
