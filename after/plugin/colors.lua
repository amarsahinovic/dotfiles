function ApplyColor(color)
	color = color or "darcula"
	vim.cmd.colorscheme(color)
    -- Not really working, messes up the terminal
	 -- vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	 -- vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end



ApplyColor()
