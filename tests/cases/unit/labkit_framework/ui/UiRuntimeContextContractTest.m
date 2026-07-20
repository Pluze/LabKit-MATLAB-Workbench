classdef UiRuntimeContextContractTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Unit'})
        function noCapabilityContextRejectsOperations(testCase)
            setupLabKitTestPath();
            context = ...
                labkit.app.internal.CallbackContextFactory.disconnected();

            testCase.verifyTrue(meta.class.fromName( ...
                "labkit.app.CallbackContext").Sealed);
            testCase.verifyError(@() context.alert("message", "title"), ...
                "labkit:app:runtime:InvariantFailure");
        end

        function namedOperationsUseOneSealedBackend(testCase)
            setupLabKitTestPath();
            store = containers.Map("KeyType", "char", "ValueType", "any");
            backend = struct( ...
                "appendStatus", @appendStatus, ...
                "choose", @choose, ...
                "chooseInputFolder", @chooseFolder, ...
                "chooseOutputFolder", @chooseFolder, ...
                "sourcePaths", @sourcePaths, ...
                "setResource", @setResource, ...
                "getResource", @getResource, ...
                "removeResource", @removeResource, ...
                "clearResourceScope", @clearResourceScope);
            context = labkit.app.internal.CallbackContextFactory.create(backend);
            context.appendStatus("ready");
            choice = context.chooseOption("Continue?", ["yes", "no"], ...
                Title="Continue operation?", DefaultChoice="no", ...
                CancelChoice="no");
            inputFolder = context.chooseInputFolder("input");
            outputFolder = context.chooseOutputFolder("output");
            context.setResource("document", "reader", 42, []);
            value = context.getResource("document", "reader");
            paths = context.resolveSourcePaths(struct(), ["first", "second"]);

            testCase.verifyEqual(choice.Value, "yes");
            testCase.verifyEqual(store("choiceTitle"), ...
                "Continue operation?");
            testCase.verifyEqual(store("choiceDefault"), "no");
            testCase.verifyEqual(store("choiceCancel"), "no");
            testCase.verifyError(@() context.chooseOption( ...
                "Continue?", ["yes", "no"], DefaultChoice="later"), ...
                "labkit:app:contract:InvalidValue");
            testCase.verifyError(@() context.chooseOption( ...
                "Continue?", ["yes", "yes"]), ...
                "labkit:app:contract:InvalidValue");
            testCase.verifyEqual(inputFolder.Value, "input/selected");
            testCase.verifyEqual(outputFolder.Value, "output/selected");
            testCase.verifyEqual(value, 42);
            testCase.verifyEqual(store("status"), "ready");
            testCase.verifyEqual(paths, ["first"; "second"] + ".dat");
            testCase.verifyError(@() context.reportError( ...
                "operation", MException("probe:error", "failure")), ...
                "labkit:app:runtime:InvariantFailure");
            function appendStatus(message)
                store("status") = message;
            end

            function result = choose(~, choices, title, ...
                    defaultChoice, cancelChoice)
                store("choiceTitle") = title;
                store("choiceDefault") = defaultChoice;
                store("choiceCancel") = cancelChoice;
                result = labkit.app.dialog.Choice(choices(1));
            end

            function result = chooseFolder(startPath)
                result = labkit.app.dialog.Choice( ...
                    string(startPath) + "/selected");
            end

            function paths = sourcePaths(~, ids)
                paths = ids + ".dat";
            end

            function setResource(scope, id, resource, ~)
                store(char(scope + ":" + id)) = resource;
            end

            function resource = getResource(scope, id)
                resource = store(char(scope + ":" + id));
            end

            function removeResource(scope, id)
                remove(store, char(scope + ":" + id));
            end

            function clearResourceScope(scope)
                keys = string(store.keys);
                selected = startsWith(keys, scope + ":");
                remove(store, cellstr(keys(selected)));
            end
        end
    end
end
