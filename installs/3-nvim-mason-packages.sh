#!/usr/bin/env bash
# ----------------------------------------------------
# Manually install some Neovim's Mason packages:
# - JDTLS: release train is a bit slow... (Java 21 still not supported at the time of coding this script).
# - vscode-java-test: no longer provides an archive, so Mason cannot install it, hence the need to manually install it.
# NOTE: May not be needed anymore as there's a custom registry that provides both packages: https://github.com/nvim-java/mason-registry.
# ----------------------------------------------------

set -euo pipefail

project_build_folder="${HOME}/tmp"
nvim_mason_package_folder="${HOME}/.local/share/nvim/mason/packages"
nvim_mason_share_folder="${HOME}/.local/share/nvim/mason/share"

green='\e[0;32m'
escape='\e[0m'

info() {
	echo -e "${green}INF ${escape} ${1}"
}

clone_and_update_project() {
  local git_repo_url="${1}"
  local target_folder="${2}"
  local git_branch_name="${3}"

	if [ ! -d "${target_folder}" ]; then
		info "${target_folder} does not exist => cloning project"
		mkdir -p "${target_folder}"
		cd "${target_folder}"
		git clone "${git_repo_url}" "${target_folder}"
	fi

	info "fetching latest ${git_repo_url} changes"
	cd "${target_folder}"
	git pull origin "${git_branch_name}"
}
backup_folder() {
  local folder="${1}"

	if [ -d "${folder}" ]; then
		local current_time
		current_time=$(date -u "+%Y-%m-%dT%H:%M:%SZ")
		info "backup existing folder '${folder}' to '${folder}.${current_time}'"
		mv "${folder}" "${folder}.${current_time}"
	fi
}

# Manually installing or upadting JDTLS because release train is a bit slow... (Java 21 still not supported at the time of coding this script).
install_or_update_jdtls() {
	local jdtls_repo="git@github.com:eclipse-jdtls/eclipse.jdt.ls.git"
	local lombok_download_url="https://projectlombok.org/downloads/lombok.jar"
	local jdtls_build_folder="${project_build_folder}/jdtls"
	local nvim_mason_package_jdtls_folder="${nvim_mason_package_folder}/jdtls"

	info "installing or updating JDTLS"

  clone_and_update_project "${jdtls_repo}" "${jdtls_build_folder}" "master"

	cd "${jdtls_build_folder}"

	info "building JDTLS project"
	./mvnw clean package -DskipTests

  backup_folder "${nvim_mason_package_jdtls_folder}"

	info "installing JDTLS to '${nvim_mason_package_jdtls_folder}'"
	cp -r org.eclipse.jdt.ls.product/target/repository "${nvim_mason_package_jdtls_folder}"

	info "download latest lombok to '${nvim_mason_package_jdtls_folder}/lombok.jar'"
	curl -s -L -o "${nvim_mason_package_jdtls_folder}/lombok.jar" "${lombok_download_url}"

	info "JDTLS installed / updated SUCCESSFULLY"
}

# vscode-java-test no longer provides an archive, so Mason cannot install it, hence the need to manually install it.
install_or_update_vscode_java_test() {
	local vscode_java_test_repo="git@github.com:microsoft/vscode-java-test.git"
	local vscode_java_test_build_folder="${project_build_folder}/vscode-java-test"
	local nvim_mason_package_vscode_java_test_folder="${nvim_mason_package_folder}/java-test"
  local nvim_mason_share_vscode_java_test_folder="${nvim_mason_share_folder}/java-test"

	info "installing or updating vscode-java-test"

  clone_and_update_project "${vscode_java_test_repo}" "${vscode_java_test_build_folder}" "main"

	cd "${vscode_java_test_build_folder}"

	info "building vscode-java-test project"
  npm install
  npm run build-plugin
  npm run vscode:prepublish

  backup_folder "${nvim_mason_package_vscode_java_test_folder}"
  backup_folder "${nvim_mason_share_vscode_java_test_folder}"

	info "installing vscode-java-test to '${nvim_mason_package_vscode_java_test_folder}'"
  mkdir -p "${nvim_mason_package_vscode_java_test_folder}/extension"
  cp -r "${vscode_java_test_build_folder}/dist" "${nvim_mason_package_vscode_java_test_folder}/extension"
  cp -r "${vscode_java_test_build_folder}/server" "${nvim_mason_package_vscode_java_test_folder}/extension"
  cp -r "${vscode_java_test_build_folder}/resources" "${nvim_mason_package_vscode_java_test_folder}/extension"

  info "creating symlinks to '${nvim_mason_share_vscode_java_test_folder}'"
  mkdir -p "${nvim_mason_share_vscode_java_test_folder}"
  for f in "${nvim_mason_package_vscode_java_test_folder}"/extension/server/*.jar; do
    ln -s "${f}" "${nvim_mason_share_vscode_java_test_folder}"
  done

	info "vscode-java-test installed / updated SUCCESSFULLY"
}

# -----------------------------------------------------------

show_help() {
  cat << EOF
Install or update Neovim's Mason package.

Usage: ${0##*/} <flags> <args>

Examples:
    # Install / Update JDTLS (https://github.com/eclipse-jdtls/eclipse.jdt.ls)
      ${0##*/} jdtls
    # Install / Update vscode-java-test (https://github.com/microsoft/vscode-java-test)
      ${0##*/} vscode-java-test

Available commands:
    jdtls                 Install / Update JDTLS
    vscode-java-test      Install / Update vscode-java-test

Flags:
    -h, --help            Display help

EOF
}

main() {
  # check the number of arguments
  if [ $# -eq 0 ]; then
    show_help
    exit
  fi

  TEMP=$(getopt -o 'h' --long 'help' -n "${0##*/}" -- "$@")
  eval set -- "$TEMP"
  unset TEMP
  while true; do
    case "${1}" in
      '-h'|'--help')
        show_help
        exit
        ;;
      '--')
        shift
        break
        ;;
      *)
        break
        ;;
    esac

    shift
  done

  case "${1}" in
    'jdtls')
      install_or_update_jdtls
      ;;
    'vscode-java-test')
      install_or_update_vscode_java_test
      ;;
    *)
      show_help
      ;;
  esac
}

#main "$@"
