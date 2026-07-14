%CONTROLLER Coordinate Video Marker autosave writes and recovery choices.
% Expected caller: definitionActions startup. Dependencies are the app figure,
% debug context, and app-log callback. Returned operations never own video IO.
function service = controller(fig, debugLog, appendLog)
    errorActive = false;
    service = struct('save', @saveState, 'offer', @offerRecovery, ...
        'discard', @video_marker.autosave.discard);

    function saveState(state, reason)
        if state.videoInfo.frameCount <= 0 || strlength(state.videoPath) == 0
            return;
        end
        try
            pathValue = video_marker.autosave.write(state.videoPath, state);
            if errorActive
                appendLog('Autosave recovered after an earlier write failure.');
            end
            errorActive = false;
            debugLog.trace('autosave', sprintf('%s | %s', ...
                char(string(reason)), char(pathValue)), 'saved');
        catch ME
            debugLog.reportException('videoMarker', 'Autosave failed', ME);
            if ~errorActive
                appendLog(sprintf('Autosave failed: %s', ME.message));
            end
            errorActive = true;
        end
    end

    function [saved, decision] = offerRecovery(videoPath)
        saved = struct();
        decision = "none";
        try
            [saved, found] = video_marker.autosave.read(videoPath);
        catch ME
            debugLog.reportException('videoMarker', 'Could not read autosave', ME);
            appendLog(sprintf('Ignored unreadable autosave: %s', ME.message));
            return;
        end
        if ~found
            return;
        end
        summary = video_marker.frameAnnotations.summary(saved.annotations);
        message = sprintf(['Recovery data exists for this video at frame %d ' ...
            '(%d confirmed, %d draft). Restore it?'], ...
            saved.currentFrame, summary.confirmed, summary.draft);
        if labkit.ui.runtime.confirm(fig, message, 'Restore Video Marker progress', ...
                'ConfirmText', 'Restore', 'CancelText', 'Start new')
            decision = "restore";
        else
            video_marker.autosave.discard(videoPath);
            appendLog('Discarded prior autosave and started a new annotation session.');
            decision = "new";
        end
    end
end
