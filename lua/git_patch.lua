local M = {}

local function setup()
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values

    local function diff_file(file)
        local bufnr = vim.fn.bufnr(file, true)
        if bufnr == -1 then
            bufnr = vim.fn.bufadd(file)
        end

        vim.fn.bufload(bufnr)
        vim.api.nvim_set_current_buf(bufnr)
        vim.cmd('diffthis')

        local temp_buf = vim.api.nvim_create_buf(false, true)
        local temp_file = vim.fn.tempname()
        vim.fn.system('git show :' .. file .. ' > ' .. temp_file)
        vim.fn.bufload(temp_buf)
        vim.api.nvim_buf_set_lines(temp_buf, 0, -1, false, vim.fn.readfile(temp_file))
        vim.cmd('vsp')
        vim.api.nvim_set_current_buf(temp_buf)
        vim.cmd('diffthis')
    end

    local function stage_hunk()
        vim.cmd('normal! gv')
        local bufnr = vim.api.nvim_get_current_buf()
        local line_start = vim.fn.line("v")
        local line_end = vim.fn.line(".")
        vim.cmd('write')
        local temp_file = vim.fn.tempname()
        vim.fn.system('git diff -U0 > ' .. temp_file)
        vim.cmd('vsp')
        local temp_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(temp_buf, 0, -1, false, vim.fn.readfile(temp_file))
        vim.api.nvim_set_current_buf(temp_buf)
        vim.cmd('diffthis')
        vim.fn.system('git apply --cached --unidiff-zero --index < ' .. temp_file)
        vim.cmd('bd')
    end

    local function git_add_patch()
        vim.cmd('write')
        local temp_file = vim.fn.tempname()
        vim.fn.system('git diff > ' .. temp_file)
        local lines = vim.fn.readfile(temp_file)
        local hunks = {}
        local current_hunk = {}

        for _, line in ipairs(lines) do
            if line:sub(1, 3) == '@@ ' then
                if #current_hunk > 0 then
                    table.insert(hunks, table.concat(current_hunk, '\n'))
                    current_hunk = {}
                end
            end
            table.insert(current_hunk, line)
        end

        if #current_hunk > 0 then
            table.insert(hunks, table.concat(current_hunk, '\n'))
        end

        for _, hunk in ipairs(hunks) do
            local choice = vim.fn.input('Stage this hunk? (y/n): ')
            if choice:lower() == 'y' then
                local hunk_file = vim.fn.tempname()
                vim.fn.writefile(vim.split(hunk, '\n'), hunk_file)
                vim.fn.system('git apply --cached ' .. hunk_file)
            end
        end

        vim.cmd('bd')
    end

    function M.stage_and_commit()
        pickers.new({}, {
            prompt_title = 'Git Status',
            finder = finders.new_oneshot_job({
                'git', 'status', '--porcelain'
            }, {
                entry_maker = function(entry)
                    local file = entry:sub(4)
                    return {
                        value = file,
                        display = file,
                        ordinal = file
                    }
                end
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
                local function show_diff()
                    local entry = action_state.get_selected_entry()
                    local file = entry.value
                    actions.close(prompt_bufnr)
                    diff_file(file)
                end
                map('i', '<CR>', show_diff)
                map('n', '<CR>', show_diff)
                return true
            end
        }):find()
    end

    function M.setup()
        vim.api.nvim_set_keymap('v', '<leader>gs', ':lua require("git_patch").stage_hunk()<CR>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '<leader>ga', ':lua require("git_patch").git_add_patch()<CR>', { noremap = true, silent = true })
    end

    return M
end

return setup()
