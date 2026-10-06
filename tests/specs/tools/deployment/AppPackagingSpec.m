classdef AppPackagingSpec < matlab.unittest.TestCase
    % Commands resolve through Root even when MATLAB can find them on its path.
    methods (TestMethodSetup)
        function configureToolPath(testCase)
            root=labkittest.setup();
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(root,"tools","deployment")));
        end
    end
    methods (Test, TestTags = {'Contract:system', 'Env:headless'})
        function packagesACommandAlreadyOnTheMatlabPath(testCase)
            % Oracle: the selected entry and asset survive a real zip round trip.
            % exist(command,'file') misclassifies this command as a local path.
            [root,folder]=sourceRoot(testCase,"selected");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(folder));
            testCase.verifyEqual(exist("labkit_PackageProbe_app","file"),2);
            result=packageLabKitApp("labkit_PackageProbe_app", ...
                fullfile(root,"package.zip"),Root=root);
            verifyBundle(testCase,root,result,"selected");
        end
        function requestedRootWinsOverAnotherCheckoutOnThePath(testCase)
            [root,~]=sourceRoot(testCase,"selected");
            [~,otherFolder]=sourceRoot(testCase,"other");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(otherFolder));
            result=packageLabKitApp("labkit_PackageProbe_app", ...
                fullfile(root,"package.zip"),Root=root);
            verifyBundle(testCase,root,result,"selected");
        end
        function supportsExplicitEntryAndFolderSelectors(testCase)
            [root,folder]=sourceRoot(testCase,"explicit");
            selectors=[string(fullfile(folder,"labkit_PackageProbe_app.m")),string(folder)];
            result=packageLabKitApp(selectors,fullfile(root,"package.zip"),Root=root);
            testCase.verifyNumElements(result.appCommands,1);
            verifyBundle(testCase,root,result,"explicit");
        end
    end
end

function [root,folder]=sourceRoot(testCase,marker)
root=testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
folder=fullfile(root,"apps","instruments","probe");
writeText(fullfile(folder,"labkit_PackageProbe_app.m"), ...
    "function result=labkit_PackageProbe_app; result="""+marker+"""; end");
writeText(fullfile(folder,"asset.txt"),marker);
writeText(fullfile(root,"labkit_launcher.m"),"% Synthetic source launcher");
writeText(fullfile(root,"+labkit","placeholder.m"),"% Synthetic library asset");
writeText(fullfile(root,"tools","deployment","packageLabKitApp.m"),"% Synthetic tool source");
writeText(fullfile(root,"tools","profiling","profileLabKitTarget.m"),"% Synthetic tool source");
end

function verifyBundle(testCase,root,result,marker)
testCase.verifyEqual(result.appCommands,"labkit_PackageProbe_app");
testCase.verifyEqual(result.entryFiles,"run_labkit_PackageProbe_app.m");
testCase.verifyTrue(isfile(result.zipFile));
unpacked=fullfile(root,"unpacked");unzip(result.zipFile,unpacked);
bundle=fullfile(unpacked,result.packageRootName);
folder=fullfile(bundle,"apps","instruments","probe");
testCase.verifyEqual(string(fileread(fullfile(folder,"asset.txt"))),marker);
testCase.verifyTrue(isfile(fullfile(folder,"labkit_PackageProbe_app.m")));
testCase.verifyTrue(isfile(fullfile(bundle,result.entryFiles)));
end

function writeText(file,text)
folder=fileparts(file);if ~isfolder(folder),mkdir(folder);end
fid=fopen(file,"w");assert(fid>0);cleanup=onCleanup(@() fclose(fid));
fprintf(fid,"%s",text);
end
