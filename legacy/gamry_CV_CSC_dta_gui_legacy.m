function gamry_CV_CSC_dta_gui_legacy
% GAMRY_CV_CSC_DTA_GUI
% GUI for Gamry DTA CV/CT integration and CSC computation.
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
% Usage
%   gamry_dta_gui

    % Application state container
    S = struct();
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

        try
            [scanRate, curves, parserLog] = gamrywb.io.parseCVCTDTA(filepath);
        catch ME
            addLog(['Parse failed: ' ME.message]);
            uialert(fig, ME.message, 'Parse Error');
            return;
        end

        for i = 1:numel(parserLog)
            addLog(parserLog{i});
        end

        S.scanRate = scanRate;
        S.curves = curves;
        S.currentCurve = 1;
        txtFile.Value = filepath;

        if isnan(scanRate)
            txtScan.Value = 'Not found';
        else
            txtScan.Value = sprintf('%.6f V/s (%.3f mV/s)', scanRate, scanRate*1000);
        end

        if isempty(curves)
            ddCurve.Items = {'(none)'};
            ddCurve.Value = '(none)';
            lblStatus.Text = 'No curve found';
            addLog('No curve parsed.');
            return;
        end

        items = cell(1,numel(curves));
        for k = 1:numel(curves)
            items{k} = sprintf('%s (%d rows)', curves(k).name, size(curves(k).data,1));
        end
        ddCurve.Items = items;
        ddCurve.Value = items{1};

        lblStatus.Text = sprintf('Loaded %d curve(s)', numel(curves));
        addLog(sprintf('Loaded %d curve(s).', numel(curves)));

        updateDropdowns();
        autoSetDefaults();
        refreshAll();
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
        [x,y,xn,yn] = getSelectedXY(c, ddTopX.Value, ddTopY.Value);
        if isempty(x) || isempty(y)
            addLog('Top plot skipped: invalid X/Y.');
            return;
        end

        if ~cbTopHold.Value
            cla(axTop);
        end
        plot(axTop, x, y, 'LineWidth', 1.2);
        grid(axTop, cbTopGrid.Value);
        title(axTop, c.name, 'Interpreter','none');
        xlabel(axTop, xn, 'Interpreter','none');
        ylabel(axTop, yn, 'Interpreter','none');
        addLog(sprintf('Top plot: %s vs %s, n=%d', yn, xn, numel(x)));
    end

    function plotBottom()
        if isempty(S.curves), return; end
        c = S.curves(S.currentCurve);
        [x,y,xn,yn] = getSelectedXY(c, ddBotX.Value, ddBotY.Value);
        if isempty(x) || isempty(y)
            addLog('Bottom plot skipped: invalid X/Y.');
            return;
        end

        if ~cbBotHold.Value
            cla(axBottom);
        end
        plot(axBottom, x, y, 'LineWidth', 1.2);
        grid(axBottom, cbBotGrid.Value);
        title(axBottom, c.name, 'Interpreter','none');
        xlabel(axBottom, xn, 'Interpreter','none');
        ylabel(axBottom, yn, 'Interpreter','none');
        addLog(sprintf('Bottom plot: %s vs %s, n=%d', yn, xn, numel(x)));
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
        R = gamrywb.analysis.computeCSC(c, opts);

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
            [xTop, ~, ~, ~] = getSelectedXY(c, ddTopX.Value, ddTopY.Value);
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
            [xBot, ~, ~, ~] = getSelectedXY(c, ddBotX.Value, ddBotY.Value);
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
        timestamp = datestr(now,'HH:MM:SS');
        old = txtLog.Value;
        old{end+1} = sprintf('[%s] %s', timestamp, char(msg));
        txtLog.Value = old;
        drawnow limitrate
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

%% ===================== DTA parser =====================

function [x,y,xname,yname] = getSelectedXY(curve, xsel, ysel)
    x = []; y = []; xname = ''; yname = '';
    if isempty(curve.headers) || isempty(curve.data), return; end

    ix = find(strcmp(curve.headers, xsel), 1);
    iy = find(strcmp(curve.headers, ysel), 1);
    if isempty(ix) || isempty(iy), return; end

    x = curve.data(:,ix);
    y = curve.data(:,iy);

    good = ~(isnan(x) | isnan(y));
    x = x(good);
    y = y(good);

    xname = curve.headers{ix};
    yname = curve.headers{iy};
end

function setDropdownValueIfExists(dd, valueText)
    if any(strcmp(dd.Items, valueText))
        dd.Value = valueText;
    elseif ~isempty(dd.Items)
        dd.Value = dd.Items{1};
    end
end
