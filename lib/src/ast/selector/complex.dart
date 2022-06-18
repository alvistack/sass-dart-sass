// Copyright 2016 Google Inc. Use of this source code is governed by an
// MIT-style license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:meta/meta.dart';

import '../../extend/functions.dart';
import '../../utils.dart';
import '../../visitor/interface/selector.dart';
import '../selector.dart';

/// A complex selector.
///
/// A complex selector is composed of [CompoundSelector]s separated by
/// [Combinator]s. It selects elements based on their parent selectors.
class ComplexSelector extends Selector {
  /// This selector's leading combinators.
  ///
  /// If this is empty, that indicates that it has no leading combinator. If
  /// it's more than one element, that means it's invalid CSS; however, we still
  /// support this for backwards-compatibility purposes.
  final List<Combinator> leadingCombinators;

  /// The components of this selector.
  ///
  /// This is never empty.
  ///
  /// Descendant combinators aren't explicitly represented here. If two
  /// [CompoundSelector]s are adjacent to one another, there's an implicit
  /// descendant combinator between them.
  ///
  /// It's possible for multiple [Combinator]s to be adjacent to one another.
  /// This isn't valid CSS, but Sass supports it for CSS hack purposes.
  final List<ComplexSelectorComponent> components;

  /// Whether a line break should be emitted *before* this selector.
  final bool lineBreak;

  /// The minimum possible specificity that this selector can have.
  ///
  /// Pseudo selectors that contain selectors, like `:not()` and `:matches()`,
  /// can have a range of possible specificities.
  int get minSpecificity {
    if (_minSpecificity == null) _computeSpecificity();
    return _minSpecificity!;
  }

  int? _minSpecificity;

  /// The maximum possible specificity that this selector can have.
  ///
  /// Pseudo selectors that contain selectors, like `:not()` and `:matches()`,
  /// can have a range of possible specificities.
  int get maxSpecificity {
    if (_maxSpecificity == null) _computeSpecificity();
    return _maxSpecificity!;
  }

  int? _maxSpecificity;

  /// If this compound selector is composed of a single compound selector with
  /// no combinators, returns it.
  ///
  /// Otherwise, returns null.
  @internal
  CompoundSelector? get singleCompound => leadingCombinators.isEmpty &&
          components.length == 1 &&
          components.first.combinators.isEmpty
      ? components.first.selector
      : null;

  late final bool isInvisible =
      components.any((component) => component.selector.isInvisible) ||
          isBogusOtherThanLeadingCombinator;

  late final bool isBogus = leadingCombinators.isNotEmpty ||
      components.last.combinators.isNotEmpty ||
      components.any((component) =>
          component.combinators.length > 1 || component.selector.isBogus);

  /// Whether this selector is bogus other than having a leading combinator.
  @internal
  late final bool isBogusOtherThanLeadingCombinator =
      leadingCombinators.length == 1
          ? ComplexSelector(const [], components).isBogus
          : isBogus;

  /// Whether this selector has more than one combinator in a row.
  ///
  /// This doesn't count selector pseudos' selectors.
  @internal
  bool get hasDoubleCombinators =>
      leadingCombinators.length > 1 ||
      components.any((component) => component.combinators.length > 1);

  ComplexSelector(Iterable<Combinator> leadingCombinators,
      Iterable<ComplexSelectorComponent> components,
      {this.lineBreak = false})
      : leadingCombinators = List.unmodifiable(leadingCombinators),
        components = List.unmodifiable(components) {
    if (this.components.isEmpty) {
      throw ArgumentError("components may not be empty.");
    }
  }

  T accept<T>(SelectorVisitor<T> visitor) => visitor.visitComplexSelector(this);

  /// Whether this is a superselector of [other].
  ///
  /// That is, whether this matches every element that [other] matches, as well
  /// as possibly matching more.
  bool isSuperselector(ComplexSelector other) =>
      leadingCombinators.isEmpty &&
      other.leadingCombinators.isEmpty &&
      complexIsSuperselector(components, other.components);

  /// Computes [_minSpecificity] and [_maxSpecificity].
  void _computeSpecificity() {
    var minSpecificity = 0;
    var maxSpecificity = 0;
    for (var component in components) {
      minSpecificity += component.selector.minSpecificity;
      maxSpecificity += component.selector.maxSpecificity;
    }
    _minSpecificity = minSpecificity;
    _maxSpecificity = maxSpecificity;
  }

  /// Returns a copy of `this` with [combinators] added to the end of the final
  /// component in [components].
  @internal
  ComplexSelector withAdditionalCombinators(List<Combinator> combinators) =>
      combinators.isEmpty
          ? this
          : ComplexSelector(
              leadingCombinators,
              [
                ...components.exceptLast,
                components.last.withAdditionalCombinators(combinators)
              ],
              lineBreak: lineBreak);

  /// Returns a copy of `this` with an additional [component] added to the end.
  @internal
  ComplexSelector withAdditionalComponent(ComplexSelectorComponent component) =>
      ComplexSelector(leadingCombinators, [...components, component],
          lineBreak: lineBreak);

  /// Returns a copy of `this` with [child]'s combinators added to the end.
  ///
  /// If [child] has [leadingCombinators], they're appended to `this`'s last
  /// combinator. This does _not_ resolve parent selectors.
  @internal
  ComplexSelector concatenate(ComplexSelector child) => ComplexSelector(
      leadingCombinators,
      [
        ...withAdditionalCombinators(child.leadingCombinators).components,
        ...child.components
      ],
      lineBreak: lineBreak || child.lineBreak);

  int get hashCode => listHash(components);

  bool operator ==(Object other) =>
      other is ComplexSelector && listEquals(components, other.components);
}
