function context = debugSampleContext(root)
%DEBUGSAMPLECONTEXT Typed filesystem context for App debug-sample tests.
    context = labkit.app.diagnostic.SampleContext(string(root));
end
