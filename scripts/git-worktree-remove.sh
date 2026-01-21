# Removes a pydantic-ai worktree and its branch
# Usage: source this file, then call pydantic-worktree-remove [branch-name]

pydantic-worktree-remove() {
    if [ -z "$PYDANTIC_AI_REPO" ]; then
        echo "Error: PYDANTIC_AI_REPO env var not set"
        echo "Set it to your pydantic-ai main repo path, e.g.:"
        echo "  export PYDANTIC_AI_REPO=/Users/david/projects/forks/pydantic-ai-main"
        return 1
    fi

    local branch_name
    local worktree_path

    if [ $# -eq 0 ]; then
        # No argument - check if current dir is a worktree
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
            if [ -n "$current_branch" ] && [ "$current_branch" != "HEAD" ]; then
                read "confirm?Remove current branch '$current_branch'? [y/N] "
                if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
                    echo "Aborted"
                    return 0
                fi
                branch_name="$current_branch"
            else
                echo "Usage: pydantic-worktree-remove [branch-name]"
                return 1
            fi
        else
            echo "Usage: pydantic-worktree-remove [branch-name]"
            return 1
        fi
    elif [ $# -ne 1 ]; then
        echo "Usage: pydantic-worktree-remove [branch-name]"
        return 1
    else
        branch_name="$1"
    fi

    worktree_path="$(dirname "$PYDANTIC_AI_REPO")/$branch_name"

    if [ ! -d "$worktree_path" ]; then
        echo "Error: Worktree not found at $worktree_path"
        return 1
    fi

    echo "Removing worktree: $worktree_path"
    echo "Branch: $branch_name"
    echo "Main repo: $PYDANTIC_AI_REPO"

    cd "$PYDANTIC_AI_REPO" || return 1

    git worktree remove "$worktree_path" || return 1

    # Delete the branch (use -d for safe delete, only if merged)
    git branch -d "$branch_name" || return 1

    echo "Worktree and branch removed successfully"
}
