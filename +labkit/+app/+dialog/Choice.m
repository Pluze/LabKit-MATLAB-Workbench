classdef (Sealed) Choice
    %DIALOGRESULT Represent a typed dialog choice or cancellation.
    %
    % Usage:
    %   result = labkit.app.dialog.Choice(value)
    %   result = labkit.app.dialog.Choice(value, Cancelled=cancelled)
    %
    % Description:
    %   Choice separates cancellation from the chosen value so an empty
    %   string, zero, false, or empty App value is not interpreted as cancel.
    %
    % Inputs:
    %   value - App-facing value returned by the dialog.
    %
    % Name-Value Arguments:
    %   Cancelled - Logical scalar. Default: false.
    %
    % Outputs:
    %   result - Immutable labkit.app.dialog.Choice value.
    %
    % Errors:
    %   labkit:app:contract:UnknownArgument - An option is unknown, duplicated,
    %       or unpaired.
    %   labkit:app:contract:InvalidValue - Cancelled is not logical scalar.
    %
    % Example:
    %   result = labkit.app.dialog.Choice("", Cancelled=false);
    %   assert(~result.Cancelled)
    %
    % See also labkit.app.CallbackContext

    properties (SetAccess = immutable)
        Value
        Cancelled (1, 1) logical
    end

    methods
        function obj = Choice(value, varargin)
            options = labkit.app.internal.OptionParser.parse( ...
                "labkit.app.dialog.Choice", "Cancelled", varargin{:});
            cancelled = false;
            if isfield(options, "Cancelled")
                cancelled = options.Cancelled;
            end
            if ~(islogical(cancelled) && isscalar(cancelled))
                error("labkit:app:contract:InvalidValue", ...
                    "Choice Cancelled must be a logical scalar.");
            end
            obj.Value = value;
            obj.Cancelled = cancelled;
        end
    end
end
