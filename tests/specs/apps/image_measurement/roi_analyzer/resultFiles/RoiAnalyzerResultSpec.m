classdef RoiAnalyzerResultSpec < matlab.unittest.TestCase
    %ROIANALYZERRESULTSPEC Specify the stable current-result CSV payload.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function exportTablePreservesStatisticsGeometryAndImageLabel(testCase)
            roi = struct("id", "roi-1", "name", "Sample", ...
                "shape", "Rectangle", ...
                "position", [2 3 2 2]);
            measured = roi_analyzer.analysisRun.measureImage( ...
                reshape(1:36, 6, 6), roi);

            output = roi_analyzer.resultFiles.buildExportTable( ...
                measured.summary, "synthetic.png");

            testCase.verifyEqual(output.Image, "synthetic.png");
            testCase.verifyEqual(output.Mean, measured.summary.Mean);
            testCase.verifyEqual(output.X, 2);
            testCase.verifyEqual(output.Y, 3);
            testCase.verifyEqual(output.Width, 2);
            testCase.verifyEqual(output.Height, 2);
        end

        function parameterRecordExcludesSourcesPixelsAndResults(testCase)
            project = roi_analyzer.initialData();
            project.inputs.sources = struct("id", "image-1", ...
                "role", "source-image", "path", "synthetic.png");
            annotation = struct("sourceId", "image-1", "rois", ...
                roi_analyzer.roiLibrary.emptyRoi());

            record = roi_analyzer.analysisParameters.buildRecord( ...
                project, annotation);

            testCase.verifyTrue(all(isfield(record, ...
                {'templates', 'rois', 'ratioDenominatorRoiId'})));
            testCase.verifyFalse(isfield(record, "sources"));
            testCase.verifyFalse(isfield(record, "results"));
        end
    end
end
