local function resolve_lmstudio_host()
  local env_host = os.getenv("LMSTUDIO_HOST")
  if env_host and env_host ~= "" then
    return env_host
  end

  local role_path = vim.fn.expand("~/.config/dotfiles/role")
  local f = io.open(role_path, "r")
  if f then
    local role = f:read("*l")
    f:close()
    if role and role:match("^%s*client") then
      return "mac-node"
    elseif role and role:match("^%s*host") then
      return "127.0.0.1"
    end
  end

  local zshrc_local = vim.fn.expand("~/.zshrc.local")
  local zf = io.open(zshrc_local, "r")
  if zf then
    local content = zf:read("*a")
    zf:close()
    local matched_host = content:match('export LMSTUDIO_HOST=["\']?([^"\'%s\n]+)')
    if matched_host then
      return matched_host
    end
  end

  return "mac-node"
end

return {
  {
    "yetone/avante.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      { "ColinKennedy/mega.cmdparse", dependencies = { "ColinKennedy/mega.logging" } },
    },
    opts = function()
      local host = resolve_lmstudio_host()
      local endpoint = "http://" .. host .. ":1234/v1"

      return {
        provider = "deepseek", -- DeepSeek-R1 (32B MLX) for deep planning, chat, and architecture (<leader>aa)
        auto_suggestions_provider = "gemma", -- Google Gemma (4B) for fast inline suggestions and edits (<leader>ae)
        providers = {
          deepseek = {
            __inherited_from = "openai",
            endpoint = endpoint,
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
            endpoint = endpoint,
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
      }
    end,
  },
}
