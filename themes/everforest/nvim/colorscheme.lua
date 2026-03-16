return {
  {
    "neanias/everforest-nvim",
    main = "everforest",  -- needed because of the dash in the repo name
    lazy = false,
    priority = 1000,
    opts = {
      background = "hard",  -- "soft", "medium", or "hard"
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "everforest",
    },
  },
}