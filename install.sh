#!/bin/sh

set -eu

usage() {
    cat <<'EOF'
Usage: install.sh [--force] [--project path/to/plugin.vcxproj] [project-root]

Run from the root of one old Union 1.0m plugin repository.

Options:
  -f, --force          overwrite integration files from an earlier install
  -p, --project PATH   select a vcxproj when more than one is present
  -h, --help           show this help
EOF
}

force=false
project=

while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -f|--force)
            force=true
            shift
            ;;
        -p|--project)
            if [ "$#" -lt 2 ]; then
                echo "install.sh: $1 requires a path" >&2
                usage >&2
                exit 2
            fi
            project=$2
            shift 2
            ;;
        --project=*)
            project=${1#--project=}
            if [ -z "$project" ]; then
                echo "install.sh: --project requires a path" >&2
                usage >&2
                exit 2
            fi
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "install.sh: unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
        *)
            break
            ;;
    esac
done

if [ "$#" -gt 1 ]; then
    echo "install.sh: expected at most one project root" >&2
    usage >&2
    exit 2
fi

script_dir=$(CDPATH= cd -P "$(dirname "$0")" && pwd)
project_root=$(pwd -P)
if [ "$#" -eq 1 ]; then
    project_root=$1
fi

set -- "-DSOURCE_ROOT=$project_root"
if [ -n "$project" ]; then
    set -- "$@" "-DVCXPROJ=$project"
fi
if [ "$force" = true ]; then
    set -- "$@" -DFORCE=ON
fi

exec cmake "$@" -P "$script_dir/install.cmake"
