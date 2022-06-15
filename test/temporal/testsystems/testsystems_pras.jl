module TestSystems_pras
using PRAS
using TimeZones
const tz = tz"UTC"

empty_str = String[]
empty_int(x) = Matrix{Int}(undef, 0, x)
empty_float(x) = Matrix{Float64}(undef, 0, x)

## Single-Region System A2
gens11 = PRAS.Generators{4,1,Hour,MW}(
    ["Gen1", "Gen2", "Gen3", "VG"], ["Gens", "Gens", "Gens", "VG"],
    [fill(10, 3, 4); [5 6 7 8]],
    [fill(0.1, 3, 4); fill(0.0, 1, 4)],
    [fill(0.9, 3, 4); fill(1.0, 1, 4)]
)

emptystors11 = PRAS.Storages{4,1,Hour,MW,MWh}((empty_str for _ in 1:2)...,
                (empty_int(4) for _ in 1:3)...,
                (empty_float(4) for _ in 1:5)...
)

emptygenstors11 = PRAS.GeneratorStorages{4,1,Hour,MW,MWh}(
    (empty_str for _ in 1:2)...,
    (empty_int(4) for _ in 1:3)..., (empty_float(4) for _ in 1:3)...,
    (empty_int(4) for _ in 1:3)..., (empty_float(4) for _ in 1:2)...
)

singlenode_a2 = PRAS.SystemModel(
    gens11, emptystors11, emptygenstors11,
    DateTime(2010,1,1,0):Hour(1):DateTime(2010,1,1,3),
    [25, 28, 27, 24]
)
##


end
import .TestSystems_pras


