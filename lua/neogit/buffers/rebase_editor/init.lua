local Buffer = require("neogit.lib.buffer")
local config = require("neogit.config")
local popup = require("neogit.lib.popup")

local commands = {
  "p",
  "r",
  "e",
  "s",
  "f",
  "x",
  "b",
  "d",
  "l",
  "t",
  "m",
  "pick",
  "reword",
  "edit",
  "squash",
  "fixup",
  "exec",
  "break",
  "drop",
  "label",
  "reset",
  "merge",
}

local function replace_rebase_command_by_line_number(rebase_buffer, new_command, current_line_number)
  local current_line = rebase_buffer:get_line(current_line_number)[1]
  if current_line == nil or current_line == "" or current_line:find("^#") ~= nil then
    return
  end
  for _, command in ipairs(commands) do
    if (current_line:find(string.format("^%s%%s", command))) ~= nil then
      local new_line = current_line:gsub(command, new_command)
      rebase_buffer:set_lines(current_line_number - 1, current_line_number, true, { new_line })
      rebase_buffer:move_cursor(current_line_number + 1)
      return
    end
  end
  print("command not supported")
end

local function replace_rebase_command(rebase_buffer, new_command)
  replace_rebase_command_by_line_number(rebase_buffer, new_command, rebase_buffer.get_current_line_number())
end

local function open_help_popup(buffer, current_line_number)
  local p = popup
    .builder()
    :name("NeogitRebaseInteractivePopup")
    :group_heading("Commands")
    :action("p", "pick", function()
      replace_rebase_command_by_line_number(buffer, "pick", current_line_number)
    end)
    :action("r", "reword", function()
      replace_rebase_command_by_line_number(buffer, "reword", current_line_number)
    end)
    :action("f", "fixup", function()
      replace_rebase_command_by_line_number(buffer, "fixup", current_line_number)
    end)
    :build()

  p:show()

  return p
end

local M = {}

function M.new(filename, on_close)
  local instance = {
    filename = filename,
    on_close = on_close,
    buffer = nil,
  }

  setmetatable(instance, { __index = M })

  return instance
end

function M:open()
  self.buffer = Buffer.create {
    name = self.filename,
    load = true,
    filetype = "NeogitRebaseTodo",
    buftype = "",
    kind = config.values.rebase_editor.kind,
    modifiable = true,
    readonly = false,
    autocmds = {
      ["BufUnload"] = function()
        self.on_close()
        vim.cmd("silent w!")
        require("neogit.process").defer_show_preview_buffers()
      end,
    },
    mappings = {
      n = {
        ["q"] = function(buffer)
          buffer:close(true)
        end,
        ["p"] = function(buffer)
          replace_rebase_command(buffer, "pick")
        end,
        ["r"] = function(buffer)
          replace_rebase_command(buffer, "reword")
        end,
        ["f"] = function(buffer)
          replace_rebase_command(buffer, "fixup")
        end,
        ["?"] = function(buffer)
          -- if this method is called inside #open_help_popup, it always return the line number of the popup
          local current_line_number = buffer:get_current_line_number()
          open_help_popup(buffer, current_line_number)
        end,
      },
    },
  }
end

return M
