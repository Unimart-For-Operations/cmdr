-- AstroCore: central place for mappings, vim options, autocommands, and more.
-- Configuration documentation: `:h astrocore`

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 },
      autopairs = true,
      cmp = true,
      diagnostics = { virtual_text = true, virtual_lines = false },
      highlighturl = true,
      notifications = true,
    },
    diagnostics = {
      virtual_text = true,
      underline = true,
    },
    options = {
      opt = {
        relativenumber = true,
        number = true,
        spell = false,
        signcolumn = "yes",
        wrap = false,
      },
    },
    autocmds = {
      markdown_local_options = {
        {
          event = "FileType",
          pattern = { "markdown" },
          desc = "Markdown readability options",
          callback = function()
            vim.opt_local.wrap = true
            vim.opt_local.linebreak = true
            vim.opt_local.spell = true
            vim.opt_local.conceallevel = 2
            vim.opt_local.concealcursor = "nc"
          end,
        },
      },
    },
    mappings = {
      n = {
        -- Telescope
        ["<Leader>fw"] = { "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
        ["<Leader>ff"] = { "<cmd>Telescope find_files<cr>", desc = "Find files" },
        ["<Leader>fb"] = { "<cmd>Telescope buffers<cr>", desc = "Find buffers" },
        ["<Leader>fh"] = { "<cmd>Telescope help_tags<cr>", desc = "Find help" },
        ["<Leader>fo"] = { "<cmd>Telescope oldfiles<cr>", desc = "Find old files" },
        ["<Leader>fc"] = { "<cmd>Telescope grep_string<cr>", desc = "Find word under cursor" },
        ["<Leader>fd"] = { "<cmd>Telescope diagnostics<cr>", desc = "Find diagnostics" },
        ["<Leader>fs"] = { "<cmd>Telescope lsp_document_symbols<cr>", desc = "Find symbols" },
        ["<Leader>fr"] = { "<cmd>Telescope resume<cr>", desc = "Resume last search" },

        -- Obsidian
        ["<Leader>o"] = { desc = "Obsidian" },
        ["<Leader>oo"] = { "<cmd>ObsidianOpen<cr>", desc = "Open in Obsidian app" },
        ["<Leader>on"] = { "<cmd>ObsidianNew<cr>", desc = "New note" },
        ["<Leader>oq"] = { "<cmd>ObsidianQuickSwitch<cr>", desc = "Quick switch" },
        ["<Leader>of"] = { "<cmd>ObsidianSearch<cr>", desc = "Search notes" },
        ["<Leader>ot"] = { "<cmd>ObsidianTags<cr>", desc = "Search tags" },
        ["<Leader>od"] = { "<cmd>ObsidianToday<cr>", desc = "Today's note" },
        ["<Leader>oy"] = { "<cmd>ObsidianYesterday<cr>", desc = "Yesterday's note" },
        ["<Leader>ob"] = { "<cmd>ObsidianBacklinks<cr>", desc = "Show backlinks" },
        ["<Leader>ol"] = { "<cmd>ObsidianLinks<cr>", desc = "Show links" },
        ["<Leader>ow"] = { "<cmd>ObsidianWorkspace<cr>", desc = "Switch workspace" },
        ["<Leader>op"] = { "<cmd>ObsidianPasteImg<cr>", desc = "Paste image" },
        ["<Leader>or"] = { "<cmd>ObsidianRename<cr>", desc = "Rename note" },
        ["gf"] = {
          function()
            local ok, obsidian = pcall(require, "obsidian")
            if ok and obsidian.util.cursor_on_markdown_link() then
              return "<cmd>ObsidianFollowLink<cr>"
            else
              return "gf"
            end
          end,
          desc = "Follow link or file",
          expr = true,
        },

        -- Buffer navigation
        ["]b"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        ["[b"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },
        ["<Leader>bd"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Close buffer from tabline",
        },
      },
    },
  },
}
