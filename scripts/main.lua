local key = "RightMouseButton"
local keyPressed = false
local UEHelpers = require("UEHelpers")
local console = require("OBRConsole")
local kismetSystemLib = UEHelpers.GetKismetSystemLibrary()
local engine = FindFirstOf("Engine")
local originalFOV = nil

local function isValid(u)
    return kismetSystemLib and kismetSystemLib:IsValid(u)
end

local function loadConfig()
    local info       = debug.getinfo(1, "S")
    local scriptPath = info.source:match("@?(.*[\\/])") or "./"
    local cfg = {}
    local f = io.open(scriptPath .. "Config.ini", "r")
    if not f then error("Cannot open config: " .. scriptPath .. "Config.ini") end
    for line in f:lines() do
        local k, v = line:match("([%w_]+)%s*=%s*(%-?%d+)")
        if k and v then cfg[k] = tonumber(v) end
    end
    f:close()
    return cfg
end

local config = loadConfig()

config.zoom_fov = config.zoom_fov or 50

local function ExecCmd(cmd)
    if not (kismetSystemLib and isValid(engine)) then return end
    kismetSystemLib:ExecuteConsoleCommand(engine, cmd, nil)
end
	
local function ExecGetCmd(cmd, callback)
    if not (kismetSystemLib and isValid(engine)) then return end
	local value = kismetSystemLib:GetConsoleVariableFloatValue(cmd)
	if callback then
		callback(value)
	end
end

local function Zoom()
    local player = FindFirstOf("BP_OblivionPlayerCharacter_C")
    if player and player:IsValid() and config.zoom_fov ~= 0 then
        ExecGetCmd("Altar.FirstPersonFOV", function(value)
            if value then
                originalFOV = value
                ExecCmd("Altar.FirstPersonFOV " .. config.zoom_fov)
                keyPressed = true
            end
        end)
    end
end

local function Reset()
    local player = FindFirstOf("BP_OblivionPlayerCharacter_C")
    if player and player:IsValid() and originalFOV then
        ExecCmd("Altar.FirstPersonFOV " .. tostring(originalFOV))
        keyPressed = false
        originalFOV = nil
    end
end

-- todo: find hook that specifies whether or not player is in the game not the main menu
RegisterHook("/Script/Altar.VMainMenuViewModel:LoadInstanceOfLevels", function()
    RegisterHook("/Game/Dev/Controllers/BP_AltarPlayerController.BP_AltarPlayerController_C:InpActEvt_AnyKey_K2Node_InputKeyEvent_1", function(_, Key)
		local isWeaponDrawn = FindFirstOf("BP_AltarPlayerController_C").Pawn.IsWeaponDrawn()
        local pressedKey = Key:get().KeyName:ToString()
		if isWeaponDrawn ~= nil then
			ExecGetCmd("Altar.FirstPersonFOV", function(value)
				if value then
					if pressedKey == key and not isWeaponDrawn then
						if not keyPressed then
							Zoom()
						else
							Reset(value)
						end
					end
				else
					print("Failed to get FOV value.")
				end
			end)
		else
			print("Failed to get weapon draw status.")
		end
    end)
end)