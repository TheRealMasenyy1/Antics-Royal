
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function()
    local Animations = ReplicatedStorage.Assets.Animations
    local UnitInfo = require(ReplicatedStorage.Shared.UnitInfo).UnitInformation

    local function count(Table)
        local Count = 0
        for name, value in pairs(Table) do
            if name then
                Count += 1
            end
        end

        return Count
    end

    describe("Create Idle Animation", function()
        it("Levels have been converted to table", function()
            expect(UnitInfo).to.be.a("table")
            for Name, UnitData in pairs(UnitInfo) do
                local FolderName = string.gsub(Name, "%s", "")
                local UnitAnimations = Animations:FindFirstChild(FolderName)

                if UnitAnimations then
                    local HasIdle = UnitAnimations:FindFirstChild(Name.."Idle")

                    if not HasIdle then
                        local Animation : Animation = Instance.new("Animation")
                        Animation.Name = Name.."Idle"
                        Animation.AnimationId = "rbxassetid://"..UnitData.IdleAnim
                        Animation.Parent = UnitAnimations
                    end
                else
                    local Folder = Instance.new("Folder")
                    Folder.Name = FolderName 
                    Folder.Parent = Animations

                    local Animation : Animation = Instance.new("Animation")
                    Animation.Name = Name.."Idle"
                    Animation.AnimationId = "rbxassetid://"..UnitData.IdleAnim
                    Animation.Parent = Folder
                end
            end
        end)

        it("Should not be empty", function()
            local Count = count(UnitInfo)
            expect(Count).never.to.equal(0)
        end)
    end)
end