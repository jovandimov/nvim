return {
    "ThePrimeagen/99",
    config = function()
        local _99 = require("99")
        local cwd = vim.uv.cwd()
        local basename = vim.fs.basename(cwd)

        _99.setup({
            -- Model to use for AI requests
            model = "anthropic/claude-opus-4-6",
            -- Debug logging to help troubleshoot issues
            logger = {
                level = _99.INFO, -- Change to _99.DEBUG for more verbose logs
                path = "/tmp/" .. basename .. ".99.debug",
                print_on_error = true,
            },
            -- Automatic context from AGENT.md files in project directories
            md_files = { "AGENT.md" },
            -- Disable cmp completion (not compatible with blink.cmp)
            completion = {
                source = nil,
            },
        })

        -- Fill in function body (AI generates implementation)
        vim.keymap.set("n", "<leader>9f", function()
            _99.fill_in_function()
        end, { desc = "99: Fill in function" })

        -- Fill in function with custom prompt
        vim.keymap.set("n", "<leader>9p", function()
            _99.fill_in_function_prompt()
        end, { desc = "99: Fill in function with prompt" })

        -- Visual selection AI (replace selection with AI response)
        vim.keymap.set("v", "<leader>9v", function()
            _99.visual()
        end, { desc = "99: Visual AI" })

        -- Visual selection with custom prompt
        vim.keymap.set("v", "<leader>9p", function()
            _99.visual_prompt()
        end, { desc = "99: Visual AI with prompt" })

        -- Stop all active AI requests
        vim.keymap.set("n", "<leader>9s", function()
            _99.stop_all_requests()
        end, { desc = "99: Stop requests" })

        -- View logs for debugging
        vim.keymap.set("n", "<leader>9l", function()
            _99.view_logs()
        end, { desc = "99: View logs" })

        -- Navigate through log history
        vim.keymap.set("n", "<leader>9[", function()
            _99.prev_request_logs()
        end, { desc = "99: Previous log" })

        vim.keymap.set("n", "<leader>9]", function()
            _99.next_request_logs()
        end, { desc = "99: Next log" })

        -- Show 99 info (rules, request count)
        vim.keymap.set("n", "<leader>9i", function()
            _99.info()
        end, { desc = "99: Info" })

        -- Send previous requests to quickfix list
        vim.keymap.set("n", "<leader>9q", function()
            _99.previous_requests_to_qfix()
        end, { desc = "99: Requests to quickfix" })

        -- Clear previous request history
        vim.keymap.set("n", "<leader>9c", function()
            _99.clear_previous_requests()
        end, { desc = "99: Clear request history" })
    end,
}
