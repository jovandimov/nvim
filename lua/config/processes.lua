-- Process listing and picking for debugger attach (used by the .NET and Node attach configs).
local M = {}

---@class config.Process
---@field pid integer
---@field name string full command line
---@field score? integer

-- Processes owned by the current user, excluding this Neovim.
-- `ps -A -o pid= -o uid= -o args=` is POSIX, so it behaves the same on macOS (BSD ps) and
-- Linux (procps), and ps never truncates the command when stdout is not a terminal.
---@return config.Process[]
function M.list()
    if vim.fn.has("win32") == 1 then
        return require("dap.utils").get_processes()
    end

    local result = vim.system({ "ps", "-A", "-o", "pid=", "-o", "uid=", "-o", "args=" }, { text = true }):wait()
    if result.code ~= 0 then
        return require("dap.utils").get_processes()
    end

    local uid, nvim_pid = vim.uv.getuid(), vim.fn.getpid()
    local procs = {}
    for line in (result.stdout or ""):gmatch("[^\n]+") do
        local pid, owner, args = line:match("^%s*(%d+)%s+(%d+)%s+(.+)$")
        pid, owner = tonumber(pid), tonumber(owner)
        if pid and owner == uid and pid ~= nvim_pid then
            table.insert(procs, { pid = pid, name = args })
        end
    end
    return procs
end

-- Working directory of a process (Linux: /proc, macOS: lsof), or nil when unknown.
---@param pid integer
---@return string?
function M.cwd(pid)
    local link = vim.uv.fs_readlink("/proc/" .. pid .. "/cwd")
    if link then
        return link
    end
    if vim.fn.executable("lsof") ~= 1 then
        return nil
    end
    local result = vim.system({ "lsof", "-a", "-p", tostring(pid), "-d", "cwd", "-Fn" }, { text = true }):wait()
    return result.code == 0 and (result.stdout or ""):match("\nn([^\n]+)") or nil
end

-- Let the user pick one of `candidates` (sorted by `score`, then newest first).
-- Returns the pid, or dap.ABORT when cancelled. Works inside nvim-dap's config coroutine
-- and from plain keymaps.
---@param candidates config.Process[]
---@param prompt string
function M.pick(candidates, prompt)
    table.sort(candidates, function(a, b)
        if (a.score or 0) == (b.score or 0) then
            return a.pid > b.pid
        end
        return (a.score or 0) > (b.score or 0)
    end)

    local co, is_main = coroutine.running()
    local ui = require("dap.ui")
    local pick = co and not is_main and ui.pick_one or ui.pick_one_sync
    local result = pick(candidates, prompt, function(proc)
        return string.format("%d  %s", proc.pid, proc.name)
    end)
    return result and result.pid or require("dap").ABORT
end

return M
