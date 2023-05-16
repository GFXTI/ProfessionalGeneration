local objects = {}
local Get, Directory, File = loadfile("Progen/libraries/FileSystem.lua")()
local Draw = Get:"libraries":Get"Draw":Load()
local Gradient = syn.crypt.base64.decode(Get:"data":Get"Gradient":Read())

objects.Outline = function(frame)
    local lines = {
        Top1 = Draw:new("Line", frame),
        Top2 = Draw:new("Line", frame),
        Right = Draw:new("Line", frame),
        Bottom1 = Draw:new("Line", frame),
        Bottom2 = Draw:new("Line", frame),
        Left = Draw:new("Line", frame),
    }

    for i,v in lines do
        v.Thickness = 1
        v.Color = Color3.new()
    end

    Top1.From = Vector2.new(-1, -1)
    Top1.To = Vector2.new((frame.Size.X / 2) - 1, -1)
    Top2.From = Vector2.new((frame.Size.X / 2) + 1, -1)
    Top2.To = Vector2.new(frame.Size.X + 1, -1)

    Right.From = Vector2.new(frame.Size.X, -1)
    Right.To = Vector2.new(frame.Size.X, frame.Size.Y + 1)

    Bottom1.From = Vector2.new(-1, frame.Size.Y + 1)
    Bottom1.To = Vector2.new((frame.Size.X / 2) - 1, frame.Size.Y + 1)
    Bottom2.From = Vector2.new((frame.Size.X / 2) + 1, frame.Size.Y + 1)
    Bottom2.To = Vector2.new(frame.Size.X + 1, frame.Size.Y + 1)

    Left.From = Vector2.new(-1, -1)
    Left.To = Vector2.new(-1, frame.Size.Y + 1)

    return lines
end

objects.Frame = function(Properties)
    local obj = Draw:new "Square"

    for i,v in Properties do
        obj[i] = v
    end

    return obj
end

objects.GradientFrame = function(Properties)
    local obj = Draw:new "Image"
    obj.__object.Data = Gradient

    for i,v in Properties do
        obj[i] = v
    end

    return obj
end

objects.Label = function(Properties)
    local obj = Draw:new "Text"

    for i,v in Properties do
        obj[i] = v
    end

    return obj
end