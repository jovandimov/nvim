-- TypeScript/JavaScript debug configurations.
-- The js-debug adapters (pwa-node / pwa-chrome / pwa-msedge and their aliases) are registered by
-- lazyvim.plugins.extras.lang.typescript, which also installs js-debug-adapter via Mason.
local skip_files = { "<node_internals>/**", "**/node_modules/**" }
local source_map_locations = { "${workspaceFolder}/**", "!**/node_modules/**" }

-- Node processes that belong to the editor or AI tooling rather than your app.
local tooling = {
    "/mason/", -- language servers / debug adapters installed by Mason
    "copilot",
    "language-server",
    "languageserver",
    "tsserver",
    "typingsinstaller",
    "--lsp",
    "biome",
    "eslint_d",
    "prettierd",
    "dapdebugserver", -- js-debug itself
    "/.claude/", -- Claude Code skill scripts
    "/_npx/", -- npx-run tools such as MCP servers
}

-- Node process picker: hides tooling and lists processes of the current workspace first
-- (matched on the command line or the process's working directory).
local function pick_node_process()
    local processes = require("config.processes")
    local workspace = vim.fn.getcwd()
    local candidates = {}
    for _, proc in ipairs(processes.list()) do
        local command = proc.name:lower()
        local exe = vim.fs.basename(command:match("^(%S+)") or "")
        local is_tooling = vim.iter(tooling):any(function(fragment)
            return command:find(fragment, 1, true) ~= nil
        end)
        if (exe == "node" or exe == "nodejs") and not is_tooling then
            local cwd = processes.cwd(proc.pid) or ""
            local in_workspace = command:find(workspace:lower(), 1, true) or vim.startswith(cwd, workspace)
            proc.score = in_workspace and 100 or 10
            table.insert(candidates, proc)
        end
    end
    if #candidates == 0 then
        vim.notify("No Node.js process found", vim.log.levels.WARN, { title = "dap-typescript" })
        return require("dap").ABORT
    end
    return processes.pick(candidates, "Select Node.js process:")
end

return {
    {
        "mfussenegger/nvim-dap",
        opts = function()
            local dap = require("dap")

            local configs = {
                -- Debug the app in Chrome; start the dev server first (`pnpm start`, port 3000 in ToolbarApp)
                {
                    type = "pwa-chrome",
                    request = "launch",
                    name = "Launch Chrome (Vite dev server)",
                    url = function()
                        return vim.fn.input("URL: ", "http://localhost:3000")
                    end,
                    webRoot = "${workspaceFolder}",
                    -- Browser binary override, e.g. Chromium on Linux (default: installed Chrome)
                    runtimeExecutable = vim.env.CHROME_PATH,
                    sourceMaps = true,
                    skipFiles = skip_files,
                },
                -- Attach to a browser started with --remote-debugging-port=9222
                {
                    type = "pwa-chrome",
                    request = "attach",
                    name = "Attach to Chrome (port 9222)",
                    port = 9222,
                    webRoot = "${workspaceFolder}",
                    sourceMaps = true,
                    skipFiles = skip_files,
                },
                -- Attach to a running Node process picked from a list
                {
                    type = "pwa-node",
                    request = "attach",
                    name = "Attach to Node process",
                    processId = pick_node_process,
                    cwd = "${workspaceFolder}",
                    sourceMaps = true,
                    skipFiles = skip_files,
                    resolveSourceMapLocations = source_map_locations,
                },
                -- Attach to a process started with --inspect (default port 9229)
                {
                    type = "pwa-node",
                    request = "attach",
                    name = "Attach to process (port 9229)",
                    port = 9229,
                    cwd = "${workspaceFolder}",
                    sourceMaps = true,
                    skipFiles = skip_files,
                    resolveSourceMapLocations = source_map_locations,
                },
                -- Attach with custom port
                {
                    type = "pwa-node",
                    request = "attach",
                    name = "Attach (pick port)",
                    port = function()
                        return tonumber(vim.fn.input("Port: ", "9229"))
                    end,
                    cwd = "${workspaceFolder}",
                    sourceMaps = true,
                    skipFiles = skip_files,
                    resolveSourceMapLocations = source_map_locations,
                },
                -- Launch current file with node (Node 22.18+/23.6+ runs .ts files natively via type stripping)
                {
                    type = "pwa-node",
                    request = "launch",
                    name = "Launch file (node)",
                    program = "${file}",
                    cwd = "${workspaceFolder}",
                    sourceMaps = true,
                    skipFiles = skip_files,
                    resolveSourceMapLocations = source_map_locations,
                },
                -- Launch current file with tsx
                {
                    type = "pwa-node",
                    request = "launch",
                    name = "Launch file (tsx)",
                    runtimeExecutable = "tsx",
                    runtimeArgs = { "${file}" },
                    cwd = "${workspaceFolder}",
                    sourceMaps = true,
                    skipFiles = skip_files,
                    resolveSourceMapLocations = source_map_locations,
                },
            }

            for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
                dap.configurations[language] = configs
            end
        end,
    },
}
