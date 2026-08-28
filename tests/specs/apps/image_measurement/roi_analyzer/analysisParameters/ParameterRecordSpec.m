classdef ParameterRecordSpec < matlab.unittest.TestCase
    % PARAMETERRECORDSPEC Invariant: parameter records omit source paths, pixels, and stale measurements.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function provesParameterRecord(testCase)
            project = roi_analyzer.initialData();
            project.inputs.sources = labkit.app.source.record( ...
                "image-1", "source-image", "sample.png");
            project.results.lastExportPath = "old-results.csv";
            roi = roi_analyzer.roiLibrary.emptyRoi();
            roi.id = "roi-1";
            roi.name = "Signal";
            roi.templateId = project.annotations.templates(1).id;
            roi.centerXY = [12 18];
            annotation = struct("sourceId", "image-1", "rois", roi);

            record = roi_analyzer.analysisParameters.buildRecord( ...
                project, annotation);

            testCase.verifyEqual(sort(string(fieldnames(record))), sort([ ...
                "format"; "formatVersion"; "templates"; "rois"; ...
                "ratioDenominatorRoiId"]));
            testCase.verifyEqual(record.rois.centerXY, [12 18]);
            encoded = string(jsonencode(record));
            testCase.verifyFalse(contains(encoded, "sample.png"));
            testCase.verifyFalse(contains(encoded, "old-results.csv"));
        end
    end
end
