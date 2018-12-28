module TrainTracksWithDataModule

using Donut.TrainTracks
using Donut.TrainTracks.Measures
using Donut.TrainTracks.Carrying

struct TrainTracksWithData
    tts::Vector{TrainTrack}
    cusphandlers::Vector{Tuple{Int, CuspHandler}} # (tt_index, cusp handler)
    measures::Vector{Tuple{Int, Measure}}  # (tt_index, measure)
    carrying_maps::Vector{Tuple{Int, Int, CarryingMap}} # (small_tt_index, large_tt_index, carryingmap)
    # Other things we could add: transverse measure, signed measure for oriented curves 
end

TrainTracksWithData() = TrainTracksWithData([], [], [])

function add_train_track!(ttwd::TrainTracksWithData, tt::TrainTrack)
    push!(ttwd.tts, tt)
    return length(ttwd.tts)
end

function cusphandler_of_tt(ttwd::TrainTracksWithData, tt_index::Int)
    for (idx, ch) in ttwd.cusphandlers
        if idx == tt_index
            return ch
        end
    end
    return nothing
    # error("The train track with index $(tt_index) has no cusp handler stored.")
end

function add_cusphandler!(ttwd::TrainTracksWithData, tt_index::Int)
    ch = cusphandler_of_tt(ttwd, tt_index)
    if ch != nothing
        error("The train track with index $(tt_index) already has a cusphandler stored.")
    end
    tt = ttwd.tts[tt_index]
    ch = CuspHandler(tt)
    push!(ttwd.cusphandlers, (tt_index, ch))
    return ch
end


function add_carryingmap_as_small_tt!(ttwd::TrainTracksWithData, small_tt_index::Int)
    tt = ttwd.tts[small_tt_index]
    ch = cusphandler_of_tt(ttwd, small_tt_index)
    if ch == nothing
        ch = add_cusphandler!(ttwd, small_tt_index)
    end
    cm = CarryingMap(tt, ch)
    large_tt_index = add_train_track!(ttwd, cm.large_tt)
    add_cusphandler!(ttwd, cm.large_cusphandler)
    push!(ttwd.carrying_maps, (small_tt_index, large_tt_index, cm))
    return large_tt_index
end

end