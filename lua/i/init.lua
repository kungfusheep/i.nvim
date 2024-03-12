local api = vim.api

local M = {}

function M.submit_journal_entry()
	local buf = api.nvim_get_current_buf()
	local lines = api.nvim_buf_get_lines(buf, 1, -1, false) -- ignore the first line
	local entry = table.concat(lines, "\n")

	-- strip off leading % chars from the entry
	entry = entry:gsub("%%", "")
	-- trim
	entry = entry:gsub("^%s*(.-)%s*$", "%1")

	-- run the i command in bash
	local isource = os.getenv("I_SOURCE_DIR")
	local command = string.format('/bin/bash -c "source %s/i.sh && i \\"%s\\""', isource, entry)
	local output = vim.fn.system(command)

	if vim.v.shell_error ~= 0 then
		print("Error submitting journal entry:")
		print(output)
	end

	api.nvim_buf_delete(buf, { force = true })
end

local function open_journal_dialogue()
	local buf = api.nvim_create_buf(false, true)
	local width = 50
	local height = 10
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
	api.nvim_buf_set_option(buf, "buftype", 'prompt')
	api.nvim_buf_set_option(buf, "bufhidden", 'wipe')
	api.nvim_buf_set_option(buf, "filetype", 'nvim-journal')

	api.nvim_buf_set_lines(buf, 0, -1, false, { "Enter your journal entry:" })
	api.nvim_buf_set_option(buf, "modifiable", true)
	api.nvim_win_set_option(win, "cursorline", true)
	-- automatically go into insert mode
	api.nvim_command("startinsert")

	local submit_mapping = api.nvim_replace_termcodes("<CR>", true, false, true)
	api.nvim_buf_set_keymap(buf, 'i', submit_mapping,
		'<cmd>lua require("i").submit_journal_entry()<CR>', { noremap = true, silent = true })
end

api.nvim_create_user_command("IEntry", function()
	open_journal_dialogue()
end, {})

local function schedule_journal_entry()
	local target_minutes = { 10, 40 } -- Change these values to set the desired minutes within the hour

	local timer = vim.loop.new_timer()
	local function schedule_callback()
		local current_time = os.date("*t")
		local current_minute = current_time.min

		local next_target_minute = nil
		for _, minute in ipairs(target_minutes) do
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
			local delay_ms = (60 - current_minute + target_minutes[1]) * 60 * 1000
			timer:start(delay_ms, 0, vim.schedule_wrap(schedule_callback))
		end
	end

	schedule_callback()
end
schedule_journal_entry()

-- define a keymap to open the journal dialogue
vim.keymap.set("n", "<leader>ie", "<cmd>IEntry<CR>", { noremap = true, silent = true })

return M
