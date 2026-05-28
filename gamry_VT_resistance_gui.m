function gamry_VT_resistance_gui
% GAMRY_VT_RESISTANCE_GUI
% GUI for estimating cathodic/anodic steady-state resistance from Gamry
% MULTI_STEP_CHRONOPOT .DTA files.
%
% The pulse detection and current estimation follow the CIC VT GUI pattern:
%   - Use ISTEP/TSTEP metadata first, with optional current-waveform fallback.
%   - Estimate phase current by median(Im) in the selected pulse window.
%   - Estimate steady phase voltage by median(Vf) in the same selected window.
%   - Compute baseline-corrected resistance as abs((Vss - Vbaseline) / Iss).

    S = struct();
    S.items = struct([]);
    S.current = [];
    S.isDragging = false;

    fig = uifigure('Name','Gamry VT Steady Resistance GUI','Position',[40 30 1680 980]);

    main = uigridlayout(fig,[1 3]);
    main.ColumnWidth = {430,6,'1x'};
    main.RowHeight = {'1x'};
    main.Padding = [10 10 10 10];
    main.ColumnSpacing = 0;

    sep = uipanel(main,'BackgroundColor',[0.75 0.75 0.75],'BorderType','none');
    sep.Layout.Row = 1;
    sep.Layout.Column = 2;
    sep.ButtonDownFcn = @startDrag;

    leftPanel = uipanel(main,'Title','Controls');
    leftPanel.Layout.Row = 1;
    leftPanel.Layout.Column = 1;

    leftHost = uigridlayout(leftPanel,[1 1]);
    leftHost.RowHeight = {'1x'};
    leftHost.ColumnWidth = {'1x'};
    leftHost.Padding = [8 8 8 8];

    tabs = uitabgroup(leftHost);
    tabs.Layout.Row = 1;
    tabs.Layout.Column = 1;

    tabFA = uitab(tabs,'Title','Files + Analysis');
    layFA = uigridlayout(tabFA,[3 1]);
    % Keep large batches from expanding the file list into settings/actions.
    layFA.RowHeight = {260,'fit','fit'};
    layFA.RowSpacing = 10;
    layFA.Padding = [8 8 8 8];

    tabSR = uitab(tabs,'Title','Summary + Results');
    laySR = uigridlayout(tabSR,[2 1]);
    laySR.RowHeight = {'fit','1x'};
    laySR.RowSpacing = 10;
    laySR.Padding = [8 8 8 8];

    tabLog = uitab(tabs,'Title','Log');
    layLog = uigridlayout(tabLog,[1 1]);
    layLog.RowHeight = {'1x'};
    layLog.Padding = [8 8 8 8];

    pFile = uipanel(layFA,'Title','Files');
    pFile.Layout.Row = 1;
    gf = uigridlayout(pFile,[3 1]);
    gf.RowHeight = {'fit','1x','fit'};
    gf.ColumnWidth = {'1x'};
    gf.Padding = [8 8 8 8];
    gf.RowSpacing = 8;
    gf.ColumnSpacing = 0;

    gbtn = uigridlayout(gf,[2 2]);
    gbtn.Layout.Row = 1;
    gbtn.Layout.Column = 1;
    gbtn.RowHeight = {'fit','fit'};
    gbtn.ColumnWidth = {'1x','1x'};
    gbtn.RowSpacing = 8;
    gbtn.ColumnSpacing = 8;
    gbtn.Padding = [0 0 0 0];

    btnOpen = uibutton(gbtn,'Text','Open DTA file(s)','ButtonPushedFcn',@onOpenFiles);
    btnOpen.Layout.Row = 1; btnOpen.Layout.Column = 1;
    btnOpenFolder = uibutton(gbtn,'Text','Open folder recursively','ButtonPushedFcn',@onOpenFolder);
    btnOpenFolder.Layout.Row = 1; btnOpenFolder.Layout.Column = 2;
    btnClearFiles = uibutton(gbtn,'Text','Clear all','ButtonPushedFcn',@(~,~) clearAllFiles());
    btnClearFiles.Layout.Row = 2; btnClearFiles.Layout.Column = 1;
    btnExport = uibutton(gbtn,'Text','Export results CSV','ButtonPushedFcn',@(~,~) exportResultsCSV());
    btnExport.Layout.Row = 2; btnExport.Layout.Column = 2;

    lbFiles = uilistbox(gf,'Items',{},'Multiselect','off','ValueChangedFcn',@(~,~) onSelectFile());
    lbFiles.Layout.Row = 2;
    lbFiles.Layout.Column = 1;

    txtLoaded = uieditfield(gf,'text','Editable','off','Value','No files loaded');
    txtLoaded.Layout.Row = 3;
    txtLoaded.Layout.Column = 1;

    pSet = uipanel(layFA,'Title','Analysis Settings');
    pSet.Layout.Row = 2;
    gs = uigridlayout(pSet,[3 2]);
    gs.RowHeight = repmat({'fit'},1,3);
    gs.ColumnWidth = {'fit','1x'};
    gs.Padding = [8 8 8 8];
    gs.ColumnSpacing = 8;

    uilabel(gs,'Text','Pulse detection:','HorizontalAlignment','right');
    ddPulseMode = uidropdown(gs, ...
        'Items',{'Metadata first, then auto','Metadata only','Auto from Im only'}, ...
        'Value','Metadata first, then auto', ...
        'ValueChangedFcn',@(~,~) analyzeCurrentFile());
    ddPulseMode.Layout.Row = 1;
    ddPulseMode.Layout.Column = 2;

    uilabel(gs,'Text','Steady window:','HorizontalAlignment','right');
    ddSteadyWindow = uidropdown(gs, ...
        'Items',{'Full pulse median','Center 60% median'}, ...
        'Value','Full pulse median', ...
        'ValueChangedFcn',@(~,~) analyzeCurrentFile());
    ddSteadyWindow.Layout.Row = 2;
    ddSteadyWindow.Layout.Column = 2;

    uilabel(gs,'Text','Resistance voltage:','HorizontalAlignment','right');
    ddVoltageMode = uidropdown(gs, ...
        'Items',{'Baseline-corrected dV/I','Raw Vf/I'}, ...
        'Value','Baseline-corrected dV/I', ...
        'ValueChangedFcn',@(~,~) analyzeCurrentFile());
    ddVoltageMode.Layout.Row = 3;
    ddVoltageMode.Layout.Column = 2;

    pAct = uipanel(layFA,'Title','Plot / Debug');
    pAct.Layout.Row = 3;
    ga = uigridlayout(pAct,[2 3]);
    ga.RowHeight = {'fit','fit'};
    ga.ColumnWidth = {'1x','1x','1x'};
    ga.Padding = [8 8 8 8];
    ga.ColumnSpacing = 8;

    btnReanalyze = uibutton(ga,'Text','Re-analyze file','ButtonPushedFcn',@(~,~) analyzeCurrentFile());
    btnReanalyze.Layout.Row = 1; btnReanalyze.Layout.Column = 1;
    btnRefresh = uibutton(ga,'Text','Refresh plots','ButtonPushedFcn',@(~,~) refreshPlots());
    btnRefresh.Layout.Row = 1; btnRefresh.Layout.Column = 2;
    btnSwap = uibutton(ga,'Text','Swap top / bottom','ButtonPushedFcn',@(~,~) swapPlots());
    btnSwap.Layout.Row = 1; btnSwap.Layout.Column = 3;

    btnReset = uibutton(ga,'Text','Reset axes','ButtonPushedFcn',@(~,~) resetAxes());
    btnReset.Layout.Row = 2; btnReset.Layout.Column = 1;
    cbShowMarkers = uicheckbox(ga,'Text','Show markers','Value',true,'ValueChangedFcn',@(~,~) refreshPlots());
    cbShowMarkers.Layout.Row = 2; cbShowMarkers.Layout.Column = 2;
    cbShowShading = uicheckbox(ga,'Text','Shade windows','Value',true,'ValueChangedFcn',@(~,~) refreshPlots());
    cbShowShading.Layout.Row = 2; cbShowShading.Layout.Column = 3;

    pInfo = uipanel(laySR,'Title','Current File Summary');
    pInfo.Layout.Row = 1;
    gi = uigridlayout(pInfo,[12 2]);
    gi.RowHeight = repmat({'fit'},1,12);
    gi.ColumnWidth = {'fit','1x'};
    gi.Padding = [8 8 8 8];
    gi.ColumnSpacing = 8;

    addInfoRow(gi,1,'Detection:', 'txtDetect');
    addInfoRow(gi,2,'Window:', 'txtWindow');
    addInfoRow(gi,3,'Cathodic I / Vss:', 'txtCathIV');
    addInfoRow(gi,4,'Anodic I / Vss:', 'txtAnodIV');
    addInfoRow(gi,5,'Cathodic baseline:', 'txtCathBase');
    addInfoRow(gi,6,'Anodic baseline:', 'txtAnodBase');
    addInfoRow(gi,7,'Cath baseline window:', 'txtCathBaseWin');
    addInfoRow(gi,8,'Anod baseline window:', 'txtAnodBaseWin');
    addInfoRow(gi,9,'Cathodic R:', 'txtCathR');
    addInfoRow(gi,10,'Anodic R:', 'txtAnodR');
    addInfoRow(gi,11,'Average R:', 'txtAvgR');
    addInfoRow(gi,12,'Status:', 'txtStatus');

    pTab = uipanel(laySR,'Title','Batch Results');
    pTab.Layout.Row = 2;
    gt = uigridlayout(pTab,[1 1]);
    gt.Padding = [8 8 8 8];
    tbl = uitable(gt);
    tbl.ColumnName = {'File','Ic(A)','Ia(A)','Vc_ss(V)','Va_ss(V)','R_cath(ohm)','R_anod(ohm)','R_avg(ohm)','Detection'};
    tbl.Data = cell(0,9);

    pLog = uipanel(layLog,'Title','Log');
    pLog.Layout.Row = 1;
    gl = uigridlayout(pLog,[1 1]);
    gl.Padding = [8 8 8 8];
    txtLog = uitextarea(gl,'Editable','off');
    txtLog.Value = {'GUI started.'};

    rightPanel = uipanel(main,'Title','Plots');
    rightPanel.Layout.Row = 1;
    rightPanel.Layout.Column = 3;

    right = uigridlayout(rightPanel,[4 1]);
    right.RowHeight = {'fit','1x','fit','1x'};
    right.RowSpacing = 10;
    right.Padding = [8 8 8 8];

    pTopCtl = uipanel(right,'Title','Top Plot');
    pTopCtl.Layout.Row = 1;
    gtCtl = uigridlayout(pTopCtl,[1 5]);
    gtCtl.ColumnWidth = {'fit','1x','fit','1x','1x'};
    gtCtl.Padding = [8 6 8 6];
    gtCtl.ColumnSpacing = 8;
    uilabel(gtCtl,'Text','X:','HorizontalAlignment','right');
    ddTopX = uidropdown(gtCtl,'Items',{'Time (s)','Sample #'},'Value','Time (s)','ValueChangedFcn',@(~,~) refreshPlots());
    uilabel(gtCtl,'Text','Y:','HorizontalAlignment','right');
    ddTopY = uidropdown(gtCtl,'Items',{'VT: Vf vs time','IT: Im vs time'},'Value','VT: Vf vs time','ValueChangedFcn',@(~,~) refreshPlots());
    cbTopGrid = uicheckbox(gtCtl,'Text','Grid','Value',true,'ValueChangedFcn',@(~,~) refreshPlots());

    axTop = uiaxes(right);
    axTop.Layout.Row = 2;
    title(axTop,'Top Plot');
    disableAxesInteractivity(axTop);

    pBotCtl = uipanel(right,'Title','Bottom Plot');
    pBotCtl.Layout.Row = 3;
    gbCtl = uigridlayout(pBotCtl,[1 5]);
    gbCtl.ColumnWidth = {'fit','1x','fit','1x','1x'};
    gbCtl.Padding = [8 6 8 6];
    gbCtl.ColumnSpacing = 8;
    uilabel(gbCtl,'Text','X:','HorizontalAlignment','right');
    ddBotX = uidropdown(gbCtl,'Items',{'Time (s)','Sample #'},'Value','Time (s)','ValueChangedFcn',@(~,~) refreshPlots());
    uilabel(gbCtl,'Text','Y:','HorizontalAlignment','right');
    ddBotY = uidropdown(gbCtl,'Items',{'VT: Vf vs time','IT: Im vs time'},'Value','IT: Im vs time','ValueChangedFcn',@(~,~) refreshPlots());
    cbBotGrid = uicheckbox(gbCtl,'Text','Grid','Value',true,'ValueChangedFcn',@(~,~) refreshPlots());

    axBottom = uiaxes(right);
    axBottom.Layout.Row = 4;
    title(axBottom,'Bottom Plot');
    disableAxesInteractivity(axBottom);

    function addInfoRow(parent,row,labelText,fieldName)
        lbl = uilabel(parent,'Text',labelText,'HorizontalAlignment','right');
        lbl.Layout.Row = row;
        lbl.Layout.Column = 1;
        h = uieditfield(parent,'text','Editable','off','Value','-');
        h.Layout.Row = row;
        h.Layout.Column = 2;
        S.(fieldName) = h;
    end

    function onOpenFiles(~,~)
        [files,path] = uigetfile({'*.DTA;*.dta','Gamry DTA files (*.DTA)'}, ...
            'Select Gamry DTA file(s)','MultiSelect','on');
        if isequal(files,0)
            return;
        end
        if ischar(files)
            files = {files};
        end
        filepaths = cellfun(@(f) fullfile(path,f), files, 'UniformOutput', false);
        addFiles(filepaths);
    end

    function onOpenFolder(~,~)
        folder = uigetdir(pwd,'Select folder containing DTA files');
        if isequal(folder,0)
            return;
        end
        filepaths = findDTAFilesRecursive(folder);
        if isempty(filepaths)
            uialert(fig,'No .DTA files found in the selected folder.','Open folder');
            return;
        end
        addFiles(filepaths);
    end

    function addFiles(filepaths)
        for k = 1:numel(filepaths)
            fp = filepaths{k};
            if any(arrayfun(@(x) strcmp(x.filepath, fp), S.items))
                addLog(['Skipped duplicate: ' fp]);
                continue;
            end
            try
                item = loadAndAnalyzeFile(fp);
                if isempty(S.items)
                    S.items = item;
                else
                    S.items(end+1) = item; %#ok<AGROW>
                end
                addLog(['Loaded: ' fp]);
            catch ME
                addLog(sprintf('Failed to load %s: %s', fp, ME.message));
            end
        end
        if ~isempty(S.items) && isempty(S.current)
            S.current = 1;
        end
        refreshFileList();
        refreshBatchTable();
        refreshResultsSummary();
        refreshPlots();
    end

    function item = loadAndAnalyzeFile(filepath)
        [~,name,ext] = fileparts(filepath);
        item = struct();
        item.filepath = filepath;
        item.name = [name ext];
        item.meta = [];
        item.tables = [];
        item.logmsg = {};
        item.analysis = [];

        [item.meta, item.tables, item.logmsg] = parseGamryChronoDTA(filepath);
        for ii = 1:numel(item.logmsg)
            addLog(item.logmsg{ii});
        end
        item = analyzeItem(item);
    end

    function analyzeCurrentFile()
        if isempty(S.items) || isempty(S.current) || S.current < 1 || S.current > numel(S.items)
            refreshResultsSummary();
            refreshPlots();
            return;
        end
        S.items(S.current) = analyzeItem(S.items(S.current));
        refreshBatchTable();
        refreshResultsSummary();
        refreshPlots();
    end

    function item = analyzeItem(item)
        A = struct();
        A.ok = false;
        A.message = '';
        A.windowMode = ddSteadyWindow.Value;
        A.voltageMode = ddVoltageMode.Value;

        [curve, okCurve, msgCurve] = getMainCurve(item.tables);
        if ~okCurve
            A.message = msgCurve;
            item.analysis = A;
            addLog(sprintf('%s: %s', item.name, msgCurve));
            return;
        end

        t = getColByName(curve,'T');
        Vf = getColByName(curve,'Vf');
        Im = getColByName(curve,'Im');
        pt = getColByName(curve,'Pt');
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
            item.analysis = A;
            return;
        end

        A.t = t;
        A.Vf = Vf;
        A.Im = Im;
        A.pt = pt;

        [pulse, pulseMsg] = detectPulses(item.meta, t, Im, ddPulseMode.Value);
        A.pulse = pulse;
        A.detectMode = pulse.method;
        A.detectMsg = pulseMsg;
        if ~pulse.ok
            A.message = pulseMsg;
            item.analysis = A;
            addLog(sprintf('%s: %s', item.name, pulseMsg));
            return;
        end

        [cStart, cEnd] = steadyBounds(pulse.cath_start, pulse.cath_end, A.windowMode);
        [aStart, aEnd] = steadyBounds(pulse.anod_start, pulse.anod_end, A.windowMode);
        cathMask = t >= cStart & t <= cEnd;
        anodMask = t >= aStart & t <= aEnd;
        if nnz(cathMask) < 2 || nnz(anodMask) < 2
            A.message = 'Steady windows are too short after pulse detection.';
            item.analysis = A;
            return;
        end

        A.cathMask = cathMask;
        A.anodMask = anodMask;
        A.cathSteadyStart = cStart;
        A.cathSteadyEnd = cEnd;
        A.anodSteadyStart = aStart;
        A.anodSteadyEnd = aEnd;

        A.Ic_est_A = median(Im(cathMask),'omitnan');
        A.Ia_est_A = median(Im(anodMask),'omitnan');
        A.Vc_ss_V = median(Vf(cathMask),'omitnan');
        A.Va_ss_V = median(Vf(anodMask),'omitnan');

        A.cathBaselineStart = pulse.pre_start;
        A.cathBaselineEnd = pulse.pre_end;
        A.anodBaselineStart = pulse.post_start;
        A.anodBaselineEnd = pulse.post_end;
        A.cathBaselineWindow_s = max(0, A.cathBaselineEnd - A.cathBaselineStart);
        A.anodBaselineWindow_s = max(0, A.anodBaselineEnd - A.anodBaselineStart);

        A.Vc_baseline_V = median_in_window(t, Vf, pulse.pre_start, pulse.pre_end);
        A.Va_baseline_V = median_in_window(t, Vf, pulse.post_start, pulse.post_end);
        if ~isfinite(A.Vc_baseline_V)
            A.Vc_baseline_V = 0;
        end
        if ~isfinite(A.Va_baseline_V)
            A.Va_baseline_V = chooseFinite(A.Vc_baseline_V, 0);
        end

        A.dVc_V = A.Vc_ss_V - A.Vc_baseline_V;
        A.dVa_V = A.Va_ss_V - A.Va_baseline_V;
        A.Rc_raw_ohm = safeDivide(A.Vc_ss_V, A.Ic_est_A);
        A.Ra_raw_ohm = safeDivide(A.Va_ss_V, A.Ia_est_A);
        A.Rc_dV_ohm = safeDivide(A.dVc_V, A.Ic_est_A);
        A.Ra_dV_ohm = safeDivide(A.dVa_V, A.Ia_est_A);

        if strcmp(A.voltageMode,'Raw Vf/I')
            A.Rc_ohm = A.Rc_raw_ohm;
            A.Ra_ohm = A.Ra_raw_ohm;
        else
            A.Rc_ohm = A.Rc_dV_ohm;
            A.Ra_ohm = A.Ra_dV_ohm;
        end
        A.Rc_abs_ohm = abs(A.Rc_ohm);
        A.Ra_abs_ohm = abs(A.Ra_ohm);
        A.Ravg_abs_ohm = mean([A.Rc_abs_ohm, A.Ra_abs_ohm],'omitnan');

        A.ok = isfinite(A.Ravg_abs_ohm);
        if A.ok
            A.message = 'OK';
            addLog(sprintf('%s: Rc=%.6g ohm, Ra=%.6g ohm, Ravg=%.6g ohm', ...
                item.name, A.Rc_abs_ohm, A.Ra_abs_ohm, A.Ravg_abs_ohm));
        else
            A.message = 'Resistance could not be computed; check current and pulse detection.';
            addLog(sprintf('%s: %s', item.name, A.message));
        end
        item.analysis = A;
    end

    function [t1, t2] = steadyBounds(p1, p2, modeText)
        t1 = p1;
        t2 = p2;
        if strcmp(modeText,'Center 60% median') && isfinite(p1) && isfinite(p2) && p2 > p1
            dt = p2 - p1;
            t1 = p1 + 0.20 * dt;
            t2 = p1 + 0.80 * dt;
        end
    end

    function [pulse, msg] = detectPulses(meta, t, Im, modeText)
        pulse = emptyPulse();
        msg = 'Pulse detection failed.';
        switch modeText
            case 'Metadata only'
                [pulse, ~, msg] = pulsesFromMetadata(meta, t);
            case 'Auto from Im only'
                [pulse, ~, msg] = pulsesFromCurrent(t, Im);
            otherwise
                [pulse, okM, msgM] = pulsesFromMetadata(meta, t);
                if okM
                    msg = msgM;
                    return;
                end
                [pulse, okA, msgA] = pulsesFromCurrent(t, Im);
                if okA
                    msg = sprintf('%s | fallback success: %s', msgM, msgA);
                else
                    msg = sprintf('%s | %s', msgM, msgA);
                end
        end
    end

    function [pulse, ok, msg] = pulsesFromMetadata(meta, t)
        pulse = emptyPulse();
        ok = false;
        if isempty(meta) || ~isfield(meta,'steps') || isempty(meta.steps)
            msg = 'Metadata pulse detection: no ISTEP/TSTEP or VSTEP/TSTEP steps found.';
            return;
        end

        steps = meta.steps;
        Ivals = [steps.I];
        Vvals = [steps.V];
        Tvals = [steps.T];
        if all(~isfinite(Tvals))
            msg = 'Metadata pulse detection: invalid step values.';
            return;
        end

        stepMode = '';
        stepVals = [];
        if any(isfinite(Ivals))
            stepVals = Ivals;
            stepMode = 'current';
        elseif any(isfinite(Vvals))
            stepVals = Vvals;
            stepMode = 'voltage';
        else
            msg = 'Metadata pulse detection: neither current nor voltage step values were found.';
            return;
        end

        [minStep, idxCath] = min(stepVals);
        [maxStep, idxAnod] = max(stepVals);
        if ~isfinite(minStep) || ~isfinite(maxStep) || minStep >= 0 || maxStep <= 0
            msg = sprintf('Metadata pulse detection: could not find both negative and positive %s steps.', stepMode);
            return;
        end
        if idxAnod < idxCath
            msg = sprintf('Metadata pulse detection: positive %s step appears before negative step.', stepMode);
            return;
        end

        t0 = 0;
        starts = zeros(size(Tvals));
        ends = zeros(size(Tvals));
        for k = 1:numel(Tvals)
            starts(k) = t0;
            ends(k) = t0 + Tvals(k);
            t0 = ends(k);
        end

        pulse.ok = true;
        pulse.method = ['metadata-' stepMode];
        pulse.cath_start = starts(idxCath);
        pulse.cath_end = ends(idxCath);
        pulse.anod_start = starts(idxAnod);
        pulse.anod_end = ends(idxAnod);
        if strcmp(stepMode,'current')
            pulse.Ic_nominal = Ivals(idxCath);
            pulse.Ia_nominal = Ivals(idxAnod);
        else
            pulse.Ic_nominal = NaN;
            pulse.Ia_nominal = NaN;
        end

        if idxCath > 1
            pulse.pre_start = starts(idxCath-1);
            pulse.pre_end = ends(idxCath-1);
        else
            pulse.pre_start = t(1);
            pulse.pre_end = pulse.cath_start;
        end

        pulse.gap_start = pulse.cath_end;
        pulse.gap_end = pulse.anod_start;
        if idxAnod < numel(Tvals)
            pulse.post_start = starts(idxAnod+1);
            pulse.post_end = ends(idxAnod+1);
        else
            pulse.post_start = pulse.anod_end;
            pulse.post_end = t(end);
        end

        ok = true;
        msg = sprintf('Metadata pulse detection OK (%s-controlled): cath step %d, anod step %d.', ...
            stepMode, idxCath, idxAnod);
    end

    function [pulse, ok, msg] = pulsesFromCurrent(t, Im)
        pulse = emptyPulse();
        ok = false;
        Iabs = abs(Im);
        thr = max(1e-12, 0.25 * max(Iabs));
        cathSeg = contiguousSegments(Im <= -thr);
        anodSeg = contiguousSegments(Im >= thr);
        if isempty(cathSeg) || isempty(anodSeg)
            msg = 'Auto pulse detection: could not find both cathodic and anodic segments.';
            return;
        end

        cathLen = cathSeg(:,2) - cathSeg(:,1) + 1;
        [~, ic] = max(cathLen);
        cseg = cathSeg(ic,:);
        asegCandidates = anodSeg(anodSeg(:,1) > cseg(2), :);
        if isempty(asegCandidates)
            msg = 'Auto pulse detection: found cathodic segment but no later anodic segment.';
            return;
        end
        anodLen = asegCandidates(:,2) - asegCandidates(:,1) + 1;
        [~, ia] = max(anodLen);
        aseg = asegCandidates(ia,:);

        pulse.ok = true;
        pulse.method = 'auto-from-Im';
        pulse.cath_start = t(cseg(1));
        pulse.cath_end = t(cseg(2));
        pulse.anod_start = t(aseg(1));
        pulse.anod_end = t(aseg(2));
        pulse.Ic_nominal = median(Im(cseg(1):cseg(2)),'omitnan');
        pulse.Ia_nominal = median(Im(aseg(1):aseg(2)),'omitnan');
        pulse.pre_start = t(1);
        pulse.pre_end = pulse.cath_start;
        pulse.gap_start = pulse.cath_end;
        pulse.gap_end = pulse.anod_start;
        pulse.post_start = pulse.anod_end;
        pulse.post_end = t(end);

        ok = true;
        msg = sprintf('Auto pulse detection OK: cath [%d %d], anod [%d %d].', cseg(1), cseg(2), aseg(1), aseg(2));
    end

    function pulse = emptyPulse()
        pulse = struct('ok',false,'method','-', ...
            'cath_start',NaN,'cath_end',NaN,'anod_start',NaN,'anod_end',NaN, ...
            'Ic_nominal',NaN,'Ia_nominal',NaN, ...
            'pre_start',NaN,'pre_end',NaN,'gap_start',NaN,'gap_end',NaN,'post_start',NaN,'post_end',NaN);
    end

    function onSelectFile()
        if isempty(lbFiles.Items)
            S.current = [];
            resetAxesToDefaultState();
            refreshResultsSummary();
            refreshPlots();
            return;
        end
        idx = find(strcmp(lbFiles.Items, lbFiles.Value),1);
        if isempty(idx)
            S.current = [];
        else
            S.current = idx;
        end
        restoreDefaultPlotSelections();
        resetAxesToDefaultState();
        refreshResultsSummary();
        refreshPlots();
    end

    function clearAllFiles()
        S.items = struct([]);
        S.current = [];
        restoreDefaultPlotSelections();
        resetAxesToDefaultState();
        refreshFileList();
        refreshBatchTable();
        refreshResultsSummary();
        refreshPlots();
        addLog('Cleared all files.');
    end

    function refreshFileList()
        if isempty(S.items)
            lbFiles.Items = {};
            lbFiles.Value = {};
            txtLoaded.Value = 'No files loaded';
            return;
        end
        names = arrayfun(@(x) x.name, S.items, 'UniformOutput', false);
        lbFiles.Items = names;
        if isempty(S.current) || S.current < 1 || S.current > numel(S.items)
            S.current = 1;
        end
        lbFiles.Value = names{S.current};
        txtLoaded.Value = sprintf('%d file(s) loaded', numel(S.items));
    end

    function refreshBatchTable()
        if isempty(S.items)
            tbl.Data = cell(0,9);
            return;
        end
        C = cell(numel(S.items),9);
        for i = 1:numel(S.items)
            it = S.items(i);
            C{i,1} = it.name;
            if isempty(it.analysis) || ~isfield(it.analysis,'ok') || ~it.analysis.ok
                C{i,2} = NaN;
                C{i,3} = NaN;
                C{i,4} = NaN;
                C{i,5} = NaN;
                C{i,6} = NaN;
                C{i,7} = NaN;
                C{i,8} = NaN;
                C{i,9} = 'parse/analyze failed';
            else
                A = it.analysis;
                C{i,2} = A.Ic_est_A;
                C{i,3} = A.Ia_est_A;
                C{i,4} = A.Vc_ss_V;
                C{i,5} = A.Va_ss_V;
                C{i,6} = A.Rc_abs_ohm;
                C{i,7} = A.Ra_abs_ohm;
                C{i,8} = A.Ravg_abs_ohm;
                C{i,9} = A.detectMode;
            end
        end
        tbl.Data = C;
    end

    function refreshResultsSummary()
        S.txtDetect.Value = '-';
        S.txtWindow.Value = '-';
        S.txtCathIV.Value = '-';
        S.txtAnodIV.Value = '-';
        S.txtCathBase.Value = '-';
        S.txtAnodBase.Value = '-';
        S.txtCathBaseWin.Value = '-';
        S.txtAnodBaseWin.Value = '-';
        S.txtCathR.Value = '-';
        S.txtAnodR.Value = '-';
        S.txtAvgR.Value = '-';
        S.txtStatus.Value = '-';

        if isempty(S.items) || isempty(S.current) || S.current < 1 || S.current > numel(S.items)
            return;
        end
        it = S.items(S.current);
        if isempty(it.analysis) || ~it.analysis.ok
            if ~isempty(it.analysis) && isfield(it.analysis,'message')
                S.txtStatus.Value = it.analysis.message;
            else
                S.txtStatus.Value = 'No valid analysis';
            end
            return;
        end

        A = it.analysis;
        S.txtDetect.Value = sprintf('%s | %s', A.detectMode, A.detectMsg);
        S.txtWindow.Value = sprintf('%s | %s', A.windowMode, A.voltageMode);
        S.txtCathIV.Value = sprintf('I=%.6e A | Vss=%.6f V | dV=%.6f V', A.Ic_est_A, A.Vc_ss_V, A.dVc_V);
        S.txtAnodIV.Value = sprintf('I=%.6e A | Vss=%.6f V | dV=%.6f V', A.Ia_est_A, A.Va_ss_V, A.dVa_V);
        S.txtCathBase.Value = sprintf('%.6f V', A.Vc_baseline_V);
        S.txtAnodBase.Value = sprintf('%.6f V', A.Va_baseline_V);
        S.txtCathBaseWin.Value = formatDurationUs(A.cathBaselineWindow_s);
        S.txtAnodBaseWin.Value = formatDurationUs(A.anodBaselineWindow_s);
        S.txtCathR.Value = sprintf('%.6g ohm (signed %.6g)', A.Rc_abs_ohm, A.Rc_ohm);
        S.txtAnodR.Value = sprintf('%.6g ohm (signed %.6g)', A.Ra_abs_ohm, A.Ra_ohm);
        S.txtAvgR.Value = sprintf('%.6g ohm', A.Ravg_abs_ohm);
        S.txtStatus.Value = A.message;
    end

    function refreshPlots()
        clearAxisObjects(axTop);
        clearAxisObjects(axBottom);
        if isempty(S.items) || isempty(S.current) || S.current < 1 || S.current > numel(S.items)
            title(axTop,'Top Plot');
            title(axBottom,'Bottom Plot');
            return;
        end

        it = S.items(S.current);
        if isempty(it.analysis) || ~it.analysis.ok
            title(axTop,'Top Plot');
            title(axBottom,'Bottom Plot');
            text(axTop,0.5,0.5,'No valid analysis','Units','normalized','HorizontalAlignment','center');
            return;
        end
        A = it.analysis;
        plotOneAxis(axTop, A, ddTopX.Value, ddTopY.Value, cbTopGrid.Value);
        plotOneAxis(axBottom, A, ddBotX.Value, ddBotY.Value, cbBotGrid.Value);
    end

    function plotOneAxis(ax, A, xChoice, yChoice, showGrid)
        if strcmp(xChoice,'Sample #')
            x = A.pt;
            xlab = 'Sample #';
            cathStartX = interp1_safe(A.t, A.pt, A.pulse.cath_start);
            cathEndX = interp1_safe(A.t, A.pt, A.pulse.cath_end);
            anodStartX = interp1_safe(A.t, A.pt, A.pulse.anod_start);
            anodEndX = interp1_safe(A.t, A.pt, A.pulse.anod_end);
            cathBaseStartX = interp1_safe(A.t, A.pt, A.pulse.pre_start);
            cathBaseEndX = interp1_safe(A.t, A.pt, A.pulse.pre_end);
            anodBaseStartX = interp1_safe(A.t, A.pt, A.anodBaselineStart);
            anodBaseEndX = interp1_safe(A.t, A.pt, A.anodBaselineEnd);
            cSteadyStartX = interp1_safe(A.t, A.pt, A.cathSteadyStart);
            cSteadyEndX = interp1_safe(A.t, A.pt, A.cathSteadyEnd);
            aSteadyStartX = interp1_safe(A.t, A.pt, A.anodSteadyStart);
            aSteadyEndX = interp1_safe(A.t, A.pt, A.anodSteadyEnd);
        else
            x = A.t;
            xlab = 'Time (s)';
            cathStartX = A.pulse.cath_start;
            cathEndX = A.pulse.cath_end;
            anodStartX = A.pulse.anod_start;
            anodEndX = A.pulse.anod_end;
            cathBaseStartX = A.pulse.pre_start;
            cathBaseEndX = A.pulse.pre_end;
            anodBaseStartX = A.anodBaselineStart;
            anodBaseEndX = A.anodBaselineEnd;
            cSteadyStartX = A.cathSteadyStart;
            cSteadyEndX = A.cathSteadyEnd;
            aSteadyStartX = A.anodSteadyStart;
            aSteadyEndX = A.anodSteadyEnd;
        end

        if startsWith(yChoice,'VT')
            plot(ax, x, A.Vf, 'LineWidth',1.25, 'Color',[0 0.4470 0.7410]);
            ylab = 'Vf (V vs Ref.)';
            ttl = sprintf('%s | VT | Ravg = %.6g ohm', itName(), A.Ravg_abs_ohm);
            hold(ax,'on');
        else
            plot(ax, x, A.Im, 'LineWidth',1.25, 'Color',[0.8500 0.3250 0.0980]);
            ylab = 'Im (A)';
            ttl = sprintf('%s | IT | Ic %.4g A, Ia %.4g A', itName(), A.Ic_est_A, A.Ia_est_A);
            hold(ax,'on');
        end

        if cbShowShading.Value
            shadeWindow(ax, cathStartX, cathEndX, [0.90 0.95 1.00], 0.12);
            shadeWindow(ax, anodStartX, anodEndX, [1.00 0.94 0.88], 0.12);
            shadeWindow(ax, cSteadyStartX, cSteadyEndX, [0.65 0.82 1.00], 0.22);
            shadeWindow(ax, aSteadyStartX, aSteadyEndX, [1.00 0.75 0.55], 0.22);
        end
        if cbShowMarkers.Value
            xline(ax, cathStartX, ':', 'Cath start','Color',[0.2 0.4 0.8]);
            xline(ax, cathEndX, ':', 'Cath end','Color',[0.2 0.4 0.8]);
            xline(ax, anodStartX, ':', 'Anod start','Color',[0.8 0.4 0.2]);
            xline(ax, anodEndX, ':', 'Anod end','Color',[0.8 0.4 0.2]);
            if startsWith(yChoice,'VT')
                addResistanceVTAnnotations(ax, A, cathBaseStartX, cathBaseEndX, anodBaseStartX, anodBaseEndX, ...
                    cSteadyStartX, cSteadyEndX, aSteadyStartX, aSteadyEndX, cathStartX, cathEndX, anodStartX, anodEndX);
            else
                addResistanceITAnnotations(ax, A, cSteadyStartX, cSteadyEndX, aSteadyStartX, aSteadyEndX, ...
                    cathStartX, cathEndX, anodStartX, anodEndX);
            end
        end
        hold(ax,'off');

        title(ax, ttl, 'Interpreter','none');
        xlabel(ax, xlab);
        ylabel(ax, ylab);
        grid(ax, ternary(showGrid,'on','off'));
    end

    function nm = itName()
        if isempty(S.items) || isempty(S.current)
            nm = 'file';
        else
            nm = S.items(S.current).name;
        end
    end

    function swapPlots()
        topX = ddTopX.Value;
        topY = ddTopY.Value;
        botX = ddBotX.Value;
        botY = ddBotY.Value;
        ddTopX.Value = botX;
        ddTopY.Value = botY;
        ddBotX.Value = topX;
        ddBotY.Value = topY;
        refreshPlots();
    end

    function resetAxes()
        resetAxesToDefaultState();
        refreshPlots();
    end

    function restoreDefaultPlotSelections()
        ddTopX.Value = 'Time (s)';
        ddTopY.Value = 'VT: Vf vs time';
        ddBotX.Value = 'Time (s)';
        ddBotY.Value = 'IT: Im vs time';
    end

    function resetAxesToDefaultState()
        hardResetAxis(axTop, 'Top Plot');
        hardResetAxis(axBottom, 'Bottom Plot');
    end

    function hardResetAxis(ax, ttl)
        cla(ax, 'reset');
        ax.NextPlot = 'replace';
        ax.XLimMode = 'auto';
        ax.YLimMode = 'auto';
        title(ax, ttl);
        xlabel(ax, '');
        ylabel(ax, '');
        grid(ax, 'off');
        box(ax, 'on');
    end

    function clearAxisObjects(ax)
        if ~isempty(ax.Children)
            delete(ax.Children);
        end
        hold(ax, 'off');
        ax.XLimMode = 'auto';
        ax.YLimMode = 'auto';
    end

    function exportResultsCSV()
        if isempty(S.items)
            uialert(fig,'No results to export.','Export');
            return;
        end
        [f,p] = uiputfile('vt_steady_resistance_results.csv','Save results CSV');
        if isequal(f,0)
            return;
        end
        out = fullfile(p,f);
        fid = fopen(out,'w');
        if fid < 0
            uialert(fig,'Could not open file for writing.','Export');
            return;
        end
        fprintf(fid,'File,Ic_A,Ia_A,Vc_ss_V,Va_ss_V,Vc_baseline_V,Va_baseline_V,dVc_V,dVa_V,Rc_bc_ohm,Ra_bc_ohm,Ravg_bc_ohm,WindowMode,Detection,Status\n');
        for i = 1:numel(S.items)
            it = S.items(i);
            if isempty(it.analysis) || ~it.analysis.ok
                msg = '';
                if ~isempty(it.analysis) && isfield(it.analysis,'message')
                    msg = it.analysis.message;
                end
                nanv = NaN;
                fprintf(fid,'"%s",%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,"%s","%s","%s"\n', ...
                    csvEscape(it.name), nanv, nanv, nanv, nanv, nanv, nanv, nanv, nanv, ...
                    nanv, nanv, nanv, '', 'failed', csvEscape(msg));
            else
                A = it.analysis;
                Rc_bc = abs(A.Rc_dV_ohm);
                Ra_bc = abs(A.Ra_dV_ohm);
                Ravg_bc = mean([Rc_bc, Ra_bc], 'omitnan');
                fprintf(fid,'"%s",%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,"%s","%s","%s"\n', ...
                    csvEscape(it.name), A.Ic_est_A, A.Ia_est_A, A.Vc_ss_V, A.Va_ss_V, ...
                    A.Vc_baseline_V, A.Va_baseline_V, A.dVc_V, A.dVa_V, Rc_bc, Ra_bc, Ravg_bc, ...
                    csvEscape(A.windowMode), csvEscape(A.detectMode), csvEscape(A.message));
            end
        end
        fclose(fid);
        addLog(['Exported CSV: ' out]);
    end

    function startDrag(~,~)
        S.isDragging = true;
        fig.WindowButtonMotionFcn = @doDrag;
        fig.WindowButtonUpFcn = @stopDrag;
        fig.Pointer = 'left';
    end

    function doDrag(~,~)
        if ~S.isDragging
            return;
        end
        cp = fig.CurrentPoint;
        pad = main.Padding;
        newW = cp(1) - pad(1);
        minW = 260;
        maxW = max(420, fig.Position(3) - 380);
        newW = min(maxW, max(minW, newW));
        main.ColumnWidth = {newW,6,'1x'};
    end

    function stopDrag(~,~)
        S.isDragging = false;
        fig.WindowButtonMotionFcn = '';
        fig.WindowButtonUpFcn = '';
        fig.Pointer = 'arrow';
    end

    function addLog(msg)
        ts = datestr(now,'HH:MM:SS');
        old = txtLog.Value;
        old{end+1} = sprintf('[%s] %s', ts, char(msg));
        txtLog.Value = old;
        drawnow limitrate
    end

    function disableAxesInteractivity(ax)
        try
            disableDefaultInteractivity(ax);
        catch
        end
        try
            ax.Interactions = [];
        catch
        end
        try
            ax.Toolbar.Visible = 'off';
        catch
        end
    end
end

function [meta, tables, logmsg] = parseGamryChronoDTA(filepath)
    txt = fileread(filepath);
    txt = erase(txt, char(13));
    lines = splitlines(string(txt));
    lines = cellstr(lines);

    meta = struct();
    meta.filepath = filepath;
    meta.area_cm2 = NaN;
    meta.sampleTime_s = NaN;
    meta.steps = struct('idx',{},'I',{},'V',{},'T',{});
    tables = struct('name',{},'headers',{},'units',{},'data',{},'numericMask',{});
    logmsg = {};

    nLines = numel(lines);
    logmsg{end+1} = sprintf('Parsing DTA: %s', filepath);

    stepI = containers.Map('KeyType','int32','ValueType','double');
    stepV = containers.Map('KeyType','int32','ValueType','double');
    stepT = containers.Map('KeyType','int32','ValueType','double');

    for i = 1:nLines
        tok = splitTabs(lines{i});
        if numel(tok) < 3
            continue;
        end
        key = strtrim(tok{1});
        valueStr = tok{3};
        valueNum = str2double(valueStr);

        switch upper(key)
            case 'AREA'
                if isfinite(valueNum), meta.area_cm2 = valueNum; end
            case 'SAMPLETIME'
                if isfinite(valueNum), meta.sampleTime_s = valueNum; end
        end

        rI = regexp(key,'^ISTEP(\d+)$','tokens','once');
        if ~isempty(rI)
            idx = int32(str2double(rI{1}));
            if isfinite(valueNum), stepI(idx) = valueNum; end
        end
        rV = regexp(key,'^VSTEP(\d+)$','tokens','once');
        if ~isempty(rV)
            idx = int32(str2double(rV{1}));
            if isfinite(valueNum), stepV(idx) = valueNum; end
        end
        rT = regexp(key,'^TSTEP(\d+)$','tokens','once');
        if ~isempty(rT)
            idx = int32(str2double(rT{1}));
            if isfinite(valueNum), stepT(idx) = valueNum; end
        end
    end

    allIdx = unique([cell2mat(keys(stepI)), cell2mat(keys(stepV)), cell2mat(keys(stepT))]);
    allIdx = sort(allIdx);
    for k = 1:numel(allIdx)
        idx = allIdx(k);
        I = NaN;
        V = NaN;
        T = NaN;
        if isKey(stepI,idx), I = stepI(idx); end
        if isKey(stepV,idx), V = stepV(idx); end
        if isKey(stepT,idx), T = stepT(idx); end
        meta.steps(end+1) = struct('idx',double(idx),'I',I,'V',V,'T',T); %#ok<AGROW>
    end

    if ~isempty(meta.steps)
        if any(isfinite([meta.steps.I]))
            logmsg{end+1} = sprintf('Found %d ISTEP/TSTEP step(s).', numel(meta.steps));
        elseif any(isfinite([meta.steps.V]))
            logmsg{end+1} = sprintf('Found %d VSTEP/TSTEP step(s).', numel(meta.steps));
        else
            logmsg{end+1} = sprintf('Found %d step(s) with timing only.', numel(meta.steps));
        end
    else
        logmsg{end+1} = 'No ISTEP/TSTEP or VSTEP/TSTEP sequence found.';
    end

    i = 1;
    while i <= nLines
        tok = splitTabs(lines{i});
        if numel(tok) >= 3 && strcmpi(tok{2},'TABLE')
            name = tok{1};
            iHeader = nextNonEmpty(lines, i+1);
            iUnits = nextNonEmpty(lines, iHeader+1);
            if isnan(iHeader) || isnan(iUnits)
                i = i + 1;
                continue;
            end

            headers = splitTabs(lines{iHeader});
            units = splitTabs(lines{iUnits});
            if isDataLike(units)
                dataStart = iUnits;
                units = repmat({''}, size(headers));
            else
                dataStart = nextNonEmpty(lines, iUnits+1);
            end

            raw = [];
            j = dataStart;
            while j <= nLines
                tokj = splitTabs(lines{j});
                if isempty(tokj)
                    j = j + 1;
                    continue;
                end
                if numel(tokj) >= 3 && strcmpi(tokj{2},'TABLE')
                    break;
                end
                row = nan(1, numel(headers));
                nKeep = min(numel(tokj), numel(headers));
                anyNumeric = false;
                for c = 1:nKeep
                    v = str2double(tokj{c});
                    if ~isnan(v)
                        row(c) = v;
                        anyNumeric = true;
                    end
                end
                if anyNumeric
                    raw(end+1,:) = row; %#ok<AGROW>
                end
                j = j + 1;
            end

            if ~isempty(raw)
                numericMask = any(~isnan(raw),1);
                tables(end+1).name = name; %#ok<AGROW>
                tables(end).headers = headers;
                tables(end).units = units;
                tables(end).data = raw;
                tables(end).numericMask = numericMask;
                logmsg{end+1} = sprintf('Table %s parsed: %d rows x %d cols.', name, size(raw,1), size(raw,2));
            else
                logmsg{end+1} = sprintf('Table %s found but no numeric rows.', name);
            end
            i = j;
        else
            i = i + 1;
        end
    end

    if isempty(tables)
        error('No numeric TABLE section was parsed from this DTA file.');
    end
end

function [curve, ok, msg] = getMainCurve(tables)
    ok = false;
    msg = 'Main transient table not found.';
    curve = struct();
    if isempty(tables)
        return;
    end

    idxMain = [];
    for i = 1:numel(tables)
        nm = lower(strtrim(tables(i).name));
        if strcmp(nm,'curve') || strcmp(nm,'curve1')
            idxMain = i;
            break;
        end
    end
    if isempty(idxMain)
        for i = 1:numel(tables)
            h = lower(tables(i).headers);
            if any(strcmp(h,'t')) && any(strcmp(h,'vf')) && any(strcmp(h,'im'))
                idxMain = i;
                break;
            end
        end
    end
    if isempty(idxMain)
        return;
    end
    curve = tables(idxMain);
    ok = true;
    msg = sprintf('Using table: %s', curve.name);
end

function filepaths = findDTAFilesRecursive(rootDir)
    entries = dir(rootDir);
    filepaths = {};
    for i = 1:numel(entries)
        name = entries(i).name;
        if strcmp(name,'.') || strcmp(name,'..')
            continue;
        end
        fullpath = fullfile(entries(i).folder, name);
        if entries(i).isdir
            subpaths = findDTAFilesRecursive(fullpath);
            if ~isempty(subpaths)
                filepaths = [filepaths, subpaths]; %#ok<AGROW>
            end
        else
            [~,~,ext] = fileparts(name);
            if strcmpi(ext,'.dta')
                filepaths{end+1} = fullpath; %#ok<AGROW>
            end
        end
    end
end

function idx = nearestIndex(x, xq)
    [~, idx] = min(abs(x - xq));
end

function v = interp1_safe(x, y, xq)
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

function m = median_in_window(t, y, t1, t2)
    if ~isfinite(t1) || ~isfinite(t2) || t2 < t1
        m = NaN;
        return;
    end
    mask = t >= t1 & t <= t2;
    if ~any(mask)
        m = NaN;
    else
        m = median(y(mask),'omitnan');
    end
end

function seg = contiguousSegments(mask)
    mask = mask(:).';
    d = diff([false, mask, false]);
    starts = find(d == 1);
    ends = find(d == -1) - 1;
    seg = [starts(:), ends(:)];
end

function out = ternary(cond, a, b)
    if cond
        out = a;
    else
        out = b;
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

function q = safeDivide(a, b)
    if ~isscalar(a) || ~isscalar(b) || ~isfinite(a) || ~isfinite(b) || abs(b) < eps
        q = NaN;
    else
        q = a / b;
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

function col = getColByName(tbl, name)
    col = [];
    if isempty(tbl) || ~isfield(tbl,'headers') || ~isfield(tbl,'data')
        return;
    end
    headers = tbl.headers;
    idx = find(strcmpi(headers, name), 1);
    if isempty(idx)
        return;
    end
    col = tbl.data(:,idx);
end

function tok = splitTabs(line)
    if isstring(line)
        line = char(line);
    end
    if isempty(strtrim(line))
        tok = {};
        return;
    end
    tok = regexp(line,'\t','split');
    tok = cellfun(@strtrim, tok, 'UniformOutput', false);
    tok = tok(~cellfun(@isempty, tok));
end

function idx = nextNonEmpty(lines, startIdx)
    idx = NaN;
    for k = startIdx:numel(lines)
        if ~isempty(strtrim(lines{k}))
            idx = k;
            return;
        end
    end
end

function tf = isDataLike(tok)
    tf = false;
    if isempty(tok)
        return;
    end
    numericCount = 0;
    for i = 1:numel(tok)
        if ~isnan(str2double(tok{i}))
            numericCount = numericCount + 1;
        end
    end
    tf = numericCount >= max(1, ceil(0.5*numel(tok)));
end
