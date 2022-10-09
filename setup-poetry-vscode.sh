#!/bin/bash

countdown() {
    sec=$1
    while [ "$sec" -ge 0 ]; do
        echo -ne "Waiting for $sec seconds...\033[0K\r"
        ((sec = sec - 1))
        sleep 1
    done
}

function get_dir() {
    pwd | awk -F'/' '{print $NF}'
}

function check_shell_and_get_shell_config_file() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        echo "$HOME/.bashrc"
    fi
}

function create_workspace() {
    if [ $# -eq 0 ]; then
        echo "create_workspace requires workspace_file_name"
        return 1
    elif [ $# -eq 1 ]; then
        echo "create_workspace requires poetry status"
    else
        workspace_file_name="$1"
        touch "$workspace_file_name"
        {
            echo "{"
            echo "    \"folders\": ["
            echo "        {"
            echo "            \"path\": \".\""
            echo "        }"
            echo "    ],"
        } >>"$workspace_file_name"

        if [ "$2" = "true" ]; then
            {
                echo "    \"settings\": {"
                echo "        \"editor.formatOnSave\": true,"
                echo "        \"python.linting.enabled\": true,"
                echo "        \"python.linting.flake8Enabled\": true,"
                echo "        \"python.linting.flake8Path\": \".venv/bin/pflake8\""
                echo "    }"
                echo "}"
            } >>"$workspace_file_name"

        elif [ "$2" = "false" ]; then
            {
                echo "    \"settings\": {}"
                echo "}"
            } >>"$workspace_file_name"
        else
            echo "invalid poetry status"
            return 1
        fi
    fi
}

function install_vscode_extensions() {
    code --install-extension ms-python.python --force
}

function install_pyenv() {
    if [ -d "$HOME/.pyenv" ]; then
        echo "pyenv already installed"
    else
        curl https://pyenv.run | bash

        __pyenv_shell_cfg=$(check_shell_and_get_shell_config_file)
        if [ -f "$__pyenv_shell_cfg" ]; then
            if grep -q "pyenv" "$__pyenv_shell_cfg"; then
                :
            else
                echo "Adding pyenv to $__pyenv_shell_cfg..."
                {
                    echo "# pyenv"
                    echo "export PYENV_ROOT=\"\$HOME/.pyenv\""
                    echo "command -v pyenv >/dev/null || export PATH=\"\$PYENV_ROOT/bin:\$PATH\""
                    echo "eval \"\$(pyenv init -)\""
                } >>"$__pyenv_shell_cfg"
                export PYENV_ROOT="$HOME/.pyenv"
                command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
                eval "$(pyenv init -)"
            fi
        fi

    fi
    pyenv install 3:latest
    pyenv global "$(pyenv versions | tail -n 1 | sed 's/^[ \t]*//')"
    echo "Using python version: $(python --version)"
}

function setup_poetry() {
    # install poetry
    if type poetry >/dev/null 2>&1; then
        poetry self update
    else
        mkdir -p "$HOME/.local"
        echo "Installing poetry..."
        curl -sSL https://install.python-poetry.org | python3 -
    fi

    __poetryshell_cfg=$(check_shell_and_get_shell_config_file)
    if [ -f "$__poetryshell_cfg" ]; then
        if grep -q "poetry" "$__poetryshell_cfg"; then
            :
        else
            echo "Adding poetry to $__poetryshell_cfg..."
            echo "# poetry" >>"$__poetryshell_cfg"
            echo "export PATH=\"\$PATH:$HOME/.local/bin\"" >>"$__poetryshell_cfg"
            export PATH="$PATH:$HOME/.local/bin"
        fi
    fi

    poetry config virtualenvs.in-project true

    # Create a new poetry project
    if [ -f "pyproject.toml" ]; then
        poetry install
        poetry_status="true"
    else
        echo "No pyproject.toml found. Skipping poetry init..."
        poetry_status="false"
    fi
}

# Main
if type "code" >/dev/null 2>&1; then
    # install vscode-server
    if [ -d "$HOME/.vscode-server" ]; then
        echo "VSCode Server already installed, skipping..."
    else
        echo "Installing VSCode Server"
        code -h >/dev/null 2>&1
    fi

    # install vscode extension
    install_vscode_extensions

    # install python dependencies
    sudo apt-get update
    sudo apt-get install -y make build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

    # install pyenv
    install_pyenv

    # install poetry
    poetry_status=""
    setup_poetry

    # create workspace
    workspace_name="$(get_dir)"
    echo "Settingup VSCode for $workspace_name"
    workspace_file_name="$workspace_name.code-workspace"

    if [ -f "$workspace_file_name" ]; then
        echo "Workspace file already exists."
        echo "Please add the following to settings column in your workspace file:"
        echo "\"python.linting.enabled\": true,"
        echo "\"python.linting.flake8Enabled\": true,"
        echo "\"python.linting.flake8Path\": \".venv/bin/pflake8\""
    else
        echo "Creating workspace file..."
        create_workspace "$workspace_file_name" "$poetry_status"
        countdown 5
    fi
    code -g "$workspace_file_name" -n
else
    echo "No VSCode Enviroment found."
    echo "maybe here is not WSL..."
fi