classdef Mark10PlaybackSpec < matlab.unittest.TestCase
    %MARK10PLAYBACKSPEC Specify supported normalized recording inputs.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function reopensLogCsvAndMatAsNormalizedReplay(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            logPath = fullfile(folder, "synthetic.log");
            csvPath = fullfile(folder, "synthetic.csv");
            matPath = fullfile(folder, "synthetic.mat");
            mark10_monitor.recording.writeMesurGaugeLog(logPath, ...
                [1; 1.2], [1; 2], [3; 4], "N", "mm", datetime(2026,1,2));
            writetable(table([1; 1.2], [1; 2], [3; 4], ...
                'VariableNames', {'Time_s', 'Force_N', 'Travel_mm'}), csvPath);
            recording = struct("Time_s", [1; 1.2], "Force_N", [1; 2], ...
                "Travel_mm", [3; 4], "Valid", [true; false]);
            save(matPath, "recording");

            logData = mark10_monitor.playback.readRecording(logPath);
            csvData = mark10_monitor.playback.readRecording(csvPath);
            matData = mark10_monitor.playback.readRecording(matPath);

            testCase.verifyEqual(logData.Time_s, [0; 0.2], "AbsTol", 1e-12);
            testCase.verifyEqual(csvData.Force_N, [1; 2]);
            testCase.verifyEqual(matData.Force_N, 1);
            testCase.verifyEqual([logData.Format, csvData.Format, matData.Format], ...
                ["MESUR gauge LOG", "Standard CSV", "Complete MAT"]);
        end
    end
end
