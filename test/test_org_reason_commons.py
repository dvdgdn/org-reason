"""Behavioral contracts against the pinned, real Reason Commons validator."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

PACKAGE = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("org_reason_commons", PACKAGE / "org_reason_commons.py")
commons = importlib.util.module_from_spec(spec)
spec.loader.exec_module(commons)


class CommonsContracts(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.file = Path(self.temporary.name) / "reason-commons.yaml"
        commons.execute(self.file, {"op": "new", "project": "Synthetic test system", "participant": "tester", "name": "Test participant"})

    def inspect(self):
        return commons.execute(self.file, {"op": "inspect"})

    def change(self, op, **fields):
        return commons.execute(self.file, {"op": op, "by": "tester", "expected_sha256": self.inspect()["sha256"], **fields})

    def node(self, text="A condition holds.", kind="necessary_condition", tree="goal", **fields):
        return self.change("add-node", text=text, kind=kind, tree=tree, **fields)["id"]

    def test_create_is_exclusive(self):
        old = self.file.read_bytes()
        with self.assertRaises(FileExistsError):
            commons.execute(self.file, {"op": "new", "project": "Overwrite", "participant": "tester", "name": "Tester"})
        self.assertEqual(old, self.file.read_bytes())

    # @RC01
    def test_capture_is_proposed_with_attribution(self):
        ident = self.node()
        item = self.inspect()["state"]["trees"]["goal"]["nodes"][0]
        self.assertEqual(item["id"], ident)
        self.assertEqual(item["status"], "proposed")
        self.assertEqual(item["contributions"], [{"by": "tester", "attribution": "explicit", "mode": "text"}])
        self.assertNotIn("accepted_by", item)

    # @RC01
    def test_all_six_tree_families_use_native_kinds(self):
        kinds = {"goal": "goal", "current_reality": "undesirable_effect", "conflict": "need",
                 "future_reality": "injection", "prerequisite": "obstacle", "transition": "action"}
        for tree, kind in kinds.items():
            self.node(tree=tree, kind=kind)
        commons.upstream.validate(self.inspect()["state"])

    # @RC02
    def test_and_link_is_one_relationship_with_multiple_sources(self):
        a, b, target = self.node(), self.node(), self.node(kind="goal")
        self.change("add-link", tree="goal", **{"from": [a, b], "to": target, "relation": "necessary_for"})
        links = self.inspect()["state"]["trees"]["goal"]["links"]
        self.assertEqual(len(links), 1)
        self.assertEqual(links[0]["from"], [a, b])
        self.assertEqual(links[0]["status"], "proposed")

    def test_invalid_endpoint_does_not_write(self):
        a = self.node()
        old = self.file.read_bytes()
        with self.assertRaises(ValueError):
            self.change("add-link", tree="goal", **{"from": [a], "to": "missing", "relation": "necessary_for"})
        self.assertEqual(old, self.file.read_bytes())

    # @RC09
    def test_assistant_contribution_is_not_human_acceptance(self):
        ident = self.node(by="assistant")
        old = self.file.read_bytes()
        with self.assertRaises(ValueError):
            self.change("accept", id=ident, by="assistant")
        self.assertEqual(old, self.file.read_bytes())

    # @RC03
    def test_endpoints_must_be_accepted_before_link(self):
        a, b = self.node(), self.node(kind="goal")
        link = self.change("add-link", tree="goal", **{"from": [a], "to": b, "relation": "necessary_for"})["id"]
        with self.assertRaises(ValueError):
            self.change("accept", id=link)
        for ident in (a, b, link):
            self.change("accept", id=ident)
        self.assertEqual(commons.find_item(self.inspect()["state"], link)[2]["status"], "accepted")

    # @RC04
    def test_challenging_node_demotes_incident_links_and_retains_history(self):
        a, b = self.node(), self.node(kind="goal")
        link = self.change("add-link", tree="goal", **{"from": [a], "to": b, "relation": "necessary_for"})["id"]
        for ident in (a, b, link):
            self.change("accept", id=ident)
        result = self.change("challenge", id=a, text="A counterexample was reported.")
        state = self.inspect()["state"]
        self.assertEqual(commons.find_item(state, a)[2]["status"], "disputed")
        self.assertEqual(commons.find_item(state, link)[2]["status"], "proposed")
        self.assertEqual(len(list((self.file.parent / ".reason-commons/history").glob("*.yaml"))), 4)
        with self.assertRaises(ValueError):
            self.change("accept", id=a)

    # @RC05
    def test_backlog_is_independent_of_acceptance(self):
        ident = self.node()
        self.change("accept", id=ident)
        self.change("backlog", id=ident, work="test_causality")
        self.assertEqual(commons.find_item(self.inspect()["state"], ident)[2]["status"], "accepted")
        self.assertEqual(len(list((self.file.parent / ".reason-commons/history").glob("*.yaml"))), 1)

    def test_proposals_do_not_generate_accepted_snapshots(self):
        self.node()
        self.assertFalse(list((self.file.parent / ".reason-commons/history").glob("*.yaml")))
        self.assertTrue(list((self.file.parent / ".org-reason/history").glob("*.yaml")))

    # @RC06
    def test_stale_digest_refuses_without_lost_update(self):
        prior = self.inspect()["sha256"]
        self.node()
        old = self.file.read_bytes()
        with self.assertRaises(ValueError):
            commons.execute(self.file, {"op": "add-node", "by": "tester", "expected_sha256": prior,
                                  "kind": "goal", "text": "Stale change"})
        self.assertEqual(old, self.file.read_bytes())

    # @RC06
    def test_uncooperative_external_edit_is_detected_before_replace(self):
        prior = commons.digest(self.file.read_bytes())
        self.file.write_text(self.file.read_text() + "# outside edit\n")
        with self.assertRaises(ValueError):
            commons.replace_checked(self.file, b"destroy", prior)
        self.assertTrue(self.file.read_text().endswith("# outside edit\n"))

    # @RC12
    def test_lock_releases_when_writer_is_killed(self):
        program = """
from pathlib import Path
import sys
import time
from org_reason_commons import lock
with lock(Path(sys.argv[1])):
    print("locked", flush=True)
    time.sleep(30)
"""
        with subprocess.Popen([sys.executable, "-c", program, str(self.file)],
                              cwd=PACKAGE, stdout=subprocess.PIPE, text=True) as writer:
            try:
                self.assertEqual(writer.stdout.readline().strip(), "locked")
                with self.assertRaisesRegex(ValueError, "Another process"):
                    self.node()
            finally:
                writer.kill()
                writer.wait(timeout=10)
        self.assertTrue(self.node())

    # @RC13
    def test_inspect_reports_kinds_and_suggests_open_relation_vocabulary(self):
        inspection = self.inspect()
        self.assertEqual(set(inspection["tree_kinds"]), set(commons.upstream.KINDS))
        for tree, kinds in inspection["tree_kinds"].items():
            self.assertEqual(set(kinds), commons.upstream.KINDS[tree] | {"observation"})
        self.assertIn("causes", inspection["relation_suggestions"])
        source, target = self.node(), self.node()
        self.assertTrue(self.change("add-link", **{"from": [source], "to": target,
                                                   "relation": "requires_a_prior_check"})["saved"])

    # @RC07
    def test_unfamiliar_schema_and_duplicate_yaml_keys_are_rejected(self):
        self.file.write_text("schema_version: 99\n")
        with self.assertRaises(ValueError):
            self.inspect()
        self.file.write_text("schema_version: 1\nschema_version: 1\n")
        with self.assertRaises(Exception):
            self.inspect()

    # @RC08
    def test_unknown_optional_data_survives_reserialization(self):
        state = self.inspect()["state"]
        state["community_metadata"] = {"languages": ["en", "de", "zh"], "nested": {"value": 17}}
        self.file.write_text(commons.yaml.safe_dump(state, sort_keys=False))
        self.node()
        self.assertEqual(self.inspect()["state"]["community_metadata"], state["community_metadata"])

    # @RC11
    def test_rendering_failure_reports_saved_state(self):
        with patch.object(commons.upstream, "update", side_effect=OSError("synthetic renderer failure")):
            result = self.change("add-node", kind="goal", text="Keep the valid save.")
        self.assertTrue(result["saved"])
        self.assertIn("view_error", result)
        self.assertEqual(len(self.inspect()["state"]["trees"]["goal"]["nodes"]), 1)

    def test_cli_json_round_trip_with_unicode(self):
        request = {"op": "add-node", "by": "tester", "kind": "goal", "text": "Deutsch üben — 学习",
                   "expected_sha256": self.inspect()["sha256"]}
        result = subprocess.run([sys.executable, str(PACKAGE / "org_reason_commons.py"), "--file", str(self.file)],
                                input=json.dumps(request), text=True, capture_output=True, check=True)
        self.assertTrue(json.loads(result.stdout)["saved"])
        self.assertEqual(self.inspect()["state"]["trees"]["goal"]["nodes"][0]["text"], request["text"])


if __name__ == "__main__":
    unittest.main()
