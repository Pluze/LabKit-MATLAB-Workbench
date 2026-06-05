classdef PlatformSkeletonTest < matlab.unittest.TestCase
    %PLATFORMSKELETONTEST Seed official tests for the new LabKit platform.
    %
    % This class tests runner/support artifact contracts used by the official suite.

    methods (Test, TestTags = {'Unit', 'Smoke', 'Style'})
        function artifactPathsUseRoadmapLayout(testCase)
            setupLabKitTestPath();
            paths = labkitArtifactPaths( ...
                "Root", fullfile(tempdir, "labkit-artifacts-seed"), ...
                "Create", false);

            testCase.verifyTrue(endsWith(string(paths.junitXml), ...
                fullfile("test-results", "junit.xml")));
            testCase.verifyTrue(endsWith(string(paths.testHtml), ...
                fullfile("test-results", "html")));
            testCase.verifyTrue(endsWith(string(paths.coberturaXml), ...
                fullfile("coverage", "cobertura.xml")));
            testCase.verifyTrue(endsWith(string(paths.coverageHtml), ...
                fullfile("coverage", "html")));
            testCase.verifyTrue(endsWith(string(paths.guiTrace), ...
                fullfile("gui", "trace")));
            testCase.verifyTrue(endsWith(string(paths.guiSnapshots), ...
                fullfile("gui", "snapshots")));
        end

        function traceArtifactsAreStructuredAndSanitized(testCase)
            setupLabKitTestPath();
            paths = labkitArtifactPaths( ...
                "Root", fullfile(tempdir, "labkit-trace-seed"), ...
                "Create", true);
            jsonlPath = fullfile(paths.guiTrace, "trace.jsonl");
            textPath = fullfile(paths.guiTrace, "trace.txt");

            recorder = createLabKitTraceRecorder( ...
                "AppName", "seed_app", ...
                "TestName", "PlatformSkeletonTest", ...
                "RunId", "seed-run");
            recorder.record("runtime", "session.acquire", "test", ...
                struct("sourcePath", "DEVICE", ...
                "value", 42));
            recorder.writeJsonl(jsonlPath);
            recorder.writeText(textPath);

            testCase.verifyEqual(numel(recorder.events()), 1);
            testCase.verifyTrue(isfile(jsonlPath));
            testCase.verifyTrue(isfile(textPath));

            jsonl = string(fileread(jsonlPath));
            text = string(fileread(textPath));
            testCase.verifyTrue(contains(jsonl, '"schemaVersion":1'));
            testCase.verifyTrue(contains(jsonl, '"reason":"test"'));
            testCase.verifyTrue(contains(jsonl, '"sourcePath":"[redacted]"'));
            testCase.verifyFalse(contains(jsonl, "DEVICE"));
            testCase.verifyTrue(contains(text, "component=runtime"));
            testCase.verifyTrue(contains(text, "event=session.acquire"));
            testCase.verifyFalse(contains(text, "DEVICE"));
        end
    end
end
