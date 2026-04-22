local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Admins = {
    [92260968] = 3,
    [204625938] = 3,
    [410916626] = 3,
}

return function (registry)
    registry:RegisterHook("BeforeRun", function(context)
        local UserId = context.Executor.UserId
        if not Admins[UserId] then
            return " You don't have permission to access this command!"
        end
    end)
end