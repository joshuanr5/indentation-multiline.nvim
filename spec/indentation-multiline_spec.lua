local find_map = function(lhs)
  local maps = vim.api.nvim_get_keymap("v")
  for _, map in ipairs(maps) do
    if map.lhs == lhs then
      return map
    end
  end
end

local mock = require("luassert.mock")

describe("Indentation Multiline", function()
  local module = require("indentation-multiline")
  local backup_line = vim.fn.line

  describe("indent_lines_by_type function", function()
    local indent_types = { ">", "<" }
    local mock_api
    local mock_vim

    before_each(function()
      vim.fn.line = function(value)
        return value == "v" and 10 or 15
      end

      mock_api = mock(vim.api, true)
      mock_api.nvim_get_mode.returns({ mode = "v" })

      mock_vim = mock(vim, false)
    end)

    after_each(function()
      vim.fn.line = backup_line

      mock.revert(mock_api)
      mock.revert(mock_vim)
    end)

    for _, indent_type in ipairs(indent_types) do
      it("Should be OK form multilines using " .. indent_type, function()
        module.indent_lines_by_type(indent_type)

        assert.stub(mock_vim.cmd).was_called_with("10,15" .. indent_type)
        assert.stub(mock_api.nvim_win_set_cursor).was_called_with(0, { 10, 0 })
        assert.stub(mock_api.nvim_input).was_called(2)
        assert.stub(mock_api.nvim_input).was_called_with("v")
        assert.stub(mock_api.nvim_input).was_called_with("5j")
      end)
    end

    for _, indent_type in ipairs(indent_types) do
      it("Should be OK for single line using " .. indent_type, function()
        vim.fn.line = function()
          return 10
        end

        module.indent_lines_by_type(indent_type)

        assert.stub(mock_vim.cmd).was_called_with(indent_type)
        assert.stub(mock_api.nvim_input).was_called(1)
        assert.stub(mock_api.nvim_input).was_called_with("v")
      end)
    end
  end)

  describe("setup function", function ()
    describe("default setup", function ()
      local lhss = { "<Tab>", "<S-Tab>" }

      before_each(function ()
        module.setup()
      end)

      after_each(function ()
        module._clear_setup()
      end)

      for _, lhs in ipairs(lhss) do
        it("Should map " .. lhs .. " by default", function ()
          local found_mapping = find_map(lhs)
          assert.is_table(found_mapping)
          assert.is_function(found_mapping.callback)
        end)
      end
    end)

    describe("user config setup", function ()
      local lhss = { "[/", "[," }

      before_each(function ()
        module.setup({
          indent_mapping = "[/",
          unindent_mapping = "[,"
        })
      end)

      after_each(function ()
        module._clear_setup()
      end)

      for _, lhs in ipairs(lhss) do
        it("Should map " .. lhs .. " by user config", function ()
          local found_mapping = find_map(lhs)
          assert.is_table(found_mapping)
          assert.is_function(found_mapping.callback)
        end)
      end
    end)
  end)
end)

