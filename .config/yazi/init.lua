th.git = th.git or {}
th.git.modified = ui.Style():fg('blue')
th.git.deleted = ui.Style():fg('red'):bold()
-- th.git.untracked = ui.Style():fg("yellow")
-- th.git.ignored = ui.Style():fg("brightblack")
-- th.git.unknown_sign = "?"
th.git.added_sign = 'A'
th.git.modified_sign = 'M'
th.git.deleted_sign = 'D'
th.git.untracked_sign = 'U'
th.git.ignored_sign = 'I'
require('git'):setup({ order = 0 })
-- ============== split plugin ==============
local mocha_light = '#89b4f9'
local mocha_black = '#323344'
require('yatline'):setup({
	style_a = {
		bg = mocha_light,
		fg = mocha_black,
		bg_mode = {
			normal = mocha_light,
			select = 'brightyellow',
			un_set = 'brightred',
		},
	},
	style_b = { bg = '#232336', fg = 'brightwhite' },
	style_c = { bg = mocha_black, fg = mocha_light },
	show_background = false,
	header_line = {
		left = {
			section_a = {
				{ type = 'line', name = 'tabs' },
			},
		},
		right = {
			section_a = {
				{ type = 'string', name = 'date', params = { '%H:%M' } },
			},
			section_b = {
				{ type = 'string', name = 'hovered_mtime' },
			},
		},
	},
	status_line = {
		left = {
			section_a = {
				{ type = 'string', name = 'tab_mode' },
			},
			section_b = {
				{ type = 'string', name = 'hovered_size' },
			},
			section_c = {
				{ type = 'string', name = 'hovered_path' },
				{ type = 'coloreds', name = 'count' },
			},
		},
		right = {
			section_a = {
				{ type = 'string', name = 'cursor_position' },
			},
			section_b = {
				{ type = 'string', name = 'hovered_ownership' },
			},
			section_c = {
				{ type = 'string', name = 'hovered_file_extension', params = { true } },
				{ type = 'coloreds', name = 'permissions' },
			},
		},
	},
})
