

-- these classes, when placed on a span will be replaced
 -- with an identical LaTeX command for PDF output
 local texMappings = {
  "nameref"
}

return {
  {
    Span = function(el)
      local contentStr = pandoc.utils.stringify(el.content)
        for i, mapping in ipairs(texMappings) do
          if #el.attr.classes == 1 and el.attr.classes:includes(mapping) then
            if quarto.doc.isFormat("pdf") then
              return pandoc.RawInline("tex", "\\" .. mapping .. "{" .. contentStr .. "}" )
            else 
              el.content = pandoc.Str( conentStr)
              return el
          end
        end
      end
    end,
    Div = function(div)
      -- Special treatment for supplementary material
      if (div.classes:includes("supp")) then
        if quarto.doc.isFormat("pdf") then
          local headerNum = 0
          local header = pandoc.List()
          local labelId
          local paraNum = 0
          local para = pandoc.List()
          -- First Take element
          div.content:walk {
            Header = function(el)
              if (headerNum > 0) then
                error('Only one header can be set in supplementary section divs')
              end
              --[[
              el.level = 4
              headerNum = headerNum + 1
              header:insert(el)
              ]]
              el.content:insert(1, pandoc.RawInline('tex', '\\paragraph*{'))
              el.content:insert(pandoc.RawInline('tex', '}'))
              header:extend(el.content)
              labelId = el.identifier
              -- Remove header
              return {}
            end,
            Para = function(el)
              if (paraNum == 0) then
                -- first paragraph is title sentence
                if (el.content and el.content[1].t ~= "Strong") then
                  el.content = pandoc.Inlines(pandoc.Strong(el.content))
                end
                el.content:insert(1, pandoc.RawInline('tex', '{'))
                el.content:insert(pandoc.RawInline('tex', '}'))
              elseif (paraNum == 1) then
                -- ok
              else
                error('Only two paragraph are allowed in supplementary section div')
              end
              
              para:insert(el)
              paraNum = paraNum + 1
              -- remove Para
              return {}
            end
          }
          -- Build the new paragraph content
          header:extend({pandoc.Str("\n"), pandoc.RawInline("tex", "\\label{"..labelId.."}"), pandoc.Str("\n")})
          para = pandoc.utils.blocks_to_inlines(para, {pandoc.Space()})
          header:extend(para)
          -- Return the new para in place of the Div
          return pandoc.Para(header)
        end
      end
    end,
  }
}