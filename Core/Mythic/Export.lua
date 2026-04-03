local _, RRT_NS = ...

local Core = RRT_NS.Mythic or _G.RRTMythicTools
if not Core then
    return
end

local LibSerialize = LibStub and LibStub("LibSerialize", true)
local LibDeflate = LibStub and LibStub("LibDeflate", true)

local Export = {}
Core.Export = Export

local function canExport()
    return LibSerialize and LibDeflate
end

function Export:BuildExportTable(profileName, authorName, payload)
    return {
        meta = {
            profileName = profileName or "Unnamed Profile",
            author = authorName or "",
            version = Core.VERSION,
            exportedAt = date("%Y-%m-%d %H:%M:%S"),
        },
        payload = payload or {},
    }
end

function Export:SerializeTable(data)
    if not canExport() then
        return nil, "Missing library: LibSerialize or LibDeflate"
    end

    local serialized = LibSerialize:Serialize(data)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)
    return encoded
end

function Export:DeserializeString(encoded)
    if not canExport() then
        return nil, "Missing library: LibSerialize or LibDeflate"
    end

    local decoded = LibDeflate:DecodeForPrint(encoded)
    if not decoded then
        return nil, "Decode failed"
    end

    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        return nil, "Decompress failed"
    end

    local ok, data = LibSerialize:Deserialize(decompressed)
    if not ok then
        return nil, "Deserialize failed"
    end

    return data
end
