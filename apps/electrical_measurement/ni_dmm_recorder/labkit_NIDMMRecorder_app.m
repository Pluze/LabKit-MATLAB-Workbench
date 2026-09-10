function varargout = labkit_NIDMMRecorder_app(varargin)
%LABKIT_NIDMMRECORDER_APP Launch or inspect the NI DMM Recorder App.
app = ni_dmm_recorder.definition();
[varargout{1:nargout}] = app.launch(varargin{:});
end
