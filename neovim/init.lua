vim.g.mapleader = " "
vim.g.maplocalleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	-- Git related plugins
	"tpope/vim-fugitive",
	"tpope/vim-rhubarb",

	-- Detect tabstop and shiftwidth automatically
	"tpope/vim-sleuth",

	-- Quality of life
	"tpope/vim-surround",
	"airblade/vim-rooter",

	--  The configuration is done below. Search for lspconfig to find it below.
	{
		-- LSP Configuration & Plugins
		"neovim/nvim-lspconfig",
		dependencies = {
			-- Automatically install LSPs to stdpath for neovim
			{ "williamboman/mason.nvim", config = true },
			"williamboman/mason-lspconfig.nvim",
			"jose-elias-alvarez/null-ls.nvim",

			-- Useful status updates for LSP
			{ "j-hui/fidget.nvim", tag = "legacy", event = "LSPAttach", opts = {} },

			-- Additional lua configuration, makes nvim stuff amazing!
			{
				"folke/neodev.nvim",
				opts = {},
			},

			-- Auto pairs
			{ "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },

			-- Function signature help
			{ "ray-x/lsp_signature.nvim", opts = {} },

			-- Problems in code
			{ "folke/trouble.nvim", opts = {} },
		},
	},

	{
		-- Autocompletion
		"hrsh7th/nvim-cmp",
		dependencies = {
			-- Snippet Engine & its associated nvim-cmp source
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",

			-- Adds LSP completion capabilities
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",

			-- Adds a number of user-friendly snippets
			"rafamadriz/friendly-snippets",
		},
	},

	-- Useful plugin to show you pending keybinds.
	{ "folke/which-key.nvim", opts = {} },

	{
		-- Adds git releated signs to the gutter, as well as utilities for managing changes
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
			on_attach = function(bufnr)
				vim.keymap.set(
					"n",
					"<leader>gp",
					require("gitsigns").prev_hunk,
					{ buffer = bufnr, desc = "[G]o to [P]revious Hunk" }
				)
				vim.keymap.set(
					"n",
					"<leader>gn",
					require("gitsigns").next_hunk,
					{ buffer = bufnr, desc = "[G]o to [N]ext Hunk" }
				)
				vim.keymap.set(
					"n",
					"<leader>ph",
					require("gitsigns").preview_hunk,
					{ buffer = bufnr, desc = "[P]review [H]unk" }
				)
			end,
		},
	},

	{
		"RRethy/nvim-base16",
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("base16-catppuccin-mocha")
		end,
	},

	{
		-- Set lualine as statusline
		"nvim-lualine/lualine.nvim",
		opts = {
			options = {
				icons_enabled = false,
				component_separators = "|",
				section_separators = "",
			},
		},
	},

	-- "gc" to comment visual regions/lines
	{ "numToStr/Comment.nvim", lazy = false, opts = {} },

	-- Fuzzy Finder (files, lsp, etc)
	{ "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } },

	-- Fuzzy Finder Algorithm which requires local dependencies to be built.
	-- Only load if `make` is available. Make sure you have the system
	-- requirements installed.
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "make",
		cond = function()
			return vim.fn.executable("make") == 1
		end,
	},

	{
		-- Highlight, edit, and navigate code
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		build = ":TSUpdate",
	},

	{
		"neovim/nvim-lspconfig",
		config = function()
			-- Switch for controlling whether you want autoformatting.
			--  Use :KickstartFormatToggle to toggle autoformatting on or off
			local format_is_enabled = true
			vim.api.nvim_create_user_command("KickstartFormatToggle", function()
				format_is_enabled = not format_is_enabled
				print("Setting autoformatting to: " .. tostring(format_is_enabled))
			end, {})

			-- Create an augroup that is used for managing our formatting autocmds.
			--      We need one augroup per client to make sure that multiple clients
			--      can attach to the same buffer without interfering with each other.
			local _augroups = {}
			local get_augroup = function(client)
				if not _augroups[client.id] then
					local group_name = "kickstart-lsp-format-" .. client.name
					local id = vim.api.nvim_create_augroup(group_name, { clear = true })
					_augroups[client.id] = id
				end

				return _augroups[client.id]
			end

			-- Whenever an LSP attaches to a buffer, we will run this function.
			--
			-- See `:help LspAttach` for more information about this autocmd event.
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach-format", { clear = true }),
				-- This is where we attach the autoformatting for reasonable clients
				callback = function(args)
					local client_id = args.data.client_id
					local client = vim.lsp.get_client_by_id(client_id)
					local bufnr = args.buf

					-- Only attach to clients that support document formatting
					if not client.server_capabilities.documentFormattingProvider then
						return
					end

					-- Tsserver usually works poorly. Sorry you work with bad languages
					-- You can remove this line if you know what you're doing :)
					if client.name == "tsserver" then
						return
					end

					-- Create an autocmd that will run *before* we save the buffer.
					--  Run the formatting command for the LSP that has just attached.
					vim.api.nvim_create_autocmd("BufWritePre", {
						group = get_augroup(client),
						buffer = bufnr,
						callback = function()
							if not format_is_enabled then
								return
							end

							vim.lsp.buf.format({
								async = false,
								filter = function(c)
									return c.id == client.id
								end,
							})
						end,
					})
				end,
			})
		end,
	},
}, {})

-- [[ Setting options ]]
vim.o.breakindent = true
vim.o.clipboard = "unnamedplus"
vim.o.completeopt = "menuone,noselect"
vim.o.fileformat = "unix" -- lf on endofline
vim.o.hlsearch = false
vim.o.ignorecase = true -- ignore case in search
vim.o.lazyredraw = true
vim.o.mouse = "a" -- enable mouse usage
vim.o.number = true
vim.o.relativenumber = true
vim.o.scrolloff = 2 -- keep somelines above and below cursor
vim.o.signcolumn = "yes" -- always draw sign column. prevent buffer moving when adding/deleting sign
vim.o.smartcase = true -- case-sensitive if contains capital
vim.o.termguicolors = true -- colors in terminal
vim.o.timeoutlen = 300
vim.o.undofile = true -- permanent undo
vim.o.updatetime = 250 -- update swap file more

-- [[ Basic Keymaps ]]
-- Keymaps for better default experience
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set("n", "<right>", "<cmd>bn<cr>", {})
vim.keymap.set("n", "<left>", "<cmd>bp<cr>", {})
vim.keymap.set("n", "<pageup>", "<cmd>tabnext<cr>", {})
vim.keymap.set("n", "<pagedown>", "<cmd>tabprevious<cr>", {})
vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", {})
vim.keymap.set({ "n", "o", "v" }, "L", "$", {})
vim.keymap.set({ "n", "o", "v" }, "H", "^", {})
vim.keymap.set("n", "<leader><leader>", "<c-^>", {})
vim.keymap.set("n", "<m-h>", "<c-w>h", {})
vim.keymap.set("n", "<m-j>", "<c-w>j", {})
vim.keymap.set("n", "<m-k>", "<c-w>k", {})
vim.keymap.set("n", "<m-l>", "<c-w>l", {})
vim.keymap.set("i", "<c-k>", "<esc>", {})
vim.keymap.set("i", "<c-j>", "<esc>", {})
vim.keymap.set("n", "/", "/\\v", {})
vim.keymap.set("n", "?", "?\\v", {})
vim.keymap.set("c", "%s/", "%sm/", {})

-- [[ Highlight on yank ]]
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank({ timeout = 700 })
	end,
	group = highlight_group,
	pattern = "*",
})

-- [[ Configure Null-ls ]])
local null_ls = require("null-ls")
null_ls.setup({
	sources = {
		null_ls.builtins.formatting.nixpkgs_fmt,
		null_ls.builtins.formatting.prettierd,
		null_ls.builtins.formatting.stylua,
	},
})

-- [[ Configure Telescope ]]
require("telescope").setup({
	defaults = {
		mappings = {
			i = {
				["<C-u>"] = false,
				["<C-d>"] = false,
			},
		},
	},
})

-- Enable telescope fzf native, if installed
pcall(require("telescope").load_extension, "fzf")

-- See `:help telescope.builtin`
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<c-p>", builtin.find_files, { desc = "Search files" })
vim.keymap.set("n", "<c-f>", builtin.live_grep, { desc = "Search by grep" })
vim.keymap.set("n", "<leader>;", builtin.buffers, { desc = "Find existing buffers" })
vim.keymap.set("n", "<leader>/", function()
	-- You can pass additional configuration to telescope to change theme, layout, etc.
	require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
		winblend = 10,
		previewer = false,
	}))
end, { desc = "[/] Fuzzily search in current buffer" })

-- [[ Configure Treesitter ]]
require("nvim-treesitter.configs").setup({
	-- Add languages to be installed here that you want installed for treesitter
	ensure_installed = { "c", "javascript", "lua", "python", "rust", "typescript", "vimdoc", "vim" },

	-- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
	auto_install = false,

	highlight = { enable = true },
	indent = { enable = true },
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
})

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

-- [[ Configure LSP ]]
local on_attach = function(_, bufnr)
	-- NOTE: Remember that lua is a real programming language, and as such it is possible
	-- to define small helper and utility functions so you don't have to repeat yourself
	-- many times.
	--
	-- In this case, we create a function that lets us more easily define mappings specific
	-- for LSP related items. It sets the mode, buffer and description for us each time.
	local nmap = function(keys, func, desc)
		if desc then
			desc = "LSP: " .. desc
		end

		vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
	end

	nmap("<leader>r", vim.lsp.buf.rename, "[R]ename")
	nmap("<leader>a", vim.lsp.buf.code_action, "Code [A]ction")

	nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
	nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
	nmap("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
	nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
	nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
	nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

	-- See `:help K` for why this keymap
	nmap("K", vim.lsp.buf.hover, "Hover Documentation")
	nmap("<c-k>", vim.lsp.buf.signature_help, "Signature Documentation")

	-- Lesser used LSP functionality
	nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
	nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
	nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
	nmap("<leader>wl", function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, "[W]orkspace [L]ist Folders")

	-- Create a command `:Format` local to the LSP buffer
	vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
		vim.lsp.buf.format()
	end, { desc = "Format current buffer with LSP" })
end

-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--
--  Add any additional override configuration in the following tables. They will be passed to
--  the `settings` field of the server config. You must look up that documentation yourself.
local servers = {
	-- pyright = {},
	rust_analyzer = {},
	-- tsserver = {},
}

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

-- Ensure the servers above are installed
local mason_lspconfig = require("mason-lspconfig")

mason_lspconfig.setup({
	ensure_installed = vim.tbl_keys(servers),
})

mason_lspconfig.setup_handlers({
	function(server_name)
		require("lspconfig")[server_name].setup({
			capabilities = capabilities,
			on_attach = on_attach,
			settings = servers[server_name],
		})
	end,
})

-- [[ Configure nvim-cmp ]]
local cmp = require("cmp")
local luasnip = require("luasnip")
require("luasnip.loaders.from_vscode").lazy_load()
luasnip.config.setup({})

cmp.setup({
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-n>"] = cmp.mapping.select_next_item(),
		["<C-p>"] = cmp.mapping.select_prev_item(),
		["<C-d>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete({}),
		["<CR>"] = cmp.mapping.confirm({
			behavior = cmp.ConfirmBehavior.Replace,
			select = true,
		}),
		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif luasnip.expand_or_locally_jumpable() then
				luasnip.expand_or_jump()
			else
				fallback()
			end
		end, { "i", "s" }),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.locally_jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, { "i", "s" }),
	}),
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
		{ name = "buffer" },
	}),
})

-- Set configuration for specific filetype.
cmp.setup.filetype("gitcommit", {
	sources = cmp.config.sources({
		{ name = "cmp_git" }, -- You can specify the `cmp_git` source if you were installed it.
	}, {
		{ name = "buffer" },
	}),
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ "/", "?" }, {
	mapping = cmp.mapping.preset.cmdline(),
	sources = {
		{ name = "buffer" },
	},
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(":", {
	mapping = cmp.mapping.preset.cmdline(),
	sources = cmp.config.sources({
		{ name = "path" },
	}, {
		{ name = "cmdline" },
	}),
})
