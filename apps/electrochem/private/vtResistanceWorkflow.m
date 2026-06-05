% App-owned VT resistance workflow helper dispatch. Expected caller:
% labkit_VTResistance_app callbacks and workflow tests.
% Inputs are a command string plus the original helper arguments; outputs match
% the selected helper. Side effects are limited to CSV export writes and drawing
% app-owned plot annotations on caller axes.
function varargout = vtResistanceWorkflow(command, varargin)
%VTRESISTANCEWORKFLOW Dispatch app-owned VT resistance helpers.
% Expected caller: labkit_VTResistance_app callbacks and temporary compatibility
% workflow tests. Inputs are a command string plus the original helper arguments.
% Outputs match the selected helper. Side effects are limited to CSV export
% writes and drawing app-owned plot annotations on caller axes.

    switch string(command)
        case "computeResistance"
            varargout{1} = computeResistance(varargin{:});
        case "buildBatchTableData"
            varargout{1} = buildBatchTableData(varargin{:});
        case "buildResultsTable"
            varargout{1} = buildResultsTable(varargin{:});
        case "writeResultsCSV"
            [varargout{1:nargout}] = writeResultsCSV(varargin{:});
        case "formatDurationUs"
            varargout{1} = formatDurationUs(varargin{:});
        case "interp1Safe"
            varargout{1} = interp1Safe(varargin{:});
        case "shadeWindow"
            shadeWindow(varargin{:});
        case "addResistanceVTAnnotations"
            addResistanceVTAnnotations(varargin{:});
        case "addResistanceITAnnotations"
            addResistanceITAnnotations(varargin{:});
        otherwise
            error('labkit:VTResistance:UnknownWorkflowCommand', ...
                'Unknown VT resistance workflow helper command: %s.', command);
    end
end
function A = computeResistance(item, opts)
%COMPUTERESISTANCE Compute VT resistance metrics for the VT app.

    if nargin < 2
        opts = struct();
    end
    opts = fillResistanceOptions(opts);

    A = struct();
    A.ok = false;
    A.message = '';
    A.windowMode = opts.windowMode;
    A.voltageMode = opts.voltageMode;
    A.logOnFailure = false;

    [curve, okCurve, msgCurve] = mainCurve(item);
    if ~okCurve
        A.message = msgCurve;
        A.logOnFailure = true;
        return;
    end

    t = labkit.dta.getColumn(curve, 'T');
    Vf = labkit.dta.getColumn(curve, 'Vf');
    Im = labkit.dta.getColumn(curve, 'Im');
    pt = labkit.dta.getColumn(curve, 'Pt');
    if isempty(pt)
        pt = (0:numel(t)-1).';
    end

    valid = ~(isnan(t) | isnan(Vf) | isnan(Im));
    t = t(valid);
    Vf = Vf(valid);
    Im = Im(valid);
    pt = pt(valid);
    if numel(t) < 5
        A.message = 'Not enough valid T/Vf/Im points.';
        return;
    end

    A.t = t;
    A.Vf = Vf;
    A.Im = Im;
    A.pt = pt;

    meta = struct();
    if isfield(item, 'meta')
        meta = item.meta;
    end
    [pulse, pulseMsg] = labkit.dta.detectPulses(t, Im, meta, opts.pulseMode);
    A.pulse = pulse;
    A.detectMode = pulse.method;
    A.detectMsg = pulseMsg;
    if ~pulse.ok
        A.message = pulseMsg;
        A.logOnFailure = true;
        return;
    end

    [cStart, cEnd] = selectSteadyWindow(pulse.cath_start, pulse.cath_end, A.windowMode);
    [aStart, aEnd] = selectSteadyWindow(pulse.anod_start, pulse.anod_end, A.windowMode);
    cathMask = t >= cStart & t <= cEnd;
    anodMask = t >= aStart & t <= aEnd;
    if nnz(cathMask) < 2 || nnz(anodMask) < 2
        A.message = 'Steady windows are too short after pulse detection.';
        return;
    end

    A.cathMask = cathMask;
    A.anodMask = anodMask;
    A.cathSteadyStart = cStart;
    A.cathSteadyEnd = cEnd;
    A.anodSteadyStart = aStart;
    A.anodSteadyEnd = aEnd;

    A.Ic_est_A = median(Im(cathMask), 'omitnan');
    A.Ia_est_A = median(Im(anodMask), 'omitnan');
    A.Vc_ss_V = median(Vf(cathMask), 'omitnan');
    A.Va_ss_V = median(Vf(anodMask), 'omitnan');

    A.cathBaselineStart = pulse.pre_start;
    A.cathBaselineEnd = pulse.pre_end;
    A.anodBaselineStart = pulse.post_start;
    A.anodBaselineEnd = pulse.post_end;
    [A.Vc_baseline_V, A.cathBaselineWindow_s] = estimateBaseline( ...
        t, Vf, pulse.pre_start, pulse.pre_end, 0);
    [A.Va_baseline_V, A.anodBaselineWindow_s] = estimateBaseline( ...
        t, Vf, pulse.post_start, pulse.post_end, chooseFinite(A.Vc_baseline_V, 0));

    A.dVc_V = A.Vc_ss_V - A.Vc_baseline_V;
    A.dVa_V = A.Va_ss_V - A.Va_baseline_V;
    A.Rc_raw_ohm = safeDivide(A.Vc_ss_V, A.Ic_est_A);
    A.Ra_raw_ohm = safeDivide(A.Va_ss_V, A.Ia_est_A);
    A.Rc_dV_ohm = safeDivide(A.dVc_V, A.Ic_est_A);
    A.Ra_dV_ohm = safeDivide(A.dVa_V, A.Ia_est_A);

    if strcmp(A.voltageMode, 'Raw Vf/I')
        A.Rc_ohm = A.Rc_raw_ohm;
        A.Ra_ohm = A.Ra_raw_ohm;
    else
        A.Rc_ohm = A.Rc_dV_ohm;
        A.Ra_ohm = A.Ra_dV_ohm;
    end
    A.Rc_abs_ohm = abs(A.Rc_ohm);
    A.Ra_abs_ohm = abs(A.Ra_ohm);
    A.Ravg_abs_ohm = mean([A.Rc_abs_ohm, A.Ra_abs_ohm], 'omitnan');

    A.ok = isfinite(A.Ravg_abs_ohm);
    if A.ok
        A.message = 'OK';
    else
        A.message = 'Resistance could not be computed; check current and pulse detection.';
        A.logOnFailure = true;
    end
end

function opts = fillResistanceOptions(opts)
    if ~isfield(opts, 'windowMode')
        opts.windowMode = 'Full pulse median';
    end
    if ~isfield(opts, 'voltageMode')
        opts.voltageMode = 'Baseline-corrected dV/I';
    end
    if ~isfield(opts, 'pulseMode')
        opts.pulseMode = 'Metadata first, then auto';
    end
end

%% App-local table/export helpers
function C = buildBatchTableData(items)
%BUILDBATCHTABLEDATA Build VT resistance uitable data.

    C = cell(numel(items), 9);
    for i = 1:numel(items)
        item = items(i);
        C{i, 1} = itemName(item);
        A = itemAnalysis(item);
        if isempty(A) || ~isfield(A, 'ok') || ~A.ok
            C{i, 2} = NaN;
            C{i, 3} = NaN;
            C{i, 4} = NaN;
            C{i, 5} = NaN;
            C{i, 6} = NaN;
            C{i, 7} = NaN;
            C{i, 8} = NaN;
            C{i, 9} = 'parse/analyze failed';
            continue;
        end

        C{i, 2} = A.Ic_est_A;
        C{i, 3} = A.Ia_est_A;
        C{i, 4} = A.Vc_ss_V;
        C{i, 5} = A.Va_ss_V;
        C{i, 6} = A.Rc_abs_ohm;
        C{i, 7} = A.Ra_abs_ohm;
        C{i, 8} = A.Ravg_abs_ohm;
        C{i, 9} = A.detectMode;
    end
end

function T = buildResultsTable(items)
%BUILDRESULTSTABLE Build VT resistance CSV result table.

    file = cell(numel(items), 1);
    Ic_A = NaN(numel(items), 1);
    Ia_A = NaN(numel(items), 1);
    Vc_ss_V = NaN(numel(items), 1);
    Va_ss_V = NaN(numel(items), 1);
    Vc_baseline_V = NaN(numel(items), 1);
    Va_baseline_V = NaN(numel(items), 1);
    dVc_V = NaN(numel(items), 1);
    dVa_V = NaN(numel(items), 1);
    Rc_bc_ohm = NaN(numel(items), 1);
    Ra_bc_ohm = NaN(numel(items), 1);
    Ravg_bc_ohm = NaN(numel(items), 1);
    windowMode = cell(numel(items), 1);
    detection = cell(numel(items), 1);
    status = cell(numel(items), 1);

    for i = 1:numel(items)
        item = items(i);
        file{i} = itemName(item);
        A = itemAnalysis(item);
        if isempty(A) || ~isfield(A, 'ok') || ~A.ok
            windowMode{i} = '';
            detection{i} = 'failed';
            status{i} = analysisMessage(A);
            continue;
        end

        Ic_A(i) = A.Ic_est_A;
        Ia_A(i) = A.Ia_est_A;
        Vc_ss_V(i) = A.Vc_ss_V;
        Va_ss_V(i) = A.Va_ss_V;
        Vc_baseline_V(i) = A.Vc_baseline_V;
        Va_baseline_V(i) = A.Va_baseline_V;
        dVc_V(i) = A.dVc_V;
        dVa_V(i) = A.dVa_V;
        Rc_bc_ohm(i) = abs(A.Rc_dV_ohm);
        Ra_bc_ohm(i) = abs(A.Ra_dV_ohm);
        Ravg_bc_ohm(i) = mean([Rc_bc_ohm(i), Ra_bc_ohm(i)], 'omitnan');
        windowMode{i} = A.windowMode;
        detection{i} = A.detectMode;
        status{i} = A.message;
    end

    T = table(file, Ic_A, Ia_A, Vc_ss_V, Va_ss_V, Vc_baseline_V, Va_baseline_V, ...
        dVc_V, dVa_V, Rc_bc_ohm, Ra_bc_ohm, Ravg_bc_ohm, windowMode, detection, status, ...
        'VariableNames', {'File', 'Ic_A', 'Ia_A', 'Vc_ss_V', 'Va_ss_V', ...
        'Vc_baseline_V', 'Va_baseline_V', 'dVc_V', 'dVa_V', 'Rc_bc_ohm', ...
        'Ra_bc_ohm', 'Ravg_bc_ohm', 'WindowMode', 'Detection', 'Status'});
end

function [ok, msg] = writeResultsCSV(items, filepath)
%WRITERESULTSCSV Write VT resistance results in legacy CSV format.

    ok = true;
    msg = '';

    fid = fopen(filepath, 'w');
    if fid < 0
        ok = false;
        msg = 'Could not open file for writing.';
        if nargout == 0
            error(msg);
        end
        return;
    end
    cleaner = onCleanup(@() fclose(fid));

    try
        T = buildResultsTable(items);
        fprintf(fid, 'File,Ic_A,Ia_A,Vc_ss_V,Va_ss_V,Vc_baseline_V,Va_baseline_V,dVc_V,dVa_V,Rc_bc_ohm,Ra_bc_ohm,Ravg_bc_ohm,WindowMode,Detection,Status\n');
        for i = 1:height(T)
            fprintf(fid, '"%s",%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,"%s","%s","%s"\n', ...
                csvEscape(T.File{i}), ...
                T.Ic_A(i), T.Ia_A(i), T.Vc_ss_V(i), T.Va_ss_V(i), ...
                T.Vc_baseline_V(i), T.Va_baseline_V(i), T.dVc_V(i), T.dVa_V(i), ...
                T.Rc_bc_ohm(i), T.Ra_bc_ohm(i), T.Ravg_bc_ohm(i), ...
                csvEscape(T.WindowMode{i}), ...
                csvEscape(T.Detection{i}), ...
                csvEscape(T.Status{i}));
        end
    catch ME
        ok = false;
        msg = ME.message;
        if nargout == 0
            rethrow(ME);
        end
    end
end

%% App-local plotting helpers
function [curve, ok, msg] = mainCurve(item)
    if isfield(item, 'curve') && ~isempty(item.curve)
        curve = item.curve;
        ok = true;
        msg = sprintf('Using table: %s', curve.name);
    elseif isfield(item, 'tables')
        [curve, ok, msg] = labkit.dta.getMainCurve(item.tables);
    else
        curve = struct();
        ok = false;
        msg = 'Main transient table not found.';
    end
end

function q = safeDivide(a, b)
    if ~isscalar(a) || ~isscalar(b) || ~isfinite(a) || ~isfinite(b) || abs(b) < eps
        q = NaN;
    else
        q = a / b;
    end
end

function v = chooseFinite(varargin)
    v = NaN;
    for k = 1:nargin
        x = varargin{k};
        if isscalar(x) && isfinite(x)
            v = x;
            return;
        end
    end
end

function [t1, t2] = selectSteadyWindow(p1, p2, modeText)
    t1 = p1;
    t2 = p2;
    if strcmp(modeText, 'Center 60% median') && isfinite(p1) && isfinite(p2) && p2 > p1
        dt = p2 - p1;
        t1 = p1 + 0.20 * dt;
        t2 = p1 + 0.80 * dt;
    end
end

function [v, window_s] = estimateBaseline(t, y, t1, t2, fallbackValue)
    if nargin < 5
        fallbackValue = NaN;
    end

    v = medianInWindow(t, y, t1, t2);
    if ~isfinite(v)
        v = fallbackValue;
    end
    window_s = max(0, t2 - t1);
end

function name = itemName(item)
    if isfield(item, 'name')
        name = item.name;
    else
        name = '';
    end
end

function A = itemAnalysis(item)
    if isfield(item, 'analysis')
        A = item.analysis;
    else
        A = [];
    end
end

function msg = analysisMessage(A)
    msg = '';
    if ~isempty(A) && isfield(A, 'message')
        msg = A.message;
    end
end

function out = ternary(cond, a, b)
    if cond
        out = a;
    else
        out = b;
    end
end

function shadeWindow(ax, x1, x2, color, alphaVal)
    if ~isfinite(x1) || ~isfinite(x2) || x2 <= x1
        return;
    end
    yl = ylim(ax);
    if any(~isfinite(yl)) || yl(1) == yl(2)
        return;
    end
    p = patch(ax, [x1 x2 x2 x1], [yl(1) yl(1) yl(2) yl(2)], color, ...
        'FaceAlpha',alphaVal,'EdgeColor','none','HandleVisibility','off');
    uistack(p,'bottom');
end

function addResistanceVTAnnotations(ax, A, cathBaseStartX, cathBaseEndX, anodBaseStartX, anodBaseEndX, ...
    cSteadyStartX, cSteadyEndX, aSteadyStartX, aSteadyEndX, cathStartX, cathEndX, anodStartX, anodEndX)
    cSteadyMidX = midpointFinite(cSteadyStartX, cSteadyEndX);
    aSteadyMidX = midpointFinite(aSteadyStartX, aSteadyEndX);

    drawBaselineSegment(ax, cathBaseStartX, cathBaseEndX, A.Vc_baseline_V, [0.20 0.20 0.20], ...
        sprintf('Cath baseline = %.4f V', A.Vc_baseline_V), 'bottom');
    drawBaselineSegment(ax, anodBaseStartX, anodBaseEndX, A.Va_baseline_V, [0.35 0.35 0.35], ...
        sprintf('Anod baseline = %.4f V', A.Va_baseline_V), 'top');

    drawLevelSegment(ax, cSteadyStartX, cSteadyEndX, A.Vc_ss_V, [0.10 0.35 0.80], '--');
    drawLevelSegment(ax, aSteadyStartX, aSteadyEndX, A.Va_ss_V, [0.80 0.35 0.10], '--');

    plot(ax, cSteadyEndX, A.Vc_ss_V, 'o', 'MarkerFaceColor',[0.10 0.35 0.80], ...
        'MarkerEdgeColor','k', 'MarkerSize',6, 'HandleVisibility','off');
    plot(ax, aSteadyEndX, A.Va_ss_V, 'o', 'MarkerFaceColor',[0.80 0.35 0.10], ...
        'MarkerEdgeColor','k', 'MarkerSize',6, 'HandleVisibility','off');

    text(ax, cSteadyEndX, A.Vc_ss_V, sprintf('  Cath steady V = %.4f V', A.Vc_ss_V), ...
        'Color',[0.10 0.35 0.80], 'VerticalAlignment','bottom', 'Interpreter','tex');
    text(ax, aSteadyEndX, A.Va_ss_V, sprintf('  Anod steady V = %.4f V', A.Va_ss_V), ...
        'Color',[0.80 0.35 0.10], 'VerticalAlignment','top', 'Interpreter','tex');

    if isfinite(cSteadyMidX) && isfinite(A.Vc_baseline_V) && isfinite(A.Vc_ss_V)
        plot(ax, [cSteadyMidX cSteadyMidX], [A.Vc_baseline_V A.Vc_ss_V], '--', ...
            'Color',[0.10 0.35 0.80], 'LineWidth',1.0, 'HandleVisibility','off');
        text(ax, cSteadyMidX, 0.5*(A.Vc_baseline_V + A.Vc_ss_V), sprintf('  Cath dV = %.4f V', A.dVc_V), ...
            'Color',[0.10 0.35 0.80], 'VerticalAlignment','middle', 'Interpreter','tex');
    end
    if isfinite(aSteadyMidX) && isfinite(A.Va_baseline_V) && isfinite(A.Va_ss_V)
        plot(ax, [aSteadyMidX aSteadyMidX], [A.Va_baseline_V A.Va_ss_V], '--', ...
            'Color',[0.80 0.35 0.10], 'LineWidth',1.0, 'HandleVisibility','off');
        text(ax, aSteadyMidX, 0.5*(A.Va_baseline_V + A.Va_ss_V), sprintf('  Anod dV = %.4f V', A.dVa_V), ...
            'Color',[0.80 0.35 0.10], 'VerticalAlignment','middle', 'Interpreter','tex');
    end

    yl = ylim(ax);
    dy = yl(2) - yl(1);
    yTop = yl(2) - 0.08 * dy;
    yLow = yl(2) - 0.16 * dy;
    drawDurationBracket(ax, cathStartX, cathEndX, yTop, 'Cathodic pulse');
    drawDurationBracket(ax, anodStartX, anodEndX, yLow, 'Anodic pulse');
end

function addResistanceITAnnotations(ax, A, cSteadyStartX, cSteadyEndX, aSteadyStartX, aSteadyEndX, ...
    cathStartX, cathEndX, anodStartX, anodEndX)
    drawLevelSegment(ax, cSteadyStartX, cSteadyEndX, A.Ic_est_A, [0.10 0.35 0.80], '--');
    drawLevelSegment(ax, aSteadyStartX, aSteadyEndX, A.Ia_est_A, [0.80 0.35 0.10], '--');

    plot(ax, cSteadyEndX, A.Ic_est_A, 'o', 'MarkerFaceColor',[0.10 0.35 0.80], ...
        'MarkerEdgeColor','k', 'MarkerSize',6, 'HandleVisibility','off');
    plot(ax, aSteadyEndX, A.Ia_est_A, 'o', 'MarkerFaceColor',[0.80 0.35 0.10], ...
        'MarkerEdgeColor','k', 'MarkerSize',6, 'HandleVisibility','off');

    text(ax, cSteadyEndX, A.Ic_est_A, sprintf('  Cath current = %.3f mA', 1e3 * A.Ic_est_A), ...
        'Color',[0.10 0.35 0.80], 'VerticalAlignment','bottom', 'Interpreter','tex');
    text(ax, aSteadyEndX, A.Ia_est_A, sprintf('  Anod current = %.3f mA', 1e3 * A.Ia_est_A), ...
        'Color',[0.80 0.35 0.10], 'VerticalAlignment','top', 'Interpreter','tex');

    yl = ylim(ax);
    dy = yl(2) - yl(1);
    yTop = yl(2) - 0.08 * dy;
    yLow = yl(2) - 0.16 * dy;
    drawDurationBracket(ax, cathStartX, cathEndX, yTop, 'Cathodic pulse');
    drawDurationBracket(ax, anodStartX, anodEndX, yLow, 'Anodic pulse');
end

function drawDurationBracket(ax, x1, x2, y, labelText)
    if ~isfinite(x1) || ~isfinite(x2) || x2 <= x1 || ~isfinite(y)
        return;
    end
    yl = ylim(ax);
    h = 0.025 * (yl(2) - yl(1));
    plot(ax, [x1 x2], [y y], 'k-', 'LineWidth',1.0, 'HandleVisibility','off');
    plot(ax, [x1 x1], [y-h y+h], 'k-', 'LineWidth',1.0, 'HandleVisibility','off');
    plot(ax, [x2 x2], [y-h y+h], 'k-', 'LineWidth',1.0, 'HandleVisibility','off');
    text(ax, 0.5 * (x1 + x2), y + 1.4 * h, labelText, 'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', 'BackgroundColor','w', 'Margin',1, 'HandleVisibility','off');
end

function drawBaselineSegment(ax, x1, x2, y, color, labelText, verticalAlignment)
    if ~isfinite(y)
        return;
    end
    if isfinite(x1) && isfinite(x2) && x2 > x1
        xStart = x1;
        xEnd = x2;
    else
        xl = xlim(ax);
        xStart = xl(1) + 0.04 * (xl(2) - xl(1));
        xEnd = xStart + 0.18 * (xl(2) - xl(1));
    end
    plot(ax, [xStart xEnd], [y y], '--', 'Color', color, 'LineWidth',1.4, 'HandleVisibility','off');
    text(ax, xStart, y, [' ' labelText], 'Color', color, 'VerticalAlignment', verticalAlignment, ...
        'BackgroundColor','w', 'Margin',1, 'Interpreter','none', 'HandleVisibility','off');
end

function drawLevelSegment(ax, x1, x2, y, color, lineStyle)
    if ~isfinite(x1) || ~isfinite(x2) || x2 <= x1 || ~isfinite(y)
        return;
    end
    plot(ax, [x1 x2], [y y], lineStyle, 'Color', color, 'LineWidth',1.3, 'HandleVisibility','off');
end

function xm = midpointFinite(x1, x2)
    if isfinite(x1) && isfinite(x2)
        xm = 0.5 * (x1 + x2);
    else
        xm = NaN;
    end
end

function txt = formatDurationUs(dt_s)
    if ~isscalar(dt_s) || ~isfinite(dt_s) || dt_s < 0
        txt = '-';
    else
        txt = sprintf('%.3f us', 1e6 * dt_s);
    end
end

function s = csvEscape(x)
    s = strrep(char(x), '"', '""');
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

function m = medianInWindow(t, y, t1, t2)
    if ~isfinite(t1) || ~isfinite(t2) || t2 < t1
        m = NaN;
        return;
    end

    mask = t >= t1 & t <= t2;
    if ~any(mask)
        m = NaN;
    else
        m = median(y(mask), 'omitnan');
    end
end
