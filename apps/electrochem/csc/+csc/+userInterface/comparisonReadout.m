% Expected caller: CSC app runner and unit tests. Inputs are a
% csc.analysisRun.computeCSC result struct and selected comparison mode. Output is a
% display/log text struct only; no file or UI side effects.

function readout = comparisonReadout(result, mode)
%COMPARISONREADOUT Prepare CSC comparison display and log text.

    if nargin < 2
        mode = '';
    end

    readout = struct( ...
        'ok', false, ...
        'qctText', '', ...
        'qcvText', '', ...
        'diffText', '', ...
        'relText', '', ...
        'dtErrText', '', ...
        'statusText', '', ...
        'logMessage', '');

    if ~isfield(result, 'ok') || ~result.ok
        message = '';
        if isfield(result, 'message')
            message = result.message;
        end

        readout.qctText = message;
        readout.qcvText = message;
        readout.diffText = '-';
        readout.relText = '-';
        readout.dtErrText = '-';
        if isfield(result, 'logMessage') && ~isempty(result.logMessage)
            readout.logMessage = result.logMessage;
        end
        return;
    end

    readout.ok = true;
    readout.qctText = csc.userInterface.formatChargeAndCSC(result.Qct, result.area_cm2);
    readout.qcvText = csc.userInterface.formatChargeAndCSC(result.Qcv, result.area_cm2);
    readout.diffText = csc.userInterface.formatChargeAndCSC(result.diff_C, result.area_cm2);
    readout.relText = sprintf('%.6f %%', result.rel_pct);
    readout.dtErrText = sprintf('%.6e s', result.dtErr);
    readout.logMessage = sprintf(['Compare [%s]: Qct=%.6e C, Qcv=%.6e C, ', ...
        'rel=%.6f %%, maxdt=%.3e s'], ...
        mode, result.Qct, result.Qcv, result.rel_pct, result.dtErr);

    if isnan(result.area_cm2)
        readout.statusText = 'Charge shown (area not set)';
    else
        readout.statusText = sprintf('CSC normalized by %.6g cm^2', ...
            result.area_cm2);
    end
end
