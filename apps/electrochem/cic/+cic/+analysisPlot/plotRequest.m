% Expected caller: CIC app runner and unit tests. Inputs are a CIC analysis
% result, item display name, and plot control selections. Output is prepared
% plot data, labels, styling, and pulse coordinate metadata; no axes side effects.

function request = plotRequest(A, itemName, xChoice, yChoice)
%PLOTREQUEST Prepare deterministic CIC plot payload for runner drawing.
% Constant: MATLAB default blue and orange preserve legacy series styling.
defaultBlue = [0 0.4470 0.7410];
defaultOrange = [0.8500 0.3250 0.0980];

    choices = cic.analysisRun.analysisChoices();
    if nargin < 2 || isempty(itemName)
        itemName = 'file';
    end
    if nargin < 3 || isempty(xChoice)
        xChoice = char(choices.xAxes(1));
    end
    if nargin < 4 || isempty(yChoice)
        yChoice = char(choices.yAxes(1));
    end

    request = struct();
    request.xChoice = xChoice;
    request.yChoice = yChoice;

    [request.x, request.xLabel, request.coords] = xPayload(A, xChoice);

    if startsWith(yChoice, 'VT')
        request.kind = 'VT';
        request.y = A.Vf;
        request.yLabel = 'Vf (V vs Ref.)';
        request.baseColor = defaultBlue;
        request.title = sprintf('%s | VT | %s', itemName, safeText(A));
    else
        request.kind = 'IT';
        request.y = A.Im;
        request.yLabel = 'Im (A)';
        request.baseColor = defaultOrange;
        request.title = sprintf('%s | IT | |I|max = %.4g A', itemName, A.ampEstimate_A);
    end
end

function [x, xLabel, coords] = xPayload(A, xChoice)
    choices = cic.analysisRun.analysisChoices();
    if strcmp(xChoice, choices.xAxes(2))
        x = A.pt;
        xLabel = char(choices.xAxes(2));
        coords = struct( ...
            'cathStartX', interp1Safe(A.t, A.pt, A.pulse.cath_start), ...
            'cathEndX', interp1Safe(A.t, A.pt, A.pulse.cath_end), ...
            'anodStartX', interp1Safe(A.t, A.pt, A.pulse.anod_start), ...
            'anodEndX', interp1Safe(A.t, A.pt, A.pulse.anod_end), ...
            'emcX', interp1Safe(A.t, A.pt, A.t_emc), ...
            'emaX', interp1Safe(A.t, A.pt, A.t_ema));
    else
        x = A.t;
        xLabel = char(choices.xAxes(1));
        coords = struct( ...
            'cathStartX', A.pulse.cath_start, ...
            'cathEndX', A.pulse.cath_end, ...
            'anodStartX', A.pulse.anod_start, ...
            'anodEndX', A.pulse.anod_end, ...
            'emcX', A.t_emc, ...
            'emaX', A.t_ema);
    end
end

function text = safeText(A)
    if A.safe
        text = 'SAFE';
    else
        text = 'UNSAFE';
    end
end

function v = interp1Safe(x, y, xq)
    if numel(x) < 2 || any(~isfinite([x(:); y(:)]))
        v = NaN;
        return;
    end

    try
        v = interp1(x, y, xq, 'linear', 'extrap');
    catch
        idx = nearestIndex(x, xq);
        v = y(idx);
    end
end

function idx = nearestIndex(x, xq)
    [~, idx] = min(abs(x - xq));
end
