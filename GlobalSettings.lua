local addOnName, LRP = ...

local flavorToNumber = {
    Cata = 4,
    Mainline = 10
}

local flavor = C_AddOns.GetAddOnMetadata(addOnName, "X-Flavor")
local flavorNumber = flavorToNumber[flavor]

LRP.isCata = flavorNumber == 4
LRP.isRetail = flavorNumber == 10
LRP.flavorNumber = flavorNumber

LRP.gs = {
    debug = false, -- Debug mode adds some additional features
    visual = {
        font = "Interface\\Addons\\TimelineReminders\\Media\\Fonts\\PTSansNarrow.ttf",
        fontFlags = "",
        borderColor = {r = 0.3, g = 0.3, b = 0.3}
    }
}
