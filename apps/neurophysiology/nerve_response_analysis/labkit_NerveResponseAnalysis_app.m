function varargout = labkit_NerveResponseAnalysis_app(varargin)
%LABKIT_NERVERESPONSEANALYSIS_APP Launch the Nerve Response Analysis app.

    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @nerve_response_analysis.definition, varargin{:});
end
