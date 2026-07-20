function varargout = labkit_ECGPrint_app(varargin)
%LABKIT_ECGPRINT_APP Explore ECG quality, SNR, and printable waveforms.

    [varargout{1:nargout}] = ecg_print.definition().launch(varargin{:});
end
