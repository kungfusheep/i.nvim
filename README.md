# i.nvim

A Neovim plugin that integrates with the `i` command-line journaling tool, opening a modal dialogue for creating journal entries at scheduled intervals.

<img width="665" alt="image" src="https://github.com/kungfusheep/i.nvim/assets/6867511/3de61f72-27be-498c-9853-c636e8cdf742">


## Features

- Opens a modal dialogue for creating journal entries at configurable intervals.
- Submits journal entries directly to the `i` tool.
- Customizable dialogue window size and default keymap.
- Automatically schedules the journal dialogue to open at the specified intervals.

## Prerequisites

- Neovim 0.5.0 or later
- The `i` command-line journaling tool (https://github.com/kungfusheep/i)

## Installation

You can install the plugin using your preferred package manager, below is an example using Lazy:

```lua
{
    "kungfusheep/i.nvim",
    event = "VeryLazy",
    config = function()
        require("i").setup()
    end,
```

## Configuration

You can customize the plugin's behavior by calling the `setup` function in your Neovim configuration file:

```lua
require("i").setup({
    use_schedule = true,         -- Automatically open the dialogue at the specified intervals
    launch_minutes = { 10, 40 }, -- Open the dialogue at 10 and 40 minutes past each hour
    dialogue_width = 50,         -- Set the dialogue window width to 50 columns
    dialogue_height = 10,        -- Set the dialogue window height to 10 lines
	keymap = {
		new_entry = "<leader>ie",
		quit_entry_normal = "<ESC>",
		quit_entry_insert = "<C-c>",
	},
})
```

The available configuration options are:

- `use_schedule`: Whether to automatically schedule the journal dialogue to open at the specified intervals (default: `true`).
- `launch_minutes`: A table of minutes of the hour to open the journal dialogue (default: `{ 10, 40 }`).
- `dialogue_width`: The width of the journal dialogue window (default: `50`).
- `dialogue_height`: The height of the journal dialogue window (default: `10`).
- `keymap`: The default keymap to open the journal dialogue (see above).

## Usage

- The journal dialogue will automatically open at the configured minutes of the hour.
- To manually open the journal dialogue, use the configured keymap (default: `<leader>ie`) or the `:IEntry` command.
- Enter your journal entry in the dialogue window.
- Press `<Enter>` to submit the journal entry using the `i` tool.

## Commands

- `:IEntry`: Opens the journal dialogue manually.

## Integration with the `i` Journaling Tool

This plugin integrates with the `i` command-line journaling tool (https://github.com/kungfusheep/i). When you submit a journal entry using the plugin, it is added to your `i` journal repository.

You can then use the various features provided by the `i` tool to manage, analyze, and interact with your journal entries. Some notable features include:

- Listing and filtering journal entries based on time ranges, mentions, and tags.
- Generating weekly digests and reminders using the GPT API.
- Analyzing your journal with arbitrary prompts using the GPT API.
- Executing Git commands on your journal repository for advanced operations.

For more details on how to use the `i` tool and its features, please refer to its documentation: https://github.com/kungfusheep/i#readme

## License

This plugin is released under the [MIT License](LICENSE).

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please submit a pull request on the [GitHub repository](https://github.com/kungfusheep/i.nvim).

