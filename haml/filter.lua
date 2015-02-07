local insert = table.insert
local concat = table.concat

--filter
local function preserve_filter (node, options)
  local content = node.content
  return content:gsub("\n", '&#x000A;'):gsub("\r", '&#x000D;')
end

local function escape_html (str, escapes)
  local chars = {}
  for k, _ in pairs(escapes) do
    insert(chars, k)
  end
  local pattern = ("([%s])"):format(concat(chars, ""))
  return (str:gsub(pattern, escapes))
end

local function escaped_filter (node, options)
  return escape_html(node.content, options.html_escapes)
end

local function javascript_filter (node, options)
  local content = node.content
  local js = {}
  js.tag = {
    "<script>",
    "</script>",
  }
  js.space = node.space
  if options.format == "xhtml" then
    local cdata = {}
    cdata.tag = {
      "//<![CDATA[",
      "//]]>",
    }
    cdata.space = node.space
    cdata[1] = content
    js.tag = {
      "<script type='text/javascript'>",
      "</script>",
    }
    js[1] = cdata
  else
    js[1] = content
  end
  node[1] = js
  return node
end

local function markdown_filter (node, options)
  local markdown = options.markdown or require "markdown"
  local output = node.content
  return markdown(output)
end

local function code_filter (node, options)
  return node.content
end

local function plain_filter (node, options)
  return node.content
end

local function cdata_filter (node, options)
  local content = node.content
  local cdata = {}
  cdata.tag = {
    "<![CDATA[",
    "]]>",

  }
  cdata.space = node.space
  cdata[1] = content
  node[1] = cdata
  node.content = nil
  return node
end

local function css_filter (node, options)
  local content = node.content

  local css = {}
  css.tag = {
    "<style>",
    "</style>",
  }
  css.space = node.space
  if options.format == "xhtml" then
    local cdata = {}
    cdata.tag = {
      "/*<![CDATA[*/",
      "/*]]>*/",
    }
    cdata.space = node.space
    cdata[1] = content
    css.tag = {
      "<style type='text/css'>",
      "</style>",

    }
    css[1] = cdata
  else
    css[1] = content
  end
  node[1] = css
  return node
end

local _filters = {
  cdata = cdata_filter,
  css = css_filter,
  escaped = escaped_filter,
  javascript = javascript_filter,
  lua = code_filter,
  markdown = markdown_filter,
  plain = plain_filter,
  preserve = preserve_filter,
}

local function filter_for (node, options)
  local func
  if _filters[node.filter] then
    local content = (node.filter == 'plain' and node.content:find '\n%s+') and node.content:gsub('^' .. node.space, '') or node.content:gsub('^' .. node.space .. options.indent, '')
    if node.filter ~= 'preserve' then
      content = content:gsub('\n$', '')
    end
    node.content = content
    func = _filters[node.filter]
  else
    error(string.format("No such filter \"%s\"", node.filter))
  end
  return func(node, options)
end

return {
  filter_for = filter_for,
  escape_html = escape_html,
}
