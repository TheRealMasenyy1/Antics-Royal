--!strict

local ContentProvider = game:GetService("ContentProvider")
-- local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = game:GetService("Players")

local player = PlayerService.LocalPlayer
local Assets = ReplicatedStorage.Assets

local SoundLibrary = require(ReplicatedStorage.Shared.SoundLibrary)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Knit = require(ReplicatedStorage.Packages.Knit)

local SoundController =  {}

export type SoundInfo = {
    Parent : any?;
    Name : string, --Name of sound
    Volume: number?, --Volume of the current sound default is 1
    Looped: boolean?, -- loop current sound
    Priority : number?,
}

function SoundController:LoadAllSound()    
    local Count = 0
    local function CreateSound(Name,data)
        local Sound : Sound = Instance.new("Sound")
        Sound.SoundId = data.SoundId
		Sound.Volume = data.Volume
		Sound.Looped = data.Looped
        Sound.RollOffMaxDistance = data.RollOffMaxDistance or 100
        Sound.Name = Name
        Sound.Parent = workspace.Sounds
        Sound:SetAttribute("Clonable", data.Clonable or false)

        Count += 1
        
        ContentProvider:PreloadAsync({Sound})
    end
    
    local function GetTable(DATA)
        for name,data in pairs(DATA) do
            if typeof(data) ~= "table" then
                CreateSound(name,data) 
            elseif typeof(data) == "table" then
                GetTable(data)
            end 
        end
    end
     
    for name,data in pairs(SoundLibrary) do
        if typeof(data) == "table" then
            CreateSound(name,data)    
        end
    end

    return Count
end

function SoundController:GetSound(Name)
    local SoundInWorld : Sound = workspace.Sounds:FindFirstChild(Name) or player.Character:FindFirstChild(Name) 

    if SoundInWorld and not SoundInWorld.Playing then
       return SoundInWorld
    end

    for name,Sound in pairs(self.Sounds) do
        if name == Name then
            return self.Sounds[name]:Clone()
        end
    end

    --- THIS IS JUST HERE UNTIL WE HAVE CONVERTED ALL OF THE SOUND
    for name,Sound in pairs(self.SoundData) do
        if name == Name then
            return Sound:Clone()
        end
    end
    return false
end

function SoundController:StopAll()
    for vSound, Priority in pairs(self.PlayingSounds) do
        vSound:Stop()
        self:Destroy(vSound)
    end
end

function SoundController:DeepSearch(t : {}, Key : any)
	local function deepSearch(t, key_to_find)
		for key, value in pairs(t) do
			----print(key,value)
			if (value == key_to_find) or (key == key_to_find) then
				return t, key
			end
			if typeof(value) == "table" then
				local a, b = deepSearch(value, key_to_find)
				if a then return a, b end
			end	
		end

		return nil -- if nothing was found
	end

	return deepSearch(t,Key)
end

function SoundController:Destroy(Sound)
    self.PlayingSounds[Sound] = nil
    Sound:Destroy()
end

function SoundController:KnitInit()
    self.PlayingSounds = {}
    self.Sounds = {}
    -- self.SoundAssets = Assets.Sound:GetDescendants()
end

function SoundController:ssad()
    -- self.Character = player.Character or player.CharacterAdded:Wait()
    self:LoadAllSound()
    -- --print("WHEN SOUNDCONTROLLER")
end


return SoundController