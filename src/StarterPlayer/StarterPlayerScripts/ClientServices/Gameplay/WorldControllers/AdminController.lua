local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Iris = require(ReplicatedStorage.Shared.Utility.Iris).Init()

local AdminController = Knit.CreateController {
    Name = "AdminController"
}

local windowSize = Iris.State(Vector2.new(300, 400))
local WaveIsPaused = Iris.State(false)
local SpeedMultiplier = Iris.State(1)
local PauseLabel = "Pause Wave"
local PauseWave;
local GiveMoney;

local WorldService;

function AdminController.ShowAdminWindow()
    local LastNumber = 1
    local SliderArguments = {
        Increment = .1,
        Min = 0.0,
        Max = 2.0,
    }

    Iris.Window({"My Second Window"}, {size = windowSize})
        -- Iris.Text({"The current time is: " .. time()})
        Iris.Text({"[ GAME INFO ]"})
        GiveMoney = Iris.Button("Give Money")

        if GiveMoney.clicked() then
            WorldService:AdminCommands("GiveMoney")
        end

        Iris.Separator();

        Iris.Tree({"[ GAME ACTIONS ]"})
            local ClearWave = Iris.Button({"Clear Wave"}) 
            PauseWave = Iris.Button(PauseLabel)

            if ClearWave.clicked() then
                WorldService:AdminCommands("ClearWave")
            end

            if PauseWave.clicked() then
                if not WaveIsPaused.value then
                    WaveIsPaused:set(true)
                    PauseLabel = "Unpause Wave"
                else
                    WaveIsPaused:set(false)
                    PauseLabel = "Pause Wave"
                end

                WorldService:AdminCommands("PauseWave",WaveIsPaused.value)
            end
            -- Iris.Text({"Multiply Speed"})

            local Slider = Iris.SliderNum({"Speed",
                .1,
                0.0,
                2.0,
            }, {number = SpeedMultiplier})
            -- Slider.

            if Slider.numberChanged() and SpeedMultiplier.value ~= LastNumber then
                LastNumber = SpeedMultiplier.value
                -- warn("THE NEW VALUE --> ", SpeedMultiplier.value , LastNumber)
                WorldService:AdminCommands("MultiplySpeed",SpeedMultiplier.value,true) -- I WAS DOING SPEED MANIPULATION (2024-08-30)
            end

        Iris.End()

    Iris.End()
end

function AdminController:KnitInit()

end

function AdminController:KnitStart()
    WorldService = Knit.GetService("WorldService")

    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if input.KeyCode == Enum.KeyCode.F2 then
            Iris:Connect(AdminController.ShowAdminWindow)         
        end
    end)
end

return AdminController