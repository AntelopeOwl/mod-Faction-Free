--[[
Simplified teleport script using table-based configuration.
Set creatureID or gameobjectID to attach the menu to an NPC or a gameobject.
The script is a refactored version of the original massive if/else chains to
reduce maintenance effort while still providing a wide selection of destinations.
]]--

local creatureID = 500000 -- NPC entry
local gameobjectID = 500002 -- stand entry

-- keep track of spawned NPCs per player
local spawnedNpcs = {}

-- menu constants
local ITEMS_PER_PAGE = 10
local PAGE_BASE = 100000

-- Teleport locations organised by category
local TELEPORTS = {
    ["Capital Cities"] = {
        {label="Dalaran", map=571, x=5788.603, y=472.3689, z=657.658, o=3.1},
        {label="Darnassus", map=1, x=9870.397, y=2496.041, z=1315.8765, o=3.1},
        {label="Exodar", map=530, x=-4036.6772, y=-11807.044, z=9.058392, o=0.7},
        {label="Ironforge", map=0, x=-4907.117, y=-932.803, z=501.56082, o=2.7},
        {label="Orgrimmar", map=1, x=1660.9198, y=-4325.259, z=61.936188, o=3.1},
        {label="Silvermoon", map=530, x=9477.896, y=-7297.8223, z=14.354342, o=4.6},
        {label="Shattrath", map=530, x=-1811.6487, y=5289.13, z=-12.428035, o=6.2},
        {label="Stormwind", map=0, x=-8842.421, y=472.01294, z=109.62057, o=5.9},
        {label="Thunder Bluff", map=1, x=-1217.6161, y=57.625187, z=129.6397, o=1},
        {label="Undercity", map=0, x=1580.2351, y=242.97531, z=-62.07735, o=3.5},
    },
    ["Eastern Kingdom Dungeons"] = {
        {label="Blackrock Depths - Blackrock Mountain", map=0, x=-7179.34, y=-921.212, z=165.821, o=5.09599},
        {label="Blackrock Spire - Blackrock Mountain", map=0, x=-7527.05, y=-1226.77, z=285.732, o=5.29626},
        {label="Deadmines - Westfall", map=0, x=-11208.7, y=1673.52, z=24.6361, o=1.51067},
        {label="Gnomeregan - Dun Morogh", map=0, x=-5163.54, y=925.423, z=257.181, o=1.57423},
        {label="Scarlet Monastery - Tirisfal Glades", map=0, x=2872.6, y=-764.398, z=160.332, o=5.05735},
        {label="Scholomance - Western Plaguelands", map=0, x=1269.64, y=-2556.21, z=93.6088, o=0.620623},
        {label="Shadowfang Keep - Silverpine Forest", map=0, x=-234.675, y=1561.63, z=76.8921, o=1.24031},
        {label="Stockades - Stormwind City", map=0, x=-8815.661, y=805.7985, z=98.6486, o=0.7},
        {label="Stratholme - Eastern Plaguelands", map=0, x=3352.92, y=-3379.03, z=144.782, o=6.25978},
        {label="Sunken Temple - Swamp of Sorrows", map=0, x=-10177.9, y=-3994.9, z=-111.239, o=6.01885},
        {label="Uldaman - Badlands", map=0, x=-6071.37, y=-2955.16, z=209.782, o=0.015708},
    },
    ["Eastern Kingdom Raids"] = {
        {label="Blackwing Lair - Blackrock Mountain", map=0, x=-7656.0894, y=-1222.044, z=287.7938, o=2.7},
        {label="Karazhan - Deadwind Pass", map=0, x=-11118.9, y=-2010.33, z=47.0819, o=0.649895},
        {label="Molten Core - Blackrock Mountain", map=230, x=1126.64, y=-459.94, z=-102.535, o=3.46095},
        {label="Zul'Gurub - Stranglethorn Vale", map=0, x=-11916.7, y=-1215.72, z=92.289, o=4.72454},
    },
    ["Kalimdor Dungeons"] = {
        {label="Black Morass - Caverns of Time (Tanaris)", map=1, x=-8734.3, y=-4230.11, z=-209.5, o=2.16212},
        {label="Blackfathom Deeps - Ashenvale", map=1, x=4249.99, y=740.102, z=-25.671, o=1.34062},
        {label="Culling of Stratholme - Caverns of Time (Tanaris)", map=1, x=-8750.76, y=-4442.2, z=-199.26, o=4.37694},
        {label="Dire Maul East - Feralas", map=1, x=-3980.8, y=789.005, z=161.007, o=4.71945},
        {label="Dire Maul West - Feralas", map=1, x=-3828.01, y=1250.22, z=160.226, o=3.20835},
        {label="Dire Maul North - Feralas", map=1, x=-3521.29, y=1085.2, z=161.097, o=4.7281},
        {label="Maraudon - Desolace", map=1, x=-1419.13, y=2908.14, z=137.464, o=1.57366},
        {label="Old Hillsbrad Foothills - Caverns of Time (Tanaris)", map=1, x=-8404.3, y=-4070.62, z=-208.586, o=0.237038},
        {label="Ragefire Chasm - Orgrimmar", map=1, x=1811.78, y=-4410.5, z=-18.4704, o=5.20165},
        {label="Razorfen Downs - Southern Barrens", map=1, x=-4657.3, y=-2519.35, z=81.0529, o=4.54808},
        {label="Razorfen Kraul - Southern Barrens", map=1, x=-4470.28, y=-1677.77, z=81.3925, o=1.16302},
        {label="Wailing Caverns - The Barrens", map=1, x=-804.5271, y=-2133.6702, z=91.76987, o=6.2},
        {label="Zul'Farrak - Tanaris", map=1, x=-6801.19, y=-2893.02, z=9.00388, o=0.158639},
    },
    ["Kalimdor Raids"] = {
        {label="Ahn'Qiraj - Silithus", map=1, x=-8248.499, y=1982.7864, z=129.0719, o=1.3},
        {label="Hyjal Summit - Caverns of Time (Tanaris)", map=1, x=-8177.89, y=-4181.23, z=-167.552, o=0.913338},
        {label="Ruins of Ahn'Qiraj - Silithus", map=1, x=-8406.917, y=1495.1635, z=25.65622, o=2.4},
    },
    ["Outland Dungeons"] = {
        {label="Arcatraz - Netherstorm", map=530, x=3308.92, y=1340.72, z=505.56, o=4.94686},
        {label="Auchenai Crypts - Terokkar Forest", map=530, x=-3362.04, y=5209.85, z=-101.05, o=1.60924},
        {label="Blood Furnace - Hellfire Peninsula", map=530, x=-291.324, y=3149.1, z=31.5541, o=2.27147},
        {label="Botanica - Netherstorm", map=530, x=3407.11, y=1488.48, z=182.838, o=5.59559},
        {label="Hellfire Ramparts - Hellfire Peninsula", map=530, x=-360.671, y=3071.9, z=-15.0977, o=1.89389},
        {label="Magisters Terrace - Isle of Quel'Danas", map=530, x=12884.6, y=-7317.69, z=65.5023, o=4.799},
        {label="Mana Tombs - Terokkar Forest", map=530, x=-3104.18, y=4945.52, z=-101.507, o=6.22344},
        {label="Mechanar - Netherstorm", map=530, x=2867.12, y=1549.42, z=252.159, o=3.82218},
        {label="Serpentshrine Cavern - Zangarmarsh", map=530, x=820.025, y=6864.93, z=-66.7556, o=6.28127},
        {label="Sethekk Halls - Terokkar Forest", map=530, x=-3362.2, y=4664.12, z=-101.049, o=4.6605},
        {label="Shadow Labyrinth - Terokkar Forest", map=530, x=-3627.9, y=4941.98, z=-101.049, o=3.16039},
        {label="Shattered Halls - Hellfire Peninsula", map=530, x=-305.79, y=3061.63, z=-2.53847, o=1.88888},
        {label="Slave Pens - Zangarmarsh", map=530, x=717.282, y=6979.87, z=-73.0281, o=1.50287},
        {label="Steamvault - Coilfang Reservoir (Zangarmarsh)", map=530, x=794.537, y=6927.81, z=-80.4757, o=0.159089},
        {label="Underbog - Coilfang Reservoir (Zangarmarsh)", map=530, x=763.307, y=6767.81, z=-67.7695, o=5.99726},
    },
    ["Outland Raids"] = {
        {label="Black Temple - Shadowmoon Valley", map=530, x=-3649.92, y=317.469, z=35.2827, o=2.94285},
        {label="Gruul's Lair - Blade's Edge Mountains", map=530, x=3530.06, y=5104.08, z=3.50861, o=5.51117},
        {label="Magtheridon's Lair - Hellfire Peninsula", map=530, x=-312.7, y=3087.26, z=-116.52, o=5.19026},
        {label="Sunwell Plateau - Isle of Quel'Danas", map=530, x=12574.1, y=-6774.81, z=15.0904, o=3.13788},
        {label="Tempest Keep - Netherstorm", map=530, x=3099.36, y=1518.73, z=190.3, o=4.72592},
        {label="Zul'Aman - Ghostlands", map=530, x=6851.78, y=-7972.57, z=179.242, o=4.64691},
    },
    ["Northrend Dungeons"] = {
        {label="Ahn'Kahet - Dragonblight", map=571, x=3643.31, y=2036.51, z=1.78742, o=4.33919},
        {label="Azjol-Nerub - Dragonblight", map=571, x=3677.53, y=2166.7, z=35.808, o=2.30108},
        {label="Drak'Tharon Keep - Grizzly Hills", map=571, x=4774.6, y=-2032.92, z=229.15, o=1.59},
        {label="Gundrak - Zul'Drak", map=571, x=6898.72, y=-4584.94, z=451.12, o=2.34455},
        {label="Halls of Lightning - Storm Peaks", map=571, x=9182.92, y=-1384.82, z=1110.21, o=5.57779},
        {label="Halls of Reflection - Icecrown Citadel", map=571, x=5630.44, y=1994.01, z=798.059, o=4.58756},
        {label="Halls of Stone - Storm Peaks", map=571, x=8921.91, y=-993.503, z=1039.41, o=1.55263},
        {label="Nexus - Coldara (Borean Tundra)", map=571, x=3781.81, y=6953.65, z=104.82, o=0.467432},
        {label="Oculus - Coldara (Borean Tundra)", map=571, x=3879.96, y=6984.62, z=106.312, o=3.19669},
        {label="Pit of Saron - Icecrown Citadel", map=571, x=5598.74, y=2015.85, z=798.042, o=3.81001},
        {label="Trial of the Champion - Icecrown Citadel", map=571, x=8588.42, y=791.888, z=558.236, o=3.23819},
        {label="Utgarde Keep - Howling Fjord", map=571, x=1219.72, y=-4865.28, z=41.2479, o=0.313228},
        {label="Utgarde Pinnacle - Howling Fjord", map=571, x=1259.33, y=-4852.02, z=215.763, o=3.48293},
        {label="Violet Hold - Dalaran (Northrend)", map=571, x=5696.73, y=507.4, z=652.97, o=4.03},
    },
    ["Northrend Raids"] = {
        {label="Eye of Eternity - Coldara (Borean Tundra)", map=571, x=3859.44, y=6989.85, z=152.041, o=5.79635},
        {label="Icecrown Citadel - Icecrown", map=571, x=5873.82, y=2110.98, z=636.011, o=3.5523},
        {label="Naxxramas - Dragonblight", map=571, x=3668.72, y=-1262.46, z=243.622, o=4.785},
        {label="Obsidian Sanctum - Dragonblight", map=571, x=3457.11, y=262.394, z=-113.819, o=3.28258},
        {label="Onyxia's Lair - Dustwallow Marsh", map=1, x=-4708.27, y=-3727.64, z=54.5589, o=3.72786},
        {label="Ruby Sanctum - Dragonblight", map=571, x=3600.5, y=197.34, z=-113.76, o=5.29905},
        {label="Trial of the Crusader - Icecrown", map=571, x=8515.68, y=716.982, z=558.248, o=1.57315},
        {label="Ulduar - Storm Peaks", map=571, x=9049.37, y=-1282.35, z=1060.19, o=5.8395},
    },
}

local FLIGHTPOINTS = {
{fp="Lakeshire", zone="Redridge Mountains", fract="a", x=-9435.21, y=-2234.88, z=69.1882, o=0.0, map=0},
{fp="Chillwind Camp", zone="Western Plaguelands", fract="a", x=928.273, y=-1429.08, z=64.8343, o=0.0, map=0},
{fp="Zoram'gar Outpost", zone="Ashenvale", fract="h", x=3373.69, y=994.351, z=5.36158, o=0.0, map=1},
{fp="Morgan's Vigil", zone="Burning Steppes", fract="a", x=-8365.08, y=-2736.93, z=185.691, o=0.0, map=0},
{fp="Stonard", zone="Swamp of Sorrows", fract="h", x=-10459.2, y=-3279.76, z=21.5445, o=0.0, map=0},
{fp="Refuge Pointe", zone="Arathi Highlands", fract="a", x=-1240.03, y=-2513.96, z=21.9831, o=0.0, map=0},
{fp="Southshore", zone="Hillsbrad Foothills", fract="a", x=-715.146, y=-512.134, z=26.6793, o=0.0, map=0},
{fp="Theramore Isle", zone="Dustwallow Marsh", fract="a", x=-3828.88, y=-4517.51, z=10.7437, o=0.0, map=1},
{fp="Sanctum of the Stars", zone="Shadowmoon Valley", fract="n", x=-4067.27, y=1127.53, z=43.0965, o=0.0, map=530},
{fp="Sylvanaar", zone="Blade's Edge Mountains", fract="a", x=2187.88, y=6794.0, z=183.413, o=0.0, map=530},
{fp="Nijel's Point", zone="Desolace", fract="a", x=136.218, y=1326.33, z=193.582, o=0.0, map=1},
{fp="Gadgetzan", zone="Tanaris", fract="a", x=-7224.87, y=-3738.21, z=8.48369, o=0.0, map=1},
{fp="Ratchet", zone="The Barrens", fract="n", x=-898.246, y=-3769.65, z=11.7932, o=0.0, map=1},
{fp="Darkshire", zone="Duskwood", fract="a", x=-10513.8, y=-1258.79, z=41.5138, o=0.0, map=0},
{fp="Bloodvenom Post", zone="Felwood", fract="h", x=5064.72, y=-338.845, z=367.463, o=0.0, map=1},
{fp="Gadgetzan", zone="Tanaris", fract="h", x=-7045.24, y=-3779.4, z=10.3158, o=0.0, map=1},
{fp="Thondroril River", zone="Western Plaguelands", fract="a", x=1943.14, y=-2561.74, z=60.9247, o=0.0, map=0},
{fp="Pestilent Scar", zone="Eastern Plaguelands", fract="h", x=2328.48, y=-5290.72, z=81.8744, o=0.0, map=0},
{fp="Revantusk Village", zone="The Hinterlands", fract="h", x=-631.736, y=-4720.6, z=5.48226, o=0.0, map=0},
{fp="Kargath", zone="Badlands", fract="h", x=-6632.22, y=-2178.42, z=244.227, o=0.0, map=0},
{fp="Auberdine", zone="Darkshore", fract="a", x=6343.2, y=561.651, z=16.1047, o=0.0, map=1},
{fp="Cenarion Hold", zone="Silithus", fract="n", x=-6758.55, y=775.594, z=89.1046, o=0.0, map=1},
{fp="Astranaar", zone="Ashenvale", fract="a", x=2828.38, y=-284.25, z=106.69, o=0.0, map=1},
{fp="The Crossroads", zone="The Barrens", fract="h", x=-437.137, y=-2596.0, z=95.8708, o=0.0, map=1},
{fp="Mudsprocket", zone="Dustwallow Marsh", fract="a", x=-4568.4, y=-3223.19, z=34.9894, o=0.0, map=1},
{fp="Acherus: The Ebon Hold", zone="Eastern Plaguelands", fract="n", x=2348.63, y=-5669.29, z=382.324, o=0.0, map=0},
{fp="Booty Bay", zone="Stranglethorn Vale", fract="h", x=-14448.6, y=506.129, z=26.3565, o=0.0, map=0},
{fp="Lake Elune’ara", zone="Moonglade", fract="h", x=7466.15, y=-2122.08, z=492.427, o=0.0, map=1},
{fp="Feathermoon Stronghold", zone="Feralas", fract="a", x=-4370.54, y=3340.11, z=12.352, o=0.0, map=1},
{fp="Thorium Point", zone="Searing Gorge", fract="h", x=-6559.26, y=-1100.23, z=310.353, o=0.0, map=0},
{fp="Aerie Peak", zone="The Hinterlands", fract="a", x=282.096, y=-2001.28, z=194.127, o=0.0, map=0},
{fp="Booty Bay", zone="Stranglethorn Vale", fract="a", x=-14477.9, y=464.101, z=36.4656, o=0.0, map=0},
{fp="The Sepulcher", zone="Silverpine Forest", fract="h", x=473.939, y=1533.95, z=131.96, o=0.0, map=0},
{fp="Light's Hope Chapel", zone="Eastern Plaguelands", fract="a", x=2269.85, y=-5345.39, z=87.0242, o=0.0, map=0},
{fp="Thorium Point", zone="Searing Gorge", fract="a", x=-6559.06, y=-1169.38, z=309.809, o=0.0, map=0},
{fp="Emerald Sanctuary", zone="Felwood", fract="n", x=3981.74, y=-1321.47, z=251.124, o=0.0, map=1},
{fp="Marshal's Refuge", zone="Un'Goro Crater", fract="n", x=-6110.54, y=-1140.35, z=-186.866, o=0.0, map=1},
{fp="Talrendis Point", zone="Azshara", fract="n", x=2718.18, y=-3880.75, z=101.532, o=0.0, map=1},
{fp="Rebel Camp", zone="Stranglethorn Vale", fract="a", x=-11340.5, y=-219.14, z=75.2143, o=0.0, map=0},
{fp="Menethil Harbor", zone="Wetlands", fract="a", x=-3793.2, y=-782.052, z=9.09773, o=0.0, map=0},
{fp="Valormok", zone="Azshara", fract="h", x=3664.02, y=-4390.45, z=113.169, o=0.0, map=1},
{fp="Everlook", zone="Winterspring", fract="a", x=6800.54, y=-4742.35, z=701.62, o=0.0, map=1},
{fp="Talonbranch Glade", zone="Felwood", fract="a", x=6204.08, y=-1951.43, z=571.581, o=0.0, map=1},
{fp="Freewind Post", zone="Thousand Needles", fract="h", x=-5407.12, y=-2419.61, z=89.7094, o=0.0, map=1},
{fp="Camp Taurajo", zone="The Barrens", fract="h", x=-2384.08, y=-1880.94, z=95.9336, o=0.0, map=1},
{fp="Sentinel Hill", zone="Westfall", fract="a", x=-10628.3, y=1037.27, z=34.1915, o=0.0, map=0},
{fp="Thelsamar", zone="Loch Modan", fract="a", x=-5424.85, y=-2929.87, z=347.645, o=0.0, map=0},
{fp="Cenarion Hold", zone="Silithus", fract="h", x=-6810.2, y=841.704, z=49.7481, o=0.0, map=1},
{fp="Brackenwall Village", zone="Dustwallow Marsh", fract="h", x=-3149.14, y=-2842.13, z=34.6649, o=0.0, map=1},
{fp="Camp Mojache", zone="Feralas", fract="h", x=-4421.94, y=198.146, z=25.1863, o=0.0, map=1},
{fp="Lake Elune’ara", zone="Moonglade", fract="a", x=7454.85, y=-2491.61, z=462.699, o=0.0, map=1},
{fp="Forest Song", zone="Ashenvale", fract="a", x=3002.88, y=-3206.81, z=190.114, o=0.0, map=1},
{fp="Grom'gol Base Camp", zone="Stranglethorn Vale", fract="h", x=-12417.5, y=144.474, z=3.36881, o=0.0, map=0},
{fp="The Bulwark", zone="Tirisfal Glades", fract="h", x=1730.37, y=-743.194, z=59.4174, o=0.0, map=0},
{fp="Hammerfall", zone="Arathi Highlands", fract="h", x=-917.658, y=-3496.94, z=70.4505, o=0.0, map=0},
{fp="Stonetalon Peak", zone="Stonetalon Mountains", fract="a", x=2682.83, y=1466.45, z=233.792, o=0.0, map=1},
{fp="Flame Crest", zone="Burning Steppes", fract="h", x=-7504.06, y=-2190.77, z=165.302, o=0.0, map=0},
{fp="Tarren Mill", zone="Hillsbrad Foothills", fract="h", x=2.67557, y=-857.919, z=58.889, o=0.0, map=0},
{fp="Shadowprey Village", zone="Desolace", fract="h", x=-1770.37, y=3262.19, z=5.27958, o=0.0, map=1},
{fp="Sun Rock Retreat", zone="Stonetalon Mountains", fract="h", x=968.077, y=1042.29, z=104.563, o=0.0, map=1},
{fp="Shattered Sun Staging Area", zone="Isle of Quel'Danas", fract="h", x=13012.7, y=-6910.98, z=9.68319, o=0.0, map=530},
{fp="Tranquillien", zone="Ghostlands", fract="h", x=7595.16, y=-6782.24, z=86.878, o=0.0, map=530},
{fp="Eversong Woods", zone="Eversong Woods", fract="h", x=9376.4, y=-7164.92, z=9.0194, o=0.0, map=530},
{fp="Thalanaar", zone="Feralas", fract="a", x=-4491.12, y=-778.347, z=-40.1193, o=0.0, map=1},
{fp="Rut'theran Village", zone="Teldrassil", fract="a", x=8640.58, y=841.118, z=23.3464, o=0.0, map=1},
{fp="Splintertree Post", zone="Ashenvale", fract="h", x=2305.64, y=-2520.15, z=103.893, o=0.0, map=1},
{fp="Everlook", zone="Winterspring", fract="h", x=6815.12, y=-4610.12, z=710.759, o=0.0, map=1},
{fp="Spinebreaker Post", zone="Hellfire Peninsula", fract="h", x=-1314.93, y=2355.39, z=89.0385, o=0.0, map=530},
{fp="The Stair of Destiny", zone="Hellfire Peninsula", fract="a", x=-323.81, y=1027.61, z=54.2399, o=0.0, map=530},
{fp="Thrallmar", zone="Hellfire Peninsula", fract="h", x=233.137, y=2632.3, z=88.3007, o=0.0, map=530},
{fp="Wildhammer Stronghold", zone="Shadowmoon Valley", fract="a", x=-3980.97, y=2156.29, z=105.233, o=0.0, map=530},
{fp="Shadowmoon Village", zone="Shadowmoon Valley", fract="h", x=-3018.0, y=2556.0, z=79.1, o=0.0, map=530},
{fp="Zabra'jin", zone="Zangarmarsh", fract="h", x=223.468, y=7812.55, z=22.6859, o=0.0, map=530},
{fp="Evergrove", zone="Blade's Edge Mountains", fract="n", x=2975.63, y=5499.79, z=143.668, o=0.0, map=530},
{fp="Honor Hold", zone="Hellfire Peninsula", fract="a", x=-665.804, y=2715.48, z=94.1981, o=0.0, map=530},
{fp="Telaar", zone="Nagrand", fract="a", x=-2723.1, y=7302.84, z=88.7157, o=0.0, map=530},
{fp="Allerian Stronghold", zone="Terokkar Forest", fract="a", x=-2995.4, y=3873.27, z=9.6248, o=0.0, map=530},
{fp="The Stormspire", zone="Netherstorm", fract="n", x=4160.16, y=2957.3, z=352.298, o=0.0, map=530},
{fp="Swamprat Post", zone="Zangarmarsh", fract="h", x=87.9806, y=5213.79, z=23.3282, o=0.0, map=530},
{fp="Garadar", zone="Nagrand", fract="h", x=-1256.63, y=7136.17, z=57.3484, o=0.0, map=530},
{fp="Orebor Harborage", zone="Zangarmarsh", fract="a", x=963.428, y=7399.58, z=29.3317, o=0.0, map=530},
{fp="Cosmowrench", zone="Netherstorm", fract="n", x=2973.2, y=1848.45, z=141.085, o=0.0, map=530},
{fp="Falcon Watch", zone="Hellfire Peninsula", fract="h", x=-584.367, y=4104.07, z=91.5878, o=0.0, map=530},
{fp="Stonebreaker Hold", zone="Terokkar Forest", fract="h", x=-2563.19, y=4426.77, z=39.4383, o=0.0, map=530},
{fp="Hatchet Hills", zone="Ghostlands", fract="n", x=6789.3, y=-7750.54, z=126.815, o=0.0, map=530},
{fp="Area 52", zone="Netherstorm", fract="n", x=3085.3, y=3600.82, z=144.111, o=0.0, map=530},
{fp="Temple of Telhamat", zone="Hellfire Peninsula", fract="a", x=199.061, y=4238.42, z=121.81, o=0.0, map=530},
{fp="Blood Watch", zone="Bloodmyst Isle", fract="a", x=-1930.02, y=-11956.8, z=57.4743, o=0.0, map=530},
{fp="Altar of Sha'tar", zone="Shadowmoon Valley", fract="n", x=-3062.63, y=741.933, z=-10.0639, o=0.0, map=530},
{fp="Telredor", zone="Telredor", fract="a", x=210.492, y=6065.09, z=148.396, o=0.0, map=530},
{fp="Toshley's Station", zone="Blade's Edge Mountains", fract="a", x=1860.71, y=5528.27, z=277.588, o=0.0, map=530},
{fp="Shatter Point", zone="Hellfire Peninsula", fract="a", x=279.397, y=1489.76, z=-15.4411, o=0.0, map=530},
{fp="Mok'Nathal Village", zone="Blade's Edge Mountains", fract="h", x=2023.78, y=4702.71, z=150.667, o=0.0, map=530},
{fp="Thunderlord Stronghold", zone="Blade's Edge Mountains", fract="h", x=2451.06, y=6022.06, z=154.839, o=0.0, map=530},
{fp="The Stair of Destiny", zone="Hellfire Peninsula", fract="h", x=-176.42, y=1028.53, z=54.2562, o=0.0, map=530},
{fp="The Argent Vanguard", zone="Icecrown", fract="a", x=6162.62, y=-62.0921, z=388.264, o=0.0, map=571},
{fp="Ebon Watch", zone="Zul'Drak", fract="h", x=5218.97, y=-1299.12, z=242.35, o=0.0, map=571},
{fp="Vengeance Landing", zone="Howling Fjord", fract="h", x=1919.03, y=-6176.72, z=24.5655, o=0.0, map=571},
{fp="Unu'pe", zone="Borean Tundra", fract="n", x=2917.21, y=4043.44, z=1.8677, o=0.0, map=571},
{fp="Bouldercrag's Refuge", zone="The Storm Peaks", fract="n", x=8475.49, y=-337.946, z=906.009, o=0.0, map=571},
{fp="Camp Winterhoof", zone="Howling Fjord", fract="h", x=2649.27, y=-4394.5, z=283.388, o=0.0, map=571},
{fp="Moa'ki Harbor", zone="Dragonblight", fract="n", x=2793.19, y=906.36, z=22.5437, o=0.0, map=571},
{fp="Light's Breach", zone="Zul'Drak", fract="n", x=5192.26, y=-2207.04, z=239.482, o=0.0, map=571},
{fp="Fordragon Hold", zone="Dragonblight", fract="a", x=4606.09, y=1410.71, z=194.831, o=0.0, map=571},
{fp="Death's Rise", zone="Icecrown", fract="n", x=7429.6, y=4231.64, z=314.367, o=0.0, map=571},
{fp="Frosthold", zone="The Storm Peaks", fract="a", x=6665.59, y=-261.258, z=961.82, o=0.0, map=571},
{fp="Windrunner's Overlook", zone="Crystalsong Forest", fract="a", x=5032.91, y=-521.242, z=226.074, o=0.0, map=571},
{fp="Westguard Keep", zone="Howling Fjord", fract="a", x=1343.75, y=-3287.78, z=174.536, o=0.0, map=571},
{fp="The Argent Stand", zone="Zul'Drak", fract="n", x=5523.68, y=-2674.97, z=304.037, o=0.0, map=571},
{fp="Argent Tournament Grounds", zone="Icecrown", fract="n", x=8481.62, y=891.614, z=547.425, o=0.0, map=571},
{fp="Camp Tunka'lo", zone="The Storm Peaks", fract="h", x=7798.38, y=-2810.29, z=1217.93, o=0.0, map=571},
{fp="Nethergarde Keep", zone="Blasted Lands", fract="a", x=-11110.2, y=-3437.1, z=79.282, o=0.0, map=0},
{fp="Fort Wildervar", zone="Howling Fjord", fract="a", x=2467.34, y=-5028.79, z=283.778, o=0.0, map=571},
{fp="Venomspite", zone="Dragonblight", fract="h", x=3248.77, y=-662.297, z=166.873, o=0.0, map=571},
{fp="Grom'arsh Crash-Site", zone="The Storm Peaks", fract="h", x=7855.98, y=-732.388, z=1177.56, o=0.0, map=571},
{fp="Fizzcrank Airstrip", zone="Borean Tundra", fract="a", x=4126.8, y=5309.59, z=28.8055, o=0.0, map=571},
{fp="Bor'gorok Outpost", zone="Borean Tundra", fract="h", x=4473.24, y=5708.79, z=81.3463, o=0.0, map=571},
{fp="Kamagua", zone="Howling Fjord", fract="n", x=787.755, y=-2889.06, z=6.49197, o=0.0, map=571},
{fp="Conquest Hold", zone="Grizzly Hills", fract="h", x=3261.52, y=-2265.45, z=114.181, o=0.0, map=571},
{fp="Apothecary Camp", zone="Howling Fjord", fract="h", x=2106.05, y=-2968.81, z=148.667, o=0.0, map=571},
{fp="Zim'Torga", zone="Zul'Drak", fract="n", x=5780.84, y=-3598.16, z=387.238, o=0.0, map=571},
{fp="Camp Oneqwah", zone="Grizzly Hills", fract="h", x=3874.18, y=-4520.87, z=217.302, o=0.0, map=571},
{fp="The Shadow Vault", zone="Icecrown", fract="n", x=8407.96, y=2700.43, z=655.201, o=0.0, map=571},
{fp="Agmar's Hammer", zone="Dragonblight", fract="h", x=3863.63, y=1523.11, z=90.2259, o=0.0, map=571},
{fp="Kor'kron Vanguard", zone="Dragonblight", fract="h", x=4941.59, y=1167.95, z=239.402, o=0.0, map=571},
{fp="Taunka'le Village", zone="Borean Tundra", fract="h", x=3446.11, y=4088.41, z=16.8603, o=0.0, map=571},
{fp="Stars' Rest", zone="Dragonblight", fract="a", x=3506.07, y=1990.42, z=65.2658, o=0.0, map=571},
{fp="Crusaders' Pinnacle", zone="Icecrown", fract="n", x=6401.22, y=464.245, z=512.632, o=0.0, map=571},
{fp="Valgarde", zone="Howling Fjord", fract="a", x=567.415, y=-5012.58, z=11.5673, o=0.0, map=571},
{fp="Dubra'Jin", zone="Zul'Drak", fract="n", x=6893.54, y=-4118.87, z=467.437, o=0.0, map=571},
{fp="Wintergarde Keep", zone="Dragonblight", fract="a", x=3712.43, y=-694.86, z=215.36, o=0.0, map=571},
{fp="Westfall Brigade Encampment", zone="Grizzly Hills", fract="a", x=4582.63, y=-4254.86, z=182.291, o=0.0, map=571},
{fp="Ulduar", zone="The Storm Peaks", fract="n", x=8861.33, y=-1322.39, z=1033.4, o=0.0, map=571},
{fp="K3", zone="The Storm Peaks", fract="n", x=6188.97, y=-1056.53, z=409.906, o=0.0, map=571},
{fp="Sunreaver's Command", zone="Crystalsong Forest", fract="h", x=5587.26, y=-694.69, z=206.71, o=0.0, map=571},
{fp="Amber Ledge", zone="Borean Tundra", fract="n", x=3571.12, y=5957.59, z=136.303, o=0.0, map=571},
{fp="Nesingwary Base Camp", zone="Sholazar Basin", fract="n", x=5587.64, y=5830.73, z=-67.8657, o=0.0, map=571},
{fp="New Agamand", zone="Howling Fjord", fract="h", x=400.47, y=-4542.25, z=245.089, o=0.0, map=571},
{fp="Valiance Keep", zone="Borean Tundra", fract="a", x=2272.98, y=5171.82, z=11.246, o=0.0, map=571},
{fp="Warsong Hold", zone="Borean Tundra", fract="h", x=2922.39, y=6244.39, z=208.835, o=0.0, map=571},
{fp="Amberpine Lodge", zone="Grizzly Hills", fract="a", x=3447.84, y=-2754.01, z=199.408, o=0.0, map=571},
{fp="Transitus Shield", zone="Borean Tundra", fract="n", x=3573.9, y=6661.07, z=195.263, o=0.0, map=571},
}

-- Map IDs to continent names
local CONTINENTS = {
    [0]   = "Eastern Kingdoms",
    [1]   = "Kalimdor",
    [530] = "Outland",
    [571] = "Northrend",
}

-- Build hierarchical menu
local ROOT = {label = "Teleports", children = {}}

-- Helper to insert a category node
local function addCategory(parent, label, items)
    table.insert(parent.children, {label = label, items = items})
end

-- Add standard teleport categories in order
local ORDERED_CATEGORIES = {
    "Capital Cities",
    "Eastern Kingdom Dungeons",
    "Eastern Kingdom Raids",
    "Kalimdor Dungeons",
    "Kalimdor Raids",
    "Outland Dungeons",
    "Outland Raids",
    "Northrend Dungeons",
    "Northrend Raids",
}

for _, name in ipairs(ORDERED_CATEGORIES) do
    addCategory(ROOT, name, TELEPORTS[name])
end

-- Flight point tree: faction -> continent -> zone
local flightRoot = {label = "Flight Points", children = {}}

local factions = {a = "Alliance", h = "Horde"}
local factionNodes = {}
for code, name in pairs(factions) do
    local node = {label = name, children = {}}
    factionNodes[code] = node
    table.insert(flightRoot.children, node)
end

local function addFlight(fcode, continent, zone, fp)
    local factionNode = factionNodes[fcode]
    local contNode = factionNode.children[continent]
    if not contNode then
        contNode = {label = continent, children = {}}
        factionNode.children[continent] = contNode
        table.insert(factionNode.children, contNode)
    end

    local zoneNode = contNode.children[zone]
    if not zoneNode then
        zoneNode = {label = zone, items = {}}
        contNode.children[zone] = zoneNode
        table.insert(contNode.children, zoneNode)
    end

    table.insert(zoneNode.items, {
        label = fp.fp,
        map   = fp.map or 0,
        x     = fp.x,
        y     = fp.y,
        z     = fp.z,
        o     = fp.o or 0,
    })
end

for _, fp in ipairs(FLIGHTPOINTS) do
    local cont = CONTINENTS[fp.map] or "Unknown"
    local zone = fp.zone or "Unknown"
    if fp.fract == 'a' or fp.fract == 'n' then
        addFlight('a', cont, zone, fp)
    end
    if fp.fract == 'h' or fp.fract == 'n' then
        addFlight('h', cont, zone, fp)
    end
end

table.insert(ROOT.children, flightRoot)

-- Assign unique IDs for menu navigation
local NODE_LOOKUP, ITEM_LOOKUP = {}, {}
local nextId = 1

local function registerNode(node, parent)
    node.parent = parent
    node.id = nextId
    NODE_LOOKUP[nextId] = node
    nextId = nextId + 1
    if node.children then
        for _, child in ipairs(node.children) do
            registerNode(child, node)
        end
    end
    if node.items then
        for _, item in ipairs(node.items) do
            item.id = nextId
            ITEM_LOOKUP[nextId] = item
            nextId = nextId + 1
        end
    end
end

registerNode(ROOT)

local function ShowNode(player, object, nodeId, page)
    player:GossipClearMenu()
    local node = NODE_LOOKUP[nodeId]
    if not node then return end
    page = page or 0
    local entries = {}
    if node.children then
        for _, child in ipairs(node.children) do
            table.insert(entries, {label = child.label, id = child.id, isNode = true})
        end
    end
    if node.items then
        for _, item in ipairs(node.items) do
            table.insert(entries, {label = item.label, id = item.id, isNode = false})
        end
    end

    local startIndex = page * ITEMS_PER_PAGE + 1
    local endIndex = math.min(startIndex + ITEMS_PER_PAGE - 1, #entries)
    for i = startIndex, endIndex do
        local e = entries[i]
        player:GossipMenuAddItem(0, e.label, 1, e.id)
    end
    if endIndex < #entries then
        player:GossipMenuAddItem(0, "Next...", 1, nodeId * PAGE_BASE + (page + 1))
    end
    if page > 0 then
        player:GossipMenuAddItem(0, "Back...", 1, nodeId * PAGE_BASE + (page - 1))
    elseif node.parent then
        player:GossipMenuAddItem(0, "Back", 1, node.parent.id)
    end
    player:GossipSendMenu(1, object)
end

local function OnGossipHello(event, player, object)
    object = object or player
    ShowNode(player, object, ROOT.id, 0)
end

local function OnGossipSelect(event, player, object, sender, intid, code)
    object = object or player
    if NODE_LOOKUP[intid] then
        ShowNode(player, object, intid, 0)
    elseif intid >= PAGE_BASE then
        local nodeId = math.floor(intid / PAGE_BASE)
        local page  = intid % PAGE_BASE
        ShowNode(player, object, nodeId, page)
    elseif ITEM_LOOKUP[intid] then
        local tp = ITEM_LOOKUP[intid]
        player:Teleport(tp.map, tp.x, tp.y, tp.z, tp.o)
        player:GossipComplete()
    else
        ShowNode(player, object, ROOT.id, 0)
    end
end

if creatureID and creatureID ~= 0 then
    RegisterCreatureGossipEvent(creatureID, 1, OnGossipHello)
    RegisterCreatureGossipEvent(creatureID, 2, OnGossipSelect)
end

if gameobjectID and gameobjectID ~= 0 then
    RegisterGameObjectGossipEvent(gameobjectID, 1, OnGossipHello)
    RegisterGameObjectGossipEvent(gameobjectID, 2, OnGossipSelect)
end

-- Spawn NPC
local function SpawnNpcNearPlayer(player)
    local x, y, z, o = player:GetLocation()
    local distance = 2
    local spawnX = x + distance * math.cos(o)
    local spawnY = y + distance * math.sin(o)
    local npc = player:SpawnCreature(creatureID, spawnX, spawnY, z, o + math.pi, 3, 30000) 
    if npc then
        npc:SetPhaseMask(player:GetPhaseMask(), true)
        -- save npc object
        spawnedNpcs[player:GetGUIDLow()] = npc
        -- open menu 
        OnGossipHello(nil, player, npc)
    end
    return npc
end

-- chat command Transveho spawn NPC
local function OnCommand(event, player, msg)
    if msg == "Transveho" then
        local npc = SpawnNpcNearPlayer(player)
        return false
    end
end

RegisterPlayerEvent(18, OnCommand)
