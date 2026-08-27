classdef Mark10WorkflowSpec < matlab.unittest.TestCase
    %MARK10WORKFLOWSPEC Specify the recording-to-modulus-export journey.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
        function loadsZerosAnalyzesAndExportsARecording(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            recordingPath = fullfile(folder, "recording.csv");
            monitoringPath = fullfile(folder, "monitoring.csv");
            exportPath = fullfile(folder, "modulus.csv");
            travel = [linspace(0, 2, 101), linspace(2, 0, 101)].';
            time = (0:numel(travel)-1).' ./ 50;
            force = 3 .* travel;
            writetable(table(time, force, travel, VariableNames= ...
                ["Time_s", "Force_N", "Travel_mm"]), recordingPath);
            alerts = containers.Map("KeyType", "char", "ValueType", "any");
            backend = struct( ...
                "chooseInputFile", @(~, ~) ...
                    labkit.app.dialog.Choice(recordingPath), ...
                "chooseOutputFile", @(~, defaultPath) ...
                    chooseOutput(defaultPath, monitoringPath, exportPath), ...
                "alert", @(message, title) captureAlert( ...
                    alerts, message, title));
            definition = mark10_monitor.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());

            runtime.invokeAction("refreshPorts");
            ports = runtime.State.session.connection.ports;
            testCase.verifyFalse(runtime.State.session.connection.connected);
            if isempty(ports)
                testCase.verifyEqual( ...
                    runtime.State.session.connection.selectedPort, "");
            else
                testCase.verifyTrue(any(ports == ...
                    runtime.State.session.connection.selectedPort));
            end
            runtime.applyControlValue("serialPort", "");
            runtime.invokeAction("connectDevice");
            testCase.verifyEqual(alerts("title"), "Mark-10 Connection");
            testCase.verifyEqual(alerts("message"), ...
                "Select a serial port first.");
            runtime.invokeAction("disconnectDevice");
            runtime.applyControlValue("sampleRate", "20 Hz");
            runtime.invokeAction("startMonitoring");
            runtime.invokeAction("stopMonitoring");
            testCase.verifyEqual(runtime.State.session.acquisition.rate, "20 Hz");
            testCase.verifyFalse(runtime.State.session.connection.connected);

            runtime.setResource("mark10Connection", ...
                syntheticConnectionBox(), []);
            runtime.postEvent("test.synthetic-connection", ...
                @installSyntheticConnection);
            runtime.invokeAction("readOnce");
            testCase.verifyEqual(runtime.State.session.acquisition.force_N, 1);
            testCase.verifyEqual(runtime.State.session.acquisition.travel_mm, 2);
            runtime.invokeAction("zeroForce");
            runtime.invokeAction("zeroTravel");
            testCase.verifyEqual(runtime.State.session.acquisition.force_N, 0);
            testCase.verifyEqual(runtime.State.session.acquisition.travel_mm, 0);
            runtime.invokeAction("refreshSettings");
            runtime.invokeAction("applySettings");
            testCase.verifyEqual(runtime.State.session.connection.lastFailure, "");

            buffer = runtime.getResource("mark10Buffer");
            populateMonitoringBuffer(buffer);
            runtime.invokeAction("refitLiveAxes");
            runtime.invokeAction("exportRecording");
            testCase.verifyTrue(isfile(monitoringPath));
            testCase.verifyTrue(isfile(fullfile(folder, "monitoring.log")));
            testCase.verifyTrue(isfile(fullfile(folder, "monitoring.mat")));

            runtime.invokeAction("openRecording");
            testCase.verifyFalse(runtime.StartupFailed);
            testCase.verifyTrue(runtime.State.session.playback.loaded);
            testCase.verifyEqual(runtime.State.session.playback.count, numel(time));
            testCase.verifyEqual(runtime.State.session.acquisition.plotForce_N, ...
                force, AbsTol=1e-12);
            liveAxes = findall(runtime.figureHandle(), "Tag", "livePlots.forceTravel");
            testCase.verifyNotEmpty(liveAxes.Children);
            runtime.invokeAction("playRecording");
            testCase.verifyTrue(runtime.State.session.playback.playing);
            runtime.invokeAction("pauseRecording");
            testCase.verifyFalse(runtime.State.session.playback.playing);
            runtime.invokeAction("refitReplayAxes");

            runtime.applyControlValue("analysisForceZero", 0);
            runtime.applyControlValue("analysisTravelZero", 0);
            runtime.invokeAction("applyAnalysisZero");
            runtime.applyControlValue("experimentType", "Tension");
            runtime.applyControlValue("gaugeLength", 10);
            runtime.applyControlValue("specimenWidth", 2);
            runtime.applyControlValue("specimenThickness", 1);
            runtime.applyControlValue("geometryConfirmed", true);
            runtime.applyControlValue("fitMode", "Manual");
            runtime.applyControlValue("manualFitStart", 0.2);
            runtime.applyControlValue("manualFitEnd", 1.5);
            testCase.verifyEmpty(runtime.State.session.analysis.resultRows);
            runtime.invokeAction("runModulusAnalysis");

            rows = runtime.State.session.analysis.resultRows;
            testCase.verifyGreaterThanOrEqual(size(rows, 1), 2);
            testCase.verifyEqual(cell2mat(rows(:, 9)), ...
                15 .* ones(size(rows, 1), 1), AbsTol=1e-10);
            testCase.verifyEqual( ...
                runtime.State.session.analysis.manualStart_mm, 0.2);
            testCase.verifyEqual( ...
                runtime.State.session.analysis.manualEnd_mm, 1.5);
            runtime.invokeAction("exportModulusResults");
            testCase.verifyTrue(isfile(exportPath));
            exported = readtable(exportPath, TextType="string");
            testCase.verifyEqual(height(exported), size(rows, 1));
            testCase.verifyEqual(exported.GaugeLength_mm, ...
                10 .* ones(size(rows, 1), 1));
            runtime.invokeAction("resetAnalysisZero");
            runtime.invokeAction("resetRecording");
            testCase.verifyEqual(runtime.State.session.playback.cursor, numel(time));
            runtime.invokeAction("disconnectDevice");
            testCase.verifyFalse(runtime.State.session.connection.connected);
            clear cleanup
        end
    end
end

function choice = chooseOutput(defaultPath, monitoringPath, modulusPath)
if contains(string(defaultPath), "recording", IgnoreCase=true)
    choice = labkit.app.dialog.Choice(monitoringPath);
else
    choice = labkit.app.dialog.Choice(modulusPath);
end
end

function alerts = captureAlert(alerts, message, title)
alerts("message") = string(message);
alerts("title") = string(title);
end

function state = installSyntheticConnection(state, ~)
state.session.connection.connected = true;
state.session.connection.status = "Synthetic device connected.";
end

function box = syntheticConnectionBox()
transportState = containers.Map("KeyType", "char", "ValueType", "any");
transportState("command") = "";
transportState("forceZero") = false;
transportState("travelZero") = false;
settingsText = "V1.00;N;CUR;FLTC0;FLTP0;AOUT0;" + ...
    "AOFF0;FULL;IPOL0;OPOL0";
transport = struct( ...
    "Write", @(bytes) writeSynthetic(transportState, bytes), ...
    "Flush", @() [], ...
    "ReadUntil", @(~, ~) readSynthetic(transportState, settingsText), ...
    "ReadFor", @(~) uint8([]), "Pause", @(~) [], ...
    "Close", @() [], "IsOpen", @() true);
connection = struct( ...
    "Type", "labkit.mark10.connection", "Port", "SYNTHETIC", ...
    "Timeout", 0.01, "Transport", transport, ...
    "Identity", struct(), "Capabilities", struct(), ...
    "Settings", labkit.mark10.decodeSettings(settingsText), ...
    "RestoreAutoOutput", "AOUT0", ...
    "AcquisitionMode", "Unknown", "SampleCount", uint64(0), ...
    "LastFailure", struct("Status", "", "Message", ""));
box = containers.Map("KeyType", "char", "ValueType", "any");
box("connection") = connection;
end

function state = writeSynthetic(state, bytes)
command = strip(erase(string(native2unicode( ...
    uint8(bytes(:).'), "UTF-8")), char(13)));
if command == "Z"
    state("forceZero") = true;
elseif command == "z"
    state("travelZero") = true;
end
if command ~= "/" && command ~= "\"
    state("command") = command;
end
end

function raw = readSynthetic(state, settingsText)
switch state("command")
    case "n"
        raw = uint8(sprintf('1.00 N\r\n2.00 mm\r\n'));
    case "?C"
        value = 1 - double(state("forceZero"));
        raw = uint8(sprintf('%.2f N\r\n', value));
    case "x"
        value = 2 .* (1 - double(state("travelZero")));
        raw = uint8(sprintf('%.2f mm\r\n', value));
    case "p"
        raw = uint8(sprintf('S\r\n'));
    case "LIST"
        raw = uint8(char(settingsText + newline));
    otherwise
        raw = uint8([]);
end
end

function buffer = populateMonitoringBuffer(buffer)
buffer("valid") = [true; true; true];
buffer("time_s") = [0; 0.1; 0.2];
buffer("force_N") = [1; 2; 3];
buffer("travel_mm") = [0; 0.2; 0.4];
buffer("forceRaw") = [1; 2; 3];
buffer("travelRaw") = [0; 0.2; 0.4];
buffer("forceUnit") = ["N"; "N"; "N"];
buffer("travelUnit") = ["mm"; "mm"; "mm"];
buffer("mode") = ["CUR"; "CUR"; "CUR"];
buffer("monitoringStartedAt") = datetime(2026, 8, 27, 12, 0, 0);
buffer("plotTime_s") = buffer("time_s");
buffer("plotForce_N") = buffer("force_N");
buffer("plotTravel_mm") = buffer("travel_mm");
end
