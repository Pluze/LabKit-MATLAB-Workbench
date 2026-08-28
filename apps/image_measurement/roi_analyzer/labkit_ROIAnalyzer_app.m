function varargout = labkit_ROIAnalyzer_app(varargin)
%LABKIT_ROIANALYZER_APP Measure and compare pixel values inside image ROIs.

    [varargout{1:nargout}] = roi_analyzer.definition().launch(varargin{:});
end
