-- ui.lua: Settings dialog interface

local ui = {}

-- Show settings dialog
function ui.showSettings(config, watcher)
  local cfg = config.getAll()

  local dlg = Dialog("RefColorSync Settings")

  dlg:entry{
    id = "referenceLayerName",
    label = "Reference Layer Name:",
    text = cfg.referenceLayerName
  }

  dlg:slider{
    id = "ticksPerSecond",
    label = "Update Frequency (Hz):",
    min = 15,
    max = 40,
    value = cfg.ticksPerSecond
  }

  dlg:check{
    id = "ignoreTransparent",
    label = "Ignore Transparent Pixels",
    selected = cfg.ignoreTransparent
  }

  dlg:check{
    id = "sampleFromComposite",
    label = "Sample from Composite",
    selected = cfg.sampleFromComposite
  }

  dlg:separator()

  dlg:button{
    id = "toggleWatching",
    text = watcher.isRunning() and "Disable Watching" or "Enable Watching",
    onclick = function()
      if watcher.isRunning() then
        watcher.stop()
        config.set("enabled", false)
        dlg:modify{ id = "toggleWatching", text = "Enable Watching" }
      else
        local data = dlg.data
        config.update({
          referenceLayerName = data.referenceLayerName,
          ticksPerSecond = data.ticksPerSecond,
          ignoreTransparent = data.ignoreTransparent,
          sampleFromComposite = data.sampleFromComposite,
          enabled = true
        })
        local ok = watcher.start(config.getAll())
        if ok then
          dlg:modify{ id = "toggleWatching", text = "Disable Watching" }
        end
      end
    end
  }

  dlg:button{
    id = "save",
    text = "Save Settings",
    onclick = function()
      local data = dlg.data

      if not data.referenceLayerName or data.referenceLayerName:match("^%s*$") then
        app.alert("Reference layer name cannot be empty")
        return
      end

      local oldTps = config.get("ticksPerSecond")

      config.update({
        referenceLayerName = data.referenceLayerName,
        ticksPerSecond = data.ticksPerSecond,
        ignoreTransparent = data.ignoreTransparent,
        sampleFromComposite = data.sampleFromComposite
      })

      -- Restart watcher if running and frequency changed
      if watcher.isRunning() then
        if oldTps ~= data.ticksPerSecond then
          local ok = watcher.updateConfig(config.getAll())
          if not ok then
            config.set("enabled", false)
            dlg:modify{ id = "toggleWatching", text = "Enable Watching" }
          end
        end
      end

      app.alert("Settings saved")
    end
  }

  dlg:button{ id = "close", text = "Close" }

  dlg:show{ wait = false }
end

return ui
