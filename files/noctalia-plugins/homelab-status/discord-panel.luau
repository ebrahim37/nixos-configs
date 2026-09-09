local STREAMING_COLOR = "#FF949D"
local MUTED_COLOR = "#696E77"
local state = noctalia.state.get("discord") or { status = "loading", peers = {} }

local function updatedLabel()
  if state.updatedAt == nil then
    return "Waiting for first update"
  end
  return "Updated " .. os.date("%H:%M:%S", state.updatedAt)
end

local function render()
  local peers = state.peers or {}
  local rows = {}

  if state.status == "loading" then
    table.insert(rows, ui.label({ text = "Loading voice call…", color = "on_surface_variant" }))
  elseif state.status == "error" then
    table.insert(rows, ui.label({
      text = "Could not load voice call: " .. tostring(state.message or "request failed"),
      color = STREAMING_COLOR,
      maxLines = 3,
    }))
  elseif #peers == 0 then
    table.insert(rows, ui.label({ text = "Nobody is in voice", color = "on_surface_variant" }))
  else
    for index, peer in ipairs(peers) do
      local nameColor = peer.isStreaming and STREAMING_COLOR
        or (peer.isMutedOrDeafened and MUTED_COLOR or "on_surface")
      local status = "LISTENING"
      if peer.isMutedOrDeafened then
        status = "MUTED"
      end
      if peer.isStreaming then
        status = status .. " · LIVE"
      end

      table.insert(rows, ui.row({
        key = "discord-" .. tostring(index) .. "-" .. peer.name,
        gap = 10,
        paddingH = 10,
        paddingV = 8,
        align = "center",
        fill = "surface_variant/0.45",
        radius = 8,
      }, {
        ui.glyph({
          name = peer.isMutedOrDeafened and "microphone-off" or "microphone",
          size = 17,
          color = nameColor,
        }),
        ui.column({ gap = 2, flexGrow = 1 }, {
          ui.label({ text = peer.name, color = nameColor, fontWeight = "semibold" }),
          ui.label({ text = status, color = nameColor, fontSize = 12 }),
        }),
        ui.glyph({
          name = "broadcast",
          size = 17,
          color = STREAMING_COLOR,
          visible = peer.isStreaming,
        }),
      }))
    end
  end

  panel.render(ui.column({ gap = 12, padding = 14 }, {
    ui.row({ align = "center", justify = "space_between" }, {
      ui.column({ gap = 2 }, {
        ui.label({ text = "Discord voice", fontSize = 20, fontWeight = "bold" }),
        ui.label({ text = updatedLabel(), fontSize = 12, color = "on_surface_variant" }),
      }),
      ui.row({ gap = 4, align = "center" }, {
        ui.button({ glyph = "refresh", variant = "ghost", tooltip = "Refresh", onClick = "refresh" }),
        ui.button({ glyph = "x", variant = "ghost", tooltip = "Close", onClick = "close" }),
      }),
    }),
    ui.separator({ color = "outline_variant" }),
    ui.scroll({ gap = 7, flexGrow = 1 }, rows),
  }))
end

local function requestRefresh()
  local revision = noctalia.state.get("refresh") or 0
  noctalia.state.set("refresh", revision + 1)
end

noctalia.state.watch("discord", function(value)
  state = value
  render()
end)

function onOpen()
  state = noctalia.state.get("discord") or state
  render()
  requestRefresh()
end

function refresh()
  requestRefresh()
end

function close()
  panel.close()
end
