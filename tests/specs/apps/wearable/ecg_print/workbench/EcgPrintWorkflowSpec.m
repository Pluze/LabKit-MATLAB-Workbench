classdef EcgPrintWorkflowSpec < matlab.unittest.TestCase
    methods (Test, TestTags={'Contract:workflow','Env:hidden-gui'})
        function importsAnalyzesReviewsAndExportsOneResult(testCase)
            % Hidden mode must be active before native construction. Exact
            % per-beat exports and diagnostics are the independent outcomes.
            testCase.assertEqual(string(getenv('LABKIT_GUI_TEST_MODE')),"hidden");
            folder=testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            project=ecgWorkflowProject(string(folder),70);
            project.parameters.roiEnd=1901; % A previous file must not define the new range.
            statsPath=fullfile(folder,'statistics.csv');
            csvPath=fullfile(folder,'beats.csv');matPath=fullfile(folder,'analysis.mat');
            backend=struct('chooseOutputFile',@(~,name)choose(name,csvPath,matPath,statsPath), ...
                'alert',@(~,~)[]);
            definition=ecg_print.definition();journal=labkittest.temporarySessionJournal(definition,folder);
            runtime=labkittest.createMatlabRuntime(definition,project,backend,journal);
            cleanup=onCleanup(@()runtime.close());
            testCase.assertFalse(runtime.StartupFailed);
            testCase.assertEqual(string(runtime.figureHandle().Visible),"off");
            testCase.verifyEqual(runtime.State.project.parameters.roiEnd,70,AbsTol=1e-8);
            for id=["roiStart","roiEnd"]
                spinner=findall(runtime.figureHandle(),'Tag',id);
                spinner=spinner(arrayfun(@(v)isprop(v,'Step'),spinner));
                testCase.assertNotEmpty(spinner);testCase.verifyEqual(spinner(1).Step,.1);
            end
            endControl=findall(runtime.figureHandle(),'Tag','roiEnd');
            for c=endControl(:)'
                if isprop(c,'Step'),testCase.verifyEqual(c.Step,.1);end
                if isprop(c,'Limits'),testCase.verifyEqual(c.Limits,[0 70],AbsTol=1e-8);end
            end
            runtime.applyControlValue('fallbackFs',500);
            runtime.applyControlValue('timeColumn',"sampleNum");
            runtime.applyControlValue('timeUnit',"samples");
            testCase.verifyTrue(runtime.State.session.importDirty);
            control=findall(runtime.figureHandle(),'Tag','analyze');
            testCase.verifyEqual(string(control.Enable),"off");
            runtime.invokeAction('refreshImport');
            testCase.verifyFalse(runtime.State.session.importDirty);
            runtime.applyControlValue('channel',"ECG");
            testCase.verifyEqual(runtime.State.session.cache.signal.fs,500,AbsTol=1e-8);
            testCase.verifyEqual(numel(runtime.State.session.cache.signal.values),35001);
            runtime.invokeAction('analyze');result=runtime.State.session.cache.ecgNext;
            testCase.assertTrue(result.ok,result.status);
            testCase.verifyGreaterThan(nnz(result.perBeat.Status=="complete"),60);
            testCase.verifySubstring(runtime.State.session.analysisStatus,"ECGNExT:");
            % Full-interval views use the applied ROI and preserve the exact
            % extraction coordinates instead of mapping noise onto raw time.
            m=ecg_print.analysisRun.debugModel(runtime.State.session.cache,false);
            testCase.verifyEqual(m.raw.values,result.raw);
            testCase.verifyEqual(m.template.values,[result.synthetic result.bandpassed]);
            testCase.verifyEqual(m.residual.values,result.raw-result.synthetic);
            testCase.verifyEqual(m.noise.time,result.time);
            testCase.verifyEqual(m.noise.values,result.noise);
            testCase.verifyEqual(m.metricNoise.values,result.nstNoise.centered);
            testCase.verifyEqual(m.metricNoise.time,result.time);
            noiseAxis=findall(runtime.figureHandle(),'Tag','resultsAxes.noise');
            ratioAxis=findall(runtime.figureHandle(),'Tag','resultsAxes.ratio');
            noiseLine=findall(noiseAxis,'Type','line');ratioLine=findall(ratioAxis,'Type','line');
            testCase.verifyEqual(noiseLine.YData(:),result.perBeat.NoiseRMS);
            testCase.verifyEqual(ratioLine.YData(:),result.perBeat.QRSNoiseDb);
            testCase.verifyEqual(ratioLine.XData(:),result.perBeat.RTime);
            testCase.verifyEqual(m.limits,[0 (numel(result.raw)-1)/result.fs]);
            ids=["raw","template","residual","noise","metricNoise","beatNoise","beatPeak","beatSnr"];
            for k=1:8
                ax=findall(runtime.figureHandle(),'Tag',"debugAxes."+ids(k));
                testCase.verifyEqual(ax.Layout.Row,k);
                testCase.verifyEqual(ax.XLim,m.limits);
            end
            top=findall(runtime.figureHandle(),'Tag','debugAxes.raw');
            bottom=findall(runtime.figureHandle(),'Tag','debugAxes.noise');
            residual=findall(runtime.figureHandle(),'Tag','debugAxes.residual');
            testCase.verifyEqual(residual.YLim,bottom.YLim);
            template=findall(runtime.figureHandle(),'Tag','debugAxes.template');
            testCase.verifyEmpty(template.Legend);
            finalNoise=findall(runtime.figureHandle(),'Tag','debugAxes.metricNoise');
            plotted=findall(finalNoise,'Type','line');
            testCase.verifyEqual(plotted.YData(:),result.nstNoise.centered);
            for pair=["beatNoise","NoiseRMS";"beatPeak","QRSPeakToPeak";"beatSnr","QRSNoiseDb"]'
                metricAxis=findall(runtime.figureHandle(),'Tag',"debugAxes."+pair(1));
                metricLine=findall(metricAxis,'Type','line');
                testCase.verifyEqual(metricLine.YData(:),result.perBeat.(pair(2)));
                testCase.verifyEqual(metricLine.XData(:),result.perBeat.RTime);
            end
            xlim(top,[10 12]);testCase.verifyEqual(bottom.XLim,[10 12]);
            testCase.verifyEqual(metricAxis.XLim,[10 12]);
            runtime.applyControlValue('debugOverlay',true);
            testCase.verifyEqual(top.Layout.Row,[1 5]);
            testCase.verifyEqual(string(bottom.Visible),"off");
            lines=findall(top,'Type','line');testCase.verifyEqual(numel(lines),6);
            runtime.applyControlValue('debugOverlay',false);
            testCase.verifyEqual(top.Layout.Row,1);testCase.verifyEqual(string(bottom.Visible),"on");
            testCase.verifyEqual(top.XLim,bottom.XLim);
            % Repeated redraws retain live linkage, not merely equal limits.
            xlim(top,[14 16]);testCase.verifyEqual(bottom.XLim,[14 16]);
            testCase.verifyEqual(metricAxis.XLim,[14 16]);
            e=result.windows(1).extraction;
            testCase.verifyEqual(e.bandResidualNoise+e.restoredResidualNoise,e.noise,AbsTol=1e-12);
            testCase.verifyEqual(e.compressedRaw-e.noise,e.compressedSignal,AbsTol=1e-12);
            runtime.invokeAction('exportSegments');runtime.invokeAction('exportEcgNext');runtime.invokeAction('exportStatistics');
            exportedStats=readtable(statsPath,'TextType','string');
            testCase.verifyEqual(exportedStats,result.statistics,AbsTol=1e-10);
            csv=readtable(csvPath,'TextType','string');saved=load(matPath,'ecgNext');
            testCase.verifyEqual(csv,result.perBeat,AbsTol=1e-10);
            testCase.verifyEqual(saved.ecgNext,result);
            runtime.applyControlValue('roiEnd',10);
            testCase.verifySubstring(runtime.State.session.analysisStatus,"Settings changed");
            runtime.invokeAction('analyze');
            testCase.verifyFalse(runtime.State.session.cache.ecgNext.ok);
            testCase.verifySubstring(runtime.State.session.analysisStatus,"30 seconds");
            runtime.applyControlValue('channel',"Motion");
            testCase.verifyEmpty(runtime.State.session.cache.ecgNext);
            testCase.verifyEmpty(runtime.State.session.cache.events);
            % Raw-recording inspection must no longer move per-beat axes.
            rawAxis=findall(runtime.figureHandle(),'Tag','resultsAxes.wave');
            independentLimits=noiseAxis.XLim;
            xlim(rawAxis,[2 4]);testCase.verifyEqual(noiseAxis.XLim,independentLimits);
            runtime.applyControlValue('timeColumn',"missing_clock");
            runtime.invokeAction('refreshImport');
            testCase.verifyEmpty(runtime.State.session.cache.signal);
            testCase.verifyEqual(runtime.State.project.parameters.roiEnd,0);
            testCase.verifyEqual(string(runtime.figureHandle().Visible),"off");
            runtime.close();
            logs=dir(fullfile(folder,'sessions','*','events-*.jsonl'));
            content="";
            for k=1:numel(logs),content=content+string(fileread(fullfile(logs(k).folder,logs(k).name)));end
            testCase.verifySubstring(content,'ecg_print.analysisrun.ecgnext.completed');
            testCase.verifySubstring(content,'ecg_print.analysisrun.ecgnext.unavailable');
            testCase.verifySubstring(content,'measuredBeatCount');
        end
    end
end
function result=choose(name,csvPath,matPath,statsPath)
if string(name)=="ecg_statistics.csv"
    result=labkit.app.dialog.Choice(statsPath);
elseif string(name)=="ecg_beats.csv"
    result=labkit.app.dialog.Choice(csvPath);
else
    result=labkit.app.dialog.Choice(matPath);
end
end
