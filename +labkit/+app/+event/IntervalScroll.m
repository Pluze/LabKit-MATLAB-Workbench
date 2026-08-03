classdef (Sealed) IntervalScroll
    %INTERVALSCROLL Describe one normalized interval scroll gesture.
    %
    % Usage:
    %   event = labkit.app.event.IntervalScroll(Anchor=anchor, Count=count)
    %
    % Description:
    %   IntervalScroll replaces native MATLAB scroll events and untyped
    %   structs with the horizontal data coordinate under the pointer and the
    %   signed vertical scroll count used by interval interactions.
    %
    % Required Name-Value Arguments:
    %   Anchor - Finite scalar horizontal data coordinate.
    %   Count - Finite nonzero scalar vertical scroll count.
    %
    % Outputs:
    %   event - Immutable labkit.app.event.IntervalScroll value.
    %
    % Errors:
    %   labkit:app:contract:UnknownArgument - An argument is missing, unknown,
    %       duplicated, or unpaired.
    %   labkit:app:contract:InvalidValue - Anchor or Count is malformed.
    %
    % Example:
    %   event = labkit.app.event.IntervalScroll(Anchor=0.25, Count=-1);
    %   assert(event.Anchor == 0.25)
    %
    % See also labkit.app.interaction.interval

    properties (SetAccess = immutable)
        Anchor (1, 1) double
        Count (1, 1) double
    end

    methods
        function obj = IntervalScroll(varargin)
            options = labkit.app.internal.contract.OptionParser.parse( ...
                "labkit.app.event.IntervalScroll", ...
                ["Anchor", "Count"], varargin{:});
            for name = ["Anchor", "Count"]
                if ~isfield(options, name)
                    error("labkit:app:contract:UnknownArgument", ...
                        "labkit.app.event.IntervalScroll requires argument %s.", ...
                        name);
                end
            end
            obj.Anchor = finiteScalar(options.Anchor, "Anchor");
            obj.Count = finiteScalar(options.Count, "Count");
            if obj.Count == 0
                error("labkit:app:contract:InvalidValue", ...
                    "IntervalScroll Count must be nonzero.");
            end
        end
    end
end

function value = finiteScalar(value, name)
if ~(isnumeric(value) && isscalar(value) && isfinite(value))
    error("labkit:app:contract:InvalidValue", ...
        "IntervalScroll %s must be a finite numeric scalar.", name);
end
value = double(value);
end
