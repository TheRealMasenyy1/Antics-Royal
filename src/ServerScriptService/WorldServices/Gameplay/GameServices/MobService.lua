local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signals = require(ReplicatedStorage.Packages.Signal)
local EntityModule = require(ReplicatedStorage.Shared.Entity)
local Maid = require(ReplicatedStorage.Shared.Utility.maid)

local MatchService

local MobService = Knit.CreateService {
    Name = "MobService",
    Create = Signals.new(),
    Remove = Signals.new(),
    RemoveAll = Signals.new(),
    Client = {
        Knockback = Knit.CreateSignal();
        TotalEntities = Knit.CreateSignal();
        PlayAnimation = Knit.CreateSignal();
        TrackHealth = Knit.CreateSignal();
        BossDialog = Knit.CreateSignal();
        BossIntro = Knit.CreateSignal()
    }
}

local GameplayFolder = workspace.Gameplay
local EntityTable = {}
local TotalEntities = 0

function Emit(Part)
	for i, v in pairs(Part:GetDescendants()) do
		if v.ClassName == "ParticleEmitter"  then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end
end

function MobService.newMobSpawn(MobInfo)
    --warn("MOB INFO --> ", MobInfo)
    local newEntity,EntityTrove = EntityModule.new(MobInfo)
    local Id = math.random(-1000,1000)
    newEntity:SetAttribute("Id",Id)
    EntityTable[Id] = EntityTrove  

    TotalEntities += 1

    if newEntity:GetAttribute("IsBoss") then
        MobService.Client.BossDialog:FireAll(newEntity,"Spawn")
    end

    MobService.Client.TrackHealth:FireAll(newEntity)
    MobService.Client.PlayAnimation:FireAll(newEntity,"WalkAnimation")

    Emit(GameplayFolder.Start)
end

function MobService.Client:RequestHit(player,UnitId : number,DamageInfo)
    
end

function MobService.RemoveMob(Id)
    for InTableId, Entity in EntityTable do
        if InTableId == Id then
            TotalEntities -= 1
            -- MobService.Client.TotalEntities:FireAll(TotalEntities,1)
            Entity:Destroy()
            return
        end
    end
end

function MobService.ClearEntities()
    for _, Entity in EntityTable do
        Entity:Destroy()
    end
end

function MobService:KnitStart()
    MobService.Create:Connect(MobService.newMobSpawn)
    MobService.Remove:Connect(MobService.RemoveMob)
end

return MobService