-- watcher.lua: Timer-based cursor position monitoring and color sampling

local sampler = dofile('./sampler.lua')

local watcher = {}

-- State
watcher.timer = nil
watcher.lastPos = nil
watcher.lastSprite = nil
watcher.running = false
watcher.config = nil

-- Timer tick function
local function onTick()
  pcall(function()
    if not app.editor or not app.editor.sprite then
      return
    end

    local sprite = app.editor.sprite
    local spritePos = app.editor.spritePos
    if not spritePos then return end

    -- Reset sampler cache on sprite switch
    if watcher.lastSprite ~= sprite then
      sampler.reset()
      watcher.lastSprite = sprite
      watcher.lastPos = nil
    end

    -- Skip if position hasn't changed
    if watcher.lastPos and
       watcher.lastPos.x == spritePos.x and
       watcher.lastPos.y == spritePos.y then
      return
    end

    watcher.lastPos = { x = spritePos.x, y = spritePos.y }

    -- Get current frame
    local frame = app.frame
    if not frame or frame.sprite ~= sprite then
      frame = sprite.frames[1]
    end

    -- Sample color
    local color = sampler.getColorAt(sprite, frame, spritePos.x, spritePos.y, watcher.config)
    if color then
      app.fgColor = color
    end
  end)
end

-- Start watching
function watcher.start(config)
  -- Version check: app.editor was added in v1.3
  if not app.editor then
    app.alert("RefColorSync requires Aseprite v1.3 or newer")
    return false
  end

  -- Validate reference layer if sprite is open and not using composite
  if app.sprite and not config.sampleFromComposite then
    local layer = sampler.findLayer(app.sprite.layers, config.referenceLayerName)
    if not layer then
      app.alert("Reference layer '" .. config.referenceLayerName .. "' not found in active sprite")
      return false
    end
  end

  if watcher.running then
    watcher.stop()
  end

  watcher.config = config
  watcher.lastPos = nil
  watcher.lastSprite = nil
  sampler.reset()

  -- Timer interval in seconds
  local interval = 1.0 / config.ticksPerSecond

  watcher.timer = Timer {
    interval = interval,
    ontick = onTick
  }

  watcher.timer:start()
  watcher.running = true
  return true
end

-- Stop watching
function watcher.stop()
  if watcher.timer then
    watcher.timer:stop()
    watcher.timer = nil
  end

  watcher.running = false
  watcher.lastPos = nil
  watcher.lastSprite = nil
  sampler.reset()
end

-- Check if watching is active
function watcher.isRunning()
  return watcher.running
end

-- Update config and restart if running
function watcher.updateConfig(config)
  local wasRunning = watcher.running
  if wasRunning then
    watcher.stop()
    return watcher.start(config)
  end
  watcher.config = config
  return true
end

return watcher
