function varargout = labkit_ECGPrint_app(varargin)
%LABKIT_ECGPRINT_APP Explore ECGNExT noise, NST-centered per-beat SNR, and waveforms.

    [varargout{1:nargout}] = ecg_print.definition().launch(varargin{:});
end
