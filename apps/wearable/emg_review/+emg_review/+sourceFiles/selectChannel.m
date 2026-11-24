function session = selectChannel(session, channel)
    session.channel = channel;
    session.signal = [];
    choices = emg_review.analysisRun.bands();
    session.band = choices(1);
    % The reference ROI uses one-second baseline and activity windows.
    session.windowSeconds = 1;
    session.pairs = [0 1];
    session.pairIndex = 1;
    session.result = [];
    session.analysisStatus = "Mark windows and select Analyze EMG.";
    session.preview = struct('time', [], 'values', []);
    if isempty(session.recording)
        return;
    end
    signal = labkit.biosignal.getChannel(session.recording, channel);
    session.signal = signal;
    session.preview = emg_review.sourceFiles.waveformPreview(signal.time, signal.values);
end
