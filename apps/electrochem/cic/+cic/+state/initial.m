% App-owned state factory for CIC. Expected caller is the LabKit app
% runtime. Output is the mutable app state struct used by actions and
% render. Side effects are none.
function state = initial()
    state = struct();
    state.items = struct([]);
    state.current = [];
end
