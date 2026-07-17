#!/usr/bin/env fish

function usage
    echo "Usage: fish install.fish [--force] [--project path/to/plugin.vcxproj] [project-root]"
    echo
    echo "Run from the root of one old Union 1.0m plugin repository."
end

argparse 'h/help' 'f/force' 'p/project=' -- $argv
or begin
    usage
    exit 2
end

if set -q _flag_help
    usage
    exit 0
end

if test (count $argv) -gt 1
    usage
    exit 2
end

set script_dir (realpath (dirname (status filename)))
set project_root (pwd)
if test (count $argv) -eq 1
    set project_root (realpath $argv[1])
end

set cmake_args "-DSOURCE_ROOT=$project_root"
if set -q _flag_project
    set -a cmake_args "-DVCXPROJ=$_flag_project"
end
if set -q _flag_force
    set -a cmake_args -DFORCE=ON
end

cmake $cmake_args -P "$script_dir/install.cmake"
