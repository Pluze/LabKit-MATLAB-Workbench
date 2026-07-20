classdef NeurophysiologyDebugSamplePackTest < matlab.unittest.TestCase
    %NEUROPHYSIOLOGYDEBUGSAMPLEPACKTEST Verify neurophysiology debug packs.

    methods (Test, TestTags = {'Unit'})
        function rhs_and_analysis_debug_packs_read_through_app_facades(testCase)
            setupLabKitTestPath();
            root = string(tempname);
            cleanup = onCleanup(@() cleanupFolder(root));
            mkdir(char(root));
            debug = debugSampleContext(root);

            rhsPack = rhs_preview.debug.writeSamplePack(debug);
            testCase.verifyClass(rhsPack, ...
                "labkit.app.diagnostic.SamplePack");
            rhsPath = sourcePath(rhsPack.InitialProject, "recording");
            [index, status] = labkit.rhs.indexFile(rhsPath);
            testCase.verifyTrue(status.ok, status.message);
            testCase.verifyGreaterThan(index.durationSec, 0);
            [window, windowStatus] = labkit.rhs.readWindow(rhsPath, ...
                struct("family", "amplifier", "timeRangeSec", [0 0.02]));
            testCase.verifyTrue(windowStatus.ok);
            testCase.verifyFalse(isempty(window.values));
            malformedRhs = artifactPath(debug, rhsPack, "malformedHeader");
            [~, malformedStatus] = labkit.rhs.indexFile(malformedRhs);
            testCase.verifyFalse(malformedStatus.ok);

            analysisPack = nerve_response_analysis.debug.writeSamplePack(debug);
            filterPath = sourcePath(analysisPack.InitialProject, "filterRecord");
            protocolPath = sourcePath(analysisPack.InitialProject, "protocol");
            session = jsondecode(fileread(char(filterPath)));
            protocol = jsondecode(fileread(char(protocolPath)));
            analysis = nerve_response_analysis.analysisRun.analyzeSession(session, protocol, ...
                struct("maxRecordings", 1, "maxDurationSec", 0.08));
            testCase.verifyEqual(analysis.recordingCount, 2);
            testCase.verifyGreaterThanOrEqual(analysis.analyzedCount, 1);

            reviewPack = response_review_stats.debug.writeSamplePack(debug);
            segmentPath = sourcePath(reviewPack.InitialProject, "reviewInput");
            T = readtable(char(segmentPath));
            segments = response_review_stats.sourceFiles.parseSegmentTable(T);
            aligned = response_review_stats.analysisRun.alignSegments(segments, struct());
            metrics = response_review_stats.analysisRun.measureAlignedSegments(aligned, struct());
            testCase.verifyGreaterThan(height(metrics), 0);
            analysisPath = artifactPath(debug, reviewPack, "analysisMetrics");
            payload = jsondecode(fileread(char(analysisPath)));
            testCase.verifyTrue(isfield(payload, "metrics"));
        end
    end
end

function filepath = sourcePath(project, role)
source = project.inputs.sources(string({project.inputs.sources.role}) == role);
filepath = source.reference.originalPath;
end

function filepath = artifactPath(context, pack, id)
artifact = pack.Artifacts{find(cellfun( ...
    @(value) value.Id == id, pack.Artifacts), 1)};
parts = cellstr(split(artifact.RelativePath, "/"));
filepath = string(fullfile(context.ArtifactFolder, parts{:}));
end

function cleanupFolder(folder)
    if strlength(string(folder)) > 0 && exist(char(folder), "dir") == 7
        rmdir(char(folder), "s");
    end
end
