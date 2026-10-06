classdef Mark10AnalysisSpec < matlab.unittest.TestCase
    % Analytic ramps, hysteresis, weak linearity and full-resolution export.
    methods (Test, TestTags={'Contract:scientific','Env:headless'})
        function extrapolatesBothDirections(tc)
            p=parameters(); t=(0:600)'/50;
            for kind=["Compression","Tension"]
                d=1; if kind=="Compression", d=-1; end
                x=10+d*(t-2)*.1; f=d*max((t-2)*.1,0)*.2;
                e=mark10_monitor.analysis.estimateInitialLength(t,f,x,p,kind);
                tc.verifyEqual(e.length_mm,10,AbsTol=1e-6);
                tc.verifyEqual(e.rSquared,1,AbsTol=1e-12);
                tc.verifyEqual(e.time_s,2,AbsTol=1e-5);
            end
        end
        function referenceIsIndependentAndFailureHasNoSilentFallback(tc)
            p=parameters(); p.timeStart_s=6;p.timeEnd_s=10;
            t=(0:600)'/50;x=10.2-.1*t;f=-.2*max(10-x,0);
            e=mark10_monitor.analysis.estimateInitialLength(t,f,x,p,"Compression");
            tc.verifyEqual(e.length_mm,10,AbsTol=1e-6);
            c=mark10_monitor.analysis.prepareCurve(t,f,x,p,"Compression");
            tc.verifyEqual(c.time_s([1 end]),[6;10]);
            p.contactTime_s=6;t=t(t>=4);x=10.2-.1*t;f=-.2*max(10-x,0);
            tc.verifyError(@() mark10_monitor.analysis.estimateInitialLength(t,f,x,p,"Compression"), ...
                "mark10_monitor:analysis:ContactNotResolved");
        end
        function infersCurvedContactWithDriftAndAnIsolatedOutlier(tc)
            % Oracle: analytic contact at 3.2 s / 10 mm, independent of force scale.
            p=parameters();p.referenceEnd_s=8;p.contactTime_s=3;
            t=(0:400)'/50;x=10+.1*(3.2-t);h=max(10-x,0);
            f=.003+.0002*t-(.08*h+.4*h.^2)+.0001*sin(31*t);f(100)=.3;
            for scale=[.001,1,1000]
                e=mark10_monitor.analysis.estimateInitialLength(t,scale*f,x,p,"Compression");
                tc.verifyEqual(e.length_mm,10,AbsTol=.025);
                tc.verifyEqual(e.modelName,"Curved initial loading");
                tc.verifyGreaterThan(e.baselineCount,6);
            end
        end
        function refusesUnresolvedOrUnbracketedContact(tc)
            p=parameters();t=(0:400)'/50;x=10+.1*(3-t);
            tc.verifyError(@() mark10_monitor.analysis.estimateInitialLength(t,zeros(size(t)),x,p,"Compression"), ...
                "mark10_monitor:analysis:ContactNotResolved");
            p.contactTime_s=-1;
            tc.verifyError(@() mark10_monitor.analysis.estimateInitialLength(t,zeros(size(t)),x,p,"Compression"), ...
                "mark10_monitor:analysis:InvalidTimeRange");
        end
        function contactIgnoresHintWithinApproachAndLaterStiffening(tc)
            p=parameters();t=(0:1000)'/50;x=10+.1*(3.2-t);
            h=max(10-x,0);f=-(.08*h+.4*h.^2);
            reference=[];
            for hint=[1 3 7]
                p.contactTime_s=hint;
                a=mark10_monitor.analysis.estimateInitialLength(t,f,x,p,"Compression");
                tc.verifyEqual(a.length_mm,10,AbsTol=1e-5);
                if isempty(reference),reference=a.length_mm;end
                tc.verifyEqual(a.length_mm,reference,AbsTol=1e-10);
                % Stiffening begins beyond every 12%-travel contact window.
                late=f-100*max(t-17,0).^3;
                b=mark10_monitor.analysis.estimateInitialLength(t,late,x,p,"Compression");
                tc.verifyEqual(b.length_mm,a.length_mm,AbsTol=1e-10);
            end
        end
        function contactHintSelectsSeparateApproaches(tc)
            p=parameters();t=(0:1800)'/50;
            x=[10.2-.1*t(1:601);9+.1*(t(602:1201)-12);10.2-.1*(t(1202:end)-24)];
            f=-.2*max(10-x,0);
            for hint=[2 26]
                p.contactTime_s=hint;
                e=mark10_monitor.analysis.estimateInitialLength(t,f,x,p,"Compression");
                tc.verifyEqual(e.length_mm,10,AbsTol=1e-5);
                tc.verifyEqual(e.time_s,hint,AbsTol=1e-4);
            end
        end
        function reportsTestDirectionMismatchExplicitly(tc)
            t=(0:100)'/10;x=10-.1*t;
            tc.verifyError(@() mark10_monitor.analysis.contactEpisode(t,x,3,"Tension"), ...
                "mark10_monitor:analysis:TestDirectionMismatch");
            tc.verifyError(@() mark10_monitor.analysis.contactEpisode(t,-x,3,"Compression"), ...
                "mark10_monitor:analysis:TestDirectionMismatch");
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
            tc.verifySize(r.rows,[2 12]);
            tc.verifyEqual(cell2mat(r.rows(:,9)),[15;15],AbsTol=1e-10);
            cyc=p;cyc.windows={true,'early',-8,-2;true,'late',-18,-10};
            cycles=mark10_monitor.analysis.compute(t,f,x,cyc,"Cyclic");
            tc.verifySize(cycles.rows,[4 12]);
            tc.verifyEqual(cell2mat(cycles.rows(:,9)),[15;15;7.5;7.5],AbsTol=1e-10);
            p.timeStart_s=10.2;r=mark10_monitor.analysis.compute(t,f,x,p,"Compression");
            tc.verifyEqual(cell2mat(r.rows(:,9)),[7.5;7.5],AbsTol=1e-10);
        end
        function singleTestsUseOneLoadingSegmentAndCyclesKeepAll(tc)
            p=parameters();t=(0:8).';e=[0;.05;.1;.15;.2;.15;.1;.05;0];
            for kind=["Tension","Compression"]
                signValue=1;if kind=="Compression",signValue=-1;end
                curve=mark10_monitor.analysis.prepareCurve(t,signValue*4*e,10+signValue*10*e,p,kind);
                result=mark10_monitor.analysis.fitWindows(curve,p.windows,kind);
                tc.verifySize(result.rows,[1 12]);
                tc.verifyEqual(result.rows{1,9},2,AbsTol=1e-12);
                tc.verifySubstring(string(result.rows{1,2}),"increasing");
                cyclic=mark10_monitor.analysis.fitWindows(curve,p.windows,"Cyclic");
                tc.verifySize(cyclic.rows,[2 12]);
                p.timeStart_s=5;
                recovery=mark10_monitor.analysis.compute(t,signValue*4*e,10+signValue*10*e,p,kind);
                tc.verifySize(recovery.rows,[1 12]);
                tc.verifySubstring(string(recovery.rows{1,2}),"decreasing");
                p.timeStart_s=0;
            end
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
    'contactTime_s',2, ...
    'excludeGlitches',false,'windows',{{true,'Region 1',0,20}});
end
