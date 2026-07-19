classdef (Sealed, Hidden) SignalBinding
    %SIGNALBINDING Private compiled link from one layout signal to a callback.
    %
    % Expected callers: LayoutNode constructors and RuntimeKernel. The value
    % derives its stable diagnostic id from the owning target and signal,
    % validates the one callback signature owned by that signal, and carries
    % no App-authored registration name. Side effects are none.

    properties (SetAccess = immutable)
        Id (1, 1) string
        Signal (1, 1) string
        AcceptsPayload (1, 1) logical
        PayloadClass (1, 1) string
        UpdateState
    end

    methods
        function obj = SignalBinding(target, signal, updateState)
            target = scalarId(target, "target");
            signal = scalarId(signal, "signal");
            [inputCount, payloadClass] = signalContract(signal);
            if ~isa(updateState, "function_handle") || ...
                    ~isscalar(updateState)
                error("labkit:app:contract:InvalidValue", ...
                    "Layout %s callback must be a function handle.", signal);
            end
            if nargin(updateState) ~= inputCount || ...
                    nargout(updateState) ~= 1
                error("labkit:app:contract:CallbackRoleMismatch", ...
                    "Layout %s callback requires %d inputs and one output.", ...
                    signal, inputCount);
            end
            obj.Id = target + "__" + signal;
            obj.Signal = signal;
            obj.AcceptsPayload = inputCount == 3;
            obj.PayloadClass = payloadClass;
            obj.UpdateState = updateState;
        end
    end
end

function [inputCount, payloadClass] = signalContract(signal)
payloadClass = "";
switch signal
    case {"pressed", "started"}
        inputCount = 2;
    case {"valueChanged", "pageChanged", "interactionChanged"}
        inputCount = 3;
    case "cellEdited"
        inputCount = 3;
        payloadClass = "labkit.app.event.TableCellEdit";
    case "cellSelectionChanged"
        inputCount = 3;
        payloadClass = "labkit.app.event.TableCellSelection";
    otherwise
        error("labkit:app:runtime:InvariantFailure", ...
            "Internal layout signal is unsupported: %s.", signal);
end
end

function value = scalarId(value, label)
if ~(ischar(value) || (isstring(value) && isscalar(value)))
    error("labkit:app:contract:InvalidValue", ...
        "Layout signal %s must be scalar text.", label);
end
value = string(value);
if strlength(value) == 0 || ~isvarname(char(value))
    error("labkit:app:contract:InvalidValue", ...
        "Layout signal %s must be a MATLAB identifier.", label);
end
end
