classdef BatchCropSourceSpec < matlab.unittest.TestCase
    %BATCHCROPSOURCESPEC Specify source-item workflow readiness.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function labelsOnlyTheItemsMissingAPhysicalScale(testCase)
            ready = item("ready.png", true);
            missing = item("needs_scale.png", false);

            entries = batch_crop.sourceFiles.taskEntries([ready; missing], "Physical");

            testCase.verifyEqual(string({entries.status}).', ["ready"; "needs scale"]);
        end

        function createsAnIndependentDeferredTaskForEachDuplicateSource(testCase)
            task = batch_crop.cropTasks.forSourceIds("image1");
            item = batch_crop.sourceFiles.emptyItem();
            item.path = "source.png";
            item.image = uint8(ones(5, 6));
            item.angleDeg = 12;
            item.centerXY = [3 4];
            item.centerSet = true;
            item.paddingPercent = 25;
            duplicate = batch_crop.cropTasks.duplicateItem(item);

            testCase.verifyEqual(task.sourceId, "image1");
            testCase.verifyFalse(isfield(task, "image"));
            testCase.verifyEqual(duplicate.path, item.path);
            testCase.verifyEqual(duplicate.angleDeg, item.angleDeg);
            testCase.verifyFalse(duplicate.centerSet);
            testCase.verifyTrue(all(isnan(duplicate.centerXY)));
            duplicate.paddingPercent = 50;
            testCase.verifyEqual(item.paddingPercent, 25);
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
