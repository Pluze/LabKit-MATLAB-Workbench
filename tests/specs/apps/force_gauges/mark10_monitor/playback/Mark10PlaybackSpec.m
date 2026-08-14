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

        function advancesAtFixedVisualSpeedIndependentOfRecordedTime(testCase)
            sampleCount = 4096;
            playback = containers.Map("KeyType", "char", "ValueType", "any");
            playback("time_s") = linspace(0, 1000, sampleCount).';
            playback("force_N") = zeros(sampleCount, 1);
            playback("travel_mm") = zeros(sampleCount, 1);
            playback("index") = 0;
            observed = containers.Map("KeyType", "char", "ValueType", "any");
            backend = struct("postEvent", @(id, update) ...
                capturePost(observed, id, update));
            context = labkittest.createCallbackContext(backend);

            mark10_monitor.playback.tick(playback, context);

            testCase.verifyEqual(playback("index"), 14);
            testCase.verifyEqual(observed("id"), "mark10.playback.refresh");
            testCase.verifyEqual( ...
                mark10_monitor.playback.stepSize(sampleCount), 14);
        end

        function vectorizedLogUnitsMatchTheDriverDecoder(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            forceUnits = ["N", "mN", "kN", "lbF", "ozF", "kgF", "gF"];
            travelUnits = ["mm", "in"];
            for forceUnit = forceUnits
                for travelUnit = travelUnits
                    filepath = fullfile(folder, ...
                        forceUnit + "-" + travelUnit + ".log");
                    mark10_monitor.recording.writeMesurGaugeLog(filepath, ...
                        [0; 1], [1; 2], [3; 4], forceUnit, travelUnit, ...
                        datetime(2026, 1, 2));
                    actual = mark10_monitor.playback.readRecording(filepath);
                    expected = labkit.mark10.decodeSample(compose( ...
                        "1.00 %s\n3.000 %s", forceUnit, travelUnit));

                    testCase.verifyEqual(actual.Force_N(1), ...
                        expected.Force_N, "AbsTol", eps(max(1, ...
                        abs(expected.Force_N))));
                    testCase.verifyEqual(actual.Travel_mm(1), ...
                        expected.Travel_mm, "AbsTol", eps(max(1, ...
                        abs(expected.Travel_mm))));
                end
            end
        end

        function resetPlayAndPauseResumeOwnTheVisibleCursor(testCase)
            resources = containers.Map("KeyType", "char", "ValueType", "any");
            backend = struct( ...
                "setResource", @(scope, id, value, cleanup) ...
                    storeResource(resources, scope, id, value, cleanup), ...
                "getResource", @(scope, id) ...
                    getResource(resources, scope, id), ...
                "removeResource", @(scope, id) ...
                    removeResource(resources, scope, id), ...
                "postEvent", @(~, ~) []);
            context = labkittest.createCallbackContext(backend);
            session = mark10_monitor.createSession(struct(), context);
            count = 4096;
            playback = containers.Map("KeyType", "char", "ValueType", "any");
            playback("time_s") = linspace(0, 120, count).';
            playback("force_N") = linspace(-2, 2, count).';
            playback("travel_mm") = linspace(0, 5, count).';
            playback("index") = count;
            storeResource(resources, "application", "mark10Playback", ...
                playback, []);
            session.playback.loaded = true;
            session.playback.cursor = count;
            session.playback.count = count;
            state = struct("project", struct(), "session", session);
            cleanup = onCleanup(@() removeResource( ...
                resources, "application", "mark10PlaybackTimer"));

            state = mark10_monitor.playback.reset(state, context);
            testCase.verifyNumElements( ...
                state.session.acquisition.plotTime_s, count);

            state = mark10_monitor.playback.play(state, context);
            timerEntry = resources("application|mark10PlaybackTimer");
            testCase.verifyEqual(playback("index"), 0);
            testCase.verifyEmpty(state.session.acquisition.plotTime_s);
            testCase.verifyEqual(timerEntry.Value.Period, 0.034);

            state = mark10_monitor.playback.pause(state, context);
            testCase.verifyFalse(state.session.playback.playing);
            state = mark10_monitor.playback.pause(state, context);
            testCase.verifyTrue(state.session.playback.playing);
            clear cleanup
        end
    end
end

function capturePost(observed, id, update)
observed("id") = id;
observed("update") = update;
end

function storeResource(resources, scope, id, value, cleanup)
key = char(string(scope) + "|" + string(id));
if isKey(resources, key)
    removeResource(resources, scope, id);
end
resources(key) = struct("Value", value, "Cleanup", cleanup);
end

function value = getResource(resources, scope, id)
key = char(string(scope) + "|" + string(id));
if ~isKey(resources, key), value = []; else, value = resources(key).Value; end
end

function removeResource(resources, scope, id)
key = char(string(scope) + "|" + string(id));
if ~isKey(resources, key), return; end
entry = resources(key);
remove(resources, key);
if ~isempty(entry.Cleanup), entry.Cleanup(entry.Value); end
end
