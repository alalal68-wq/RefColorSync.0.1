-- config.lua: Configuration storage and retrieval using Aseprite's plugin.preferences

local config = {}

-- Default configuration values
local defaults = {
  enabled = false,
  referenceLayerName = "Reference",
  ticksPerSecond = 25,
  ignoreTransparent = true,
  sampleFromComposite = false
}

-- Initialize configuration with plugin instance
function config.init(plugin)
  config.plugin = plugin

  -- Ensure preferences exist with defaults
  for key, value in pairs(defaults) do
    if plugin.preferences[key] == nil then
      plugin.preferences[key] = value
    end
  end
end

-- Get a configuration value
function config.get(key)
  if config.plugin.preferences[key] ~= nil then
    return config.plugin.preferences[key]
  end
  return defaults[key]
end

-- Set a configuration value
function config.set(key, value)
  config.plugin.preferences[key] = value
end

-- Get all current configuration as a table
function config.getAll()
  local result = {}
  for key, _ in pairs(defaults) do
    result[key] = config.get(key)
  end
  return result
end

-- Update multiple configuration values at once
function config.update(values)
  for key, value in pairs(values) do
    if defaults[key] ~= nil then
      config.set(key, value)
    end
  end
end

return config
