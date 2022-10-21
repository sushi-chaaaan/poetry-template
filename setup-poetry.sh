#!/bin/bash

# インストールするバージョンを指定してください
# 個人的には3.10.xを強く推奨します
PYTHON_VERSION="3.10.8"

# dependencies
sudo apt update
sudo apt install -y \
    git \
    curl \
    make \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    wget \
    curl \
    llvm \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev

# install pyenv
# 本家のインストールに従っても良かったのですが
# ここでは公式でも紹介されている
# Automatic Installerを使います
# https://github.com/pyenv/pyenv
# https://github.com/pyenv/pyenv-installer
curl https://pyenv.run | bash

echo '# pyenv' >>~/.bashrc
echo 'export PYENV_ROOT="$HOME/.pyenv"' >>~/.bashrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >>~/.bashrc
echo 'eval "$(pyenv init -)"' >>~/.bashrc

export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# install python
pyenv install "$PYTHON_VERSION"
pyenv local "$PYTHON_VERSION"

# install poetry
curl -sSL https://install.python-poetry.org | python3 -

poetry config virtualenvs.in-project true
poetry install
poetry update
