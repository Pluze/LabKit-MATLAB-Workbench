function gamry_CIC_VT_gui_paperlabels_legacy
% GAMRY_CIC_VT_GUI
% GUI for calculating CIC from Gamry MULTI_STEP_CHRONOPOT .DTA files.
% Layout updated to 3 left-side tabs with vertical file actions.
%
% Main features
%   - Parses Gamry chronopotentiometry DTA files (MULTI_STEP_CHRONOPOT)
%   - Supports loading one or multiple files
%   - Extracts pulse timing from ISTEP/TSTEP metadata when available
%   - Falls back to current-based automatic pulse detection when needed
%   - Calculates voltage-transient metrics used for CIC evaluation:
%         Emc = Vf at (end of cathodic pulse + delay)
%         Ema = Vf at (end of anodic   pulse + delay)
%   - Calculates injected charge from the measured current waveform
%   - Reports per-phase and total charge densities
%   - Highlights selected voltage points and pulse windows on VT / IT plots
%
% Notes
%   - This GUI is for single transient files and batch comparison across files.
%   - True "CIC limit" usually comes from a series of files acquired at different
%     current amplitudes; the GUI therefore marks each file safe/unsafe and also
%     reports the highest safe file among all loaded files.
%   - By default, the evaluation point is 10 us after the end of each phase,
%     matching the convention commonly used in the literature the user shared.
%
% Usage
%   >> gamry_CIC_VT_gui

    S = struct();
    S.items = struct([]);      % loaded files + parsed content + analysis
    S.current = [];
    S.isDragging = false;

    %% ===================== Figure & Layout =====================
    fig = uifigure('Name','Gamry CIC GUI (Voltage Transient)','Position',[40 30 1680 980]);

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
    % Keep large file batches from expanding the file list into the controls below.
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

    %% ===================== File panel =====================
    pFile = uipanel(layFA,'Title','Files');
    pFile.Layout.Row = 1;
    gf = uigridlayout(pFile,[3 1]);
    gf.RowHeight = {'fit','1x','fit'};
    gf.ColumnWidth = {'1x'};
    gf.Padding = [8 8 8 8];
    gf.RowSpacing = 8;
    gf.ColumnSpacing = 0;

    gbtn = uigridlayout(gf,[2 2]);
    gbtn.Layout.Row = 1; gbtn.Layout.Column = 1;
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
    txtLoaded.Layout.Row = 3; txtLoaded.Layout.Column = 1;

    %% ===================== Analysis settings =====================
    pSet = uipanel(layFA,'Title','Analysis Settings');
    pSet.Layout.Row = 2;
    gs = uigridlayout(pSet,[9 2]);
    gs.RowHeight = repmat({'fit'},1,9);
    gs.ColumnWidth = {'fit','1x'};
    gs.Padding = [8 8 8 8];
    gs.ColumnSpacing = 8;

    uilabel(gs,'Text','Window preset:','HorizontalAlignment','right');
    ddPreset = uidropdown(gs, ...
        'Items',{'Pt (-0.6 to 0.8 V)','PEDOT:PSS (-0.9 to 0.6 V)','Custom'}, ...
        'Value','Pt (-0.6 to 0.8 V)', ...
        'ValueChangedFcn',@(~,~) onPresetChanged());
    ddPreset.Layout.Row = 1; ddPreset.Layout.Column = 2;

    uilabel(gs,'Text','Cathodic limit (V):','HorizontalAlignment','right');
    edCathLim = uieditfield(gs,'numeric','Value',-0.6,'Limits',[-10 10], ...
        'ValueDisplayFormat','%.6g','ValueChangedFcn',@(~,~) analyzeCurrentFile());
    edCathLim.Layout.Row = 2; edCathLim.Layout.Column = 2;

    uilabel(gs,'Text','Anodic limit (V):','HorizontalAlignment','right');
    edAnodLim = uieditfield(gs,'numeric','Value',0.8,'Limits',[-10 10], ...
        'ValueDisplayFormat','%.6g','ValueChangedFcn',@(~,~) analyzeCurrentFile());
    edAnodLim.Layout.Row = 3; edAnodLim.Layout.Column = 2;

    uilabel(gs,'Text','Sample delay after pulse end:','HorizontalAlignment','right');
    edDelayUs = uieditfield(gs,'numeric','Value',10,'Limits',[0 inf], ...
        'ValueDisplayFormat','%.6g','ValueChangedFcn',@(~,~) analyzeCurrentFile());
    edDelayUs.Layout.Row = 4; edDelayUs.Layout.Column = 2;

    uilabel(gs,'Text','Area override (cm^2):','HorizontalAlignment','right');
    edArea = uieditfield(gs,'text','Value','', ...
        'ValueChangedFcn',@(~,~) analyzeCurrentFile());
    edArea.Layout.Row = 5; edArea.Layout.Column = 2;

    uilabel(gs,'Text','Pulse detection:','HorizontalAlignment','right');
    ddPulseMode = uidropdown(gs, ...
        'Items',{'Metadata first, then auto','Metadata only','Auto from Im only'}, ...
        'Value','Metadata first, then auto', ...
        'ValueChangedFcn',@(~,~) analyzeCurrentFile());
    ddPulseMode.Layout.Row = 6; ddPulseMode.Layout.Column = 2;

    uilabel(gs,'Text','CIC summary mode:','HorizontalAlignment','right');
    ddCICMode = uidropdown(gs, ...
        'Items',{'Cathodic phase','Anodic phase','Total biphasic'}, ...
        'Value','Total biphasic', ...
        'ValueChangedFcn',@(~,~) refreshResultsSummary());
    ddCICMode.Layout.Row = 7; ddCICMode.Layout.Column = 2;

    uilabel(gs,'Text','CIC unit:','HorizontalAlignment','right');
    ddCICUnit = uidropdown(gs, ...
        'Items',{'mC/cm^2','uC/cm^2'}, ...
        'Value','mC/cm^2', ...
        'ValueChangedFcn',@(~,~) refreshCICUnitDisplays());
    ddCICUnit.Layout.Row = 8; ddCICUnit.Layout.Column = 2;

    cbUseMeasuredCurrent = uicheckbox(gs,'Text','Use measured Im integration for charge (recommended)', ...
        'Value',true,'ValueChangedFcn',@(~,~) analyzeCurrentFile());
    cbUseMeasuredCurrent.Layout.Row = 9; cbUseMeasuredCurrent.Layout.Column = [1 2];

    %% ===================== Quick info =====================
    pInfo = uipanel(laySR,'Title','Current File Summary');
    pInfo.Layout.Row = 1;
    gi = uigridlayout(pInfo,[10 2]);
    gi.RowHeight = repmat({'fit'},1,10);
    gi.ColumnWidth = {'fit','1x'};
    gi.Padding = [8 8 8 8];
    gi.ColumnSpacing = 8;

    addInfoRow(gi,1,'Detection:', 'txtDetect');
    addInfoRow(gi,2,'Delay used:', 'txtDelay');
    addInfoRow(gi,3,'Area:', 'txtArea');
    addInfoRow(gi,4,'Emc:', 'txtEmc');
    addInfoRow(gi,5,'Ema:', 'txtEma');
    addInfoRow(gi,6,'Cathodic Q/CIC:', 'txtQc');
    addInfoRow(gi,7,'Anodic Q/CIC:', 'txtQa');
    addInfoRow(gi,8,'Total Q/CIC:', 'txtQt');
    addInfoRow(gi,9,'Safety:', 'txtSafe');
    addInfoRow(gi,10,'Best safe among loaded:', 'txtBest');

    %% ===================== Actions =====================
    pAct = uipanel(layFA,'Title','Plot / Debug');
    pAct.Layout.Row = 3;
    ga = uigridlayout(pAct,[2 3]);
    ga.RowHeight = {'fit','fit'};
    ga.ColumnWidth = {'1x','1x','1x'};
    ga.Padding = [8 8 8 8];
    ga.ColumnSpacing = 8;

    btnRefresh = uibutton(ga,'Text','Refresh plots','ButtonPushedFcn',@(~,~) refreshPlots());
    btnRefresh.Layout.Row = 1; btnRefresh.Layout.Column = 1;
    btnSwap = uibutton(ga,'Text','Swap top / bottom','ButtonPushedFcn',@(~,~) swapPlots());
    btnSwap.Layout.Row = 1; btnSwap.Layout.Column = 2;
    btnReset = uibutton(ga,'Text','Reset axes','ButtonPushedFcn',@(~,~) resetAxes());
    btnReset.Layout.Row = 1; btnReset.Layout.Column = 3;

    cbShowMarkers = uicheckbox(ga,'Text','Show debug markers','Value',true,'ValueChangedFcn',@(~,~) refreshPlots());
    cbShowMarkers.Layout.Row = 2; cbShowMarkers.Layout.Column = 1;
    cbShowLimits = uicheckbox(ga,'Text','Show window limits','Value',true,'ValueChangedFcn',@(~,~) refreshPlots());
    cbShowLimits.Layout.Row = 2; cbShowLimits.Layout.Column = 2;
    cbShowShading = uicheckbox(ga,'Text','Shade pulse windows','Value',true,'ValueChangedFcn',@(~,~) refreshPlots());
    cbShowShading.Layout.Row = 2; cbShowShading.Layout.Column = 3;

    %% ===================== Results table =====================
    pTab = uipanel(laySR,'Title','Batch Results');
    pTab.Layout.Row = 2;
    gt = uigridlayout(pTab,[1 1]);
    gt.Padding = [8 8 8 8];

    tbl = uitable(gt);
    tbl.ColumnName = {'File','Amp(A)','Emc(V)','Ema(V)','Qc(mC/cm^2)','Qa(mC/cm^2)','Qtot(mC/cm^2)','Safe'};
    tbl.Data = cell(0,8);

    %% ===================== Log =====================
    pLog = uipanel(layLog,'Title','Log');
    pLog.Layout.Row = 1;
    gl = uigridlayout(pLog,[1 1]);
    gl.Padding = [8 8 8 8];
    txtLog = uitextarea(gl,'Editable','off');
    txtLog.Value = {'GUI started.'};

    %% ===================== Right: plots =====================
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

    onPresetChanged();

    %% ===================== Nested helpers =====================
    function addInfoRow(parent,row,labelText,fieldName)
        lbl = uilabel(parent,'Text',labelText,'HorizontalAlignment','right');
        lbl.Layout.Row = row;
        lbl.Layout.Column = 1;
        h = uieditfield(parent,'text','Editable','off','Value','-');
        h.Layout.Row = row;
        h.Layout.Column = 2;
        assigninStruct(fieldName,h);
    end

    function assigninStruct(name,val)
        S.(name) = val;
    end

    function onPresetChanged()
        switch ddPreset.Value
            case 'Pt (-0.6 to 0.8 V)'
                edCathLim.Value = -0.6;
                edAnodLim.Value = 0.8;
            case 'PEDOT:PSS (-0.9 to 0.6 V)'
                edCathLim.Value = -0.9;
                edAnodLim.Value = 0.6;
            otherwise
                % keep manual values
        end
        analyzeCurrentFile();
    end

    function onOpenFiles(~,~)
        [f,p] = uigetfile({'*.DTA;*.dta','Gamry DTA (*.DTA)';'*.*','All files'}, ...
            'Select one or more Gamry DTA files','MultiSelect','on');
        if isequal(f,0)
            addLog('Open cancelled.');
            return;
        end

        if ischar(f) || isstring(f)
            f = {char(f)};
        end

        filepaths = cellfun(@(name) fullfile(p, name), f, 'UniformOutput', false);
        loadDTAFiles(filepaths);
    end

    function onOpenFolder(~,~)
        folder = uigetdir(pwd, 'Select a folder to recursively scan for .DTA files');
        if isequal(folder,0)
            addLog('Folder selection cancelled.');
            return;
        end

        filepaths = findDTAFilesRecursive(folder);
        if isempty(filepaths)
            addLog(sprintf('No DTA files found under: %s', folder));
            uialert(fig, sprintf('No .DTA files found under:\n%s', folder), 'No files found');
            return;
        end

        addLog(sprintf('Found %d DTA file(s) under %s', numel(filepaths), folder));
        loadDTAFiles(filepaths);
    end

    function loadDTAFiles(filepaths)
        if isempty(filepaths)
            return;
        end

        filepaths = unique(filepaths, 'stable');
        if isempty(S.items) || ~isfield(S.items, 'filepath')
            existing = strings(0,1);
        else
            existing = string({S.items.filepath});
        end

        queued = string(filepaths);
        if ~isempty(existing)
            isNew = ~ismember(queued, existing);
            skipped = filepaths(~isNew);
            filepaths = filepaths(isNew);
            for j = 1:numel(skipped)
                addLog(sprintf('Skipped already loaded: %s', skipped{j}));
            end
        end

        if isempty(filepaths)
            refreshFileList();
            restoreDefaultPlotSelections();
            resetAxesToDefaultState();
            refreshBatchTable();
            refreshResultsSummary();
            refreshPlots();
            return;
        end

        firstError = [];
        for i = 1:numel(filepaths)
            filepath = filepaths{i};
            try
                item = loadOneDTA(filepath);
                S.items = appendStruct(S.items, item);
                addLog(sprintf('Loaded: %s', filepath));
            catch ME
                addLog(sprintf('Failed: %s | %s', filepath, ME.message));
                if isempty(firstError)
                    firstError = struct('filepath', filepath, 'message', ME.message);
                end
            end
        end

        refreshFileList();
        restoreDefaultPlotSelections();
        resetAxesToDefaultState();
        refreshBatchTable();
        refreshResultsSummary();
        refreshPlots();

        if ~isempty(firstError)
            uialert(fig, sprintf('Failed to load:\n%s\n\n%s', firstError.filepath, firstError.message), 'Load error');
        end
    end

    function item = loadOneDTA(filepath)
        item = struct();
        item.filepath = filepath;
        item.name = shortName(filepath);
        [item.meta, item.tables, item.logmsg] = parseGamryChronoDTA(filepath);
        item.analysis = [];

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
        A.delay_s = edDelayUs.Value * 1e-6;
        A.cathLimit = edCathLim.Value;
        A.anodLimit = edAnodLim.Value;
        A.area_cm2 = chooseArea(item.meta, edArea.Value);
        A.usedMeasuredCurrent = cbUseMeasuredCurrent.Value;

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
        t = t(valid); Vf = Vf(valid); Im = Im(valid); pt = pt(valid);
        if numel(t) < 5
            A.message = 'Not enough valid T/Vf/Im points.';
            item.analysis = A;
            return;
        end

        A.t = t;
        A.Vf = Vf;
        A.Im = Im;
        A.pt = pt;
        A.sample_dt = median(diff(t));
        A.sample_dt_report = A.sample_dt;
        A.ampEstimate_A = max(abs(Im));

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

        % Voltage evaluation times
        A.t_emc = pulse.cath_end + A.delay_s;
        A.t_ema = pulse.anod_end + A.delay_s;
        A.emc_idx = nearestIndex(t, A.t_emc);
        A.ema_idx = nearestIndex(t, A.t_ema);
        A.Emc = interp1_safe(t, Vf, A.t_emc);
        A.Ema = interp1_safe(t, Vf, A.t_ema);

        % Optional supporting baseline values
        A.Epre = median_in_window(t, Vf, pulse.pre_start, pulse.pre_end);
        A.Ebetween = median_in_window(t, Vf, pulse.gap_start, pulse.gap_end);
        A.Epost = median_in_window(t, Vf, pulse.post_start, pulse.post_end);
        [A.Eipp, A.baselineCathSource, A.baselineCathWindow] = chooseBaselineCandidate( ...
            [A.Epre, A.Ebetween, A.Epost, 0], ...
            {'pre-pulse median','interpulse median','post-pulse median','zero fallback'}, ...
            [pulse.pre_start pulse.pre_end; pulse.gap_start pulse.gap_end; pulse.post_start pulse.post_end; NaN NaN]);
        [A.Eipp_gap, A.baselineAnodSource, A.baselineAnodWindow] = chooseBaselineCandidate( ...
            [A.Ebetween, A.Epre, A.Epost, A.Eipp], ...
            {'interpulse median','pre-pulse median','post-pulse median','cathodic baseline fallback'}, ...
            [pulse.gap_start pulse.gap_end; pulse.pre_start pulse.pre_end; pulse.post_start pulse.post_end; A.baselineCathWindow]);

        % Time points used for paper-style annotations
        A.tc_s = max(0, pulse.cath_end - pulse.cath_start);
        A.ta_s = max(0, pulse.anod_end - pulse.anod_start);
        A.tip_s = max(0, pulse.anod_start - pulse.cath_end);
        A.t_conset = pulse.cath_start + A.delay_s;
        A.t_aonset = pulse.anod_start + A.delay_s;
        A.Vc_on = interp1_safe(t, Vf, A.t_conset);
        A.Va_on = interp1_safe(t, Vf, A.t_aonset);
        A.Va_cath_mag = abs(A.Eipp - A.Vc_on);
        A.Va_anod_mag = abs(A.Eipp_gap - A.Va_on);

        % Charges from pulse windows
        cathMask = (t >= pulse.cath_start) & (t <= pulse.cath_end);
        anodMask = (t >= pulse.anod_start) & (t <= pulse.anod_end);
        A.cathMask = cathMask;
        A.anodMask = anodMask;

        if sum(cathMask) < 2 || sum(anodMask) < 2
            A.message = 'Pulse windows too short after detection.';
            item.analysis = A;
            return;
        end

        A.Ic_est_A = median(Im(cathMask), 'omitnan');
        A.Ia_est_A = median(Im(anodMask), 'omitnan');
        if ~isfinite(A.Ic_est_A), A.Ic_est_A = pulse.Ic_nominal; end
        if ~isfinite(A.Ia_est_A), A.Ia_est_A = pulse.Ia_nominal; end

        if A.usedMeasuredCurrent
            Qc = abs(trapz(t(cathMask), Im(cathMask)));
            Qa = abs(trapz(t(anodMask), Im(anodMask)));
        else
            Qc = abs(pulse.Ic_nominal * (pulse.cath_end - pulse.cath_start));
            Qa = abs(pulse.Ia_nominal * (pulse.anod_end - pulse.anod_start));
        end
        A.Qc_C = Qc;
        A.Qa_C = Qa;
        A.Qt_C = Qc + Qa;

        if isfinite(A.area_cm2) && A.area_cm2 > 0
            A.CICc_mCcm2 = 1e3 * A.Qc_C / A.area_cm2;
            A.CICa_mCcm2 = 1e3 * A.Qa_C / A.area_cm2;
            A.CICt_mCcm2 = 1e3 * A.Qt_C / A.area_cm2;
        else
            A.CICc_mCcm2 = NaN;
            A.CICa_mCcm2 = NaN;
            A.CICt_mCcm2 = NaN;
        end

        A.cathOK = A.Emc >= A.cathLimit;
        A.anodOK = A.Ema <= A.anodLimit;
        A.safe = A.cathOK && A.anodOK;

        if A.safe
            A.limitSide = 'safe';
        elseif ~A.cathOK && ~A.anodOK
            A.limitSide = 'both exceeded';
        elseif ~A.cathOK
            A.limitSide = 'cathodic exceeded';
        else
            A.limitSide = 'anodic exceeded';
        end

        A.ok = true;
        A.message = 'OK';
        item.analysis = A;
        addLog(sprintf('%s: Emc=%.6f V, Ema=%.6f V, safe=%d', item.name, A.Emc, A.Ema, A.safe));
    end

    function [pulse, msg] = detectPulses(meta, t, Im, modeText)
        pulse = emptyPulse();
        msg = 'Pulse detection failed.';

        switch modeText
            case 'Metadata only'
                [pulse, ok, msg1] = pulsesFromMetadata(meta, t);
                if ok
                    msg = msg1; return;
                else
                    msg = msg1; return;
                end
            case 'Auto from Im only'
                [pulse, ok, msg1] = pulsesFromCurrent(t, Im);
                if ok
                    msg = msg1; return;
                else
                    msg = msg1; return;
                end
            otherwise
                [pulse, okM, msgM] = pulsesFromMetadata(meta, t);
                if okM
                    msg = msgM; return;
                end
                [pulse, okA, msgA] = pulsesFromCurrent(t, Im);
                if okA
                    msg = sprintf('%s | fallback success: %s', msgM, msgA);
                    return;
                else
                    msg = sprintf('%s | %s', msgM, msgA);
                    return;
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
        pulse.cath_end   = ends(idxCath);
        pulse.anod_start = starts(idxAnod);
        pulse.anod_end   = ends(idxAnod);
        if strcmp(stepMode,'current')
            pulse.Ic_nominal = Ivals(idxCath);
            pulse.Ia_nominal = Ivals(idxAnod);
        else
            pulse.Ic_nominal = NaN;
            pulse.Ia_nominal = NaN;
        end

        if idxCath > 1
            pulse.pre_start = starts(idxCath-1);
            pulse.pre_end   = ends(idxCath-1);
        else
            pulse.pre_start = t(1);
            pulse.pre_end   = pulse.cath_start;
        end

        if idxAnod > idxCath
            pulse.gap_start = pulse.cath_end;
            pulse.gap_end   = pulse.anod_start;
        else
            pulse.gap_start = pulse.cath_end;
            pulse.gap_end   = pulse.cath_end;
        end

        if idxAnod < numel(Tvals)
            pulse.post_start = starts(idxAnod+1);
            pulse.post_end   = ends(idxAnod+1);
        else
            pulse.post_start = pulse.anod_end;
            pulse.post_end   = t(end);
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
        cathMask = Im <= -thr;
        anodMask = Im >= thr;

        cathSeg = contiguousSegments(cathMask);
        anodSeg = contiguousSegments(anodMask);

        if isempty(cathSeg) || isempty(anodSeg)
            msg = 'Auto pulse detection: could not find both cathodic and anodic segments.';
            return;
        end

        % pick longest negative segment and first positive segment after it
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
        pulse.cath_end   = t(cseg(2));
        pulse.anod_start = t(aseg(1));
        pulse.anod_end   = t(aseg(2));
        pulse.Ic_nominal = median(Im(cseg(1):cseg(2)),'omitnan');
        pulse.Ia_nominal = median(Im(aseg(1):aseg(2)),'omitnan');

        pulse.pre_start = t(1);
        pulse.pre_end   = pulse.cath_start;
        pulse.gap_start = pulse.cath_end;
        pulse.gap_end   = pulse.anod_start;
        pulse.post_start = pulse.anod_end;
        pulse.post_end   = t(end);

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
        [scale, unitLabel] = cicDisplayUnit();
        tbl.ColumnName = {'File','Amp(A)','Emc(V)','Ema(V)', ...
            ['Qc(' unitLabel ')'], ['Qa(' unitLabel ')'], ['Qtot(' unitLabel ')'], 'Safe'};
        if isempty(S.items)
            tbl.Data = cell(0,8);
            return;
        end
        C = cell(numel(S.items),8);
        for i = 1:numel(S.items)
            it = S.items(i);
            if isempty(it.analysis) || ~isfield(it.analysis,'ok') || ~it.analysis.ok
                C{i,1} = it.name;
                C{i,2} = NaN;
                C{i,3} = NaN;
                C{i,4} = NaN;
                C{i,5} = NaN;
                C{i,6} = NaN;
                C{i,7} = NaN;
                C{i,8} = 'parse/analyze failed';
            else
                A = it.analysis;
                C{i,1} = it.name;
                C{i,2} = A.ampEstimate_A;
                C{i,3} = A.Emc;
                C{i,4} = A.Ema;
                C{i,5} = scale * A.CICc_mCcm2;
                C{i,6} = scale * A.CICa_mCcm2;
                C{i,7} = scale * A.CICt_mCcm2;
                C{i,8} = ternary(A.safe,'safe',A.limitSide);
            end
        end
        tbl.Data = C;
    end

    function refreshResultsSummary()
        % clear first
        S.txtDetect.Value = '-';
        S.txtDelay.Value = '-';
        S.txtArea.Value = '-';
        S.txtEmc.Value = '-';
        S.txtEma.Value = '-';
        S.txtQc.Value = '-';
        S.txtQa.Value = '-';
        S.txtQt.Value = '-';
        S.txtSafe.Value = '-';
        S.txtBest.Value = bestSafeString();

        if isempty(S.items) || isempty(S.current) || S.current < 1 || S.current > numel(S.items)
            return;
        end

        it = S.items(S.current);
        if isempty(it.analysis) || ~it.analysis.ok
            if ~isempty(it.analysis) && isfield(it.analysis,'message')
                S.txtSafe.Value = it.analysis.message;
            else
                S.txtSafe.Value = 'No valid analysis';
            end
            S.txtBest.Value = bestSafeString();
            return;
        end

        A = it.analysis;
        S.txtDetect.Value = sprintf('%s | %s', A.detectMode, A.detectMsg);
        S.txtDelay.Value = sprintf('%.3f us', 1e6 * A.delay_s);
        S.txtArea.Value = formatMaybeNum(A.area_cm2,'%.8g cm^2');
        S.txtEmc.Value = sprintf('%.6f V @ %.6fus', A.Emc, 1e6*A.t_emc);
        S.txtEma.Value = sprintf('%.6f V @ %.6fus', A.Ema, 1e6*A.t_ema);
        S.txtQc.Value = formatChargeDensity(A.Qc_C, A.CICc_mCcm2, ddCICUnit.Value);
        S.txtQa.Value = formatChargeDensity(A.Qa_C, A.CICa_mCcm2, ddCICUnit.Value);
        S.txtQt.Value = formatChargeDensity(A.Qt_C, A.CICt_mCcm2, ddCICUnit.Value);
        S.txtSafe.Value = sprintf('%s | Emc>=%.3f? %d | Ema<=%.3f? %d', ...
            ternary(A.safe,'SAFE','UNSAFE'), A.cathLimit, A.cathOK, A.anodLimit, A.anodOK);
        S.txtBest.Value = bestSafeString();
    end

    function out = bestSafeString()
        if isempty(S.items)
            out = '-';
            return;
        end
        safeIdx = [];
        vals = [];
        for i = 1:numel(S.items)
            if ~isempty(S.items(i).analysis) && S.items(i).analysis.ok && S.items(i).analysis.safe
                safeIdx(end+1) = i; %#ok<AGROW>
                vals(end+1) = selectedCICValue(S.items(i).analysis); %#ok<AGROW>
            end
        end
        if isempty(safeIdx)
            out = 'No safe file in current batch';
            return;
        end
        [~, imax] = max(vals);
        ii = safeIdx(imax);
        [scale, unitLabel] = cicDisplayUnit();
        out = sprintf('%s | %s = %.6g %s', S.items(ii).name, shortModeName(), scale * vals(imax), unitLabel);
    end

    function refreshCICUnitDisplays()
        refreshBatchTable();
        refreshResultsSummary();
    end

    function [scale, unitLabel] = cicDisplayUnit()
        unitLabel = ddCICUnit.Value;
        switch unitLabel
            case 'uC/cm^2'
                scale = 1e3;
            otherwise
                scale = 1;
                unitLabel = 'mC/cm^2';
        end
    end

    function v = selectedCICValue(A)
        switch ddCICMode.Value
            case 'Cathodic phase'
                v = A.CICc_mCcm2;
            case 'Anodic phase'
                v = A.CICa_mCcm2;
            otherwise
                v = A.CICt_mCcm2;
        end
    end

    function s = shortModeName()
        switch ddCICMode.Value
            case 'Cathodic phase'
                s = 'CICc';
            case 'Anodic phase'
                s = 'CICa';
            otherwise
                s = 'CICtotal';
        end
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
            cathEndX   = interp1_safe(A.t, A.pt, A.pulse.cath_end);
            anodStartX = interp1_safe(A.t, A.pt, A.pulse.anod_start);
            anodEndX   = interp1_safe(A.t, A.pt, A.pulse.anod_end);
            emcX       = interp1_safe(A.t, A.pt, A.t_emc);
            emaX       = interp1_safe(A.t, A.pt, A.t_ema);
        else
            x = A.t;
            xlab = 'Time (s)';
            cathStartX = A.pulse.cath_start;
            cathEndX   = A.pulse.cath_end;
            anodStartX = A.pulse.anod_start;
            anodEndX   = A.pulse.anod_end;
            emcX       = A.t_emc;
            emaX       = A.t_ema;
        end

        if startsWith(yChoice,'VT')
            y = A.Vf;
            ylab = 'Vf (V vs Ref.)';
            baseColor = [0 0.4470 0.7410];
            plot(ax, x, y, 'LineWidth',1.25, 'Color', baseColor);
            hold(ax,'on');

            if cbShowShading.Value
                shadeWindow(ax, cathStartX, cathEndX, [0.85 0.93 1.00]);
                shadeWindow(ax, anodStartX, anodEndX, [1.00 0.92 0.85]);
            end

            if cbShowLimits.Value
                yline(ax, A.cathLimit, '--', sprintf('Cath limit = %.3f V', A.cathLimit), ...
                    'Color',[0.85 0.2 0.2],'LabelHorizontalAlignment','left');
                yline(ax, A.anodLimit, '--', sprintf('Anod limit = %.3f V', A.anodLimit), ...
                    'Color',[0.85 0.2 0.2],'LabelHorizontalAlignment','left');
            end

            addBaselineYLines(ax, A);

            if cbShowMarkers.Value
                xline(ax, cathStartX, ':', 'Cath start','Color',[0.2 0.4 0.8]);
                xline(ax, cathEndX, ':', 'Cath end','Color',[0.2 0.4 0.8]);
                xline(ax, anodStartX, ':', 'Anod start','Color',[0.8 0.4 0.2]);
                xline(ax, anodEndX, ':', 'Anod end','Color',[0.8 0.4 0.2]);
                addPaperStyleVTAnnotations(ax, A, xChoice, cathStartX, cathEndX, anodStartX, anodEndX, emcX, emaX);
            end
            hold(ax,'off');
            ttl = sprintf('%s | VT | %s', itName(), ternary(A.safe,'SAFE','UNSAFE'));
        else
            y = A.Im;
            ylab = 'Im (A)';
            baseColor = [0.8500 0.3250 0.0980];
            plot(ax, x, y, 'LineWidth',1.25, 'Color', baseColor);
            hold(ax,'on');

            if cbShowShading.Value
                shadeWindow(ax, cathStartX, cathEndX, [0.85 0.93 1.00]);
                shadeWindow(ax, anodStartX, anodEndX, [1.00 0.92 0.85]);
            end

            if cbShowMarkers.Value
                xline(ax, cathStartX, ':', 'Cath start','Color',[0.2 0.4 0.8]);
                xline(ax, cathEndX, ':', 'Cath end','Color',[0.2 0.4 0.8]);
                xline(ax, anodStartX, ':', 'Anod start','Color',[0.8 0.4 0.2]);
                xline(ax, anodEndX, ':', 'Anod end','Color',[0.8 0.4 0.2]);
                addPaperStyleITAnnotations(ax, A, xChoice, cathStartX, cathEndX, anodStartX, anodEndX, emcX, emaX);
            end
            hold(ax,'off');
            ttl = sprintf('%s | IT | |I|max = %.4g A', itName(), A.ampEstimate_A);
        end

        title(ax, ttl, 'Interpreter','none');
        xlabel(ax, xlab);
        ylabel(ax, ylab);
        grid(ax, ternary(showGrid,'on','off'));
    end

    function nm = itName()
        if isempty(S.items) || isempty(S.current), nm = 'file'; else, nm = S.items(S.current).name; end
    end

    function swapPlots()
        topX = ddTopX.Value; topY = ddTopY.Value;
        botX = ddBotX.Value; botY = ddBotY.Value;
        ddTopX.Value = botX; ddTopY.Value = botY;
        ddBotX.Value = topX; ddBotY.Value = topY;
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
        ax.XScale = 'linear';
        ax.YScale = 'linear';
        ax.XTickMode = 'auto';
        ax.YTickMode = 'auto';
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
        [f,p] = uiputfile('cic_results.csv','Save results CSV');
        if isequal(f,0)
            return;
        end
        out = fullfile(p,f);
        fid = fopen(out,'w');
        if fid < 0
            uialert(fig,'Could not open file for writing.','Export');
            return;
        end
        [scale, unitLabel] = cicDisplayUnit();
        unitSuffix = regexprep(unitLabel, '[\^/]', '');
        fprintf(fid,'File,Amp_A,Emc_V,Ema_V,Qc_C,Qa_C,Qt_C,CICc_%s,CICa_%s,CICt_%s,Safe,Detection\n', ...
            unitSuffix, unitSuffix, unitSuffix);
        for i = 1:numel(S.items)
            it = S.items(i);
            if isempty(it.analysis) || ~it.analysis.ok
                fprintf(fid,'"%s",,,,,,,,,,0,"failed"\n', it.name);
            else
                A = it.analysis;
                fprintf(fid,'"%s",%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%d,"%s"\n', ...
                    it.name, A.ampEstimate_A, A.Emc, A.Ema, A.Qc_C, A.Qa_C, A.Qt_C, ...
                    scale * A.CICc_mCcm2, scale * A.CICa_mCcm2, scale * A.CICt_mCcm2, A.safe, A.detectMode);
            end
        end
        fclose(fid);
        addLog(['Exported CSV: ' out]);
    end

    %% ===================== Drag separator =====================
    function startDrag(~,~)
        S.isDragging = true;
        fig.WindowButtonMotionFcn = @doDrag;
        fig.WindowButtonUpFcn = @stopDrag;
        fig.Pointer = 'left';
    end

    function doDrag(~,~)
        if ~S.isDragging, return; end
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

    %% ===================== Logging =====================
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

%% ========================================================================
%% =========================== Core parser =================================
%% ========================================================================
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

    % Pass 1: metadata + steps
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
        I = NaN; V = NaN; T = NaN;
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

    % Pass 2: tables
    i = 1;
    while i <= nLines
        tok = splitTabs(lines{i});
        if numel(tok) >= 3 && strcmpi(tok{2},'TABLE')
            name = tok{1};
            iHeader = nextNonEmpty(lines, i+1);
            iUnits  = nextNonEmpty(lines, iHeader+1);
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
        % fallback: choose first table containing T/Vf/Im
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

%% ========================================================================
%% =============================== Utilities ===============================
%% ========================================================================
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

function v = chooseArea(meta, txtOverride)
    v = parsePositiveScalar(txtOverride);
    if ~isfinite(v)
        if isfield(meta,'area_cm2') && isfinite(meta.area_cm2) && meta.area_cm2 > 0
            v = meta.area_cm2;
        else
            v = NaN;
        end
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

function out = appendStruct(S, item)
    if isempty(S)
        out = item;
    else
        out = [S, item];
    end
end

function name = shortName(filepath)
    [~,name,ext] = fileparts(filepath);
    name = [name ext];
end

function txt = ternary(cond, a, b)
    if cond
        txt = a;
    else
        txt = b;
    end
end

function tok = splitTabs(line)
    tok = regexp(char(line), '\t+', 'split');
    tok = tok(~cellfun(@isempty, tok));
end

function idx = nextNonEmpty(lines, startIdx)
    idx = NaN;
    for i = startIdx:numel(lines)
        if ~isempty(strtrim(lines{i}))
            idx = i;
            return;
        end
    end
end

function tf = isDataLike(tok)
    if isempty(tok)
        tf = false;
        return;
    end
    vals = nan(size(tok));
    for i = 1:numel(tok)
        vals(i) = str2double(tok{i});
    end
    tf = any(~isnan(vals));
end

function col = getColByName(tbl, name)
    idx = find(strcmpi(tbl.headers, name), 1);
    if isempty(idx)
        col = [];
    else
        col = tbl.data(:,idx);
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
        cOnX = interp1_safe(A.t, A.pt, A.t_conset);
        aOnX = interp1_safe(A.t, A.pt, A.t_aonset);
        cathBase1 = interp1_safe(A.t, A.pt, A.baselineCathWindow(1));
        cathBase2 = interp1_safe(A.t, A.pt, A.baselineCathWindow(2));
        anodBase1 = interp1_safe(A.t, A.pt, A.baselineAnodWindow(1));
        anodBase2 = interp1_safe(A.t, A.pt, A.baselineAnodWindow(2));
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
    plot(ax, emcX, interp1_safe(chooseX(A,xChoice), A.Im, emcX), 'o', 'MarkerFaceColor',[0.1 0.7 0.1], 'MarkerEdgeColor','k', 'MarkerSize',6);
    plot(ax, emaX, interp1_safe(chooseX(A,xChoice), A.Im, emaX), 'o', 'MarkerFaceColor',[0.95 0.8 0.1], 'MarkerEdgeColor','k', 'MarkerSize',6);

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

function [v, sourceLabel, window] = chooseBaselineCandidate(candidates, sourceLabels, windows)
    v = NaN;
    sourceLabel = 'unavailable';
    window = [NaN NaN];
    for k = 1:numel(candidates)
        if isfinite(candidates(k))
            v = candidates(k);
            sourceLabel = sourceLabels{k};
            if size(windows,1) >= k
                window = windows(k,:);
            end
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
