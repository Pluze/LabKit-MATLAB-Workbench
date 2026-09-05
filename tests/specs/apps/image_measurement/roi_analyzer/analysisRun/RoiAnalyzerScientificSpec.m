classdef RoiAnalyzerScientificSpec < matlab.unittest.TestCase
    %ROIANALYZERSCIENTIFICSPEC Specify original-pixel ROI statistics.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function measuresBatchWithExplicitMissingAndAdjustedRows(testCase)
            folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            first = string(fullfile(folder, "first.png"));
            small = string(fullfile(folder, "small.png"));
            missing = string(fullfile(folder, "missing.png"));
            imwrite(uint8(10 .* ones(8)), first);
            imwrite(uint8(20 .* ones(2)), small);
            sources = [labkit.app.source.record("a", "source-image", first); ...
                labkit.app.source.record("b", "source-image", small); ...
                labkit.app.source.record("c", "source-image", missing); ...
                labkit.app.source.record("d", "source-image", first)];
            templates = roi_analyzer.roiTemplates.defaultTemplates();
            templates(1).size = [3 3];
            roi = roi_analyzer.roiLibrary.emptyRoi();
            roi.id = "roi"; roi.name = "Sample";
            roi.templateId = templates(1).id; roi.centerXY = [4 4];
            annotations = repmat(struct("sourceId", "", "rois", roi), 3, 1);
            for k = 1:3, annotations(k).sourceId = sources(k).id; end
            [items, status, failures] = roi_analyzer.analysisRun.measureSources( ...
                sources, annotations, templates, "");
            results = struct("items", items, "batchStatus", status);
            output = roi_analyzer.resultFiles.buildBatchTable(sources, annotations, templates, results);
            % Constant images give independent means; missing input must not
            % become a zero or reuse another source's previous result.
            testCase.verifyEqual(output.Mean(1:2), [10;20]);
            testCase.verifyEqual(output.GeometryAdjusted(1:2), [0;1]);
            testCase.verifyEqual(output.Status, ["Measured";"Measured";"Read failed";"No ROIs"]);
            testCase.verifyTrue(all(isnan(output.Mean(3:4))));
            testCase.verifyTrue(all(isnan(output.PixelCount(3:4))));
            testCase.verifyClass(failures{3}, "MException");
            [again, repeatedStatus] = roi_analyzer.analysisRun.measureSources(sources, annotations, templates, "");
            testCase.verifyEqual(again, items);
            testCase.verifyEqual(repeatedStatus, status);
        end

        function measuresRectangleWithIndependentOrderStatisticOracles(testCase)
            roi = makeRoi("sample", "Rectangle", [1 1 1 1]);

            result = roi_analyzer.analysisRun.measureImage( ...
                reshape(1:9, 3, 3).', roi);
            row = result.summary;

            testCase.verifyEqual(row.PixelCount, 4);
            testCase.verifyEqual(row.Integrated, 12);
            testCase.verifyEqual(row.Mean, 3);
            testCase.verifyEqual(row.StdDev, sqrt(10/3), AbsTol=1e-12);
            testCase.verifyEqual(row.Median, 3);
            testCase.verifyEqual(row.MAD, 1.5);
            testCase.verifyEqual(row.Minimum, 1);
            testCase.verifyEqual(row.Maximum, 5);
            testCase.verifyEqual(row.Quartile25, 1.75);
            testCase.verifyEqual(row.Quartile75, 4.25);
        end

        function circleUsesPixelCentersInsideItsInscribedDisk(testCase)
            roi = makeRoi("disk", "Circle", [1 1 2 2]);

            result = roi_analyzer.analysisRun.measureImage( ...
                reshape(1:9, 3, 3).', roi);

            testCase.verifyEqual(result.summary.PixelCount, 5);
            testCase.verifyEqual(result.summary.Mean, 5);
        end

        function rgbKeepsOnlyOriginalChannels(testCase)
            imageData = uint16(cat(3, 10 .* ones(2), ...
                20 .* ones(2), 30 .* ones(2)));
            roi = makeRoi("rgb", "Rectangle", [1 1 1 1]);

            result = roi_analyzer.analysisRun.measureImage(imageData, roi);

            testCase.verifyEqual(result.summary.Channel, ...
                ["Red"; "Green"; "Blue"]);
            testCase.verifyEqual(result.summary.Mean, [10; 20; 30]);
        end

        function referenceRatioUsesSameChannelOriginalMeans(testCase)
            rois = [makeRoi("reference", "Rectangle", [1 1 1 1]); ...
                makeRoi("sample", "Rectangle", [3 1 1 1])];

            result = roi_analyzer.analysisRun.measureImage( ...
                [2 4 6 8], rois, "reference");

            testCase.verifyEqual(result.summary.Ratio, ...
                [1; 7/3], AbsTol=1e-12);
        end
    end
end

function roi = makeRoi(id, shape, position)
roi = roi_analyzer.roiLibrary.emptyRoi();
roi.id = id;
roi.name = upper(id);
roi.shape = shape;
roi.position = position;
end
