# shellcheck shell=bash
# Stack shell functions for the Luxus-Python-Stack.
# Source this file from ~/.zshrc; it provides jupyter-launcher,
# prompt_my_jupyter, and the jl alias. Project generation lives in a separate
# project initializer.

# ─── jupyter-launcher ─────────────────────────────────────────────────────────
# Flexible Jupyter Lab launcher with optional Colab integration and port selection.
#
# Usage: jupyter-launcher [-n] [-c] [-p PORT] [folder]
#
#   -n          Tokenless mode: disables password/token authentication.
#               Useful for local development or when Google Colab should connect
#               without a token.
#
#   -c          Colab mode: adds the Google Colab CORS/XSRF arguments so that
#               colab.research.google.com can connect to this local server.
#               Can be combined with -n (token is then also disabled).
#
#   -p PORT     Use an alternative port instead of the default 8888.
#               Example: jupyter-launcher -p 9999
#
#   folder      Optional path to use as the notebook directory (--notebook-dir).
#               Use '.' to refer to the current working directory.
#               If omitted, ~/labor is used as the default.
#
# Examples:
#   jupyter-launcher                     # default: port 8888, ~/labor, token required
#   jupyter-launcher -n                  # tokenless, ~/labor
#   jupyter-launcher -c                  # Colab-compatible, ~/labor, token required
#   jupyter-launcher -n -c              # tokenless + Colab-compatible, ~/labor
#   jupyter-launcher -n -c .            # tokenless + Colab, current directory
#   jupyter-launcher -p 9999 myproject  # custom port, ./myproject as notebook-dir
#   jupyter-launcher -n -c -p 9999 .   # all options combined
#
# Personal alias suggestion: alias jl='jupyter-launcher -n -c'
jupyter-launcher() {

    # ─── FLAG ARGUMENT DOCUMENTATION ──────────────────────────────────────────
    # --no-browser
    #     Prevents Jupyter from automatically opening a browser window on start.
    #
    # --ip=127.0.0.1
    #     Binds the server strictly to localhost (security: not reachable from LAN).
    #
    # --port=PORT
    #     Sets the port for the local Jupyter instance (default: 8888).
    #
    # --ServerApp.port_retries=0
    #     Aborts immediately if the chosen port is already in use, instead of
    #     silently falling back to the next port (e.g. 8889). This prevents
    #     accidental multi-instance confusion.
    #
    # --notebook-dir=PATH
    #     Sets the root directory shown in the Jupyter file browser.
    #
    # ─── BUGFIX: FILE-ID ERRORS AND INFINITE LOOPS ────────────────────────────
    # --YDocExtension.disable_rtc=True
    #     Disables Real-Time Collaboration (RTC). Without this, JupyterLab enters
    #     a 404 loop trying to open the "globalAwareness" room, which blocks the
    #     server. Safe to disable when collaboration is not needed.
    #     NOTE: To prevent WebSocket crashes with Google Colab (TypeError on strings),
    #     the underlying server extensions (jupyter_server_documents and 
    #     jupyter_server_ydoc) are globally disabled via ~/.jupyter/jupyter_server_config.json
    #     during the initial Mamba system setup.
    #
    # --FileIdManager.file_id_manager_class=jupyter_server.fileid.manager.ArbitraryFileIdManager
    #     Fixes the recurring "File ID error". By default Jupyter uses a local
    #     SQLite database for file IDs which frequently gets corrupted or loses
    #     track of paths. The ArbitraryFileIdManager keeps IDs in memory only -
    #     files can be opened again without DB corruption issues.
    #
    # ─── GOOGLE COLAB INTEGRATION (only when -c is set) ───────────────────────
    # --ServerApp.allow_origin='https://colab.research.google.com'
    #     Allows Colab to access this local server via CORS.
    #
    # --ServerApp.allow_remote_access=True
    #     Required for any external origin to be permitted at all.
    #
    # --ServerApp.disable_check_xsrf=True
    #     Prevents the server from treating Colab requests as malicious
    #     cross-site request forgery (XSRF) attacks.
    #
    # ─── TOKENLESS MODE (only when -n is set) ─────────────────────────────────
    # --ServerApp.token=''
    #     Disables the password/token prompt entirely.
    #
    # --ServerApp.allow_credentials=True
    #     Required when Colab (or any client) needs to connect without a token.
    # ──────────────────────────────────────────────────────────────────────────

    # ── Default values for all configurable options ───────────────────────────
    local _jl_tokenless=0      # -n flag: 1 = disable token authentication
    local _jl_colab=0          # -c flag: 1 = add Colab CORS/XSRF arguments
    local _jl_port="8888"      # -p PORT: port number (default 8888)
    local _jl_folder=""        # positional: notebook-dir path (empty = use default)

    # ── Parse optional flags with getopts ─────────────────────────────────────
    # getopts processes flags one at a time; OPTIND tracks the position so we
    # can shift to the remaining positional argument (the optional folder) afterward.
    local OPTIND=1
    local _jl_opt
    while getopts ":ncp:" _jl_opt; do
        case "$_jl_opt" in
            n)
                # Tokenless mode: no password/token required
                _jl_tokenless=1
                ;;
            c)
                # Colab mode: enable Google Colab CORS/XSRF arguments
                _jl_colab=1
                ;;
            p)
                # Custom port: OPTARG holds the value that follows -p
                _jl_port="$OPTARG"
                ;;
            :)
                # A flag that requires an argument was given without one (e.g. -p with no number)
                echo "jupyter-launcher: option -${OPTARG} requires an argument." >&2
                return 1
                ;;
            \?)
                # An unknown flag was passed; print usage hint and abort
                echo "jupyter-launcher: unknown option -${OPTARG}." >&2
                echo "Usage: jupyter-launcher [-n] [-c] [-p PORT] [folder]" >&2
                return 1
                ;;
        esac
    done

    # Shift past the flags so that "$1" now refers to the optional folder argument
    shift $(( OPTIND - 1 ))

    # ── Resolve the notebook directory ────────────────────────────────────────
    if [[ $# -ge 1 ]]; then
        # A folder argument was provided. '.' is explicitly valid and resolves to
        # the current working directory via pwd.
        if [[ "$1" == "." ]]; then
            _jl_folder="$(pwd)"
        else
            # Expand to an absolute path so Jupyter always sees a clean path,
            # regardless of how the user typed it (relative or absolute).
            _jl_folder="$(realpath -m "$1")"
        fi
        # Create the directory if it does not exist yet, so Jupyter does not error.
        mkdir -p "$_jl_folder"
    else
        # No folder argument: fall back to the standard workspace directory.
        _jl_folder="$HOME/labor"
        mkdir -p "$_jl_folder"
    fi

    # ── Build the argument list incrementally ─────────────────────────────────
    # Using an array avoids quoting pitfalls and makes conditional flag injection
    # clean and readable.
    local -a _jl_args=(
        --no-browser
        --ip=127.0.0.1
        "--port=${_jl_port}"
        --ServerApp.port_retries=0
        "--notebook-dir=${_jl_folder}"
        # Disable real-time collaboration to prevent the globalAwareness 404 loop
        --YDocExtension.disable_rtc=True
        # Use in-memory file ID manager to avoid SQLite corruption errors
        --FileIdManager.file_id_manager_class=jupyter_server.fileid.manager.ArbitraryFileIdManager
    )

    # ── Conditionally append tokenless-mode arguments ─────────────────────────
    if [[ $_jl_tokenless -eq 1 ]]; then
        _jl_args+=(
            --ServerApp.token=''
            # allow_credentials is required for credential-bearing requests (e.g. from Colab)
            --ServerApp.allow_credentials=True
        )
    fi

    # ── Conditionally append Colab-integration arguments ──────────────────────
    if [[ $_jl_colab -eq 1 ]]; then
        _jl_args+=(
            # Grant Colab cross-origin access to this local server
            "--ServerApp.allow_origin=https://colab.research.google.com"
            --ServerApp.allow_remote_access=True
            # Disable XSRF check so Colab requests are not rejected as attacks
            --ServerApp.disable_check_xsrf=True
        )
    fi

    # ── Print a summary so the user knows exactly what will start ─────────────
    echo "Starting Jupyter Lab:"
    echo "  notebook-dir : $_jl_folder"
    echo "  port         : $_jl_port"
    echo "  tokenless    : $([ $_jl_tokenless -eq 1 ] && echo yes || echo no)"
    echo "  colab mode   : $([ $_jl_colab    -eq 1 ] && echo yes || echo no)"
    echo ""

    # ─── Launch Jupyter with the assembled argument list ───────────────────────
    jupyter lab "${_jl_args[@]}"
}

# Standard alias for quick access (tokenless + Colab mode, default directory)
alias jl='jupyter-launcher -n -c'





# ─── Custom Jupyter P10k Segment (Passive Runtime Tracker) ────────────────────
# otptional: info is folder a jupyter runtime-folder in p10k prompt
# insert in ~/.p10k.zsh to the list of segments in POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS 
# without 'prompt_', just 'my_jupyter'
function prompt_my_jupyter() {
  # Where Jupyter on Linux logs its active server processes
  local runtime_dir="${XDG_DATA_HOME:-$HOME/.local/share}/jupyter/runtime"
  # Under ZSH, unmatched globs must expand to an empty list. Bash parses the
  # line as a simple command and never runs it; there the loop skips literal
  # patterns via the [[ -e ... ]] check below.
  if [ -n "${ZSH_VERSION:-}" ]; then
    setopt localoptions nullglob
  fi
  local json_files=()
  local _json_candidate
  for _json_candidate in "$runtime_dir"/jpserver-*.json "$runtime_dir"/nbserver-*.json; do
    [[ -e "$_json_candidate" ]] || continue
    json_files+=("$_json_candidate")
  done
  # If no JSON files at all -> abort immediately (costs 0 performance)
  if (( ${#json_files} == 0 )); then
    return
  fi

  local is_jupyter_dir=false
  local active_dirs=()

  # Check each JSON file: only consider a live Jupyter server process
  local json_file
  local pid
  local process_args
  local server_dir
  for json_file in "${json_files[@]}"; do
    # Extract PID from filename (e.g. jpserver-17343.json -> 17343)
    pid="${json_file##*-}"
    pid="${pid%.json}"
    # Verify the process is still running (kill -0 returns 0 if alive)
    if kill -0 "$pid" 2>/dev/null; then
      # A stale runtime file can point to an unrelated process after PID reuse.
      process_args=$(ps -p "$pid" -o args= 2>/dev/null)
      if [[ "$process_args" != *jupyter* && "$process_args" != *notebook* ]]; then
        continue
      fi

      # Read root_dir from this active server
      server_dir=$(grep -o '"root_dir"[[:space:]]*:[[:space:]]*"[^\}]*"' "$json_file" 2>/dev/null | head -1 | cut -d'"' -f4)
      if [[ -n "$server_dir" ]]; then
        active_dirs+=("$server_dir")
      fi
    fi
  done

  # If no active servers remain after PID check -> abort
  if (( ${#active_dirs} == 0 )); then
    return
  fi

  # Check whether the current directory ($PWD) is a (sub)folder of an active server
  for server_dir in "${active_dirs[@]}"; do
    if [[ "$PWD" == "$server_dir" || "$PWD" == "$server_dir/"* ]]; then
      is_jupyter_dir=true
      break
    fi
  done

  # Hit! Active server is running and we are within its sphere of influence.
  if $is_jupyter_dir; then
    p10k segment -f 208 -i '' -t 'jupyter'
  fi
}
