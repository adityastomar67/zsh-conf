# ------------------------[  ZSH ICONS DEFINITION  ]------------------------ #
# This file defines the glyphs and symbols used in the prompt and scripts.
# Requires a Nerd Font (https://www.nerdfonts.com/) for proper rendering.


# ........................[  1. Initialization  ]........................ #

typeset -gAH icons


# ........................[  2. Icon Definitions  ]........................ #

icons=(
    # -- Powerline Separators --
    LEFT_SEGMENT_SEPARATOR         $'\uE0B0'              # 
    RIGHT_SEGMENT_SEPARATOR        $'\uE0B2'              # 
    LEFT_SUBSEGMENT_SEPARATOR      $'\uE0B1'              # 
    RIGHT_SUBSEGMENT_SEPARATOR     $'\uE0B3'              # 
    LEFT_SEGMENT_END_SEPARATOR     ' '                    # (Space)

    # -- OS & System --
    ROOT_ICON                      $'\uF201'              # 
    LINUX_ICON                     $'\uF17C'              # 
    APPLE_ICON                     $'\uF179'              # 
    FREEBSD_ICON                   $'\U1F608 '            # 😈
    SUNOS_ICON                     $'\uF185 '             # 
    SERVER_ICON                    $'\uF233'              # 
    SSH_ICON                       '(ssh)'                # Text Fallback

    # -- Directory & Files --
    HOME_ICON                      $'\uF015'              # 
    HOME_SUB_ICON                  $'\uF07C'              # 
    FOLDER_ICON                    $'\uF115'              # 
    DISK_ICON                      $'\uF0A0 '             # 
    LOCK_ICON                      $'\UE138'              # 

    # -- Version Control System (VCS) --
    VCS_GIT_ICON                   $'\uF1D3 '             # 
    VCS_GIT_GITHUB_ICON            $'\uF113 '             # 
    VCS_GIT_BITBUCKET_ICON         $'\uF171 '             # 
    VCS_GIT_GITLAB_ICON            $'\uF296 '             # 
    VCS_HG_ICON                    $'\uF0C3 '             # 
    VCS_SVN_ICON                   '(svn) '               # Text Fallback

    VCS_BRANCH_ICON                $'\uF126'              # 
    VCS_REMOTE_BRANCH_ICON         $'\u2192'              # →
    VCS_TAG_ICON                   $'\uF217 '             # 
    VCS_BOOKMARK_ICON              $'\uF27B'              # 
    VCS_COMMIT_ICON                $'\uF221 '             # 

    VCS_UNTRACKED_ICON             $'\uF059'              # 
    VCS_UNSTAGED_ICON              $'\uF06A'              # 
    VCS_STAGED_ICON                $'\uF055'              # 
    VCS_CHANGED_ICON               $'\uF067'              # 
    VCS_STASH_ICON                 $'\uF01C '             # 
    VCS_INCOMING_CHANGES_ICON      $'\uF01A '             # 
    VCS_OUTGOING_CHANGES_ICON      $'\uF01B '             # 

    # -- Languages & Frameworks --
    PYTHON_ICON                    $'\U1F40D'             # 🐍
    RUBY_ICON                      $'\uF219 '             # 
    NODE_ICON                      $'\u2B22'              # ⬢
    RUST_ICON                      $'\uE6A8'              # 
    ELIXIR_ICON                    $'\Uf0c3'              # 
    SWIFT_ICON                     ''                     # Empty
    SYMFONY_ICON                   'SF'                   # Text
    AWS_ICON                       $'\uF270'              # 
    AWS_EB_ICON                    $'\U1F331 '            # 🌱

    # -- Status & Hardware --
    OK_ICON                        $'\u2713'              # ✓
    FAIL_ICON                      $'\u2718'              # ✘
    TEST_ICON                      $'\uF291'              # 
    TODO_ICON                      $'\u2611'              # ☑
    LOAD_ICON                      $'\uF080 '             # 
    BATTERY_ICON                   $'\U1F50B'             # 🔋
    NETWORK_ICON                   $'\uF09E'              # 
    RAM_ICON                       $'\uF0E4'              # 
    SWAP_ICON                      $'\uF0E4'              # 
    EXECUTION_TIME_ICON            $'\uF253'              # 
    BACKGROUND_JOBS_ICON           $'\uF013 '             # 
    CARRIAGE_RETURN_ICON           $'\u21B5'              # ↵

    # -- Prompt Styling --
    MULTILINE_FIRST_PROMPT_PREFIX  $'\u256D'$'\U2500'     # ╭─
    MULTILINE_SECOND_PROMPT_PREFIX $'\u2570'$'\U2500 '    # ╰─
    PUBLIC_IP_ICON                 ''                     # Empty
)


# ........................[  3. Helper Functions  ]........................ #

# Prints the named icon, or prints nothing if undefined.
function print_icon() {
    echo -n "${icons[$1]}"
}

# Debugging: Prints all defined icons and their keys.
get_icon_names() {
    for key in ${(@k)icons}; do
        echo "$key: ${icons[$key]}"
    done
}

