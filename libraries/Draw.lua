local Get, Directory, File = loadfile("Progen/libraries/FileSystem.lua")()
local Services, Easing, Math, Tween = Get:Get"libraries":Get"Services":Load(), Get:Get"libraries":Get"Easing":Load(), Get:Get"libraries":Get"Math":Load(Get), Get:Get"libraries":Get"Tween":Load(Get)

local DeltaIter, Lerp = Math.DeltaIter, Math.Lerp

local DraggableObjs = {} do
    local Connection

    Services.Input.InputBegan:Connect(function(input, ret)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            for _, frame in DraggableObjs do
                if frame:MouseInFrame() and frame.Visible and frame.Opacity ~= 0 then
                    local _continue

                    for __, descendant in frame:Children(true) do
                        if (descendant.Active and descendant:IsInFrame() and descendant.Opacity ~= 0 and descendant.__object.Visible and frame.__object.Main.ZIndex <= descendant.__object.Main.ZIndex) then
                            _continue = true

                            break
                        end
                    end

                    if _continue then continue end

                    if Connection then
                        Connection:Disconnect()
                    end

                    local mp = Services.Input:GetMouseLocation()
                    local offset = (frame.Parent and frame.__object.Position - mp or mp) - frame.Position

                    Connection = Services.Input.InputChanged:Connect(function()
                        frame.Position = (frame.Parent and frame.Parent.Position or Vector2.zero) + mp - offset
                    end)
                end
            end
        end
    end)
end

local ScrollableObjs = setmetatable({}, {__newindex = function(self, key, value)
    if key.__properties.ScrollBarThickness ~= 0 then
        local t1, t2

        key.MouseEnter:Connect(function()
            t1 = true
            local localinterrupttween = false

            DeltaIter(0, 1, 50, function(inc)
                if t2 or localinterrupttween then
                    localinterrupttween = true
                    return
                end
                inc = Easing.Out.Quad(inc)
                value.DrawFill.Opacity = inc
                value.DrawOutline.Opacity = inc
            end)

            t1 = false
        end)

        key.MouseLeave:Connect(function()
            t2 = true
            local localinterrupttween = false

            DeltaIter(1, 0, 50, function(inc)
                if t1 or localinterrupttween then
                    localinterrupttween = true
                    return
                end
                inc = Easing.Out.Quad(inc)
                value.DrawFill.Opacity = inc
                value.DrawOutline.Opacity = inc
            end)

            t2 = false
        end)
    end

    local connection = key.Changed:Connect(function()
        value.DrawFill.Filled = true -- kms
        value.DrawFill.Color = key.__properties.ScrollbarColor
        value.DrawFill.Size = Vector2.new(key.__properties.ScrollBarThickness, 8 - (key.__object.Size.Y / key.ScrollSize))
        value.DrawFill.Position = key.__object.Position + Vector2.new(key.__object.Size.X - 4 - key.__properties.ScrollBarThickness, 4)
        value.DrawFill.ZIndex = key.__object.ZIndex + 1
        value.DrawFill.Visible = key.__properties.ScrollBarThickness ~= 0
        value.DrawFill.Opacity = 0

        value.DrawOutline.Color = key.__properties.ScrollbarOutlineColor
        value.DrawOutline.Size = value.DrawFill.Size + Vector2.new(2, 2)
        value.DrawOutline.Position = value.DrawFill.Position - Vector2.new(1, 1)
        value.DrawOutline.Thickness = 2
        value.DrawOutline.ZIndex = value.DrawFill.ZIndex
        value.DrawOutline.Visible = key.__properties.ScrollBarThickness ~= 0
        value.DrawOutline.Opacity = 0
    end)

    rawset(self, key, value)
end}) do
    Services.Input.InputChanged:Connect(function(input, ret)
        if ret then return end

        if input.UserInputType == Enum.UserInputType.MouseWheel then
            local up = input.Position.Z > 0

            for frame, scrollbar in ScrollableObjs do
                if frame.__scrolling.YPosition <= 0 and not up then continue end
                if frame.__scrolling.YPosition >= frame.__properties.ScrollSize and up then continue end
                local samount, ypos = frame.__properties.ScrollAmount, frame.__scrolling.YPosition
                frame.__scrolling.YPosition += (up and 1 or -1) * frame.ScrollAmount

                if frame:MouseInFrame() and frame.Visible and frame.Opacity ~= 0 then
                    DeltaIter(up and 0 or 1, up and 1 or 0, 50, function(inc)
                        inc = Easing.Out.Quad(inc)

                        for i,v in frame:Children(true) do
                            if v.__properties.IgnoreScrolling then continue end

                            if v.Class == "Line" then
                                v.__object.To = Vector2.new(v.__object.To.X, frame.Position.Y + v.To.Y + Lerp(ypos, ypos + samount, inc))
                                v.__object.From = Vector2.new(v.__object.from.X, frame.Position.Y + v.From.Y + Lerp(ypos, ypos + samount, inc))

                                continue
                            end

                            v.__object.Position = Vector2.new(v.__object.Position.X, frame.Position.Y + v.Y + Lerp(ypos, ypos + samount, inc))

                            if v.__object.Position.Y + v.__object.Size.Y > frame.__object.Position.Y + frame.__object.Size.Y - 2 or v.__object.Position.Y < frame.__object.Position.Y + 2 then
                                v.__object.Visible = false
                            end
                        end

                        scrollbar.DrawFill.Position = frame.__object.Position + Vector2.new(frame.__object.Size.X - 4 - frame.__properties.ScrollBarThickness, 4) + Vector2.new(0, Lerp(0, frame.__object.Size.Y - 6 - scrollbar.DrawFill.Size.Y, ypos / frame.__properties.ScrollSize))
                    end)
                end
            end
        end
    end)
end

local Draw = {}

Draw.__index = function(self, key)
    return Draw[key] or self.__properties[key] or self.__children[key] or (self.__connections[key] and self.__connections[key].Event) or error(`{key} is not a valid member of {self.Name}`)
end
Draw.__newindex = function(self, key, value)
    self.__connections.Changed:Fire(key, value)

    if key == "Parent" then
        if value then
            table.insert(self, value.__children)

            Draw.__newindex(self, "Position", self.Position)
        end

        if self.__properties.Parent then
            table.remove(self.__properties.Parent, table.find(self.__properties.Parent, self))
        end

        self.__properties.Parent = value
    end

    if key == "Draggable" then
        if not value and not table.find(DraggableObjs, self) then return end
        table[value and "insert" or "remove"](DraggableObjs, value and self or table.find(DraggableObjs, self))
    end

    if key == "Scrollable" then
        if not value and not ScrollableObjs[self] then return end
        ScrollableObjs[self] = value and {
            DrawFill = Drawing.new "Square", -- this will most likely get gc'd if u dont mention scrolling at all (which is good)
            DrawOutline = Drawing.new "Square"
        } or nil
    end

    if key == "Position" then
        local pos, parent = Vector2.zero, self.__properties.Parent

        while parent do
            parent = parent.__properties.Parent

            if parent then
                pos += parent.__properties.Position
            end
        end

        for _, descendant in self:Children(true) do
            if descendant.__properties.Class ~= "Line" then
                descendant.__object.Position = descendant.__object.Position + (self.__object.Position - descendant.__object.Position)

                continue
            end

            descendant.__object.To = descendant.__object.To + (self.__object.Position - descendant.__object.To)
            descendant.__object.From = descendant.__object.From + (self.__object.Position - descendant.__object.From)
        end

        self.__properties[key] = value

        return
    end

    if key == "ZIndex" then
        local zindex, parent = self.__properties.ZIndex, self.__properties.Parent

        while parent do
            parent = parent.__properties.Parent

            if parent then
                zindex += parent.__properties.ZIndex
            end
        end

        self.__object.ZIndex = zindex
        self.__properties[key] = value

        return
    end

    if key == "Visible" then
        for _, descendant in self:Children(true) do
            descendant.__object.Visible = descendant.Visible and value or false
        end
    end

    if self.__object[key] then
        self.__object[key] = value
    end

    self.__properties[key] = value
end
Draw.__tostring = function(self)
    return self.__properties.Name
end

function Draw.Children(self, recursive)
    local children = {}

    for idx, child in self.__children do
        table.insert(children, child)

        if recursive then
            for _, descendant in child.__children do
                table.insert(children, descendant)
            end
        end
    end

    return children
end

function Draw.Tween(...)
    Tween:new(...):Play()
end

function Draw.Destroy(self)
    self.Object:Destroy()

    for i,v in self:Children(true) do
        v.Object:Destroy()
    end
end

function Draw.MouseInFrame(self)
    local Mouse = Services.Input:GetMouseLocation()
    local Pos = self.__object.Position or self.__object.PointB 
    local Size = typeof(self.__object.Size) == "Vector2" and self.__object.Size or self.__object.TextBounds

    return Pos.Y < Mouse.Y and Mouse.Y < Pos.Y + Size.Y and Pos.X < Mouse.X and Mouse.X < Pos.X + Size.X
end

function Draw.Find(self, name, recursive)
    for i,v in self.__children do
        if v.Name == name then
            return v
        end
    end

    if recursive then
        for i,v in self:Children(true) do
            if v.Name == name then
                return v
            end
        end
    end
end

function Draw.ChildrenOfClass(self, type, recursive)
    local children = {}

    for idx, child in self.__children do
        if self.__properties.Class ~= type then continue end
        table.insert(children, child)

        if recursive then
            for _, descendant in child.__children do
                if self.__properties.Class ~= type then continue end
                table.insert(children, descendant)
            end
        end
    end

    return children
end

function Draw.FindOfClass(self, type, recursive)
    for i,v in self.__children do
        if v.Class == type then
            return v
        end
    end

    if recursive then
        for i,v in self:Children(true) do
            if v.Class == type then
                return v
            end
        end
    end
end

function Draw.SetAttribute(self, key, value)
    self.__attributes[key] = value
end

function Draw.GetAttribute(self, key)
    return self.__attributes[key]
end

function Draw.Set(self, idx, idx2, val)
    if idx == "object" then
        self.__object[idx] = idx2

        return
    end

    self[`__{idx}`][idx2] = val
end

local function GetDefaultConnections(obj)
    local cons = {}
    local inframe

    cons.Button1Down = Instance.new "BindableEvent"
    cons.Button2Down = Instance.new "BindableEvent"
    cons.Button1Up = Instance.new "BindableEvent"
    cons.Button2Down = Instance.new "BindableEvent"
    cons.MouseEnter = Instance.new "BindableEvent"
    cons.MouseLeave = Instance.new "BindableEvent"
    cons.Changed = Instance.new "BindableEvent"

    Services.Input.InputBegan:Connect(function(input, ret)
        if ret or not obj.__properties.Active or not obj.__object.Visible or obj.__object.Opacity == 0 or not obj:MouseInFrame() then return end
        local mp = Services.Input:GetMouseLocation()

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            cons.Button1Down:Fire(mp)
            while Services.Input.InputLost:Wait().UserInputType ~= Enum.UserInputType.MouseButton1 do end
            cons.Button1Up:Fire(Services.Input:GetMouseLocation())

            return
        end

        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            cons.Button2Down:Fire(mp)
            while Services.Input.InputLost:Wait().UserInputType ~= Enum.UserInputType.MouseButton2 do end
            cons.Button2Up:Fire(Services.Input:GetMouseLocation())
        end
    end)

    Services.Input.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement or not obj.__properties.Active or not obj.__object.Visible or obj.__object.Opacity == 0 or not obj:MouseInFrame() then return end

        if inframe and not obj:MouseInFrame() then
            inframe = false
            cons.MouseLeave:Fire()

            return
        end

        if not inframe and obj:MouseInFrame() then
            inframe = true
            cons.MouseEnter:Fire()
        end
    end)

    return cons
end

function Draw:new(Type, parent)
    local obj = Drawing.new(Type)
    local properties = {
        -- Dragging
        Draggable = false,
        -- Scrolling
        Scrollable = false,
        IgnoreScrolling = false,
        ScrollSize = 200,
        ScrollAmount = 20,
        ScrollbarColor = Color3.new(1, 1, 1),
        ScrollBarThickness = 4,
        ScrollbarOutlineColor = Color3.new(.1, .1, .1),
        -- Universal
        Name = Type,
        Class = Type,
        Parent = parent,
        Active = false,
        -- Defaualt properties
        Visible = true,
        Opacity = 1,
        ZIndex = 0,
        Color = Color3.new(1, 1, 1),
    }

    local mt = setmetatable({__properties = properties, __children = {}, __object = obj, __attributes = {}, __connections = {}, __scrolling = {
        YPosition = 0,
    }}, Draw)

    for i,v in GetDefaultConnections(mt) do
        mt.__connections[i] = v
    end

    if Type == "Line" then
        properties["To"] = Vector2.zero
        properties["From"] = Vector2.zero
    end

    if Type == "Image" then
        properties["Rounding"] = 0
        properties["Size"] = Vector2.new(200, 200)
        properties["Position"] = Vector2.zero
        properties["Data"] = ""
    end

    if Type == "Text" then
        properties["Text"] = ""
        properties["Size"] = 18
        properties["Centered"] = false
        properties["Outlined"] = true
        properties["OutlineColor"] = Color3.new()
        properties["Position"] = Vector2.zero
        properties["Font"] = Drawing.Fonts["Monospace"]
    end

    if Type == "Square" then
        properties["Position"] = Vector2.zero
        properties["Size"] = Vector2.new(200, 200)
        properties["Thickness"] = 2
        properties["Filled"] = true
    end

    if Type == "Circle" then
        properties["Radius"] = 20
        properties["Position"] = Vector2.zero
        properties["NumSides"] = 150
        properties["Filled"] = false
        properties["Thickness"] = 2
    end

    return mt
end

return Draw, Easing
