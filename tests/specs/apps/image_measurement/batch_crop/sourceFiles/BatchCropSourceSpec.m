classdef BatchCropSourceSpec < matlab.unittest.TestCase
    %BATCHCROPSOURCESPEC Specify source-item workflow readiness.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function labelsOnlyTheItemsMissingAPhysicalScale(testCase)
            ready = item("ready.png", true);
            missing = item("needs_scale.png", false);

            entries = batch_crop.sourceFiles.taskEntries([ready; missing], "Physical");

            testCase.verifyEqual(string({entries.status}).', ["ready"; "needs scale"]);
        end
    end
end

function value = item(path, calibrated)
value = batch_crop.sourceFiles.emptyItem();
value.path = path;
value.image = uint8(ones(8));
value.centerXY = [4 4];
value.centerSet = true;
if calibrated
    value.scaleCalibration = labkit.app.interaction.scaleCalibration(40, 10, "um");
else
    value.scaleCalibration = batch_crop.scaleCalibration.emptyCalibration("um");
end
end
