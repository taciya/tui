-- Small compatibility surface. Prefer current APIs; retain guarded fallbacks.
TUI_Compat = TUI_Compat or {}
local Compat = TUI_Compat

function Compat.ContainerNumSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag) or 0
    end
    if GetContainerNumSlots then return GetContainerNumSlots(bag) or 0 end
    return 0
end

function Compat.ContainerItemLink(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then
        return C_Container.GetContainerItemLink(bag, slot)
    end
    if GetContainerItemLink then return GetContainerItemLink(bag, slot) end
end

function Compat.ContainerItemInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        return C_Container.GetContainerItemInfo(bag, slot)
    end
    if GetContainerItemInfo then return GetContainerItemInfo(bag, slot) end
end

function Compat.PickupContainerItem(bag, slot)
    if C_Container and C_Container.PickupContainerItem then
        return C_Container.PickupContainerItem(bag, slot)
    end
    if PickupContainerItem then return PickupContainerItem(bag, slot) end
end

function Compat.GetSpellNameByID(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(spellID) end
    if GetSpellInfo then return GetSpellInfo(spellID) end
end

function Compat.GetSpellLink(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellLink then return C_Spell.GetSpellLink(spellID) end
    if GetSpellLink then return GetSpellLink(spellID) end
end

function Compat.GetSpellBookItemName(index)
    if C_SpellBook and C_SpellBook.GetSpellBookItemName and Enum and Enum.SpellBookSpellBank then
        return C_SpellBook.GetSpellBookItemName(index, Enum.SpellBookSpellBank.Player)
    end
    if GetSpellName then return GetSpellName(index, BOOKTYPE_SPELL or "spell") end
end

function Compat.GetSpellBookItemType(index)
    if C_SpellBook and C_SpellBook.GetSpellBookItemType and Enum and Enum.SpellBookSpellBank then
        return C_SpellBook.GetSpellBookItemType(index, Enum.SpellBookSpellBank.Player)
    end
    if GetSpellBookItemInfo then return GetSpellBookItemInfo(index, BOOKTYPE_SPELL or "spell") end
end

function Compat.GetNumSpellBookSkillLines()
    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
        return C_SpellBook.GetNumSpellBookSkillLines()
    end
    if GetNumSpellTabs then return GetNumSpellTabs() end
    return 0
end

function Compat.GetSpellTextureByID(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(spellID) end
    if GetSpellTexture then return GetSpellTexture(spellID) end
end
