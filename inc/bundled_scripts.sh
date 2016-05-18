extract_bundled_scripts() {
	mkdir "$runtime"

	(
		cd "$runtime"

		mkdir macros autoload plugin syntax bin

		# we extract all files in case the user uses :Page or :Page!
		autoload_vimpager_vim
		autoload_vimpager_utils_vim
		autoload_vimcat_vim
		plugin_vimpager_vim
		macros_less_vim

		syntax_perldoc_vim

		autoload_AnsiEsc_vim
		plugin_AnsiEscPlugin_vim
		plugin_cecutil_vim

		if [ -n "$cat_files" ]; then
			vimcat_script
			chmod +x ./bin/vimcat
		fi
	)
}
