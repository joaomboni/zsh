# =========================================================
# fzf
# =========================================================

export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix'  # strip-cwd-prefix removes the leading ./ from results

# Ctrl-T uses fd
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# UI
export FZF_DEFAULT_OPTS='
  --height=60%
  --layout=reverse
  --border=rounded
  --prompt="  "
  --pointer="  "
  --preview-window=right:65%:wrap:border-left
'

export _FZF_PREVIEW_CMD='bat --color=always --style=plain,numbers --line-range=:500 {}'
export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"

# Ctrl+F: file picker excluding hidden files
_fzf_file_no_hidden() {
  local cmd result
  cmd="${FZF_DEFAULT_COMMAND/--hidden /}"
  result=$(eval "${cmd:-find . -type f}" | fzf --preview "$_FZF_PREVIEW_CMD") \
    && LBUFFER+="$result"  # LBUFFER is the text left of the cursor
  zle reset-prompt
}
zle -N _fzf_file_no_hidden

# Ctrl+G: fuzzy git commit browser
_fzf_git_log() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    zle -M "Not a git repository"
    return 1
  }
  local commit
  commit=$(
    git log --oneline --color=always --decorate -n 500 |
      fzf --ansi --no-sort --reverse \
        --preview 'git show --color=always --stat -p {1}' \
        --preview-window=right:65%:wrap:border-left
  ) ||{
    zle reset-prompt 
    return 1
  }
  # Insert the short hash into the command line (optional)
  LBUFFER+="${commit%% *}"
  zle reset-prompt
}
zle -N _fzf_git_log

# Ctrl+X: fuzzy browser for unstaged / untracked changes
_fzf_git_status() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    zle -M "Not a git repository"
    return 1
  }
  local selection file
  selection=$(
    git -c color.status=always status --short |
      fzf --ansi --no-sort --reverse \
        --preview '
          file={2}
          # unmerged / renames can shift fields; fall back to last field
          [[ -z "$file" ]] && file={-1}
          if [[ -f "$file" ]]; then
            if git diff --quiet -- "$file" 2>/dev/null; then
              # untracked or only staged differently — show file or unstaged/untracked diff
              git diff --no-index -- /dev/null "$file" 2>/dev/null \
                || bat --color=always --style=plain,numbers --line-range=:500 "$file"
            else
              git diff --color=always -- "$file"
            fi
          else
            echo "deleted or missing: $file"
          fi
        ' \
        --preview-window=right:65%:wrap:border-left
  ) || {
    zle reset-prompt 
    return 1
  }
  file="${selection##* }"   # path is usually the last field in `git status -s`
  LBUFFER+="$file"
  zle reset-prompt
}
zle -N _fzf_git_status

# Ctrl+B: fuzzy git branch browser (last update, author, subject; creation approx in preview)
_fzf_git_branches() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    zle -M "Not a git repository"
    return 1
  }

  local selection branch
  selection=$(
    git for-each-ref --sort=-committerdate refs/heads/ refs/remotes/ \
      --format=$'%(refname:short)\t%(committerdate:short)\t%(authorname)\t%(subject)' |
      grep -v '/HEAD$' |
      column -t -s $'\t' |
      fzf --ansi --no-sort --reverse \
        --preview '
          b=$(echo {} | awk "{print \$1}")
          echo "Branch: $b"
          echo "Last update: $(git log -1 --format="%ci (%cr)" "$b" 2>/dev/null)"
          echo "Updated by:  $(git log -1 --format="%an <%ae>" "$b" 2>/dev/null)"
          echo "Created ~:   $(git reflog show --date=short "$b" 2>/dev/null | tail -1)"
          echo
          echo "Last commit:"
          git log -1 --color=always --stat -p "$b" 2>/dev/null
        ' \
        --preview-window=right:65%:wrap:border-left
  ) || {
    zle reset-prompt
    return 1
  }
  branch="${selection%% *}"
  LBUFFER+="git checkout $branch"
  zle reset-prompt
}
zle -N _fzf_git_branches
