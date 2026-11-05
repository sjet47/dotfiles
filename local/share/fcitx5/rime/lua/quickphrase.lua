-- 分号快捷输入:复刻 fcitx5 pinyin 的 QuickPhrase,数据直接读 fcitx5 自带的 .mb。
-- QuickPhrase 只由 pinyin 引擎触发,全局 TriggerKey 拦不住 Rime,所以在 Rime 里实现。
-- 触发规则见 rime_ice.custom.yaml 的 recognizer/patterns/quickphrase;
-- 规则不含数字,否则数字键没法选词。\frac12、:100: 这类键靠前缀匹配从候选里选。
local dirs = {
  "/usr/share/fcitx5/data/quickphrase.d/",
  (os.getenv("HOME") or "") .. "/.local/share/fcitx5/data/quickphrase.d/",
}
local files = { "latex.mb", "emoji.mb", "emoji-eac.mb" }
local entries

local function load_entries()
  entries = {}
  for _, dir in ipairs(dirs) do
    for _, name in ipairs(files) do
      local f = io.open(dir .. name, "r")
      if f then
        for line in f:lines() do
          local key, value = line:match("^(%S+)%s+(.+)$")
          if key then entries[#entries + 1] = { key = key, value = value } end
        end
        f:close()
      end
    end
  end
end

local function translator(input, seg, env)
  if not seg:has_tag("quickphrase") then return end
  if not entries then load_entries() end
  local query = input:sub(2)
  if query == "" then
    yield(Candidate("punct", seg.start, seg._end, "；", ""))
    yield(Candidate("punct", seg.start, seg._end, ";", ""))
    return
  end
  local exact, prefix = {}, {}
  for _, e in ipairs(entries) do
    if e.key == query then
      exact[#exact + 1] = e
    elseif e.key:sub(1, #query) == query then
      prefix[#prefix + 1] = e
    end
  end
  table.sort(prefix, function(a, b)
    if #a.key ~= #b.key then return #a.key < #b.key end
    return a.key < b.key
  end)
  for _, list in ipairs({ exact, prefix }) do
    for _, e in ipairs(list) do
      yield(Candidate("quickphrase", seg.start, seg._end, e.value, e.key))
    end
  end
end

return translator
