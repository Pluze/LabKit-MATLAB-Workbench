%REQUIREMENTS App dependency contract for labkit_GaitAnalysis_app.
% Expected caller: the public app entrypoint and launcher discovery.
function requirements = requirements()
    requirements = labkit.contract.requirements( ...
        "ui", ">=7 <8");
end
