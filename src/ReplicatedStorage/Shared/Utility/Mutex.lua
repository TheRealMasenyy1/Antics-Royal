-- Mutex is a mutual exclusion lock.
local Mutex = {__index = {}}
local playerMutexes = {}

-- Lock locks the mutex. If the lock is already in use, then the calling thread
-- blocks until the lock is available.
function Mutex.__index:Lock()
	local blocker = Instance.new("BoolValue")
	table.insert(self.blockers, blocker)
	if #self.blockers > 1 then
		blocker.Changed:Wait() -- Yield
	end
end

-- Unlock unlocks the mutex. If threads are blocked by the mutex, then the next
-- blocked mutex will be resumed.
function Mutex.__index:Unlock()
	local blocker = table.remove(self.blockers, 1)
	if not blocker then
		error("attempt to unlock non-locked mutex", 2)
	end
	if #self.blockers == 0 then
		return
	end
	blocker = self.blockers[1]
	blocker.Value = not blocker.Value -- Resume
end

-- Wrap returns a function that, when called, locks the mutex before func is
-- called, and unlocks it after func returns. The new function receives and
-- returns the same parameters as func.
function Mutex.__index:Wrap(func)
	return function(...)
		self:Lock()
		local results = table.pack(func(...))
		self:Unlock()
		return table.unpack(results, 1, results.n)
	end
end

-- NewMutex returns a new mutex.
local function NewMutex()
	return setmetatable({blockers = {}}, Mutex)
end

-- GetMutex returns a mutex associated with a player.
local function GetMutex(player)
	if playerMutexes[player] == nil then
		playerMutexes[player] = NewMutex()
	end
	return playerMutexes[player]
end

return {
	new = NewMutex,
	get = GetMutex
}