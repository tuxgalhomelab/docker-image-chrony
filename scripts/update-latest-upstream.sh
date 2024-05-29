#!/usr/bin/env bash

set -e -o pipefail

script_parent_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
git_repo_dir="$(realpath "${script_parent_dir:?}/..")"

PACKAGES_FILE="${git_repo_dir:?}/config/PACKAGES_INSTALL"

get_package_version() {
    arg="${1:?}"
    sed -n -E "s/^${arg:?}=(.*)\$/\\1/p" ${PACKAGES_FILE:?}
}

pkg="Chrony"
pkg_install_name="chrony"

existing_upstream_ver=$(get_package_version ${pkg_install_name:?})
make update_packages
latest_upstream_ver=$(get_package_version ${pkg_install_name:?})

if [[ "${existing_upstream_ver:?}" == "${latest_upstream_ver:?}" ]]; then
    echo "Existing config is already up to date and pointing to the latest upstream ${pkg:?} version '${latest_upstream_ver:?}'"
else
    echo "Updated ${pkg:?} '${existing_upstream_ver:?}' -> '${latest_upstream_ver:?}'"
    git add ${PACKAGES_FILE:?}
    git commit -m "feat: Bump upstream ${pkg:?} version to ${latest_upstream_ver:?}."
fi
