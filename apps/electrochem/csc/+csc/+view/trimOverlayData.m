% Expected caller: CSC app runner and unit tests. Inputs are the trim enabled
% state, selected Y-axis name, selected X-axis values, and csc.ops.computeCSC
% result struct. Output is prepared overlay data only; no file or UI side
% effects.

function overlay = trimOverlayData(enabled, ySelection, xValues, result)
%TRIMOVERLAYDATA Prepare CSC trim overlay vectors for runner plotting.

    overlay = struct( ...
        'ok', false, ...
        'x', [], ...
        'cathY', [], ...
        'anodY', []);

    if ~enabled || ~strcmp(ySelection, 'Im')
        return;
    end

    if ~isfield(result, 'IcathDisp') || ~isfield(result, 'IanodDisp')
        return;
    end

    if numel(xValues) ~= numel(result.IcathDisp)
        return;
    end

    overlay.ok = true;
    overlay.x = xValues;
    overlay.cathY = result.IcathDisp;
    overlay.anodY = result.IanodDisp;
end
