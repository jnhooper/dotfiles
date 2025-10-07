local present, gp = pcall(require, 'gp')

if not present then
  return
end

local conf = {
  openai_api_key = 'sk-thisIsMadeUp',
  providers = {
    openai = {
      disable = true,
    },
    ollama = {
      disable = false,
      endpoint = 'http://localhost:11434/v1/chat/completions',
      openai_api_key = 'dummy',
    }, -- For customization, refer to Install > Configuration in the Documentation/Readme
  },
  default_chat_agent = 'phi4',
  default_command_agent = 'phi4',
  agents = {
    {
      provider = 'ollama',
      name = 'llama3.2',
      chat = true,
      command = false,
      -- string with model name or table with model name and parameters
      model = {
        model = 'llama3.2',
        temperature = 0.6,
        top_p = 1,
        min_p = 0.05,
      },
      -- system prompt (use this to specify the persona/role of the AI)
      system_prompt = 'You are a senior software engineer.',
    },
    {
      provider = 'ollama',
      name = 'phi4',
      chat = true,
      command = false,
      -- string with model name or table with model name and parameters
      model = {
        model = 'phi4',
        temperature = 0.6,
        top_p = 1,
        min_p = 0.05,
      },
      -- system prompt (use this to specify the persona/role of the AI)
      system_prompt = 'You are a senior software engineer.',
    },
    {
      provider = 'ollama',
      name = 'deepseek-r1',
      chat = true,
      command = false,
      -- string with model name or table with model name and parameters
      model = {
        model = 'deepseek-r1:7b',
        temperature = 0.6,
        top_p = 1,
        min_p = 0.05,
      },
      -- system prompt (use this to specify the persona/role of the AI)
      system_prompt = 'You are a senior software engineer.',
    },
  },
  hooks = {
    Explain = function(gpParam, params)
      local template = 'I have the following code from {{filename}}:\n\n'
        .. '```{{filetype}}\n{{selection}}\n```\n\n'
        .. 'Please respond by explaining the code above.'
      local agent = gpParam.get_chat_agent()
      gpParam.Prompt(params, gpParam.Target.popup, agent, template)
    end,
    -- example of adding command which writes unit tests for the selected code
    UnitTests = function(gpParam, params)
      local template = 'I have the following code from {{filename}}:\n\n'
        .. '```{{filetype}}\n{{selection}}\n```\n\n'
        .. 'Please respond by writing table driven unit tests for the code above.\n\n'
        .. 'Only respond with code.'
      local agent = gpParam.get_command_agent()
      gpParam.Prompt(params, gpParam.Target.popup, agent, template)
    end,
  },
}

gp.setup(conf)
local function keymapOptions(desc)
  return {
    noremap = true,
    silent = true,
    nowait = true,
    desc = 'GPT prompt ' .. desc,
  }
end

vim.keymap.set('v', '<leader>ge', '<cmd>GpExplain<cr>', keymapOptions '[e]xplain the current selection')
vim.keymap.set('v', '<leader>gt', '<cmd>GpUnitTests<cr>', keymapOptions 'create unit [t]ests')
vim.keymap.set({ 'n', 'i' }, '<C-g>c', '<cmd>GpChatNew popup<cr>', keymapOptions 'New Chat')
vim.keymap.set({ 'n', 'i' }, '<C-g>r', '<cmd>GpChatRespond<cr>', keymapOptions 'New Chat')
vim.keymap.set({ 'n', 'i' }, '<C-g>t', '<cmd>GpChatToggle<cr>', keymapOptions 'Toggle Chat')
vim.keymap.set({ 'n', 'i' }, '<C-g>d', '<cmd>GpChatDelete<cr>', keymapOptions '[d]elete chat')
