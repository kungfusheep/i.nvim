if exists("g:i_journal_plugin")
  finish
endif
let g:i_journal_plugin = 1

lua require("i")
