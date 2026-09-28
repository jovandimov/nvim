-- :checkhealth dotnet — everything the C#/.NET setup (OmniSharp, netcoredbg, tests) needs.
local M = {}

local health = vim.health

local function run(cmd)
    local ok, result = pcall(function()
        return vim.system(cmd, { text = true }):wait()
    end)
    if not ok or result.code ~= 0 then
        return nil
    end
    return vim.trim(result.stdout or "")
end

local function load(plugin)
    pcall(function()
        require("lazy").load({ plugins = { plugin } })
    end)
end

local function check_dotnet()
    health.start("dotnet: SDK and runtimes")
    local path = vim.fn.exepath("dotnet")
    if path == "" then
        health.error("`dotnet` is not on PATH", {
            "Install the .NET SDK (https://dot.net) and make sure `dotnet` is on PATH",
            "With mise: `mise use -g dotnet@8`",
        })
        return false
    end
    health.ok(("dotnet %s: %s"):format(run({ "dotnet", "--version" }) or "?", path))

    local sdks = run({ "dotnet", "--list-sdks" }) or ""
    if sdks == "" then
        health.error("No .NET SDK found (OmniSharp needs an SDK to load projects)")
    else
        for line in sdks:gmatch("[^\n]+") do
            health.info("SDK " .. line)
        end
    end

    -- OmniSharp 1.39 (net6 build, rollForward LatestMajor) needs a Microsoft.NETCore.App runtime >= 6.
    local runtime
    for major in (run({ "dotnet", "--list-runtimes" }) or ""):gmatch("Microsoft%.NETCore%.App (%d+)%.") do
        runtime = math.max(runtime or 0, tonumber(major))
    end
    if runtime and runtime >= 6 then
        health.ok(("Microsoft.NETCore.App %d.x runtime available"):format(runtime))
    else
        health.error("No Microsoft.NETCore.App runtime >= 6 found (needed to run OmniSharp)")
    end
    return true
end

local function check_omnisharp()
    health.start("dotnet: OmniSharp")
    load("mason.nvim")
    local has_registry, registry = pcall(require, "mason-registry")
    if has_registry and registry.has_package("omnisharp") then
        local pkg = registry.get_package("omnisharp")
        if pkg:is_installed() then
            health.ok(("omnisharp %s installed (Mason)"):format(pkg:get_installed_version() or "?"))
        else
            health.error("omnisharp is not installed", { "Run :MasonInstall omnisharp" })
        end
    end

    load("nvim-lspconfig")
    local config = vim.lsp.config.omnisharp
    local cmd = config and config.cmd
    if type(cmd) == "table" and table.concat(cmd, " "):find("RoslynExtensionsOptions:", 1, true) then
        health.ok("settings are passed to OmniSharp as command-line options")
    else
        health.error("OmniSharp is started without its settings", {
            "OmniSharp ignores LSP settings; lua/plugins/dotnet.lua must build `cmd` from them",
        })
    end

    load("omnisharp-extended-lsp.nvim")
    if pcall(require, "omnisharp_extended") then
        health.ok("omnisharp-extended-lsp.nvim available (decompiled / source-linked navigation)")
    else
        health.warn("omnisharp-extended-lsp.nvim not available: gd into framework types won't work")
    end
end

local function check_debugger()
    health.start("dotnet: debugger (netcoredbg)")
    local dotnet = require("dotnet")
    local command, err = dotnet.netcoredbg_command()
    if not command then
        health.error(err)
        return
    end

    local version = (run({ command, "--version" }) or ""):match("[^\n]+") or "?"
    health.ok(("%s: %s"):format(version, command))

    local arch = dotnet.arch_info(command)
    if arch.debugger and arch.dotnet and arch.debugger ~= arch.dotnet then
        health.error(("netcoredbg is %s but dotnet is %s (fails with 0x80131c3c)"):format(arch.debugger, arch.dotnet), {
            "Update it with :Mason (lua/dotnet/mason provides native macOS arm64 and Linux builds)",
            "Or point NETCOREDBG_PATH at a matching build",
        })
    elseif arch.debugger then
        health.ok(("architecture %s matches dotnet"):format(arch.debugger))
    end
end

local function check_tooling()
    health.start("dotnet: tooling")
    local ok, has_parser = pcall(vim.treesitter.language.add, "c_sharp")
    if ok and has_parser then
        health.ok("treesitter parser `c_sharp` installed")
    else
        health.warn("treesitter parser `c_sharp` missing", { "Run :TSInstall c_sharp" })
    end

    load("neotest-vstest")
    if pcall(require, "neotest-vstest") then
        health.ok("neotest-vstest available (tests: <leader>t…, debug nearest: <leader>td)")
    else
        health.warn("neotest-vstest not available")
    end

    if vim.fn.executable("csharpier") == 1 then
        health.ok("csharpier available (used only in projects that opt in)")
    else
        health.info("csharpier not installed (optional; only used in projects with a csharpier config)")
    end
end

function M.check()
    if check_dotnet() then
        check_omnisharp()
        check_debugger()
    end
    check_tooling()
end

return M
