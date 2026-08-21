classdef BatchCropPresentationSpec < matlab.unittest.TestCase
    %BATCHCROPPRESENTATIONSPEC Specify batch crop workflow declarations.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function declaresSourceCropScaleAndExportControls(testCase)
            plan = labkittest.inspectDefinition(batch_crop.definition());
            ids = string({plan.Nodes.Id});

            testCase.verifyTrue(all(ismember( ...
                ["images" "restoreManifest" "cropWidth" ...
                 "exportCrops" "resultTable"], ids)));
        end
    end
end
