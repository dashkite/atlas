import semver from "semver"
import * as _ from "../../joy"
import {
  context
  dependencies
} from "./dependencies"
import { merge } from "./helpers"

# We start with defining different equivalence classes.

# 1. Resource equality: same version of the same module
eq = (a, b) -> a.name == b.name && a.version == b.version

# 2. Compatible versions...
compatible = (a, b) ->
  (a.name == b.name) &&
    (semver.validRange a.qualifier)? && (semver.validRange b.qualifier)? &&
      (semver.satisfies a.version, b.qualifier) &&
        (semver.satisfies b.version, a.qualifier)

# ... relative equality
req = (a, b) -> (eq a, b) || (compatible a, b)

# Next, we need some utilities for reasoning about lists of dependencies.
find = (dx, d) -> dx.find eq
found = (dx, d) -> (find dx, d)?

# Is there a compatible version of a dependency already in a list?
alternative = (dx, b) -> dx.find (a) -> req a, b

# Is there a conflicting version of dependency already in a list?
conflict = (dx, b) -> (dx.find (a) -> a.name == b.name && !(req a, b))?

# If there's not, we can potentially add it...
available = (dx, b) -> !conflict dx, b

# Select the latest version between two options...
promote = (a, b) -> if semver.gt a.version, b.version then a else b

# Replace a dependency within a list
replace = (a, b, dx) ->
  if a == b
    dx
  else
    for d in dx
      if d == a then b else d

# Attempt to place a dependency within a list,
# possibly replacing an alternative
place = (dx, d) ->
  if (_d = alternative dx, d)?
    replace _d, (promote _d, d), dx
  else
    [ dx..., d ]

# Obtain the name without the version or other qualifier
# ex: module-name instead of module-name@1.0.0
unqualify = (s) ->
  x = s.split "@"
  x[x.length - 2]

# some scopes end up empty, so lets' clear those out
compact = (sx) ->
  rx = {}
  rx[key] = value for key, value of sx when !_.empty value
  rx

# attempt place each dependency in the broadest scope
# TODO we could keep a count of how many times we see a module,
#      so we could prioritize which one gets the root
optimize = (sx) ->
  rx = {}
  root = []
  # for each qualified scope...
  for s, dx of sx
    # p is the unqualified (name) scope, q the qualified (name@version)
    p = [] ; q = []
    # for each dependency within that scope...
    for d in dx
      # if we haven't already placed the equivalent scope...
      if !((found root, d) || (found p, d))
        # can we place d in the root scope?
        if available root, d
          root = place root, d
        # can we place d in the unqualified scope? (name)
        else if available p, d
          p = place p, d
        # okay, place it in the dependent scope (name@version)
        else
          q = place q, d
    rx[s] = q
    rx[unqualify s] = p
  rx.root = root
  compact rx

# now we're ready for the big event....
scopes = (dx) ->

  # initialize the root scope with the direct dependencies
  rx =
    root:
      await Promise.all (
        context name, qualifier for name, qualifier of dx)

  # merge the (unoptimized) scopes for each dependency and optimize the result
  optimize merge [
    rx
    (await Promise.all (
      dependencies name, qualifier for name, qualifier of dx))...
  ]

export { scopes }
