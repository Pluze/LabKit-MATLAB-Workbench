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
    end
end

function session = mark10Session()
session = struct("settings", struct(), "settingsDraft", struct( ...
    "unit", "N", "mode", "CUR", "currentFilter", "1", ...
    "displayFilter", "1", "outputFormat", "FULL", "autoOutput", "0"));
end
