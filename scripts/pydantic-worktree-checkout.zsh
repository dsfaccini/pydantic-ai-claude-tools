# Checks out an existing upstream branch as a worktree (useful for PRs)
# Usage: source this file, then call pydantic-worktree-checkout <branch-name>

pydantic-worktree-checkout() {
    if [ -z "$PYDANTIC_AI_TOOLS_REPO" ]; then
        echo "Error: PYDANTIC_AI_TOOLS_REPO env var not set"
        echo "Set it to your pydantic-ai-claude-tools repo path, e.g.:"
        echo "  export PYDANTIC_AI_TOOLS_REPO=~/projects/pydantic-ai-claude-tools"
        return 1
    fi

    if [ -z "$PYDANTIC_AI_REPO" ]; then
        echo "Error: PYDANTIC_AI_REPO env var not set"
        echo "Set it to your pydantic-ai main repo path, e.g.:"
        echo "  export PYDANTIC_AI_REPO=/Users/david/projects/forks/pydantic-ai-main"
        return 1
    fi

    if [ $# -ne 1 ]; then
        echo "Usage: pydantic-worktree-checkout <branch-name>"
        return 1
    fi

    local branch_name="$1"
    local worktree_path="$(dirname "$PYDANTIC_AI_REPO")/$branch_name"

    echo "Creating worktree at: $worktree_path"
    echo "Tracking branch: upstream/$branch_name"

    cd "$PYDANTIC_AI_REPO" || return 1
    git fetch upstream "$branch_name" || return 1
    git worktree add --track -b "$branch_name" "$worktree_path" "upstream/$branch_name" || return 1

    cd "$worktree_path" || return 1

    # Copy config files
    "$PYDANTIC_AI_TOOLS_REPO/scripts/copy-pydantic-config.sh" . || return 1

    echo "Running make install..."
    make install || return 1

    # Set venv prompt to branch name
    if [ -f ".venv/bin/activate" ]; then
        sed -i '' "s/VIRTUAL_ENV_PROMPT=\"[^\"]*\"/VIRTUAL_ENV_PROMPT=\"$branch_name\"/" .venv/bin/activate
    fi

    source .venv/bin/activate

    echo "Setup complete! Opening VS Code..."
    code .

    echo "$worktree_path"
}
