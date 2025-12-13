#!/bin/bash

ado() {

    if ! _ado_check_basic_prerequisites; then
        return 1
    fi

    if [[ $# -eq 0 ]]; then
        echo "Usage: ado <command> [arguments]"
        echo "Available commands:"
        echo "  browse  - Open repository in Azure DevOps web interface"
        echo "  repo    - Repository operations"
        echo "  pr      - Pull request operations"
        return 1
    fi

    local command="$1"
    shift

    case "$command" in
        browse)
            ado_browse "$@"
            ;;
        repo)
            ado_repo "$@"
            ;;
        pr)
            ado_pr "$@"
            ;;
        *)
            echo "Unknown ado command: $command"
            return 1
            ;;
    esac
}

ado_browse() {
    if ! _ado_check_repository; then
        return 1
    fi
    
    local remote_url=$(git remote get-url origin 2>/dev/null)
    
    if [[ -z "$remote_url" ]]; then
        echo "Error: No git repository found or no origin remote configured"
        return 1
    fi
    
    if [[ "$remote_url" =~ ^https://dev\.azure\.com/ ]]; then
        echo "Opening Azure DevOps repository: $remote_url"
        open "$remote_url"
    elif [[ "$remote_url" =~ ^https://.*\.visualstudio\.com ]]; then
        local clean_url=$(echo "$remote_url" | sed 's|https://[^@]*@|https://|')
        local org=$(echo "$clean_url" | sed -n 's|^https://\([^.]*\)\..*|\1|p')
        local project=$(echo "$clean_url" | sed -n 's|.*/DefaultCollection/\([^/]*\)/_git/.*|\1|p')
        local repo=$(echo "$clean_url" | sed -n 's|.*/_git/\(.*\)|\1|p')
        
        if [[ -n "$org" && -n "$project" && -n "$repo" ]]; then
            project=$(printf '%s\n' "$project" | sed 's/ /%20/g')
            local web_url="https://dev.azure.com/${org}/${project}/_git/${repo}"
            echo "Opening Azure DevOps repository: $web_url"
            open "$web_url"
        else
            echo "Error: Could not parse Azure DevOps URL format"
            echo "Remote URL: $remote_url"
            return 1
        fi
    elif [[ "$remote_url" =~ ^git@ssh\.dev\.azure\.com ]]; then
        local org=$(echo "$remote_url" | sed -n 's|git@ssh\.dev\.azure\.com:v3/\([^/]*\)/.*|\1|p')
        local project=$(echo "$remote_url" | sed -n 's|git@ssh\.dev\.azure\.com:v3/[^/]*/\([^/]*\)/.*|\1|p')
        local repo=$(echo "$remote_url" | sed -n 's|.*[^/]*/\([^/]*\)$|\1|p')
        
        if [[ -n "$org" && -n "$project" && -n "$repo" ]]; then
            project=$(printf '%s\n' "$project" | sed 's/ /%20/g')
            local web_url="https://dev.azure.com/${org}/${project}/_git/${repo}"
            echo "Opening Azure DevOps repository: $web_url"
            open "$web_url"
        else
            echo "Error: Could not parse SSH Azure DevOps URL format"
            echo "Remote URL: $remote_url"
            return 1
        fi
    else
        echo "Error: This doesn't appear to be an Azure DevOps repository"
        echo "Remote URL: $remote_url"
        return 1
    fi
}

ado_repo() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: ado repo <command> [arguments]"
        echo "Available commands:"
        echo "  create  - Create a new repository"
        echo "  delete  - Delete a repository"
        return 1
    fi

    local command="$1"
    shift

    case "$command" in
        create)
            ado_repo_create "$@"
            ;;
        delete)
            ado_repo_delete "$@"
            ;;
        *)
            echo "Unknown repo command: $command"
            echo "Run 'ado repo' for available commands"
            return 1
            ;;
    esac
}

ado_repo_create() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: ado repo create <repo-name> <project-name> [org-url]"
        echo "Example: ado repo create quiver \"Platform Engineering\" \"https://dev.azure.com/mcgsead\""
        return 1
    fi

    local repo_name="$1"
    local project="$2"
    local org="${3:-}"

    local cmd=(az repos create --name "$repo_name" --project "$project")
    
    if [[ -n "$org" ]]; then
        cmd+=(--org "$org")
    fi
    
    cmd+=(--output table --query "{Name:name,Project:project.name,URL:webUrl}")

    echo "Creating repository '$repo_name' in project '$project'..."
    "${cmd[@]}"
}

ado_repo_delete() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: ado repo delete <repo-name> <project-name> [org-url]"
        echo "Example: ado repo delete quiver \"Platform Engineering\" \"https://dev.azure.com/mcgsead\""
        return 1
    fi

    local repo_name="$1"
    local project="$2"
    local org="${3:-}"

    local cmd=(az repos delete --id "$repo_name" --project "$project" --yes)
    
    if [[ -n "$org" ]]; then
        cmd+=(--org "$org")
    fi

    echo "Deleting repository '$repo_name' from project '$project'..."
    "${cmd[@]}"
    
    if [[ $? -eq 0 ]]; then
        echo "Repository '$repo_name' deleted successfully"
    fi
}

ado_pr() {
    if ! _ado_check_repository; then
        return 1
    fi
    
    if [[ $# -eq 0 ]]; then
        echo "Usage: ado pr <command> [arguments]"
        echo "Available commands:"
        echo "  create|open      - Create a new pull request"
        echo "  list|ls          - List pull requests"
        echo "  show             - Show pull request details"
        echo "  update           - Update pull request properties"
        echo "  complete|merge   - Complete (merge) a pull request"
        echo "  abandon|close    - Abandon a pull request"
        echo "  vote|approve     - Vote on a pull request"
        echo "  browse           - Open pull request in browser"
        return 1
    fi

    local command="$1"
    shift

    case "$command" in
        create|open)
            ado_pr_create "$@"
            ;;
        list|ls)
            ado_pr_list "$@"
            ;;
        show)
            ado_pr_show "$@"
            ;;
        update)
            ado_pr_update "$@"
            ;;
        complete|merge)
            ado_pr_complete "$@"
            ;;
        abandon|close)
            ado_pr_abandon "$@"
            ;;
        vote|approve)
            ado_pr_vote "$@"
            ;;
        browse)
            ado_pr_browse "$@"
            ;;
        *)
            echo "Unknown PR command: $command"
            echo "Run 'ado pr' for available commands"
            return 1
            ;;
    esac
}

ado_pr_create() {
    if [[ $# -eq 0 ]]; then
        az repos pr create --help
        echo "Example: ado pr create --title \"Demo PR - abc123\""
        return
    fi
    
    local base_url=$(_ado_get_base_url)
    if [[ $? -ne 0 ]]; then
        echo "Error: Could not determine base URL"
        return 1
    fi
    
    az repos pr create "$@" --output table --query "{PR:pullRequestId,Status:status,URL:join(\`\`,[\`$base_url\`,\`/pullrequest/\`,to_string(pullRequestId)])}"
}

ado_pr_list() {
    local base_url=$(_ado_get_base_url)
    if [[ $? -ne 0 ]]; then
        echo "Error: Could not determine base URL"
        return 1
    fi
    
    az repos pr list "$@" --output table --query "[].{PR:pullRequestId,Title:title,Creator:createdBy.uniqueName,Created:creationDate,URL:join(\`\`,[\`$base_url\`,\`/pullrequest/\`,to_string(pullRequestId)])}"
}

ado_pr_show() {
    if [[ $# -eq 0 ]]; then
        az repos pr show --help
        echo "Example: ado pr show --id 12345"
        return
    fi
    
    local base_url=$(_ado_get_base_url)
    if [[ $? -ne 0 ]]; then
        echo "Error: Could not determine base URL"
        return 1
    fi
    
    az repos pr show "$@" --output table --query "{PR:pullRequestId,Title:title,Creator:createdBy.uniqueName,Created:creationDate,URL:join(\`\`,[\`$base_url\`,\`/pullrequest/\`,to_string(pullRequestId)])}"
}

ado_pr_update() {
    if [[ $# -eq 0 ]]; then
        az repos pr update --help
        echo "Example: ado pr update --id 12345 --description 'Updated: Complete workflow demo'"
        return
    fi
    
    local base_url=$(_ado_get_base_url)
    if [[ $? -ne 0 ]]; then
        echo "Error: Could not determine base URL"
        return 1
    fi
    
    az repos pr update "$@" --output table --query "{PR:pullRequestId,Status:status,URL:join(\`\`,[\`$base_url\`,\`/pullrequest/\`,to_string(pullRequestId)])}"
}

ado_pr_complete() {
    if [[ $# -eq 0 ]]; then
        az repos pr update --help
        echo "Example: ado pr complete --id 12345 --merge-commit-message 'Merged PR 12345: Demo PR'"
        return
    fi
    
    local base_url=$(_ado_get_base_url)
    if [[ $? -ne 0 ]]; then
        echo "Error: Could not determine base URL"
        return 1
    fi
    
    az repos pr update --status completed --bypass-policy true "$@" --output table --query "{PR:pullRequestId,Status:status,URL:join(\`\`,[\`$base_url\`,\`/pullrequest/\`,to_string(pullRequestId)])}"
}

ado_pr_abandon() {
    if [[ $# -eq 0 ]]; then
        az repos pr update --help
        echo "Example: ado pr abandon --id 12345"
        return
    fi
    
    local base_url=$(_ado_get_base_url)
    if [[ $? -ne 0 ]]; then
        echo "Error: Could not determine base URL"
        return 1
    fi
    
    az repos pr update --status abandoned "$@" --output table --query "{PR:pullRequestId,Status:status,URL:join(\`\`,[\`$base_url\`,\`/pullrequest/\`,to_string(pullRequestId)])}"
}

ado_pr_vote() {
    if [[ $# -eq 0 ]]; then
        az repos pr set-vote --help
        echo "Example: ado pr approve 12345"
        return
    fi
    
    local pr_id=""
    local parsed_args=("$@")
    
    if [[ "${1}" != "--id" && "${1}" != "--vote" ]]; then
        if [[ $# -eq 1 ]]; then
            pr_id="$1"
            parsed_args=(--id "$1" --vote approve)
        fi
    else
        local args=("$@")
        for ((i=1; i<=${#args}; i++)); do
            if [[ "${args[i]}" == "--id" ]]; then
                ((i++))
                pr_id="${args[i]}"
                break
            fi
        done
    fi
    
    if [[ -z "$pr_id" ]]; then
        echo "Error: Could not determine PR ID"
        return 1
    fi
    
    az repos pr set-vote "${parsed_args[@]}" >/dev/null 2>&1
    
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    local base_url=$(_ado_get_base_url)
    if [[ $? -ne 0 ]]; then
        echo "Error: Could not determine base URL"
        return 1
    fi
    
    az repos pr show --id "$pr_id" --output table --query "{PR:pullRequestId,Title:title,Creator:createdBy.uniqueName,Created:creationDate,URL:join(\`\`,[\`$base_url\`,\`/pullrequest/\`,to_string(pullRequestId)])}"
}

ado_pr_browse() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: ado pr browse <pr-id>"
        echo "Example: ado pr browse 12345"
        return 1
    fi
    
    local pr_id="$1"
    local remote_url=$(git remote get-url origin 2>/dev/null)
    
    if [[ -z "$remote_url" ]]; then
        echo "Error: No git repository found or no origin remote configured"
        return 1
    fi
    
    if [[ "$remote_url" =~ ^https://dev\.azure\.com/ ]]; then
        local org=$(echo "$remote_url" | sed -n 's|https://dev\.azure\.com/\([^/]*\)/.*|\1|p')
        local project=$(echo "$remote_url" | sed -n 's|https://dev\.azure\.com/[^/]*/\([^/]*\)/_git/.*|\1|p')
        local repo=$(echo "$remote_url" | sed -n 's|.*/_git/\(.*\)|\1|p')
        
        if [[ -n "$org" && -n "$project" && -n "$repo" ]]; then
            local pr_url="https://dev.azure.com/${org}/${project}/_git/${repo}/pullrequest/${pr_id}"
            echo "Opening PR #${pr_id}: $pr_url"
            open "$pr_url"
        else
            echo "Error: Could not parse repository information"
            return 1
        fi
    elif [[ "$remote_url" =~ ^https://.*\.visualstudio\.com ]]; then
        local clean_url=$(echo "$remote_url" | sed 's|https://[^@]*@|https://|')
        local org=$(echo "$clean_url" | sed -n 's|^https://\([^.]*\)\..*|\1|p')
        local project=$(echo "$clean_url" | sed -n 's|.*/DefaultCollection/\([^/]*\)/_git/.*|\1|p')
        local repo=$(echo "$clean_url" | sed -n 's|.*/_git/\(.*\)|\1|p')
        
        if [[ -n "$org" && -n "$project" && -n "$repo" ]]; then
            local pr_url="https://dev.azure.com/${org}/${project}/_git/${repo}/pullrequest/${pr_id}"
            echo "Opening PR #${pr_id}: $pr_url"
            open "$pr_url"
        else
            echo "Error: Could not parse repository information"
            return 1
        fi
    elif [[ "$remote_url" =~ ^git@ssh\.dev\.azure\.com ]]; then
        local org=$(echo "$remote_url" | sed -n 's|git@ssh\.dev\.azure\.com:v3/\([^/]*\)/.*|\1|p')
        local project=$(echo "$remote_url" | sed -n 's|git@ssh\.dev\.azure\.com:v3/[^/]*/\([^/]*\)/.*|\1|p')
        local repo=$(echo "$remote_url" | sed -n 's|.*[^/]*/\([^/]*\)$|\1|p')
        
        if [[ -n "$org" && -n "$project" && -n "$repo" ]]; then
            local pr_url="https://dev.azure.com/${org}/${project}/_git/${repo}/pullrequest/${pr_id}"
            echo "Opening PR #${pr_id}: $pr_url"
            open "$pr_url"
        else
            echo "Error: Could not parse SSH repository information"
            return 1
        fi
    else
        echo "Error: This doesn't appear to be an Azure DevOps repository"
        echo "Remote URL: $remote_url"
        return 1
    fi
}

_ado_get_base_url() {
    local remote_url=$(git remote get-url origin 2>/dev/null)
    
    if [[ -z "$remote_url" ]]; then
        echo "Error: No git repository found or no origin remote configured" >&2
        return 1
    fi
    
    local org project repo
    
    if [[ "$remote_url" =~ ^https://.*@?dev\.azure\.com/ ]]; then
        local clean_url=$(echo "$remote_url" | sed 's|https://[^@]*@|https://|')
        org=$(echo "$clean_url" | sed -n 's|https://dev\.azure\.com/\([^/]*\)/.*|\1|p')
        project=$(echo "$clean_url" | sed -n 's|https://dev\.azure\.com/[^/]*/\([^/]*\)/_git/.*|\1|p')
        repo=$(echo "$clean_url" | sed -n 's|.*/_git/\(.*\)|\1|p')
    elif [[ "$remote_url" =~ ^https://.*\.visualstudio\.com ]]; then
        local clean_url=$(echo "$remote_url" | sed 's|https://[^@]*@|https://|')
        org=$(echo "$clean_url" | sed -n 's|^https://\([^.]*\)\..*|\1|p')
        project=$(echo "$clean_url" | sed -n 's|.*/DefaultCollection/\([^/]*\)/_git/.*|\1|p')
        repo=$(echo "$clean_url" | sed -n 's|.*/_git/\(.*\)|\1|p')
    elif [[ "$remote_url" =~ ^git@ssh\.dev\.azure\.com ]]; then
        org=$(echo "$remote_url" | sed -n 's|git@ssh\.dev\.azure\.com:v3/\([^/]*\)/.*|\1|p')
        project=$(echo "$remote_url" | sed -n 's|git@ssh\.dev\.azure\.com:v3/[^/]*/\([^/]*\)/.*|\1|p')
        repo=$(echo "$remote_url" | sed -n 's|.*[^/]*/\([^/]*\)$|\1|p')
    else
        echo "Error: Unsupported remote URL format: $remote_url" >&2
        return 1
    fi
    
    if [[ -z "$org" || -z "$project" || -z "$repo" ]]; then
        echo "Error: Could not parse repository information from: $remote_url" >&2
        return 1
    fi
    
    project=$(printf '%s\n' "$project" | sed 's/ /%20/g')
    
    echo "https://dev.azure.com/${org}/${project}/_git/${repo}"
}

_ado_check_basic_prerequisites() {
    if ! az extension list --query "[?name=='azure-devops']" --output tsv | grep -q azure-devops; then
        echo "Error: Azure DevOps CLI extension is not installed."
        echo "Install with: az extension add --name azure-devops"
        return 1
    fi
    
    if ! az account show &>/dev/null; then
        echo "Error: Not authenticated with Azure CLI."
        echo "Login with: az login"
        return 1
    fi
    
    return 0
}

_ado_check_repository() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "Error: Not in a git repository."
        return 1
    fi
    
    local remote_url=$(git remote get-url origin 2>/dev/null)
    if [[ ! "$remote_url" =~ dev\.azure\.com ]] && [[ ! "$remote_url" =~ visualstudio\.com ]]; then
        echo "Error: Current repository is not an Azure DevOps repository."
        echo "Remote URL: $remote_url"
        return 1
    fi
    
    return 0
}
