function writeFile(applicationState, filepath)
%WRITEFILE Save one current ROI Analyzer project snapshot.
filepath = string(filepath);
if ~isscalar(filepath) || strlength(filepath) == 0
    error("roi_analyzer:InvalidArchivePath", ...
        "ROI Analyzer project path must be nonempty scalar text.");
end
project = applicationState.project;
project.inputs.sources = rebaseSources(project.inputs.sources, filepath);
roi_analyzer.archive.validateProject(project);
roiAnalyzerArchive = struct("format", "roi_analyzer.archive", ...
    "formatVersion", 1, "project", project, ...
    "sourceIndex", applicationState.session.selection.sourceIndex, ...
    "roiIndices", applicationState.session.selection.roiIndices);
save(char(filepath), "roiAnalyzerArchive", "-mat");
end

function sources = rebaseSources(sources, filepath)
archiveFolder = string(fileparts(filepath));
for k = 1:numel(sources)
    recorded = string(sources(k).path);
    [folder, name, extension] = fileparts(recorded);
    if string(folder) == archiveFolder
        sources(k).path = string(name) + string(extension);
    end
end
end
