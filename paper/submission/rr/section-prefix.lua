-- section-prefix.lua
-- 为正文和附录章节使用不同的前缀
-- 正文章节使用默认前缀，附录章节使用 "OSM"

local appendix_prefix = "OSM"
local section_locations = {}

function Pandoc(doc)
  local in_appendix = false

  -- 第一遍：扫描所有块，记录章节位置
  for _, block in ipairs(doc.blocks) do
    if block.t == "RawBlock" then
      local text = block.text or ""
      if text:match("\\appendix") then
        in_appendix = true
      end
    end

    if block.t == "Header" then
      local header_text = pandoc.utils.stringify(block)
      if header_text:match("Online Supplementary Materials") then
        in_appendix = true
      end
      if block.identifier and block.identifier ~= "" then
        section_locations[block.identifier] = in_appendix
      end
    end
  end

  -- 第二遍：处理Cite元素，为附录章节添加OSM前缀
  local function process_cite(el)
    if el.t == "Cite" then
      for _, citation in ipairs(el.citations) do
        local cite_id = citation.id or ""
        if cite_id:match("^sec%-") and section_locations[cite_id] == true then
          citation.prefix = {pandoc.Str(appendix_prefix)}
        end
      end
    end
    return el
  end

  doc = doc:walk({Cite = process_cite})
  return doc
end

return {{Pandoc = Pandoc}}
