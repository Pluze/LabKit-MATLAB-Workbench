% Expected caller: CIC app runner and unit tests. Inputs are a DTA item struct
% and CIC option struct. Output is the stable CIC analysis result struct. No file
% or UI side effects.
function A = computeCIC(item, opts)
    A = cic.core.dispatch("computeCIC", item, opts);
end
