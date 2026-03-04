th.git = th.git or {}
th.git.unknown_sign = " "
th.git.modified_sign = "M"
require("git"):setup {
	-- Order of status signs showing in the linemode
	order = 1500,
}
