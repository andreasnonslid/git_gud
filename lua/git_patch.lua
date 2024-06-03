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
end

function M.setup()
    setup()
end

return M
