import assert from "node:assert/strict";
import path from "node:path";
import test from "node:test";
import {
  LEAST_USED_SKILLS_LIMIT,
  TOP_SKILLS_LIMIT,
  getSessionRoot,
} from "./constants.js";
import { given_tempHome } from "./test-helpers.js";

test("getSessionRoot GIVEN a temp home WHEN resolving THEN it uses ~/.pi/agent/sessions and keeps the skill table limits stable", (t) => {
  const tempHome = given_tempHome(t);

  const actual = getSessionRoot();
  const expected = path.join(tempHome, ".pi", "agent", "sessions");

  assert.equal(actual, expected);
  assert.equal(TOP_SKILLS_LIMIT, 10);
  assert.equal(LEAST_USED_SKILLS_LIMIT, 20);
});
