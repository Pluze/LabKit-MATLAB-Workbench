classdef (Hidden, Sealed) HeadlessPlatformAdapter < handle
    % Private deterministic adapter used before concrete MATLAB UI creation.
    methods (Access = ?labkit.app.internal.runtime.RuntimeKernel)
        function reconcile(~, ~, ~)
        end

        function close(~)
        end
    end
end
