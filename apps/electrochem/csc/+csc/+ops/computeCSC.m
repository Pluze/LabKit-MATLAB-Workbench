% Expected caller: CSC app runner and unit tests. Inputs are a CV/CT curve struct
% and CSC options. Output is the stable CSC comparison result struct. No file or
% UI side effects.
function A = computeCSC(curve, opts)
    A = csc.core.dispatch("computeCSC", curve, opts);
end
