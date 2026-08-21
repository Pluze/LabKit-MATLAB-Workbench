% Read and update strict App-owned state paths for RuntimeKernel.
% Expected caller: RuntimeKernel transaction and file-list operations.
% Inputs and outputs are scalar application-state structs. Updates rebuild
% nested structs without mutating the supplied value and raise stable
% contract errors when a declared path is unavailable.
classdef (Sealed, Hidden) RuntimeStatePath
    methods (Static)
        function value = read(state, path)
            parts = split(path, ".");
            value = state;
            for k = 1:numel(parts)
                name = char(parts(k));
                if ~isstruct(value) || ~isscalar(value) || ...
                        ~isfield(value, name)
                    error("labkit:app:contract:UnknownReference", ...
                        "Bound state path is unavailable: %s.", path);
                end
                value = value.(name);
            end
        end

        function state = write(state, path, value)
            parts = split(path, ".");
            state = labkit.app.internal.runtime.RuntimeStatePath.assign( ...
                state, parts, value, path);
        end
    end

    methods (Static, Access = private)
        function owner = assign(owner, parts, value, path)
            name = char(parts(1));
            if ~isstruct(owner) || ~isscalar(owner) || ~isfield(owner, name)
                error("labkit:app:contract:UnknownReference", ...
                    "Bound state path is unavailable: %s.", path);
            end
            if isscalar(parts)
                owner.(name) = value;
                return;
            end
            owner.(name) = labkit.app.internal.runtime.RuntimeStatePath.assign( ...
                owner.(name), parts(2:end), value, path);
        end
    end
end
