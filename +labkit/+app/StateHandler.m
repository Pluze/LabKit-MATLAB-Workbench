classdef (Sealed) StateHandler
    %STATEHANDLER Declare one typed App-state transition.
    %
    % Usage:
    %   handler = labkit.app.StateHandler(id, updateState)
    %   handler = labkit.app.StateHandler(id, updateState, Event=event)
    %
    % Description:
    %   StateHandler binds one stable identifier to one event-specific state
    %   transition. Construction validates the fixed callback shape before a
    %   Definition is compiled. The runtime never probes or retries callback
    %   signatures.
    %
    % Inputs:
    %   id - Nonempty MATLAB identifier used by WorkbenchLayout events.
    %   updateState - Scalar function handle with the signature required by
    %       Event.
    %
    % Name-Value Arguments:
    %   Event - One of "action", "valueChange", "tableCellEdit",
    %       "listSelection", "tableCellSelection", or "interaction".
    %       "action" handlers accept (state,context); every other event accepts
    %       (state,payload,context). Every handler returns updated state.
    %       Default: "action".
    %
    % Outputs:
    %   handler - Immutable StateHandler value.
    %
    % Errors:
    %   labkit:app:contract:UnknownArgument - A Name-Value argument is unknown,
    %       duplicated, or unpaired.
    %   labkit:app:contract:InvalidValue - id, updateState, or Event is invalid.
    %   labkit:app:contract:CallbackRoleMismatch - updateState does not have
    %       the fixed input/output count required by Event.
    %
    % Typical Call:
    %   handler = labkit.app.StateHandler("run", @runAnalysis);
    %
    % See also labkit.app.Definition, labkit.app.layout.button

    properties (SetAccess = immutable)
        Id (1, 1) string
        Event (1, 1) string
        PayloadClass (1, 1) string
        UpdateState
    end

    methods
        function obj = StateHandler(id, updateState, varargin)
            options = labkit.app.internal.OptionParser.parse( ...
                "labkit.app.StateHandler", "Event", varargin{:});
            event = "action";
            if isfield(options, "Event")
                event = options.Event;
            end
            id = normalizeId(id);
            event = normalizeEvent(event);
            if ~isa(updateState, "function_handle") || ~isscalar(updateState)
                error("labkit:app:contract:InvalidValue", ...
                    "StateHandler updateState must be a function handle.");
            end
            expectedInputs = 2 + (event ~= "action");
            if nargin(updateState) ~= expectedInputs || ...
                    nargout(updateState) ~= 1
                error("labkit:app:contract:CallbackRoleMismatch", ...
                    "StateHandler %s event %s requires %d inputs and " + ...
                    "one output.", id, event, expectedInputs);
            end
            obj.Id = id;
            obj.Event = event;
            obj.PayloadClass = payloadClass(event);
            obj.UpdateState = updateState;
        end
    end
end

function value = payloadClass(event)
    value = "";
    if event == "tableCellEdit"
        value = "labkit.app.event.TableCellEdit";
    elseif event == "listSelection"
        value = "labkit.app.event.ListSelection";
    elseif event == "tableCellSelection"
        value = "labkit.app.event.TableCellSelection";
    end
end

function value = normalizeId(value)
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        error("labkit:app:contract:InvalidValue", ...
            "StateHandler id must be a text scalar.");
    end
    value = string(value);
    if strlength(value) == 0 || ~isvarname(char(value))
        error("labkit:app:contract:InvalidValue", ...
            "StateHandler id must be a nonempty MATLAB identifier.");
    end
end

function value = normalizeEvent(value)
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        error("labkit:app:contract:InvalidValue", ...
            "StateHandler Event must be a text scalar.");
    end
    value = string(value);
    allowed = ["action", "valueChange", "tableCellEdit", ...
        "listSelection", "tableCellSelection", "interaction"];
    if ~any(value == allowed)
        error("labkit:app:contract:InvalidValue", ...
            "Unsupported StateHandler Event: %s.", value);
    end
end

function state = runAnalysis(state, ~)
    state.finished = true;
end
