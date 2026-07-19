function varargout = labkit_GaitAnalysis_app(varargin)
%LABKIT_GAITANALYSIS_APP Analyze gait from a current Video Marker MAT project.

    [varargout{1:nargout}] = gait_analysis.definition().launch(varargin{:});
end
