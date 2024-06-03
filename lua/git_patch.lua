local M = {}

local function setup()
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values

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
                    vim.cmd('Gdiffsplit ' .. file)
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
