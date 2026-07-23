classdef BatchCropGeometrySpec < matlab.unittest.TestCase
    %BATCHCROPGEOMETRYSPEC Specify crop geometry and calibrated output plans.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function cropsAtTheRequestedPixelSizeWithoutChangingImageClass(testCase)
            image = uint8(reshape(1:100, 10, 10));

            result = batch_crop.cropGeometry.cropImage(image, struct( ...
                "cropWidth", 4, "cropHeight", 3, "centerXY", [5 6], ...
                "angleDeg", 0, "paddingPercent", 0));

            testCase.verifyTrue(result.ok);
            testCase.verifyClass(result.image, "uint8");
            testCase.verifySize(result.image, [3 4]);
            testCase.verifyEqual([result.cropWidth result.cropHeight], [4 3]);
        end

        function keepsOriginalCoordinatesAcrossThePreviewCanvasTransform(testCase)
            image = uint8(zeros(120, 160));
            geometry = batch_crop.cropGeometry.prepareCropCanvas(image, struct( ...
                "angleDeg", 35, "paddingPercent", 200, "maxCanvasPixels", 4000));
            point = [73.25 44.75];

            recovered = batch_crop.cropGeometry.canvasToOriginal(geometry, ...
                batch_crop.cropGeometry.originalToCanvas(geometry, point));

            testCase.verifyLessThan(geometry.coordinateScale, 1);
            testCase.verifyEqual(recovered, point, AbsTol=1e-9);
        end

        function plansOnePhysicalOutputSizeAcrossUnequalCalibrations(testCase)
            items = [physicalItem("a.png", 4); physicalItem("b.png", 8)];

            plan = batch_crop.cropGeometry.scalePlan(items, struct( ...
                "physicalWidth", 10, "physicalHeight", 5, "scaleUnit", "um", ...
                "targetPixelsPerUnit", 6, "maxUpsamplePercent", 15));

            testCase.verifyEqual([plan.outputWidth plan.outputHeight], [60 30]);
            testCase.verifyEqual(plan.nativeCropWidth, [40; 80]);
            testCase.verifyTrue(contains(plan.warnings(1), "upsample"));
        end
    end
end

function item = physicalItem(path, pixelsPerUnit)
item = batch_crop.sourceFiles.emptyItem();
item.path = path;
item.image = uint8(80 .* ones(120, 120));
item.centerXY = [60 60];
item.centerSet = true;
item.scaleCalibration = labkit.app.interaction.scaleCalibration( ...
    40, 40 ./ pixelsPerUnit, "um");
end
