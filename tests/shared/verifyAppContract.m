function verifyAppContract(testCase, packageName)
%VERIFYAPPCONTRACT Verify the public definition contract for one App.
% Expected caller: one App-owned appContract unit test.
% Inputs: testCase and packageName App package identifier.
% Side effects: none.

    setupLabKitTestPath();
    definition = feval(char(string(packageName) + ".definition"));
    testCase.verifyEqual(string(definition.AppId), string(packageName));
    testCase.verifyNotEmpty(string(definition.Entrypoint));
    testCase.verifyNotEmpty(regexp(string(definition.AppVersion), ...
        '^\d+\.\d+\.\d+$', "once"));
    testCase.verifyTrue(labkit.contract.checkRequirements( ...
        definition.Requirements).ok);
end
