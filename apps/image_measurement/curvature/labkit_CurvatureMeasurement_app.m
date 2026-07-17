function varargout = labkit_CurvatureMeasurement_app(varargin)
%LABKIT_CURVATUREMEASUREMENT_APP Measure curve radius and curvature from images.

    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @curvature.definition, varargin{:});
end
