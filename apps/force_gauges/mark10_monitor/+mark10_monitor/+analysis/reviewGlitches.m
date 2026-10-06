function applicationState = reviewGlitches(applicationState, context)
%REVIEWGLITCHES Inspect full-source isolated candidates without changing raw data.
[t,f,x]=mark10_monitor.analysis.sourceData(applicationState,context);
valid=isfinite(t)&isfinite(f)&isfinite(x); t=t(valid); f=f(valid); x=x(valid);
[mask,fmask,xmask]=mark10_monitor.analysis.detectGlitches(f,x);
a=applicationState.session.analysis;
a.excludedPreview=struct("time_s",t(mask),"force_N",f(mask),"gap_mm",x(mask));
a.glitchStatus=compose("%d candidates (%d force, %d travel). Exclusion is optional; narrow real peaks may also be flagged.",nnz(mask),nnz(fmask),nnz(xmask));
applicationState.session.analysis=a;
end
