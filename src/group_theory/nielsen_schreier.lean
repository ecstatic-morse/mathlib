/-
Copyright (c) 2021 David Wärn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: David Wärn
-/
import category_theory.action
import category_theory.is_connected
import combinatorics.quiver
import group_theory.free_group
import group_theory.semidirect_product
/-!
# The Nielsen-Schreier theorem

This file proves that a subgroup of a free group is itself free.

## Main definitions

- `is_free_group G`: a class expressing that `G` has the universal property of a free group.
- `subgroup_is_free H`: an instance saying that a subgroup of a free group is free.

## Proof overview

The proof is analogous to the proof using covering spaces and fundamental groups of graphs,
but we work directly with groupoids instead of topological spaces. Under this analogy,

- `is_free_groupoid G` corresponds to saying that a space is a graph.
- `End_mul_equiv_subgroup H` plays the role of replacing 'subgroup of fundamental group' with
  'fundamental group of covering space'.
- `action_category_is_free G A` corresponds to the fact that a covering of a (single-vertex)
  graph is a graph.
- `End_is_free_group_of_arborescence` corresponds to the fact that, given a spanning tree of a
  graph, its fundamental group is free (generated by loops from the complement of the tree).

## Implementation notes

This proof works with the universal property `is_free_group` instead of the concrete description
`free_group A` of free groups. The two are related by `free_group_is_free_group` and
`iso_free_group_of_is_free_group`.

Our definition of `is_free_groupoid` is nonstandard. Normally one would require that functors
`G ⥤ X` to any _groupoid_ `X` are given by graph homomorphisms from the generators, but we only
consider _groups_ `X`. This simplifies the argument since functor equality is complicated in
general, but simple for functors to single object categories.

## References

https://ncatlab.org/nlab/show/Nielsen-Schreier+theorem

## Tags

free group, Nielsen-Schreier

-/

noncomputable theory
open_locale classical
universes v u

open category_theory opposite category_theory.action_category semidirect_product

/-- `is_free_group G` means that `G` has the universal property of a free group.
    That is, it has a family `generators G` of elements, such that a group homomorphism
    `G →* X` is uniquely determined by a function `generators G → X`. -/
class is_free_group (G) [group.{u} G] :=
(generators : Type u)
(of : generators → G)
(unique_lift : ∀ {X} [group.{u} X] (f : generators → X),
                ∃! F : G →* X, ∀ a, F (of a) = f a)

instance free_group_is_free_group {A} : is_free_group (free_group A) :=
{ generators := A,
  of := free_group.of,
  unique_lift := by { introsI X _ f, exact ⟨free_group.lift f, λ _, free_group.lift.of,
      λ g hg, monoid_hom.ext (λ _, free_group.lift.unique g hg)⟩ } }

namespace is_free_group

lemma end_is_id {G} [group G] [is_free_group G] (f : G →* G)
  (h : ∀ a, f (of a) = of a) : ∀ g, f g = g :=
let ⟨_, _, u⟩ := unique_lift (f ∘ of) in
have claim : f = monoid_hom.id G := trans (u _ (λ _, rfl)) (u _ (by simp [h])).symm,
monoid_hom.ext_iff.mp claim

/-- An abstract free group is isomorphic to a concrete free group. -/
def iso_free_group_of_is_free_group (G) [group G] [is_free_group G] :
  G ≃* free_group (generators G) :=
let ⟨F, hF, uF⟩ := classical.indefinite_description _ (unique_lift free_group.of) in
{ to_fun := F,
  inv_fun := free_group.lift of,
  left_inv := end_is_id ((free_group.lift of).comp F) (by simp [hF]),
  right_inv := by { suffices : F.comp (free_group.lift of) = monoid_hom.id _,
    { rwa monoid_hom.ext_iff at this }, apply free_group.ext_hom, simp [hF] },
  map_mul' := F.map_mul }

/-- Being a free group transports across group isomorphisms. -/
def of_mul_equiv {G H : Type u} [group G] [group H] (h : G ≃* H) [is_free_group G] :
  is_free_group H :=
{ generators := generators G,
  of := h ∘ of,
  unique_lift := begin
    introsI X _ f,
    rcases unique_lift f with ⟨F, hF, uF⟩,
    refine ⟨F.comp h.symm.to_monoid_hom, by simp [hF], _⟩,
    intros F' hF',
    suffices : F'.comp h.to_monoid_hom = F,
    { rw ←this, ext, simp },
    apply uF,
    simp [hF'],
  end }

end is_free_group

/-- A groupoid `G` is free when we have the following data:
 - a quiver `generators` whose vertices are objects of `G`
 - a function `of` sending an arrow in `generators` to a morphism in `G`
 - such that a functor from `G` to any group `X` is uniquely determined
   by assigning labels in `X` to the arrows in `generators. -/
class is_free_groupoid (G) [groupoid.{v} G] :=
(generators : quiver.{v+1} G)
(of : Π ⦃a b⦄, generators.arrow a b → (a ⟶ b))
(unique_lift : ∀ {X} [group.{v} X] (f : generators.labelling X),
                ∃! F : G ⥤ single_obj X, ∀ a b (g : generators.arrow a b),
                  F.map (of g) = f g)

namespace is_free_groupoid

@[ext]
lemma ext_functor {G X} [groupoid.{v} G] [is_free_groupoid G] [group.{v} X]
  (f g : G ⥤ single_obj X)
  (h : ∀ a b (e : generators.arrow a b), f.map (of e) = g.map (of e)) :
  f = g :=
match unique_lift (show generators.labelling X, from λ a b e, g.map (of e)) with
| ⟨m, _, um⟩ := trans (um _ h) (um _ (λ _ _ _, rfl)).symm
end

namespace covering

instance {G A X : Type*} [monoid G] [mul_action G A] : mul_action Gᵒᵖ (A → X) :=
{ smul := λ g' F a, F (g'.unop • a),
  one_smul := by simp,
  mul_smul := by simp [mul_smul] }

@[simp] lemma arrow_action_apply {G A X : Type*} [monoid G] [mul_action G A]
  (g : Gᵒᵖ) (F : A → X) (a : A) : (g • F) a = F (g.unop • a) := rfl

/-- Given groups `G X` with `G` acting on `A`,
    `Gᵒᵖ` acts by multiplicative automorphisms on `A → X`. -/
def mul_aut_of_action (G A X) [group G] [mul_action G A] [has_mul X] :
  Gᵒᵖ →* mul_aut (A → X) :=
{ to_fun := λ g, {
    to_fun := λ F, g • F,
    inv_fun := λ F, g⁻¹ • F,
    left_inv := λ F, inv_smul_smul g F,
    right_inv := λ F, smul_inv_smul g F,
    map_mul' := by { intros, funext, simp only [arrow_action_apply, pi.mul_apply]} },
  map_one' := by { ext, simp only [mul_aut.one_apply, mul_equiv.coe_mk, one_smul]},
  map_mul' := by {intros, ext, simp only [mul_smul, mul_equiv.coe_mk, mul_aut.mul_apply] } }

@[simp] lemma mul_aut_of_action_apply {G A X : Type*} [group G] [mul_action G A] [has_mul X]
  (g : Gᵒᵖ) (F : A → X) (a : A) : mul_aut_of_action G A X g F a = F (g.unop • a) := rfl

/-- A group homomorphisms `G →* Hᵒᵖ` is the same as a group homomorphism `Gᵒᵖ →* H`. -/
def op_hom_of_hom_op {G H} [monoid G] [monoid H] (f : G →* Hᵒᵖ) : (Gᵒᵖ →* H) :=
{ to_fun := λ g', (f g'.unop).unop,
  map_one' := by simp only [unop_one, monoid_hom.map_one],
  map_mul' := by simp only [forall_const, unop_mul, monoid_hom.map_mul, eq_self_iff_true] }

/-- Given `G` acting on `A`, a functor from the corresponding action groupoid to a group `X`
    can be curried to a group homomorphism `G →* G ⋉ (A → X)`.
    (We simulate `⋉` using `⋊` and lots of `ᵒᵖ`s.) -/
def curry {G A X} [group G] [mul_action G A] [group X]
  (F : action_category G A ⥤ single_obj X) :
  G →* ((A → Xᵒᵖ) ⋊[mul_aut_of_action G A Xᵒᵖ] Gᵒᵖ)ᵒᵖ :=
have F_map_eq : ∀ {a b} {f : a ⟶ b}, F.map f = (F.map (hom_of_pair a.back f.val) : X) :=
  action_category.cases (λ _ _, rfl),
{ to_fun := λ g, op ⟨λ a, op (F.map (hom_of_pair a g)), op g⟩,
  map_one' := begin
    rw [op_eq_iff_eq_unop, unop_one],
    congr, funext,
    rw [pi.one_apply, op_eq_iff_eq_unop, unop_one],
    exact F_map_eq.symm.trans (F.map_id a),
  end,
  map_mul' := begin
    intros g h,
    rw [op_eq_iff_eq_unop, ←op_mul, unop_op],
    congr, funext,
    rw [op_eq_iff_eq_unop, pi.mul_apply, unop_mul, unop_op],
    exact F_map_eq.symm.trans (F.map_comp (hom_of_pair a h) (hom_of_pair (h • a) g)),
  end }

/-- Given `G` acting on `A`, a group homomorphism `φ : G →* G ⋉ (A → X)` can be uncurried to
    a functor from the action groupoid to `X`, provided that `φ g = (g, _)` for all `g`.
    (We simulate `⋉` using `⋊` and lots of `ᵒᵖ`s.) -/
def uncurry {G A X} [group G] [mul_action G A] [group X]
  (F : G →* ((A → Xᵒᵖ) ⋊[mul_aut_of_action G A Xᵒᵖ] Gᵒᵖ)ᵒᵖ)
  (sane : ∀ g, (F g).unop.right.unop = g) :
  action_category G A ⥤ single_obj X :=
{ obj := λ _, (),
  map := λ a b f, ((F f.val).unop.left a.back).unop,
  map_id' := by { intro x, rw [action_category.id_val, F.map_one], refl },
  map_comp' := by {
    intros x y z f, revert x y f,
    refine action_category.cases _, intros x g f,
    rw [action_category.comp_val, F.map_mul, unop_mul,
        mul_left, pi.mul_apply, mul_aut_of_action_apply, sane],
    refl } }

open is_free_group as fgp

instance action_category_is_free {G A : Type u} [group G] [is_free_group G] [mul_action G A] :
  is_free_groupoid (action_category G A) :=
{ generators := ⟨λ a b, { e : fgp.generators G // fgp.of e • a.back = b.back }⟩,
  of := λ a b e, ⟨fgp.of e, e.property⟩,
  unique_lift := begin
    introsI X _ f,
    let X' := ((A → Xᵒᵖ) ⋊[mul_aut_of_action G A Xᵒᵖ] Gᵒᵖ)ᵒᵖ,
    let f' : fgp.generators G → X' := λ e, op ⟨λ a, op (@f a (_ : A) ⟨e, rfl⟩), op (fgp.of e)⟩,
    rcases fgp.unique_lift f' with ⟨F', hF', uF'⟩,
    let F : action_category G A ⥤ single_obj X := uncurry F' _,
    refine ⟨F, _, _⟩,
    { rintros ⟨⟨⟩, a : A⟩ ⟨⟨⟩, b⟩ ⟨e, h : fgp.of e • a = b⟩,
      change ((F' (fgp.of _)).unop.left _).unop = _,
      rw hF', cases h, refl },
    { intros E hE,
      let E' := curry E,
      have : E' = F',
      { apply uF',
        intro e,
        refine unop_injective (semidirect_product.ext _ _ _ rfl),
        funext,
        change op (E.map _) = op (f _),
        rw [op_eq_iff_eq_unop, unop_op],
        exact hE _ _ ⟨e, _⟩ },
      apply functor.hext,
      { intro, apply unit.ext },
      { refine action_category.cases _, intros,
        change _ == ((F' _).unop.left _).unop,
        rw ←this, refl } },
    { apply fgp.end_is_id ((op_hom_of_hom_op (right_hom : _ →* Gᵒᵖ)).comp F'),
      intro, rw [monoid_hom.comp_apply, hF'], refl }
  end }

end covering

section retract
open quiver

variables {G : Type u} [groupoid.{u} G] [is_free_groupoid G]
  (T : wide_subquiver (generators.symmetrify : quiver G))

-- an abbreviation for taking the quiver corresponding to a subquiver
local notation T `♯` :10000 := T.quiver

variable [arborescence T♯]

/-- A path in the tree gives a hom, by composition. -/
noncomputable def hom_of_path : Π {a : G}, T♯.path T♯.root a → (T♯.root ⟶ a)
| _ path.nil := 𝟙 _
| a (path.cons p ⟨sum.inl e, h⟩) := hom_of_path p ≫ of e
| a (path.cons p ⟨sum.inr e, h⟩) := hom_of_path p ≫ inv (of e)

/-- For every vertex `a`, there is a canonical hom from the root, given by the
    path in the tree. -/
def tree_hom (a : G) : T♯.root ⟶ a := hom_of_path T (default _)

lemma tree_hom_eq {a : G} (p q : T♯.path T♯.root a) : hom_of_path T p = hom_of_path T q :=
by congr

@[simp] lemma tree_hom_root : tree_hom T T♯.root = 𝟙 _ :=
trans (tree_hom_eq T _ path.nil) rfl -- ???

/-- Any hom in `G` can be made into a loop, by conjugating with `tree_hom`s. -/
@[simp] def loop_of_hom {a b : G} (p : a ⟶ b) : End T♯.root :=
tree_hom T a ≫ p ≫ inv (tree_hom T b)

lemma loop_of_hom_eq_id {a b : G} {e : generators.arrow a b} :
  (sum.inl e) ∈ T a b ∨ (sum.inr e) ∈ T b a
    → loop_of_hom T (of e) = 𝟙 _ :=
begin
  rw [loop_of_hom, ←category.assoc, is_iso.comp_inv_eq, category.id_comp, tree_hom, tree_hom],
  rintro (h | h),
  { refine eq.trans _ (tree_hom_eq T (path.cons (default _) ⟨sum.inl e, h⟩) _),
    rw hom_of_path },
  { rw tree_hom_eq T (default _) (path.cons (default _) ⟨sum.inr e, h⟩),
    simp only [hom_of_path, is_iso.inv_hom_id, category.comp_id, category.assoc] }
end

/-- Since a hom gives a loop, a homomorphism from the vertex group at the root
    extends to a functor on the whole groupoid. -/
def functor_of_monoid_hom {X} [monoid X] (f : End T♯.root →* X) :
  G ⥤ single_obj X :=
{ obj := λ _, (),
  map := λ a b p, f (loop_of_hom T p),
  map_id' := begin intro a, convert f.map_one, simp end,
  map_comp' := by { intros, rw [single_obj.comp_as_mul, ←f.map_mul],
    simp only [is_iso.inv_hom_id_assoc, loop_of_hom, End.mul_def, category.assoc] } }

@[simp] lemma functor_of_monoid_hom.apply {X} [monoid X] (f : End T♯.root →* X)
  {a b : G} (p : a ⟶ b) : (functor_of_monoid_hom T f).map p = f (loop_of_hom T p) := rfl

/-- Given a free groupoid and an arborescence of its generating quiver, the vertex
    group at the root is freely generated by loops coming from generating arrows
    in the complement of the tree. -/
def End_is_free_group_of_arborescence : is_free_group (End T♯.root) :=
{ generators := set.compl (wide_subquiver_equiv_set_total $ wide_subquiver_symmetrify T),
  of := λ e, loop_of_hom T (of e.val.arrow),
  unique_lift := begin
    introsI X _ f,
    let f' : Π ⦃a b : G⦄, generators.arrow a b → X := λ a b e,
      if h : sum.inl e ∈ T a b ∨ sum.inr e ∈ T b a then 1
      else f ⟨⟨a, b, e⟩, h⟩,
    rcases unique_lift f' with ⟨F', hF', uF'⟩,
    let F : End T♯.root →* X := F'.map_End _,
    have sane : ∀ {a b} (p : a ⟶ b), (functor_of_monoid_hom T F).map p = F'.map p,
    { intros a b p,
      change F'.map _ = _,
      suffices : ∀ {a} (p : T♯.path T♯.root a), F'.map (hom_of_path T p) = 1,
      { simp [this, tree_hom, single_obj.comp_as_mul, single_obj.inv_as_inv] },
      intros a p, induction p with b c p e ih,
      { apply F'.map_id },
      rcases e with ⟨e | e, eT⟩,
      { have : f' e = 1 := dif_pos (or.inl eT),
        simp only [hom_of_path, ih, hF', this, single_obj.comp_as_mul, mul_one, F'.map_comp] },
      { have : f' e = 1 := dif_pos (or.inr eT),
        simp [hom_of_path, ih, hF', this, single_obj.comp_as_mul, single_obj.inv_as_inv] } },
    refine ⟨F, _, _⟩,
    { intro e,
      convert sane _,
      rw hF',
      change _ = dite _ _ _,
      convert (dif_neg e.property).symm,
      apply congr_arg, ext; refl },
    { intros E hE,
      have : functor_of_monoid_hom T E = F',
      { apply uF',
        intros a b e,
        change E (loop_of_hom T _) = dite _ _ _,
        split_ifs,
        { rw loop_of_hom_eq_id T h, apply E.map_one },
        exact hE ⟨⟨a, b, e⟩, h⟩ },
      ext,
      have : (functor_of_monoid_hom T E).map x = (functor_of_monoid_hom T F).map x,
      { rw [this, sane] },
      simpa using this }
  end }

end retract

open is_free_groupoid quotient_group

/-- `G` acts pretransitively on `X` if for any `x y` there is `g` such that `g • x = y`.
  A transitive action should furthermore have `X` nonempty. -/
class is_pretransitive (G X) [monoid G] [mul_action G X] : Prop :=
(exists_smul_eq : ∀ x y : X, ∃ g : G, g • x = y)

lemma exists_smul_eq (M) {X} [monoid M] [mul_action M X] [is_pretransitive M X] (x y : X) :
  ∃ m : M, m • x = y := is_pretransitive.exists_smul_eq x y

instance is_pretransitive_quotient (G) [group G] (H : subgroup G) :
  is_pretransitive G (quotient H) :=
{ exists_smul_eq := by { rintros ⟨x⟩ ⟨y⟩, refine ⟨y * x⁻¹, quotient_group.eq.mpr _⟩,
    simp only [mul_left_inv, inv_mul_cancel_right, H.one_mem] } }

instance (G X) [monoid G] [mul_action G X] [is_pretransitive G X] [nonempty X] :
  is_connected (action_category G X) :=
zigzag_is_connected $ λ x y, relation.refl_trans_gen.single $ or.inl $
  nonempty_subtype.mpr (show _, from exists_smul_eq G x.back y.back)

instance (G) [groupoid G] [is_connected G] (x y : G) : nonempty (x ⟶ y) :=
begin
  have h := is_connected_zigzag x y,
  induction h with z w _ h ih,
  { exact ⟨𝟙 x⟩ },
  { refine nonempty.map (λ f, f ≫ classical.choice _) ih,
    cases h,
    { assumption },
    { apply nonempty.map (λ f, inv f) h } }
end

/-- Given a function `f : C → G` from a category to a group, we get a functor
    `C ⥤ G` sending any morphism `x ⟶ y` to `f y * (f x)⁻¹`. -/
def difference_functor {C G} [category C] [group G] (f : C → G) : C ⥤ single_obj G :=
{ obj := λ _, (),
  map := λ x y _, f y * (f x)⁻¹,
  map_id' := by { intro, rw [single_obj.id_as_one, mul_right_inv] },
  map_comp' := by { intros, rw single_obj.comp_as_mul, group } }

@[simp]
lemma difference_functor_map {C G} [category C] [group G] (f : C → G) (x y : C) (p : x ⟶ y) :
  (difference_functor f).map p = f y * (f x)⁻¹ := rfl

instance generators_connected (G) [groupoid.{u u} G] [is_connected G] [is_free_groupoid G] (r : G) :
  (generators : quiver G).symmetrify.rooted_connected r :=
begin
  let X := free_group (generators : quiver G).weakly_connected_component,
  set f : G → X := λ g, free_group.of ↑g with hf,
  set F : G ⥤ single_obj X := difference_functor f with hF,
  have claim : F = (category_theory.functor.const G).obj (),
  { ext,
    rw [functor.const.obj_map, single_obj.id_as_one, hF,
      difference_functor_map, mul_inv_eq_one, hf],
    apply congr_arg free_group.of,
    rw quiver.weakly_connected_component.eq,
    exact ⟨quiver.arrow.to_path (sum.inr e)⟩ },
  refine ⟨λ b, _⟩,
  rw ←quiver.weakly_connected_component.eq,
  apply free_group.of_injective,
  rw ←mul_inv_eq_one,
  rcases (infer_instance : nonempty (b ⟶ r)) with ⟨p⟩,
  change F.map p = _,
  rw [claim, functor.const.obj_map, single_obj.id_as_one],
end

lemma stabilizer_quotient {G} [group G] (H : subgroup G) :
  mul_action.stabilizer G ((1 : G) : quotient H) = H :=
by { ext, change _ = _ ↔ _, rw eq_comm, convert quotient_group.eq, simp }

/-- Any subgroup of `G` is a vertex group in its action groupoid. -/
def End_mul_equiv_subgroup {G} [group G] (H : subgroup G) :
  End (obj_equiv G (quotient H) (1 : G)) ≃* H :=
mul_equiv.trans
  (stabilizer_iso_End G ((1 : G) : quotient H)).symm
  (mul_equiv.subgroup_congr $ stabilizer_quotient H)

instance {G} [groupoid G] [is_free_groupoid G] [is_connected G] (r : G) : is_free_group (End r) :=
End_is_free_group_of_arborescence (quiver.geodesic_subtree _ r)

instance subgroup_is_free {G} [group.{u} G] [is_free_group G] (H : subgroup G) : is_free_group H :=
is_free_group.of_mul_equiv (End_mul_equiv_subgroup H)

end is_free_groupoid
