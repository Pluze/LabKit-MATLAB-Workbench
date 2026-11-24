function varargout = labkit_EMGReview_app(varargin)
%LABKIT_EMGREVIEW_APP Mark EMG windows and inspect SNR and frequency content.
    [varargout{1:nargout}] = emg_review.definition().launch(varargin{:});
end
