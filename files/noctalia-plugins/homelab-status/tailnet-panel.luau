local ONLINE_COLOR = "#21FEC0"
local OFFLINE_COLOR = "#FF949D"
local state = noctalia.state.get("tailnet") or { status = "loading", peers = {} }

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
    table.insert(rows, ui.label({ text = "Loading devices…", color = "on_surface_variant" }))
  elseif state.status == "error" then
    table.insert(rows, ui.label({
      text = "Could not load devices: " .. tostring(state.message or "request failed"),
      color = OFFLINE_COLOR,
      maxLines = 3,
    }))
  elseif #peers == 0 then
    table.insert(rows, ui.label({ text = "No devices returned", color = "on_surface_variant" }))
  else
    for index, peer in ipairs(peers) do
      local statusColor = peer.connected and ONLINE_COLOR or OFFLINE_COLOR
      table.insert(rows, ui.row({
        key = "tailnet-" .. tostring(index) .. "-" .. peer.name,
        gap = 10,
        paddingH = 10,
        paddingV = 8,
        align = "center",
        fill = "surface_variant/0.45",
        radius = 8,
      }, {
        ui.glyph({ name = peer.connected and "circle-check" or "circle-x", size = 17, color = statusColor }),
        ui.column({ gap = 2, flexGrow = 1 }, {
          ui.label({ text = peer.name, fontWeight = "semibold" }),
          ui.label({
            text = peer.ip ~= "" and peer.ip or "No IP address",
            color = "on_surface_variant",
            fontSize = 12,
          }),
        }),
        ui.label({ text = peer.connected and "UP" or "DOWN", color = statusColor, fontWeight = "bold" }),
      }))
    end
  end

  panel.render(ui.column({ gap = 12, padding = 14 }, {
    ui.row({ align = "center", justify = "space_between" }, {
      ui.column({ gap = 2 }, {
        ui.label({ text = "Tailnet", fontSize = 20, fontWeight = "bold" }),
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

noctalia.state.watch("tailnet", function(value)
  state = value
  render()
end)

function onOpen()
  state = noctalia.state.get("tailnet") or state
  render()
  requestRefresh()
end

function refresh()
  requestRefresh()
end

function close()
  panel.close()
end
