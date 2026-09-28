-- netcoredbg from Samsung's official releases, as a Mason package.
-- mason-org's registry still ships 3.1.3, whose macOS asset is x64-only (fails with 0x80131c3c
-- on Apple Silicon). 3.2.0 publishes a native osx-arm64 build; it no longer ships osx-x64, so
-- Intel Macs are not covered here.
-- To update: bump the version in `source.id` and run :MasonUpdate / :Mason.
return {
    name = "netcoredbg",
    description = "NetCoreDbg is a managed code debugger with MI interface for CoreCLR.",
    homepage = "https://github.com/Samsung/netcoredbg",
    licenses = { "MIT" },
    languages = { ".NET", "C#", "F#" },
    categories = { "DAP" },
    source = {
        id = "pkg:github/Samsung/netcoredbg@3.2.0-1092",
        asset = {
            {
                target = "darwin_arm64",
                file = "netcoredbg-osx-arm64.zip:libexec/",
                bin = "exec:libexec/netcoredbg/netcoredbg",
            },
            {
                target = "linux_arm64_gnu",
                file = "netcoredbg-linux-arm64.tar.gz:libexec/",
                bin = "exec:libexec/netcoredbg/netcoredbg",
            },
            {
                target = "linux_x64_gnu",
                file = "netcoredbg-linux-amd64.tar.gz:libexec/",
                bin = "exec:libexec/netcoredbg/netcoredbg",
            },
            {
                target = "win_x64",
                file = "netcoredbg-win64.zip",
                bin = "netcoredbg/netcoredbg.exe",
            },
        },
    },
    bin = {
        netcoredbg = "{{source.asset.bin}}",
    },
}
