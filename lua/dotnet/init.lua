-- Shared .NET helpers: netcoredbg resolution, project discovery, launch profiles, builds and
-- the debug configurations built on them. Used by lua/plugins/dap-dotnet.lua,
-- lua/plugins/dap.lua and `:checkhealth dotnet`.
local M = {}

local processes = require("config.processes")

local function notify(msg, level)
    vim.notify(msg, level or vim.log.levels.INFO, { title = "dap-dotnet" })
end

local function executable(path)
    return path and path ~= "" and vim.fn.executable(vim.fn.expand(path)) == 1
end

-- ───────────────────────────────────────────────────────────────────────────
-- Debugger (netcoredbg)
-- ───────────────────────────────────────────────────────────────────────────

-- Resolution order: NETCOREDBG_PATH / vim.g.netcoredbg_path, Mason (native build on macOS arm64
-- and Linux via lua/dotnet/mason), then PATH.
---@return string? command, string? err
function M.netcoredbg_command()
    local configured = vim.g.netcoredbg_path or vim.env.NETCOREDBG_PATH
    if executable(configured) then
        return vim.fn.expand(configured)
    end

    local mason = vim.fs.joinpath(vim.env.MASON or (vim.fn.stdpath("data") .. "/mason"), "bin", "netcoredbg")
    if executable(mason) then
        return mason
    end

    local path = vim.fn.exepath("netcoredbg")
    if path ~= "" then
        return path
    end

    return nil, "netcoredbg not found. Run :MasonInstall netcoredbg or set NETCOREDBG_PATH / vim.g.netcoredbg_path"
end

-- Mason installs a shell wrapper (`exec ".../netcoredbg" "$@"`); resolve it to the real binary.
local function resolve_binary(command)
    local expanded = vim.fn.expand(command)
    local ok, lines = pcall(vim.fn.readfile, expanded, "", 5)
    if ok then
        for _, line in ipairs(lines) do
            local exec_path = line:match('exec%s+"([^"]+)"')
            if exec_path then
                return exec_path
            end
        end
    end
    return expanded
end

local function normalize_arch(value)
    value = value and value:lower() or ""
    if value:find("arm64", 1, true) or value:find("aarch64", 1, true) then
        return "arm64"
    end
    if
        value:find("x86_64", 1, true)
        or value:find("x86-64", 1, true)
        or value:find("amd64", 1, true)
        or value:find("x64", 1, true)
    then
        return "x64"
    end
    return nil
end

-- Architecture of the netcoredbg binary vs. the dotnet host; a mismatch fails with 0x80131c3c.
---@return { debugger?: string, dotnet?: string, binary: string }
function M.arch_info(command)
    local binary = resolve_binary(command)
    local info = { binary = binary }
    if vim.fn.has("win32") == 1 or vim.fn.executable("file") ~= 1 then
        return info
    end

    local file_out = vim.system({ "file", "-b", binary }, { text = true }):wait()
    if file_out.code == 0 then
        info.debugger = normalize_arch(file_out.stdout)
    end
    local dotnet_info = vim.system({ "dotnet", "--info" }, { text = true }):wait()
    if dotnet_info.code == 0 then
        local out = dotnet_info.stdout or ""
        info.dotnet = normalize_arch(out:match("Architecture:%s*(%S+)") or out:match("RID:%s*%a+%-(%S+)"))
    end
    return info
end

local warned_arch = false

-- The nvim-dap adapter for netcoredbg (and VS Code's "coreclr" type).
function M.adapter(callback)
    local command, err = M.netcoredbg_command()
    if not command then
        notify(err, vim.log.levels.ERROR)
        return
    end

    if not warned_arch then
        warned_arch = true
        local arch = M.arch_info(command)
        if arch.debugger and arch.dotnet and arch.debugger ~= arch.dotnet then
            notify(
                ("netcoredbg is %s but dotnet is %s; this commonly causes 0x80131c3c. Update it with :Mason or set NETCOREDBG_PATH."):format(
                    arch.debugger,
                    arch.dotnet
                ),
                vim.log.levels.WARN
            )
        end
    end

    callback({
        type = "executable",
        command = command,
        args = { "--interpreter=vscode" },
        options = { detached = false },
    })
end

-- ───────────────────────────────────────────────────────────────────────────
-- Async helpers (nvim-dap resolves configurations, including `__call` metatables, inside a
-- coroutine, so callback-style APIs can be awaited there without blocking the UI)
-- ───────────────────────────────────────────────────────────────────────────

local function await(fn)
    local co, is_main = coroutine.running()
    assert(co and not is_main, "await() must be called from a coroutine")
    fn(function(...)
        local args = vim.F.pack_len(...)
        vim.schedule(function()
            coroutine.resume(co, vim.F.unpack_len(args))
        end)
    end)
    return coroutine.yield()
end

local function ui_select(items, opts)
    return await(function(callback)
        vim.ui.select(items, opts, callback)
    end)
end

-- Remembered choices, listed first next time so Run Last (<leader>dl) is a couple of <CR>s.
local last = { project = nil, profiles = {} }

local function preferred_first(items, preferred)
    if not preferred or not vim.tbl_contains(items, preferred) then
        return items
    end
    local ordered = { preferred }
    for _, item in ipairs(items) do
        if item ~= preferred then
            table.insert(ordered, item)
        end
    end
    return ordered
end

-- ───────────────────────────────────────────────────────────────────────────
-- Projects and launch profiles
-- ───────────────────────────────────────────────────────────────────────────

---@return string[] .csproj/.vbproj files under the cwd
function M.project_files()
    -- Prune directories that never hold projects to debug: VCS/IDE metadata, Claude Code
    -- worktrees (full copies of the solution), node_modules and build output.
    local files = vim.fn.systemlist({
        "find",
        vim.fn.getcwd(),
        "(",
        "-name",
        ".git",
        "-o",
        "-name",
        ".claude",
        "-o",
        "-name",
        ".idea",
        "-o",
        "-name",
        ".vs",
        "-o",
        "-name",
        "node_modules",
        "-o",
        "-name",
        "bin",
        "-o",
        "-name",
        "obj",
        ")",
        "-prune",
        "-o",
        "-type",
        "f",
        "(",
        "-name",
        "*.csproj",
        "-o",
        "-name",
        "*.vbproj",
        ")",
        "-print",
    })
    if vim.v.shell_error ~= 0 then
        return {}
    end
    table.sort(files)
    return files
end

-- Pick a .NET project from the workspace; nil when there is none or the pick is cancelled.
local function pick_project()
    local files = M.project_files()
    if #files == 0 then
        notify("No .NET project found under " .. vim.fn.getcwd(), vim.log.levels.ERROR)
        return nil
    end
    if #files == 1 then
        return files[1]
    end
    return ui_select(preferred_first(files, last.project), {
        prompt = "Select project to debug:",
        format_item = function(path)
            return vim.fn.fnamemodify(path, ":.")
        end,
    })
end

-- Reads JSON that may contain comments or trailing commas (VS allows both in launchSettings.json).
local function read_json(path)
    local ok, lines = pcall(vim.fn.readfile, path)
    if not ok then
        return nil
    end
    local text = table.concat(lines, "\n")
    local has_plenary, plenary_json = pcall(require, "plenary.json")
    if has_plenary then
        text = plenary_json.json_strip_comments(text)
    end
    local decoded, data = pcall(vim.json.decode, text, { luanil = { object = true, array = true } })
    return decoded and data or nil
end

-- Pick a "Project" profile from Properties/launchSettings.json (what `dotnet run`, Rider and
-- Visual Studio use). Returns the profile and its name, nil when there is none, or false when
-- cancelled.
local function pick_launch_profile(proj_dir)
    local path = vim.fs.joinpath(proj_dir, "Properties", "launchSettings.json")
    if not vim.uv.fs_stat(path) then
        return nil
    end
    local settings = read_json(path)
    if type(settings) ~= "table" or type(settings.profiles) ~= "table" then
        notify("Could not parse " .. path .. "; launching without a profile", vim.log.levels.WARN)
        return nil
    end

    local names = {}
    for name, profile in pairs(settings.profiles) do
        if type(profile) == "table" and profile.commandName == "Project" then
            table.insert(names, name)
        end
    end
    if #names == 0 then
        return nil
    end
    table.sort(names)

    local name = #names == 1 and names[1]
        or ui_select(preferred_first(names, last.profiles[proj_dir]), { prompt = "Select launch profile:" })
    if not name then
        return false
    end
    return settings.profiles[name], name
end

-- Apply a launch profile's environment variables, URLs and arguments to a launch configuration.
local function apply_launch_profile(config, profile)
    for key, value in pairs(profile.environmentVariables or {}) do
        config.env[key] = tostring(value)
    end

    -- ASPNETCORE_URLS only accepts scheme://host:port; applicationUrl may carry a path (e.g. /docs/...).
    if type(profile.applicationUrl) == "string" and not config.env.ASPNETCORE_URLS then
        local urls = {}
        for url in profile.applicationUrl:gmatch("[^;]+") do
            local base = vim.trim(url):match("^%a[%w+.-]*://[^/?#]+")
            if base then
                table.insert(urls, base)
            end
        end
        if #urls > 0 then
            config.env.ASPNETCORE_URLS = table.concat(urls, ";")
        end
    end

    if type(profile.commandLineArgs) == "string" and profile.commandLineArgs ~= "" then
        config.args = vim.split(profile.commandLineArgs, "%s+", { trimempty = true })
    end
end

-- Build the project without blocking the UI. On failure the errors go to the quickfix list.
local function build_project(project)
    local name = vim.fn.fnamemodify(project, ":t:r")
    notify("Building " .. name .. "...")
    local result = await(function(callback)
        vim.system({
            "dotnet",
            "build",
            project,
            "-c",
            "Debug",
            "--nologo",
            "-v",
            "quiet",
            "-p:MSBUILDDISABLENODEREUSE=1",
        }, { text = true }, callback)
    end)
    if result.code == 0 then
        return true
    end

    local lines = vim.split((result.stdout or "") .. (result.stderr or ""), "\n", { trimempty = true })
    local errors, seen = {}, {}
    for _, line in ipairs(lines) do
        if line:find(": error ", 1, true) and not seen[line] then
            seen[line] = true
            table.insert(errors, line)
        end
    end
    vim.fn.setqflist({}, " ", {
        title = "dotnet build " .. name,
        lines = #errors > 0 and errors or lines,
        efm = "%f(%l\\,%c): %t%*[a-z] %m",
    })
    notify(("dotnet build failed (%d errors), see :copen"):format(#errors), vim.log.levels.ERROR)
    return false
end

local function tfm_score(path)
    local tfm = path:match("/bin/Debug/([^/]+)/[^/]+%.dll$") or ""
    local major, minor = tfm:match("^net(%d+)%.(%d+)")
    if major then
        return 300000 + tonumber(major) * 1000 + tonumber(minor)
    end

    major, minor = tfm:match("^netcoreapp(%d+)%.(%d+)")
    if major then
        return 200000 + tonumber(major) * 1000 + tonumber(minor)
    end

    major, minor = tfm:match("^netstandard(%d+)%.(%d+)")
    if major then
        return 100000 + tonumber(major) * 1000 + tonumber(minor)
    end

    return tonumber(tfm:match("^net(%d+)$")) or 0
end

-- Locate the project's main Debug output dll, preferring the newest target framework.
local function locate_dll(project)
    local proj_dir = vim.fn.fnamemodify(project, ":h")
    local proj_name = vim.fn.fnamemodify(project, ":t:r")
    local matches = vim.fn.glob(proj_dir .. "/bin/Debug/*/" .. proj_name .. ".dll", false, true)
    table.sort(matches, function(a, b)
        local a_score = tfm_score(a)
        local b_score = tfm_score(b)
        if a_score == b_score then
            return a < b
        end
        return a_score < b_score
    end)
    return matches[#matches]
end

-- Launch configuration resolved when it is selected: project → launch profile → build → dll.
-- LazyVim's "Run with Args" (<leader>da) hands us `config.args` as a prompt function; the prompt
-- is then pre-filled with the profile's commandLineArgs.
---@param name string
---@param build boolean run `dotnet build` first
function M.project_launch_config(name, build)
    return setmetatable({
        type = "netcoredbg",
        request = "launch",
        name = name,
    }, {
        __call = function(config)
            local abort = vim.tbl_extend("force", config, { program = require("dap").ABORT })

            local project = pick_project()
            if not project then
                return abort
            end
            local proj_dir = vim.fn.fnamemodify(project, ":h")
            local profile, profile_name = pick_launch_profile(proj_dir)
            if profile == false or (build and not build_project(project)) then
                return abort
            end

            local dll = locate_dll(project)
            if not dll then
                notify(
                    "No Debug dll found for " .. vim.fn.fnamemodify(project, ":t") .. "; build it first",
                    vim.log.levels.ERROR
                )
                return abort
            end
            last.project = project
            last.profiles[proj_dir] = profile_name

            local launch = {
                type = "netcoredbg",
                request = "launch",
                name = config.name,
                program = dll,
                cwd = proj_dir,
                env = {
                    ASPNETCORE_ENVIRONMENT = "Development",
                    DOTNET_ENVIRONMENT = "Development",
                },
                stopAtEntry = false,
                console = "integratedTerminal",
            }
            if profile then
                apply_launch_profile(launch, profile)
            end

            if type(config.args) == "function" then
                local default = table.concat(launch.args or {}, " ")
                launch.args = function()
                    return require("dap.utils").splitstr(vim.fn.expand(vim.fn.input("Run with args: ", default)))
                end
            elseif type(config.args) == "table" then
                launch.args = config.args
            end
            return launch
        end,
    })
end

-- ───────────────────────────────────────────────────────────────────────────
-- Attach
-- ───────────────────────────────────────────────────────────────────────────

local function is_tooling_process(command)
    if command:find("msbuild", 1, true) and command:find("nodemode", 1, true) then
        return true
    end
    for _, fragment in ipairs({
        "dotnet-watch",
        "dotnet watch",
        "dotnet run",
        "dotnet build",
        "dotnet restore",
        "dotnet msbuild",
        "dotnet test",
        "netcoredbg",
        "vbcscompiler",
        "microsoft.codeanalysis.languageserver",
        "omnisharp",
    }) do
        if command:find(fragment, 1, true) then
            return true
        end
    end
    return false
end

-- Process picker tuned for .NET apps: hides the `dotnet watch` wrapper and build tooling and
-- lists processes belonging to this workspace first.
function M.pick_process()
    local projects = {}
    for _, path in ipairs(M.project_files()) do
        table.insert(projects, {
            name = vim.fn.fnamemodify(path, ":t:r"):lower(),
            dir = vim.fn.fnamemodify(path, ":h"):lower(),
        })
    end

    local candidates = {}
    for _, proc in ipairs(processes.list()) do
        local command = (proc.name or ""):lower()
        if not is_tooling_process(command) then
            for _, project in ipairs(projects) do
                if command:find(project.name, 1, true) then
                    proc.score = 100
                    break
                elseif command:find(project.dir, 1, true) and command:find("%.dll") then
                    proc.score = 90
                end
            end
            -- Last-resort fallback for framework-dependent apps launched as `dotnet App.dll`.
            if not proc.score and command:find("dotnet", 1, true) and command:find("%.dll") then
                proc.score = 10
            end
            if proc.score then
                table.insert(candidates, proc)
            end
        end
    end

    if #candidates == 0 then
        notify(
            "No .NET app process found. Wait until dotnet watch/run starts the child app, then attach again.",
            vim.log.levels.WARN
        )
        return require("dap").ABORT
    end
    return processes.pick(candidates, "Select .NET app process:")
end

function M.attach_config()
    return {
        type = "netcoredbg",
        request = "attach",
        name = "Attach to process (dotnet watch/run)",
        processId = M.pick_process,
    }
end

return M
