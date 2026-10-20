--!nonstrict
-- Server-only. Secret ingredients are sent only after the recipe is discovered.
return {
    { Id = "sharktopus", Ingredients = { "shark", "octopus" }, Output = "sharktopus", Secret = false },
    { Id = "leviathan_squid", Ingredients = { "sperm_whale", "giant_squid" }, Output = "leviathan_squid", Secret = false },
    { Id = "dolphark", Ingredients = { "dolphin", "shark" }, Output = "dolphark", Secret = false },
    { Id = "kraken_shark", Ingredients = { "kraken", "shark" }, Output = "kraken_shark", Secret = false },
    { Id = "orca_dragon", Ingredients = { "orca", "sea_dragon" }, Output = "orca_dragon", Secret = false },
    { Id = "nautilux", Ingredients = { "jellyfish", "narwhal", "giant_eel" }, Output = "nautilux", Secret = true },
    { Id = "eclipse_kraken", Ingredients = { "ancient_kraken", "luminara", "ghost_orca" }, Output = "eclipse_kraken", Secret = true },
    { Id = "thalassor", Ingredients = { "asterion", "primordial_leviathan", "poseidon_echo" }, Output = "thalassor", Secret = true },
}
