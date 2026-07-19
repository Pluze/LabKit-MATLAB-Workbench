% Private UI contract helper. Expected callers: sealed explicit-contract
% values in labkit.ui. Inputs are the public symbol, canonical allowed names,
% and raw Name-Value arguments. Output is a scalar struct containing supplied
% values. Side effect: throws stable public contract errors.
function values = parseContractOptions(symbol, allowed, varargin)
    if mod(numel(varargin), 2) ~= 0
        error("labkit:ui:contract:UnknownArgument", ...
            "%s requires paired Name-Value arguments.", symbol);
    end
    values = struct();
    allowed = string(allowed);
    for k = 1:2:numel(varargin)
        name = varargin{k};
        if ~(ischar(name) || (isstring(name) && isscalar(name)))
            error("labkit:ui:contract:UnknownArgument", ...
                "%s argument names must be text scalars.", symbol);
        end
        name = string(name);
        if ~any(name == allowed) || isfield(values, name)
            error("labkit:ui:contract:UnknownArgument", ...
                "%s received an unknown or duplicate argument: %s.", ...
                symbol, name);
        end
        values.(name) = varargin{k + 1};
    end
end
