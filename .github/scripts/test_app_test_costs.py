import importlib.util
from pathlib import Path
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location("app_test_costs", Path(__file__).with_name("app_test_costs.py"))
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class AppTestCosts(unittest.TestCase):
    def test_merges_partition_reports_and_uses_median_for_repeated_observations(self):
        with tempfile.TemporaryDirectory() as folder:
            first = Path(folder) / "first.xml"
            second = Path(folder) / "second.xml"
            first.write_text('<testsuite><testcase classname="B" name="one" time="4"/>'
                             '<testcase classname="A" name="two" time="8"/></testsuite>')
            second.write_text('<testsuite><testcase classname="B" name="one" time="2"/></testsuite>')
            self.assertEqual(MODULE.collect_costs([first, second]), [
                {"id": "A/two", "seconds": 8}, {"id": "B/one", "seconds": 3}])

    def test_rejects_incomplete_or_invalid_cost_evidence(self):
        with tempfile.TemporaryDirectory() as folder:
            report = Path(folder) / "report.xml"
            for body in ('', '<testcase classname="A" name="one" time="-1"/>',
                         '<testcase classname="A" name="one" time="nan"/>',
                         '<testcase classname="A" name="one" time="1"><skipped/></testcase>',
                         '<testcase classname="A" name="one" time="1"><failure/></testcase>'):
                with self.subTest(body=body):
                    report.write_text('<testsuite>' + body + '</testsuite>')
                    with self.assertRaises(ValueError):
                        MODULE.collect_costs([report])
