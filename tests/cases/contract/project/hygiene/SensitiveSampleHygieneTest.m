classdef SensitiveSampleHygieneTest < matlab.unittest.TestCase
    %SENSITIVESAMPLEHYGIENETEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Integration', 'Style'})
        function test_sensitive_sample_hygiene(testCase)
            setupLabKitTestPath();
            verify_sensitive_sample_hygiene();
        end
    end
end

function verify_sensitive_sample_hygiene()
%TEST_SENSITIVE_SAMPLE_HYGIENE Guard tracked text against local sample-data leaks.

    root = testRepoRoot();
    scope = labkitQualityScanScope(root);
    files = cellstr(scope.textFiles);
    assert(~isempty(files), 'Sensitive sample hygiene test should scan tracked text files.');

    for k = 1:numel(files)
        filepath = files{k};
        content = fileread(filepath);
        rel = relativeRepoPath(root, filepath);
        assertNoDriveRootPath(content, rel);
        assertNoCurrentHomePath(content, rel);
        assertNoSampleTimestampToken(content, rel);
    end
end

function rel = relativeRepoPath(root, filepath)
    prefix = [root filesep];
    rel = filepath;
    if startsWith(filepath, prefix)
        rel = filepath(numel(prefix)+1:end);
    end
    rel = strrep(rel, filesep, '/');
end

function assertNoDriveRootPath(content, rel)
    drivePathPattern = '[A-Za-z]:[\\/]';
    matchStarts = regexp(content, drivePathPattern, 'start');
    isDriveRoot = false(size(matchStarts));
    for k = 1:numel(matchStarts)
        isDriveRoot(k) = matchStarts(k) == 1 || ...
            ~isstrprop(content(matchStarts(k)-1), 'alpha');
    end
    assert(~any(isDriveRoot), ...
        ['Tracked text file %s contains a drive-root absolute path. ' ...
        'Use synthetic relative paths in source, tests, and docs.'], rel);
end

function assertNoCurrentHomePath(content, rel)
    homeValues = unique(string({getenv('USERPROFILE'), getenv('HOME')}));
    for k = 1:numel(homeValues)
        home = homeValues(k);
        if strlength(home) <= 3
            continue;
        end
        variants = unique([home, replace(home, "\", "/"), replace(home, "/", "\")]);
        for i = 1:numel(variants)
            assert(~contains(content, variants(i)), ...
                ['Tracked text file %s contains the current user home path. ' ...
                'Use synthetic relative paths in source, tests, and docs.'], rel);
        end
    end
end

function assertNoSampleTimestampToken(content, rel)
    sampleTimestampPattern = '\d{8}_\d{6}';
    assert(isempty(regexp(content, sampleTimestampPattern, 'once')), ...
        ['Tracked text file %s contains a timestamp-shaped sample token. ' ...
        'Use synthetic fixture names and metadata in source, tests, and docs.'], rel);
end
