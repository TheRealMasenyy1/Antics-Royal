local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function()
    local ViewportLoader = require(ReplicatedStorage.Shared.Utility.ViewportModule)

    describe("Viewport instance", function()
        it("Generated Unit Icons", function()
            local ViewportCount, MaxCount = ViewportLoader:Initialize()

            expect(MaxCount).to.be.equal(ViewportCount)
        end)

        it("Generated Item Icons", function()
            local ViewportCount, MaxCount = ViewportLoader:InitializeItems()

            expect(MaxCount).to.be.equal(ViewportCount)
        end)
    end)
end