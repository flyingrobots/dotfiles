return {
  {
    "yetone/avante.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      { "ColinKennedy/mega.cmdparse", dependencies = { "ColinKennedy/mega.logging" } },
    },
    opts = {
      provider = "deepseek", -- DeepSeek-R1 (32B MLX) for deep planning, chat, and architecture (<leader>aa)
      auto_suggestions_provider = "gemma", -- Google Gemma (4B) for fast inline suggestions and edits (<leader>ae)
      providers = {
        deepseek = {
          __inherited_from = "openai",
          endpoint = "http://127.0.0.1:1234/v1",
          model = "deepseek-r1-distill-qwen-32b",
          api_key_name = "",
          timeout = 180000,
          temperature = 0.6,
          max_tokens = 8192,
          extra_request_body = {
            temperature = 0.6,
            max_tokens = 8192,
          },
        },
        gemma = {
          __inherited_from = "openai",
          endpoint = "http://127.0.0.1:1234/v1",
          model = "google/gemma-4-e4b",
          api_key_name = "",
          timeout = 30000,
          temperature = 0.1,
          max_tokens = 4096,
          extra_request_body = {
            temperature = 0.1,
            max_tokens = 4096,
          },
        },
      },
    },
  },
}
