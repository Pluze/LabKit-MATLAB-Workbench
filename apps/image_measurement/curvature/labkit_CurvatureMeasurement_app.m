function varargout = labkit_CurvatureMeasurement_app(varargin)
%LABKIT_CURVATUREMEASUREMENT_APP Measure curve radius and curvature from images.

    [varargout{1:nargout}] = curvature.definition().launch(varargin{:});
end
