% Expected caller: Runtime V2. Input is a validated RHS Preview project with
% resolved sources. Output owns transient indexing, decoded preview windows,
% filter rows, status, selection, time view, and workflow log.
function session = createSession(project)
    session = emptySession();
    session.cache.protocol = project.annotations.protocol;
    session.cache.previewChannelRows = project.annotations.previewChannelRows;
    if ~isempty(project.inputs.protocolSource)
        session.cache.protocolPath = sourcePath(project.inputs.protocolSource(1));
        session.cache.protocol = rhs_preview.sourceFiles.loadProtocol( ...
            session.cache.protocolPath);
    end
    if ~isempty(project.inputs.rhsSource)
        session.cache.rhsPath = sourcePath(project.inputs.rhsSource(1));
        [index, status] = labkit.rhs.indexFile(session.cache.rhsPath);
        if ~status.ok
            error('rhs_preview:SourceLoadFailed', ...
                'Could not index %s: %s', session.cache.rhsPath, status.message);
        end
        session.cache.index = index;
        session.cache.info = index.info;
        if isempty(session.cache.previewChannelRows)
            session.cache.previewChannelRows = rhs_preview.analysisRun.channelRows( ...
                index.info, project.parameters.family, ...
                project.parameters.maxPreviewChannels, session.cache.protocol);
        end
        session.view.windowDurationSec = ...
            rhs_preview.analysisRun.suggestedPreviewDurationSec(index, ...
            session.cache.previewChannelRows, project.parameters.maxPreviewChannels);
        session = readInitialPreview(session, project.parameters);
        session.workflow.statusMessage = string(status.message);
        if strlength(session.workflow.statusMessage) == 0
            session.workflow.statusMessage = "RHS header indexed.";
        end
    end
    if ~isempty(project.inputs.filterSources)
        paths = arrayfun(@sourcePath, project.inputs.filterSources).';
        session.cache.filterRows = rhs_preview.analysisRun.discoverFilterRows(paths);
        session.cache.filterRows = applyFilterAnnotations( ...
            session.cache.filterRows, project.annotations);
    end
end

function session = emptySession()
    session = struct( ...
        "selection", struct(), ...
        "workflow", struct("statusMessage", "No RHS file selected.", ...
            "lastAction", "Ready", "logLines", strings(0, 1)), ...
        "view", struct("windowStartSec", 0, "windowDurationSec", 0.050, ...
            "roiSec", [NaN NaN], "autoWindow", true), ...
        "cache", struct("rhsPath", "", "protocolPath", "", ...
            "protocol", struct(), "previewChannelRows", table(), ...
            "filterRows", table(), "info", [], "index", [], "preview", []));
end

function session = readInitialPreview(session, parameters)
    context = contextFromSession(session, parameters);
    selected = selectedChannels(context.previewChannelRows, ...
        parameters.maxPreviewChannels);
    if isempty(selected)
        return;
    end
    [context, ~] = rhs_preview.analysisRun.readPreviewWindow( ...
        context, selected, "Opened project", false);
    session = applyContext(session, context);
end

function context = contextFromSession(session, parameters)
    context = struct("rhsFile", session.cache.rhsPath, ...
        "family", parameters.family, ...
        "maxPreviewChannels", parameters.maxPreviewChannels, ...
        "previewChannelRows", session.cache.previewChannelRows, ...
        "windowStartSec", session.view.windowStartSec, ...
        "windowDurationSec", session.view.windowDurationSec, ...
        "roiSec", session.view.roiSec, "index", session.cache.index, ...
        "preview", session.cache.preview, ...
        "statusMessage", session.workflow.statusMessage, ...
        "lastAction", session.workflow.lastAction);
end

function session = applyContext(session, context)
    session.view.windowStartSec = context.windowStartSec;
    session.view.windowDurationSec = context.windowDurationSec;
    session.view.roiSec = context.roiSec;
    session.cache.preview = context.preview;
    session.workflow.statusMessage = context.statusMessage;
    session.workflow.lastAction = context.lastAction;
end

function selected = selectedChannels(rows, limit)
    selected = strings(0, 1);
    if istable(rows) && height(rows) > 0
        selected = string(rows.channel(logical(rows.preview)));
        selected = selected(1:min(numel(selected), limit));
    end
end

function rows = applyFilterAnnotations(rows, annotations)
    count = min([height(rows), numel(annotations.filterLabels), ...
        numel(annotations.filterComments)]);
    if count > 0
        rows.label(1:count) = annotations.filterLabels(1:count);
        rows.comment(1:count) = annotations.filterComments(1:count);
    end
end

function path = sourcePath(source)
    path = string(source.reference.originalPath);
end
