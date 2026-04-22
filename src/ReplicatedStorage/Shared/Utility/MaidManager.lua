local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MaidManager = {}
MaidManager.__index = MaidManager

local Maid = require(ReplicatedStorage.Shared.Utility.maid)

function MaidManager.new()
    local self = setmetatable({}, MaidManager)
    self._maids = {}
    return self
end

function MaidManager:AddMaid(Element : any, TaskUniqueId : string, task)
    local TaskId = TaskUniqueId or #self._maids[Element] + 1

    if self._maids[Element] and self._maids[Element][TaskUniqueId] then
        -- warn("Task: ", TaskUniqueId," for ", Element ," has been cleaned")
        self._maids[Element][TaskUniqueId]:Destroy()
    elseif not self._maids[Element] then 
        self._maids[Element] = {}
    end
    
    self._maids[Element][TaskUniqueId] = Maid.new()
    self._maids[Element][TaskUniqueId]:GiveTask(task)

    return self._maids[Element][TaskUniqueId]
end

function MaidManager:Destroy(MaidName : string, TaskId)
    local findMaid = table.find(self._maids[MaidName],TaskId)
    if findMaid and MaidName then
        self._maids[MaidName][findMaid]:Destroy()
    else
        for _,maids in ipairs(self._maids[MaidName]) do
            maids:Destroy()
        end
    end
end

return MaidManager