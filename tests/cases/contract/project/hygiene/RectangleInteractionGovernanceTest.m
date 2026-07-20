classdef RectangleInteractionGovernanceTest < matlab.unittest.TestCase
    %RECTANGLEINTERACTIONGOVERNANCETEST Guard managed plot-region behavior.

    methods (Test, TestTags = {'Integration', 'Style'})
        function directRectangleCallsStayInsideReviewedBoundaries(testCase)
            root = setupLabKitTestPath();
            files = sourceFiles(root);
            directFiles = filesWithDirectRectangleCalls(root, files);
            expected = [
                "+labkit/+app/+interaction/rectangle.m"
                "+labkit/+app/+internal/private/createRectangleEditor.m"
                "+labkit/+app/+internal/private/reconcileInteractions.m"
                "+labkit/+app/+view/Snapshot.m"
                "apps/dic/dic_preprocess/+dic_preprocess/+analysisRun/drawPreview.m"
                "apps/image_measurement/batch_crop/+batch_crop/+cropPreview/draw.m"
                "apps/image_measurement/flir_thermal/+flir_thermal/+thermalPreview/+presentationData/drawTemperatureReadings.m"
                "apps/image_measurement/image_enhance/+image_enhance/+imagePreview/draw.m"
            ];
            testCase.verifyEqual(sort(directFiles), sort(expected), ...
                ['Editable rectangles must use labkit.app.interaction.rectangle. ' ...
                'Direct graphics primitives require an explicit boundary review.']);

            appDirectFiles = directFiles(startsWith(directFiles, "apps/"));
            for k = 1:numel(appDirectFiles)
                source = fileread(fullfile(root, char(appDirectFiles(k))));
                hitTestOff = contains(source, "'HitTest', 'off'") || ...
                    contains(source, 'HitTest="off"');
                pickingOff = contains(source, "'PickableParts', 'none'") || ...
                    contains(source, 'PickableParts="none"');
                testCase.verifyTrue(hitTestOff && pickingOff, ...
                    appDirectFiles(k) + ...
                    " must keep direct rectangle overlays non-pickable.");
            end
        end

        function knownInteractiveWorkflowsDeclareSemanticInteractions(testCase)
            root = setupLabKitTestPath();
            rectangleLayouts = [
                "apps/dic/dic_preprocess/+dic_preprocess/+workbench/buildLayout.m"
                "apps/image_measurement/image_enhance/+image_enhance/+workbench/buildLayout.m"
            ];
            for k = 1:numel(rectangleLayouts)
                source = fileread(fullfile(root, char(rectangleLayouts(k))));
                testCase.verifyTrue(contains(source, ...
                    "labkit.app.interaction.rectangle("), ...
                    rectangleLayouts(k) + ...
                    " must declare an App SDK managed rectangle.");
            end

            batchCropLayout = fileread(fullfile(root, ...
                'apps/image_measurement/batch_crop/+batch_crop', ...
                '+workbench/buildLayout.m'));
            testCase.verifyTrue(contains(batchCropLayout, ...
                'labkit.app.interaction.pointSlots("cropCenter"') && ...
                contains(batchCropLayout, ...
                '"placeSelectedOnBackground", true'), ...
                ['Batch Crop uses a fixed-size ROI, so its Imager-style ' ...
                'interaction must expose a draggable center plus one-click ' ...
                'placement instead of a misleading resizable rectangle.']);

            flirLayout = fileread(fullfile(root, ...
                'apps/image_measurement/flir_thermal/+flir_thermal', ...
                '+workbench/buildLayout.m'));
            testCase.verifyTrue(contains(flirLayout, ...
                'labkit.app.interaction.regionSelection(') && ...
                contains(flirLayout, ...
                'OnBackgroundPressed=@flir_thermal.temperatureReadings.changePoint'), ...
                ['FLIR point and ROI reads must share one App SDK managed ' ...
                'region-selection gesture with explicit point dispatch.']);
        end
    end
end

function files = sourceFiles(root)
    [status, output] = system(sprintf([ ...
        'git -C "%s" ls-files --cached --others --exclude-standard ' ...
        '+labkit apps'], root));
    assert(status == 0, 'Could not list rectangle source files.');
    files = string(splitlines(strtrim(output)));
    files = files(endsWith(files, ".m"));
    existsNow = arrayfun(@(file) isfile(fullfile(root, file)), files);
    files = files(existsNow);
end

function files = filesWithDirectRectangleCalls(root, candidates)
    files = strings(0, 1);
    pattern = '(?<![A-Za-z0-9_.])rectangle\s*\(';
    for k = 1:numel(candidates)
        source = fileread(fullfile(root, char(candidates(k))));
        if ~isempty(regexp(source, pattern, 'once'))
            files(end + 1, 1) = replace(candidates(k), "\", "/");
        end
    end
end
