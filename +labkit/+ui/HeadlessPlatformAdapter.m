classdef (Hidden, Sealed) HeadlessPlatformAdapter < handle
    % Private deterministic adapter used before concrete MATLAB UI creation.
    properties (SetAccess = private)
        CommitCount (1, 1) double = 0
    end

    properties (Access = private)
        FailNext (1, 1) logical = false
    end

    methods (Access = ?labkit.ui.RuntimeKernel)
        function reconcile(obj, ~, ~)
            if obj.FailNext
                obj.FailNext = false;
                error("labkit:ui:runtime:InvariantFailure", ...
                    "Injected platform commit failure.");
            end
            obj.CommitCount = obj.CommitCount + 1;
        end

        function failNextCommit(obj)
            obj.FailNext = true;
        end

        function close(~)
        end
    end
end
