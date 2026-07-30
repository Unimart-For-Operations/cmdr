-- This file simply bootstraps the installation of Lazy.nvim and then calls other files for execution
-- This file doesn't necessarily need to be touched, BE CAUTIOUS editing this file and proceed at your own risk.
local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

-- In headless mode (e.g. CI) skip the interactive "press any key" prompts and
-- exit with a non-zero code instead so the calling process sees a failure.
local function fatal(msg)
  vim.api.nvim_echo({ { msg, "ErrorMsg" } }, true, {})
  if vim.tbl_contains(vim.v.argv, "--headless") then
    vim.cmd "cquit 1"
  else
    vim.api.nvim_echo({ { "Press any key to exit...", "MoreMsg" } }, true, {})
    vim.fn.getchar()
    vim.cmd.quit()
  end
end

if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
  -- stylua: ignore
  local result = vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
  if vim.v.shell_error ~= 0 then
    fatal(("Error cloning lazy.nvim:\n%s\n"):format(result))
  end
end

vim.opt.rtp:prepend(lazypath)

-- validate that lazy is available
if not pcall(require, "lazy") then
  fatal(("Unable to load lazy from: %s\n"):format(lazypath))
end

require "lazy_setup"
