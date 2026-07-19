classdef (Sealed) DialogResult
    %DIALOGRESULT Represent a typed dialog choice or cancellation.
    %
    % Usage:
    %   result = labkit.ui.DialogResult(value)
    %   result = labkit.ui.DialogResult(value, Cancelled=cancelled)
    %
    % Description:
    %   DialogResult separates cancellation from the chosen value so an empty
    %   string, zero, false, or empty App value is not interpreted as cancel.
    %
    % Inputs:
    %   value - App-facing value returned by the dialog.
    %
    % Name-Value Arguments:
    %   Cancelled - Logical scalar. Default: false.
    %
    % Outputs:
    %   result - Immutable labkit.ui.DialogResult value.
    %
    % Errors:
    %   labkit:ui:contract:UnknownArgument - An option is unknown, duplicated,
    %       or unpaired.
    %   labkit:ui:contract:InvalidValue - Cancelled is not logical scalar.
    %
    % Example:
    %   result = labkit.ui.DialogResult("", Cancelled=false);
    %   assert(~result.Cancelled)
    %
    % See also labkit.ui.RuntimeContext

    properties (SetAccess = immutable)
        Value
        Cancelled (1, 1) logical
    end

    methods
        function obj = DialogResult(value, varargin)
            options = parseContractOptions( ...
                "labkit.ui.DialogResult", "Cancelled", varargin{:});
            cancelled = false;
            if isfield(options, "Cancelled")
                cancelled = options.Cancelled;
            end
            if ~(islogical(cancelled) && isscalar(cancelled))
                error("labkit:ui:contract:InvalidValue", ...
                    "DialogResult Cancelled must be a logical scalar.");
            end
            obj.Value = value;
            obj.Cancelled = cancelled;
        end
    end
end
