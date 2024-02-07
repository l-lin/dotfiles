#!/usr/bin/env bash

set -euo pipefail

ob_theme="${1:-Windows-10-Dark}"
ob_layout="${2:-DLIMC}"
ob_font="${3:-JetBrains Mono}"
ob_font_size="${4:-13}"
ob_menu="${5:-menu-icons.xml}"
ob_margin_t="${6:-0}"
ob_margin_b="${7:-0}"
ob_margin_l="${8:-0}"
ob_margin_r="${9:-0}"

namespace="http://openbox.org/3.4/rc"

openbox_dir="${HOME}/.config/openbox"
file_path="$openbox_dir/rc.xml"

# Theme
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:name' -v "${ob_theme}" "${file_path}"

# Title
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:titleLayout' -v "${ob_layout}" "${file_path}"

# Fonts
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="ActiveWindow"]/a:name' -v "${ob_font}" "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="ActiveWindow"]/a:size' -v "${ob_font_size}" "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="ActiveWindow"]/a:weight' -v Bold "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="ActiveWindow"]/a:slant' -v Normal "${file_path}"

xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="InactiveWindow"]/a:name' -v "${ob_font}" "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="InactiveWindow"]/a:size' -v "${ob_font_size}" "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="InactiveWindow"]/a:weight' -v Normal "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="InactiveWindow"]/a:slant' -v Normal "${file_path}"

xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="MenuHeader"]/a:name' -v "${ob_font}" "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="MenuHeader"]/a:size' -v "${ob_font_size}" "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="MenuHeader"]/a:weight' -v Bold "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="MenuHeader"]/a:slant' -v Normal "${file_path}"

xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="MenuItem"]/a:name' -v "${ob_font}" "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="MenuItem"]/a:size' -v "${ob_font_size}" "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="MenuItem"]/a:weight' -v Normal "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="MenuItem"]/a:slant' -v Normal "${file_path}"

xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="ActiveOnScreenDisplay"]/a:name' -v "${ob_font}" "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="ActiveOnScreenDisplay"]/a:size' -v "${ob_font_size}" "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="ActiveOnScreenDisplay"]/a:weight' -v Bold "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="ActiveOnScreenDisplay"]/a:slant' -v Normal "${file_path}"

xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="InactiveOnScreenDisplay"]/a:name' -v "${ob_font}" "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="InactiveOnScreenDisplay"]/a:size' -v "${ob_font_size}" "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="InactiveOnScreenDisplay"]/a:weight' -v Normal "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="InactiveOnScreenDisplay"]/a:slant' -v Normal "${file_path}"

# Openbox Menu Style
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:menu/a:file' -v "${ob_menu}" "${file_path}"

# Margins
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:margins/a:top' -v "${ob_margin_t}" "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:margins/a:bottom' -v "${ob_margin_b}" "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:margins/a:left' -v "${ob_margin_l}" "${file_path}"
xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:margins/a:right' -v "${ob_margin_r}" "${file_path}"

# Reload Openbox Config
openbox --reconfigure

