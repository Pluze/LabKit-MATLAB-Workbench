% App-owned action registry for Video Marker. Expected caller is
% video_marker.definition. Handlers own video loading, frame navigation,
% marker editing, project files, and CSV exports.
function actions = definitionActions()
    S = [];
    ui = [];
    fig = [];
    debugLog = [];
    imageRuntime = [];
    pointEditor = [];
    scaleTool = [];
    videoReader = [];

    actions = struct( ...
        "startup", @onStartup, ...
        "openVideo", @onOpenVideo, ...
        "frameChanged", @onFrameChanged, ...
        "previousFrame", @onPreviousFrame, ...
        "nextFrame", @onNextFrame, ...
        "startPointEdit", @onStartPointEdit, ...
        "undoPoint", @onUndoPoint, ...
        "clearFramePoints", @onClearFramePoints, ...
        "confirmFrame", @onConfirmFrame, ...
        "applySkeleton", @onApplySkeleton, ...
        "importMarkerCsv", @onImportMarkerCsv, ...
        "exportMarkerCsv", @onExportMarkerCsv, ...
        "exportCoordinateCsv", @onExportCoordinateCsv, ...
        "openProject", @onOpenProject, ...
        "saveProject", @onSaveProject);

    function state = onStartup(state, ~, services)
        S = state;
        ui = services.ui;
        fig = services.figure;
        debugLog = services.debug;
        ax = ui.controls.videoAxes.primaryAxes;
        imageRuntime = labkit.ui.interaction.runtime(ax, struct( ...
            'figure', fig, ...
            'onTrace', debugLog.trace));
        scaleTool = labkit.ui.interaction.scaleBar(ui.controls.scaleBarHost.grid, ...
            1, imageRuntime, struct( ...
            'onBeforeReferenceEdit', @onBeforeReferenceEdit, ...
            'onCalibrationChanged', @onCalibrationChanged, ...
            'onError', @onScaleToolError, ...
            'onTrace', debugLog.trace));
        if debugLog.enabled
            debugLog.trace('Video marker debug trace enabled.');
            debugLog.instrumentFigure(fig);
            setupDebugSamples();
        end
        refreshAll();
        state = S;
    end

    function state = onOpenVideo(state, payload, services)
        capture(state, services);
        paths = labkit.ui.control.filePaths(payload.event.files);
        if isempty(paths)
            paths = labkit.ui.control.filePaths(payload.event.addedFiles);
        end
        if isempty(paths)
            addLog('Video selection cancelled.');
            state = S;
            return;
        end
        openVideoPath(paths(1));
        state = S;
    end

    function state = onFrameChanged(state, ~, services)
        capture(state, services);
        if ~hasVideo()
            state = S;
            return;
        end
        target = round(double(labkit.ui.control.getValue(ui, 'currentFrame')));
        goToFrame(target);
        state = S;
    end

    function state = onPreviousFrame(state, ~, services)
        capture(state, services);
        goToFrame(S.currentFrame - 1);
        state = S;
    end

    function state = onNextFrame(state, ~, services)
        capture(state, services);
        goToFrame(S.currentFrame + 1);
        state = S;
    end

    function state = onStartPointEdit(state, ~, services)
        capture(state, services);
        if ~hasVideo()
            showError('No video loaded', 'Open a video before editing points.');
            state = S;
            return;
        end
        if S.pointEditActive
            pointEditor.setActive(false);
            S.pointEditActive = false;
            addLog('Finished point edit.');
            refreshAll();
            state = S;
            return;
        end
        scaleTool.finishReferenceEdit(false);
        ensurePointEditor();
        S.pointEditActive = true;
        pointEditor.start(video_marker.frameAnnotations.framePoints(S.annotations, S.currentFrame));
        addLog('Started point edit. Click keypoints in order; drag points to refine.');
        refreshAll();
        state = S;
    end

    function state = onUndoPoint(state, ~, services)
        capture(state, services);
        if ~isempty(pointEditor)
            pointEditor.undoLast();
        end
        state = S;
    end

    function state = onClearFramePoints(state, ~, services)
        capture(state, services);
        S.annotations = video_marker.frameAnnotations.setFramePoints( ...
            S.annotations, S.currentFrame, zeros(0, 2), "empty");
        S.pointEditActive = false;
        if ~isempty(pointEditor)
            pointEditor.clearPoints();
        end
        addLog(sprintf('Cleared frame %d points.', S.currentFrame));
        refreshAll();
        state = S;
    end

    function state = onConfirmFrame(state, ~, services)
        capture(state, services);
        points = currentEditorOrFramePoints();
        if size(points, 1) ~= numel(S.skeleton.pointIds)
            showError('Incomplete frame', 'Place every keypoint before confirming the frame.');
            state = S;
            return;
        end
        S.annotations = video_marker.frameAnnotations.setFramePoints( ...
            S.annotations, S.currentFrame, points, "confirmed");
        addLog(sprintf('Confirmed frame %d.', S.currentFrame));
        refreshAll();
        state = S;
    end

    function state = onApplySkeleton(state, ~, services)
        capture(state, services);
        try
            skeleton = video_marker.skeletonDefinition.fromText( ...
                labkit.ui.control.getValue(ui, 'keypointNames'), ...
                labkit.ui.control.getValue(ui, 'skeletonEdges'));
        catch ME
            showException('Invalid skeleton', ME);
            state = S;
            return;
        end
        S.skeleton = skeleton;
        S.annotations = video_marker.frameAnnotations.emptyAnnotations( ...
            S.videoInfo.frameCount, numel(S.skeleton.pointIds));
        S.pointEditActive = false;
        deletePointEditor();
        addLog(sprintf('Applied skeleton with %d keypoint(s). Existing frame marks were reset.', ...
            numel(S.skeleton.pointIds)));
        refreshAll();
        state = S;
    end

    function state = onImportMarkerCsv(state, ~, services)
        capture(state, services);
        [file, folder] = uigetfile({'*.csv', 'Marker CSV'}, 'Import marker CSV', ...
            labkit.ui.runtime.defaultDialogFolder("input"));
        if isequal(file, 0)
            addLog('Marker CSV import cancelled.');
            state = S;
            return;
        end
        try
            payload = video_marker.markerCsv.readFile(fullfile(folder, file));
        catch ME
            showException('Could not import marker CSV', ME);
            state = S;
            return;
        end
        S.skeleton = payload.skeleton;
        S.annotations = payload.annotations;
        S.videoInfo = payload.videoInfo;
        S.videoPath = string(payload.videoInfo.path);
        S.calibration = payload.calibration;
        if strlength(S.videoPath) > 0 && exist(S.videoPath, 'file') == 2
            try
                [videoReader, S.videoInfo] = video_marker.videoSource.openVideo(S.videoPath);
                S.currentFrame = 1;
                S.currentImage = video_marker.videoSource.readFrame(videoReader, 1);
                scaleTool.resetForNewImage(size(S.currentImage));
                scaleTool.setCalibration(S.calibration);
            catch ME
                debugLog.reportException('videoMarker', 'Could not reopen marker CSV video', ME);
                S.currentImage = [];
            end
        end
        S.pointEditActive = false;
        deletePointEditor();
        addLog(sprintf('Imported marker CSV: %s', fullfile(folder, file)));
        refreshAll();
        state = S;
    end

    function state = onExportMarkerCsv(state, ~, services)
        capture(state, services);
        if ~hasVideo()
            showError('No video loaded', 'Open a video before exporting marker CSV.');
            state = S;
            return;
        end
        [filepath, cancelled] = labkit.ui.runtime.promptOutputFile( ...
            '*.csv', 'Export marker CSV', 'video_marker_markers.csv');
        if cancelled
            addLog('Marker CSV export cancelled.');
            state = S;
            return;
        end
        try
            S.calibration = scaleTool.calibration();
            video_marker.markerCsv.writeFile(filepath, S.annotations, S.skeleton, S.videoInfo, S.calibration);
        catch ME
            showException('Could not export marker CSV', ME);
            state = S;
            return;
        end
        addLog(sprintf('Exported marker CSV: %s', filepath));
        state = S;
    end

    function state = onExportCoordinateCsv(state, ~, services)
        capture(state, services);
        if ~hasVideo()
            showError('No video loaded', 'Open a video before exporting coordinate CSV.');
            state = S;
            return;
        end
        opts = video_marker.coordinateExport.options( ...
            "startFrame", labkit.ui.control.getValue(ui, 'coordinateStartFrame'), ...
            "endFrame", labkit.ui.control.getValue(ui, 'coordinateEndFrame'), ...
            "unitMode", labkit.ui.control.getValue(ui, 'coordinateUnitMode'), ...
            "originMode", labkit.ui.control.getValue(ui, 'coordinateOriginMode'), ...
            "yAxisMode", labkit.ui.control.getValue(ui, 'coordinateYAxisMode'));
        [filepath, cancelled] = labkit.ui.runtime.promptOutputFile( ...
            '*.csv', 'Export coordinate CSV', 'video_marker_coordinates.csv');
        if cancelled
            addLog('Coordinate CSV export cancelled.');
            state = S;
            return;
        end
        try
            S.calibration = scaleTool.calibration();
            T = video_marker.coordinateExport.buildTable( ...
                S.annotations, S.skeleton, S.videoInfo, S.calibration, opts);
            writetable(T, filepath);
        catch ME
            showException('Could not export coordinate CSV', ME);
            state = S;
            return;
        end
        addLog(sprintf('Exported coordinate CSV: %s', filepath));
        state = S;
    end

    function state = onOpenProject(state, ~, services)
        capture(state, services);
        [file, folder] = uigetfile({'*.mat', 'Video Marker project'}, 'Open Video Marker project', ...
            labkit.ui.runtime.defaultDialogFolder("input"));
        if isequal(file, 0)
            addLog('Project open cancelled.');
            state = S;
            return;
        end
        try
            loaded = video_marker.projectFiles.loadProject(fullfile(folder, file));
        catch ME
            showException('Could not open project', ME);
            state = S;
            return;
        end
        S = loaded;
        S.projectPath = string(fullfile(folder, file));
        if strlength(S.videoPath) > 0 && exist(S.videoPath, 'file') == 2
            try
                [videoReader, S.videoInfo] = video_marker.videoSource.openVideo(S.videoPath);
                S.currentFrame = min(max(1, S.currentFrame), S.videoInfo.frameCount);
                S.currentImage = video_marker.videoSource.readFrame(videoReader, S.currentFrame);
            catch ME
                debugLog.reportException('videoMarker', 'Could not reopen project video', ME);
            end
        end
        scaleTool.resetForNewImage(size(S.currentImage));
        scaleTool.setCalibration(S.calibration);
        S.pointEditActive = false;
        deletePointEditor();
        addLog(sprintf('Opened project: %s', S.projectPath));
        refreshAll();
        state = S;
    end

    function state = onSaveProject(state, ~, services)
        capture(state, services);
        defaultName = "video_marker_project.mat";
        [filepath, cancelled] = labkit.ui.runtime.promptOutputFile( ...
            '*.mat', 'Save Video Marker project', defaultName);
        if cancelled
            addLog('Project save cancelled.');
            state = S;
            return;
        end
        try
            S.calibration = scaleTool.calibration();
            S.projectPath = string(filepath);
            video_marker.projectFiles.saveProject(filepath, S);
        catch ME
            showException('Could not save project', ME);
            state = S;
            return;
        end
        addLog(sprintf('Saved project: %s', filepath));
        state = S;
    end

    function capture(state, services)
        if isempty(S)
            S = state;
        end
        if isempty(ui) && isfield(services, 'ui')
            ui = services.ui;
        end
        if isempty(fig) && isfield(services, 'figure')
            fig = services.figure;
        end
        if isempty(debugLog) && isfield(services, 'debug')
            debugLog = services.debug;
        end
    end

    function openVideoPath(pathValue)
        try
            [videoReader, info] = video_marker.videoSource.openVideo(pathValue);
            frame = video_marker.videoSource.readFrame(videoReader, 1);
        catch ME
            showException('Could not open video', ME);
            return;
        end
        S.videoPath = string(pathValue);
        S.videoInfo = info;
        S.currentFrame = 1;
        S.currentImage = frame;
        S.annotations = video_marker.frameAnnotations.emptyAnnotations( ...
            info.frameCount, numel(S.skeleton.pointIds));
        S.outputFolder = string(labkit.ui.runtime.defaultOutputFolder(S.videoPath, "video_marker"));
        scaleTool.resetForNewImage(size(frame));
        S.pointEditActive = false;
        deletePointEditor();
        addLog(sprintf('Opened video: %s', S.videoPath));
        refreshAll();
    end

    function goToFrame(frameIndex)
        if ~hasVideo()
            return;
        end
        frameIndex = min(max(1, round(double(frameIndex))), S.videoInfo.frameCount);
        if frameIndex == S.currentFrame
            refreshAll();
            return;
        end
        try
            frame = video_marker.videoSource.readFrame(videoReader, frameIndex);
        catch ME
            showException('Could not read frame', ME);
            refreshAll();
            return;
        end
        S.currentFrame = frameIndex;
        S.currentImage = frame;
        if S.annotations.frameStatus(frameIndex) == video_marker.frameAnnotations.statusCode("empty")
            S.annotations = video_marker.frameAnnotations.inheritDraft(S.annotations, frameIndex);
        end
        S.pointEditActive = false;
        deletePointEditor();
        addLog(sprintf('Moved to frame %d.', frameIndex));
        refreshAll();
    end

    function ensurePointEditor()
        if isempty(pointEditor)
            pointEditor = labkit.ui.interaction.anchorEditor(imageRuntime, size(S.currentImage), ...
                struct('mode', 'points', ...
                'maxPoints', numel(S.skeleton.pointIds), ...
                'onChanged', @onPointEditorChanged, ...
                'onTrace', debugLog.trace));
        else
            pointEditor.setImageSize(size(S.currentImage));
        end
    end

    function onPointEditorChanged(points, reason)
        S.annotations = video_marker.frameAnnotations.setFramePoints( ...
            S.annotations, S.currentFrame, points, "draft");
        if any(strcmp(string(reason), ["add point", "undo point", "clear points", "move point", "set points"]))
            addLog(sprintf('Frame %d draft points: %d / %d.', ...
                S.currentFrame, size(points, 1), numel(S.skeleton.pointIds)));
        end
        refreshSummaryControls();
        syncRuntimeState();
    end

    function onBeforeReferenceEdit(~, ~)
        if ~isempty(pointEditor)
            pointEditor.setActive(false);
        end
        S.pointEditActive = false;
        syncRuntimeState();
    end

    function onCalibrationChanged(~, ~)
        S.calibration = scaleTool.calibration();
        refreshAll();
        syncRuntimeState();
    end

    function onScaleToolError(titleText, message)
        showError(titleText, message);
    end

    function points = currentEditorOrFramePoints()
        if ~isempty(pointEditor)
            points = pointEditor.getPoints();
        else
            points = video_marker.frameAnnotations.framePoints(S.annotations, S.currentFrame);
        end
    end

    function tf = hasVideo()
        tf = S.videoInfo.frameCount > 0 && ~isempty(S.currentImage);
    end

    function deletePointEditor()
        if ~isempty(pointEditor)
            pointEditor.delete();
        end
        pointEditor = [];
    end

    function refreshAll()
        if hasVideo()
            labkit.ui.control.setValue(ui, 'videoFile', S.videoPath);
            labkit.ui.control.setLimits(ui, 'currentFrame', [1 max(2, S.videoInfo.frameCount)]);
            labkit.ui.control.setValue(ui, 'currentFrame', S.currentFrame);
            labkit.ui.control.setValue(ui, 'coordinateEndFrame', S.videoInfo.frameCount);
            refreshPreview();
        else
            labkit.ui.plot.reset(ui, 'videoAxes', 'Frame + Skeleton', true, 'raw');
        end
        labkit.ui.control.setValue(ui, 'keypointNames', strjoin(S.skeleton.pointNames, ", "));
        labkit.ui.control.setValue(ui, 'skeletonEdges', edgeText(S.skeleton));
        refreshSummaryControls();
        syncRuntimeState();
    end

    function refreshPreview()
        ax = ui.controls.videoAxes.primaryAxes;
        labkit.ui.plot.clear(ax, "ResetScale", true);
        hImage = video_marker.annotationCanvas.drawFrame( ...
            ui, 'videoAxes', S.currentImage, S.skeleton, S.annotations, S.currentFrame);
        if ~isempty(pointEditor)
            pointEditor.setBackground(hImage);
            pointEditor.refresh();
        elseif scaleTool.isReferenceEditActive()
            scaleTool.setBackground(hImage);
            scaleTool.refresh();
        end
        scaleTool.renderOverlay(ax);
    end

    function refreshSummaryControls()
        info = S.videoInfo;
        if info.frameCount > 0
            videoText = sprintf('%d frames | %.4g fps | %dx%d px', ...
                info.frameCount, info.frameRate, info.width, info.height);
        else
            videoText = 'No video loaded';
        end
        labkit.ui.control.setValue(ui, 'videoSummary', videoText);
        statusName = "empty";
        points = zeros(0, 2);
        if hasVideo()
            statusName = video_marker.frameAnnotations.statusName(S.annotations.frameStatus(S.currentFrame));
            points = video_marker.frameAnnotations.framePoints(S.annotations, S.currentFrame);
        end
        labkit.ui.control.setValue(ui, 'frameStatus', sprintf('Frame %d: %s | points %d / %d', ...
            S.currentFrame, statusName, size(points, 1), numel(S.skeleton.pointIds)));
        summary = video_marker.frameAnnotations.summary(S.annotations);
        labkit.ui.control.setValue(ui, 'summaryTable', { ...
            'Video', char(S.videoPath); ...
            'Frames', sprintf('%d', summary.frameCount); ...
            'Empty', sprintf('%d', summary.empty); ...
            'Draft', sprintf('%d', summary.draft); ...
            'Confirmed', sprintf('%d', summary.confirmed); ...
            'Keypoints', sprintf('%d', numel(S.skeleton.pointIds))});
        updateEnabledControls(size(points, 1));
    end

    function updateEnabledControls(currentPointCount)
        has = hasVideo();
        pointCount = numel(S.skeleton.pointIds);
        labkit.ui.control.setEnabled(ui, 'previousFrame', has && S.currentFrame > 1);
        labkit.ui.control.setEnabled(ui, 'nextFrame', has && S.currentFrame < S.videoInfo.frameCount);
        labkit.ui.control.setEnabled(ui, 'startPointEdit', has);
        labkit.ui.control.setEnabled(ui, 'undoPoint', has && currentPointCount > 0);
        labkit.ui.control.setEnabled(ui, 'clearFramePoints', has && currentPointCount > 0);
        labkit.ui.control.setEnabled(ui, 'confirmFrame', has && currentPointCount == pointCount);
        labkit.ui.control.setEnabled(ui, 'exportMarkerCsv', has);
        labkit.ui.control.setEnabled(ui, 'exportCoordinateCsv', has);
        labkit.ui.control.setEnabled(ui, 'saveProject', has);
        scaleTool.setEnabled(struct('hasImage', has, ...
            'blockInputs', S.pointEditActive, ...
            'blockPlacement', S.pointEditActive));
        scaleTool.updateReadout();
    end

    function syncRuntimeState()
        if isempty(fig) || ~isvalid(fig) || ~isappdata(fig, 'labkitUiAppRuntime')
            return;
        end
        runtime = getappdata(fig, 'labkitUiAppRuntime');
        runtime.state = S;
        setappdata(fig, 'labkitUiAppRuntime', runtime);
    end

    function addLog(message)
        labkit.ui.control.appendLog(ui, 'appLog', message);
        debugLog.append(message);
    end

    function setupDebugSamples()
        try
            pack = video_marker.debug.writeSamplePack(debugLog);
            addLog(sprintf('Debug sample files: %s', char(pack.sampleFolder)));
            addLog(sprintf('Debug output folder: %s', char(pack.outputFolder)));
        catch ME
            debugLog.reportException('videoMarker', 'Debug sample setup failed', ME);
            addLog(sprintf('Debug sample setup failed: %s', ME.message));
        end
    end

    function showError(titleText, message)
        addLog(sprintf('%s: %s', titleText, message));
        labkit.ui.runtime.showAlert(fig, message, titleText);
    end

    function showException(titleText, exception)
        debugLog.reportException('videoMarker', titleText, exception);
        showError(titleText, exception.message);
    end
end

function textValue = edgeText(skeleton)
    parts = strings(size(skeleton.edges, 1), 1);
    for k = 1:size(skeleton.edges, 1)
        parts(k) = skeleton.pointNames(skeleton.edges(k, 1)) + "-" + ...
            skeleton.pointNames(skeleton.edges(k, 2));
    end
    textValue = strjoin(parts, ", ");
end
