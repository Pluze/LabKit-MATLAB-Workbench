% Expected caller: ecg_print.userInterface.updateWorkbenchFromState and direct unit tests. Inputs are the
% current signal, events, segments, and measurement structs. Output is a
% two-column cell array for the summary table. Side effects: none.

function rows = summaryRows(signal, events, segments, measurements)
%SUMMARYROWS Build ECG Print summary table rows from app state fields.

    rows = ecg_print.userInterface.initialSummaryRows();
    if ~isempty(signal)
        rows = [rows; {
            'Channel', char(signal.displayName);
            'Samples', sprintf('%d', numel(signal.values));
            'Estimated Fs (Hz)', sprintf('%.3g', signal.fs);
            'Duration (s)', sprintf('%.3g', max(signal.time) - min(signal.time))}];
    end
    if ~isempty(events)
        methodLabel = '';
        if isfield(events, 'metadata') && isfield(events.metadata, 'method')
            methodLabel = sprintf(' (%s)', char(events.metadata.method));
        end
        rows = [rows; {'Detected peaks', sprintf('%d%s', numel(events.index), methodLabel)}];
    end
    if ~isempty(segments)
        rows = [rows; {'Valid segments', sprintf('%d', size(segments.values, 2))}];
    end
    if ~isempty(measurements) && ~isempty(measurements.summary)
        M = measurements.summary;
        rows = [rows; {
            'Mean SNR (dB)', sprintf('%.3g', M.SNRdBMean);
            'SNR std (dB)', sprintf('%.3g', M.SNRdBStd);
            'Mean template corr.', sprintf('%.3g', M.TemplateCorrelationMean)}];
    end
end
