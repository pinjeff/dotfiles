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
		-- { "RRethy/base16-nvim", config = function() vim.cmd.colorscheme("base16-catppuccin-mocha") end },
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
					nix = { "nixpkgs_fmt" },
					javascript = { "prettierd" },
					json = { "prettierd" },
					lua = { "stylua" },
					markdown = { "prettierd" },
					toml = { "taplo" },
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
		{ "VonHeikemen/lsp-zero.nvim", branch = "v4.x" },
		{ "williamboman/mason.nvim" },
		{ "williamboman/mason-lspconfig.nvim" },
		{ "neovim/nvim-lspconfig" },
		{
			"hrsh7th/nvim-cmp",
			dependencies = {
				{ "L3MON4D3/LuaSnip" },
				{ "hrsh7th/cmp-buffer" },
				{ "hrsh7th/cmp-nvim-lsp" },
				{ "hrsh7th/cmp-path" },
				{ "rafamadriz/friendly-snippets" },
				{ "saadparwaiz1/cmp_luasnip" },
			},
		},
		{ "j-hui/fidget.nvim", opts = {} },
		{
			"folke/trouble.nvim",
			-- settings without a patched font or icons
			opts = {
				icons = false,
				fold_open = "v", -- icon used for open folds
				fold_closed = ">", -- icon used for closed folds
				indent_lines = false, -- add an indent guide below the fold icons
				signs = {
					-- icons / text used for a diagnostic
					error = "error",
					warning = "warn",
					hint = "hint",
					information = "info",
				},
				use_diagnostic_signs = false, -- enabling this will use the signs defined in your lsp client
			},
		},
	},
})

local lsp_zero = require("lsp-zero")

local lsp_attach = function(client, bufnr)
	local opts = { buffer = bufnr }

	vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
	vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
	vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
	vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
	vim.keymap.set("n", "go", vim.lsp.buf.type_definition, opts)
	vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
	vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, opts)
	vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, opts)
	vim.keymap.set({ "n", "x" }, "<F3>", function() vim.lsp.buf.format({ async = true }) end, opts)
	vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, opts)
end

lsp_zero.extend_lspconfig({
	sign_text = true,
	lsp_attach = lsp_attach,
	float_border = "rounded",
	capabilities = require("cmp_nvim_lsp").default_capabilities(),
})

require("mason").setup({})
require("mason-lspconfig").setup({
	handlers = { function(server_name) require("lspconfig")[server_name].setup({ single_file_support = true }) end },
})

local cmp = require("cmp")
local cmp_action = lsp_zero.cmp_action()

-- this is the function that loads the extra snippets
-- from rafamadriz/friendly-snippets
require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
	sources = {
		{ name = "path" },
		{ name = "nvim_lsp" },
		{ name = "luasnip", keyword_length = 2 },
		{ name = "buffer", keyword_length = 3 },
	},
	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},
	snippet = {
		expand = function(args) require("luasnip").lsp_expand(args.body) end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-u>"] = cmp.mapping.scroll_docs(-4),
		["<C-d>"] = cmp.mapping.scroll_docs(4),
		["<C-f>"] = cmp_action.luasnip_jump_forward(),
		["<C-b>"] = cmp_action.luasnip_jump_backward(),
	}),
	-- note: if you are going to use lsp-kind (another plugin)
	-- replace the line below with the function from lsp-kind
	formatting = lsp_zero.cmp_format({ details = true }),
})
