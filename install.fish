#!/usr/bin/env fish

set script_dir (realpath (dirname (status filename)))

exec sh "$script_dir/install.sh" $argv
