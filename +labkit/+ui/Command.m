classdef (Sealed) Command
    %COMMAND Declare one role-specific immutable App command.
    %
    % Usage:
    %   command = labkit.ui.Command(id, callback)
    %   command = labkit.ui.Command(id, callback, Role=role)
    %
    % Description:
    %   Command binds one stable identifier to one callback role. Construction
    %   validates the callback's fixed input and output counts before an
    %   Application is compiled. Variable-arity callbacks are rejected; the
    %   runtime never probes or retries callback shapes.
    %
    % Inputs:
    %   id - Nonempty MATLAB identifier used by Layout signal bindings.
    %   callback - Scalar function handle with the signature required by Role.
    %
    % Name-Value Arguments:
    %   Role - One of "invoke", "value", "tableEdit", "selection", or
    %       "interaction". "invoke" callbacks accept (state,context); every
    %       other role accepts (state,payload,context). All roles return one
    %       updated state value. Default: "invoke".
    %
    % Outputs:
    %   command - Immutable labkit.ui.Command value.
    %
    % Errors:
    %   labkit:ui:contract:UnknownArgument - A Name-Value argument is unknown,
    %       duplicated, or unpaired.
    %   labkit:ui:contract:InvalidValue - id, callback, or Role is invalid.
    %   labkit:ui:contract:CallbackRoleMismatch - callback does not have the
    %       fixed input/output count required by Role.
    %
    % Typical Call:
    %   command = labkit.ui.Command("run", @runAnalysis);
    %
    % See also labkit.ui.Application, labkit.ui.Layout

    properties (SetAccess = immutable)
        Id (1, 1) string
        Role (1, 1) string
        PayloadClass (1, 1) string
        Callback
    end

    methods
        function obj = Command(id, callback, varargin)
            options = parseContractOptions( ...
                "labkit.ui.Command", "Role", varargin{:});
            role = "invoke";
            if isfield(options, "Role")
                role = options.Role;
            end
            id = normalizeId(id);
            role = normalizeRole(role);
            if ~isa(callback, "function_handle") || ~isscalar(callback)
                error("labkit:ui:contract:InvalidValue", ...
                    "Command callback must be a scalar function handle.");
            end
            expectedInputs = 2 + (role ~= "invoke");
            if nargin(callback) ~= expectedInputs || nargout(callback) ~= 1
                error("labkit:ui:contract:CallbackRoleMismatch", ...
                    "Command %s role %s requires %d inputs and one output.", ...
                    id, role, expectedInputs);
            end
            obj.Id = id;
            obj.Role = role;
            obj.PayloadClass = payloadClass(role);
            obj.Callback = callback;
        end
    end
end

function value = payloadClass(role)
    value = "";
    if role == "tableEdit"
        value = "labkit.ui.TableEdit";
    elseif role == "selection"
        value = "labkit.ui.Selection";
    end
end

function value = normalizeId(value)
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        error("labkit:ui:contract:InvalidValue", ...
            "Command id must be a text scalar.");
    end
    value = string(value);
    if strlength(value) == 0 || ~isvarname(char(value))
        error("labkit:ui:contract:InvalidValue", ...
            "Command id must be a nonempty MATLAB identifier.");
    end
end

function value = normalizeRole(value)
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        error("labkit:ui:contract:InvalidValue", ...
            "Command Role must be a text scalar.");
    end
    value = string(value);
    allowed = ["invoke", "value", "tableEdit", "selection", "interaction"];
    if ~any(value == allowed)
        error("labkit:ui:contract:InvalidValue", ...
            "Unsupported Command Role: %s.", value);
    end
end

function state = runAnalysis(state, ~)
    state.finished = true;
end
