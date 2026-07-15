% Expected caller: CIC app runner and unit tests. Inputs are current app items,
% selected item index, CIC summary mode, and display unit. Output is the stable
% Current File Summary text model; no UI handle or file side effects.

function summary = buildCurrentSummary(items, currentIndex, modeLabel, unitLabel)
%BUILDCURRENTSUMMARY Build CIC current-file summary text.

    choices = cic.userInterface.analysisChoices();
    if nargin < 2
        currentIndex = [];
    end
    if nargin < 3 || isempty(modeLabel)
        modeLabel = char(choices.cicModes(3));
    end
    if nargin < 4
        unitLabel = 'mC/cm^2';
    end

    summary = emptySummary();
    summary.bestSafe = bestSafeString(items, modeLabel, unitLabel);

    if isempty(items) || isempty(currentIndex) ...
            || currentIndex < 1 || currentIndex > numel(items)
        return;
    end

    item = items(currentIndex);
    summary.controlMode = chronoControlModeText(item);
    A = itemAnalysis(item);
    if isempty(A) || ~isfield(A, 'ok') || ~A.ok
        if ~isempty(A) && isfield(A, 'message')
            summary.safe = A.message;
        else
            summary.safe = 'No valid analysis';
        end
        return;
    end

    summary.detect = sprintf('%s | %s', A.detectMode, A.detectMsg);
    % Constant: one million converts seconds to microseconds for display.
    microsecondsPerSecond = 1e6;
    summary.delay = sprintf('%.3f us', microsecondsPerSecond * A.delay_s);
    summary.area = formatMaybeNumText(A.area_cm2, '%.8g cm^2');
    summary.emc = sprintf('%.6f V @ %.6fus', A.Emc, ...
        microsecondsPerSecond * A.t_emc);
    summary.ema = sprintf('%.6f V @ %.6fus', A.Ema, ...
        microsecondsPerSecond * A.t_ema);
    summary.qc = formatChargeDensityText(A.Qc_C, A.CICc_mCcm2, unitLabel);
    summary.qa = formatChargeDensityText(A.Qa_C, A.CICa_mCcm2, unitLabel);
    summary.qt = formatChargeDensityText(A.Qt_C, A.CICt_mCcm2, unitLabel);
    if A.safe
        safeText = 'SAFE';
    else
        safeText = 'UNSAFE';
    end
    summary.safe = sprintf('%s | Emc>=%.3f? %d | Ema<=%.3f? %d', ...
        safeText, A.cathLimit, A.cathOK, A.anodLimit, A.anodOK);
end

function summary = emptySummary()
    summary = struct( ...
        'controlMode', '-', ...
        'detect', '-', ...
        'delay', '-', ...
        'area', '-', ...
        'emc', '-', ...
        'ema', '-', ...
        'qc', '-', ...
        'qa', '-', ...
        'qt', '-', ...
        'safe', '-', ...
        'bestSafe', '-');
end

function out = chronoControlModeText(item)
    out = 'Unknown chrono control mode';
    if ~isfield(item, 'controlMode')
        return;
    end

    switch string(item.controlMode)
        case "current"
            out = 'Current-controlled chrono';
        case "voltage"
            out = 'Voltage-controlled chrono';
        otherwise
            out = 'Unknown chrono control mode';
    end
end

function out = bestSafeString(items, modeLabel, unitLabel)
    if isempty(items)
        out = '-';
        return;
    end
    safeIdx = [];
    vals = [];
    for i = 1:numel(items)
        A = itemAnalysis(items(i));
        if ~isempty(A) && isfield(A, 'ok') && A.ok && isfield(A, 'safe') && A.safe
            safeIdx(end+1) = i;
            vals(end+1) = selectedCICValue(A, modeLabel);
        end
    end
    if isempty(safeIdx)
        out = 'No safe file in current batch';
        return;
    end
    [~, imax] = max(vals);
    ii = safeIdx(imax);
    [scale, unitLabel] = displayScale(unitLabel);
    out = sprintf('%s | %s = %.6g %s', itemName(items(ii)), ...
        shortModeName(modeLabel), scale * vals(imax), unitLabel);
end

function v = selectedCICValue(A, modeLabel)
    choices = cic.userInterface.analysisChoices();
    switch modeLabel
        case char(choices.cicModes(1))
            v = A.CICc_mCcm2;
        case char(choices.cicModes(2))
            v = A.CICa_mCcm2;
        otherwise
            v = A.CICt_mCcm2;
    end
end

function s = shortModeName(modeLabel)
    choices = cic.userInterface.analysisChoices();
    switch modeLabel
        case char(choices.cicModes(1))
            s = 'CICc';
        case char(choices.cicModes(2))
            s = 'CICa';
        otherwise
            s = 'CICtotal';
    end
end

function A = itemAnalysis(item)
    if isfield(item, 'analysis')
        A = item.analysis;
    else
        A = [];
    end
end

function name = itemName(item)
    if isfield(item, 'name')
        name = item.name;
    else
        name = '';
    end
end

function s = formatMaybeNumText(v, fmt)
    if isfinite(v)
        s = sprintf(fmt, v);
    else
        s = 'NaN';
    end
end

function out = formatChargeDensityText(Q_C, cic_mCcm2, unitLabel)
    if isfinite(cic_mCcm2)
        [scale, unitLabel] = displayScale(unitLabel);
        out = sprintf('%.6e C | %.6f %s', Q_C, scale * cic_mCcm2, unitLabel);
    else
        out = sprintf('%.6e C | area unavailable', Q_C);
    end
end

function [scale, unitLabel] = displayScale(unitLabel)
    [scale, unitLabel] = cic.userInterface.displayUnit(unitLabel);
end
