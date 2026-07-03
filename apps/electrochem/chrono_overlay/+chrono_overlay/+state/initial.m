% App-owned state factory for Chrono Overlay. Expected caller is the LabKit
% app runtime. Output is the mutable app state struct used by actions/render.
% Side effects are none.
function state = initial()
    state = struct();
    state.items = struct([]);
end
