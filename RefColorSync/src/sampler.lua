-- sampler.lua: reads one pixel from the reference source and converts it to a Color.

local sampler = {}

local GRAY_MODE = ColorMode.GRAY or ColorMode.GRAYSCALE

-- Recursive so a reference layer nested in a group is still found.
local function findLayer(layers, name)
  for _, layer in ipairs(layers) do
    if layer.isGroup then
      local found = findLayer(layer.layers, name)
      if found then return found end
    elseif layer.name == name then
      return layer
    end
  end
  return nil
end
sampler.findLayer = findLayer

-- Raw pixel value -> Color. Alpha 0 means "transparent" in every color mode.
local function pixelToColor(px, sprite)
  local mode = sprite.colorMode

  if mode == ColorMode.RGB then
    return Color{
      r = app.pixelColor.rgbaR(px),
      g = app.pixelColor.rgbaG(px),
      b = app.pixelColor.rgbaB(px),
      a = app.pixelColor.rgbaA(px)
    }

  elseif mode == GRAY_MODE then
    local v = app.pixelColor.grayaV(px)
    return Color{ r = v, g = v, b = v, a = app.pixelColor.grayaA(px) }

  elseif mode == ColorMode.INDEXED then
    -- In indexed mode getPixel returns the palette index itself.
    if px == sprite.transparentColor then
      return Color{ r = 0, g = 0, b = 0, a = 0 }
    end
    local pal = sprite.palettes[1]
    if pal and px >= 0 and px < #pal then
      local c = pal:getColor(px)
      return Color{ r = c.red, g = c.green, b = c.blue, a = c.alpha }
    end
  end

  return nil
end

-- Composite sampling state.
local dot = nil                    -- reusable 1x1 render target
local pointSampleWorks = true      -- set false if drawSprite() rejects an offset
local cache = { image = nil, sprite = nil, frameNumber = nil, time = 0 }

local function compositePixel(sprite, frame, x, y)
  -- Fast path: render only the single pixel we need by offsetting the sprite.
  if pointSampleWorks then
    if not dot or dot.colorMode ~= sprite.colorMode then
      dot = Image(1, 1, sprite.colorMode)
    end
    dot:clear()
    local ok = pcall(function() dot:drawSprite(sprite, frame, Point(-x, -y)) end)
    if ok then return dot:getPixel(0, 0) end
    pointSampleWorks = false
  end

  -- Fallback: full composite, rebuilt at most twice per second.
  local now = os.clock()
  if cache.image == nil
     or cache.sprite ~= sprite
     or cache.frameNumber ~= frame.frameNumber
     or (now - cache.time) > 0.5 then
    local img = Image(sprite.spec)
    img:drawSprite(sprite, frame)
    cache.image = img
    cache.sprite = sprite
    cache.frameNumber = frame.frameNumber
    cache.time = now
  end
  return cache.image:getPixel(x, y)
end

-- Returns a Color, or nil when there is nothing to sample.
function sampler.getColorAt(sprite, frame, x, y, cfg)
  if not sprite or not frame then return nil end

  local px

  if cfg.sampleFromComposite then
    if x < 0 or y < 0 or x >= sprite.width or y >= sprite.height then
      return nil
    end
    px = compositePixel(sprite, frame, x, y)
  else
    local layer = findLayer(sprite.layers, cfg.referenceLayerName)
    -- Tilemap cels store tile indexes, not colors.
    if not layer or layer.isTilemap then return nil end

    local cel = layer:cel(frame.frameNumber)
    if not cel then return nil end

    local b = cel.bounds
    if x < b.x or y < b.y or x >= b.x + b.width or y >= b.y + b.height then
      return nil
    end
    px = cel.image:getPixel(x - b.x, y - b.y)
  end

  if px == nil then return nil end

  local color = pixelToColor(px, sprite)
  if not color then return nil end
  if cfg.ignoreTransparent and color.alpha == 0 then return nil end

  return color
end

-- Drop cached composite data (call on sprite switch / watcher restart).
function sampler.reset()
  cache.image = nil
  cache.sprite = nil
  cache.frameNumber = nil
  cache.time = 0
end

return sampler
