less_vim() {
	(cat <<'EOF') | do_uudecode > macros/less.vim
begin 644 macros/less.vim
EOF
# END OF macros/less.vim
}

vimcat_script() {
	(cat <<'EOF') | do_uudecode > bin/vimcat
begin 755 vimcat
EOF
# END OF vimcat
}

perldoc_vim() {
	(cat <<'EOF') | do_uudecode > syntax/perldoc.vim
begin 644 syntax/perldoc.vim
EOF
# END OF syntax/perldoc.vim
}

ansi_esc_vim() {
	(cat <<'EOF') | do_uudecode > autoload/AnsiEsc.vim
begin 644 autoload/AnsiEsc.vim
EOF
# END OF autoload/AnsiEsc.vim
}

ansi_esc_plugin_vim() {
	(cat <<'EOF') | do_uudecode > plugin/AnsiEscPlugin.vim
begin 644 plugin/AnsiEscPlugin.vim
EOF
# END OF plugin/AnsiEscPlugin.vim
}

cecutil_plugin_vim() {
	(cat <<'EOF') | do_uudecode > plugin/cecutil.vim
begin 644 plugin/cecutil.vim
EOF
# END OF plugin/cecutil.vim
}

autoload_vimpager_vim() {
	(cat <<'EOF') | do_uudecode > autoload/vimpager.vim
begin 644 autoload/vimpager.vim
EOF
# END OF autoload/vimpager.vim
}

plugin_vimpager_vim() {
	(cat <<'EOF') | do_uudecode > plugin/vimpager.vim
begin 644 plugin/vimpager.vim
EOF
# END OF plugin/vimpager.vim
}

autoload_vimpager_utils_vim() {
	(cat <<'EOF') | do_uudecode > autoload/vimpager_utils.vim
begin 644 autoload/vimpager_utils.vim
EOF
# END OF autoload/vimpager_utils.vim
}
