local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TimeModule = {}

local maid = require(ReplicatedStorage.Shared.Utility.maid)

function formatTimeWithHour(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

function formatTime(seconds)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", minutes, secs)
end

function formatWeek(seconds)
    local days = math.floor(seconds / (24 * 3600)) -- Calculate full days
    seconds = seconds % (24 * 3600) -- Remaining seconds after days
    local hours = math.floor(seconds / 3600) -- Calculate full hours
    seconds = seconds % 3600 -- Remaining seconds after hours
    local minutes = math.floor(seconds / 60) -- Calculate full minutes

    return string.format("%dD:%02dH:%02dM", days, hours, minutes)
end

function TimeModule:SetTimer(Name : string, Duration : number, func : any, ResetOnCompletion : boolean)
    local Maid = maid.new(); 
    Name = Name or "Challenge"
    Duration = Duration or (60 * 30)
    local dt_Time = Duration
    ResetOnCompletion = ResetOnCompletion or false

    Maid:GiveTask(RunService.Heartbeat:Connect(function(deltaTime)
        local FormattedTime = formatTime(Duration)
        func(FormattedTime,Duration)

        if dt_Time <= 0 and not ResetOnCompletion then
            Maid:Destroy()
        elseif dt_Time <= 0 and ResetOnCompletion then
            dt_Time = Duration 
        end

        dt_Time -= RunService.Heartbeat:Wait()
    end))
end

function TimeModule:SetTimerInHeartbeat(Name : string, MaxDuration : number, Duration : number, func : any, ResetOnCompletion : boolean)
    local Maid = maid.new(); 
    Name = Name or "Challenge"
    -- Duration = Duration or (60 * 30)
    local FormattedTime = formatTime(Duration)
    func(FormattedTime,Duration)

    if Duration <= 0 and not ResetOnCompletion then
        Maid:Destroy()
    -- elseif Duration <= 0 and ResetOnCompletion then
    --     Duration = MaxDuration 
    end

    -- dt_Time -= RunService.Heartbeat:Wait()
end

return TimeModule