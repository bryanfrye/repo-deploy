#!/bin/bash
command -v pylint >/dev/null 2>&1 || { echo "pylint not installed. Skipping."; exit 0; }
find . -name "*.py" -exec pylint {} +
