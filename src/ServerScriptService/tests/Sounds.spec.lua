local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function()
    local SoundLoader = require(ReplicatedStorage.Shared.SoundModule)
    local SoundLibrary = require(ReplicatedStorage.Shared.SoundLibrary)
    local SoundAmount = 0

    local function count(Table)
        local Count = 0
        for name, value in pairs(Table) do
            if name then
                Count += 1
            end
        end

        return Count
    end

    describe("Sound instance", function()
        it("Generated", function()
            local SoundsCount = SoundLoader:LoadAllSound()
            local AmountSound = count(SoundLibrary)

            expect(SoundsCount).to.be.equal(AmountSound)
        end)
    end)
end