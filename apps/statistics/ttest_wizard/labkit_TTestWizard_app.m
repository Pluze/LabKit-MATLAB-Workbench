function varargout = labkit_TTestWizard_app(varargin)
%LABKIT_TTESTWIZARD_APP Launch the T-Test Wizard.
%
% Usage:
%   labkit_TTestWizard_app
%   fig = labkit_TTestWizard_app
%   info = labkit_TTestWizard_app("version")
%   requirements = labkit_TTestWizard_app("requirements")
%
% Description:
%   Opens tabular CSV or workbook sources, captures two or more visible numeric
%   groups, compares every later group with the first using explicit Welch,
%   equal-variance, or paired t-tests, and draws a grouped mean/SD plot.
%
% Inputs:
%   varargin - Launch requests accepted by labkit.app.Definition.launch.
%
% Outputs:
%   varargout - Optional figure, version metadata, or requirements returned by
%       the LabKit runtime.
%
% Typical Call:
%   labkit_TTestWizard_app
%
% See also labkit.app.Definition

    [varargout{1:nargout}] = ...
        ttest_wizard.definition().launch(varargin{:});
end
