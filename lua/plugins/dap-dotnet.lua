-- .NET / C# debugging via netcoredbg (extends lazyvim.plugins.extras.lang.dotnet).
-- The helpers live in lua/dotnet (check a machine with :checkhealth dotnet).
--
-- Configurations registered for `cs`/`vb` filetypes:
--   • Build & launch project    – builds the picked .csproj/.vbproj and launches its dll with the
--                                 chosen Properties/launchSettings.json profile (env, URLs, args)
--   • Launch project (no build) – same, but skips `dotnet build` (fast relaunch)
--   • Launch dll (manual path)  – prompts for a dll path and launches it
--   • Attach to process         – attach to an already-running .NET process
-- (plus anything in a project's .vscode/launch.json, which nvim-dap reads on demand;
--  VS Code's "coreclr" type is mapped to netcoredbg).
-- The last project/profile you picked is listed first, so Run Last (<leader>dl) is quick, and
-- Run with Args (<leader>da) pre-fills the profile's commandLineArgs.
--
-- ───────────────────────────────────────────────────────────────────────────
-- Attaching the debugger to a running `dotnet watch` process
-- ───────────────────────────────────────────────────────────────────────────
--   1. Start the app in a terminal (or :terminal) from the project directory:
--          dotnet watch run
--          dotnet run --project path/to/App.csproj
--      Tip: `dotnet watch --no-hot-reload run` turns every change into a clean
--      restart, which is more predictable under a debugger (see step 4).
--   2. In Neovim, set your breakpoints, then either:
--          <leader>dA   → jump straight to the attach picker, or
--          <leader>dc   → (Continue) then pick "Attach to process (dotnet watch/run)"
--   3. In the picker choose the *application* process. It is named after the
--      project (native apphost, e.g. "MyApi") or shows as `dotnet exec …/MyApi.dll`.
--      Do NOT pick `dotnet watch`, MSBuild, or VBCSCompiler — the picker already
--      filters those out and prefers processes belonging to this workspace.
--   4. Hot reload vs restart:
--        • In-place edits keep the same PID → the debug session stays attached.
--        • "Rude" edits (e.g. changing a method signature) make `dotnet watch`
--          restart the app → new PID → the session detaches. Just re-run attach.
--
-- Rule of thumb: use a Launch config for interactive step-debugging; use Attach
-- to inspect a bug that only reproduces in an already-running `dotnet watch/run`.

return {
    -- netcoredbg from Samsung's releases via a local Mason registry (lua/dotnet/mason): native on
    -- macOS arm64 and Linux x64/arm64. The first registry wins; this list replaces Mason's default.
    {
        "mason-org/mason.nvim",
        opts = {
            registries = {
                "lua:dotnet.mason",
                "github:mason-org/mason-registry",
            },
        },
    },

    {
        "mfussenegger/nvim-dap",
        opts = function()
            local dap = require("dap")
            local dotnet = require("dotnet")

            dap.adapters.netcoredbg = dotnet.adapter
            -- VS Code launch.json files use "type": "coreclr" (nvim-dap reads .vscode/launch.json on
            -- demand; mason-nvim-dap maps coreclr to the cs filetype), so route it to netcoredbg too.
            dap.adapters.coreclr = dotnet.adapter
            require("dap.ext.vscode").type_to_filetypes.netcoredbg = { "cs", "vb" }

            -- Break when an exception escapes user code (Visual Studio's default).
            -- Change it for the running session with <leader>dx (filters: user-unhandled, all).
            for _, adapter in ipairs({ "netcoredbg", "coreclr" }) do
                dap.defaults[adapter].exception_breakpoints = { "user-unhandled" }
            end

            local cs_configs = {
                dotnet.project_launch_config("Build & launch project", true),
                dotnet.project_launch_config("Launch project (no build)", false),
                {
                    type = "netcoredbg",
                    request = "launch",
                    name = "Launch dll (manual path)",
                    program = function()
                        return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/", "file")
                    end,
                    cwd = "${workspaceFolder}",
                    env = { ASPNETCORE_ENVIRONMENT = "Development" },
                    stopAtEntry = false,
                },
                dotnet.attach_config(),
            }
            for _, ft in ipairs({ "cs", "vb" }) do
                dap.configurations[ft] = cs_configs
            end
        end,
    },

    -- mason-nvim-dap's default coreclr handler (run by LazyVim after the opts above) would
    -- replace the coreclr adapter with Mason's netcoredbg wrapper and append a
    -- "NetCoreDbg: Launch" config. The adapters above cover C#, so skip it.
    {
        "jay-babu/mason-nvim-dap.nvim",
        optional = true,
        opts = {
            handlers = {
                coreclr = function() end,
            },
        },
    },
}
