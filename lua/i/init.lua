local api = vim.api

local M = {}

-- default configuration
local config = {
	use_schedule = true,    -- whether to schedule the journal dialogue to open at defined intervals
	launch_minutes = { 10, 40 }, -- the minutes of the hour to open the journal dialogue
	dialogue_width = 50,
	dialogue_height = 10,
	keymap = {
		new_entry = "<leader>ie",
		submit_entry = "<CR>",
		quit_entry_normal = "<ESC>",
		quit_entry_insert = "<C-c>",
	},
}

-- submit_journal_entry submits the current journal buffer's contents as a journal entry to the i command
function M.submit_journal_entry()
	local buf = api.nvim_get_current_buf()
	local lines = api.nvim_buf_get_lines(buf, 1, -1, false) -- ignore the first line
	local entry = table.concat(lines, "\n")

	entry = entry:gsub("%%", "")        -- remove any percent signs
	entry = entry:gsub("^%s*(.-)%s*$", "%1") -- trim

	local command = string.format('/bin/bash -c "source %s/i.sh && i \\"%s\\""', os.getenv("I_SOURCE_DIR"), entry)
	local output = vim.fn.system(command)

	if vim.v.shell_error ~= 0 then
		print("Error submitting journal entry:")
		print(output)
	end

	M.close_journal_entry()
end

-- close_journal_entry closes the current journal buffer and window
function M.close_journal_entry()
	local buf = api.nvim_get_current_buf()
	api.nvim_buf_delete(buf, { force = true })
end

-- open_journal_dialogue opens a new buffer and window for the user to enter a journal entry
local function open_journal_dialogue()
	local buf = api.nvim_create_buf(false, true)
	vim.b[buf].copilot_enabled = false -- disable copilot for this buffer
	local width = config.dialogue_width
	local height = config.dialogue_height
	local x = (api.nvim_get_option("columns") - width) / 2
	local y = (api.nvim_get_option("lines") - height) / 2

	local win = api.nvim_open_win(buf, true, { -- opts
		style = "minimal",
		relative = "editor",
		width = width,
		height = height,
		row = y,
		col = x
	})
	api.nvim_buf_set_option(buf, "buftype", "nofile")
	api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	api.nvim_buf_set_option(buf, "filetype", "nvim-journal")

	api.nvim_buf_set_lines(buf, 0, -1, false, { "Journal", "", "i " })
	api.nvim_buf_set_option(buf, "modifiable", true)
	api.nvim_win_set_option(win, "cursorline", true)

	api.nvim_win_set_cursor(win, { 3, 3 })

	-- automatically go into insert mode
	api.nvim_command("startinsert")

	local submit_mapping = api.nvim_replace_termcodes(config.keymap.submit_entry, true, false, true)
	api.nvim_buf_set_keymap(buf, "i", submit_mapping,
		"<cmd>lua require('i').submit_journal_entry()<CR>", { noremap = true, silent = true })

	-- same for escape
	api.nvim_buf_set_keymap(buf, "n", config.keymap.quit_entry_normal, "<cmd>bdelete!<CR>",
		{ noremap = true, silent = true })
	api.nvim_buf_set_keymap(buf, "i", config.keymap.quit_entry_insert, "<cmd>bdelete!<CR>",
		{ noremap = true, silent = true })
end


-- schedule_journal_entry schedules the journal dialogue to open at the next target minute
local function schedule_journal_entry()
	local launch_minutes = config.launch_minutes -- how often to open the journal dialogue

	local timer = vim.loop.new_timer()
	local function schedule_callback()
		local current_time = os.date("*t")
		local current_minute = current_time.min

		local next_target_minute = nil
		for _, minute in ipairs(launch_minutes) do
			if minute > current_minute then
				next_target_minute = minute
				break
			end
		end

		if next_target_minute then
			-- Schedule the timer to run at the next target minute
			local delay_ms = (next_target_minute - current_minute) * 60 * 1000
			timer:start(delay_ms, 0, vim.schedule_wrap(function()
				-- Check if a journal buffer is already open
				local buffers = api.nvim_list_bufs()
				for _, buf in ipairs(buffers) do
					if api.nvim_buf_get_option(buf, "filetype") == "nvim-journal" then
						return
					end
				end

				-- Open the journal dialogue if no journal buffer is open
				open_journal_dialogue()

				-- Reschedule the timer for the next target minute
				schedule_callback()
			end))
		else
			-- Schedule the timer to run at the first target minute in the next hour
			local delay_ms = (60 - current_minute + launch_minutes[1]) * 60 * 1000
			timer:start(delay_ms, 0, vim.schedule_wrap(schedule_callback))
		end
	end

	schedule_callback()
end

local function setup_keymap()
	vim.keymap.set("n", config.keymap.new_entry, "<cmd>IEntry<CR>", { noremap = true, silent = true })
end

-- setup function to allow users to override default configuration
function M.setup(user_config)
	assert(os.getenv("I_SOURCE_DIR") ~= nil, "I_SOURCE_DIR environment variable not set. You may need to update i.")

	config = vim.tbl_deep_extend("force", config, user_config or {})

	api.nvim_create_user_command("IEntry", function()
		open_journal_dialogue()
	end, {})

	setup_keymap()

	if config.use_schedule and #config.launch_minutes > 0 then
		schedule_journal_entry()
	end
end

return M
