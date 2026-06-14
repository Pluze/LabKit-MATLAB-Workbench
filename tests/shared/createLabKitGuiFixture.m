function fixture = createLabKitGuiFixture(testCase)
%CREATELABKITGUIFIXTURE Return helpers for noninteractive GUI tests.
%
% Expected caller: matlab.uitest or matlab.unittest GUI tests. The optional
% testCase input receives figure cleanup teardowns. Full interactive workflow
% validation remains manual.

    if nargin < 1
        testCase = [];
    end

    fixture = struct();
    fixture.assertUifigureAvailable = @assertUifigureAvailable;
    fixture.closeFigure = @closeFigure;
    fixture.addFigureTeardown = @addFigureTeardown;
end

function assertUifigureAvailable()
    try
        fig = uifigure("Visible", "off");
        cleanup = onCleanup(@() closeFigure(fig));
        drawnow;
    catch ME
        error("LabKit:GUI:Unavailable", ...
            "MATLAB uifigure support is unavailable: %s", ME.message);
    end
end

function addFigureTeardown(fig)
    if isempty(testCase)
        return;
    end
    testCase.addTeardown(@() closeFigure(fig));
end

function closeFigure(fig)
    if ~isempty(fig) && isvalid(fig)
        close(fig);
        drawnow;
    end
end
