classdef FlirThermalPresentationSpec < matlab.unittest.TestCase
    %FLIRTHERMALPRESENTATIONSPEC Specify the declared thermal reader workflow.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function declaresFileDisplayReadingAndExportControls(testCase)
            plan = labkittest.inspectDefinition(flir_thermal.definition());
            ids = string({plan.Nodes.Id});

            testCase.verifyTrue(all(ismember( ...
                ["thermalFiles" "summaryTable" "exportCurrent" "exportAll"], ids)));
        end

        function rendersNonlinearColorsWithoutMutatingTemperatures(testCase)
            values = [10 20; 40 90];
            baseline = values;
            linear = flir_thermal.thermalPreview.presentationData.renderThermalImage( ...
                values, [10 90], "turbo", "Linear");
            gamma = flir_thermal.thermalPreview.presentationData.renderThermalImage( ...
                values, [10 90], "turbo", "Gamma", 1.6);

            testCase.verifyEqual(values, baseline);
            testCase.verifyGreaterThan(max(abs(linear(:) - gamma(:))), 0);
        end
    end
end
