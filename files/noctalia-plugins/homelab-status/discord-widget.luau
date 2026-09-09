local STREAMING_COLOR = "#FF949D"
local MUTED_COLOR = "#696E77"
local state = noctalia.state.get("discord") or { status = "loading", peers = {} }

local function render()
  local peers = state.peers or {}
  local children = {
    ui.glyph({
      name = "brand-discord",
      size = 14,
      color = state.status == "error" and STREAMING_COLOR or "on_surface",
    }),
  }

  if state.status == "loading" then
    table.insert(children, ui.label({ text = "…", color = "on_surface_variant" }))
    barWidget.setTooltip("Loading Discord call")
    barWidget.setVisible(true)
  elseif state.status == "error" then
    table.insert(children, ui.label({ text = "ERR", color = STREAMING_COLOR }))
    barWidget.setTooltip("Discord: " .. tostring(state.message or "request failed"))
    barWidget.setVisible(true)
  elseif #peers == 0 then
    barWidget.setVisible(false)
  else
    local tooltip = {}
    for _, peer in ipairs(peers) do
      table.insert(tooltip, peer.name)

      table.insert(children, ui.label({
        text = peer.name,
        color = peer.isStreaming and STREAMING_COLOR
          or (peer.isMutedOrDeafened and MUTED_COLOR or "on_surface"),
      }))
    end
    barWidget.setTooltip(table.concat(tooltip, "\n"))
    barWidget.setVisible(true)
  end

  local container = barWidget.isVertical() and ui.column or ui.row
  barWidget.render(container({ gap = 6, align = "center" }, children))
end

noctalia.state.watch("discord", function(value)
  state = value
  render()
end)
noctalia.setUpdateInterval(30000)
render()

function update()
  state = noctalia.state.get("discord") or state
  render()
end

function onClick()
  local revision = noctalia.state.get("refresh-discord") or 0
  noctalia.state.set("refresh-discord", revision + 1)
end
