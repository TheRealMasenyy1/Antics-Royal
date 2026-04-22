local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function()
    local LevelInfo = require(ReplicatedStorage.Difficulties)

    local function count(Table)
        local Count = 0
        for name, value in pairs(Table) do
            if name then
                Count += 1
            end
        end

        return Count
    end

    describe("Levels Converted", function()
        it("Levels have been converted to table", function()
            expect(LevelInfo).to.be.a("table")
        end)

        it("Should not be empty", function()
            local Count = count(LevelInfo)
            expect(Count).never.to.equal(0)
        end)
    end)
end