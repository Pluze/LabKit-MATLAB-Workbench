classdef Mark10AnalysisSpec < matlab.unittest.TestCase
    % Analytic ramps, hysteresis, weak linearity and full-resolution export.
    methods (Test, TestTags={'Contract:scientific','Env:headless'})
        function extrapolatesBothDirections(tc)
            p=parameters(); t=(0:600)'/50;
            for kind=["Compression","Tension"]
                d=1; if kind=="Compression", d=-1; end
                x=10+d*(t-2)*.1; f=d*max((t-2)*.1,0)*.2;
                e=mark10_monitor.analysis.estimateInitialLength(t,f,x,p,kind);
                tc.verifyEqual(e.length_mm,10,AbsTol=1e-10);
                tc.verifyEqual(e.rSquared,1,AbsTol=1e-12);
                tc.verifyGreaterThan(d*(e.thresholdLength_mm-10),0);
            end
        end
        function referenceIsIndependentAndFailureHasNoSilentFallback(tc)
            p=parameters(); p.timeStart_s=6;p.timeEnd_s=10;
            t=(0:600)'/50;x=10.2-.1*t;f=-.2*max(10-x,0);
            e=mark10_monitor.analysis.estimateInitialLength(t,f,x,p,"Compression");
            tc.verifyEqual(e.length_mm,10,AbsTol=1e-10);
            c=mark10_monitor.analysis.prepareCurve(t,f,x,p,"Compression");
            tc.verifyEqual(c.time_s([1 end]),[6;10]);
            p.contactMin_N=.0001;p.contactMax_N=.0002;
            tc.verifyError(@() mark10_monitor.analysis.estimateInitialLength(t,f,x,p,"Compression"), ...
                "mark10_monitor:analysis:InsufficientContactFit");
        end
        function detectsIsolatedSpikeButRetainsStep(tc)
            f=zeros(100,1);x=linspace(12,8,100)';f(30)=9;f(60:end)=2;
            mask=mark10_monitor.analysis.detectGlitches(f,x);
            tc.verifyTrue(mask(30));tc.verifyFalse(any(mask(60:end)));
            p=parameters();p.excludeGlitches=true;
            c=mark10_monitor.analysis.prepareCurve((0:99)'/10,f,x,p,"Compression");
            tc.verifyFalse(any(c.sourceIndex==30));tc.verifyEqual(c.excludedCount,1);
            tc.verifyNumElements(unique(c.segment),1);
        end
        function preservesSignsAreaModesAndEngineeringSlope(tc)
            p=parameters();t=(0:100)'/10;e=linspace(0,.2,101)';
            for kind=["Compression","Tension","Cyclic"]
                d=1;if kind=="Compression",d=-1;end
                for mode=["Length x width","Radius","Area"]
                    p.crossSectionMode=mode;p.radius_mm=sqrt(2/pi);p.area_mm2=2;
                    r=mark10_monitor.analysis.compute(t,d*30*e,10+d*10*e,p,kind);
                    tc.verifyEqual(r.curve.strain,e,AbsTol=1e-12);
                    tc.verifyEqual(r.rows{1,9},15,AbsTol=1e-10);
                end
            end
        end
        function offsetsPreservePhysicalCoordinates(tc)
            p=parameters();t=(0:100)'/10;x=10-t/10;f=-3*(10-x);
            a=mark10_monitor.analysis.prepareCurve(t,f,x,p,"Compression");
            p.forceZero_N=2;p.travelZero_mm=4;
            b=mark10_monitor.analysis.prepareCurve(t,f+2,x+4,p,"Compression");
            tc.verifyEqual(b.strain,a.strain,AbsTol=1e-12);
            tc.verifyEqual(b.stress_MPa,a.stress_MPa,AbsTol=1e-12);
        end
        function separatesBranchesAndRestrictsTime(tc)
            p=parameters();p.windows={true,'early',2,8;true,'late',10,18};
            x=[linspace(10,8,101),linspace(8,10,101)]';t=(0:201)'/10;
            f=[-3*(10-x(1:101));-1.5*(10-x(102:end))];p.timeEnd_s=max(t);
            r=mark10_monitor.analysis.compute(t,f,x,p,"Compression");
            tc.verifySize(r.rows,[4 12]);
            tc.verifyEqual(cell2mat(r.rows(:,9)),[15;15;7.5;7.5],AbsTol=1e-10);
            p.timeStart_s=10.2;r=mark10_monitor.analysis.compute(t,f,x,p,"Compression");
            tc.verifyEqual(cell2mat(r.rows(:,9)),[7.5;7.5],AbsTol=1e-10);
        end
        function keepsNonlinearNegativeAndPartialFits(tc)
            p=parameters();p.windows={true,'all',0,20;true,'partial',10,30;true,'empty',40,50};
            t=(0:100)'/10;e=linspace(0,.2,101)';y=-3*e+.6*sin(50*e);
            r=mark10_monitor.analysis.compute(t,2*y,10+10*e,p,"Tension");
            tc.verifyTrue(isfinite(r.rows{1,9}));tc.verifyLessThan(r.rows{1,10},.95);
            tc.verifySubstring(string(r.rows{1,12}),"low R2");
            tc.verifyTrue(isfinite(r.rows{2,9}));tc.verifySubstring(string(r.rows{2,12}),"partial");
            tc.verifyTrue(isnan(r.rows{3,9}));
            r=mark10_monitor.analysis.compute(t,-6*e,10+10*e,p,"Tension");
            tc.verifyEqual(r.rows{1,9},-3,AbsTol=1e-12);
            tc.verifySubstring(string(r.rows{1,12}),"negative slope");
        end
        function keepsTwoPointAndConstantStressFits(tc)
            p=parameters();r=mark10_monitor.analysis.compute([0;1],[0;2],[10;12],p,"Tension");
            tc.verifyEqual(r.rows{1,9},5,AbsTol=1e-12);
            tc.verifySubstring(string(r.rows{1,12}),"two points");
            r=mark10_monitor.analysis.compute([0;1],[2;2],[10;12],p,"Tension");
            tc.verifyEqual(r.rows{1,9},0);tc.verifyTrue(isnan(r.rows{1,10}));
        end
        function scalesModulusDisplayWithoutChangingScientificResults(tc)
            % Oracle: SI prefix ratios and exact 1 MPa / 1 GPa boundaries.
            % A reversed conversion or signed rather than absolute Auto rule fails.
            rows=cell(3,12);rows(:,9)={.00246;-.01409;NaN};
            [shown,unit]=mark10_monitor.analysis.resultTable(rows,"Auto");
            tc.verifyEqual(unit,"kPa");
            tc.verifyEqual(cell2mat(shown(1:2,9)),[2.46;-14.09],AbsTol=1e-12);
            tc.verifyTrue(isnan(shown{3,9}));tc.verifyEqual(rows{1,9},.00246);
            for magnitude=[1,999.9,1000,-2000]
                rows{1,9}=magnitude;
                [~,unit]=mark10_monitor.analysis.resultTable(rows,"Auto");
                expected="MPa";if abs(magnitude)>=1000,expected="GPa";end
                tc.verifyEqual(unit,expected);
            end
            rows{1,9}=2;
            for choice=["kPa","MPa","GPa"]
                [shown,unit]=mark10_monitor.analysis.resultTable(rows,choice);
                tc.verifyEqual(unit,choice);
                expected=2;if choice=="kPa",expected=2000;elseif choice=="GPa",expected=.002;end
                tc.verifyEqual(shown{1,9},expected);
            end
            rows(:,9)={0;NaN;0};
            [shown,unit]=mark10_monitor.analysis.resultTable(rows,"Auto");
            tc.verifyEqual(unit,"kPa");tc.verifyEqual(shown{1,9},0);
        end
        function exportsWholeSelectedCurve(tc)
            p=parameters();p.timeStart_s=2;p.timeEnd_s=8;t=(0:1000)'/100;x=10-t/10;
            c=mark10_monitor.analysis.prepareCurve(t,-3*(10-x),x,p,"Compression");
            out=mark10_monitor.analysis.exportTable(c);
            tc.verifyEqual(string(out.Properties.VariableNames),["Time_s","Strain","Stress_MPa"]);
            tc.verifyEqual(height(out),601);tc.verifyEqual(out.Time_s([1 end]),[2;8]);
            tc.verifyEqual(out.Strain,(10-x(201:801))/10,AbsTol=1e-12);
        end
        function rejectsInvalidGeometryAndTime(tc)
            p=parameters();p.geometryConfirmed=false;
            tc.verifyError(@() mark10_monitor.analysis.compute([0;1],[0;1],[10;11],p,"Tension"), ...
                "mark10_monitor:analysis:GeometryNotConfirmed");
            p.geometryConfirmed=true;p.timeStart_s=2;p.timeEnd_s=1;
            tc.verifyError(@() mark10_monitor.analysis.compute([0;1],[0;1],[10;11],p,"Tension"), ...
                "mark10_monitor:analysis:InvalidTimeRange");
        end
        function invalidationFollowsDependencies(tc)
            a=parameters();a.resultRevision=0;a.curve=mark10_monitor.analysis.emptyCurve();
            a.curveReady=true;a.estimate=struct('length_mm',10);a.geometryConfirmed=true;
            s=struct('session',struct('analysis',a));
            s=mark10_monitor.analysis.invalidateWindows(s,[],[]);tc.verifyTrue(s.session.analysis.curveReady);
            s=mark10_monitor.analysis.invalidate(s,[],[]);tc.verifyFalse(s.session.analysis.curveReady);
            tc.verifyTrue(s.session.analysis.geometryConfirmed);tc.verifyNotEmpty(s.session.analysis.estimate);
            s=mark10_monitor.analysis.invalidateReference(s,[],[]);
            tc.verifyFalse(s.session.analysis.geometryConfirmed);tc.verifyEmpty(s.session.analysis.estimate);
        end
    end
end
function p=parameters()
p=struct('gaugeLength_mm',10,'width_mm',2,'thickness_mm',1, ...
    'crossSectionMode',"Length x width",'radius_mm',1,'area_mm2',2, ...
    'geometryConfirmed',true,'forceZero_N',0,'travelZero_mm',0, ...
    'timeStart_s',0,'timeEnd_s',12,'referenceStart_s',0,'referenceEnd_s',12, ...
    'onsetThreshold_N',.02,'contactMin_N',.002,'contactMax_N',.04, ...
    'excludeGlitches',false,'windows',{{true,'Region 1',0,20}});
end
