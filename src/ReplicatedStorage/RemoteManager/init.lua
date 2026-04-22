local RunService            = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Import = require(ReplicatedStorage.Packages.import)
local RemoteStorage         = script.Events

local KnightRemote  = nil
local KnightFunction = nil
local KnightEvent = nil

local IsClient = RunService:IsClient()
local Promise = require(ReplicatedStorage.Packages.Promise)

local RemoteManager = {
} --- This is for the Knight Framework and not to be used ingame


type RemoteTypes = {
    Client : {};
    Server : {};
}

local ListenerStorage = {
    ClientListener = {};
    ServerListener = {};
    FunctionListener = {};
}

RemoteManager.TempRequests = {}
RemoteManager.Import = Import

function RemoteManager.new(Name : string,RemoteType ,Parent : Instance?,...)
	if not IsClient then
		local self  = RemoteStorage:FindFirstChild(Name) or Instance.new(RemoteType)

		self.Name = Name
		self.Parent = Parent or RemoteStorage

		return self
	else
		local self  = RemoteStorage:FindFirstChild(Name)
		
		if self then
			return self
		end
	end
end

function RemoteManager:AwaitResponse(player : Player, Event : string, timeout : number, func : any)
	local remote : RemoteFunction = RemoteManager.new(player.UserId.."-"..Event,"RemoteFunction")
	print("Remote Created")
	remote.OnServerInvoke = func

	if timeout then
		if remote ~= nil then
			task.delay(timeout, game.Destroy, remote);
		end
	end

	return remote
end

function RemoteManager:RemoveRemote(Event : string)
	local remote = RemoteStorage:FindFirstChild(Event)
	if remote then
		remote:Destroy()
	end
end

function RemoteManager:SendRequest(Name,...) -- From client to server! but can also be used client -> server -> client
	if not IsClient then 
		error("SendRequest can only be used in client") 
	end

	local Remote = RemoteStorage:FindFirstChild(Name)
	local player = game.Players.LocalPlayer 
	local args = {...}

	if Remote then
		return Promise.new(function(resolve, cancel, reject, ...)
			if resolve then
				return resolve(Remote:InvokeServer(player, table.unpack(args)))
			end
		end):catch(function(err)
			warn(err)
		end)
	end
end

function RemoteManager:RegisterAccessPoint(Name, func)
	local newRemote : RemoteFunction = RemoteManager.new(Name,"RemoteFunction")
	newRemote.OnServerInvoke = func
end

function RemoteManager:RetriveAccessPoint(Name,...) -- Gets a server or client remote and fires it 
    local Data = RemoteManager:CheckVariables(Name,...)
    local Listener = ListenerStorage.FunctionListener[Name] or ListenerStorage.FunctionListener[table.unpack({...})] 
    
    if typeof(Data) == "table" and typeof(Data[1]) == "Instance" then
        --warn("CALLED WITH PLAYER")
        return KnightFunction:InvokeClient(Data[1],Data[2],Data[3])
    else
        --warn("\n CALLED WITHOUT PLAYER")
        return KnightFunction:InvokeServer(Name,...)    
    end
end

function RemoteManager.proccessEvent(Name,...)
    local Listener = ListenerStorage.ClientListener[Name] or ListenerStorage.ServerListener[Name] 

    if not Listener then return end
    return Listener[1](...) -- Fire the event
end

function RemoteManager:CheckVariables(Name,...)
    local player : Instance;
    local Variables;
    if typeof(Name) == "Instance" then 
        --warn("PLAYER WAS DETECTED")
        player = Name 
        Name = table.unpack({...})
        Variables = table.unpack({...},2)
        return table.pack({player,Name,Variables})[1]
    end

    --warn("PLAYER WASN'T DETECTED")
    return ...
end

function RemoteManager.proccessFunction(Name,...)
    local Data = RemoteManager:CheckVariables(Name,...) --- Used From the CheckFunction Data[1] is a player Data[2] is the Component Name Data[3] is the Variables
    local Listener = ListenerStorage.FunctionListener[Name] or ListenerStorage.FunctionListener[table.unpack({...})] 
	if not Listener then warn("Function COULDN'T BE FOUND --> ",ListenerStorage.FunctionListener) return end
    
    if  typeof(Data[1]) == "Instance" then
        --warn("CALLED WITH PLAYER")
        return Listener[1](Data[1],Data[2],Data[3]) -- Fire the event
    else
        --warn("\t CALLED WITHOUT PLAYER")
        return Listener[1](...) -- Fire the event        
    end
end

function RemoteManager:Subscribe(Name,Function)
    if IsClient then return end
    if not ListenerStorage.FunctionListener[Name] then ListenerStorage.FunctionListener[Name] = {} end
    table.insert(ListenerStorage.FunctionListener[Name],Function) 
end

function RemoteManager:Listen(Name,Function)
    if IsClient then
        if not ListenerStorage.ClientListener[Name] then ListenerStorage.ClientListener[Name] = {} end
        table.insert(ListenerStorage.ClientListener[Name],Function)         
    else
        if not ListenerStorage.ServerListener[Name] then ListenerStorage.ServerListener[Name] = {} end
        table.insert(ListenerStorage.ServerListener[Name],Function) 
    end
end

function RemoteManager:Fire(Name,...)
    return RemoteManager.proccessEvent(Name,...)
end

function RemoteManager:CreatePoints()
    if IsClient then
        KnightRemote = RemoteStorage:WaitForChild("KnightRemote")
        KnightFunction = RemoteStorage:WaitForChild("KnightFunction")
        KnightEvent = RemoteStorage:WaitForChild("KnightEvent")
    else
        KnightRemote = RemoteManager.new("KnightRemote","RemoteEvent")
        KnightFunction = RemoteManager.new("KnightFunction","RemoteFunction")
        KnightEvent = RemoteManager.new("KnightEvent","BindableEvent")
    end
end


function RemoteManager:AccessPoints()
    if IsClient then
        KnightEvent.Event:Connect(RemoteManager.proccessEvent)
        KnightFunction.OnClientInvoke = RemoteManager.proccessFunction
        KnightRemote.OnClientEvent:Connect(RemoteManager.proccessEvent)
    else
        KnightEvent.Event:Connect(RemoteManager.proccessEvent)
        KnightFunction.OnServerInvoke = RemoteManager.proccessFunction
        KnightRemote.OnServerEvent:Connect(RemoteManager.proccessEvent)
    end
end


RemoteManager:CreatePoints()
RemoteManager:AccessPoints()

return RemoteManager
