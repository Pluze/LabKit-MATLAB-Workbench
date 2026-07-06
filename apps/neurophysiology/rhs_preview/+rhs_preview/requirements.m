% App-local LabKit facade requirement declaration.
% Expected caller: public app entrypoint and contract tests. Side effects: none.

function req = requirements()

    req = labkit.contract.requirements( ...
        "ui", ">=5 <6", ...
        "rhs", ">=1.0 <2");
end
