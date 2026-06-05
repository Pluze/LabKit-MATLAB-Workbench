% Expected caller: EIS app runner. Input is EIS item structs. Output is the
% stable summary text cell array. No side effects.
function summary = buildSummary(items)
    summary = eis.core.dispatch("buildSummary", items);
end
