local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Maid = require(ReplicatedStorage.Shared.Utility.maid)
local TopbarUI = require(ReplicatedStorage.Shared.Icon)
local SettingsController = Knit.CreateController {
    Name = "SettingsController",
}

local player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local playerGui = player:WaitForChild("PlayerGui")
local playerScripts = player:WaitForChild("PlayerScripts")
local Core = playerGui:WaitForChild("Main")
local Content = Core:WaitForChild("Content")
local Settings = Content:WaitForChild("Settings")

type Graphics = {
    Current : number, -- 1 = Low, 2 = Medium, 3 = High
    GlobalShadows : boolean,
    ShadowSoftness : number;
}

function SettingsController:KnitInit()

end

local TextureStorage = {}

function SettingsController:ApplyGraphics(GraphicsFrame : Frame,Settings : Graphics)
    -- local Next : TextButton = GraphicsFrame:WaitForChild("Next")
    -- local Back : TextButton = GraphicsFrame:WaitForChild("Back")
    -- local Current : TextButton = GraphicsFrame:WaitForChild("Current")
    -- local Checkbox : TextButton = GraphicsFrame:WaitForChild("CheckBox")
    -- local TreeCheck : TextButton = GraphicsFrame:WaitForChild("TreeCheck")
    -- local WindCheck : TextButton = GraphicsFrame:WaitForChild("WindCheck")
    local Foliage = CollectionService:GetTagged("Foliage")
    local Buildings = CollectionService:GetTagged("Buildings")
    -- local CurrentTier = 3
    local CurrentSetting;

    local function BuildingTexture(Value)
        for _,Building in ipairs(Buildings) do
            local Descendants = Building:GetDescendants() 
            for _,parts in ipairs(Descendants) do
                if parts:IsA("Decal") or parts:IsA("Texture") then
                    local OriginalValue

                    if not parts:GetAttribute("OriginalValue") then
                        parts:SetAttribute("OriginalValue",parts.Transparency) 
                    else
                        OriginalValue = parts:GetAttribute("OriginalValue")
                    end

                    if Value > 0 then
                        parts.Transparency = Value
                    elseif Value ~= 0 then
                        parts.Transparency = OriginalValue or parts.Transparency
                    end
                end
            end
        end
    end

    local Tiers = {
        [1] = "Low",
        [2] = "Medium",
        [3] = "High",
    }

    local GraphicsSettings = {
        ["Low"] = function()
            Settings.GlobalShadows = false
            Settings.WindEffect = false
            Settings.TreeEffect = false

            task.spawn(BuildingTexture,1)

            for _,parts in pairs(Foliage) do
                local Particle = parts:FindFirstChildWhichIsA("ParticleEmitter")

                if Particle then
                    Particle.Enabled = false
                end
            end

            for _,buildings : Part in pairs(Buildings) do
                local Descendants = buildings:GetDescendants() 

                for _,parts in ipairs(Descendants) do
                    if parts:IsA("BasePart") then

                        if not TextureStorage[parts] then
                            TextureStorage[parts] = parts.Material
                        end 
                        
                        parts.Material = Enum.Material.SmoothPlastic
                    elseif parts:IsA("ParticleEmitter") then
                        parts.Enabled = false
                    end
                end
            end

            playerScripts.WindEffect.Value = Settings.WindEffect
            playerScripts.TreeEffect.Value = Settings.TreeEffect

            -- WindCheck.Text = ""
            -- TreeCheck.Text = ""

            Lighting.EnvironmentDiffuseScale = 0.7
            Lighting.EnvironmentSpecularScale = 0
            Lighting.ShadowSoftness = 0

            Lighting.GlobalShadows = Settings.GlobalShadows
        end,

        ["Medium"] = function()
            Settings.GlobalShadows = false
            Settings.WindEffect = false
            Settings.TreeEffect = false

            task.spawn(BuildingTexture,-1)

            for _,parts in pairs(Foliage) do
                local Particle = parts:FindFirstChildWhichIsA("ParticleEmitter")

                if Particle then
                    Particle.Enabled = false
                end
            end

            for _,buildings : Part in pairs(Buildings) do
                local Descendants = buildings:GetDescendants() 

                for _,parts : BasePart | ParticleEmitter in ipairs(Descendants) do
                    if parts:IsA("BasePart") then
                        parts.Material = TextureStorage[parts]
                    elseif parts:IsA("ParticleEmitter") then
                        -- parts.Rate /= 2 
                        parts.Enabled = false
                    end
                end
            end

            playerScripts.WindEffect.Value = Settings.WindEffect
            playerScripts.TreeEffect.Value = Settings.TreeEffect

            -- WindCheck.Text = "x"
            -- TreeCheck.Text = ""

            Lighting.EnvironmentDiffuseScale = 0.75
            Lighting.EnvironmentSpecularScale = 0
            Lighting.ShadowSoftness = 0

            Lighting.GlobalShadows = Settings.GlobalShadows
        end,

        ["High"] = function()
            Settings.GlobalShadows = true
            Settings.WindEffect = true
            Settings.TreeEffect = true

            task.spawn(BuildingTexture,-1)

            for _,parts in pairs(Foliage) do
                local Particle = parts:FindFirstChildWhichIsA("ParticleEmitter")

                if Particle then
                    Particle.Enabled = true
                end
            end

            for _,buildings : Part in pairs(Buildings) do
                local Descendants = buildings:GetDescendants() 

                for _,parts in ipairs(Descendants) do
                    if parts:IsA("BasePart") then
                        parts.Material = TextureStorage[parts]
                    elseif parts:IsA("ParticleEmitter") then
                        parts.Rate *= 2 
                        parts.Enabled = true
                    end
                end
            end

            playerScripts.WindEffect.Value = Settings.WindEffect
            playerScripts.TreeEffect.Value = Settings.TreeEffect

            -- WindCheck.Text = "x"
            -- TreeCheck.Text = "x"

            Lighting.EnvironmentDiffuseScale = 0.75
            Lighting.EnvironmentSpecularScale = 0.711

            Lighting.GlobalShadows = Settings.GlobalShadows
        end,
    }
    
    local function changeGraphics(number)
        -- CurrentTier += number
        CurrentSetting = Tiers[number]
        -- Current.Text = CurrentSetting

        if GraphicsSettings[CurrentSetting] then
            GraphicsSettings[CurrentSetting]()
        end
    end

    changeGraphics(Settings.Current)

    -- Checkbox.Text = "x"

    -- Checkbox.Activated:Connect(function()
    --     -- Change player Datastore
    --     Settings.GlobalShadows = not Settings.GlobalShadows 

    --     if Settings.GlobalShadows then
    --         Checkbox.Text = "x"
    --     else
    --         Checkbox.Text = ""
    --     end
    -- end)
    
    -- Next.Activated:Connect(function()
    --     if CurrentTier < #Tiers then
    --         changeGraphics(1)
    --     end
    -- end)

    -- Back.Activated:Connect(function()
    --     if CurrentTier > 1 then
    --         changeGraphics(-1)
    --     end
    -- end)
end

function SettingsController:EngageSettings(playerSettings)
    local FrameSettings = Settings:WaitForChild("ScrollingFrame")
    local Exit = Settings:WaitForChild("Exit")
    
    Exit.Activated:Connect(function()
        Settings.Visible = not Settings.Visible
    end)

    SettingsController:ApplyGraphics(FrameSettings.Graphics,playerSettings.Graphics)
end

function SettingsController:KnitStart()
    local Fps = 0;
    local PlayerSettings = { -- Should get from player Datastore
        Graphics = {
            Current = 3, -- 1 = Low, 2 = Medium, 3 = High
            GlobalShadows = true,
            ShadowSoftness = .02
        },

        Effects = {
            Current = 3,
        },
    }

    local CurrentGraphics = 3
    local CurrentDestructionLevel = 3
    local Tiers = {
        [1] = "Low",
        [2] = "Medium",
        [3] = "High",
    }

    local DestructionTiers = {
        [1] = "Off",
        [2] = "Medium",
        [3] = "High",
    }

    local WorldService = Knit.GetService("WorldService")
    local MatchService = Knit.GetService("MatchService")

    local Icon = TopbarUI.new()
    Icon:setLabel("Settings"):bindToggleKey(Enum.KeyCode.V):setCaption("Improve performance")

    local Graphics = TopbarUI.new()
    local TeleportTostart = TopbarUI.new()
    local DestructionLevel = TopbarUI.new()
    local TeleportToLobby = TopbarUI.new()

    TeleportTostart:setLabel("Teleport To Start"):bindEvent("selected", function()
        WorldService:RequestTeleportToStart()
    end):oneClick(true)

    TeleportTostart:setLabel("Teleport To Lobby"):bindEvent("selected", function()
        MatchService:SendToLobby()
    end):oneClick(true)

    DestructionLevel:setLabel("Destruction: High"):bindEvent("selected", function()
        local DestructionValue = workspace.Values:FindFirstChild("Destruction")
        --[[
            Medium = Only Buidlings 
            High = Buidlings and ground 
            Off = Turned off
        --]]
        CurrentDestructionLevel += 1

        if CurrentDestructionLevel > #Tiers then
            CurrentDestructionLevel = 1
        end

        if DestructionValue then
            DestructionValue.Value = CurrentDestructionLevel
            
            if DestructionValue.Value == 3 then
                for _,Parts in pairs(workspace.Map.Buildings.Maps:GetChildren()) do
                    if Parts:IsA("BasePart") then
                        Parts:SetAttribute("Destroyable", true)
                    end
                end
            else
                for _,Parts in pairs(workspace.Map.Buildings.Maps:GetChildren()) do
                    if Parts:IsA("BasePart") then
                        Parts:SetAttribute("Destroyable", false)
                    end
                end
            end
        end

        PlayerSettings.Graphics.Destruction = CurrentDestructionLevel
        DestructionLevel:setLabel("Destruction: " .. DestructionTiers[CurrentDestructionLevel])
        -- SettingsController:ApplyGraphics(Settings,PlayerSettings.Graphics)
    end):oneClick(true)

    Graphics:setLabel("Graphics: High"):bindEvent("selected",function()
        CurrentGraphics += 1

        if CurrentGraphics > #Tiers then
            CurrentGraphics = 1
        end
        
        PlayerSettings.Graphics.Current = CurrentGraphics
        Graphics:setLabel("Graphics: " .. Tiers[CurrentGraphics])
        SettingsController:ApplyGraphics(Settings,PlayerSettings.Graphics)
    end):oneClick(true)

    Icon:setDropdown({
        Graphics,
        TeleportTostart,
        DestructionLevel,
    })

    DestructionLevel:setLabel("Destruction: " .. DestructionTiers[CurrentDestructionLevel])

    local function gettotalSum(TABLE)
        local sum = 0
        for _,value in TABLE do
            sum += value
        end

        return (sum / #TABLE)
    end

    task.spawn(function()
        if RunService:IsStudio() then
            local FpsCounter = TopbarUI.new()
            local FpsStorage = {}
            local start = os.clock()
            local timer = 0
            FpsCounter:setLabel("Fps: "..Fps):setCaption("Average Fps per second")
    
            RunService.RenderStepped:Connect(function(frametime) 
                timer = timer + frametime -- Increment the timer by the time since last frame

                table.insert(FpsStorage,math.round(tonumber(1/frametime)))

                if timer >= 1 then
                    local AverageFps = gettotalSum(FpsStorage)
                    Fps = math.round(AverageFps)
                    FpsCounter:setLabel("Fps: "..Fps)

                    FpsStorage = {}
                    timer = 0
                end
            end)
        end
    end)

    task.delay(1,function()
        SettingsController:EngageSettings(PlayerSettings)
    end)
end

return SettingsController