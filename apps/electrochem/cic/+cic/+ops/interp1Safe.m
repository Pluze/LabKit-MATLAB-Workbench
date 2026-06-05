% Expected caller: CIC app plotting helpers. Inputs are vectors x/y and query
% points. Output mirrors the app-owned safe interpolation helper. No side effects.
function v = interp1Safe(x, y, xq)
    v = cic.core.dispatch("interp1Safe", x, y, xq);
end
