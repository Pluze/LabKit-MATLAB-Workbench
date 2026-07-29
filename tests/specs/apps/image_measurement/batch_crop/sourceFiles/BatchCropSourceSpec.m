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

        function duplicatesFromRowShapedFileListStateWithoutLosingAlignment(testCase)
            project = batch_crop.projectSpec().Create();
            first = labkit.app.project.sourceRecord( ...
                "image1", "cropSource", "first.png", true);
            second = labkit.app.project.sourceRecord( ...
                "image2", "cropSource", "second.png", true);
            project.inputs.sources = [first, second];
            project.inputs.items = batch_crop.cropTasks.forSourceIds( ...
                ["image1", "image2"]).';
            project.inputs.items(1).centerXY = [2, 3];
            project.inputs.items(1).centerSet = true;
            imageOne = uint8(reshape(1:30, 5, 6));
            imageTwo = uint8(zeros(5, 6));
            applicationState = struct( ...
                "project", project, ...
                "session", struct( ...
                    "selection", struct("currentIndex", 1), ...
                    "cache", struct( ...
                        "images", {{imageOne, imageTwo}}, ...
                        "paths", ["first.png", "second.png"], ...
                        "canvas", batch_crop.cropGeometry.emptyCanvasCache())));
            callbackContext = struct("log", @(varargin) []);

            actual = batch_crop.sourceFiles.duplicateCurrent( ...
                applicationState, callbackContext);

            testCase.verifySize(actual.project.inputs.items, [3, 1]);
            testCase.verifySize(actual.project.inputs.sources, [3, 1]);
            testCase.verifySize(actual.session.cache.images, [3, 1]);
            testCase.verifySize(actual.session.cache.paths, [3, 1]);
            testCase.verifyEqual(string({actual.project.inputs.items.sourceId}).', ...
                string({actual.project.inputs.sources.id}).');
            testCase.verifyEqual(actual.session.selection.currentIndex, 2);
            testCase.verifyEqual(actual.session.cache.images{2}, imageOne);
            testCase.verifyEqual(actual.session.cache.paths(2), "first.png");
            testCase.verifyFalse(actual.project.inputs.items(2).centerSet);
            testCase.verifyEqual(actual.project.inputs.items(3).sourceId, "image2");
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
