classdef EcgPrintScientificSpec < matlab.unittest.TestCase
    methods (Test, TestTags={'Contract:scientific','Env:headless'})
        function preservesFdaNoiseAndAssignsEverySample(testCase)
            % Frozen unmodified FDA oracle independently fixes subtraction,
            % median alignment, QRS removal, crossfade and time coordinates.
            d=load(fullfile(fileparts(mfilename('fullpath')),'ecgNextOracle.mat'));
            x=ecg_print.analysisRun.ecgNextExtract(d.raw,d.bandpassed,d.rPeaks,d.fs);
            testCase.verifyEqual(x.noise,d.noise,AbsTol=1e-12);
            testCase.verifyEqual(x.time,d.plotTime,AbsTol=1e-12);
            % Midpoint samples belong to the later beat (half-open intervals).
            midpoints=(d.rPeaks(1:end-1)+d.rPeaks(2:end))/2;
            nearest=1+sum(round(x.time(:)*1000+1)>=midpoints,2);
            testCase.assertEqual(x.beatIndex(:),nearest);
            a=signal(d.raw,1000);b=signal(d.bandpassed,1000);
            result=ecg_print.analysisRun.ecgNextAnalysis(a,b,struct('index',d.rPeaks));
            testCase.verifyTrue(result.ok);
            testCase.verifyEqual(result.noise,d.noise(:),AbsTol=1e-12);
            testCase.verifyEqual(result.time,d.plotTime(:),AbsTol=1e-12);
            testCase.verifyEqual(sum(result.perBeat.NoiseSamples),numel(d.noise));
            for k=find(result.perBeat.Status=="complete")'
                expected=result.statisticsNoise.detrended(nearest==k);
                rms=sqrt(mean(expected.^2));
                testCase.verifyEqual(result.perBeat.NoiseRMS(k),rms,AbsTol=1e-12);
                qrs=d.bandpassed(d.rPeaks(k)-50:d.rPeaks(k)+50);
                amp=max(qrs)-min(qrs);
                testCase.verifyEqual(result.perBeat.QRSPeakToPeak(k),amp,AbsTol=1e-12);
                testCase.verifyEqual(result.perBeat.QRSNoiseDb(k), ...
                    20*log10(amp/(sqrt(8)*rms)),AbsTol=1e-12);
            end
            testCase.verifyEqual(ecg_print.analysisRun.ecgNextAnalysis(a,b,struct('index',d.rPeaks)),result);
        end
        function usesOverlappingWindowsWithoutDuplicateBeats(testCase)
            % Known noise amplitude steps from .02 to .1; a global RMS copied
            % onto every beat, duplicate joins, or lost interior beats fails.
            [raw,bp,events]=prepared(95);
            result=ecg_print.analysisRun.ecgNextAnalysis(raw,bp,events);
            testCase.verifyTrue(result.ok);
            testCase.verifyEqual(height(result.perBeat),numel(events.index));
            testCase.verifyGreaterThan(numel(result.windows),1);
            t=result.perBeat;
            interior=t.RTime>3 & t.RTime<92;
            testCase.verifyTrue(all(t.Status(interior)=="complete"));
            testCase.verifyTrue(all(diff(result.time)>0));
            testCase.verifyEqual(numel(result.noise),sum(t.NoiseSamples));
            early=median(t.NoiseRMS(t.RTime>5 & t.RTime<25));
            late=median(t.NoiseRMS(t.RTime>65 & t.RTime<85));
            testCase.verifyGreaterThan(late/early,4);
            testCase.verifyLessThan(late/early,6);
        end
        function preservesPTAndUsesOnlyQrsForAmplitude(testCase)
            [raw,bp,events]=prepared(40);
            result=ecg_print.analysisRun.ecgNextExtract(bp.values,bp.values,events.index,1000);
            testCase.verifyLessThan(sqrt(mean(result.noise.^2)),.01);
            x=zeros(40001,1);peaks=501:1000:39501;x(peaks)=.8;x(peaks+20)=-.2;
            original=ecg_print.analysisRun.qrsAmplitude(x,peaks,1000);
            x(peaks-200)=3;x(peaks+250)=4;
            testCase.verifyEqual(ecg_print.analysisRun.qrsAmplitude(x,peaks,1000),original);
            x(peaks)=.4; reduced=ecg_print.analysisRun.qrsAmplitude(x,peaks,1000);
            testCase.verifyEqual(reduced.peakToPeak,.6,AbsTol=1e-14);
            testCase.verifyGreaterThan(std(raw.values),0);
        end
        function preparesRatesAndMatchesIndependentButterworth(testCase)
            d=load(fullfile(fileparts(mfilename('fullpath')),'ecgNextOracle.mat'));
            testCase.verifyEqual(ecg_print.analysisRun.ecgNextBandpass(d.raw),d.bandpassed,AbsTol=2e-10);
            fs=2000;t=(0:80000)'/fs;
            source=signal(sin(2*pi*10*t)+sin(2*pi*800*t),fs);
            [raw,bp,info]=ecg_print.analysisRun.prepareSignal(source,[5 35]);
            testCase.verifyEqual(raw.fs,1000);testCase.verifyEqual(numel(raw.values),30001);
            testCase.verifyEqual(info.antialiasCutoffHz,450);
            testCase.verifyEqual(raw.metadata.sourceStartSeconds,5);
            spectrum=abs(fft(raw.values(5001:25000)));
            testCase.verifyLessThan(spectrum(4001)/spectrum(201),.01);
            testCase.verifyEqual(numel(bp.values),numel(raw.values));
        end
        function excludesOutsideArtifactsAndSettlesFilterEdges(testCase)
            % Excluded spikes must never influence an ROI. An even periodic
            % endpoint has an independently known zero-baseline passband.
            fs=1000;t=(0:60000)'/fs;x=1000+cos(2*pi*10*t);
            [raw,bp,info]=ecg_print.analysisRun.prepareSignal(signal(x,fs),[10 50]);
            altered=x;altered(t<10|t>50)=1e8*sin(t(t<10|t>50));
            [other,filtered]=ecg_print.analysisRun.prepareSignal(signal(altered,fs),[10 50]);
            testCase.verifyEqual(other.values,raw.values);
            testCase.verifyEqual(filtered.values,bp.values);
            testCase.verifyLessThan(max(abs(bp.values-cos(2*pi*10*raw.time))),.01);
            testCase.verifyEqual(info.sourceTimeRangeSeconds,[10 50]);
            testCase.verifyEqual(info.reflectionSeconds,15);
        end
        function reportsUnavailableWithoutInventedNoise(testCase)
            [raw,bp,events]=prepared(10);
            result=ecg_print.analysisRun.ecgNextAnalysis(raw,bp,events);
            testCase.verifyFalse(result.ok);testCase.verifyEqual(result.statusCode,"short-record");
            testCase.verifyTrue(all(isnan(result.perBeat.NoiseRMS)));
            [raw,bp,~]=prepared(40);
            result=ecg_print.analysisRun.ecgNextAnalysis(raw,bp,struct('index',[1001 1101 1201 1301]));
            testCase.verifyFalse(result.ok);testCase.verifyEqual(result.statusCode,"peak-geometry");
            testCase.verifyError(@() ecg_print.analysisRun.ecgNextExtract(raw.values,bp.values,[1001 2001 3001 4001],512),'ecg_print:InvalidECGNextInput');
        end
        function summarizesFiniteBeatsWithSampleVariance(testCase)
            % Hand-computed values detect population variance,
            % accidental trimming, and inclusion of boundary/undefined rows.
            t=table([1;3;5;100;NaN],[2;4;6;100;NaN],[10;20;30;100;Inf], ...
                ["complete";"complete";"complete";"boundary";"complete"], ...
                'VariableNames',{'NoiseRMS','QRSPeakToPeak','QRSNoiseDb','Status'});
            s=ecg_print.analysisRun.beatStatistics(t,"mV");
            testCase.verifyEqual(s.Mean,[3;4;20]);testCase.verifyEqual(s.Variance,[4;4;100]);
            testCase.verifyEqual(s.N,[3;3;3]);testCase.verifyEqual(s.VarianceUnit,["mV^2";"mV^2";"dB^2"]);
            one=ecg_print.analysisRun.beatStatistics(t(1,:),"mV");
            testCase.verifyTrue(all(isnan(one.Variance)));
        end
        function removesDriftWithinBeatOwnershipInsteadOfSecondBlocks(testCase)
            % Repeated [1 -2 1] is orthogonal to constants and time. Known
            % unequal beat lengths cross second boundaries; a fixed-second
            % or mean-only implementation leaves a ramp and fails this oracle.
            t=(0:2004)'/1000;
            residual=[repmat([1;-2;1],367,1);3*repmat([1;-2;1],301,1);0];
            identities=[ones(1101,1);2*ones(903,1);3];
            noise=[100+50*t(1:1101);-200-30*t(1102:2004);999]+residual;
            n=ecg_print.analysisRun.beatNoiseStatistics(noise,t,identities,[true;true;false]);
            testCase.verifyEqual(n.detrended(1:2004),residual(1:2004),AbsTol=1e-11);
            testCase.verifyTrue(isnan(n.detrended(end)));
            testCase.verifyEqual(n.fits.RemovedSlope(1:2),[50;-30],AbsTol=1e-10);
            testCase.verifyEqual(n.fits.NoiseSamples,[1101;903;1]);
            testCase.verifyEqual(n.trend(1:2004)+n.detrended(1:2004),noise(1:2004),AbsTol=1e-11);
            changed=noise+5000+70*t;
            other=ecg_print.analysisRun.beatNoiseStatistics(changed,t,identities,[true;true;false]);
            testCase.verifyEqual(other.detrended,n.detrended,AbsTol=1e-10);
            % This prescribed nonuniform coordinate makes index-based
            % detrending incorrect even when the beat mean is removed.
            times=[0;.2;.5;1;1.1;1.5;1.8];
            expected=[3;-5;2;4;-5;1;0];
            values=10+4*times+expected;
            irregular=ecg_print.analysisRun.beatNoiseStatistics(values,times,[1;1;1;2;2;2;2],[true;true]);
            testCase.verifyEqual(irregular.detrended,expected,AbsTol=1e-12);
            testCase.verifyEqual(irregular.fits.RemovedSlope,[4;4],AbsTol=1e-12);
            tiny=ecg_print.analysisRun.beatNoiseStatistics([1;2],[0;1],[1;1],true);
            testCase.verifyTrue(all(isnan(tiny.detrended)));
            flatTime=ecg_print.analysisRun.beatNoiseStatistics([1;2;3],[0;0;0],[1;1;1],true);
            testCase.verifyTrue(all(isnan(flatTime.detrended)));
            testCase.verifyError(@()ecg_print.analysisRun.beatNoiseStatistics([1;NaN],[0;1],[1;1],true), ...
                'ecg_print:InvalidBeatNoiseInput');
            d=load(fullfile(fileparts(mfilename('fullpath')),'ecgNextOracle.mat'));
            result=ecg_print.analysisRun.ecgNextAnalysis(signal(d.raw,1000), ...
                signal(d.bandpassed,1000),struct('index',d.rPeaks));
            expected=NaN(size(result.noise));
            for beat=find(result.perBeat.Status=="complete")'
                ids=result.beatIndex==beat;times=result.time(ids);values=result.noise(ids);
                coefficients=polyfit(times,values,1);
                expected(ids)=values-polyval(coefficients,times);
                testCase.verifyEqual(result.perBeat.NoiseRMS(beat), ...
                    sqrt(mean(expected(ids).^2)),AbsTol=1e-12);
                testCase.verifyLessThan(abs(mean(result.statisticsNoise.detrended(ids))),1e-12);
            end
            testCase.verifyEqual(result.statisticsNoise.detrended,expected,AbsTol=1e-12);
            testCase.verifyEqual(result.noise,d.noise(:),AbsTol=1e-12);
        end
        function localizesRawPeaksWithoutFollowingDistantWaves(testCase)
            % Known extrema differ from detector anchors; distant larger
            % waves must not pull an anchor outside the local QRS search.
            raw=signal(1000*ones(1000,1),1000);
            raw.values([110 310 510])=[1010 1011 1012];
            raw.values([140 340 540])=[1100 900 1100];
            raw.values([95 295 495])=900; % Larger negative lobes cannot become R.
            events=struct('index',[100;300;500],'metadata',struct());
            actual=ecg_print.analysisRun.refineRPeaks(events,raw,.15);
            testCase.verifyEqual(actual.index,[110;310;510]);
            testCase.verifyEqual(actual.amplitude,[1010;1011;1012]);
            testCase.verifyEqual(actual.time,[.109;.309;.509],AbsTol=1e-12);
            testCase.verifyEqual(actual.metadata.rawLocalization.shiftSamples,[10;10;10]);
            % A conflicting move must retain the original beat identities.
            raw.values(:)=0;raw.values([120 390])=[5 5];
            events.index=[100;400];
            actual=ecg_print.analysisRun.refineRPeaks(events,raw,.3);
            testCase.verifyEqual(actual.index,[100;400]);
        end
        function analyzesFullSourceThroughSinglePipeline(testCase)
            [raw,~,~]=prepared(70);
            params=struct('roiStart',0,'roiEnd',0,'peakMethod',"QRS streaming",'peakDistance',.28);
            cache=ecg_print.analysisRun.analyzeSignal(struct('signal',raw),params);
            testCase.verifyTrue(cache.ecgNext.ok);
            testCase.verifyGreaterThan(nnz(cache.ecgNext.perBeat.Status=="complete"),60);
            testCase.verifyEqual(cache.signal,raw);
            testCase.verifyEqual(cache.ecgNext.preparation.sourceFs,1000);
            testCase.verifyEqual(cache.peakDetectionSignal.metadata.filter.cutoffHz,[5 20]);
        end
    end
end
function x=signal(values,fs)
x=struct('values',values(:),'time',(0:numel(values)-1)'/fs,'fs',fs, ...
    'metadata',struct(),'displayName',"ECG",'unit',"mV");
end
function [raw,bp,events]=prepared(duration)
t=(0:duration*1000)'/1000;r=1001:900:numel(t)-1000;
y=zeros(size(t));
for index=r
    u=t-(index-1)/1000;
    y=y+exp(-(u/.012).^2)+.2*exp(-((u+.18)/.04).^2)+.3*exp(-((u-.26)/.06).^2);
end
amplitude=.02+.08*(t>45);
bp=signal(y,1000);raw=signal(y+amplitude.*sin(2*pi*61.7*t),1000);events=struct('index',r);
end
