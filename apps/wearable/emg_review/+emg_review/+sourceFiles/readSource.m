function session = readSource(paths)
    session = struct('recording', [], 'channels', "(none)", ...
        'sourceStatus', "Open an EMG recording.");
    if ~isempty(paths)
        [recording, status] = labkit.biosignal.readRecording(paths(1));
        if status.ok && ~isempty(recording.signals)
            session.recording = recording;
            session.channels = string(labkit.biosignal.listChannels(recording));
            session.sourceStatus = "Format " + status.format;
        elseif status.ok
            session.sourceStatus = "The recording has no numeric channels.";
        else
            session.sourceStatus = status.message;
        end
    end
    session = emg_review.sourceFiles.selectChannel(session, session.channels(1));
end
