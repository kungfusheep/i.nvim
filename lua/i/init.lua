local api = vim.api

local M = {}

M.submit_journal_entry = function()
	local buf = api.nvim_get_current_buf()
	local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
	local entry = table.concat(lines, '\n')

	-- TODO: Save the journal entry to a file or database
	--
	print(entry)

	api.nvim_buf_delete(buf, { force = true })
end

local function open_journal_dialogue()
	local buf = api.nvim_create_buf(false, true)
	local width = 50
	local height = 10
	local x = (api.nvim_get_option('columns') - width) / 2
	local y = (api.nvim_get_option('lines') - height) / 2

	local opts = {
		style = 'minimal',
		relative = 'editor',
		width = width,
		height = height,
		row = y,
		col = x
	}

	local win = api.nvim_open_win(buf, true, opts)
	api.nvim_buf_set_option(buf, 'buftype', 'prompt')
	api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
	api.nvim_buf_set_option(buf, 'filetype', 'nvim-journal')

	api.nvim_buf_set_lines(buf, 0, -1, false, { 'Enter your journal entry:', '' })
	api.nvim_buf_set_option(buf, 'modifiable', true)
	api.nvim_win_set_option(win, 'cursorline', true)

	local submit_mapping = api.nvim_replace_termcodes('<CR>', true, false, true)
	api.nvim_buf_set_keymap(buf, 'i', submit_mapping,
		'<cmd>lua require("i").submit_journal_entry()<CR>', { noremap = true, silent = true })
end

api.nvim_create_user_command('JournalEntry', function()
	open_journal_dialogue()
end, {})

return M
