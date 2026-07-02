classdef NeurophysiologyDebugSamplePackTest < matlab.unittest.TestCase
    %NEUROPHYSIOLOGYDEBUGSAMPLEPACKTEST Verify neurophysiology debug packs.

    methods (Test, TestTags = {'Unit'})
        function rhs_and_analysis_debug_packs_read_through_app_facades(testCase)
            setupLabKitTestPath();
            root = string(tempname);
            cleanup = onCleanup(@() cleanupFolder(root));
            mkdir(char(root));
            debug = labkit.ui.diag.createContext("neuro_debug_sample_test", struct( ...
                "logFile", fullfile(char(root), "trace.log")));

            rhsPack = rhs_preview.debug.writeSamplePack(debug);
            [index, status] = labkit.rhs.indexFile(rhsPack.representativeFiles.primaryRhs);
            testCase.verifyTrue(status.ok, status.message);
            testCase.verifyGreaterThan(index.durationSec, 0);
            [window, windowStatus] = labkit.rhs.readWindow(rhsPack.representativeFiles.primaryRhs, ...
                struct("family", "amplifier", "timeRangeSec", [0 0.02]));
            testCase.verifyTrue(windowStatus.ok);
            testCase.verifyFalse(isempty(window.values));
            [~, malformedStatus] = labkit.rhs.indexFile(rhsPack.boundaryFiles.malformedRhs);
            testCase.verifyFalse(malformedStatus.ok);

            analysisPack = nerve_response_analysis.debug.writeSamplePack(debug);
            session = jsondecode(fileread(char(analysisPack.representativeFiles.filterRecordJson)));
            protocol = jsondecode(fileread(char(analysisPack.representativeFiles.protocolJson)));
            analysis = nerve_response_analysis.ops.analyzeSession(session, protocol, ...
                struct("maxRecordings", 1, "maxDurationSec", 0.08));
            testCase.verifyEqual(analysis.recordingCount, 2);
            testCase.verifyGreaterThanOrEqual(analysis.analyzedCount, 1);

            reviewPack = response_review_stats.debug.writeSamplePack(debug);
            T = readtable(char(reviewPack.representativeFiles.segmentCsv));
            segments = response_review_stats.io.parseSegmentTable(T);
            aligned = response_review_stats.ops.alignSegments(segments, struct());
            metrics = response_review_stats.ops.measureAlignedSegments(aligned, struct());
            testCase.verifyGreaterThan(height(metrics), 0);
            payload = jsondecode(fileread(char(reviewPack.representativeFiles.analysisJson)));
            testCase.verifyTrue(isfield(payload, "metrics"));
        end
    end
end

function cleanupFolder(folder)
    if strlength(string(folder)) > 0 && exist(char(folder), "dir") == 7
        rmdir(char(folder), "s");
    end
end
