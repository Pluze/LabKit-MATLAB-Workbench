% Rebuild transient indexing, decoded preview windows, filter rows, selection,
% time view, status, and workflow log from one validated RHS Preview project.
function session = createSession(project, callbackContext)
    session = emptySession();
    session.cache.protocol = project.annotations.protocol;
    session.cache.previewChannelRows = project.annotations.previewChannelRows;
    protocolPaths = rhs_preview.sourceFiles.pathsForRole( ...
        project.inputs.sources, "protocol", callbackContext);
    rhsPaths = rhs_preview.sourceFiles.pathsForRole( ...
        project.inputs.sources, "recording", callbackContext);
    filterPaths = rhs_preview.sourceFiles.pathsForRole( ...
        project.inputs.sources, "filterRecording", callbackContext);
    filterIds = sourceIdsForRole( ...
        project.inputs.sources, "filterRecording");
    if ~isempty(protocolPaths)
        session.cache.protocolPath = protocolPaths(1);
        session.cache.protocol = rhs_preview.sourceFiles.loadProtocol( ...
            session.cache.protocolPath);
    end
    if ~isempty(rhsPaths)
        session.cache.rhsPath = rhsPaths(1);
        [index, status] = labkit.rhs.indexFile(session.cache.rhsPath);
        if ~status.ok
            error('rhs_preview:SourceLoadFailed', ...
                'Could not index %s: %s', session.cache.rhsPath, status.message);
        end
        session.cache.index = index;
        session.cache.info = index.info;
        session = rhs_preview.analysisRun.rebuildPreviewRows( ...
            session, project.parameters, ...
            project.annotations.previewChannelRows);
        session = rhs_preview.analysisRun.applyAdaptiveWindow( ...
            session, project.parameters);
        session = readInitialPreview(session, project.parameters);
        session.workflow.statusMessage = string(status.message);
        if strlength(session.workflow.statusMessage) == 0
            session.workflow.statusMessage = "RHS header indexed.";
        end
    end
    if ~isempty(filterPaths)
        session.cache.filterRows = ...
            rhs_preview.analysisRun.discoverFilterRows(filterPaths);
        session.cache.filterRows = applyFilterAnnotations( ...
            session.cache.filterRows, project.annotations, filterIds);
    end
end

function session = emptySession()
    session = struct( ...
        "workflow", struct("statusMessage", "No RHS file selected.", ...
            "lastAction", "Ready"), ...
        "view", struct("windowStartSec", 0, "windowDurationSec", 0.050, ...
            "roiSec", [NaN NaN], "autoWindow", true), ...
        "cache", struct("rhsPath", "", "protocolPath", "", ...
            "protocol", struct(), "previewChannelRows", table(), ...
            "filterRows", table(), "info", [], "index", [], "preview", []));
end

function session = readInitialPreview(session, parameters)
    if ~rhs_preview.analysisRun.hasReadableChannel( ...
            rhs_preview.analysisRun.previewContext(session, parameters))
        return;
    end
    session = rhs_preview.analysisRun.readCurrentPreview( ...
        session, parameters, "Opened project", false);
end

function rows = applyFilterAnnotations(rows, annotations, sourceIds)
labels = string(annotations.filterLabels(:));
comments = string(annotations.filterComments(:));
count = min([numel(labels), numel(comments)]);
if count == 0
    return;
end
if isfield(annotations, "filterSourceIds")
    savedIds = string(annotations.filterSourceIds(:));
else
    savedIds = strings(0, 1);
end
if numel(savedIds) == count
    for row = 1:min(height(rows), numel(sourceIds))
        match = find(savedIds == sourceIds(row), 1);
        if isempty(match)
            continue;
        end
        rows.label(row) = labels(match);
        rows.comment(row) = comments(match);
    end
    return;
end
count = min(height(rows), count);
rows.label(1:count) = labels(1:count);
rows.comment(1:count) = comments(1:count);
end

function ids = sourceIdsForRole(sources, role)
ids = strings(0, 1);
if isempty(sources)
    return;
end
mask = string({sources.role}) == string(role);
ids = string({sources(mask).id}).';
end
