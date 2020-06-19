--[[
/tank/tera Ver:1.0
Written by Tank
Contains ants
]]

local component = require("component")
local sides = require("sides")
local GUI = require("GUI")
local thread = require("thread")

local ver = 1.0
local progName = "/tank/tera"
local reactor = component.reactor_redstone_port
local inv = component.inventory_controller
local tank = component.tank_controller
local rs = component.redstone
local cap = nil
local cSide = sides.east
local rSide = sides.down

local maxHeat = reactor.getMaxHeat()
local rods = {}
local overide = false
local prog = GUI.manager()
prog.back = 0xcccccc

-----Main Window-----
-- local exit = GUI.newButton(prog, 80, 1, 1, 1, 0xff3333, 0xff3333, 0xffffff, 0xffffff, " ")
-- local title = GUI.newLabel(prog, 1, 1, prog.width, 0x333399, 0xffffff, progName.." v:"..ver)
-- title.align = "left"

-----Fuel Window-----

-----Energy Window-----

-----Program Functions-----
local function checkReactor()
  if not component.get(reactor.address) then -- See if the reactor even exists
    local rbuffer = rs.setOutput(rSide, 0) -- if not, shut off reactor
    -- TODO: some code to do UI stuff when this is happening
    for i = 1, 3 do -- Check if reactor exists again once per second for 3 seconds
      if component.get(reactor.address) then
        if rbuffer > 0 then -- Restart reactor if it was on
          rs.setOutput(rSide, 15)
        end
        -- TODO: revert UI stuff
        break
      elseif i == 3 then
        -- rs.setOutput(rSide, 0)
        -- GUI.invertTouch(false)
        -- prog:stop()
        -- error("Reactor does not exist.  Please check the block formation for explosions.")
        -- os.exit()
        return false
      end
      os.sleep(1)
    end
  end
  -- local active = reactor.getReactorEUOutput()
  -- local heat = reactor.getHeat()
  -- local heatPercent = math.floor((math.min(heat, maxHeat) / maxHeat) * 100)
  -- local coolent = tank.getFluidInTank(cSide)
  -- local coolTank = coolent[1].amount
  -- local coolPercent = math.floor((math.min(coolTank, 10000) / 10000) * 100)
  -- local hotTank = coolent[2].amount
  -- local hotPercent = math.floor((math.min(hotTank, 10000) / 10000) * 100)
  -- return {active, heat, heatPercent, coolTank, coolPercent, hotTank, hotPercent}
  return true
end

local function checkFuel(fuel, deep)
  if deep then
    fuel = {}
    for i = 1, 54 do
      local slot = inv.getStackInSlot(cSide, i)
      if slot ~= nil then
        if string.find(slot.label, "Fuel") then
          fuel[i] = slot
        end
      end
    end
  else
    for k, v in pairs(fuel) do
      fuel[k] = inv.getStackInSlot(cSide, k)
    end
  end
  return fuel
end

local function reactorControl(status)
  if not status then
    return false
  else
    if status[1] == 0 then
      print("offline") -- TODO: Actual UI stuff
    else
      print("online") -- TODO: Actual UI stuff
    end
    print(status[3])
    if overide then -- Manual shutoff
      print("SCRAM engaged") -- TODO: Actual UI stuff
      rs.setOutput(rSide, 0)
    else
      if status[3] >= 80 then -- 85% is failure, we want to stop BEFORE that.
        print("critical temps") -- TODO: Actual UI stuff
        rs.setOutput(rSide, 0)
      elseif status[3] >= 70 then -- 70% however is just radiation leaks.
          print("radwarning") -- TODO: Actual UI stuff
      end
      rods = checkFuel(rods)
      for k, v in pairs(rods) do
        if rods[k].damage == 0 then
          print("fuel depleted") -- TODO: Actual UI stuff
          -- TODO: set activator to lock until deep fuel scan
          rs.setOutput(rSide, 0)
        end
      end
    end
    return true
  end
end

local function capControl()
  -- TODO: code to automate reactor based on cacpacitor levels
end

-----Common Commands-----
local function close()
  rs.setOutput(rSide, 0)
  GUI.invertTouch(false)
  prog:stop()
  os.exit()
end

-----Button Init-----

-----Container Events-----


GUI.res(2)
GUI.invertTouch(true)
prog:start()

-- rs.setOutput(rSide, 15)

repeat
  if checkReactor() then
    local status = {active = reactor.getReactorEUOutput(),
      heat = reactor.getHeat(),
      heatPercent = math.floor((math.min(reactor.getHeat(), maxHeat) / maxHeat) * 100),
      coolent = tank.getFluidInTank(cSide),
      coolTank = tank.getFluidInTank(cSide)[1].amount,
      coolPercent = math.floor((math.min(tank.getFluidInTank(cSide)[1].amount, 10000) / 10000) * 100),
      hotTank = tank.getFluidInTank(cSide)[2].amount,
      hotPercent = math.floor((math.min(tank.getFluidInTank(cSide)[2].amount, 10000) / 10000) * 100)
    }
    reactorControl(status)
    capControl()
    os.sleep(0.25)
  else
    rs.setOutput(rSide, 0)
    GUI.invertTouch(false)
    prog:stop()
    error("Reactor does not exist.  Please check the block formation for explosions.")
    os.exit()
  end
until not prog.run