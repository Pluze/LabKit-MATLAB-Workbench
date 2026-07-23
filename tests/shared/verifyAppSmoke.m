function verifyAppSmoke(testCase, packageName)
%VERIFYAPPSMOKE Launch one App through its supported SDK entry contract.
% Expected caller: one independently selectable App GUI smoke test.
% Inputs: testCase MATLAB unit test and packageName App package identifier.
% Side effects: creates and closes an off-screen App UI.

    setupLabKitTestPath();
    helpers = guiTestHelpers();
    helpers.assertUifigureAvailable();
    cleanup = onCleanup(@() helpers.closeAllFigures());
    definition = feval(char(string(packageName) + ".definition"));
    runtime = labkit.app.internal.RuntimeFactory.createMatlab(definition);
    runtimeCleanup = onCleanup(@() runtime.close());
    figure = runtime.figureHandle();

    testCase.verifyTrue(isgraphics(figure, "figure"), ...
        "The App smoke proof must create a native interactive figure.");
    testCase.verifyNotEmpty(findall(figure), ...
        "The App smoke proof must materialize its declared product layout.");
    clear runtimeCleanup cleanup
end
