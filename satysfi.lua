-- This is a sample custom writer for pandoc.  It produces output
-- that is very similar to that of pandoc's HTML writer.
-- There is one new feature: code blocks marked with class 'dot'
-- are piped through graphviz and images are included in the HTML
-- output using 'data:' URLs.
--
-- Invoke with: pandoc -t sample.lua
--
-- Note:  you need not have lua installed on your system to use this
-- custom writer.  However, if you do have lua installed, you can
-- use it to test changes to the script.  'lua sample.lua' will
-- produce informative error messages if your code contains
-- syntax errors.

-- Character escaping
local function escape(s, in_attribute)
    return s:gsub("[<>&\"*{}\\|%%\\*;#$\\\\@`]",
    function(x)
      if x == '*' then
        return "\\*"
      elseif x == '{' then
        return "\\{"
      elseif x == '}' then
        return "\\}"
      elseif x == '<' then
        return "\\<"
      elseif x == '>' then
        return "\\>"
      elseif x == '|' then
        return "\\|"
      elseif x == '%' then
        return "\\%"
      elseif x == '*' then
        return "\\*"
      elseif x == ';' then
        return "\\;"
      elseif x == '#' then
        return "\\#"
      elseif x == '$' then
        return "\\$"
      elseif x == '\\' then
        return "\\\\"
      elseif x == '@' then
        return "\\@"
      elseif x == '`' then
        return "\\`"
      else
        return x
      end
    end)
end

-- Character escaping in math env
local function math_escape(s, in_attribute)
  return s:gsub("[()*%[%]|]",
    function(x)
      if x == '(' then
        return '\\('
      elseif x == ')' then
        return '\\)'
      elseif x == '[' then
        return '\\['
      elseif x == ']' then
        return '\\]'
      elseif x == '|' then
        return '\\|'
      else
        return x
      end
    end)
end

-- Helper function to convert an attributes table into
-- a string that can be put into HTML tags.
local function attributes(attr)
  local attr_table = {}
  for x,y in pairs(attr) do
    if y and y ~= "" then
      table.insert(attr_table, ' ' .. x .. '="' .. escape(y,true) .. '"')
    end
  end
  return table.concat(attr_table)
end

-- Run cmd on a temporary file containing inp and return result.
local function pipe(cmd, inp)
  local tmp = os.tmpname()
  local tmph = io.open(tmp, "w")
  tmph:write(inp)
  tmph:close()
  local outh = io.popen(cmd .. " " .. tmp,"r")
  local result = outh:read("*all")
  outh:close()
  os.remove(tmp)
  return result
end

-- Blocksep is used to separate block elements.
function Blocksep()
  return "\n"
end

local header_level = 0
local no_para = false

-- This function is called once for the whole document. Parameters:
-- body is a string, metadata is a table, variables is a table.
-- This gives you a fragment.  You could use the metadata table to
-- fill variables in a custom lua template.  Or, pass `--template=...`
-- to pandoc, and pandoc will add do the template processing as
-- usual.
function Doc(body, metadata, variables)
  local buffer = {}
  local function add(s)
    table.insert(buffer, s)
  end
  add(body)
  close_paren = ''
  for i = 1, header_level do
    close_paren = close_paren .. '>\n'
  end
  return table.concat(buffer,'\n') .. '\n' .. close_paren
end

-- The functions that follow render corresponding pandoc elements.
-- s is always a string, attr is always a table of attributes, and
-- items is always an array of strings (the items in a list).
-- Comments indicate the types of other variables.

function Str(s)
  return escape(s)
end

function Space()
  return " "
end

function SoftBreak()
  return "\n"
end

function LineBreak()
  return "\n"
--  return "<br/>"
end

function Emph(s)
  return "\\emph{" .. s .. "}"
end

function Strong(s)
--  return "<strong>" .. s .. "</strong>"
  return "\\emph{" .. s .. "}"
end

function Subscript(s)
  return "<sub>" .. s .. "</sub>"
end

function Superscript(s)
  return "<sup>" .. s .. "</sup>"
end

function SmallCaps(s)
  return '<span style="font-variant: small-caps;">' .. s .. '</span>'
end

function Strikeout(s)
  return '<del>' .. s .. '</del>'
end

function Link(s, src, tit, attr)
     return "\\href(`" .. escape(src,true) .. "`){" .. s .. "}"
end

function Image(s, src, tit, attr)
  return "<img src='" .. escape(src,true) .. "' title='" ..
         escape(tit,true) .. "'/>"
end

function Code(s, attr)
  local backquote = "`"
  while string.match(s, backquote) do
    backquote = backquote .. "`"
  end
  return "\\code(" .. backquote .. s .. backquote .. ");"
end

function InlineMath(s)
  return "${" .. math_escape(s) .. "}"
end

function DisplayMath(s)
  return "+math(${\n" .. math_escape(s) .. "\n});"
end

-- Warning: stdja does not support footnote!
function Note(s)
  raw_string = string.reverse(string.sub(string.reverse(string.sub(s, 5)), 2))
  return '\\footnote{' .. raw_string .. '}'
end

function Span(s, attr)
  return "<span" .. attributes(attr) .. ">" .. s .. "</span>"
end

function RawInline(format, str)
  return str
end

function Cite(s, cs)
  local ids = {}
  for _,cit in ipairs(cs) do
    table.insert(ids, cit.citationId)
  end
  return "\\cite([`" .. table.concat(ids, "`;`") .. "`]);"
end

function Plain(s)
  return s
end

function Para(s)
  if no_para then
    no_para = false
    return "{\n  " .. s .. "\n}"
  elseif string.match(s, "^%s*%+math%(.*%);$") and string.match(s, ";.") == nil then
    return s
  elseif  string.match(s, "%+math") then
    s = string.gsub(s, "%+math", "\\eqn")
  end
  return "+p {\n  " .. s .. "\n}"
end

-- lev is an integer, the header level.
function Header(lev, s, attr)
  if attr.class == "definition" then
    no_para = true
    return "+definition ?:({" .. s .. "}) ?:(`" .. attr.id .."`)"
  elseif attr.class == "theorem" then
    no_para = true
    return "+theorem ?:({" .. s .. "}) ?:(`" .. attr.id .."`)"
  elseif attr.class == "corollary" then
    no_para = true
    return "+corollary ?:({" .. s .. "}) ?:(`" .. attr.id .."`)"
  end
  no_para = false
  close_paren = ''
  for i = lev, header_level do
    close_paren = close_paren .. '>\n'
  end
  if lev == 1 then
    section = "+section"
  elseif lev == 2 then
    section = "+subsection"
  elseif lev == 3 then
    section = "+subsubsection"
  end
  -- attributes(attr)
  header_level = lev
  if attr.id == "" or lev >= 3 then
    id = ""
  else
    id = " ?:(`" .. attr.id .. "`) "
  end
  return close_paren .. section .. id .. "{" .. s .. "} <" 
end

function BlockQuote(s)
  return "+quote<" .. "\n" .. s .. ">\n"
end

function HorizontalRule()
  return "<hr/>"
end

function LineBlock(ls)
  return '<div style="white-space: pre-line;">' .. table.concat(ls, '\n') ..
         '</div>'
end

function CodeBlock(s, attr)
  -- If code block has class 'dot', pipe the contents through dot
  -- and base64, and include the base64-encoded png as a data: URL.
  if attr.class and string.match(' ' .. attr.class .. ' ',' dot ') then
    local png = pipe("base64", pipe("dot -Tpng", s))
    return '<img src="data:image/png;base64,' .. png .. '"/>'
  -- otherwise treat as code (one could pipe through a highlighter)
  else
    local backquote = "`"
    while string.match(s, backquote) do
      backquote = backquote .. "`"
    end
    return "+code(" .. backquote .. "\n" .. s .. backquote .. ");"
  end
end

function BulletList(items)
  local buffer = {}
  for _, item in pairs(items) do
    item = string.gsub(item, "+listing{\n([^}]*)\n}", "%1")
    item = string.gsub(item, "\n%*", "\n**")
    table.insert(buffer, "* " .. " " .. item)
  end
  return "+listing{\n" .. table.concat(buffer, "\n") .. "\n}"
end

function OrderedList(items)
  local buffer = {}
  for _, item in pairs(items) do
    item = string.gsub(item, "+enumerate{\n([^}]*)\n}", "%1")
    item = string.gsub(item, "\n%*", "\n**")
    table.insert(buffer, "* " .. " " .. item)
  end
  return "+enumerate{\n" .. table.concat(buffer, "\n") .. "\n}"
end

function DefinitionList(items)
  local buffer = {}
  for _,item in pairs(items) do
    local k, v = next(item)
    table.insert(buffer, "* \\emph{" .. k .. "} " ..
                   table.concat(v, "\n") .. "")
  end
  return "+listing{\n" .. table.concat(buffer, "\n") .. "\n}"

end

-- Convert pandoc alignment to something HTML can use.
-- align is AlignLeft, AlignRight, AlignCenter, or AlignDefault.
function html_align(align)
  if align == 'AlignLeft' then
    return 'left'
  elseif align == 'AlignRight' then
    return 'right'
  elseif align == 'AlignCenter' then
    return 'center'
  else
    return 'left'
  end
end

function CaptionedImage(src, tit, caption, attr)
   return '<div class="figure">\n<img src="' .. escape(src,true) ..
      '" title="' .. escape(tit,true) .. '"/>\n' ..
      '<p class="caption">' .. caption .. '</p>\n</div>'
end

-- Caption is a string, aligns is an array of strings,
-- widths is an array of floats, headers is an array of
-- strings, rows is an array of arrays of strings.
function Table(caption, aligns, widths, headers, rows)
  local buffer = {}
  local function add(s)
    table.insert(buffer, s)
  end
  add("+frame<")
  add("+centering{")
  if caption ~= "" then
    add("<caption>" .. caption .. "</caption>")
  end
  if widths and widths[1] ~= 0 then
    for _, w in pairs(widths) do
      add('<col width="' .. string.format("%.0f%%", w * 100) .. '" />')
    end
  end
  local header_row = {}
  local empty_header = true
  add("\\tabular(fun cellf multif empty -> [")
  for i, h in pairs(headers) do
    local align = html_align(aligns[i])
    table.insert(header_row, h)
    empty_header = empty_header and h == ""
  end
  if empty_header then
    head = ""
  else
---    add('<tr class="header">')
    add("[")
    for _,h in pairs(header_row) do
      add("cellf {" .. h .. "} ;")
    end
    add("];")
--    add('</tr>')
  end
  local class = "even"
  for _, row in pairs(rows) do
    class = (class == "even" and "odd") or "even"
---    add('<tr class="' .. class .. '">')
    add('[')
    for i,c in pairs(row) do
      add('cellf {' .. c .. '};')
    end
    add('];')
----    add('</tr>')
  end
  add([[          ])(fun xs ys -> (
              match (ys, List.reverse ys) with
              | (y0 :: y1 :: _, ylast :: _) ->
                  ( match (xs, List.reverse xs) with
                    | (x0 :: x1 :: _, xlast :: _) ->
                        let grlstY =
                          [y0; ylast] |> List.map (fun y ->
                            stroke 1pt Color.black (Gr.line (x0, y) (xlast, y)))
                        in
                        (stroke 0.5pt Color.black (Gr.line (x1, y0) (x1, ylast)))
                          :: (stroke 0.5pt Color.black (Gr.line (x0, y1) (xlast, y1))) :: grlstY

                    | _ -> []
                  )
              | _ -> []
          ));
  ]]);
  add('}')
  add('>')
  return table.concat(buffer,'\n')
end

function RawBlock(format, str)
  if format == "html" then
    return str
  else
    return ''
  end
end

function Div(s, attr)
  return "<div" .. attributes(attr) .. ">\n" .. s .. "</div>"
end

function DoubleQuoted(s)
  return '"' .. s .. '"'
end

-- The following code will produce runtime warnings when you haven't defined
-- all of the functions you need for the custom writer, so it's useful
-- to include when you're working on a writer.
local meta = {}
meta.__index =
  function(_, key)
    io.stderr:write(string.format("WARNING: Undefined function '%s'\n",key))
    return function() return "" end
  end
setmetatable(_G, meta)

