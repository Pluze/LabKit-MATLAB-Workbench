function varargout = curvatureMeasurementWorkflow(command, varargin)
%CURVATUREMEASUREMENTWORKFLOW Dispatch app-owned curvature helpers.
% Expected caller: curvature app tests and migration-time workflow checks.
% Inputs are a workflow command plus command-specific arguments. Outputs match
% the selected app-private helper. This helper has no file side effects.

    switch string(command)
        case "computeCurvatureFit"
            opts = varargin{3};
            calibration = scaleOptionsFromStruct(opts);
            doDensify = optionValue(opts, 'doDensify', true);
            denseN = optionValue(opts, 'denseN', 300);
            fitPathX = optionValue(opts, 'fitPathX', []);
            fitPathY = optionValue(opts, 'fitPathY', []);
            varargout{1} = computeCurvatureFit(varargin{1}, varargin{2}, ...
                calibration, doDensify, denseN, fitPathX, fitPathY);
        case "computeCurveLength"
            opts = varargin{3};
            calibration = scaleOptionsFromStruct(opts);
            varargout{1} = computeCurveLength(varargin{1}, varargin{2}, calibration);
        case "buildCurvatureResultTable"
            if numel(varargin) >= 3
                lengthResult = varargin{3};
            else
                lengthResult = lengthResultFromFit(varargin{1});
            end
            varargout{1} = buildCurvatureResultTable(varargin{1}, ...
                string(varargin{2}), lengthResult);
        otherwise
            error('labkit:CurvatureMeasurement:UnknownWorkflowCommand', ...
                'Unknown curvature workflow helper command: %s.', command);
    end
end
