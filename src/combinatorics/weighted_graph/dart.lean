/-
Copyright (c) 2021 Yaël Dillies. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yaël Dillies
-/
import combinatorics.weighted_graph.basic
import algebra.big_operators.basic
import data.zmod.parity

/-!
# Degree-sum formula and handshaking lemma

The degree-sum formula is that the sum of the degrees of the vertices in
a finite graph is equal to twice the number of edges.  The handshaking lemma,
a corollary, is that the number of odd-degree vertices is even.

## Main definitions

- A `dart` is a directed edge, consisting of an ordered pair of adjacent vertices,
  thought of as being a directed edge.
- `weighted_graph.sum_degrees_eq_twice_card_edges` is the degree-sum formula.
- `weighted_graph.even_card_odd_degree_vertices` is the handshaking lemma.
- `weighted_graph.odd_card_odd_degree_vertices_ne` is that the number of odd-degree
  vertices different from a given odd-degree vertex is odd.
- `weighted_graph.exists_ne_odd_degree_of_exists_odd_degree` is that the existence of an
  odd-degree vertex implies the existence of another one.

## Implementation notes

We give a combinatorial proof by using the facts that (1) the map from
darts to vertices is such that each fiber has cardinality the degree
of the corresponding vertex and that (2) the map from darts to edges is 2-to-1.

## Tags

weighted graphs, sums, degree-sum formula, handshaking lemma
-/

open finset
open_locale big_operators

variables {α W : Type*}

namespace weighted_graph
variables (G : weighted_graph α W)

/-- A dart is a directed edge, consisting of an ordered pair of adjacent vertices. -/
@[ext] structure dart :=
(fst snd : α)
(adj : G.adj fst snd)

instance dart.fintype [fintype α] [decidable_rel G.adj] : fintype G.dart :=
fintype.of_equiv (Σ v, G.neighbor_set v)
{ to_fun := λ s, ⟨s.fst, s.snd, s.snd.property⟩,
  inv_fun := λ d, ⟨d.fst, d.snd, d.adj⟩,
  left_inv := λ s, by ext; simp,
  right_inv := λ d, by ext; simp }

-- `derive decidable_eq` creates an instance that wrongly asks for `decidable_eq W`
instance [decidable_eq α] : decidable_eq G.dart := λ a b, decidable_of_iff _ (dart.ext_iff _ _).symm

variables {G}

/-- The edge associated to the dart. -/
def dart.edge (d : G.dart) : sym2 α := ⟦(d.fst, d.snd)⟧

@[simp] lemma dart.edge_mem (d : G.dart) : d.edge ∈ G.edge_set := d.adj

/-- The dart with reversed orientation from a given dart. -/
def dart.rev (d : G.dart) : G.dart := ⟨d.snd, d.fst, G.adj_symm d.adj⟩

@[simp] lemma dart.rev_edge (d : G.dart) : d.rev.edge = d.edge := sym2.eq_swap

@[simp] lemma dart.rev_rev (d : G.dart) : d.rev.rev = d := dart.ext _ _ rfl rfl

@[simp] lemma dart.rev_involutive : function.involutive (dart.rev : G.dart → G.dart) :=
dart.rev_rev

lemma dart.rev_ne (d : G.dart) : d.rev ≠ d := λ h, d.adj.ne $ congr_arg dart.snd h

lemma dart_edge_eq_iff (d₁ d₂ : G.dart) : d₁.edge = d₂.edge ↔ d₁ = d₂ ∨ d₁ = d₂.rev :=
begin
  cases d₁ with s₁ t₁ h₁,
  cases d₂ with s₂ t₂ h₂,
  simp only [dart.edge, dart.rev_edge, dart.rev],
  rw sym2.eq_iff,
end

variables (G)

/-- For a given vertex `v`, this is the bijective map from the neighbor set at `v`
to the darts `d` with `d.fst = v`. --/
def dart_of_neighbor_set (v : α) (w : G.neighbor_set v) : G.dart := ⟨v, w, w.property⟩

lemma dart_of_neighbor_set_injective (v : α) : function.injective (G.dart_of_neighbor_set v) :=
λ e₁ e₂ h, by { injection h with h₁ h₂, exact subtype.ext h₂ }

instance dart.inhabited [inhabited α] [inhabited (G.neighbor_set (default _))] :
  inhabited G.dart := ⟨G.dart_of_neighbor_set (default _) (default _)⟩

section degree_sum
variables [fintype α] [decidable_rel G.adj]

lemma dart_fst_fiber [decidable_eq α] (v : α) :
  univ.filter (λ d : G.dart, d.fst = v) = univ.image (G.dart_of_neighbor_set v) :=
begin
  ext d,
  simp only [mem_image, true_and, mem_filter, set_coe.exists, mem_univ, exists_prop_of_true],
  split,
  { rintro rfl,
    exact ⟨_, d.adj, dart.ext _ _ rfl rfl⟩ },
  { rintro ⟨e, he, rfl⟩,
    refl },
end

lemma dart_fst_fiber_card_eq_degree [decidable_eq α] (v : α) :
  (univ.filter (λ d : G.dart, d.fst = v)).card = G.degree v :=
begin
  have hh := card_image_of_injective univ (G.dart_of_neighbor_set_injective v),
  rw [finset.card_univ, card_neighbor_set_eq_degree] at hh,
  rwa dart_fst_fiber,
end

lemma dart_card_eq_sum_degrees : fintype.card G.dart = ∑ v, G.degree v :=
begin
  haveI h : decidable_eq α, { classical, apply_instance },
  simp only [←card_univ, ←dart_fst_fiber_card_eq_degree],
  exact card_eq_sum_card_fiberwise (by simp),
end

variables {G} [decidable_eq α]

lemma dart.edge_fiber (d : G.dart) :
  (univ.filter (λ (d' : G.dart), d'.edge = d.edge)) = {d, d.rev} :=
finset.ext (λ d', by simpa using dart_edge_eq_iff d' d)

variables (G)

lemma dart_edge_fiber_card (e : sym2 α) (h : e ∈ G.edge_set) :
  (univ.filter (λ (d : G.dart), d.edge = e)).card = 2 :=
begin
  refine quotient.ind (λ p h, _) e h,
  cases p with v w,
  let d : G.dart := ⟨v, w, h⟩,
  convert congr_arg card d.edge_fiber,
  rw [card_insert_of_not_mem, card_singleton],
  rw [mem_singleton],
  exact d.rev_ne.symm,
end

lemma dart_card_eq_twice_card_edges : fintype.card G.dart = 2 * G.edge_finset.card :=
begin
  rw ←card_univ,
  rw @card_eq_sum_card_fiberwise _ _ _ dart.edge _ G.edge_finset
    (λ d h, by { rw mem_edge_finset, apply dart.edge_mem }),
  rw [←mul_comm, sum_const_nat],
  intros e h,
  apply G.dart_edge_fiber_card e,
  rwa ←mem_edge_finset,
end

/-- The degree-sum formula.  This is also known as the handshaking lemma, which might
more specifically refer to `weighted_graph.even_card_odd_degree_vertices`. -/
theorem sum_degrees_eq_twice_card_edges : ∑ v, G.degree v = 2 * G.edge_finset.card :=
G.dart_card_eq_sum_degrees.symm.trans G.dart_card_eq_twice_card_edges

end degree_sum

/-- The handshaking lemma.  See also `weighted_graph.sum_degrees_eq_twice_card_edges`. -/
theorem even_card_odd_degree_vertices [fintype α] [decidable_rel G.adj] :
  even (univ.filter (λ v, odd (G.degree v))).card :=
begin
  classical,
  have h := congr_arg ((λ n, ↑n) : ℕ → zmod 2) G.sum_degrees_eq_twice_card_edges,
  simp only [zmod.nat_cast_self, zero_mul, nat.cast_mul] at h,
  rw [nat.cast_sum, ←sum_filter_ne_zero] at h,
  rw @sum_congr _ _ _ _ (λ v, (G.degree v : zmod 2)) (λ v, (1 : zmod 2)) _ rfl at h,
  { simp only [filter_congr_decidable, mul_one, nsmul_eq_mul, sum_const, ne.def] at h,
    rw ←zmod.eq_zero_iff_even,
    convert h,
    ext v,
    rw ←zmod.ne_zero_iff_odd,
    congr' },
  { intros v,
    simp only [true_and, mem_filter, mem_univ, ne.def],
    rw [zmod.eq_zero_iff_even, zmod.eq_one_iff_odd, nat.odd_iff_not_even, imp_self],
    trivial }
end

lemma odd_card_odd_degree_vertices_ne [fintype α] [decidable_eq α] [decidable_rel G.adj]
  (v : α) (h : odd (G.degree v)) :
  odd (univ.filter (λ w, w ≠ v ∧ odd (G.degree w))).card :=
begin
  rcases G.even_card_odd_degree_vertices with ⟨k, hg⟩,
  have hk : 0 < k,
  { have hh : (filter (λ (v : α), odd (G.degree v)) univ).nonempty,
    { use v,
      simp only [true_and, mem_filter, mem_univ],
      use h },
    rwa [←card_pos, hg, zero_lt_mul_left] at hh,
    exact zero_lt_two },
  have hc : (λ (w : α), w ≠ v ∧ odd (G.degree w)) = (λ (w : α), odd (G.degree w) ∧ w ≠ v),
  { ext w,
    rw and_comm },
  simp only [hc, filter_congr_decidable],
  rw [←filter_filter, filter_ne', card_erase_of_mem],
  { use k - 1,
    rw [nat.pred_eq_succ_iff, hg, mul_tsub, tsub_add_eq_add_tsub, eq_comm,
      tsub_eq_iff_eq_add_of_le],
    { ring },
    { exact add_le_add_right (zero_le _) 2 },
    { exact nat.mul_le_mul_left _ hk } },
  { simpa only [true_and, mem_filter, mem_univ] },
end

lemma exists_ne_odd_degree_of_exists_odd_degree [fintype α] [decidable_rel G.adj]
  (v : α) (h : odd (G.degree v)) :
  ∃ (w : α), w ≠ v ∧ odd (G.degree w) :=
begin
  haveI : decidable_eq α, { classical, apply_instance },
  rcases G.odd_card_odd_degree_vertices_ne v h with ⟨k, hg⟩,
  have hg' : (filter (λ (w : α), w ≠ v ∧ odd (G.degree w)) univ).card > 0,
  { rw hg,
    apply nat.succ_pos },
  rcases card_pos.mp hg' with ⟨w, hw⟩,
  simp only [true_and, mem_filter, mem_univ, ne.def] at hw,
  exact ⟨w, hw⟩,
end

end weighted_graph