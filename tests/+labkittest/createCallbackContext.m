function context = createCallbackContext(backend)
%CREATECALLBACKCONTEXT Construct an App callback context for specifications.
%   CONTEXT = labkittest.createCallbackContext(BACKEND) is the stable
%   test-only seam for App specifications that
%   exercise callbacks without a complete runtime. BACKEND is a scalar struct.

arguments
    backend (1, 1) struct
end

context = labkit.app.internal.runtime.CallbackContextFactory.create(backend);
end
