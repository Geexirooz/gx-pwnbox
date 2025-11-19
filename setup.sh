#!/bin/bash
set -euo pipefail # Exit on error, undefined variable, or failed pipeline

# ====================================== #
# Dotfiles and Python Tools Setup Script #
# ====================================== #
DATE=$(date +%Y%m%d_%H%M%S)
TARGET_DIR="$HOME"
TOOLS_DIR="$HOME/tools"
SCRIPTS_DIR="$TOOLS_DIR/scripts"
WORDLISTS_DIR="$HOME/wlists"
VENV="$HOME/python-tools"
TOOLS_VENV="gx_env"
ERROR_LOGS=/tmp/.gx_errors

# ==================================== #
#          Helper Functions            #
# ==================================== #

# ---------------- Clone quietly ----------------
git_clone_quiet() {
	local repo_url="$1"
	local dest_dir="$2"

	if [ ! -d "$dest_dir/.git" ]; then
		git clone --depth 1 --quiet "$repo_url" "$dest_dir"
	fi
}

# ---------------- setup pyenv for tools' directory tools ----------------
setup_tools_python_env() {
	echo "[*] Setting up $1's environment"
	cd "$TOOLS_DIR/$1"
	if [[ ! -d "$TOOLS_VENV" ]]; then
		python3 -m venv "$TOOLS_VENV" || {
			echo "Failed to create virtual environment" 2>$ERROR_LOGS
			exit 1
		}
	fi
	source "$TOOLS_VENV/bin/activate" || {
		echo "Failed to activate virtual environment" 2>$ERROR_LOGS
		exit 1
	}
	pip install -q -r requirements.txt || {
		echo "Failed to install Python tools" 2>$ERROR_LOGS
		exit 1
	}
	cd ~
}

# ---------------- pipx installation ----------------
pipx_it() {
	for pkg in "$@"; do
		pipx list | grep -F -q -- "$pkg" >/dev/null 2>$ERROR_LOGS && continue

		printf '[*] Installing %s\n' "$pkg"
		pipx --quiet install "$pkg" >/dev/null 2>$ERROR_LOGS || {
			printf 'failed to install %s\n' "$pkg" 2>$ERROR_LOGS
			return 1
		}
	done
}

# ---------------- Install Python Tools ----------------
install_python_tool() {
	local repo="$1"
	local target="$2"

	git_clone_quiet "$repo" "$TOOLS_DIR/$target"
	setup_tools_python_env "$target"
}

# ---------------- Install Golang tools ----------------
install_golang_tool() {
	local repo="$1"
	go install "$repo" >/dev/null 2>$ERROR_LOGS
}

# ---------------- Download Peas scripts ----------------
get_peas() {
	PEAS=$(basename "$1")
	if [ ! -f "$SCRIPTS_DIR/peas/$PEAS" ]; then
		wget -q "$1" -O "$SCRIPTS_DIR/peas/$PEAS" 2>$ERROR_LOGS
	fi
}

# ==================================== #
#       Installation Functions         #
# ==================================== #

# ---------------- Sudoise ----------------
ensure_sudo() {
	echo "[*] Checking sudo access..."
	# If already root, nothing to do
	[[ $EUID -eq 0 ]] && return

	command -v sudo >/dev/null 2>$ERROR_LOGS || {
		echo "error: sudo not found" 2>$ERROR_LOGS
		exit 1
	}

	# Prompt for password now. Fails if user cancels.
	sudo -v || {
		echo "error: sudo authentication failed" 2>$ERROR_LOGS
		exit 1
	}
}

# ---------------- Update Repositories ----------------
update_repos() {
	echo "[*] Updating repositories"
	sudo DEBIAN_FRONTEND=noninteractive apt-get -qq -y update >/dev/null 2>$ERROR_LOGS
}

# ---------------- Install Packages ----------------
install_packages() {
	echo "[*] Installing packages"
	local pkgs_raw="$1"
	local pkgs
	pkgs=$(echo "$pkgs_raw" | xargs)
	sudo DEBIAN_FRONTEND=noninteractive apt-get -qq -y install $pkgs >/dev/null 2>$ERROR_LOGS
}

# ---------------- Setup dotfiles symlinks ----------------
setup_symlink() {
	echo "[*] Setting up symlinks..."
	for f in * .*; do
		# Skip . and ..
		[[ "$f" == "." || "$f" == ".." ]] && continue

		# Exclude specific files/directories
		[[ "$f" == "README.md" || "$f" == ".gitignore" || "$f" == ".git" || "$f" == "setup.sh" ]] && continue

		SYMLINK_FILE="$TARGET_DIR/$f"

		# Skip if symlink already exists
		if [[ -L "$SYMLINK_FILE" ]]; then
			continue
		fi

		# Backup existing files/directories
		if [[ -e "$SYMLINK_FILE" || -d "$SYMLINK_FILE" ]]; then
			mv "$SYMLINK_FILE" "$SYMLINK_FILE.$DATE.off" || {
				echo "Failed to backup $SYMLINK_FILE" 2>$ERROR_LOGS
				continue
			}
			echo "Moved existing $SYMLINK_FILE to $SYMLINK_FILE.$DATE.off"
		fi

		# Create new symlink
		ln -s "$(pwd)/$f" "$SYMLINK_FILE" || {
			echo "Failed to create symlink for $f" 2>$ERROR_LOGS
			continue
		}
		echo "Created symlink: $SYMLINK_FILE -> $(pwd)/$f"
	done
}

# ---------------- Setup Vundle ----------------
install_vundle() {
	echo "[*] Installing Vundle..."
	# Create .vim if it does not exist
	[[ ! -d "$HOME/.vim" ]] && mkdir "$HOME/.vim"

	# ---------------- Setup colour scheme ----------------
	if [[ ! -d "$HOME/.vim/colors" ]]; then
		git_clone_quiet https://github.com/gosukiwi/vim-atom-dark.git /tmp/vim-atom-dark
		mv /tmp/vim-atom-dark/colors ~/.vim/
		rm -rf /tmp/vim-atom-dark
	fi

	# ---------------- Setup Vundle ----------------
	if [[ ! -d "$HOME/.vim/bundle/Vundle.vim" ]]; then
		git_clone_quiet https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim || {
			echo "Failed to clone Vundle" 2>$ERROR_LOGS
			exit 1
		}
		vim +PluginInstall +qall || {
			echo "Vim plugin installation failed" 2>$ERROR_LOGS
			exit 1
		}
	fi
}

# ---------------- Setup Python Virtual Environment ----------------
# Required for .vimrc ALE config
setup_python_venv() {
	if [[ ! -d "$VENV" ]]; then
		echo "[*] Creating Python virtual environment at $VENV"
		python3 -m venv "$VENV" || {
			echo "Failed to create virtual environment" 2>$ERROR_LOGS
			exit 1
		}
	fi

	echo "[*] Activating virtual environment"
	source "$VENV/bin/activate" || {
		echo "Failed to activate virtual environment" 2>$ERROR_LOGS
		exit 1
	}

	# Upgrade pip and install Python tools
	echo "[*] Installing pip packages"
	pip install -q --upgrade pip || {
		echo "Failed to upgrade pip" 2>$ERROR_LOGS
		exit 1
	}
	pip install -q flake8 black || {
		echo "Failed to install Python tools" 2>$ERROR_LOGS
		exit 1
	}

	# Deactivate virtual environment
	echo "[*] Deactivating virtual environment"
	deactivate
}

# ---------------- pipx tools ----------------
pipx_tools() {
	#tools
	pipx_it impacket oletools devious-winrm
	#netexec
	pipx --quiet install git+https://github.com/Pennyw0rth/NetExec >/dev/null 2>$ERROR_LOGS
}

# ---------------- python tools ----------------
python_tools() {
	echo "[*] Installing Python-based tools..."
	# Responder
	install_python_tool "https://github.com/lgandx/Responder.git" "responder"
	# NTLMhash-gen
	install_python_tool "https://github.com/Geexirooz/ntlmhash-gen.git" "ntlmhash-gen"
	# BloodyAD
	install_python_tool "https://github.com/CravateRouge/bloodyAD.git" "bloodyAD"
	# AesKrbKeyGen
	install_python_tool "https://github.com/Tw1sm/aesKrbKeyGen.git" "aesKrbKeyGen"
}

# ---------------- Golang tools ----------------
golang_tools() {
	echo "[*] Installing Golang-based tools..."
	# Ffuf
	install_golang_tool github.com/ffuf/ffuf/v2@latest
}

# ---------------- Ruby tools ----------------
ruby_tools() {
	echo "[*] Installing Ruby-based tools..."
	gem install evil-winrm wpscan >/dev/null 2>$ERROR_LOGS
}

# ---------------- Rust tools ----------------
rust_tools() {
	RUST_STATUS="SUCCESS"
	echo "[*] Installing Rust-based tools..."
	rustc --version >/dev/null 2>&1 || RUST_STATUS="FAILURE"
	if [[ "$RUST_STATUS" == "FAILURE" ]]; then
		rustup default stable >/dev/null 2>$ERROR_LOGS
	fi
	#rusthound-ce
	cargo install rusthound-ce >/dev/null 2>$ERROR_LOGS
}

# ---------------- Install Hashcat  ----------------
# Installing hashcat from source to have the most up to date version
install_hashcat() {
	# 1) define install location
	echo "[*] Installing Hashcat..."
	local HASHCAT_DIR="$TOOLS_DIR/hashcat"
	[ -f "$HASHCAT_DIR/hashcat" ] && return

	# 2) clone Jumbo
	git_clone_quiet https://github.com/hashcat/hashcat.git "$HASHCAT_DIR"
	cd "$HASHCAT_DIR"

	# Clean and build using all CPU cores:
	make -s clean >/dev/null 2>$ERROR_LOGS
	make -sj"$(nproc)" >/dev/null 2>$ERROR_LOGS
}

# ---------------- Install John the Ripper ----------------
install_john() {
	echo "[*] Installing John the Ripper..."
	# 1) define install location
	JDIR="$TOOLS_DIR/john"
	[ -f "$JDIR/run/john" ] && return

	# 2) clone Jumbo
	git_clone_quiet https://github.com/openwall/john.git "$JDIR"
	cd "$JDIR/src"

	# 3) Configure and build
	./configure >/dev/null 2>$ERROR_LOGS
	# Clean and build using all CPU cores:
	make -s clean >/dev/null 2>$ERROR_LOGS
	make -sj"$(nproc)" >/dev/null 2>$ERROR_LOGS
}

# ---------------- Install msfconsole ----------------
install_msf() {
	echo "[*] Installing Metasploit console..."
	[ -f "/opt/metasploit-framework/bin/msfconsole" ] && return
	(curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb >/tmp/msfinstall &&
		chmod 755 /tmp/msfinstall &&
		/tmp/msfinstall) >/dev/null 2>$ERROR_LOGS
}

# ---------------- Install Pwndbg ----------------
install_pwndb() {
	if [[ ! -L "/usr/local/bin/pwndbg" ]]; then
		echo "[*] Installing pwndbg..."
		(curl -qsL 'https://install.pwndbg.re' | sh -s -- -t pwndbg-gdb) >/dev/null 2>$ERROR_LOGS
	fi
}

# ---------------- install Burpsuite ----------------
install_burpsuite() {
	echo "[*] Installing Burpsuite..."
	local BURP_STATUS="SUCCESS"
	BurpSuiteCommunity --version >/dev/null 2>$ERROR_LOGS || BURP_STATUS="FAILURE"
	if [[ "$BURP_STATUS" == "FAILURE" ]]; then
		local BURP_VERSION='2025.10.4'
		local BURP_TMP_PATH=/tmp/burpsuite.sh
		local BURP_ANSWERS='/tmp/burpsuite_installer_answers.tmp'
		wget -q "https://portswigger.net/burp/releases/download?product=community&version=$BURP_VERSION&type=Linux" -O $BURP_TMP_PATH
		echo -ne "\n\n\n\n" >$BURP_ANSWERS
		chmod u+x $BURP_TMP_PATH
		$BURP_TMP_PATH <$BURP_ANSWERS >/dev/null 2>$ERROR_LOGS
		rm $BURP_TMP_PATH $BURP_ANSWERS
	fi
}
# ---------------- install bloodhound-ce ----------------
install_bloodhound-ce() {
	echo "[*] Installing Bloodhound-ce..."
	# Check if bloodhound is already installed
	local BLOODHOUND_STATUS="SUCCESS"
	# grep -q did not work
	docker images | grep bloodhound >/dev/null || BLOODHOUND_STATUS="FAILURE"

	local BLOODHOUND_PATH="$HOME/.local/bin/bloodhound-cli"

	# If Docker image is missing, then ensure the CLI is downloaded.
	if [[ "$BLOODHOUND_STATUS" == "FAILURE" ]]; then
		local BLOODHOUND_TAR_PATH="$BLOODHOUND_PATH-linux-amd64.tar.gz"

		# If binary is missing, download it.
		if [ ! -f "$BLOODHOUND_PATH" ]; then
			# Download, extract, and remove tar.gz
			wget -q 'https://github.com/SpecterOps/bloodhound-cli/releases/latest/download/bloodhound-cli-linux-amd64.tar.gz' -O "$BLOODHOUND_TAR_PATH" 2>$ERROR_LOGS
			tar -xvzf "$BLOODHOUND_TAR_PATH" -C "$HOME/.local/bin/" >/dev/null 2>$ERROR_LOGS
			rm "$BLOODHOUND_TAR_PATH"
		fi
	fi

	# If Docker image is missing but the binary is existing, just install it
	if [[ "$BLOODHOUND_STATUS" == "FAILURE" ]] && [ -f "$BLOODHOUND_PATH" ]; then
		# Install it and bring down the containers
		($BLOODHOUND_PATH install && $BLOODHOUND_PATH down) >/dev/null 2>$ERROR_LOGS
	fi
}

# ---------------- Download Peas scripts ----------------
download_peas() {
	if [ ! -d "$SCRIPTS_DIR/peas" ]; then
		mkdir "$SCRIPTS_DIR/peas"
	fi
	echo "[*] Downloading Peas scripts..."
	get_peas "https://github.com/peass-ng/PEASS-ng/releases/download/20251028-8d75ce03/linpeas.sh"
}

# ---------------- Download SharpCollection ----------------
download_sharpcollection() {
	if [ ! -d "$TOOLS_DIR/SharpCollection" ]; then
		echo "[*] Downloading SharpCollection..."
		git_clone_quiet "https://github.com/Flangvik/SharpCollection.git" "$TOOLS_DIR/SharpCollection"
	fi
}

# ---------------- Download Seclists ----------------
download_seclists() {
	if [ ! -d "$WORDLISTS_DIR/SecLists-master" ]; then
		echo "[*] Downloading Seclists..."
		wget -q -c https://github.com/danielmiessler/SecLists/archive/master.zip -O "$WORDLISTS_DIR/SecLists.zip" &&
			unzip -q "$WORDLISTS_DIR/SecLists.zip" -d "$WORDLISTS_DIR" &&
			rm -f "$WORDLISTS_DIR/SecLists.zip"
	fi
}

# ---------------- Profiles ----------------
init_setup() {
	ensure_sudo
	update_repos
	utilities="vim tmux net-tools curl wget zip python3-venv pipx 7zip"
	install_packages "$utilities"
	setup_symlink
	install_vundle
	setup_python_venv
}

core_setup() {
	init_setup
	vimrc_reqs="vim-nox shellcheck shfmt clang-format clang-tidy cppcheck"
	# concatenate the tools
	pkgs="$vimrc_reqs"
	install_packages "$pkgs"
}

attack_setup() {
	echo "[*] Creating tools/wordlists directories"
	[ ! -d "$SCRIPTS_DIR" ] && mkdir -p "$SCRIPTS_DIR" # Create $TOOLS_DIR as well
	[ ! -d "$WORDLISTS_DIR" ] && mkdir "$WORDLISTS_DIR"
	core_setup
	common_deps="build-essential git pkg-config autoconf libssl-dev zlib1g-dev libbz2-dev libgmp-dev libnss3-dev libkrb5-dev libpcap-dev libsqlite3-dev python3 python3-pip yasm liblzma-dev libzstd-dev ruby-dev gcc-mingw-w64-x86-64 musl-tools clang libclang-dev rustup"
	network_tools="tcpdump wireshark"
	advanced_tools="docker.io docker-compose-v2 net-tools golang-go"
	scanners="nmap"
	linux_tools="nfs-common"
	windows_tools="smbclient"
	kali_tools="hashid"
	misc_tools="ntpdate sqlite3"
	# concatenate the tools
	pkgs="$common_deps $network_tools $advanced_tools $scanners $kali_tools $windows_tools $linux_tools $misc_tools"
	install_packages "$pkgs"
	pipx_tools
	python_tools
	golang_tools
	ruby_tools
	rust_tools
	install_hashcat
	install_john
	install_msf
	install_pwndb
	install_burpsuite
	install_bloodhound-ce
	download_peas
	download_sharpcollection
	download_seclists
}

# ---------------- Usage ----------------
usage() {
	cat <<EOF
Usage:
  bash setup.sh core
  bash setup.sh attack
  bash setup.sh help
EOF
}

# ---------------- Main ----------------
if [[ $# -lt 1 ]]; then
	usage
	exit 1
fi

cmd="$1"
shift || true

case "$cmd" in
core)
	core_setup
	;;
attack)
	attack_setup
	;;
help | --help | -h)
	usage
	;;
*)
	echo "Unknown command: $cmd" >&2
	usage
	exit 2
	;;
esac
