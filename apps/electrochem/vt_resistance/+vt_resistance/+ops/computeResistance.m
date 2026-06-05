% Expected caller: VT resistance app runner and unit tests. Inputs are a DTA item
% struct and option struct. Output is the stable resistance result struct. No
% file or UI side effects.
function A = computeResistance(item, opts)
    A = vt_resistance.core.dispatch("computeResistance", item, opts);
end
