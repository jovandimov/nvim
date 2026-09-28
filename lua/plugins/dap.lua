-- Debugger extras on top of lazyvim.plugins.extras.dap.core, shared by .NET and TypeScript:
--   <leader>dA  attach to a process (.NET or Node.js by filetype, otherwise pick a target)
--   <leader>dx  exception breakpoints for the running session
--   <leader>dL  logpoint (emulated for adapters without logpoint support, e.g. netcoredbg)
--   F5 / F9 / F10 / F11 / S-F11 / S-F5  Visual Studio-style keys

local node_filetypes = { javascript = true, javascriptreact = true, typescript = true, typescriptreact = true }

local attach_targets = {
    { label = ".NET process", filetype = "cs", name = "Attach to process (dotnet watch/run)" },
    { label = "Node.js process", filetype = "typescript", name = "Attach to Node process" },
    { label = "Chrome (port 9222)", filetype = "typescript", name = "Attach to Chrome (port 9222)" },
}

-- Run the debug configuration called `name` registered for `filetype`.
local function run_config(filetype, name)
    local dap = require("dap")
    for _, config in ipairs(dap.configurations[filetype] or {}) do
        if config.name == name then
            return dap.run(config)
        end
    end
    vim.notify(("No debug configuration %q for %s"):format(name, filetype), vim.log.levels.WARN)
end

local function attach()
    local ft = vim.bo.filetype
    if ft == "cs" or ft == "vb" then
        return run_config(attach_targets[1].filetype, attach_targets[1].name)
    elseif node_filetypes[ft] then
        return run_config(attach_targets[2].filetype, attach_targets[2].name)
    end
    vim.ui.select(attach_targets, {
        prompt = "Attach to:",
        format_item = function(target)
            return target.label
        end,
    }, function(target)
        if target then
            run_config(target.filetype, target.name)
        end
    end)
end

local function exception_breakpoints()
    local dap = require("dap")
    if not dap.session() then
        vim.notify(
            "Start a debug session first (.NET breaks on user-unhandled exceptions by default)",
            vim.log.levels.INFO
        )
        return
    end
    dap.set_exception_breakpoints()
end

local function set_logpoint()
    local message = vim.fn.input("Log point message: ")
    if message ~= "" then
        require("dap").set_breakpoint(nil, nil, message)
    end
end

-- netcoredbg does not implement DAP logpoints (no `supportsLogPoints`), so emulate them for
-- adapters without that capability: when a logpoint is hit, evaluate its {expressions} in the
-- top frame, print the message to the REPL and continue. js-debug supports logpoints natively.
-- The emulation stops and resumes the program, so it is slow inside hot loops.
local function emulate_logpoints()
    local dap = require("dap")
    dap.listeners.after.event_stopped["logpoint-emulation"] = function(session, body)
        if session.capabilities.supportsLogPoints or body.reason ~= "breakpoint" then
            return
        end
        session:request("stackTrace", { threadId = body.threadId, levels = 1 }, function(err, response)
            local frame = not err and response and response.stackFrames and response.stackFrames[1]
            local path = frame and frame.source and frame.source.path
            local bufnr = path and vim.fn.bufnr(path) or -1
            if bufnr == -1 then
                return
            end
            local logpoint
            for _, bp in ipairs(require("dap.breakpoints").get(bufnr)[bufnr] or {}) do
                if bp.line == frame.line and bp.logMessage then
                    logpoint = bp
                end
            end
            if not logpoint then
                return
            end

            local expressions, values = {}, {}
            for expression in logpoint.logMessage:gmatch("{(.-)}") do
                table.insert(expressions, expression)
            end
            local function evaluate(i)
                if i > #expressions then
                    local message = logpoint.logMessage:gsub("{(.-)}", function(expression)
                        return values[expression]
                    end)
                    require("dap.repl").append(message)
                    session:request("continue", { threadId = body.threadId }, function() end)
                    return
                end
                local expression = expressions[i]
                session:request(
                    "evaluate",
                    { expression = expression, frameId = frame.id, context = "repl" },
                    function(eval_err, result)
                        values[expression] = eval_err and ("<" .. (eval_err.message or "error") .. ">")
                            or (result and result.result)
                            or ""
                        evaluate(i + 1)
                    end
                )
            end
            evaluate(1)
        end)
    end
end

return {
    {
        "mfussenegger/nvim-dap",
        opts = emulate_logpoints,
        -- stylua: ignore
        keys = {
            { "<leader>dA", attach, desc = "Attach to Process" },
            { "<leader>dx", exception_breakpoints, desc = "Exception Breakpoints" },
            { "<leader>dL", set_logpoint, desc = "Logpoint" },
            -- Visual Studio-style keys. Terminals that send legacy codes report Shift+F5 as <F17>
            -- and Shift+F11 as <F23>, so map those too.
            { "<F5>", function() require("dap").continue() end, desc = "Debug: Run/Continue" },
            { "<F9>", function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle Breakpoint" },
            { "<F10>", function() require("dap").step_over() end, desc = "Debug: Step Over" },
            { "<F11>", function() require("dap").step_into() end, desc = "Debug: Step Into" },
            { "<S-F11>", function() require("dap").step_out() end, desc = "Debug: Step Out" },
            { "<F23>", function() require("dap").step_out() end, desc = "Debug: Step Out" },
            { "<S-F5>", function() require("dap").terminate() end, desc = "Debug: Terminate" },
            { "<F17>", function() require("dap").terminate() end, desc = "Debug: Terminate" },
        },
    },

    {
        "folke/which-key.nvim",
        optional = true,
        opts = {
            spec = {
                { "<leader>dW", group = "watches" },
            },
        },
    },
}
