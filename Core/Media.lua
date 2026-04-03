local _, RRT_NS = ... -- Internal namespace
RRT_NS.LSM = LibStub("LibSharedMedia-3.0")
RRTMedia = {}
--Sounds
RRT_NS.LSM:Register("sound","|cFF4BAAC8Macro|r", [[Interface\Addons\InfinityTools\Media\Sounds\macro.mp3]])
RRT_NS.LSM:Register("sound","|cFF4BAAC801|r", [[Interface\Addons\InfinityTools\Media\Sounds\1.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC802|r", [[Interface\Addons\InfinityTools\Media\Sounds\2.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC803|r", [[Interface\Addons\InfinityTools\Media\Sounds\3.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC804|r", [[Interface\Addons\InfinityTools\Media\Sounds\4.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC805|r", [[Interface\Addons\InfinityTools\Media\Sounds\5.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC806|r", [[Interface\Addons\InfinityTools\Media\Sounds\6.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC807|r", [[Interface\Addons\InfinityTools\Media\Sounds\7.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC808|r", [[Interface\Addons\InfinityTools\Media\Sounds\8.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC809|r", [[Interface\Addons\InfinityTools\Media\Sounds\9.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC810|r", [[Interface\Addons\InfinityTools\Media\Sounds\10.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Dispel|r", [[Interface\Addons\InfinityTools\Media\Sounds\Dispel.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Yellow|r", [[Interface\Addons\InfinityTools\Media\Sounds\Yellow.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Orange|r", [[Interface\Addons\InfinityTools\Media\Sounds\Orange.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Purple|r", [[Interface\Addons\InfinityTools\Media\Sounds\Purple.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Green|r", [[Interface\Addons\InfinityTools\Media\Sounds\Green.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Moon|r", [[Interface\Addons\InfinityTools\Media\Sounds\Moon.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Blue|r", [[Interface\Addons\InfinityTools\Media\Sounds\Blue.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Red|r", [[Interface\Addons\InfinityTools\Media\Sounds\Red.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Skull|r", [[Interface\Addons\InfinityTools\Media\Sounds\Skull.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Gate|r", [[Interface\Addons\InfinityTools\Media\Sounds\Gate.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Soak|r", [[Interface\Addons\InfinityTools\Media\Sounds\Soak.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Fixate|r", [[Interface\Addons\InfinityTools\Media\Sounds\Fixate.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Next|r", [[Interface\Addons\InfinityTools\Media\Sounds\Next.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Interrupt|r", [[Interface\Addons\InfinityTools\Media\Sounds\Interrupt.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Spread|r", [[Interface\Addons\InfinityTools\Media\Sounds\Spread.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Break|r", [[Interface\Addons\InfinityTools\Media\Sounds\Break.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Targeted|r", [[Interface\Addons\InfinityTools\Media\Sounds\Targeted.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Rune|r", [[Interface\Addons\InfinityTools\Media\Sounds\Rune.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Light|r", [[Interface\Addons\InfinityTools\Media\Sounds\Light.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Void|r", [[Interface\Addons\InfinityTools\Media\Sounds\Void.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Debuff|r", [[Interface\Addons\InfinityTools\Media\Sounds\Debuff.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Clear|r", [[Interface\Addons\InfinityTools\Media\Sounds\Clear.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Stack|r", [[Interface\Addons\InfinityTools\Media\Sounds\Stack.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Charge|r", [[Interface\Addons\InfinityTools\Media\Sounds\Charge.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Linked|r", [[Interface\Addons\InfinityTools\Media\Sounds\Linked.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8HealAbsorb|r", [[Interface\Addons\InfinityTools\Media\Sounds\HealAbsorb.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Music1|r", [[Interface\Addons\InfinityTools\Media\Sounds\music1.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Music2|r", [[Interface\Addons\InfinityTools\Media\Sounds\music2.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Music3|r", [[Interface\Addons\InfinityTools\Media\Sounds\music3.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Music4|r", [[Interface\Addons\InfinityTools\Media\Sounds\music4.ogg]])
RRT_NS.LSM:Register("sound","|cFF4BAAC8Music5|r", [[Interface\Addons\InfinityTools\Media\Sounds\music5.mp3]])
--Fonts
RRT_NS.LSM:Register("font","Expressway", [[Interface\Addons\InfinityTools\Media\Fonts\Expressway.TTF]])
--StatusBars
RRT_NS.LSM:Register("statusbar","Atrocity", [[Interface\Addons\InfinityTools\Media\StatusBars\Atrocity]])

-- Memes for Break-Timer
RRTMedia.BreakMemes = {
    {[[Interface\AddOns\InfinityTools\Media\Memes\ZarugarPeace.blp]], 256, 256},
    {[[Interface\AddOns\InfinityTools\Media\Memes\ZarugarChad.blp]], 256, 147},
    {[[Interface\AddOns\InfinityTools\Media\Memes\Overtime.blp]], 256, 256},
    {[[Interface\AddOns\InfinityTools\Media\Memes\TherzBayern.blp]], 256, 24},
    {[[Interface\AddOns\InfinityTools\Media\Memes\senfisaur.blp]], 256, 256},
    {[[Interface\AddOns\InfinityTools\Media\Memes\schinky.blp]], 256, 256},
    {[[Interface\AddOns\InfinityTools\Media\Memes\TizaxHose.blp]], 202, 256},
    {[[Interface\AddOns\InfinityTools\Media\Memes\ponkyBanane.blp]], 256, 174},
    {[[Interface\AddOns\InfinityTools\Media\Memes\ponkyDespair.blp]], 256, 166},
    {[[Interface\AddOns\InfinityTools\Media\Memes\docPog.blp]], 195, 211},
}
