#!/bin/bash
command -v rubocop >/dev/null 2>&1 || { echo "rubocop not installed. Skipping."; exit 0; }
rubocop .
