# CI scope and repair

Read for CI workflow changes, hosted feedback inspection, or failed CI identities.

For hosted task-branch feedback, pass the complete push range's explicit changed
paths to the existing changed planner. Never infer a multi-commit push from a
clean checkout's `HEAD^..HEAD`, and never report the single-platform feedback
job as merge safety or as a replacement for local pre-PR and the required PR gate.
For pushes containing only agent guidance and metadata, lightweight Python
validation owns feedback. Let a newer push cancel superseded feedback, and inspect hosted feedback only
on user request, when checkpoint evidence needs it, or when a reported failure
blocks the current task. When an open PR from that task branch to `main` owns
validation of the merge result, let push-triggered feedback stop before MATLAB setup; use manual
dispatch only when independent focused evidence is explicitly needed. Do not
continuously poll non-gating development runs.

Copy the full test ID from the CI failure summary into `labkittest.run(Id=IDENTITY)`,
including its parameter suffix. Repair the cause, rerun that identity,
and let CI rerun the scope selected for the complete PR diff. Do not repeat broad local gates for each
repair or invent a third CI scope.
