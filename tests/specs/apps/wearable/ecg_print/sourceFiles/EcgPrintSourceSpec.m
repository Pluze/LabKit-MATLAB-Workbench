classdef EcgPrintSourceSpec < matlab.unittest.TestCase
    %ECGPRINTSOURCESPEC Specify recording import normalization and preview.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function normalizesImportControlsAndMetadataStatus(testCase)
            numeric = ecg_print.sourceFiles.importOptions(2000, 3, 'No', '2', ...
                'milliseconds', '1, 3, 5');
            named = ecg_print.sourceFiles.importOptions(1000, 0, 'Auto', ...
                'time_s', 'Auto', 'LeadI; LeadII');
            recording = struct("metadata", struct("timeColumn", "time_s", ...
                "timeUnit", "seconds", "timeSource", "column", ...
                "timeRepair", struct("repairedBackwardCount", 3, ...
                    "largeGapCount", 1)));

            testCase.verifyEqual(numeric.fallbackFs, 2000);
            testCase.verifyEqual(numeric.headerLine, 3);
            testCase.verifyFalse(numeric.hasHeader);
            testCase.verifyEqual(numeric.timeColumn, 2);
            testCase.verifyEqual(numeric.signalColumns, [1 3 5]);
            testCase.verifyFalse(isfield(named, 'headerLine'));
            testCase.verifyEqual(named.signalColumns(:), {'LeadI'; 'LeadII'});
            testCase.verifyEqual(ecg_print.sourceFiles.importStatusText(recording, 2), ...
                ['2 channel(s) | time: time_s | unit: seconds | source: column | ' ...
                'repaired backward: 3 | large gaps: 1']);
        end

        function previewsNumberedHeaderLinesWithoutParsingTheWholeRecording(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            path = fullfile(folder, 'recording.csv');
            writeText(path, sprintf('time_s,LeadI\n0,1\n1,2\n'));

            lines = ecg_print.sourceFiles.previewFileHeader(path, 2);

            testCase.verifyEqual(lines, {'01: time_s,LeadI'; '02: 0,1'});
        end
    end
end

function writeText(path, contents)
file = fopen(path, 'w');
cleanup = onCleanup(@() fclose(file));
fprintf(file, '%s', contents);
clear cleanup
end
