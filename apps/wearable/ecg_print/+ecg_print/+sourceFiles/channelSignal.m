function signal = channelSignal(recording,channel,parameters)
%CHANNELSIGNAL Decode a channel and apply an explicitly selected sample clock.
%   signal = ecg_print.sourceFiles.channelSignal(recording,channel,parameters)
%   uses labkit.biosignal.getChannel. When parameters.timeUnit is "samples",
%   numeric reader time represents sample indices: divide it by the positive
%   parameters.fallbackFs and multiply the inferred index rate by that value.
%   Other time units are already seconds. Amplitude values are unchanged.
%   Invalid sample-clock rate raises ecg_print:InvalidSampleRate. No IO or GUI.
signal = labkit.biosignal.getChannel(recording,channel);
if string(parameters.timeUnit)=="samples"
    fs=parameters.fallbackFs;
    if ~isnumeric(fs)||~isscalar(fs)||~isfinite(fs)||fs<=0
        error('ecg_print:InvalidSampleRate','Set the acquisition sample rate in Hz.');
    end
    signal.time=signal.time/fs;
    signal.fs=signal.fs*fs;
    signal.metadata.sampleClockHz=fs;
end
signal.time=signal.time-signal.time(1);
end
