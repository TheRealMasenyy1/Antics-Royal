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

local SoundController = Knit.CreateController {
    Name = "SoundController",
}

export type SoundInfo = {
    Parent : any?;
    Name : string, --Name of sound
    Volume: number?, --Volume of the current sound default is 1
    Looped: boolean?, -- loop current sound
    Priority : number?,
}

local Play = Signal.new()

function SoundController:GetSound(Name)
    local SoundStorage = ReplicatedStorage.Assets.Sounds

    for _,sound in pairs(SoundStorage:GetDescendants()) do
        if sound.Name == Name then
            return sound:Clone()
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

function SoundController:Stop(Sound : string, Destroy)
    for vSound, Priority in pairs(self.PlayingSounds) do
        if vSound.Name == Sound then
            Sound:Stop()
            if Destroy then
                self:Destroy()
            end
        end

    end
end

function SoundController:Destroy(Sound)
    self.PlayingSounds[Sound] = nil
    Sound:Destroy()
end

function SoundController:Play(Name, SoundInfo : SoundInfo)
    self = SoundController
    SoundInfo = SoundInfo or {}
    local Sound,OldParent = self:GetSound(Name,SoundInfo)

    -- SoundInfo.Parent = SoundInfo.Parent or player.Character
    if not Sound then  return end -- warn(Name, " was not found in sound assets")

    Sound.Parent = SoundInfo.Parent or player.Character
    Sound:Play()
    Sound.Volume = SoundInfo.Volume or Sound.Volume
    Sound.Looped = SoundInfo.Looped or Sound.Looped

    Sound.Ended:Connect(function()
        task.delay(1.5,function()
            if not OldParent then
                self:Destroy(Sound)
            else
                Sound.Parent = OldParent
            end 
        end)
    end)

    self.PlayingSounds[Sound.Name] = SoundInfo.Priority or 1
end

function SoundController:KnitInit()
    self.PlayingSounds = {}
    self.Sounds = {}
    self.SoundData = {}
end

function SoundController:KnitStart()
    -- self.Character = player.Character or player.CharacterAdded:Wait()

    Play:Connect(function(SoundName, SoundInfo)
        SoundController:Play(SoundName, SoundInfo)
    end)
end


return SoundController