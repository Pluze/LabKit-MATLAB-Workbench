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
        function displaysExactSnrResidualsAcrossOverlappingTemplateWindows(testCase)
            % Oracle: prescribed SNR residuals and winning-window provenance.
            % Re-extracting or refitting the selected template window changes
            % these values and fails the direct sample equality checks.
            first=struct('timeShiftSamples',[10;-20],'time',[-.1 0 .2],'alignedBeats',[1 2 3;2 3 4]);
            second=struct('timeShiftSamples',[10;-20],'time',[-.2 0 .1 .3],'alignedBeats',[1 4 2 0;2 5 3 1]);
            windows=struct('startIndex',{1,10001},'endIndex',{5000,15000}, ...
                'template',{[1.5 2.5 3.5],[1.5 4.5 2.5 .5]}, ...
                'status',{"complete","complete"}, ...
                'extraction',{struct('alignment',first,'noise',[9 8 7], ...
                    'beatIndex',[1 2 2],'time',[.2 .4 1.8]),struct('alignment',second, ...
                    'noise',[2 -3 4],'beatIndex',[1 2 2],'time',[.2 .33 1.7])});
            r=struct('fs',1000,'rPeaks',[100;200;10100;10200], ...
                'windows',windows,'preparation',struct('sourceTimeRangeSeconds',[7 22]));
            r.time=[10;10.2;10.5;11;11.1;11.5;11.8];
            r.beatIndex=[3;3;3;4;4;4;4];
            r.statisticsNoise=struct('detrended',[3;-5;2;4;-5;1;0]);
            r.perBeat=table(repmat("complete",4,1),[1;1;1;2], ...
                'VariableNames',{'Status','Window'});
            cache=struct('signal',struct('unit',"mV"),'ecgNext',r);
            model=ecg_print.analysisRun.morphologyModel(cache,2);
            testCase.verifyEqual(model.windowChoices(2),"Window 2 | File 17.000-21.999 s | complete");
            testCase.verifyEqual([model.noiseBeats.beat],[3 4]);
            testCase.verifyEqual(model.noiseBeats(1).values,[3;-5;2]);
            testCase.verifyEqual(model.noiseBeats(1).sourceWindow,1);
            testCase.verifyEqual(model.noiseBeats(2).values,[4;-5;1;0]);
            testCase.verifyEqual(model.noiseBeats(1).time,[-.089;.111;.411],AbsTol=1e-12);
            testCase.verifyEqual(model.noiseBeats(2).time,[.781;.881;1.281;1.581],AbsTol=1e-12);
            testCase.verifyEqual(model.templates(1).time,[-.1 0 .2]);
            testCase.verifyEqual(model.templates(2).time,[-.2 0 .1 .3]);
            testCase.verifyEqual(model.templates(2).values,[1.5 4.5 2.5 .5]);
            testCase.verifyEqual(model.beatNumbers,[3;4]);
            cache.ecgNext.windows(2).extraction=[];
            missing=ecg_print.analysisRun.morphologyModel(cache,20);
            testCase.verifyEqual(missing.window,2);
            testCase.verifyEmpty(missing.noiseBeats);
            testCase.verifyEqual([missing.templates.window],1);
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
