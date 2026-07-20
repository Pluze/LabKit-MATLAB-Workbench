classdef (Sealed, Hidden) OptionParser
    % Private strict Name-Value parser for App SDK contract values.

    methods (Static)
        function values = parse(symbol, allowed, varargin)
            if mod(numel(varargin), 2) ~= 0
                error("labkit:app:contract:UnknownArgument", ...
                    "%s requires paired Name-Value arguments.", symbol);
            end
            values = struct();
            allowed = string(allowed);
            for k = 1:2:numel(varargin)
                name = varargin{k};
                if ~(ischar(name) || ...
                        (isstring(name) && isscalar(name)))
                    error("labkit:app:contract:UnknownArgument", ...
                        "%s argument names must be text scalars.", symbol);
                end
                name = string(name);
                if ~any(name == allowed) || isfield(values, name)
                    error("labkit:app:contract:UnknownArgument", ...
                        "%s received an unknown or duplicate argument: %s.", ...
                        symbol, name);
                end
                values.(name) = varargin{k + 1};
            end
        end
    end
end
