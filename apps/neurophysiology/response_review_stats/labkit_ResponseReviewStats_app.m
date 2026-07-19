function varargout = labkit_ResponseReviewStats_app(varargin)
%LABKIT_RESPONSEREVIEWSTATS_APP Launch the Response Review Stats app.

    [varargout{1:nargout}] = response_review_stats.definition().launch(varargin{:});
end
