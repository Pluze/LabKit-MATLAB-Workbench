classdef Mark10SettingsSpec < matlab.unittest.TestCase
    %MARK10SETTINGSSPEC Specify driver readback mapping into editable state.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function copiesNormalizedReadbackAndDisplayUnits(testCase)
            state = struct("session", mark10Session());
            settings = labkit.mark10.decodeSettings( ...
                "V1.00;MN;CUR;FLTC3;FLTP1;AOUT25;AOFF5;FULL;IPOL0;OPOL0;B0");

            state = mark10_monitor.settings.copyReadback(state, settings);

            testCase.verifyEqual(state.session.settings.unit, "MN");
            testCase.verifyEqual(state.session.settingsDraft.unit, "mN");
            testCase.verifyEqual(state.session.settingsDraft.currentFilter, "8");
            testCase.verifyEqual(state.session.settingsDraft.autoOutput, "25");
        end
        function readableLabelsRoundTripEveryProtocolValue(testCase)
            options = mark10_monitor.settings.options();
            names = string(fieldnames(options));
            for name = names.'
                option = options.(name);
                for k = 1:numel(option.Values)
                    testCase.verifyEqual( ...
                        mark10_monitor.settings.displayChoice( ...
                            name, option.Values(k)), option.Labels(k));
                    testCase.verifyEqual( ...
                        mark10_monitor.settings.settingValue( ...
                            name, option.Labels(k)), option.Values(k));
                end
            end
            testCase.verifyEqual(options.mode.Labels(2), ...
                "Peak tension (PT)");
            testCase.verifyEqual(options.unit.Labels(2), ...
                "Millinewtons (mN)");
            testCase.verifyEqual(options.outputFormat.Labels(1), ...
                "Numeric value + units (FULL)");
            testCase.verifyError(@() ...
                mark10_monitor.settings.settingValue("mode", "Unknown"), ...
                "mark10_monitor:settings:InvalidChoice");
        end

        function refreshesAndAppliesEditableSettingsThroughVerifiedReadback(testCase)
            transportState = containers.Map("KeyType", "char", "ValueType", "any");
            transportState("command") = "";
            settingsText = "V1.00;N;CUR;FLTC0;FLTP0;AOUT0;" + ...
                "AOFF0;FULL;IPOL0;OPOL0";
            transport = struct( ...
                "Write", @(bytes) captureCommand(transportState, bytes), ...
                "Flush", @() [], ...
                "ReadUntil", @(~, ~) readSettings(transportState, settingsText), ...
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
            context = labkittest.createCallbackContext(struct( ...
                "getResource", @(~) box));
            state = struct("session", mark10Session());
            state.session.connection = struct("status", "", ...
                "lastFailure", "");

            state = mark10_monitor.settings.refresh(state, context);
            testCase.verifyEqual(state.session.settingsDraft.unit, "N");
            state = mark10_monitor.settings.apply(state, context);

            testCase.verifyEqual(state.session.connection.status, ...
                "Settings applied without SAVE.");
            testCase.verifyEqual(state.session.connection.lastFailure, "");
            testCase.verifyEqual(state.session.settingsDraft.mode, "CUR");
            retained = box("connection");
            testCase.verifyEqual(retained.Settings.OutputFormat, "FULL");
        end
    end
end

function session = mark10Session()
session = struct("settings", struct(), "settingsDraft", struct( ...
    "unit", "N", "mode", "CUR", "currentFilter", "1", ...
    "displayFilter", "1", "outputFormat", "FULL", "autoOutput", "0"));
end

function state = captureCommand(state, bytes)
command = strip(erase(string(native2unicode( ...
    uint8(bytes(:).'), "UTF-8")), char(13)));
if command ~= "/" && command ~= "\"
    state("command") = command;
end
end

function raw = readSettings(state, settingsText)
if state("command") == "LIST"
    raw = uint8(char(settingsText + newline));
else
    raw = uint8([]);
end
end
