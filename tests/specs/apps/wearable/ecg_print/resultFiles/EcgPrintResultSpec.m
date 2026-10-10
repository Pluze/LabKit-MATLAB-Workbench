classdef EcgPrintResultSpec < matlab.unittest.TestCase
    methods (Test, TestTags={'Contract:result','Env:headless'})
        function exportsPreparedGridWithSourceCoordinates(testCase)
            s=struct('time',(0:4)'/1000,'values',(1:5)', ...
                'fs',1000,'displayName',"ECG",'unit',"mV", ...
                'metadata',struct('sourceStartSeconds',5));
            b=s;b.values=b.values*.5;
            cache=struct('signal',s,'workingSignal',s,'filteredSignal',b,'events',struct('index',3));
            t=ecg_print.resultFiles.analysisRegionTimetable(cache);
            testCase.verifyEqual(t.SourceTimeSeconds,5+(0:4)'/1000);
            testCase.verifyEqual(t.RawSignal,(1:5)');
            testCase.verifyEqual(t.FilteredSignal,(1:5)'*.5);
            testCase.verifyEqual(t.DetectedPeak,[false;false;true;false;false]);
            testCase.verifyEqual(t.Properties.VariableUnits,{'s','mV','mV',''});
        end
    end
end
