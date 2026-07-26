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

        function preservesNativePreviewPixelsForOrdinaryImages(testCase)
            item = batch_crop.sourceFiles.emptyItem();
            item.image = uint8(zeros(2000, 3000));
            geometry = batch_crop.cropGeometry.currentGeometry( ...
                batch_crop.cropGeometry.emptyCanvasCache(), 1, item, 0);

            testCase.verifyEqual(geometry.coordinateScale, 1);
            testCase.verifySize(geometry.canvas, [2000 3000]);
        end

        function movesTheCropCenterWhenTheManagedRoiMoves(testCase)
            state = stateWithImage(uint8(zeros(200, 300)));
            state.project.parameters.cropWidth = 40;
            state.project.parameters.cropHeight = 30;
            state.project.inputs.items(1).centerXY = [150 120];
            state.project.inputs.items(1).centerSet = true;
            item = batch_crop.sourceFiles.currentItem(state);
            [geometry, ~] = batch_crop.cropGeometry.currentGeometry( ...
                state.session.cache.canvas, 1, item, 0);
            position = batch_crop.cropGeometry.cropRectanglePosition( ...
                geometry, item.centerXY, [40 30]);

            state = batch_crop.cropGeometry.changeCropRectangle( ...
                state, position + [20 -10 0 0], ...
                labkit.app.internal.CallbackContextFactory.create( ...
                    struct("log", @(varargin) [])));

            testCase.verifyEqual(state.project.inputs.items(1).centerXY, ...
                [170.5 110.5]);
            testCase.verifyTrue(state.project.inputs.items(1).centerSet);
        end

        function setsTheCropCenterWhenAnyCanvasPointIsClicked(testCase)
            state = stateWithImage(uint8(zeros(200, 300)));
            state.project.parameters.cropWidth = 40;
            state.project.parameters.cropHeight = 30;
            state.project.inputs.items(1).centerXY = [150 120];
            state.project.inputs.items(1).centerSet = true;

            state = batch_crop.cropGeometry.changeCenterFromPreview( ...
                state, [155 125], ...
                labkit.app.internal.CallbackContextFactory.create( ...
                    struct("log", @(varargin) [])));

            testCase.verifyEqual(state.project.inputs.items(1).centerXY, ...
                [155.5 125.5]);
            testCase.verifyTrue(state.project.inputs.items(1).centerSet);
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

        function repairsDarkEdgesWithoutMutatingInteriorPixels(testCase)
            image = uint8(180 .* ones(20, 30));
            image(:, 1) = 0;
            image(9:12, 9:12) = 200;

            [padded, padding] = batch_crop.cropGeometry.padImageEdges(image, 40);

            source = padded((1:20) + padding.top, (1:30) + padding.left);
            leftPadding = double(padded(padding.top + 10, 1:padding.left));
            testCase.verifyEqual(source(9:12, 9:12), image(9:12, 9:12));
            testCase.verifyGreaterThan(source(10, 1), 120);
            testCase.verifyGreaterThan(min(leftPadding), 60);
        end

        function keepsRotatedCropsInsideTheValidMaskWhenPossible(testCase)
            image = uint8(zeros(7, 9));

            result = batch_crop.cropGeometry.cropImage(image, struct( ...
                "cropWidth", 3, "cropHeight", 3, "centerXY", [2 5], ...
                "angleDeg", 33, "paddingPercent", 40));

            testCase.verifyEqual([result.centerX result.centerY], ...
                [1.9393 4.7952], AbsTol=1e-4);
            testCase.verifyEqual(max(result.image, [], "all"), uint8(0));
            testCase.verifyEqual([result.sourceWidth result.sourceHeight], [9 7]);
            testCase.verifyEqual(result.paddingPercent, 40);
        end

        function preservesTheOriginalPreviewViewportAcrossPaddingAndScaleChanges(testCase)
            image = uint8(zeros(120, 160));
            first = batch_crop.cropGeometry.prepareCropCanvas(image, struct( ...
                "angleDeg", 0, "paddingPercent", 20));
            second = batch_crop.cropGeometry.prepareCropCanvas(image, struct( ...
                "angleDeg", 0, "paddingPercent", 200, "maxCanvasPixels", 5000));
            firstPlacement = batch_crop.cropPreview.placement(first);
            secondPlacement = batch_crop.cropPreview.placement(second);
            figureValue = figure(Visible="off");
            cleanup = onCleanup(@() close(figureValue));
            axesValue = axes(Parent=figureValue);
            axesValue.XLim = [30 70];
            axesValue.YLim = [25 65];

            view = batch_crop.cropPreview.captureView(axesValue, first, firstPlacement);
            batch_crop.cropPreview.restoreView(axesValue, view, second, secondPlacement);
            xCanvas = axesValue.XLim - secondPlacement.offset(1);
            yCanvas = axesValue.YLim - secondPlacement.offset(2);
            leftTop = batch_crop.cropGeometry.canvasToOriginal(second, [xCanvas(1) yCanvas(1)]);
            rightBottom = batch_crop.cropGeometry.canvasToOriginal(second, [xCanvas(2) yCanvas(2)]);

            testCase.verifyLessThan(second.coordinateScale, first.coordinateScale);
            testCase.verifyEqual(sort([leftTop(1) rightBottom(1)]), view.originalXLim, AbsTol=1e-9);
            testCase.verifyEqual(sort([leftTop(2) rightBottom(2)]), view.originalYLim, AbsTol=1e-9);
            clear cleanup
        end
    end
end

function state = stateWithImage(imageData)
project = batch_crop.projectSpec().Create();
project.inputs.items = batch_crop.cropTasks.forSourceIds("image1");
state = struct("project", project, "session", struct( ...
    "selection", struct("currentIndex", 1), ...
    "workflow", struct("cropDefaultsInitialized", true, ...
        "scaleReferenceEditing", false), ...
    "view", struct("scaleBar", []), ...
    "cache", struct("images", {{imageData}}, "paths", "source.png", ...
        "canvas", batch_crop.cropGeometry.emptyCanvasCache())));
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
