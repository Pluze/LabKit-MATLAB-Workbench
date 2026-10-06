classdef Mark10WorkflowSpec < matlab.unittest.TestCase
    %MARK10WORKFLOWSPEC Specify the recording-to-modulus-export journey.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
        function loadsZerosAnalyzesAndExportsARecording(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            recordingPath = fullfile(folder, "recording_one.csv");
            monitoringPath = fullfile(folder, "monitoring.csv");
            exportPath = fullfile(folder, "modulus.csv");
            travel = [linspace(0, 2, 101), linspace(2, 0, 101)].';
            time = (0:numel(travel)-1).' ./ 50;
            force = 3 .* travel;
            travel = travel + 10;
            writetable(table(time, force, travel, VariableNames= ...
                ["Time_s", "Force_N", "Travel_mm"]), recordingPath);
            alerts = containers.Map("KeyType", "char", "ValueType", "any");
            input = containers.Map("path", recordingPath);
            backend = struct( ...
                "chooseInputFile", @(~, ~) ...
                    labkit.app.dialog.Choice(input("path")), ...
                "chooseOutputFile", @(~, defaultPath) ...
                    chooseOutput(defaultPath, monitoringPath, exportPath), ...
                "alert", @(message, title) captureAlert( ...
                    alerts, message, title));
            definition = mark10_monitor.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            experiment = findall(runtime.figureHandle(), "Tag", "experimentType");
            testCase.verifyEqual(string(experiment.Items), ["Tension", "Compression", "Cyclic"]);

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
            testCase.verifySubstring(string(runtime.figureHandle().Name), "recording_one.csv");
            testCase.verifySubstring(string(liveAxes.Title.String), "recording_one.csv");
            testCase.verifyEqual(string(liveAxes.Title.Interpreter), "none");
            panel = findall(runtime.figureHandle(), "Tag", "modulusPlot");
            testCase.verifySubstring(string(panel.Title), "recording_one.csv");
            secondPath = fullfile(folder, "recording_two.csv");
            copyfile(recordingPath, secondPath);
            input("path") = secondPath;
            runtime.invokeAction("openRecording");
            testCase.verifySubstring(string(runtime.figureHandle().Name), "recording_two.csv");
            testCase.verifySubstring(string(liveAxes.Title.String), "recording_two.csv");
            testCase.verifySubstring(string(panel.Title), "recording_two.csv");
            input("path") = recordingPath;
            runtime.invokeAction("openRecording");
            testCase.verifyEqual(runtime.State.session.playback.source, string(input("path")));
            runtime.invokeAction("playRecording");
            testCase.verifyTrue(runtime.State.session.playback.playing);
            runtime.invokeAction("pauseRecording");
            testCase.verifyFalse(runtime.State.session.playback.playing);
            runtime.invokeAction("refitReplayAxes");

            runtime.applyControlValue("analysisForceZero",0);
            runtime.applyControlValue("analysisTravelZero",0);
            runtime.invokeAction("applyAnalysisZero");
            runtime.applyControlValue("experimentType","Compression");
            time=(0:600)'/50; travel=10.2-.1*time; force=-.2*max(10-travel,0); force(30)=9;
            writetable(table(time,force,travel,VariableNames=["Time_s","Force_N","Travel_mm"]),recordingPath);
            runtime.invokeAction("openRecording");
            runtime.invokeAction("detectGlitches");
            testCase.verifySubstring(runtime.State.session.analysis.glitchStatus,"1 candidates");
            runtime.applyControlValue("excludeGlitches",true);
            runtime.applyControlValue("referenceStart",0);
            runtime.applyControlValue("referenceEnd",12);
            runtime.applyControlValue("onsetThreshold",.02);
            runtime.applyControlValue("contactMin",.002);
            runtime.applyControlValue("contactMax",.04);
            runtime.invokeAction("estimateInitialLength");
            testCase.verifyEqual(runtime.State.session.analysis.gaugeLength_mm,10,AbsTol=1e-10);
            runtime.applyControlValue("gaugeLength",10);
            runtime.applyControlValue("specimenWidth",2);
            runtime.applyControlValue("specimenThickness",1);
            runtime.applyControlValue("specimenRadius",sqrt(2/pi));
            runtime.applyControlValue("specimenArea",2);
            runtime.applyControlValue("crossSectionMode","Radius");
            runtime.applyControlValue("crossSectionMode","Area");
            runtime.applyControlValue("crossSectionMode","Length x width");
            runtime.applyControlValue("geometryConfirmed",true);
            runtime.applyControlValue("analysisStart",3);
            runtime.applyControlValue("analysisEnd",10);
            testCase.verifyTrue(runtime.State.session.analysis.geometryConfirmed);
            testCase.verifyNotEmpty(runtime.State.session.analysis.estimate);
            runtime.invokeAction("updateStressStrain");
            testCase.verifyTrue(runtime.State.session.analysis.curveReady);
            runtime.invokeAction("exportStressStrain");
            exported=readtable(exportPath);
            testCase.verifyEqual(height(exported),351);
            testCase.verifyEqual(exported.Time_s([1 end]),[3;10]);
            testCase.verifyEqual(exported.Strain([1 end]),[.01;.08],AbsTol=1e-12);
            runtime.applyTableEdit("strainWindows",labkit.app.event.TableCellEdit( ...
                RowIndex=1,ColumnIndex=4,PreviousValue=10,NewValue=5));
            testCase.verifyTrue(runtime.State.session.analysis.curveReady);
            testCase.verifyError(@() runtime.applyTableEdit("strainWindows", ...
                labkit.app.event.TableCellEdit(RowIndex=1,ColumnIndex=4,PreviousValue=5,NewValue=-1)), ...
                "labkit:app:runtime:ActionFailed");
            testCase.verifyEqual(runtime.State.session.analysis.windows{1,4},5);
            nativeWindows=findall(runtime.figureHandle(),"Tag","strainWindows");
            testCase.verifyEqual(nativeWindows.Data{1,4},5);
            runtime.invokeAction("addStrainWindow");
            runtime.applyTableSelection("strainWindows",[2 1]);
            runtime.invokeAction("deleteStrainWindow");
            testCase.verifySize(runtime.State.session.analysis.windows,[1 4]);
            runtime.invokeAction("addStrainWindow");
            runtime.invokeAction("runModulusAnalysis");
            a=runtime.State.session.analysis;
            testCase.verifySize(a.resultRows,[2 12]);
            testCase.verifyEqual(cell2mat(a.resultRows(:,9)),[1;1],AbsTol=1e-10);
            testCase.verifySubstring(string(a.resultRows{2,12}),"partial window");
            resultsTable=findall(runtime.figureHandle(),"Tag","modulusResults");
            runtime.applyControlValue("modulusUnit","kPa");
            testCase.verifyEqual(string(resultsTable.ColumnName{3}),"E (kPa)");
            testCase.verifyEqual(cell2mat(resultsTable.Data(:,3)),[1000;1000],AbsTol=1e-8);
            runtime.applyControlValue("modulusUnit","GPa");
            testCase.verifyEqual(string(resultsTable.ColumnName{3}),"E (GPa)");
            testCase.verifyEqual(cell2mat(resultsTable.Data(:,3)),[.001;.001],AbsTol=1e-12);
            runtime.applyControlValue("modulusUnit","MPa");
            testCase.verifyEqual(cell2mat(resultsTable.Data(:,3)),[1;1],AbsTol=1e-10);
            runtime.applyControlValue("modulusUnit","Auto");
            testCase.verifyEqual(runtime.State.session.analysis.resultRows,a.resultRows);
            testCase.verifyTrue(runtime.State.session.analysis.curveReady);
            runtime.applyTableSelection("modulusResults",[2 1]);
            testCase.verifyEqual(runtime.State.session.analysis.selectedResult,2);
            runtime.invokeAction("openAnalysisDiagnostics");
            diagnostic=findall(groot,"Tag","labkitPlotWindow.diagnosticPlot");
            testCase.verifyNumElements(diagnostic,1);
            testCase.verifySubstring(string(diagnostic.Name),"recording_one.csv");
            testCase.verifyNumElements(findall(diagnostic,"Type","axes"),4);
            runtime.applyControlValue("gaugeLength",9.9);
            testCase.verifyFalse(runtime.State.session.analysis.curveReady);
            testCase.verifyFalse(runtime.State.session.analysis.geometryConfirmed);
            testCase.verifyNotEmpty(findall(diagnostic,"Type","text","String","Curve needs updating"));
            runtime.applyControlValue("gaugeLength",10);
            runtime.applyControlValue("geometryConfirmed",true);
            runtime.invokeAction("updateStressStrain");
            runtime.invokeAction("runModulusAnalysis");
            delete(diagnostic);
            runtime.applyTableSelection("modulusResults",[1 1]);
            testCase.verifyEmpty(findall(groot,"Tag","labkitPlotWindow.diagnosticPlot"));
            runtime.invokeAction("openAnalysisDiagnostics");
            diagnostic=findall(groot,"Tag","labkitPlotWindow.diagnosticPlot");
            testCase.verifyNumElements(diagnostic,1);
            capture=labkittest.nativeGraphicsCapability("interface-capture");
            if capture.Available
                analysisTab=findall(runtime.figureHandle(),"Tag","replayTab");
                analysisTab.Parent.SelectedTab=analysisTab;
                analysisPage=findall(runtime.figureHandle(),"Tag","analysisPage");
                analysisPage.Parent.SelectedTab=analysisPage;
                drawnow;
                exportapp(diagnostic,labkittest.visualEvidencePath("mark10-diagnostics",".png"));
                exportapp(runtime.figureHandle(),labkittest.visualEvidencePath("mark10-multi-window",".png"));
            end
            runtime.invokeAction("resetTimeRange");
            testCase.verifyEqual(runtime.State.session.analysis.timeStart_s,0);
            testCase.verifyEqual(runtime.State.session.analysis.timeEnd_s,12);
            runtime.invokeAction("resetAnalysisZero");
            testCase.verifyFalse(runtime.State.session.analysis.geometryConfirmed);
            runtime.invokeAction("resetRecording");
            runtime.invokeAction("disconnectDevice");
            clear cleanup
            testCase.verifyFalse(isgraphics(diagnostic));
        end
    end
end

function choice = chooseOutput(defaultPath, monitoringPath, modulusPath)
if ~contains(string(defaultPath), "stress_strain", IgnoreCase=true)
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
buffer("timestampUTC") = datetime(2026, 8, 27, 12, 0, ...
    [0; 0.1; 0.2], "TimeZone", "UTC");
buffer("timeUncertainty_s") = [0.01; 0.01; 0.01];
buffer("monitoringStartedAt") = datetime(2026, 8, 27, 12, 0, 0);
buffer("plotTime_s") = buffer("time_s");
buffer("plotForce_N") = buffer("force_N");
buffer("plotTravel_mm") = buffer("travel_mm");
end
