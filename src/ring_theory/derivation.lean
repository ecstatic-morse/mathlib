/-
Copyright © 2020 Nicolò Cavalleri. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Nicolò Cavalleri
-/

import algebra.lie.of_associative
import ring_theory.adjoin.basic
import ring_theory.algebra_tower

/-!
# Derivations

This file defines derivation. A derivation `D` from the `R`-algebra `A` to the `A`-module `M` is an
`R`-linear map that satisfy the Leibniz rule `D (a * b) = a * D b + D a * b`.

## Notation

The notation `⁅D1, D2⁆` is used for the commutator of two derivations.

TODO: this file is just a stub to go on with some PRs in the geometry section. It only
implements the definition of derivations in commutative algebra. This will soon change: as soon
as bimodules will be there in mathlib I will change this file to take into account the
non-commutative case. Any development on the theory of derivations is discouraged until the
definitive definition of derivation will be implemented.
-/

open algebra

/-- `D : derivation R A M` is an `R`-linear map from `A` to `M` that satisfies the `leibniz`
equality.
TODO: update this when bimodules are defined. -/
@[protect_proj]
structure derivation (R : Type*) (A : Type*) [comm_semiring R] [comm_semiring A]
  [algebra R A] (M : Type*) [add_cancel_comm_monoid M] [module A M] [module R M]
  [is_scalar_tower R A M]
  extends A →ₗ[R] M :=
(leibniz' (a b : A) : to_fun (a * b) = a • to_fun b + b • to_fun a)

/-- The `linear_map` underlying a `derivation`. -/
add_decl_doc derivation.to_linear_map

namespace derivation

section

variables {R : Type*} [comm_semiring R]
variables {A : Type*} [comm_semiring A] [algebra R A]
variables {M : Type*} [add_cancel_comm_monoid M] [module A M] [module R M]
variables [is_scalar_tower R A M]
variables (D : derivation R A M) {D1 D2 : derivation R A M} (r : R) (a b : A)

instance : has_coe_to_fun (derivation R A M) (λ _, A → M) := ⟨λ D, D.to_linear_map.to_fun⟩

instance has_coe_to_linear_map : has_coe (derivation R A M) (A →ₗ[R] M) :=
⟨λ D, D.to_linear_map⟩

@[simp] lemma to_linear_map_eq_coe : D.to_linear_map = D := rfl

@[simp] lemma mk_coe (f : A →ₗ[R] M) (h) :
  ((⟨f, h⟩ : derivation R A M) : A → M) = f := rfl

@[simp, norm_cast]
lemma coe_fn_coe (f : derivation R A M) : ⇑(f : A →ₗ[R] M) = f := rfl

lemma coe_injective : @function.injective (derivation R A M) (A → M) coe_fn :=
λ D1 D2 h, by { rcases D1 with ⟨⟨⟩⟩, rcases D2 with ⟨⟨⟩⟩, congr', }

@[ext] theorem ext (H : ∀ a, D1 a = D2 a) : D1 = D2 :=
coe_injective $ funext H

lemma congr_fun (h : D1 = D2) (a : A) : D1 a = D2 a := congr_fun (congr_arg coe_fn h) a

@[simp] lemma map_add : D (a + b) = D a + D b := linear_map.map_add D a b
@[simp] lemma map_zero : D 0 = 0 := linear_map.map_zero D
@[simp] lemma map_smul : D (r • a) = r • D a := linear_map.map_smul D r a
@[simp] lemma leibniz : D (a * b) = a • D b + b • D a := D.leibniz' _ _

@[simp] lemma map_one_eq_zero : D 1 = 0 :=
begin
  have h : D 1 = D (1 * 1) := by rw mul_one,
  rwa [leibniz D 1 1, one_smul, self_eq_add_right] at h
end

@[simp] lemma map_algebra_map : D (algebra_map R A r) = 0 :=
by rw [←mul_one r, ring_hom.map_mul, ring_hom.map_one, ←smul_def, map_smul, map_one_eq_zero,
  smul_zero]

@[simp] lemma leibniz_pow (n : ℕ) : D (a ^ n) = n • a ^ (n - 1) • D a :=
begin
  induction n with n ihn,
  { rw [pow_zero, map_one_eq_zero, zero_smul] },
  { rcases (zero_le n).eq_or_lt with (rfl|hpos),
    { rw [pow_one, one_smul, pow_zero, one_smul] },
    { have : a * a ^ (n - 1) = a ^ n, by rw [← pow_succ, nat.sub_add_cancel hpos],
      simp only [pow_succ, leibniz, ihn, smul_comm a n, smul_smul a, add_smul, this,
        nat.succ_eq_add_one, nat.add_succ_sub_one, add_zero, one_nsmul] } }
end

lemma eq_on_adjoin {s : set A} (h : set.eq_on D1 D2 s) : set.eq_on D1 D2 (adjoin R s) :=
λ x hx, algebra.adjoin_induction hx h
  (λ r, (D1.map_algebra_map r).trans (D2.map_algebra_map r).symm)
  (λ x y hx hy, by simp only [map_add, *])
  (λ x y hx hy, by simp only [leibniz, *])

/-- If adjoin of a set is the whole algebra, then any two derivations equal on this set are equal
on the whole algebra. -/
lemma ext_of_adjoin_eq_top (s : set A) (hs : adjoin R s = ⊤) (h : set.eq_on D1 D2 s) : D1 = D2 :=
ext $ λ a, eq_on_adjoin h $ hs.symm ▸ trivial

/- Data typeclasses -/

instance : has_zero (derivation R A M) :=
⟨{ leibniz' := λ a b, by simp only [add_zero, linear_map.zero_apply, linear_map.to_fun_eq_coe,
     smul_zero],
   ..(0 : A →ₗ[R] M) }⟩

@[simp] lemma coe_zero : ⇑(0 : derivation R A M) = 0 := rfl
@[simp] lemma coe_zero_linear_map : ↑(0 : derivation R A M) = (0 : A →ₗ[R] M) := rfl
lemma zero_apply (a : A) : (0 : derivation R A M) a = 0 := rfl

instance : has_add (derivation R A M) :=
⟨λ D1 D2, { leibniz' := λ a b, by simp only [leibniz, linear_map.add_apply,
              linear_map.to_fun_eq_coe, coe_fn_coe, smul_add, add_add_add_comm],
            ..(D1 + D2 : A →ₗ[R] M) }⟩

@[simp] lemma coe_add (D1 D2 : derivation R A M) : ⇑(D1 + D2) = D1 + D2 := rfl
@[simp] lemma coe_add_linear_map (D1 D2 : derivation R A M) : ↑(D1 + D2) = (D1 + D2 : A →ₗ[R] M) :=
rfl
lemma add_apply : (D1 + D2) a = D1 a + D2 a := rfl

instance Rscalar : has_scalar R (derivation R A M) :=
⟨λ r D, { leibniz' := λ a b, by simp only [linear_map.smul_apply, leibniz,
            linear_map.to_fun_eq_coe, smul_algebra_smul_comm, coe_fn_coe, smul_add, add_comm],
          ..(r • D : A →ₗ[R] M) }⟩

@[simp] lemma coe_Rsmul (r : R) (D : derivation R A M) : ⇑(r • D) = r • D := rfl
@[simp] lemma coe_Rsmul_linear_map (r : R) (D : derivation R A M) :
  ↑(r • D) = (r • D : A →ₗ[R] M) := rfl
lemma Rsmul_apply (r : R) (D : derivation R A M) : (r • D) a = r • D a := rfl

instance has_scalar : has_scalar A (derivation R A M) :=
⟨λ a D, { leibniz' := λ b c, by {
            dsimp, simp only [smul_add, leibniz, smul_comm a, add_comm] },
          ..(a • D : A →ₗ[R] M) }⟩

@[simp] lemma coe_smul (a : A) (D : derivation R A M) : ⇑(a • D) = a • D := rfl
@[simp] lemma coe_smul_linear_map (a : A) (D : derivation R A M) :
  ↑(a • D) = (a • D : A →ₗ[R] M) := rfl
lemma smul_apply (a : A) (D : derivation R A M) (b : A) : (a • D) b = a • D b := rfl

instance : inhabited (derivation R A M) := ⟨0⟩

instance : add_comm_monoid (derivation R A M) :=
coe_injective.add_comm_monoid _ coe_zero coe_add

/-- `coe_fn` as an `add_monoid_hom`. -/
def coe_fn_add_monoid_hom : derivation R A M →+ (A → M) :=
{ to_fun := coe_fn, map_zero' := coe_zero, map_add' := coe_add }

@[priority 100]
instance derivation.Rmodule : module R (derivation R A M) :=
function.injective.module R coe_fn_add_monoid_hom coe_injective coe_Rsmul

instance : module A (derivation R A M) :=
function.injective.module A coe_fn_add_monoid_hom coe_injective coe_smul

instance : is_scalar_tower R A (derivation R A M) :=
⟨λ x y z, ext (λ a, smul_assoc _ _ _)⟩

section push_forward

variables {N : Type*} [add_cancel_comm_monoid N] [module A N] [module R N] [is_scalar_tower R A N]
variables (f : M →ₗ[A] N)

/-- We can push forward derivations using linear maps, i.e., the composition of a derivation with a
linear map is a derivation. Furthermore, this operation is linear on the spaces of derivations. -/
def _root_.linear_map.comp_der : derivation R A M →ₗ[R] derivation R A N :=
{ to_fun    := λ D,
  { leibniz'  := λ a b, by simp only [coe_fn_coe, function.comp_app, linear_map.coe_comp,
                      linear_map.map_add, leibniz, linear_map.coe_coe_is_scalar_tower,
                      linear_map.map_smul, linear_map.to_fun_eq_coe],
    .. (f : M →ₗ[R] N).comp (D : A →ₗ[R] M), },
  map_add'  := λ D₁ D₂, by { ext, exact linear_map.map_add _ _ _, },
  map_smul' := λ r D, by { ext, exact linear_map.map_smul _ _ _, }, }

@[simp] lemma coe_to_linear_map_comp :
  (f.comp_der D : A →ₗ[R] N) = (f : M →ₗ[R] N).comp (D : A →ₗ[R] M) :=
rfl

@[simp] lemma coe_comp :
  (f.comp_der D : A → N) = (f : M →ₗ[R] N).comp (D : A →ₗ[R] M) :=
rfl

end push_forward

end

section

variables {R : Type*} [comm_ring R]
variables {A : Type*} [comm_ring A] [algebra R A]

section

variables {M : Type*} [add_comm_group M] [module A M] [module R M] [is_scalar_tower R A M]
variables (D : derivation R A M) {D1 D2 : derivation R A M} (r : R) (a b : A)

@[simp] lemma map_neg : D (-a) = -D a := linear_map.map_neg D a
@[simp] lemma map_sub : D (a - b) = D a - D b := linear_map.map_sub D a b

lemma leibniz_of_mul_eq_one {a b : A} (h : a * b = 1) : D a = -a^2 • D b :=
begin
  rw neg_smul,
  refine eq_neg_of_add_eq_zero _,
  calc D a + a ^ 2 • D b = a • b • D a + a • a • D b : by simp only [smul_smul, h, one_smul, sq]
                     ... = a • D (a * b)             : by rw [leibniz, smul_add, add_comm]
                     ... = 0                         : by rw [h, map_one_eq_zero, smul_zero]
end

lemma leibniz_inv_of [invertible a] : D (⅟a) = -⅟a^2 • D a :=
D.leibniz_of_mul_eq_one $ inv_of_mul_self a

lemma leibniz_inv {K : Type*} [field K] [module K M] [algebra R K] [is_scalar_tower R K M]
  (D : derivation R K M) (a : K) : D (a⁻¹) = -a⁻¹ ^ 2 • D a :=
begin
  rcases eq_or_ne a 0 with (rfl|ha),
  { simp },
  { exact D.leibniz_of_mul_eq_one (inv_mul_cancel ha) }
end

instance : has_neg (derivation R A M) :=
⟨λ D, { leibniz' := λ a b, by simp only [linear_map.neg_apply, smul_neg, neg_add_rev, leibniz,
          linear_map.to_fun_eq_coe, coe_fn_coe, add_comm],
        ..(-D : A →ₗ[R] M)}⟩

@[simp] lemma coe_neg (D : derivation R A M) : ⇑(-D) = -D := rfl
@[simp] lemma coe_neg_linear_map (D : derivation R A M) : ↑(-D) = (-D : A →ₗ[R] M) :=
rfl
lemma neg_apply : (-D) a = -D a := rfl

instance : has_sub (derivation R A M) :=
⟨λ D1 D2, { leibniz' := λ a b, by { simp only [linear_map.to_fun_eq_coe, linear_map.sub_apply,
              leibniz, coe_fn_coe, smul_sub], abel },
            ..(D1 - D2 : A →ₗ[R] M)}⟩

@[simp] lemma coe_sub (D1 D2 : derivation R A M) : ⇑(D1 - D2) = D1 - D2 := rfl
@[simp] lemma coe_sub_linear_map (D1 D2 : derivation R A M) : ↑(D1 - D2) = (D1 - D2 : A →ₗ[R] M) :=
rfl
lemma sub_apply : (D1 - D2) a = D1 a - D2 a := rfl

instance : add_comm_group (derivation R A M) :=
coe_injective.add_comm_group _ coe_zero coe_add coe_neg coe_sub

end

section lie_structures

/-! # Lie structures -/

variables (D : derivation R A A) {D1 D2 : derivation R A A} (r : R) (a b : A)

/-- The commutator of derivations is again a derivation. -/
instance : has_bracket (derivation R A A) (derivation R A A) :=
⟨λ D1 D2, { leibniz' := λ a b, by
            { simp only [ring.lie_def, map_add, id.smul_eq_mul, linear_map.mul_apply, leibniz,
                        linear_map.to_fun_eq_coe, coe_fn_coe, linear_map.sub_apply], ring, },
            to_linear_map := ⁅(D1 : module.End R A), (D2 : module.End R A)⁆, }⟩

@[simp] lemma commutator_coe_linear_map :
  ↑⁅D1, D2⁆ = ⁅(D1 : module.End R A), (D2 : module.End R A)⁆ := rfl

lemma commutator_apply : ⁅D1, D2⁆ a = D1 (D2 a) - D2 (D1 a) := rfl

instance : lie_ring (derivation R A A) :=
{ add_lie     := λ d e f, by { ext a, simp only [commutator_apply, add_apply, map_add], ring, },
  lie_add     := λ d e f, by { ext a, simp only [commutator_apply, add_apply, map_add], ring, },
  lie_self    := λ d, by { ext a, simp only [commutator_apply, add_apply, map_add], ring_nf, },
  leibniz_lie := λ d e f,
    by { ext a, simp only [commutator_apply, add_apply, sub_apply, map_sub], ring, } }

instance : lie_algebra R (derivation R A A) :=
{ lie_smul := λ r d e, by { ext a, simp only [commutator_apply, map_smul, smul_sub, Rsmul_apply]},
  ..derivation.Rmodule }

end lie_structures

end

end derivation
