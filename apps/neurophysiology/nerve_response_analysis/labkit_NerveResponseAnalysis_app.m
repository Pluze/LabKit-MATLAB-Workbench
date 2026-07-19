function varargout = labkit_NerveResponseAnalysis_app(varargin)
%LABKIT_NERVERESPONSEANALYSIS_APP Launch the Nerve Response Analysis app.

    [varargout{1:nargout}] = nerve_response_analysis.definition().launch(varargin{:});
end
