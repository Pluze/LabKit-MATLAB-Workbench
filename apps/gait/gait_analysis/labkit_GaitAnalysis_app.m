function varargout = labkit_GaitAnalysis_app(varargin)
%LABKIT_GAITANALYSIS_APP Analyze gait metrics from tracked pose coordinates.

    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @gait_analysis.definition, @gait_analysis.requirements, ...
        @gait_analysis.version, varargin{:});
end
