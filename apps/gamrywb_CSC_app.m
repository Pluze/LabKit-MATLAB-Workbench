function varargout = gamrywb_CSC_app(varargin)
%GAMRYWB_CSC_APP Launch the CV/CSC app.
% Single-file app that composes +gamrywb GUI/DTA APIs and owns CV/CSC workflow choices.
%
% Assumptions
%   - CV data is already constrained to the intended water window during acquisition.
%   - No additional window cropping is applied inside the GUI.
%
% Integration rules
%   - Cathodic charge: integrate only the negative current portion.
%   - Anodic  charge: integrate only the positive current portion.
%   - Full charge     : cathodic + anodic.
%
% CT charge
%   Qct = ∫ I · dt using recorded time.
%
% CV charge (constant scan rate v)
%   dt = |dV| / v, so Qcv = ∫ I · (|dV| / v) (not trapz(V, I) directly).
%
% Optional normalization
%   CSC = Q / area (cm²); both charge and normalized CSC are shown.
%
    if nargin > 0
        % Keep CSC numerical tests direct while the app owns the local analysis code.
        if isCSCAnalysisTestRequest(varargin)
            if nargout > 1
                error('gamrywb_CSC_app:TooManyOutputs', 'CSC analysis test request returns one result struct.');
            end
            varargout{1} = computeCSC(varargin{2}, varargin{3});
            return;
        end
        error('gamrywb_CSC_app:UnsupportedInput', 'gamrywb_CSC_app does not accept input arguments.');
    end
    if nargout > 1
        error('gamrywb_CSC_app:TooManyOutputs', 'gamrywb_CSC_app returns at most the app figure handle.');
    end

    % Application state container
    S = struct();
    S.session = gamrywb.data.makeSession('cv_csc');
    S.filepath = '';
    S.curves = struct('name',{},'headers',{},'units',{},'data',{},'numericMask',{});
    S.scanRate = NaN; % V/s
    S.currentCurve = 1;
    S.isDragging = false;

    %% ===================== Figure & Layout =====================
    fig = uifigure('Name','Gamry DTA GUI (literature CSC)','Position',[50 30 1580 950]);

    main = uigridlayout(fig,[1 3]);
    main.ColumnWidth = {390,6,'1x'};
    main.RowHeight = {'1x'};
    main.Padding = [10 10 10 10];
    main.ColumnSpacing = 0;

    sep = uipanel(main,'BackgroundColor',[0.75 0.75 0.75],'BorderType','none');
    sep.Layout.Row = 1;
    sep.Layout.Column = 2;
    sep.ButtonDownFcn = @startDrag;

    %% LEFT: controls
    leftPanel = uipanel(main,'Title','Controls','Scrollable','on');
    leftPanel.Layout.Row = 1;
    leftPanel.Layout.Column = 1;

    left = uigridlayout(leftPanel,[4 1]);
    left.RowHeight = {'fit','fit','fit','1x'};
    left.RowSpacing = 10;
    left.Padding = [8 8 8 8];

    % -------- File / Curve --------
    pFile = uipanel(left,'Title','File / Curve');
    pFile.Layout.Row = 1;
    gf = uigridlayout(pFile,[5 2]);
    gf.RowHeight = {'fit','fit','fit','fit','fit'};
    gf.ColumnWidth = {'fit','1x'};
    gf.Padding = [8 8 8 8];
    gf.ColumnSpacing = 8;

    btnOpen = uibutton(gf,'Text','Open DTA','ButtonPushedFcn',@onOpenFile);
    btnOpen.Layout.Row = 1; btnOpen.Layout.Column = 1;
    btnReload = uibutton(gf,'Text','Reload','ButtonPushedFcn',@(~,~) onReloadFile());
    btnReload.Layout.Row = 1; btnReload.Layout.Column = 2;

    uilabel(gf,'Text','File:','HorizontalAlignment','right');
    txtFile = uieditfield(gf,'text','Editable','off');
    txtFile.Layout.Row = 2; txtFile.Layout.Column = 2;

    uilabel(gf,'Text','Scan rate:','HorizontalAlignment','right');
    txtScan = uieditfield(gf,'text','Editable','off');
    txtScan.Layout.Row = 3; txtScan.Layout.Column = 2;

    uilabel(gf,'Text','Curve:','HorizontalAlignment','right');
    ddCurve = uidropdown(gf,'Items',{'(none)'},'ValueChangedFcn',@(~,~) onCurveChanged());
    ddCurve.Layout.Row = 4; ddCurve.Layout.Column = 2;

    btnAuto = uibutton(gf,'Text','Auto CV + CT','ButtonPushedFcn',@(~,~) autoPresetAndRefresh());
    btnAuto.Layout.Row = 5; btnAuto.Layout.Column = [1 2];

    % -------- Actions --------
    pActions = uipanel(left,'Title','Actions');
    pActions.Layout.Row = 2;
    ga = uigridlayout(pActions,[2 2]);
    ga.RowHeight = {'fit','fit'};
    ga.ColumnWidth = {'1x','1x'};
    ga.Padding = [8 8 8 8];
    ga.ColumnSpacing = 8;

    btnSwap = uibutton(ga,'Text','Swap Top/Bottom','ButtonPushedFcn',@(~,~) onSwapPlots());
    btnSwap.Layout.Row = 1; btnSwap.Layout.Column = 1;
    btnCompare = uibutton(ga,'Text','Compare Q / CSC','ButtonPushedFcn',@(~,~) refreshCompare());
    btnCompare.Layout.Row = 1; btnCompare.Layout.Column = 2;
    btnRefresh = uibutton(ga,'Text','Refresh Plots','ButtonPushedFcn',@(~,~) refreshPlotsOnly());
    btnRefresh.Layout.Row = 2; btnRefresh.Layout.Column = 1;
    btnClear = uibutton(ga,'Text','Clear Both','ButtonPushedFcn',@(~,~) clearBothAxes());
    btnClear.Layout.Row = 2; btnClear.Layout.Column = 2;

    % -------- Comparison / CSC --------
    pComp = uipanel(left,'Title','CSC / Comparison');
    pComp.Layout.Row = 3;
    gc = uigridlayout(pComp,[8 2]);
    gc.RowHeight = repmat({'fit'},1,8);
    gc.ColumnWidth = {'fit','1x'};
    gc.Padding = [8 8 8 8];
    gc.ColumnSpacing = 8;

    uilabel(gc,'Text','Mode:','HorizontalAlignment','right');
    ddMode = uidropdown(gc, ...
        'Items',{'Full','Cathodic','Anodic'}, ...
        'Value','Full', ...
        'ValueChangedFcn',@(~,~) refreshCompare());
    ddMode.Layout.Row = 1; ddMode.Layout.Column = 2;

    uilabel(gc,'Text','Area (cm^2):','HorizontalAlignment','right');
    edArea = uieditfield(gc,'text','Value','');
    edArea.ValueChangedFcn = @(~,~) refreshCompare();
    edArea.Layout.Row = 2; edArea.Layout.Column = 2;

    uilabel(gc,'Text','CT charge / CSC:','HorizontalAlignment','right');
    txtQct = uieditfield(gc,'text','Editable','off');
    txtQct.Layout.Row = 3; txtQct.Layout.Column = 2;

    uilabel(gc,'Text','CV charge / CSC:','HorizontalAlignment','right');
    txtQcv = uieditfield(gc,'text','Editable','off');
    txtQcv.Layout.Row = 4; txtQcv.Layout.Column = 2;

    uilabel(gc,'Text','Difference:','HorizontalAlignment','right');
    txtDiff = uieditfield(gc,'text','Editable','off');
    txtDiff.Layout.Row = 5; txtDiff.Layout.Column = 2;

    uilabel(gc,'Text','Relative diff:','HorizontalAlignment','right');
    txtRel = uieditfield(gc,'text','Editable','off');
    txtRel.Layout.Row = 6; txtRel.Layout.Column = 2;

    uilabel(gc,'Text','max|dt-|dV|/v|:','HorizontalAlignment','right');
    txtDtErr = uieditfield(gc,'text','Editable','off');
    txtDtErr.Layout.Row = 7; txtDtErr.Layout.Column = 2;

    lblStatus = uilabel(gc,'Text','Ready');
    lblStatus.Layout.Row = 8; lblStatus.Layout.Column = [1 2];
    lblStatus.FontWeight = 'bold';

    % -------- Log --------
    pLog = uipanel(left,'Title','Log Output');
    pLog.Layout.Row = 4;
    glog = uigridlayout(pLog,[1 1]);
    glog.Padding = [8 8 8 8];
    txtLog = uitextarea(glog,'Editable','off');
    txtLog.Value = {'GUI started.'};

    %% RIGHT: plots
    rightPanel = uipanel(main,'Title','Plots');
    rightPanel.Layout.Row = 1;
    rightPanel.Layout.Column = 3;

    right = uigridlayout(rightPanel,[4 1]);
    right.RowHeight = {'fit','1x','fit','1x'};
    right.RowSpacing = 10;
    right.Padding = [8 8 8 8];

    % -------- Top controls --------
    pTopCtl = uipanel(right,'Title','Top Plot');
    pTopCtl.Layout.Row = 1;
    gt = uigridlayout(pTopCtl,[1 6]);
    gt.ColumnWidth = {'fit','1x','fit','1x','fit','fit'};
    gt.RowHeight = {'fit'};
    gt.Padding = [8 6 8 6];
    gt.ColumnSpacing = 8;

    uilabel(gt,'Text','X:','HorizontalAlignment','right');
    ddTopX = uidropdown(gt,'Items',{'(none)'},'ValueChangedFcn',@(~,~) plotTop());
    uilabel(gt,'Text','Y:','HorizontalAlignment','right');
    ddTopY = uidropdown(gt,'Items',{'(none)'},'ValueChangedFcn',@(~,~) plotTop());

    topOptions = uigridlayout(gt,[1 3]);
    topOptions.ColumnWidth = {'fit','fit','fit'};
    topOptions.RowHeight = {'fit'};
    topOptions.Padding = [0 0 0 0];
    topOptions.ColumnSpacing = 10;
    cbTopGrid = uicheckbox(topOptions,'Text','Grid','Value',true,'ValueChangedFcn',@(~,~) plotTop());
    cbTopHold = uicheckbox(topOptions,'Text','Hold','Value',false);
    cbTopTrim = uicheckbox(topOptions,'Text','Show Trim','Value',true,'ValueChangedFcn',@(~,~) refreshCompare());

    axTop = uiaxes(right);
    axTop.Layout.Row = 2;
    title(axTop,'Top Plot');
    xlabel(axTop,'X');
    ylabel(axTop,'Y');

    % -------- Bottom controls --------
    pBotCtl = uipanel(right,'Title','Bottom Plot');
    pBotCtl.Layout.Row = 3;
    gb = uigridlayout(pBotCtl,[1 6]);
    gb.ColumnWidth = {'fit','1x','fit','1x','fit','fit'};
    gb.RowHeight = {'fit'};
    gb.Padding = [8 6 8 6];
    gb.ColumnSpacing = 8;

    uilabel(gb,'Text','X:','HorizontalAlignment','right');
    ddBotX = uidropdown(gb,'Items',{'(none)'},'ValueChangedFcn',@(~,~) plotBottom());
    uilabel(gb,'Text','Y:','HorizontalAlignment','right');
    ddBotY = uidropdown(gb,'Items',{'(none)'},'ValueChangedFcn',@(~,~) plotBottom());

    botOptions = uigridlayout(gb,[1 3]);
    botOptions.ColumnWidth = {'fit','fit','fit'};
    botOptions.RowHeight = {'fit'};
    botOptions.Padding = [0 0 0 0];
    botOptions.ColumnSpacing = 10;
    cbBotGrid = uicheckbox(botOptions,'Text','Grid','Value',true,'ValueChangedFcn',@(~,~) plotBottom());
    cbBotHold = uicheckbox(botOptions,'Text','Hold','Value',false);
    cbBotTrim = uicheckbox(botOptions,'Text','Show Trim','Value',true,'ValueChangedFcn',@(~,~) refreshCompare());

    axBottom = uiaxes(right);
    axBottom.Layout.Row = 4;
    title(axBottom,'Bottom Plot');
    xlabel(axBottom,'X');
    ylabel(axBottom,'Y');
    if nargout == 1
        varargout{1} = fig;
    end

    %% ===================== Callbacks =====================
    function onOpenFile(~,~)
        [f,p] = uigetfile({'*.DTA;*.dta','Gamry DTA (*.DTA)';'*.*','All Files'}, ...
            'Select Gamry DTA file');
        if isequal(f,0)
            addLog('Open file canceled.');
            return;
        end
        S.filepath = fullfile(p,f);
        loadFile(S.filepath);
    end

    function onReloadFile()
        if isempty(S.filepath) || ~isfile(S.filepath)
            uialert(fig,'No valid file loaded.','Reload Error');
            addLog('Reload failed: no valid file loaded.');
            return;
        end
        loadFile(S.filepath);
    end

    function onCurveChanged()
        if isempty(S.curves)
            return;
        end
        idx = find(strcmp(ddCurve.Items, ddCurve.Value),1);
        if isempty(idx), idx = 1; end
        S.currentCurve = idx;
        syncSessionCurrentCurve();
        addLog(sprintf('Selected curve %d', idx));
        updateDropdowns();
        autoSetDefaults();
        refreshAll();
    end

    function autoPresetAndRefresh()
        autoSetDefaults();
        refreshAll();
    end

    function onSwapPlots()
        tx = ddTopX.Value; ty = ddTopY.Value;
        bx = ddBotX.Value; by = ddBotY.Value;

        if any(strcmp(ddTopX.Items,bx)), ddTopX.Value = bx; end
        if any(strcmp(ddTopY.Items,by)), ddTopY.Value = by; end
        if any(strcmp(ddBotX.Items,tx)), ddBotX.Value = tx; end
        if any(strcmp(ddBotY.Items,ty)), ddBotY.Value = ty; end

        addLog('Swapped top/bottom selections.');
        refreshPlotsOnly();
        refreshCompare();
    end

    function clearBothAxes()
        cla(axTop);
        cla(axBottom);
        title(axTop,'Top Plot'); xlabel(axTop,'X'); ylabel(axTop,'Y');
        title(axBottom,'Bottom Plot'); xlabel(axBottom,'X'); ylabel(axBottom,'Y');
        addLog('Cleared both axes.');
    end

    function loadFile(filepath)
        addLog(['Loading file: ' filepath]);

        callbacks = struct();
        callbacks.onFailed = @(~, message) addLog(['Parse failed: ' message]);
        [loadedSession, report] = gamrywb.data.addFilesToSession( ...
            gamrywb.data.makeSession('cv_csc'), {filepath}, @loadOneCVCT, callbacks);
        if ~isempty(report.failed)
            ME = report.failed(1);
            uialert(fig, ME.message, 'Parse Error');
            return;
        end
        item = loadedSession.items(1);

        for i = 1:numel(item.logmsg)
            addLog(item.logmsg{i});
        end

        S.session = loadedSession;
        S.filepath = item.filepath;
        S.scanRate = item.scanRate;
        S.curves = item.curves;
        S.currentCurve = 1;
        txtFile.Value = filepath;

        if isnan(S.scanRate)
            txtScan.Value = 'Not found';
        else
            txtScan.Value = sprintf('%.6f V/s (%.3f mV/s)', S.scanRate, S.scanRate*1000);
        end

        if isempty(S.curves)
            ddCurve.Items = {'(none)'};
            ddCurve.Value = '(none)';
            lblStatus.Text = 'No curve found';
            addLog('No curve parsed.');
            return;
        end

        items = cell(1,numel(S.curves));
        for k = 1:numel(S.curves)
            items{k} = sprintf('%s (%d rows)', S.curves(k).name, size(S.curves(k).data,1));
        end
        ddCurve.Items = items;
        ddCurve.Value = items{1};

        lblStatus.Text = sprintf('Loaded %d curve(s)', numel(S.curves));
        addLog(sprintf('Loaded %d curve(s).', numel(S.curves)));

        updateDropdowns();
        autoSetDefaults();
        refreshAll();
    end

    function item = loadOneCVCT(filepath)
        [item, status] = gamrywb.dta.loadFile(filepath, "cvct");
        if ~status.ok
            error('%s', char(status.message));
        end
        item.currentCurve = 1;
        item.analysis = [];
    end

    function syncSessionCurrentCurve()
        if ~isempty(S.session.items)
            S.session.items(1).currentCurve = S.currentCurve;
        end
    end

    function updateDropdowns()
        if isempty(S.curves), return; end
        c = S.curves(S.currentCurve);
        cols = c.headers(c.numericMask);
        if isempty(cols)
            cols = {'(none)'};
        end
        ddTopX.Items = cols;
        ddTopY.Items = cols;
        ddBotX.Items = cols;
        ddBotY.Items = cols;
        addLog(['Numeric columns: ' strjoin(cols, ', ')]);
    end

    function autoSetDefaults()
        if isempty(S.curves), return; end
        setDropdownValueIfExists(ddTopX,'Vf');
        setDropdownValueIfExists(ddTopY,'Im');
        setDropdownValueIfExists(ddBotX,'T');
        setDropdownValueIfExists(ddBotY,'Im');
    end

    function refreshPlotsOnly()
        if isempty(S.curves), return; end
        plotTop();
        plotBottom();
    end

    function refreshAll()
        refreshPlotsOnly();
        refreshCompare();
    end

    % -------- Draggable divider --------
    function startDrag(~,~)
        % Begin tracking horizontal drag on the separator bar
        S.isDragging = true;
        fig.WindowButtonMotionFcn = @doDrag;
        fig.WindowButtonUpFcn = @stopDrag;
        fig.Pointer = 'leftarrow';
    end

    function doDrag(~,~)
        % Resize left panel while dragging; clamp to sensible bounds
        if ~S.isDragging, return; end
        cp = fig.CurrentPoint;
        pad = main.Padding;
        newW = cp(1) - pad(1);
        minW = 220;
        maxW = max(320, fig.Position(3) - 320);
        newW = min(maxW, max(minW, newW));
        main.ColumnWidth = {newW,6,'1x'};
    end

    function stopDrag(~,~)
        % Stop drag tracking and reset cursor
        S.isDragging = false;
        fig.WindowButtonMotionFcn = '';
        fig.WindowButtonUpFcn = '';
        fig.Pointer = 'arrow';
    end

    function plotTop()
        if isempty(S.curves), return; end
        c = S.curves(S.currentCurve);
        opts = struct('holdPlot', cbTopHold.Value, 'showGrid', cbTopGrid.Value, 'lineWidth', 1.2);
        info = gamrywb.ui.plotCurveXY(axTop, c, ddTopX.Value, ddTopY.Value, opts);
        if ~info.ok
            addLog('Top plot skipped: invalid X/Y.');
            return;
        end
        addLog(sprintf('Top plot: %s vs %s, n=%d', info.yName, info.xName, numel(info.x)));
    end

    function plotBottom()
        if isempty(S.curves), return; end
        c = S.curves(S.currentCurve);
        opts = struct('holdPlot', cbBotHold.Value, 'showGrid', cbBotGrid.Value, 'lineWidth', 1.2);
        info = gamrywb.ui.plotCurveXY(axBottom, c, ddBotX.Value, ddBotY.Value, opts);
        if ~info.ok
            addLog('Bottom plot skipped: invalid X/Y.');
            return;
        end
        addLog(sprintf('Bottom plot: %s vs %s, n=%d', info.yName, info.xName, numel(info.x)));
    end

    function refreshCompare()
        if isempty(S.curves)
            txtQct.Value = '';
            txtQcv.Value = '';
            txtDiff.Value = '';
            txtRel.Value = '';
            txtDtErr.Value = '';
            return;
        end

        c = S.curves(S.currentCurve);
        opts = struct();
        opts.mode = ddMode.Value;
        opts.scanRate = S.scanRate;
        opts.area_cm2 = edArea.Value;
        R = computeCSC(c, opts);

        if ~R.ok
            txtQct.Value = R.message;
            txtQcv.Value = R.message;
            txtDiff.Value = '-';
            txtRel.Value = '-';
            txtDtErr.Value = '-';
            if isfield(R, 'logMessage') && ~isempty(R.logMessage)
                addLog(R.logMessage);
            end
            return;
        end

        txtQct.Value = formatChargeAndCSC(R.Qct, R.area_cm2);
        txtQcv.Value = formatChargeAndCSC(R.Qcv, R.area_cm2);
        txtDiff.Value = formatChargeAndCSC(R.diff_C, R.area_cm2);
        txtRel.Value = sprintf('%.6f %%', R.rel_pct);
        txtDtErr.Value = sprintf('%.6e s', R.dtErr);

        clearTrim(axTop);
        clearTrim(axBottom);

        if cbTopTrim.Value && strcmp(ddTopY.Value,'Im')
            [xTop, ~, ~, ~] = gamrywb.data.getCurveXY(c, ddTopX.Value, ddTopY.Value);
            if numel(xTop) == numel(R.IcathDisp)
                hold(axTop,'on');
                plot(axTop, xTop, R.IcathDisp, 'Color',[0.1 0.6 0.1], ...
                    'LineWidth',1.0,'Tag','trimCath');
                plot(axTop, xTop, R.IanodDisp, 'Color',[0.8 0.3 0.1], ...
                    'LineWidth',1.0,'Tag','trimAnod');
                hold(axTop,'off');
            end
        end

        if cbBotTrim.Value && strcmp(ddBotY.Value,'Im')
            [xBot, ~, ~, ~] = gamrywb.data.getCurveXY(c, ddBotX.Value, ddBotY.Value);
            if numel(xBot) == numel(R.IcathDisp)
                hold(axBottom,'on');
                plot(axBottom, xBot, R.IcathDisp, 'Color',[0.1 0.6 0.1], ...
                    'LineWidth',1.0,'Tag','trimCath');
                plot(axBottom, xBot, R.IanodDisp, 'Color',[0.8 0.3 0.1], ...
                    'LineWidth',1.0,'Tag','trimAnod');
                hold(axBottom,'off');
            end
        end

        addLog(sprintf(['Compare [%s]: Qct=%.6e C, Qcv=%.6e C, ', ...
            'rel=%.6f %%, maxdt=%.3e s'], ...
            ddMode.Value, R.Qct, R.Qcv, R.rel_pct, R.dtErr));

        if isnan(R.area_cm2)
            lblStatus.Text = 'Charge shown (area not set)';
        else
            lblStatus.Text = sprintf('CSC normalized by %.6g cm^2', R.area_cm2);
        end
    end

    function addLog(msg)
        gamrywb.ui.appendLog(txtLog, msg);
    end
end

%% ===================== Charge / CSC helpers =====================

function s = formatChargeAndCSC(Q, area_cm2)
    if isnan(area_cm2) || area_cm2 <= 0
        s = sprintf('%.12e C', Q);
    else
        CSC_mC_cm2 = 1e3 * Q / area_cm2; % C -> mC/cm^2
        s = sprintf('%.12e C | %.12e mC/cm^2', Q, CSC_mC_cm2);
    end
end

function clearTrim(ax)
    delete(findobj(ax,'Tag','trimCath'));
    delete(findobj(ax,'Tag','trimAnod'));
end

function setDropdownValueIfExists(dd, valueText)
    if any(strcmp(dd.Items, valueText))
        dd.Value = valueText;
    elseif ~isempty(dd.Items)
        dd.Value = dd.Items{1};
    end
end

function tf = isCSCAnalysisTestRequest(args)
    tf = numel(args) == 3 ...
        && (ischar(args{1}) || (isstring(args{1}) && isscalar(args{1}))) ...
        && strcmp(char(args{1}), '__test_computeCSC__');
end

function A = computeCSC(curve, opts)
%COMPUTECSC Compute CV/CT charge comparison and CSC for the CSC app.

    if nargin < 2
        opts = struct();
    end
    opts = fillOptions(opts);

    A = struct();
    A.ok = false;
    A.message = '';
    A.logMessage = '';
    A.mode = opts.mode;
    A.scanRate = opts.scanRate;
    A.area_cm2 = gamrywb.util.parsePositiveScalar(opts.area_cm2);

    if ~(isscalar(A.scanRate) && isfinite(A.scanRate) && A.scanRate > 0)
        A.message = 'scan rate missing';
        A.logMessage = 'Compare skipped: scan rate missing.';
        return;
    end

    if ~hasExactColumns(curve, {'T', 'Vf', 'Im'})
        A.message = 'Need T, Vf, Im';
        A.logMessage = 'Compare skipped: T/Vf/Im not all present.';
        return;
    end

    t = exactColumn(curve, 'T');
    V = exactColumn(curve, 'Vf');
    I = exactColumn(curve, 'Im');

    good = ~(isnan(t) | isnan(V) | isnan(I));
    t = t(good);
    V = V(good);
    I = I(good);

    if numel(t) < 2
        A.message = 'Not enough points';
        A.logMessage = 'Compare skipped: not enough valid points.';
        return;
    end

    CT = computeCTCharge(t, V, I);
    CV = computeCVCharge(t, V, I, A.scanRate);
    if ~CT.ok
        A.message = CT.message;
        A.logMessage = 'Compare skipped: not enough valid points.';
        return;
    end
    if ~CV.ok
        A.message = CV.message;
        A.logMessage = 'Compare skipped: scan rate missing.';
        return;
    end

    A.t = t;
    A.Vf = V;
    A.Im = I;
    A.IcathDisp = CT.IcathDisp;
    A.IanodDisp = CT.IanodDisp;
    A.QctCath = CT.QctCath;
    A.QctAnod = CT.QctAnod;
    A.QctFull = CT.QctFull;
    A.QcvCath = CV.QcvCath;
    A.QcvAnod = CV.QcvAnod;
    A.QcvFull = CV.QcvFull;
    A.dtErr = CV.dtErr;

    switch A.mode
        case 'Cathodic'
            A.Qct = A.QctCath;
            A.Qcv = A.QcvCath;
        case 'Anodic'
            A.Qct = A.QctAnod;
            A.Qcv = A.QcvAnod;
        otherwise
            A.mode = 'Full';
            A.Qct = A.QctFull;
            A.Qcv = A.QcvFull;
    end

    A.diff_C = A.Qct - A.Qcv;
    denom = max(abs(A.Qct), abs(A.Qcv));
    if denom == 0
        A.rel_pct = 0;
    else
        A.rel_pct = 100 * abs(A.diff_C) / denom;
    end

    if isfinite(A.area_cm2) && A.area_cm2 > 0
        A.Qct_mC_cm2 = 1e3 * A.Qct / A.area_cm2;
        A.Qcv_mC_cm2 = 1e3 * A.Qcv / A.area_cm2;
        A.diff_mC_cm2 = 1e3 * A.diff_C / A.area_cm2;
    else
        A.Qct_mC_cm2 = NaN;
        A.Qcv_mC_cm2 = NaN;
        A.diff_mC_cm2 = NaN;
    end

    A.ok = true;
    A.message = 'OK';
end

function opts = fillOptions(opts)
    if ~isfield(opts, 'mode')
        opts.mode = 'Full';
    end
    if ~isfield(opts, 'scanRate')
        opts.scanRate = NaN;
    end
    if ~isfield(opts, 'area_cm2')
        opts.area_cm2 = NaN;
    end
end

function tf = hasExactColumns(curve, names)
    tf = isfield(curve, 'headers');
    if ~tf
        return;
    end
    for k = 1:numel(names)
        if ~any(strcmp(curve.headers, names{k}))
            tf = false;
            return;
        end
    end
end

function col = exactColumn(curve, name)
    idx = find(strcmp(curve.headers, name), 1);
    if isempty(idx)
        col = [];
    else
        col = curve.data(:, idx);
    end
end

function R = computeCTCharge(t, V, I)
    R = struct();
    R.ok = false;
    R.message = '';

    if nargin < 3 || numel(t) < 2 || numel(V) < 2 || numel(I) < 2
        R.message = 'Not enough points';
        R = fillEmptyCT(R);
        return;
    end

    S = integrateCVCTSignSplit(t, V, I, NaN);
    R = copyFields(R, S, {'QctCath', 'QctAnod', 'IcathDisp', 'IanodDisp'});
    R.QctFull = R.QctCath + R.QctAnod;
    R.ok = true;
    R.message = 'OK';
end

function R = computeCVCharge(t, V, I, scanRate)
    R = struct();
    R.ok = false;
    R.message = '';

    if nargin < 4 || ~(isscalar(scanRate) && isfinite(scanRate) && scanRate > 0)
        R.message = 'scan rate missing';
        R = fillEmptyCV(R);
        return;
    end
    if numel(t) < 2 || numel(V) < 2 || numel(I) < 2
        R.message = 'Not enough points';
        R = fillEmptyCV(R);
        return;
    end

    S = integrateCVCTSignSplit(t, V, I, scanRate);
    R = copyFields(R, S, {'QcvCath', 'QcvAnod', 'dtErr', 'IcathDisp', 'IanodDisp'});
    R.QcvFull = R.QcvCath + R.QcvAnod;
    R.ok = true;
    R.message = 'OK';
end

function R = integrateCVCTSignSplit(t, V, I, scanRate)
    if nargin < 4
        scanRate = NaN;
    end

    t = t(:);
    V = V(:);
    I = I(:);

    R = struct();
    R.QctCath = 0;
    R.QctAnod = 0;
    R.QcvCath = 0;
    R.QcvAnod = 0;
    R.dtErr = NaN;

    R.IcathDisp = I;
    R.IanodDisp = I;
    R.IcathDisp(I >= 0) = NaN;
    R.IanodDisp(I <= 0) = NaN;

    dtErrList = [];
    useCV = isscalar(scanRate) && isfinite(scanRate) && scanRate > 0;

    for k = 1:numel(t)-1
        t1 = t(k);   t2 = t(k+1);
        V1 = V(k);   V2 = V(k+1);
        I1 = I(k);   I2 = I(k+1);

        if any(~isfinite([t1 t2 V1 V2 I1 I2]))
            continue;
        end

        bp = [0, 1];
        s0 = crossingFraction(I1, I2, 0);
        if ~isempty(s0)
            bp(end+1) = s0; %#ok<AGROW>
        end
        bp = unique(sort(bp));

        for j = 1:numel(bp)-1
            sa = bp(j);
            sb = bp(j+1);

            ta = lerp(t1, t2, sa);
            tb = lerp(t1, t2, sb);
            Va = lerp(V1, V2, sa);
            Vb = lerp(V1, V2, sb);
            Ia = lerp(I1, I2, sa);
            Ib = lerp(I1, I2, sb);

            Imid = 0.5 * (Ia + Ib);
            if Imid < 0
                R.QctCath = R.QctCath + abs(trapz([ta tb], [Ia Ib]));
            elseif Imid > 0
                R.QctAnod = R.QctAnod + trapz([ta tb], [Ia Ib]);
            end

            if useCV
                dt_act = tb - ta;
                dt_cv = abs(Vb - Va) / scanRate;
                dtErrList(end+1) = abs(dt_act - dt_cv); %#ok<AGROW>

                if Imid < 0
                    R.QcvCath = R.QcvCath + abs(trapz([0 dt_cv], [Ia Ib]));
                elseif Imid > 0
                    R.QcvAnod = R.QcvAnod + trapz([0 dt_cv], [Ia Ib]);
                end
            end
        end
    end

    if ~isempty(dtErrList)
        R.dtErr = max(dtErrList);
    end
end

function R = fillEmptyCT(R)
    R.QctCath = 0;
    R.QctAnod = 0;
    R.QctFull = 0;
    R.IcathDisp = [];
    R.IanodDisp = [];
end

function R = fillEmptyCV(R)
    R.QcvCath = 0;
    R.QcvAnod = 0;
    R.QcvFull = 0;
    R.dtErr = NaN;
    R.IcathDisp = [];
    R.IanodDisp = [];
end

function out = copyFields(out, in, names)
    for k = 1:numel(names)
        out.(names{k}) = in.(names{k});
    end
end

function y = lerp(a, b, s)
    y = a + s * (b - a);
end

function s = crossingFraction(y1, y2, y0)
    if ~isfinite(y1) || ~isfinite(y2) || y1 == y2
        s = [];
        return;
    end
    s = (y0 - y1) / (y2 - y1);
    if ~(s > 0 && s < 1)
        s = [];
    end
end
