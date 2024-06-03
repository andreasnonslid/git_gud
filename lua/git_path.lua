local M = {}

local function setup()
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local previewers = require('telescope.previewers')
    local conf = require('telescope.config').values

    function M.stage_and_commit()
        pickers.new({}, {
            prompt_title = 'Git Status',
            finder = finders.new_oneshot_job({'git', 'status', '--short'}, {}),
            sorter = conf.generic_sorter({}),
            previewer = previewers.new_termopen_previewer({
                get_command = function(entry)
                    return { 'git', 'diff', entry.value:match("%s*(.-)%s*$") }
                end
            }),
            attach_mappings = function(prompt_bufnr, map)
                local function stage_and_commit()
                    local entry = action_state.get_selected_entry()
                    local file = entry.value:match("%s*(.-)%s*$")
                    vim.cmd('silent !git add -p ' .. file)
                    vim.cmd('silent !git commit -m "Interactive commit for ' .. file .. '"') -- Replace this with a prompt for a commit message
                    actions.close(prompt_bufnr)
                end
                map('i', '<CR>', stage_and_commit)
                map('n', '<CR>', stage_and_commit)
                return true
            end
        }):find()
    end
end

function M.setup()
    setup()
end

return M
