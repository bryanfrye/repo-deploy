#!/bin/bash
command -v terraform >/dev/null 2>&1 || { echo "terraform not installed. Skipping."; exit 0; }
terraform fmt -check -recursive
