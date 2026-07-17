function varargout = labkit_GaitAnalysis_app(varargin)
%LABKIT_GAITANALYSIS_APP Analyze gait from a current Video Marker MAT project.

    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @gait_analysis.definition, varargin{:});
end
