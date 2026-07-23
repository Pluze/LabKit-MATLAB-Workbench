classdef ChronoOverlayResultSpec < matlab.unittest.TestCase
    %CHRONOOVERLAYRESULTSPEC Specify merged aligned-overlay export values.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function interpolatesMultipleTracesOntoOneAlignedExportAxis(testCase)
            first = ChronoOverlayResultSpec.item('trace 1.DTA', [-1; 0; 1], ...
                [10; 20; 30], [1; 2; 3]);
            second = ChronoOverlayResultSpec.item('trace+2.DTA', [-0.5; 0.5], ...
                [100; 200], [10; 20]);
            single = ChronoOverlayResultSpec.item('single sample.DTA', 0, 42, 5);

            tableData = chrono_overlay.resultFiles.buildOverlayExportTable( ...
                [first, second, single]);

            firstName = matlab.lang.makeValidName(first.name);
            secondName = matlab.lang.makeValidName(second.name);
            testCase.verifyEqual(tableData.TimeGapCenterAligned_s, ...
                [-1; -0.5; 0; 0.5; 1], "AbsTol", 1e-12);
            testCase.verifyEqual(tableData.(['V_' char(firstName)]), ...
                [10; 15; 20; 25; 30], "AbsTol", 1e-12);
            testCase.verifyEqual(tableData.(['I_' char(secondName)]), ...
                [NaN; 10; 15; 20; NaN], "AbsTol", 1e-12);
            testCase.verifyTrue(all(isnan(tableData.(['V_' char( ...
                matlab.lang.makeValidName(single.name))]))));
        end
    end

    methods (Static, Access = private)
        function item = item(name, time, voltage, current)
            item = struct("name", name, "tAligned_s", time(:), ...
                "Vf_V", voltage(:), "Im_A", current(:));
        end
    end
end
