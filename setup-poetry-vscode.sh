#!/bin/bash

# Funcion
countdown() {
    sec=$1
    while [ "$sec" -ge 0 ]; do
        echo -ne "Waiting for $sec seconds...\033[0K\r"
        ((sec = sec - 1))
        sleep 1
    done
}

get_dir() {
    pwd | awk -F'/' '{print $NF}'
}

check_shell_and_get_shell_config_file() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        echo "$HOME/.bashrc"
    fi
}

judge_os() {
    if [ "$(uname)" = "Darwin" ]; then
        echo "MACOS"
    elif [[ "$(uname -r)" = *"WSL"* ]]; then
        echo "WSL"
    elif [ "$(uname)" = "Linux" ]; then
        echo "LINUX"
    fi
}

judge_linux_package_manager() {
    if [ -x "$(command -v apt-get)" ]; then
        echo "APT"
    elif [ -x "$(command -v yum)" ]; then
        echo "YUM"
    elif [ -x "$(command -v dnf)" ]; then
        echo "DNF"
    elif [ -x "$(command -v pacman)" ]; then
        echo "PACMAN"
    elif [ -x "$(command -v apk)" ]; then
        echo "ALPINE"
    elif [ -x "$(command -v xbps-install)" ]; then
        echo "VOID"
    else
        echo "UNKNOWN"
        return 1
    fi
}

setup_vscode_wsl() {
    # install vscode-server
    if [ -d "$HOME/.vscode-server" ]; then
        echo "VSCode Server already installed, skipping..."
    else
        echo "Installing VSCode Server..."
        code -h >/dev/null 2>&1
    fi

    # install vscode extension
    echo "Installing VSCode extensions..."
    code --install-extension ms-python.python --force >>/dev/null 2>&1 &
    wait
}

install_python_deps() {
    # macos
    if [ "$OS_ENV" = "MACOS" ]; then
        brew install openssl readline sqlite3 xz zlib tcl-tk
    # linux
    elif [ "$OS_ENV" = "LINUX" ] || [ "$OS_ENV" = "WSL" ]; then
        PKM=$(judge_linux_package_manager)
        # apt
        if [ "$PKM" = "APT" ]; then
            sudo apt-get update
            sudo apt-get install make build-essential libssl-dev zlib1g-dev \
                libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
                libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
        # yum
        elif [ "$PKM" = "YUM" ]; then
            sudo yum install gcc zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel
        # dnf
        elif [ "$PKM" = "DNF" ]; then
            sudo dnf install make gcc zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel
        # pacman
        elif [ "$PKM" = "PACMAN" ]; then
            sudo pacman -S --noconfirm base-devel openssl zlib xz tk
        # alpine
        elif [ "$PKM" = "ALPINE" ]; then
            sudo apk add linux-headers
            sudo apk add --no-cache git bash build-base libffi-dev openssl-dev bzip2-dev zlib-dev xz-dev readline-dev sqlite-dev tk-dev
        # void
        elif [ "$PKM" = "VOID" ]; then
            xbps-install base-devel bzip2-devel openssl openssl-devel readline readline-devel sqlite-devel xz zlib zlib-devel
        else
            echo "Unknown package manager, skipping..."
            return 1
        fi
    # unknown
    else
        echo "Unknown OS, skipping..."
        return 1
    fi
}

install_and_setup_pyenv() {
    if [ -x "$(command -v pyenv)" ]; then
        echo "Updating pyenv..."
        pyenv update >>/dev/null 2>&1 &
        wait
    else
        echo "Installing pyenv..."
        curl -sSL https://pyenv.run | bash >>/dev/null 2>&1 &
        wait

        __pyenv_shell_cfg=$(check_shell_and_get_shell_config_file)
        if [ -f "$__pyenv_shell_cfg" ]; then
            if grep -q "pyenv" "$__pyenv_shell_cfg"; then
                :
            else
                echo "Adding pyenv to $__pyenv_shell_cfg..."
                {
                    echo ""
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

    # search latest pure python and install
    latest_python_version="$(pyenv install --list | grep -E "^\s+3\.[0-9]+\.[0-9]+$" | tail -n 1 | sed -e "s/^[[:space:]]*//")"
    echo "Installing python $latest_python_version with pyenv..."
    pyenv install "$latest_python_version" >>/dev/null 2>&1 &
    wait
    pyenv global "$latest_python_version"
    echo "Using python version: $latest_python_version"
}

install_and_setup_poetry() {
    echo "Installing or Updating poetry..."
    curl -sSL https://install.python-poetry.org | python3 - >>/dev/null 2>&1 &
    wait

    __poetryshell_cfg=$(check_shell_and_get_shell_config_file)
    if [ -f "$__poetryshell_cfg" ]; then
        if grep -q "poetry" "$__poetryshell_cfg"; then
            :
        else
            echo "Adding poetry to $__poetryshell_cfg..."
            {
                echo ""
                echo "# poetry"
                echo "export PATH=\"\$PATH:$HOME/.local/bin\""
            } >>"$__poetryshell_cfg"
            export PATH="$PATH:$HOME/.local/bin"
        fi
    fi

    poetry config virtualenvs.in-project true

    # Create a new poetry project
    if [ -f "pyproject.toml" ]; then
        poetry install
        poetry_status="true"
    else
        curl -OL "https://raw.githubusercontent.com/sushi-chaaaan/poetry-template/main/pyproject.toml"
        poetry install
        poetry_status="true"
    fi
}

setup_python_env() {
    install_python_deps
    install_and_setup_pyenv
    install_and_setup_poetry
}

create_vscode_workspace() {
    if [ $# -eq 0 ]; then
        echo "create_vscode_workspace requires workspace_file_name"
        return 1
    elif [ $# -eq 1 ]; then
        echo "create_vscode_workspace requires poetry status"
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

setup_vscode_workspace() {
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
        create_vscode_workspace "$workspace_file_name" "$poetry_status"
        countdown 5
    fi
}

# Main

# judge if I am in WSL
OS_ENV=$(judge_os) # MACOS or LINUX or WSL

if [ "$HOME" = "$(pwd)" ]; then
    echo "You are in your home directory."
    echo "making a new directory..."
    read -r -p "Please enter the name of the directory:" new_dir_name
    mkdir -p "$new_dir_name"
    cd "$new_dir_name" || exit
fi

if [ "$OS_ENV" = "WSL" ]; then
    # install vscode
    setup_vscode_wsl

    # setup python env
    poetry_status=""
    setup_python_env

    # create vscode workspace
    setup_vscode_workspace

    code -g "$workspace_file_name" -n

elif [ "$OS_ENV" = "LINUX" ]; then
    # setup python env
    poetry_status=""
    setup_python_env
elif [ "$OS_ENV" = "MACOS" ]; then
    # setup python env
    poetry_status=""
    setup_python_env
else
    echo "Unknown OS"
fi
