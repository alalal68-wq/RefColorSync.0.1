-- main.lua: Entry point for RefColorSync extension

local config = dofile('./src/config.lua')
local watcher = dofile('./src/watcher.lua')
local ui = dofile('./src/ui.lua')

function init(plugin)
  -- Initialize configuration system
  config.init(plugin)

  -- Register toggle command
  plugin:newCommand{
    id = "RefColorSyncToggle",
    title = "Toggle RefColorSync",
    group = "file_scripts",
    onclick = function()
      if watcher.isRunning() then
        watcher.stop()
        config.set("enabled", false)
      else
        local ok = watcher.start(config.getAll())
        if ok then
          config.set("enabled", true)
        end
      end
    end
  }

  -- Register settings command
  plugin:newCommand{
    id = "RefColorSyncSettings",
    title = "RefColorSync Settings...",
    group = "file_scripts",
    onclick = function()
      ui.showSettings(config, watcher)
    end
  }

  -- Restore watching state from previous session
  if config.get("enabled") then
    watcher.start(config.getAll())
  end
end

function exit(plugin)
  -- Clean shutdown: stop timer to avoid dangling callbacks
  if watcher.isRunning() then
    watcher.stop()
  end
end
