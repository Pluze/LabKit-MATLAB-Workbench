classdef EcgPrintPresentationSpec < matlab.unittest.TestCase
    methods (Test, TestTags={'Contract:presentation','Env:headless'})
        function defaultsToValidTenthsWithoutChangingFileDuration(testCase)
            % The selected endpoint must not exceed the exact source extent.
            for duration=[65.234134123123123 65.28 65.2 70]
                state=struct('session',struct('cache',struct('signal', ...
                    struct('time',[0;duration]))),'project',struct('parameters',struct()));
                updated=ecg_print.analysisRun.resetRange(state);
                expected=65.2;
                if duration==70,expected=70;end
                testCase.verifyEqual(updated.project.parameters.roiEnd,expected,AbsTol=1e-12);
                testCase.verifyEqual(updated.session.cache.signal.time(end),duration);
                testCase.verifyLessThanOrEqual(updated.project.parameters.roiEnd,duration);
            end
        end
        function preservesFullOverviewAndPeakCoordinates(testCase)
            signal=struct('time',(0:9999)'/1000,'values',zeros(10000,1), ...
                'fs',1000,'displayName',"ECG",'unit',"mV",'metadata',struct());
            signal.values([1001 2001])=[3 4];
            filtered=signal;filtered.values=circshift(signal.values,5);
            result=struct('rPeaks',[1001;2001],'raw',signal.values,'fs',1000, ...
                'bandpassed',filtered.values,'perBeat',table());
            cache=struct('signal',signal,'workingSignal',signal,'filteredSignal',filtered,'ecgNext',result);
            model=ecg_print.analysisRun.previewModels(cache);
            testCase.verifyEqual(model.time,signal.time);
            testCase.verifyEqual(model.ecg,signal.values);
            testCase.verifyEqual(model.peakValues,[3;4]);
            testCase.verifyEqual(model.peakTime,[1;2]);testCase.verifyEqual(model.unit,"mV");
        end
    end
end
