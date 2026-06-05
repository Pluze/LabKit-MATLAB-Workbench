% App-owned CIC workflow helper dispatch. Expected caller: labkit_CIC_app
% callbacks and workflow tests. Inputs are a command
% string plus the original helper arguments; outputs match the selected helper.
% Side effects are limited to writeResultsCSV file writes.
function varargout = cicWorkflow(command, varargin)
%CICWORKFLOW Dispatch app-owned CIC analysis/export helpers.
% Expected caller: labkit_CIC_app callbacks and workflow tests.
% Inputs are a command string plus the original helper arguments. Outputs match
% the selected helper. Side effects are limited to writeResultsCSV file writes.

    switch string(command)
        case "computeCIC"
            varargout{1} = computeCIC(varargin{:});
        case "buildBatchTableData"
            [varargout{1:nargout}] = buildBatchTableData(varargin{:});
        case "buildResultsTable"
            varargout{1} = buildResultsTable(varargin{:});
        case "writeResultsCSV"
            [varargout{1:nargout}] = writeResultsCSV(varargin{:});
        otherwise
            error('labkit:CIC:UnknownWorkflowCommand', ...
                'Unknown CIC workflow helper command: %s.', command);
    end
end
function A = computeCIC(item, opts)
%COMPUTECIC Compute legacy-compatible CIC / voltage-transient metrics.

    if nargin < 2
        opts = struct();
    end
    opts = fillCICOptions(opts);

    A = struct();
    A.ok = false;
    A.message = '';
    A.delay_s = opts.delay_s;
    A.cathLimit = opts.cathLimit;
    A.anodLimit = opts.anodLimit;
    A.area_cm2 = chooseArea(item, opts);
    A.usedMeasuredCurrent = opts.usedMeasuredCurrent;
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
    A.sample_dt = median(diff(t));
    A.sample_dt_report = A.sample_dt;
    A.ampEstimate_A = max(abs(Im));

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

    V = computeVoltageTransientMetrics(t, Vf, pulse, A.delay_s);
    A = mergeStructs(A, V);

    Q = computeInjectedCharge(t, Im, pulse, A.usedMeasuredCurrent);
    A = mergeStructs(A, Q);
    if ~Q.ok
        A.message = Q.message;
        return;
    end

    if isfinite(A.area_cm2) && A.area_cm2 > 0
        A.CICc_mCcm2 = 1e3 * A.Qc_C / A.area_cm2;
        A.CICa_mCcm2 = 1e3 * A.Qa_C / A.area_cm2;
        A.CICt_mCcm2 = 1e3 * A.Qt_C / A.area_cm2;
    else
        A.CICc_mCcm2 = NaN;
        A.CICa_mCcm2 = NaN;
        A.CICt_mCcm2 = NaN;
    end

    safety = checkWaterWindowSafety(A.Emc, A.Ema, A.cathLimit, A.anodLimit);
    A = mergeStructs(A, safety);

    A.ok = true;
    A.message = 'OK';
end

function opts = fillCICOptions(opts)
    if ~isfield(opts, 'delay_s')
        opts.delay_s = 10e-6;
    end
    if ~isfield(opts, 'cathLimit')
        opts.cathLimit = -0.6;
    end
    if ~isfield(opts, 'anodLimit')
        opts.anodLimit = 0.8;
    end
    if ~isfield(opts, 'areaOverride')
        opts.areaOverride = '';
    end
    if ~isfield(opts, 'area_cm2')
        opts.area_cm2 = NaN;
    end
    if ~isfield(opts, 'pulseMode')
        opts.pulseMode = 'Metadata first, then auto';
    end
    if ~isfield(opts, 'usedMeasuredCurrent')
        opts.usedMeasuredCurrent = true;
    end
end

function area = chooseArea(item, opts)
    area = NaN;
    if isfield(opts, 'areaOverride')
        area = parsePositiveScalar(opts.areaOverride);
    end
    if ~isfinite(area) && isfield(opts, 'area_cm2')
        area = parsePositiveScalar(opts.area_cm2);
    end
    if ~isfinite(area) && isfield(item, 'meta') && isfield(item.meta, 'area_cm2') ...
            && isfinite(item.meta.area_cm2) && item.meta.area_cm2 > 0
        area = item.meta.area_cm2;
    end
end

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

function out = mergeStructs(out, in)
    names = fieldnames(in);
    for i = 1:numel(names)
        out.(names{i}) = in.(names{i});
    end
end

function V = computeVoltageTransientMetrics(t, Vf, pulse, delay_s)
    V = struct();
    V.t_emc = pulse.cath_end + delay_s;
    V.t_ema = pulse.anod_end + delay_s;
    V.emc_idx = nearestIndex(t, V.t_emc);
    V.ema_idx = nearestIndex(t, V.t_ema);
    V.Emc = interp1Safe(t, Vf, V.t_emc);
    V.Ema = interp1Safe(t, Vf, V.t_ema);

    V.Epre = medianInWindow(t, Vf, pulse.pre_start, pulse.pre_end);
    V.Ebetween = medianInWindow(t, Vf, pulse.gap_start, pulse.gap_end);
    V.Epost = medianInWindow(t, Vf, pulse.post_start, pulse.post_end);
    [V.Eipp, V.baselineCathSource, V.baselineCathWindow] = chooseBaselineCandidate( ...
        [V.Epre, V.Ebetween, V.Epost, 0], ...
        {'pre-pulse median', 'interpulse median', 'post-pulse median', 'zero fallback'}, ...
        [pulse.pre_start pulse.pre_end; pulse.gap_start pulse.gap_end; pulse.post_start pulse.post_end; NaN NaN]);
    [V.Eipp_gap, V.baselineAnodSource, V.baselineAnodWindow] = chooseBaselineCandidate( ...
        [V.Ebetween, V.Epre, V.Epost, V.Eipp], ...
        {'interpulse median', 'pre-pulse median', 'post-pulse median', 'cathodic baseline fallback'}, ...
        [pulse.gap_start pulse.gap_end; pulse.pre_start pulse.pre_end; pulse.post_start pulse.post_end; V.baselineCathWindow]);

    V.tc_s = max(0, pulse.cath_end - pulse.cath_start);
    V.ta_s = max(0, pulse.anod_end - pulse.anod_start);
    V.tip_s = max(0, pulse.anod_start - pulse.cath_end);
    V.t_conset = pulse.cath_start + delay_s;
    V.t_aonset = pulse.anod_start + delay_s;
    V.Vc_on = interp1Safe(t, Vf, V.t_conset);
    V.Va_on = interp1Safe(t, Vf, V.t_aonset);
    V.Va_cath_mag = abs(V.Eipp - V.Vc_on);
    V.Va_anod_mag = abs(V.Eipp_gap - V.Va_on);
end

function Q = computeInjectedCharge(t, Im, pulse, useMeasuredCurrent)
    if nargin < 4
        useMeasuredCurrent = true;
    end

    Q = struct();
    cathMask = (t >= pulse.cath_start) & (t <= pulse.cath_end);
    anodMask = (t >= pulse.anod_start) & (t <= pulse.anod_end);
    Q.cathMask = cathMask;
    Q.anodMask = anodMask;

    if sum(cathMask) < 2 || sum(anodMask) < 2
        Q.ok = false;
        Q.message = 'Pulse windows too short after detection.';
        return;
    end

    Q.Ic_est_A = median(Im(cathMask), 'omitnan');
    Q.Ia_est_A = median(Im(anodMask), 'omitnan');
    if ~isfinite(Q.Ic_est_A)
        Q.Ic_est_A = pulse.Ic_nominal;
    end
    if ~isfinite(Q.Ia_est_A)
        Q.Ia_est_A = pulse.Ia_nominal;
    end

    if useMeasuredCurrent
        Qc = abs(trapz(t(cathMask), Im(cathMask)));
        Qa = abs(trapz(t(anodMask), Im(anodMask)));
    else
        Qc = abs(pulse.Ic_nominal * (pulse.cath_end - pulse.cath_start));
        Qa = abs(pulse.Ia_nominal * (pulse.anod_end - pulse.anod_start));
    end

    Q.Qc_C = Qc;
    Q.Qa_C = Qa;
    Q.Qt_C = Qc + Qa;
    Q.ok = true;
    Q.message = 'OK';
end

function safety = checkWaterWindowSafety(Emc, Ema, cathLimit, anodLimit)
    safety = struct();
    safety.cathOK = Emc >= cathLimit;
    safety.anodOK = Ema <= anodLimit;
    safety.safe = safety.cathOK && safety.anodOK;

    if safety.safe
        safety.limitSide = 'safe';
    elseif ~safety.cathOK && ~safety.anodOK
        safety.limitSide = 'both exceeded';
    elseif ~safety.cathOK
        safety.limitSide = 'cathodic exceeded';
    else
        safety.limitSide = 'anodic exceeded';
    end
end

%% App-local table/export helpers
function [C, columnNames] = buildBatchTableData(items, unitLabel)
%BUILDBATCHTABLEDATA Build legacy CIC batch uitable data.

    if nargin < 2
        unitLabel = 'mC/cm^2';
    end
    [scale, unitLabel] = displayScale(unitLabel);
    columnNames = {'File', 'Amp(A)', 'Emc(V)', 'Ema(V)', ...
        ['Qc(' unitLabel ')'], ['Qa(' unitLabel ')'], ['Qtot(' unitLabel ')'], 'Safe'};

    C = cell(numel(items), 8);
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
            C{i, 8} = 'parse/analyze failed';
            continue;
        end

        C{i, 2} = A.ampEstimate_A;
        C{i, 3} = A.Emc;
        C{i, 4} = A.Ema;
        C{i, 5} = scale * A.CICc_mCcm2;
        C{i, 6} = scale * A.CICa_mCcm2;
        C{i, 7} = scale * A.CICt_mCcm2;
        C{i, 8} = ternary(A.safe, 'safe', A.limitSide);
    end
end

function T = buildResultsTable(items, unitLabel)
%BUILDRESULTSTABLE Build legacy CIC CSV result table.

    if nargin < 2
        unitLabel = 'mC/cm^2';
    end
    [scale, unitSuffix] = displayScaleSuffix(unitLabel);

    file = cell(numel(items), 1);
    amp_A = NaN(numel(items), 1);
    Emc_V = NaN(numel(items), 1);
    Ema_V = NaN(numel(items), 1);
    Qc_C = NaN(numel(items), 1);
    Qa_C = NaN(numel(items), 1);
    Qt_C = NaN(numel(items), 1);
    CICc = NaN(numel(items), 1);
    CICa = NaN(numel(items), 1);
    CICt = NaN(numel(items), 1);
    safe = zeros(numel(items), 1);
    detection = cell(numel(items), 1);

    for i = 1:numel(items)
        item = items(i);
        file{i} = itemName(item);
        A = itemAnalysis(item);
        if isempty(A) || ~isfield(A, 'ok') || ~A.ok
            detection{i} = 'failed';
            continue;
        end

        amp_A(i) = A.ampEstimate_A;
        Emc_V(i) = A.Emc;
        Ema_V(i) = A.Ema;
        Qc_C(i) = A.Qc_C;
        Qa_C(i) = A.Qa_C;
        Qt_C(i) = A.Qt_C;
        CICc(i) = scale * A.CICc_mCcm2;
        CICa(i) = scale * A.CICa_mCcm2;
        CICt(i) = scale * A.CICt_mCcm2;
        safe(i) = A.safe;
        detection{i} = A.detectMode;
    end

    T = table(file, amp_A, Emc_V, Ema_V, Qc_C, Qa_C, Qt_C, CICc, CICa, CICt, safe, detection, ...
        'VariableNames', {'File', 'Amp_A', 'Emc_V', 'Ema_V', 'Qc_C', 'Qa_C', 'Qt_C', ...
        ['CICc_' unitSuffix], ['CICa_' unitSuffix], ['CICt_' unitSuffix], 'Safe', 'Detection'});
end

function [ok, msg] = writeResultsCSV(items, filepath, unitLabel)
%WRITERESULTSCSV Write CIC results in legacy CSV format.

    if nargin < 3
        unitLabel = 'mC/cm^2';
    end

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
        T = buildResultsTable(items, unitLabel);
        names = T.Properties.VariableNames;
        fprintf(fid, 'File,Amp_A,Emc_V,Ema_V,Qc_C,Qa_C,Qt_C,%s,%s,%s,Safe,Detection\n', ...
            names{8}, names{9}, names{10});
        for i = 1:height(T)
            if strcmp(T.Detection{i}, 'failed')
                fprintf(fid, '"%s",,,,,,,,,,0,"failed"\n', T.File{i});
            else
                fprintf(fid, '"%s",%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%d,"%s"\n', ...
                    T.File{i}, T.Amp_A(i), T.Emc_V(i), T.Ema_V(i), T.Qc_C(i), T.Qa_C(i), T.Qt_C(i), ...
                    T.(names{8})(i), T.(names{9})(i), T.(names{10})(i), T.Safe(i), T.Detection{i});
            end
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
function [v, sourceLabel, window] = chooseBaselineCandidate(candidates, sourceLabels, windows)
    v = NaN;
    sourceLabel = 'unavailable';
    window = [NaN NaN];
    for k = 1:numel(candidates)
        if isfinite(candidates(k))
            v = candidates(k);
            sourceLabel = sourceLabels{k};
            if size(windows, 1) >= k
                window = windows(k, :);
            end
            return;
        end
    end
end

function [scale, unitLabel] = displayScale(unitLabel)
    switch unitLabel
        case 'uC/cm^2'
            scale = 1e3;
        otherwise
            scale = 1;
            unitLabel = 'mC/cm^2';
    end
end

function [scale, unitSuffix] = displayScaleSuffix(unitLabel)
    [scale, unitLabel] = displayScale(unitLabel);
    unitSuffix = regexprep(unitLabel, '[\^/]', '');
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

function out = formatChargeDensity(Q_C, cic_mCcm2, unitLabel)
    if isfinite(cic_mCcm2)
        switch unitLabel
            case 'uC/cm^2'
                cic = 1e3 * cic_mCcm2;
            otherwise
                cic = cic_mCcm2;
                unitLabel = 'mC/cm^2';
        end
        out = sprintf('%.6e C | %.6f %s', Q_C, cic, unitLabel);
    else
        out = sprintf('%.6e C | area unavailable', Q_C);
    end
end

function s = formatMaybeNum(v, fmt)
    if isfinite(v)
        s = sprintf(fmt, v);
    else
        s = 'NaN';
    end
end

function txt = ternary(cond, a, b)
    if cond
        txt = a;
    else
        txt = b;
    end
end

function shadeWindow(ax, x1, x2, color)
    if ~isfinite(x1) || ~isfinite(x2) || x2 <= x1
        return;
    end
    yl = ylim(ax);
    patch(ax,[x1 x2 x2 x1],[yl(1) yl(1) yl(2) yl(2)],color, ...
        'FaceAlpha',0.25,'EdgeColor','none','HandleVisibility','off');
    uistack(findobj(ax,'Type','patch'),'bottom');
end

function labelPulseCharge(ax, x1, x2, Q, tagText)
    if ~isfinite(x1) || ~isfinite(x2) || x2 <= x1
        return;
    end
    xm = 0.5 * (x1 + x2);
    yl = ylim(ax);
    y0 = yl(1) + 0.90 * (yl(2) - yl(1));
    text(ax, xm, y0, sprintf('%s = %.3e C', tagText, Q), ...
        'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'BackgroundColor','w','Margin',2);
end

function addPaperStyleVTAnnotations(ax, A, xChoice, cathStartX, cathEndX, anodStartX, anodEndX, emcX, emaX)
    yl = ylim(ax);
    dy = yl(2) - yl(1);
    yTop = yl(2) - 0.07*dy;
    yMid = yl(1) + 0.55*dy;
    yLow = yl(1) + 0.18*dy;

    if strcmp(xChoice,'Sample #')
        cOnX = interp1Safe(A.t, A.pt, A.t_conset);
        aOnX = interp1Safe(A.t, A.pt, A.t_aonset);
        cathBase1 = interp1Safe(A.t, A.pt, A.baselineCathWindow(1));
        cathBase2 = interp1Safe(A.t, A.pt, A.baselineCathWindow(2));
        anodBase1 = interp1Safe(A.t, A.pt, A.baselineAnodWindow(1));
        anodBase2 = interp1Safe(A.t, A.pt, A.baselineAnodWindow(2));
    else
        cOnX = A.t_conset;
        aOnX = A.t_aonset;
        cathBase1 = A.baselineCathWindow(1);
        cathBase2 = A.baselineCathWindow(2);
        anodBase1 = A.baselineAnodWindow(1);
        anodBase2 = A.baselineAnodWindow(2);
    end

    plot(ax, emcX, A.Emc, 'o', 'MarkerFaceColor',[0.1 0.7 0.1], 'MarkerEdgeColor','k', 'MarkerSize',7);
    plot(ax, emaX, A.Ema, 'o', 'MarkerFaceColor',[0.95 0.8 0.1], 'MarkerEdgeColor','k', 'MarkerSize',7);
    plot(ax, cOnX, A.Vc_on, 's', 'MarkerFaceColor',[0.2 0.6 1.0], 'MarkerEdgeColor','k', 'MarkerSize',6);
    plot(ax, aOnX, A.Va_on, 's', 'MarkerFaceColor',[1.0 0.6 0.2], 'MarkerEdgeColor','k', 'MarkerSize',6);

    if isfinite(A.Eipp)
        drawBaselineSegment(ax, cathBase1, cathBase2, A.Eipp, [0.25 0.25 0.25], ...
            sprintf('Baseline(cath) = %.3f V [%s]', A.Eipp, shortBaselineSource(A.baselineCathSource)), 'bottom');
    end
    if isfinite(A.Eipp_gap)
        drawBaselineSegment(ax, anodBase1, anodBase2, A.Eipp_gap, [0.45 0.45 0.45], ...
            sprintf('Baseline(anod) = %.3f V [%s]', A.Eipp_gap, shortBaselineSource(A.baselineAnodSource)), 'top');
    end

    if isfinite(A.Eipp) && isfinite(A.Vc_on)
        plot(ax, [cOnX cOnX], [A.Eipp A.Vc_on], '--', 'Color',[0.2 0.6 1.0], 'LineWidth',1.0);
        text(ax, cOnX, 0.5*(A.Eipp + A.Vc_on), sprintf(' Va(c)=%.3f V', A.Va_cath_mag), ...
            'Color',[0.15 0.45 0.8], 'VerticalAlignment','middle', 'HorizontalAlignment','left');
    end
    if isfinite(A.Eipp_gap) && isfinite(A.Va_on)
        plot(ax, [aOnX aOnX], [A.Eipp_gap A.Va_on], '--', 'Color',[0.95 0.55 0.2], 'LineWidth',1.0);
        text(ax, aOnX, 0.5*(A.Eipp_gap + A.Va_on), sprintf(' Va(a)=%.3f V', A.Va_anod_mag), ...
            'Color',[0.75 0.35 0.05], 'VerticalAlignment','middle', 'HorizontalAlignment','left');
    end

    text(ax, emcX, A.Emc, sprintf(' Emc = %.4f V', A.Emc), 'VerticalAlignment','bottom', 'Color',[0.1 0.5 0.1]);
    text(ax, emaX, A.Ema, sprintf(' Ema = %.4f V', A.Ema), 'VerticalAlignment','top', 'Color',[0.6 0.4 0]);

    drawDurationBracket(ax, cathStartX, cathEndX, yTop, sprintf('tc = %.3f ms', 1e3*A.tc_s));
    drawDurationBracket(ax, anodStartX, anodEndX, yTop - 0.06*dy, sprintf('ta = %.3f ms', 1e3*A.ta_s));
    if A.tip_s > 0 && anodStartX > cathEndX
        drawDurationBracket(ax, cathEndX, anodStartX, yLow, sprintf('tip = %.1f us', 1e6*A.tip_s));
    end
    yline(ax, yMid, ':', 'Color',[0.8 0.8 0.8], 'HandleVisibility','off');
end

function addPaperStyleITAnnotations(ax, A, xChoice, cathStartX, cathEndX, anodStartX, anodEndX, emcX, emaX)
    plot(ax, emcX, interp1Safe(chooseX(A,xChoice), A.Im, emcX), 'o', 'MarkerFaceColor',[0.1 0.7 0.1], 'MarkerEdgeColor','k', 'MarkerSize',6);
    plot(ax, emaX, interp1Safe(chooseX(A,xChoice), A.Im, emaX), 'o', 'MarkerFaceColor',[0.95 0.8 0.1], 'MarkerEdgeColor','k', 'MarkerSize',6);

    plot(ax, [cathStartX cathEndX], [A.Ic_est_A A.Ic_est_A], '--', 'Color',[0.1 0.45 0.8], 'LineWidth',1.3);
    plot(ax, [anodStartX anodEndX], [A.Ia_est_A A.Ia_est_A], '--', 'Color',[0.85 0.45 0.1], 'LineWidth',1.3);
    text(ax, cathEndX, A.Ic_est_A, sprintf('  ic = %.3f mA', 1e3*A.Ic_est_A), 'Color',[0.1 0.35 0.75], 'VerticalAlignment','bottom');
    text(ax, anodEndX, A.Ia_est_A, sprintf('  ia = %.3f mA', 1e3*A.Ia_est_A), 'Color',[0.7 0.32 0.05], 'VerticalAlignment','top');

    labelPulseCharge(ax, cathStartX, cathEndX, A.Qc_C, 'Qc');
    labelPulseCharge(ax, anodStartX, anodEndX, A.Qa_C, 'Qa');

    yl = ylim(ax);
    dy = yl(2) - yl(1);
    yTop = yl(2) - 0.08*dy;
    yMid = yl(2) - 0.16*dy;
    drawDurationBracket(ax, cathStartX, cathEndX, yTop, sprintf('tc = %.3f ms', 1e3*A.tc_s));
    drawDurationBracket(ax, anodStartX, anodEndX, yTop, sprintf('ta = %.3f ms', 1e3*A.ta_s));
    if A.tip_s > 0 && anodStartX > cathEndX
        drawDurationBracket(ax, cathEndX, anodStartX, yMid, sprintf('tip = %.1f us', 1e6*A.tip_s));
    end
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
    text(ax, 0.5*(x1+x2), y + 1.4*h, labelText, 'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', 'BackgroundColor','w', 'Margin',1);
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
        'BackgroundColor','w', 'Margin',1, 'Interpreter','none');
end

function addBaselineYLines(ax, A)
    if isfinite(A.Eipp)
        yline(ax, A.Eipp, '--', ...
            sprintf('Baseline(cath) = %.3f V [%s]', A.Eipp, shortBaselineSource(A.baselineCathSource)), ...
            'Color',[0.20 0.20 0.20], 'LabelHorizontalAlignment','right', 'LabelVerticalAlignment','bottom');
    end
    if isfinite(A.Eipp_gap)
        yline(ax, A.Eipp_gap, '--', ...
            sprintf('Baseline(anod) = %.3f V [%s]', A.Eipp_gap, shortBaselineSource(A.baselineAnodSource)), ...
            'Color',[0.40 0.40 0.40], 'LabelHorizontalAlignment','right', 'LabelVerticalAlignment','top');
    end
end

function x = chooseX(A, xChoice)
    if strcmp(xChoice, 'Sample #')
        x = A.pt;
    else
        x = A.t;
    end
end

function v = chooseFinite(varargin)
    v = NaN;
    for k = 1:nargin
        if isfinite(varargin{k})
            v = varargin{k};
            return;
        end
    end
end

function s = shortBaselineSource(sourceLabel)
    switch sourceLabel
        case 'pre-pulse median'
            s = 'pre';
        case 'interpulse median'
            s = 'gap';
        case 'post-pulse median'
            s = 'post';
        case 'zero fallback'
            s = '0 V fallback';
        case 'cathodic baseline fallback'
            s = 'cath fallback';
        otherwise
            s = sourceLabel;
    end
end

function q = parsePositiveScalar(x)
    if isnumeric(x)
        q = x;
    else
        x = strtrim(char(x));
        if isempty(x)
            q = NaN;
            return;
        end
        q = str2double(x);
    end

    if ~isscalar(q) || ~isfinite(q) || q <= 0
        q = NaN;
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
