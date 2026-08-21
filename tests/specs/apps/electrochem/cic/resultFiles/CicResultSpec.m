classdef CicResultSpec < matlab.unittest.TestCase
    %CICRESULTSPEC Verify result-schema evidence consumed after CIC calculation.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function preservesResultSchemaAndUnits(testCase)
            item = testfixtures.dta.chronoItem('', 'chrono.DTA');
            item.analysis = cic.analysisRun.computeCIC(item, defaultOptions());
            failed = item;
            failed.name = 'failed.DTA';
            failed.analysis = struct('ok', false, 'message', 'bad input');

            tableData = cic.resultFiles.buildResultsTable([item, failed], 'uC/cm^2');

            testCase.verifyEqual(tableData.Properties.VariableNames(8:10), ...
                {'CICc_uCcm2', 'CICa_uCcm2', 'CICt_uCcm2'});
            testCase.verifyEqual(tableData.CICc_uCcm2(1), 1e4, 'AbsTol', 1e-12);
            testCase.verifyEqual(tableData.CICt_uCcm2(1), 2e4, 'AbsTol', 1e-12);
            testCase.verifyTrue(isnan(tableData.CICt_uCcm2(2)));
            testCase.verifyEqual(tableData.Detection{2}, 'failed');
        end
    end
end

function options = defaultOptions()
    choices = cic.analysisRun.analysisChoices();
    options = struct('delay_s', 10e-6, 'cathLimit', -0.6, 'anodLimit', 0.8, ...
        'areaOverride', '', 'pulseMode', char(choices.pulseModes(1)), ...
        'usedMeasuredCurrent', true);
end
