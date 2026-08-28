function applicationState = readFile(filepath, context)
%READFILE Restore one current ROI Analyzer project snapshot.
filepath = string(filepath);
details = whos("-file", char(filepath));
if numel(details) ~= 1 || string(details.name) ~= "roiAnalyzerArchive"
    error("roi_analyzer:UnknownArchiveFormat", ...
        "MAT file must contain one current ROI Analyzer archive.");
end
loaded = load(char(filepath), "roiAnalyzerArchive");
archive = loaded.roiAnalyzerArchive;
if ~isstruct(archive) || ~isscalar(archive) || ...
        ~all(isfield(archive, {'format', 'formatVersion', 'project', ...
            'sourceIndex', 'roiIndices'})) || ...
        string(archive.format) ~= "roi_analyzer.archive" || ...
        archive.formatVersion ~= 1
    error("roi_analyzer:UnknownArchiveFormat", ...
        "MAT file is not a current ROI Analyzer archive.");
end
project = archive.project;
roi_analyzer.archive.validateProject(project);
project.inputs.sources = resolveSources(project.inputs.sources, filepath);
session = roi_analyzer.createSession(project, context);
session.selection.sourceIndex = min(max(0, double(archive.sourceIndex)), ...
    numel(project.inputs.sources));
if session.selection.sourceIndex > 0
    session.selection.sourceImages = labkit.app.event.ListSelection( ...
        Ids=string(project.inputs.sources(session.selection.sourceIndex).id), ...
        Indices=session.selection.sourceIndex);
    session.cache = roi_analyzer.sourceImages.loadSource( ...
        project.inputs.sources(session.selection.sourceIndex));
    annotation = roi_analyzer.roiLibrary.annotationForSource( ...
        project.annotations.items, ...
        project.inputs.sources(session.selection.sourceIndex).id);
    savedSelection = struct("roiIndices", archive.roiIndices, "roiIndex", 0);
    session.selection.roiIndices = roi_analyzer.roiLibrary.selectedIndices( ...
        savedSelection, numel(annotation.rois));
    session.selection.roiIndex = 0;
    if ~isempty(session.selection.roiIndices)
        session.selection.roiIndex = session.selection.roiIndices(1);
    end
end
applicationState = struct("project", project, "session", session);
end

function sources = resolveSources(sources, filepath)
archiveFolder = string(fileparts(filepath));
for k = 1:numel(sources)
    recorded = string(sources(k).path);
    [~, name, extension] = fileparts(recorded);
    fileName = string(name) + string(extension);
    candidates = [recorded, string(fullfile(archiveFolder, recorded)), ...
        string(fullfile(archiveFolder, fileName))];
    match = find(arrayfun(@isfile, candidates), 1);
    if isempty(match)
        error("roi_analyzer:MissingArchiveSource", ...
            "A required project image is missing: %s", fileName);
    end
    sources(k) = labkit.app.source.record( ...
        sources(k).id, sources(k).role, candidates(match));
end
end
