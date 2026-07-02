classdef RhsFacadeTest < matlab.unittest.TestCase
    %RHSFACADETEST Verify GUI-free Intan RHS facade behavior.

    methods (Test, TestTags = {'Unit'})
        function rhsFacadeReadsHeaderIndexAndWindows(testCase)
            setupLabKitTestPath();

            fixtureDir = tempname;
            mkdir(fixtureDir);
            cleaner = onCleanup(@() removeFolderIfPresent(fixtureDir));
            rhsFile = fullfile(fixtureDir, 'synthetic_primary.rhs');
            nestedDir = fullfile(fixtureDir, 'nested');
            mkdir(nestedDir);
            nestedFile = fullfile(nestedDir, 'synthetic_secondary.rhs');
            writeSyntheticRhs(rhsFile, 2);
            writeSyntheticRhs(nestedFile, 1);

            files = labkit.rhs.findFiles(fixtureDir);
            testCase.verifyEqual(numel(files), 2);
            testCase.verifyTrue(any(strcmp(files, rhsFile)));
            testCase.verifyTrue(any(strcmp(files, nestedFile)));
            testCase.verifyError(@() labkit.rhs.findFiles(42), ...
                'labkit:rhs:InvalidFolder');

            [info, infoStatus] = labkit.rhs.inspectFile(rhsFile);
            testCase.verifyTrue(infoStatus.ok, infoStatus.message);
            testCase.verifyEqual(info.fileVersion, [3 4]);
            testCase.verifyEqual(info.sampleRateHz, 30000);
            testCase.verifyEqual(numel(info.channelFamilies.amplifier), 2);
            testCase.verifyEqual(numel(info.channelFamilies.boardAdc), 1);
            testCase.verifyEqual(numel(info.channelFamilies.boardDigIn), 1);
            testCase.verifyEqual(info.sampleCount, 256);
            testCase.verifyTrue(info.exactBlocks);
            testCase.verifyEqual(info.channelTable.nativeName(1), "C-001");

            [index, indexStatus] = labkit.rhs.indexFile(rhsFile);
            testCase.verifyTrue(indexStatus.ok, indexStatus.message);
            testCase.verifyTrue(index.hasData);
            testCase.verifyEqual(index.blockCount, 2);
            testCase.verifyEqual(index.sampleCount, 256);

            opts = struct("family", "amplifier", ...
                "channels", "C001", ...
                "timeRangeSec", [0 3/30000]);
            [ampWindow, ampStatus] = labkit.rhs.readWindow(rhsFile, opts);
            testCase.verifyTrue(ampStatus.ok, ampStatus.message);
            testCase.verifyEqual(ampWindow.family, "amplifier");
            testCase.verifyEqual(ampWindow.channels, "C-001");
            testCase.verifySize(ampWindow.values, [4 1]);
            testCase.verifyEqual(ampWindow.values(:).', 0.195 .* (100:103), ...
                "AbsTol", 1e-12);

            opts.family = "stim";
            [stimWindow, stimStatus] = labkit.rhs.readWindow(rhsFile, opts);
            testCase.verifyTrue(stimStatus.ok, stimStatus.message);
            testCase.verifyEqual(stimWindow.values(:).', [1 -2 3 0], ...
                "AbsTol", 1e-6);

            opts = struct("family", "boardDigIn", ...
                "channels", "DIN001", ...
                "timeRangeSec", [0 3/30000]);
            [digWindow, digStatus] = labkit.rhs.readWindow(rhsFile, opts);
            testCase.verifyTrue(digStatus.ok, digStatus.message);
            testCase.verifyEqual(digWindow.values(:).', [0 1 0 1]);
        end
    end
end

function writeSyntheticRhs(filepath, nBlocks)
    fid = fopen(filepath, 'w', 'ieee-le');
    if fid < 0
        error('Could not create synthetic RHS fixture.');
    end
    cleaner = onCleanup(@() fclose(fid));

    sampleRate = 30000;
    samplesPerBlock = 128;
    stimStepSize = 1e-6;

    fwrite(fid, uint32(hex2dec('d69127ac')), 'uint32');
    fwrite(fid, int16([3 4]), 'int16');
    fwrite(fid, single(sampleRate), 'single');
    fwrite(fid, int16(0), 'int16');
    fwrite(fid, single([0 1 1 7500 0 1 1 7500]), 'single');
    fwrite(fid, int16(0), 'int16');
    fwrite(fid, single([1000 1000]), 'single');
    fwrite(fid, int16([0 0]), 'int16');
    fwrite(fid, single([stimStepSize 0 0]), 'single');
    writeQString(fid, "");
    writeQString(fid, "");
    writeQString(fid, "");
    fwrite(fid, int16(0), 'int16');
    fwrite(fid, int16(0), 'int16');
    writeQString(fid, "n/a");

    fwrite(fid, int16(1), 'int16');
    writeQString(fid, "Port A");
    writeQString(fid, "A");
    fwrite(fid, int16([1 4 2]), 'int16');
    writeChannel(fid, "C-001", "Primary", 0, 0, 0);
    writeChannel(fid, "C-002", "Secondary", 1, 0, 1);
    writeChannel(fid, "ADC-001", "Monitor", 0, 3, 0);
    writeChannel(fid, "DIN-001", "Trigger", 1, 5, 0);

    for block = 1:nBlocks
        base = (block - 1) * samplesPerBlock;
        sampleIdx = 0:(samplesPerBlock - 1);
        fwrite(fid, int32(base + sampleIdx), 'int32');

        ampRaw = zeros(2, samplesPerBlock, 'uint16');
        ampRaw(1, :) = uint16(32768 + 100 + sampleIdx);
        ampRaw(2, :) = uint16(32768 + 200 + sampleIdx);
        fwrite(fid, ampRaw.', 'uint16');

        stimRaw = zeros(2, samplesPerBlock, 'uint16');
        if block == 1
            stimRaw(1, 1:3) = uint16([1, 2^8 + 2, 3]);
        end
        fwrite(fid, stimRaw.', 'uint16');

        adcRaw = uint16(32768 + sampleIdx);
        fwrite(fid, adcRaw.', 'uint16');

        digitalRaw = uint16(2 .* mod(sampleIdx, 2));
        fwrite(fid, digitalRaw, 'uint16');
    end
end

function writeChannel(fid, nativeName, customName, nativeOrder, signalType, chipChannel)
    writeQString(fid, nativeName);
    writeQString(fid, customName);
    fwrite(fid, int16(nativeOrder), 'int16');
    fwrite(fid, int16(nativeOrder), 'int16');
    fwrite(fid, int16(signalType), 'int16');
    fwrite(fid, int16(1), 'int16');
    fwrite(fid, int16(chipChannel), 'int16');
    fwrite(fid, int16(0), 'int16');
    fwrite(fid, int16(0), 'int16');
    fwrite(fid, int16([0 0 0 0]), 'int16');
    fwrite(fid, single([0 0]), 'single');
end

function writeQString(fid, value)
    value = char(string(value));
    fwrite(fid, uint32(numel(value) * 2), 'uint32');
    fwrite(fid, uint16(value), 'uint16');
end

function removeFolderIfPresent(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
