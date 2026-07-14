# Testing

This document describes the testing approach for Atlas.

## General Approach

The testing methodology focuses on verifying the correctness of the import map compaction algorithms and scope resolution to prevent shadowing conflicts. The suite leverages `@dashkite/amen` to structure assertions and `@dashkite/assert` to validate map structures. The test suite primarily tests `groupByMapping`, `groupBySpecifier`, `Map.optimize`, and `resolve` functionality using synthetic dependency structures to ensure safe greedy lifting and verifiable promotion.

## Running Tests

To run the test suite, invoke the following command:

```bash
npx genie test
```
