vim.g.mapleader = " "
vim.opt.breakindent = true
vim.opt.clipboard = "unnamedplus"
vim.opt.completeopt = "menuone,noselect"
vim.opt.fileformat = "unix"
vim.opt.hlsearch = false
vim.opt.ignorecase = true -- ignore case in search
-- vim.opt.lazyredraw = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 2 -- keep somelines above and below cursor
vim.opt.shiftwidth = 4
vim.opt.signcolumn = "yes" -- always draw sign column. prevent buffer moving when adding/deleting sign
vim.opt.smartcase = true -- case-sensitive if contains capital
vim.opt.tabstop = 4
vim.opt.termguicolors = true -- colors in terminal
vim.opt.timeoutlen = 700
vim.opt.undofile = true -- permanent undo
vim.opt.updatetime = 250 -- update swap file more
vim.opt.wrap = false

-- keymap
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>")
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
vim.keymap.set("n", ";", ":")
vim.keymap.set({ "n", "i", "v", "s", "x", "c", "o", "l", "t" }, "<c-j>", "<Esc>")
vim.keymap.set({ "n", "i", "v", "s", "x", "c", "o", "l", "t" }, "<c-k>", "<Esc>")
vim.keymap.set("", "H", "^")
vim.keymap.set("", "L", "$")
vim.keymap.set("n", "<leader><leader>", "<c-^>")
-- always center search results
vim.keymap.set("n", "n", "nzz", { silent = true })
vim.keymap.set("n", "N", "Nzz", { silent = true })
vim.keymap.set("n", "*", "*zz", { silent = true })
vim.keymap.set("n", "#", "#zz", { silent = true })
vim.keymap.set("n", "g*", "g*zz", { silent = true })
-- "very magic" (less escaping needed) regexes by default
vim.keymap.set("n", "?", "?\\v")
vim.keymap.set("n", "/", "/\\v")
vim.keymap.set("c", "%s/", "%sm/")
-- let the left and right arrows be useful: they can switch buffers
vim.keymap.set("n", "<left>", ":bp<cr>")
vim.keymap.set("n", "<right>", ":bn<cr>")
-- make j and k move by visual line, not actual line, when text is soft-wrapped
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")

-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function() vim.highlight.on_yank({ timeout = 700 }) end,
	group = highlight_group,
	pattern = "*",
})

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
	spec = {
		-- vimscript
		{ "airblade/vim-rooter" },
		{ "tpope/vim-sleuth" },
		{ "tpope/vim-surround" },
		{ "junegunn/vim-easy-align", config = function() vim.keymap.set({ "n", "v" }, "ga", ":EasyAlign<cr>") end },

		-- visual
		{ "RRethy/base16-nvim", config = function() vim.cmd.colorscheme("base16-catppuccin-mocha") end },
		{
			"nvim-lualine/lualine.nvim",
			opts = { options = { icons_enabled = false, component_separators = "|", section_separators = "" } },
		},
		-- lua
		{
			"nvim-treesitter/nvim-treesitter",
			dependencies = {
				{ "folke/ts-comments.nvim", opts = {}, event = "VeryLazy" },
				{ "nvim-treesitter/nvim-treesitter-textobjects" },
				{ "nvim-treesitter/nvim-treesitter-context", opts = {} },
				{ "windwp/nvim-ts-autotag", opts = {} },
			},
			opts = {
				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = "<c-space>",
						node_incremental = "<c-space>",
						scope_incremental = "<c-s>",
						node_decremental = "<M-space>",
					},
				},
				textobjects = {
					select = {
						enable = true,
						lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
						keymaps = {
							-- You can use the capture groups defined in textobjects.scm
							["aa"] = "@parameter.outer",
							["ia"] = "@parameter.inner",
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							["ic"] = "@class.inner",
						},
					},
					move = {
						enable = true,
						set_jumps = true, -- whether to set jumps in the jumplist
						goto_next_start = {
							["]m"] = "@function.outer",
							["]]"] = "@class.outer",
						},
						goto_next_end = {
							["]M"] = "@function.outer",
							["]["] = "@class.outer",
						},
						goto_previous_start = {
							["[m"] = "@function.outer",
							["[["] = "@class.outer",
						},
						goto_previous_end = {
							["[M"] = "@function.outer",
							["[]"] = "@class.outer",
						},
					},
					swap = {
						enable = true,
						swap_next = {
							["<leader>a"] = "@parameter.inner",
						},
						swap_previous = {
							["<leader>A"] = "@parameter.inner",
						},
					},
				},
			},
			config = function(_, opts) require("nvim-treesitter.configs").setup(opts) end,
		},
		{
			"lewis6991/gitsigns.nvim",
			opts = {
				on_attach = function(bufnr)
					local gitsigns = require("gitsigns")

					local function map(mode, l, r, opts)
						opts = opts or {}
						opts.buffer = bufnr
						vim.keymap.set(mode, l, r, opts)
					end

					-- Navigation
					map("n", "]c", function()
						if vim.wo.diff then
							vim.cmd.normal({ "]c", bang = true })
						else
							gitsigns.nav_hunk("next")
						end
					end)

					map("n", "[c", function()
						if vim.wo.diff then
							vim.cmd.normal({ "[c", bang = true })
						else
							gitsigns.nav_hunk("prev")
						end
					end)

					-- Actions
					map("n", "<leader>hs", gitsigns.stage_hunk)
					map("n", "<leader>hr", gitsigns.reset_hunk)

					map("v", "<leader>hs", function() gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end)

					map("v", "<leader>hr", function() gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end)

					map("n", "<leader>hS", gitsigns.stage_buffer)
					map("n", "<leader>hR", gitsigns.reset_buffer)
					map("n", "<leader>hp", gitsigns.preview_hunk)
					map("n", "<leader>hi", gitsigns.preview_hunk_inline)

					map("n", "<leader>hb", function() gitsigns.blame_line({ full = true }) end)

					map("n", "<leader>hd", gitsigns.diffthis)

					map("n", "<leader>hD", function() gitsigns.diffthis("~") end)

					map("n", "<leader>hQ", function() gitsigns.setqflist("all") end)
					map("n", "<leader>hq", gitsigns.setqflist)

					-- Toggles
					map("n", "<leader>tb", gitsigns.toggle_current_line_blame)
					map("n", "<leader>td", gitsigns.toggle_deleted)
					map("n", "<leader>tw", gitsigns.toggle_word_diff)

					-- Text object
					map({ "o", "x" }, "ih", gitsigns.select_hunk)
				end,
			},
		},
		{ "stevearc/oil.nvim", opts = {} },
		{ "windwp/nvim-autopairs", opts = {}, event = "InsertEnter" },
		{ "echasnovski/mini.nvim", config = function() require("mini.ai").setup({ n_lines = 500 }) end },
		{
			"nvim-telescope/telescope.nvim",
			branch = "0.1.x",
			dependencies = {
				{ "nvim-lua/plenary.nvim" },
				{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
				{ "nvim-telescope/telescope-ui-select.nvim" },
			},
			config = function()
				require("telescope").setup({
					extensions = { ["ui-select"] = { require("telescope.themes").get_dropdown() } },
				})
				pcall(require("telescope").load_extension, "fzf")
				pcall(require("telescope").load_extension, "ui-select")

				-- See `:help telescope.builtin`
				local builtin = require("telescope.builtin")
				vim.keymap.set("n", "<c-p>", builtin.find_files, { desc = "[S]earch [F]iles" })
				vim.keymap.set("n", "<leader>;", builtin.buffers, { desc = "[S]earch [B]uffers" })
				vim.keymap.set("n", "<leader>sb", builtin.buffers, { desc = "[S]earch [B]uffers" })
				vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
				vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
				vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
				vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
				vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
				vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
				vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
				vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
				vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
				vim.keymap.set("n", "<leader>/", function()
					-- You can pass additional configuration to telescope to change theme, layout, etc.
					builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
						winblend = 10,
						previewer = false,
					}))
				end, { desc = "[/] Fuzzily search in current buffer" })
				vim.keymap.set(
					"n",
					"<leader>s/",
					function() builtin.live_grep({ grep_open_files = true, prompt_title = "Live Grep in Open Files" }) end,
					{ desc = "[S]earch [/] in Open Files" }
				)
			end,
		},
		{
			"stevearc/conform.nvim",
			opts = {
				formatters_by_ft = {
					html = { "prettierd" },
					javascript = { "prettierd" },
					json = { "prettierd" },
					lua = { "stylua" },
					markdown = { "prettierd" },
					nix = { "nixpkgs_fmt" },
					toml = { "taplo" },
					yaml = { "prettierd" },
				},
				format_on_save = { timeout_ms = 700, lsp_format = "fallback" },
			},
		},
		{
			"jake-stewart/multicursor.nvim",
			branch = "1.0",
			config = function()
				local mc = require("multicursor-nvim")
				mc.setup()

				-- Add or skip cursor above/below the main cursor.
				vim.keymap.set({ "n", "v" }, "<up>", function() mc.lineAddCursor(-1) end)
				vim.keymap.set({ "n", "v" }, "<down>", function() mc.lineAddCursor(1) end)
				vim.keymap.set({ "n", "v" }, "<leader><up>", function() mc.lineSkipCursor(-1) end)
				vim.keymap.set({ "n", "v" }, "<leader><down>", function() mc.lineSkipCursor(1) end)

				-- Add or skip adding a new cursor by matching word/selection
				vim.keymap.set({ "n", "v" }, "<leader>n", function() mc.matchAddCursor(1) end)
				vim.keymap.set({ "n", "v" }, "<leader>s", function() mc.matchSkipCursor(1) end)
				vim.keymap.set({ "n", "v" }, "<leader>N", function() mc.matchAddCursor(-1) end)
				vim.keymap.set({ "n", "v" }, "<leader>S", function() mc.matchSkipCursor(-1) end)

				-- Add all matches in the document
				vim.keymap.set({ "n", "v" }, "<leader>A", mc.matchAllAddCursors)

				-- You can also add cursors with any motion you prefer:
				vim.keymap.set("n", "<right>", function() mc.addCursor("w") end)
				vim.keymap.set("n", "<leader><right>", function() mc.skipCursor("w") end)

				-- Rotate the main cursor.
				vim.keymap.set({ "n", "v" }, "<left>", mc.nextCursor)
				vim.keymap.set({ "n", "v" }, "<right>", mc.prevCursor)

				-- Delete the main cursor.
				vim.keymap.set({ "n", "v" }, "<leader>x", mc.deleteCursor)

				-- Add and remove cursors with control + left click.
				vim.keymap.set("n", "<c-leftmouse>", mc.handleMouse)

				-- Easy way to add and remove cursors using the main cursor.
				vim.keymap.set({ "n", "v" }, "<c-q>", mc.toggleCursor)

				-- Clone every cursor and disable the originals.
				vim.keymap.set({ "n", "v" }, "<leader><c-q>", mc.duplicateCursors)

				vim.keymap.set("n", "<esc>", function()
					if not mc.cursorsEnabled() then
						mc.enableCursors()
					elseif mc.hasCursors() then
						mc.clearCursors()
					else
						-- Default <esc> handler.
					end
				end)
				vim.keymap.set("n", "<c-j>", function()
					if not mc.cursorsEnabled() then
						mc.enableCursors()
					elseif mc.hasCursors() then
						mc.clearCursors()
					else -- Default <c-j> handler.
					end
				end)
				vim.keymap.set("n", "<c-k>", function()
					if not mc.cursorsEnabled() then
						mc.enableCursors()
					elseif mc.hasCursors() then
						mc.clearCursors()
					else
						-- Default <c-k> handler.
					end
				end)
				vim.keymap.set("n", "<c-k>", function()
					if not mc.cursorsEnabled() then
						mc.enableCursors()
					elseif mc.hasCursors() then
						mc.clearCursors()
					end
				end)

				-- bring back cursors if you accidentally clear them
				vim.keymap.set("n", "<leader>gv", mc.restoreCursors)

				-- Align cursor columns.
				vim.keymap.set("v", "<leader>a", mc.alignCursors)

				-- Split visual selections by regex.
				vim.keymap.set("v", "S", mc.splitCursors)

				-- Append/insert for each line of visual selections.
				vim.keymap.set("v", "I", mc.insertVisual)
				vim.keymap.set("v", "A", mc.appendVisual)

				-- match new cursors within visual selections by regex.
				vim.keymap.set("v", "M", mc.matchCursors)

				-- Rotate visual selection contents.
				vim.keymap.set("v", "<leader>t", function() mc.transposeCursors(1) end)
				vim.keymap.set("v", "<leader>T", function() mc.transposeCursors(-1) end)

				-- Jumplist support
				vim.keymap.set({ "v", "n" }, "<c-i>", mc.jumpForward)
				vim.keymap.set({ "v", "n" }, "<c-o>", mc.jumpBackward)

				-- Customize how cursors look.
				local hl = vim.api.nvim_set_hl
				hl(0, "MultiCursorCursor", { link = "Cursor" })
				hl(0, "MultiCursorVisual", { link = "Visual" })
				hl(0, "MultiCursorSign", { link = "SignColumn" })
				hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
				hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
				hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
			end,
		},
		{ "williamboman/mason.nvim" },
		{ "williamboman/mason-lspconfig.nvim" },
		{
			"saghen/blink.cmp",
			dependencies = { "rafamadriz/friendly-snippets" },
			-- use a release tag to download pre-built binaries
			version = "1.*",
			opts = {
				keymap = { preset = "default" },
				appearance = {
					nerd_font_variant = "mono",
				},
				completion = { documentation = { auto_show = false } },
				sources = {
					default = { "lsp", "path", "snippets", "buffer" },
				},
				fuzzy = { implementation = "prefer_rust_with_warning" },
			},
			opts_extend = { "sources.default" },
		},
		{ "neovim/nvim-lspconfig" },
		{ "j-hui/fidget.nvim", opts = {} },
		{ "folke/trouble.nvim", opts = {} },
	},
})

require("mason").setup({})
require("mason-lspconfig").setup({
	handlers = { function(server_name) require("lspconfig")[server_name].setup({ single_file_support = true }) end },
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
	callback = function(event)
		local map = function(keys, func, desc, mode)
			mode = mode or "n"
			vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
		end

		map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
		map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
		map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
		map("go", vim.lsp.buf.type_definition, "[G]oto type definition")
		map("gs", vim.lsp.buf.signature_help, "[G]oto [S]ingature help")
		map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
		map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
		map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
		map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
		map("<leader>a", vim.lsp.buf.code_action, "Code [A]ction", { "n", "x" })
		map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

		local function client_supports_method(client, method, bufnr)
			if vim.fn.has("nvim-0.11") == 1 then
				return client:supports_method(method, bufnr)
			else
				return client.supports_method(method, { bufnr = bufnr })
			end
		end

		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if
			client
			and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf)
		then
			local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
			vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
				buffer = event.buf,
				group = highlight_augroup,
				callback = vim.lsp.buf.document_highlight,
			})

			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
				buffer = event.buf,
				group = highlight_augroup,
				callback = vim.lsp.buf.clear_references,
			})

			vim.api.nvim_create_autocmd("LspDetach", {
				group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
				callback = function(event2)
					vim.lsp.buf.clear_references()
					vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = event2.buf })
				end,
			})
		end

		if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
			map(
				"<leader>th",
				function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf })) end,
				"[T]oggle Inlay [H]ints"
			)
		end
	end,
})
