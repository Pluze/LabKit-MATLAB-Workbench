function varargout = labkit_ECGPrint_app(varargin)
%LABKIT_ECGPRINT_APP Explore ECG quality, SNR, and printable waveforms.

    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @ecg_print.definition, varargin{:});
end
