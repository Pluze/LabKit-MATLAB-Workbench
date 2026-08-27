classdef Mark10RecordingSpec < matlab.unittest.TestCase
    %MARK10RECORDINGSPEC Specify Mark-10 interchange and replay inputs.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function writesMesurGaugeCompatibleLogBytes(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            filepath = fullfile(folder, "synthetic.log");

            mark10_monitor.recording.writeMesurGaugeLog(filepath, ...
                [0; 0.181], [0.02; 1.5], [0; 0.54], "N", "mm", ...
                datetime(2026, 8, 14, 10, 46, 0));

            fileId = fopen(filepath, "r");
            cleanup = onCleanup(@() fclose(fileId));
            bytes = fread(fileId, Inf, "*uint8").';
            expected = sprintf([ ...
                '8/14/2026  10:46 AM\r\n' ...
                'Units: N\r\n' ...
                'Readings: Continuous\r\n' ...
                'X-Axis: Travel\r\n' ...
                'Travel Unit: mm\r\n' ...
                'Reading\tLoad\tTravel\tTime\r\n' ...
                '1\t0.02\t0.000\t0.000\r\n' ...
                '2\t1.50\t0.540\t0.181\r\n']);

            testCase.verifyEqual(bytes, uint8(expected));
        end

        function exportRecordingWritesTheThreeUserArtifacts(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            csvPath = fullfile(folder, "monitoring.csv");
            buffer = containers.Map("KeyType", "char", "ValueType", "any");
            buffer("valid") = [true; false; true];
            buffer("time_s") = [0; 0.1; 0.2];
            buffer("force_N") = [1; NaN; 3];
            buffer("travel_mm") = [0; NaN; 0.4];
            buffer("forceRaw") = [1; NaN; 3];
            buffer("travelRaw") = [0; NaN; 0.4];
            buffer("forceUnit") = ["N"; ""; "N"];
            buffer("travelUnit") = ["mm"; ""; "mm"];
            buffer("mode") = ["CUR"; ""; "CUR"];
            buffer("monitoringStartedAt") = datetime(2026, 8, 27, 12, 0, 0);
            context = labkittest.createCallbackContext(struct( ...
                "getResource", @(~) buffer, ...
                "chooseOutputFile", @(~, ~) ...
                    labkit.app.dialog.Choice(csvPath), ...
                "alert", @(message, title) unexpectedAlert(message, title)));
            state = struct("session", struct( ...
                "experiment", struct("type", "Tension"), ...
                "settings", struct("unit", "N"), ...
                "connection", struct("connected", true), ...
                "acquisition", struct("rate", 10), ...
                "export", struct("status", "")));

            state = mark10_monitor.recording.export(state, context);

            testCase.verifyTrue(isfile(csvPath));
            testCase.verifyTrue(isfile(fullfile(folder, "monitoring.log")));
            testCase.verifyTrue(isfile(fullfile(folder, "monitoring.mat")));
            exported = readtable(csvPath);
            testCase.verifyEqual(height(exported), 2);
            testCase.verifyEqual(exported.Force_N, [1; 3]);
            testCase.verifyEqual(state.session.export.status, ...
                "Exported: " + string(csvPath));
        end

    end
end

function unexpectedAlert(message, title)
error("mark10_monitor:test:UnexpectedAlert", "%s: %s", title, message);
end
