#!/bin/bash

# Check if .bashrc exists and source it
if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
fi

# ----------------- Define PATH ----------------- #
export PATH=$PATH:$HOME/go/bin:$HOME/.cargo/bin:$HOME/.local/bin
