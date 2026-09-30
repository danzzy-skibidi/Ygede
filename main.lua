local Players = game:GetService("Players")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "DanzzyTest"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Parent = gui
button.Size = UDim2.fromOffset(220,60)
button.Position = UDim2.new(0.5,-110,0.5,-30)
button.Text = "DANZZY MENU TEST"
button.TextSize = 18
button.BackgroundColor3 = Color3.fromRGB(40,40,50)
button.TextColor3 = Color3.new(1,1,1)

Instance.new("UICorner",button).CornerRadius = UDim.new(0,10)
