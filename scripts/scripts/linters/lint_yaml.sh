#!/bin/bash
command -v yamllint >/dev/null 2>&1 || { echo "yamllint not installed. Skipping."; exit 0; }
yamllint .
