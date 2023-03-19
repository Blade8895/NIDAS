local component = require("component")
local serialization = require("serialization")
local states         = require("server.entities.states")
local powerDisplay = {}

local gui = require("lib.graphics.gui")
local graphics = require("lib.graphics.graphics")
local renderer = require("lib.graphics.renderer")

local machineList = {}

local inView = false

local function gridAlignedX()
    return 1 + 21 * math.floor((renderer.getX() - 1) / 21)
end

local function gridAlignedY()
    return 1 + 3 * math.floor((renderer.getY() - 1) / 3)
end

-- local function genericMachine(savedX, savedY, skipRendering)
    -- local context = graphics.context()
    -- local border = gui.borderColor()
    -- local emptyBar = 0x111111
    -- local accent = gui.accentColor()
    -- local progress = gui.primaryColor()
    -- local gpu = context.gpu
    -- local xLoc = savedX or gridAlignedX()
    -- local yLoc = savedY or gridAlignedY()
    -- local page = renderer.createObject(xLoc, yLoc, 21, 3, true)
    -- gpu.setActiveBuffer(page)
    -- --Initialization
    -- local function reset(x, y, skipProgress)
        -- graphics.text(x, y*2+1, "│          ╭───", emptyBar)
        -- graphics.text(x, y*2+3, "╰──────────╯", emptyBar)
        -- if not skipProgress then
            -- graphics.text(x+12, y*2+3, "---", progress)
            -- graphics.text(x+16, y*2+3, "---s", progress)
        -- end
    -- end

    --Borders
    graphics.text(1, 1, "┎╴╶────────────────╮", border)
    graphics.text(14, 1, "╶", border)
    graphics.text(16, 3, "┭───╯", border)
    graphics.text(16, 5, "┊", border)
    graphics.text(3, 1, "Set Address", accent)
    reset(1, 1)

    local function fillBar(x, y, percentage)
        local function between(p, min, max) return (p > min and p < max) end
        local function fill(row, chars) graphics.text(x, (y*2)+(2*row)-1, chars, progress) end
        if between(percentage, 0, 13/17) then fill(1, "│") end
        if between(percentage, 1/17, 2/17) then fill(2, "╰") end
        if between(percentage, 2/17, 3/17) then fill(2, "╰─") end
        if between(percentage, 3/17, 4/17) then fill(2, "╰──") end
        if between(percentage, 4/17, 5/17) then fill(2, "╰───") end
        if between(percentage, 5/17, 6/17) then fill(2, "╰────") end
        if between(percentage, 6/17, 7/17) then fill(2, "╰─────") end
        if between(percentage, 7/17, 8/17) then fill(2, "╰──────") end
        if between(percentage, 8/17, 9/17) then fill(2, "╰───────") end
        if between(percentage, 9/17, 10/17) then fill(2, "╰────────") end
        if between(percentage, 10/17, 11/17) then fill(2, "╰─────────") end
        if between(percentage, 11/17, 12/17) then fill(2, "╰──────────") end
        if between(percentage, 12/17, 13/17) then fill(2, "╰──────────╯") end
        if between(percentage, 13/17, 14/17) then fill(1, "│          ╭") end
        if between(percentage, 14/17, 15/17) then fill(1, "│          ╭─") end
        if between(percentage, 15/17, 16/17) then fill(1, "│          ╭──") end
        if between(percentage, 16/17, 17/17) then fill(1, "│          ╭───") end
    end
    local function update(x, y, data)
        if data.state.name == states.ON.name or data.state.name == states.BROKEN.name then
            local currentProgress = data.progress
            local maxProgress = data.maxProgress
            local percentage = currentProgress / maxProgress
            fillBar(x, y, percentage)

            local currentString = ""..tostring(math.floor(currentProgress/20))
            while #currentString < 3 do currentString = " "..currentString end
            graphics.text(x+12, y*2+3, currentString, progress)
            local maxString = tostring(math.ceil(maxProgress/20)).."s"
            while #maxString < 4 do maxString = maxString.." " end
            graphics.text(x+16, y*2+3, maxString, progress)
            if maxProgress - currentProgress <= 5 then reset(x, y, true) end
            if data.state.name == states.BROKEN.name then
                graphics.text(x+1, y*2+1, "Broken", accent)
            end
        elseif data.state.name == states.IDLE.name then
            reset(x, y)
        elseif data.state.name == states.OFF.name then
            reset(x, y)
            graphics.text(x+1, y*2+1, "Disabled", 0xFF0000)
        elseif data.state.name == states.MISSING.name then
            reset(x, y)
            graphics.text(x+1, y*2+1, "Not Found", 0xFF0000)
        end
    end 
    local onActivation = {
        {displayName = "Set Address",
        value = setMachine,
        args = {}},
        {displayName = "Remove",
        value = delete,
        args = {}}
    }
    renderer.setClickable(page, gui.selectionBox, {xLoc, yLoc, onActivation}, {xLoc, yLoc}, {xLoc+20, yLoc+3})
    gpu.setActiveBuffer(0)
    if not skipRendering then renderer.update() end
    return setMachine
end
machineConstructor = genericMachine

local function returnToMenu()
    inView = false
    renderer.switchWindow("main")
    renderer.clearWindow("powerDisplay")
    renderer.update()
end

local function displayView()
    inView = true
    local context = graphics.context()
    machineList = {}
    renderer.switchWindow("powerDisplay")
    gui.smallButton(1, (context.height), "< < < Return", returnToMenu, {}, nil, gui.primaryColor())
    local divider = renderer.createObject(1, context.height - 1, context.width, 1)
    context.gpu.setActiveBuffer(divider)
    local bar = ""
    for i = 1, context.width do bar = bar .. "▂" end
    graphics.text(1, 1, bar, gui.borderColor())
    context.gpu.setActiveBuffer(0)
    local onActivation = {
        {displayName = "Add Display",
        value = genericMachine,
        args = {}}
    }
    load()
    renderer.setClickable(divider, gui.selectionBox, {gridAlignedX, gridAlignedY, onActivation}, {1, 1}, {context.width, context.height-2}, true)
end

function powerDisplay.windowButton()
    return {name = "Power Display", func = displayView}
end
--gui.bigButton(40, graphics.context().height-4, "Machines", displayView, _, _, true)

local currentConfigWindow = {}
function powerDisplay.configure(x, y, _, _, _, page)
    local renderingData = {x, y, gui, graphics, renderer, page}
    graphics.context().gpu.setActiveBuffer(page)
    renderer.update()
    return currentConfigWindow
end

function powerDisplay.update(data)
    if inView and data ~= nil then
        graphics.context().gpu.setActiveBuffer(0)
        for i = 1, #machineList do
            local machine = machineList[i]
            machine.update(machine.x, machine.y, data.multiblocks[machine.address])
        end
    end
end

return powerDisplay