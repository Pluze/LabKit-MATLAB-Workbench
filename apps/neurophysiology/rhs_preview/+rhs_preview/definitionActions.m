% App-owned Runtime V2 action table for RHS Preview. Handlers own RHS source
% indexing, lazy window reads, protocol/filter drafting, and semantic interval
% events without closure state, UI registry access, or figure callbacks.
function actions = definitionActions()
    actions = struct( ...
        "rhsChosen", @onRhsChosen, ...
        "folderChosen", @onFolderChosen, ...
        "folderRemoved", @onFolderRemoved, ...
        "folderCleared", @onFolderCleared, ...
        "protocolChosen", @onProtocolChosen, ...
        "settingChanged", @onSettingChanged, ...
        "previewChannelEdited", @onPreviewChannelEdited, ...
        "fileFilterEdited", @onFileFilterEdited, ...
        "refreshPreviewWindow", @onRefreshPreviewWindow, ...
        "refreshFolderFiles", @onRefreshFolderFiles, ...
        "previewRoiEdited", @onPreviewRoiEdited, ...
        "previewWindowScrolled", @onPreviewWindowScrolled, ...
        "zoomToRoi", @onZoomToRoi, ...
        "saveProtocol", @onSaveProtocol, ...
        "saveFilterRecord", @onSaveFilterRecord, ...
        "resetWorkflow", @onResetWorkflow);
end

function state = onRhsChosen(state, event, services)
    paths = services.events.paths(event, "addedFiles");
    if isempty(paths)
        paths = services.events.paths(event, "files");
    end
    if isempty(paths)
        return;
    end
    filepath = paths(1);
    [index, status] = labkit.rhs.indexFile(filepath);
    if ~status.ok
        state.session.workflow.statusMessage = string(status.message);
        state = services.workflow.log(state, ...
            "RHS inspect failed: " + string(status.message));
        return;
    end
    source = services.project.sourceRecord( ...
        "rhs", "recording", filepath, true);
    state.project.inputs.sources = replaceRole( ...
        state.project.inputs.sources, "recording", source);
    state.session.cache.rhsPath = filepath;
    state.session.cache.index = index;
    state.session.cache.info = index.info;
    selection = rhs_preview.userInterface.channelSelection( ...
        index.info, state.project.parameters.family, "");
    state.project.parameters.family = selection.family;
    state.project.annotations.previewChannelRows = ...
        rhs_preview.analysisRun.channelRows(index.info, selection.family, ...
        state.project.parameters.maxPreviewChannels, ...
        state.project.annotations.protocol);
    state.session.cache.previewChannelRows = ...
        state.project.annotations.previewChannelRows;
    state.session.view.autoWindow = true;
    state.session.view.windowStartSec = 0;
    state = applyAdaptiveWindow(state);
    state = readPreview(state, "Auto preview window", services, true, false);
    state.session.workflow.statusMessage = string(status.message);
    if strlength(state.session.workflow.statusMessage) == 0
        state.session.workflow.statusMessage = "RHS header indexed.";
    end
    state.session.workflow.lastAction = "Indexed RHS file";
    state = services.workflow.log(state, sprintf( ...
        'Indexed %s: %.3f s, %d amplifier channel(s).', ...
        rhs_preview.userInterface.displayFile(filepath), index.durationSec, ...
        numel(index.info.channelFamilies.amplifier)));
end

function state = onProtocolChosen(state, event, services)
    paths = services.events.paths(event, "addedFiles");
    if isempty(paths)
        paths = services.events.paths(event, "files");
    end
    if isempty(paths)
        return;
    end
    filepath = paths(1);
    protocol = rhs_preview.sourceFiles.loadProtocol(filepath);
    source = services.project.sourceRecord( ...
        "protocol", "protocol", filepath, false);
    state.project.inputs.sources = replaceRole( ...
        state.project.inputs.sources, "protocol", source);
    state.project.annotations.protocol = protocol;
    state.session.cache.protocolPath = filepath;
    state.session.cache.protocol = protocol;
    state = rebuildPreviewRows(state);
    state.session.workflow.lastAction = "Selected protocol";
    state = services.workflow.log(state, ...
        "Selected protocol: " + rhs_preview.userInterface.displayFile(filepath));
end

function state = onFolderChosen(state, event, services)
    paths = services.events.paths(event, "addedFiles");
    if isempty(paths)
        paths = services.events.paths(event, "files");
    end
    if isempty(paths)
        return;
    end
    try
        rows = rhs_preview.analysisRun.discoverFilterRows( ...
            paths, state.session.cache.filterRows);
    catch ME
        services.diagnostics.report("RHS task scan failed", ME);
        state.session.workflow.statusMessage = string(ME.message);
        return;
    end
    state.session.cache.filterRows = rows;
    state.project.inputs.sources = replaceRole(state.project.inputs.sources, ...
        "filterRecording", sourceRecords(rows, services));
    state = storeFilterAnnotations(state);
    state.session.workflow.statusMessage = sprintf( ...
        'Discovered %d RHS file(s).', height(rows));
    state.session.workflow.lastAction = "Discovered RHS files";
    state = services.workflow.log(state, state.session.workflow.statusMessage);
end

function state = onFolderRemoved(state, event, services)
    rows = state.session.cache.filterRows;
    indices = services.events.indices(event, "removedFiles", height(rows));
    if isempty(indices)
        return;
    end
    rows(indices, :) = [];
    if height(rows) > 0
        rows.recordingId = "R" + compose("%03d", (1:height(rows)).');
    end
    state.session.cache.filterRows = rows;
    sources = roleSources(state, "filterRecording");
    sources(indices) = [];
    state.project.inputs.sources = replaceRole( ...
        state.project.inputs.sources, "filterRecording", sources);
    state = storeFilterAnnotations(state);
    state.session.workflow.statusMessage = sprintf( ...
        'Removed %d RHS filter task(s).', numel(indices));
    state.session.workflow.lastAction = "Removed RHS filter files";
    state = services.workflow.log(state, state.session.workflow.statusMessage);
end

function state = onFolderCleared(state, ~, services)
    state.project.inputs.sources = replaceRole(state.project.inputs.sources, ...
        "filterRecording", labkit.ui.runtime.emptySourceRecords());
    state.project.annotations.filterLabels = strings(0, 1);
    state.project.annotations.filterComments = strings(0, 1);
    state.session.cache.filterRows = table();
    state.session.workflow.statusMessage = "No RHS folder selected.";
    state.session.workflow.lastAction = "Cleared RHS folder";
    state = services.workflow.log(state, "Cleared RHS filter files.");
end

function state = onSettingChanged(state, event, services)
    target = string(event.target);
    if any(target == ["channelFamily", "maxPreviewChannels"])
        state = rebuildPreviewRows(state);
        if state.session.view.autoWindow
            state = applyAdaptiveWindow(state);
        end
    end
    if hasReadableChannel(state)
        state = readPreview(state, settingLabel(target), services, false, false);
    end
    state.session.workflow.lastAction = "Updated preview settings";
end

function state = onPreviewChannelEdited(state, event, services)
    rows = rhs_preview.analysisRun.applyPreviewChannelsTableData( ...
        state.session.cache.previewChannelRows, event.value);
    state.session.cache.previewChannelRows = rows;
    state.project.annotations.previewChannelRows = rows;
    if state.session.view.autoWindow
        state = applyAdaptiveWindow(state);
    end
    if hasReadableChannel(state)
        state = readPreview(state, ...
            "Updated preview channel window", services, false, false);
    end
    state.session.workflow.lastAction = "Updated preview channels";
end

function state = onFileFilterEdited(state, event, ~)
    state.session.cache.filterRows = ...
        rhs_preview.analysisRun.applyFileFilterTableData( ...
        state.session.cache.filterRows, event.value);
    state = storeFilterAnnotations(state);
    state.session.workflow.statusMessage = "File filter updated.";
    state.session.workflow.lastAction = "Updated file filter";
end

function state = onRefreshPreviewWindow(state, ~, services)
    state = readPreview(state, "Refresh preview window", services, true, false);
end

function state = onRefreshFolderFiles(state, ~, services)
    filterSources = roleSources(state, "filterRecording");
    if isempty(filterSources)
        state.session.workflow.statusMessage = "Select RHS filter files first.";
        return;
    end
    paths = sourcePaths(filterSources);
    try
        state.session.cache.filterRows = ...
            rhs_preview.analysisRun.discoverFilterRows( ...
            paths, state.session.cache.filterRows);
    catch ME
        services.diagnostics.report("Folder scan failed", ME);
        state.session.workflow.statusMessage = string(ME.message);
        return;
    end
    state.project.inputs.sources = replaceRole(state.project.inputs.sources, ...
        "filterRecording", sourceRecords( ...
        state.session.cache.filterRows, services));
    state = storeFilterAnnotations(state);
    state.session.workflow.statusMessage = sprintf( ...
        'Discovered %d RHS file(s).', height(state.session.cache.filterRows));
    state = services.workflow.log(state, state.session.workflow.statusMessage);
end

function state = onPreviewRoiEdited(state, event, ~)
    context = previewContext(state);
    state.session.view.roiSec = ...
        rhs_preview.analysisRun.clampRoi(event.value, context.preview.timeSec);
    state.session.workflow.statusMessage = sprintf('ROI %.6g to %.6g s.', ...
        state.session.view.roiSec(1), state.session.view.roiSec(2));
    state.session.workflow.lastAction = "Updated preview ROI";
end

function state = onPreviewWindowScrolled(state, event, services)
    if ~hasReadableChannel(state) || ~isstruct(event.value)
        return;
    end
    context = previewContext(state);
    bounds = rhs_preview.analysisRun.previewWindowBounds(context);
    if ~bounds.hasIndexedDuration
        return;
    end
    count = finiteScalar(event.value.count, 0);
    anchor = finiteScalar(event.value.anchor, ...
        context.windowStartSec + context.windowDurationSec / 2);
    oldDuration = max(context.windowDurationSec, bounds.minDurationSec);
    fraction = min(1, max(0, (anchor - context.windowStartSec) / oldDuration));
    factor = 1.25 .^ count;
    context.windowDurationSec = min( ...
        rhs_preview.analysisRun.maxInteractivePreviewDurationSec(context), ...
        max(bounds.minDurationSec, oldDuration * factor));
    context.windowStartSec = anchor - fraction * context.windowDurationSec;
    context.windowStartSec = ...
        rhs_preview.analysisRun.clampWindowStartSec(context.windowStartSec, context);
    state = applyPreviewContext(state, context);
    state.session.view.autoWindow = false;
    state = readPreview(state, "Zoom preview window", services, false, false);
    state.session.workflow.statusMessage = "Preview zoom updated.";
end

function state = onZoomToRoi(state, ~, services)
    context = previewContext(state);
    if ~rhs_preview.analysisRun.hasValidRoi(context)
        state.session.workflow.statusMessage = ...
            "Drag a preview ROI before using Zoom to ROI.";
        return;
    end
    roi = sort(double(state.session.view.roiSec(:))).';
    bounds = rhs_preview.analysisRun.previewWindowBounds(context);
    state.session.view.windowDurationSec = max(diff(roi), bounds.minDurationSec);
    if bounds.hasIndexedDuration
        state.session.view.windowDurationSec = min( ...
            state.session.view.windowDurationSec, bounds.durationSec);
    end
    state.session.view.windowStartSec = roi(1);
    state.session.view.autoWindow = false;
    state = readPreview(state, "Zoom to ROI window", services, true, true);
end

function state = onSaveProtocol(state, ~, services)
    if height(state.session.cache.previewChannelRows) == 0
        state.session.workflow.statusMessage = ...
            "Select an RHS file before saving a protocol.";
        return;
    end
    [out, cancelled] = services.dialogs.outputFile( ...
        {'*.json', 'Protocol JSON'}, 'Save RHS protocol', ...
        'rhs_protocol_draft.json');
    if cancelled
        return;
    end
    context = previewContext(state);
    rhs_preview.resultFiles.writeProtocolJson(context, out);
    state.project.annotations.protocol = ...
        rhs_preview.resultFiles.protocolJsonStruct(context);
    state.session.cache.protocol = state.project.annotations.protocol;
    [manifest, ~] = writeJsonManifest(state, services, out, ...
        "rhsProtocol", "rhs_protocol_draft.labkit.json");
    state.project.results.lastProtocolExport = struct( ...
        "jsonPath", string(out), "manifestPath", string(manifest));
    state = services.workflow.log(state, "Saved protocol JSON: " + string(out));
end

function state = onSaveFilterRecord(state, ~, services)
    if height(state.session.cache.filterRows) == 0
        state.session.workflow.statusMessage = ...
            "Select RHS filter files before saving a filter record.";
        return;
    end
    [out, cancelled] = services.dialogs.outputFile( ...
        {'*.json', 'Filter JSON'}, 'Save RHS filter record', ...
        'rhs_filter_record.json');
    if cancelled
        return;
    end
    context = previewContext(state);
    rhs_preview.resultFiles.writeFilterRecordJson(context, out);
    [manifest, ~] = writeJsonManifest(state, services, out, ...
        "rhsFilterRecord", "rhs_filter_record.labkit.json");
    state.project.results.lastFilterExport = struct( ...
        "jsonPath", string(out), "manifestPath", string(manifest));
    state = services.workflow.log(state, ...
        "Saved filter record JSON: " + string(out));
end

function state = onResetWorkflow(~, ~, services)
    project = rhs_preview.appLifecycle.createProject();
    state = struct("project", project, ...
        "session", rhs_preview.appLifecycle.createSession(project));
    state = services.workflow.log(state, "Reset RHS Preview state.");
end

function state = rebuildPreviewRows(state)
    context = previewContext(state);
    selection = rhs_preview.userInterface.channelSelection( ...
        context.info, state.project.parameters.family, "");
    state.project.parameters.family = selection.family;
    rows = rhs_preview.analysisRun.channelRows(context.info, selection.family, ...
        state.project.parameters.maxPreviewChannels, ...
        state.project.annotations.protocol);
    state.project.annotations.previewChannelRows = rows;
    state.session.cache.previewChannelRows = rows;
end

function state = applyAdaptiveWindow(state)
    duration = rhs_preview.analysisRun.suggestedPreviewDurationSec( ...
        state.session.cache.index, state.session.cache.previewChannelRows, ...
        state.project.parameters.maxPreviewChannels);
    if isfinite(duration) && duration > 0
        state.session.view.windowDurationSec = duration;
        context = previewContext(state);
        state.session.view.windowStartSec = ...
            rhs_preview.analysisRun.clampWindowStartSec( ...
            context.windowStartSec, context);
    end
end

function state = readPreview(state, label, services, logRead, preserveRoi)
    context = previewContext(state);
    selected = selectedChannels(context.previewChannelRows, ...
        context.maxPreviewChannels);
    [context, ok, message] = rhs_preview.analysisRun.readPreviewWindow( ...
        context, selected, label, preserveRoi);
    state = applyPreviewContext(state, context);
    if strlength(message) > 0 && (logRead || ~ok)
        state = services.workflow.log(state, message);
    end
end

function context = previewContext(state)
    context = struct( ...
        "rhsFile", state.session.cache.rhsPath, ...
        "rhsFolder", commonParent(sourcePaths( ...
        roleSources(state, "filterRecording"))), ...
        "protocolFile", state.session.cache.protocolPath, ...
        "protocol", state.project.annotations.protocol, ...
        "family", state.project.parameters.family, ...
        "previewChannelRows", state.session.cache.previewChannelRows, ...
        "filterRows", state.session.cache.filterRows, ...
        "windowStartSec", state.session.view.windowStartSec, ...
        "windowDurationSec", state.session.view.windowDurationSec, ...
        "roiSec", state.session.view.roiSec, ...
        "autoWindow", state.session.view.autoWindow, ...
        "maxPreviewChannels", state.project.parameters.maxPreviewChannels, ...
        "info", state.session.cache.info, "index", state.session.cache.index, ...
        "preview", state.session.cache.preview, ...
        "statusMessage", state.session.workflow.statusMessage, ...
        "lastAction", state.session.workflow.lastAction);
end

function state = applyPreviewContext(state, context)
    state.session.view.windowStartSec = context.windowStartSec;
    state.session.view.windowDurationSec = context.windowDurationSec;
    state.session.view.roiSec = context.roiSec;
    state.session.cache.preview = context.preview;
    state.session.workflow.statusMessage = context.statusMessage;
    state.session.workflow.lastAction = context.lastAction;
end

function state = storeFilterAnnotations(state)
    rows = state.session.cache.filterRows;
    if height(rows) == 0
        state.project.annotations.filterLabels = strings(0, 1);
        state.project.annotations.filterComments = strings(0, 1);
    else
        state.project.annotations.filterLabels = string(rows.label);
        state.project.annotations.filterComments = string(rows.comment);
    end
end

function sources = sourceRecords(rows, services)
    sources = labkit.ui.runtime.emptySourceRecords();
    for k = 1:height(rows)
        source = services.project.sourceRecord("filter" + string(k), ...
            "filterRecording", string(rows.filePath(k)), true);
        if isempty(sources)
            sources = source;
        else
            sources(end + 1) = source;
        end
    end
end

function paths = sourcePaths(sources)
    paths = strings(0, 1);
    for k = 1:numel(sources)
        paths(end + 1, 1) = string(sources(k).reference.originalPath);
    end
end

function selected = selectedChannels(rows, limit)
    selected = strings(0, 1);
    if istable(rows) && height(rows) > 0
        selected = string(rows.channel(logical(rows.preview)));
        selected = selected(1:min(numel(selected), limit));
    end
end

function tf = hasReadableChannel(state)
    tf = rhs_preview.analysisRun.hasReadableChannel(previewContext(state));
end

function label = settingLabel(target)
    if target == "windowStartPanner"
        label = "Panned preview window";
    else
        label = "Updated preview window";
    end
end

function [manifestPath, report] = writeJsonManifest( ...
        state, services, outputPath, id, manifestName)
    [folder, name, extension] = fileparts(outputPath);
    output = services.results.output(id, "primary", ...
        string(name) + string(extension), "application/json");
    spec = struct("Outputs", output, ...
        "Inputs", state.project.inputs.sources, ...
        "Parameters", state.project.parameters, ...
        "Summary", struct(), "ManifestName", manifestName);
    [manifestPath, report] = services.results.writeManifest(folder, spec);
end

function sources = roleSources(state, role)
    sources = rhs_preview.appLifecycle.sourceRecordsForRole( ...
        state.project.inputs.sources, role);
end

function sources = replaceRole(sources, role, replacements)
    sources = rhs_preview.appLifecycle.replaceSourceRecordsForRole( ...
        sources, role, replacements);
end

function value = finiteScalar(value, fallback)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
end

function folder = commonParent(paths)
    folder = "";
    if ~isempty(paths)
        folder = string(fileparts(char(paths(1))));
    end
end
