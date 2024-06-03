local git_patch = require('git_patch')

return {
    setup = git_patch.setup,
    stage_and_commit = git_patch.stage_and_commit,
    stage_hunk = git_patch.stage_hunk,
    git_add_patch = git_patch.git_add_patch
}
