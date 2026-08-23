function context = disconnectedCallbackContext()
%DISCONNECTEDCALLBACKCONTEXT Return an inert callback context for specifications.
%   CONTEXT = labkittest.disconnectedCallbackContext() is the stable test-only
%   seam for App specifications whose callback does
%   not require runtime services.

context = labkit.app.internal.runtime.CallbackContextFactory.disconnected();
end
