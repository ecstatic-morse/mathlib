import measure_theory.lebesgue_measure
import group_theory.subgroup
import analysis.convex.basic
import tactic

open measure_theory
variables {n : ℕ}
noncomputable theory

variables (trans_inv : ∀ (v : fin n → ℝ) (S : set (fin n → ℝ)), volume S = volume ((+ v) '' S))

/-- Blichfeldt's Principle --/
-- def L (n : ℕ) : add_subgroup (fin n → ℝ) := set.range (monoid_hom.comp {to_fun := (coe : ℤ → ℝ),
-- map_one' := int.cast_one, map_mul' := int.cast_mul})

-- instance : is_add_group_hom ((∘) (coe : ℤ → ℝ) : (fin n → ℤ) → (fin n → ℝ)) :=
-- { map_add := λ x y, by ext;
--   exact int.cast_add (x x_1) (y x_1), }
-- instance : is_add_subgroup (L n) := is_add_group_hom.range_add_subgroup ((∘) coe)
/- this can be generalized any range of a morphism is a subgroup -/

/- TODO decide wether to include measurablity in defn of a fundamental domain-/

structure fundamental_domain (L : add_subgroup (fin n → ℝ)) := /- this is _just_ a coset right? -/
  (F : set (fin n → ℝ))
  (hF : measurable_set F)
  (disjoint : ∀ (l : fin n → ℝ) (hl : l ∈ L) (h : l ≠ 0), disjoint ((+ l) '' F) F)
  (covers : ∀ (x : fin n → ℝ), ∃ (l : fin n → ℝ) (hl : l ∈ L), l + x ∈ F)

-- def cube_fund : fundamental_domain (L n) :=
-- { F := {v : fin n → ℝ | ∀ m : fin n, 0 ≤ v m ∧ v m < 1},
--   disjoint := λ l hl h x ⟨⟨a, ha, hx₁⟩, hx₂⟩, false.elim (h (begin
--     ext m, specialize ha m, specialize hx₂ m,
--     simp only [hx₁.symm, int.cast_zero, pi.add_apply, pi.zero_apply,
--       eq_self_iff_true, ne.def, zero_add] at ha hx₂ ⊢,
--     rcases hl with ⟨w, hw⟩,
--     rw ← hw at *,
--     dsimp,
--     have wlt : (↑(w m): ℝ) < 1 := by linarith,
--     have ltw : (-1 : ℝ) < w m := by linarith,
--     norm_cast,
--     have : w m < 1 := by exact_mod_cast wlt,
--     have : (-1 : ℤ) < w m := by exact_mod_cast ltw,
--     linarith,
--   end)),
--   covers := λ x, ⟨-(coe ∘ floor ∘ x), ⟨is_add_subgroup.neg_mem (set.mem_range_self (floor ∘ x)),
--   begin
--     intro,
--     simp only [int.cast_zero, pi.add_apply, pi.zero_apply, pi.neg_apply,
--       function.comp_app, zero_add, neg_add_lt_iff_lt_add],
--     split,
--     { linarith [floor_le (x m)], },
--     { linarith [lt_floor_add_one (x m)], }
--   end⟩⟩}

-- lemma cube_fund_volume : volume (cube_fund.F : set (fin n → ℝ)) = 1 :=
-- begin
--   dsimp [cube_fund],
--   rw volume_pi,
--   sorry,
-- end


lemma fundamental_domain.exists_unique {L : add_subgroup (fin n → ℝ)} (F : fundamental_domain L)
  (x : fin n → ℝ) : ∃! (p : L), x ∈ (+ (p : fin n → ℝ)) '' F.F :=
exists_unique_of_exists_of_unique
begin
  simp only [exists_prop, set.mem_preimage, set.image_add_right, exists_unique_iff_exists],
  obtain ⟨l, hl, lh⟩ := F.covers x,
  use -l,
  exact L.neg_mem hl,
  simpa [hl, add_comm] using lh,
end (begin rintro y₁ y₂ ⟨ᾰ_w, ⟨ᾰ_h_left_w, ᾰ_h_left_h_left, rfl⟩, ᾰ_h_right⟩ ⟨ᾰ_1_w,
 ⟨ᾰ_1_h_left_w, ᾰ_1_h_left_h_left, ᾰ_1_h_left_h_right⟩,
 ᾰ_1_h_right⟩, simp at *, sorry end)

/- TODO do I want to use this instance instead -/
-- instance {F : fundamental_domain $ L n} (hF : measurable_set F.F) :
--   measurable_space F.F := subtype.measurable_space

instance subtype.measure_space {V : Type*} [measure_space V] {p : set V} :
measure_space (subtype p) :=
{ volume := measure.comap subtype.val volume,
  ..subtype.measurable_space }

lemma volume_subtype_univ {V : Type*} [measure_space V] {p : set V} (hmp : measurable_set p) :
  @volume _ subtype.measure_space (set.univ : set (subtype p)) = volume p :=
begin
  dsimp [measure_space.volume],
  rw [measure.comap_apply _ subtype.val_injective, set.image_univ],
  congr,
  exact subtype.range_val,
  begin
    intros x hx,
    exact measurable_set.subtype_image hmp hx,
  end,
  exact measurable_set.univ,
end

/-instance {F : fundamental_domain $ L n} : measure_space F.F :=
{ measurable_set := λ s, measure_space.to_measurable_space.measurable_set (subtype.val '' s),
  measurable_set_empty := by rw [set.image_empty];
                          exact measure_space.to_measurable_space.is_measurable_empty,
  measurable_set_compl := λ S h, begin
    have : subtype.val '' (-S) = -(subtype.val '' S) ∩ F.F :=
    begin
      ext,
      simp only [not_exists, set.mem_image, set.mem_inter_eq, exists_and_distrib_right,
      exists_eq_right, subtype.exists,
 set.mem_compl_eq], /- TODO is this a logic lemma now ? -/
      split; intro; cases a,
      split,
      intro,
      exact a_h,
      exact a_w,
      exact Exists.intro a_right (a_left a_right),
    end,
    rw this,
    apply measurable_set.inter,
    exact measurable_space.is_measurable_compl _ _ h,
    exact hF,
  end,
  is_measurable_Union := λ f a, begin
    rw set.image_Union,
    exact measure_space.to_measurable_space.is_measurable_Union (λ (i : ℕ), subtype.val '' f i) a,
  end,
  μ := { measure_of := λ S, begin let l := (subtype.val '' S), exact _inst_1.μ.measure_of l, end,
  empty := _,
  mono := _,
  Union_nat := _,
  m_Union := sorry,
  trimmed := _ }
  }-/

include trans_inv
lemma exists_diff_lattice_of_volume_le_volume (L : add_subgroup (fin n → ℝ)) [encodable L]
  (S : set (fin n → ℝ)) (hS : measurable_set S) (F : fundamental_domain L)
  (h : volume F.F < volume S) :
∃ (x y : fin n → ℝ) (hx : x ∈ S) (hy : y ∈ S) (hne : x ≠ y), x - y ∈ L :=
begin
  suffices : ∃ (p₁ p₂ : L) (hne : p₁ ≠ p₂),
    (((+ ↑p₁) '' S ∩ F.F) ∩ ((+ ↑p₂) '' S ∩ F.F)).nonempty,
  begin
    rcases this with ⟨p₁, p₂, hne, u, ⟨⟨q₁, ⟨hS₁, ht₁⟩⟩, hu⟩, ⟨⟨q₂, ⟨hS₂, ht₂⟩⟩, hu⟩⟩,
    use [u - p₁, u - p₂],
    split,
    { rwa [← ht₁, add_sub_cancel], },
    split,
    { rwa [← ht₂, add_sub_cancel], },
    rw (by abel : u - p₁ - (u - p₂) = p₂ - p₁),
    split,
    { intro a,
      apply hne,
      rw sub_right_inj at a,
      exact subtype.eq a, },
    exact L.sub_mem p₂.mem p₁.mem,
  end,
  rw ← volume_subtype_univ F.hF at h,
  let s := λ p : L, (λ a, ((+ (p : fin n → ℝ)) '' S) a.val : set F.F),
  have := exists_nonempty_inter_of_measure_univ_lt_tsum_measure subtype.measure_space.volume
    (_ : (∀ p : L, measurable_set (λ a, ((+ ↑p) '' S) a.val : set F.F))) _,
  { rcases this with ⟨i, j, hij, t, ht⟩,
    use [i, j, hij, t],
    simp only [and_true, set.mem_inter_eq, set.mem_preimage, subtype.coe_prop],
    exact ht, },
  { intros,
    dsimp [s],
    suffices : measurable_set (λ (a : ↥(F.F)), (S) ↑a),
    { simp only [set.image_add_right],
      refine measurable_set_preimage _ hS,
      refine measurable.add_const _ (-↑p),
      exact measurable_subtype_coe, },
    exact ⟨S, ⟨hS, rfl⟩⟩, },
  convert h,
  have : (∑' (i : L), volume ((+ (i : fin n → ℝ)) '' S ∩ F.F)) = volume S,
  { rw (_ : ∑' (i : L), volume ((+ ↑i) '' S ∩ F.F) =
        ∑' (i : L), volume ((+ (-↑i)) '' ((+ ↑i) '' S ∩ F.F))),
    { conv in (_ '' (_ ∩ _)) {
        rw [← set.image_inter (add_left_injective _), ← set.image_comp],
        simp only [add_neg_cancel_right, function.comp_app, set.image_id',
          comp_add_right, add_zero, add_right_neg, set.image_add_right, neg_neg],
        rw set.inter_comm, },
      rw ← measure_Union _ _,
      { congr,
        -- conv_lhs {
        --   congr,
        --   funext,
        --   rw [← set.image_inter (add_left_injective _), ← set.image_comp],
        --   simp [add_neg_cancel_right, function.comp_app, set.image_id'], -- TODO nonterminal but can't squeeze
        --   rw set.inter_comm, },
        rw [← set.Union_inter, set.inter_eq_self_of_subset_right],
        convert set.subset_univ _,
        rw set.eq_univ_iff_forall,
        intros,
        rw set.mem_Union,
        rcases F.covers x with ⟨w, t, h_1_h⟩,
        use ⟨w, t⟩,
        rw [set.mem_preimage, subtype.coe_mk, add_comm],
        assumption, },
      { apply_instance, },
      { intros x y hxy,
        suffices : (disjoint on λ (i : ↥(L)), (λ (_x : fin n → ℝ), _x + -↑i) '' F.F) x y,
        {
          -- conv in (_ '' (_ ∩ _))
          -- { rw [← set.image_inter (add_left_injective (-(i : fin n → ℝ))), ← set.image_comp], },
          simp only [comp_add_right, add_zero, add_right_neg,
            set.image_add_right, neg_neg, set.image_id'] at this ⊢,
          rintros z ⟨⟨hzx, hzS⟩, ⟨hzy, hzS⟩⟩,
          apply this,
          simp only [set.mem_preimage, set.mem_inter_eq, set.inf_eq_inter],
          exact ⟨hzx, hzy⟩, },
        rintros t ⟨htx, hty⟩,
        simp only [set.mem_empty_eq, set.mem_preimage, set.bot_eq_empty,
          set.image_add_right, neg_neg] at htx hty ⊢,
        apply hxy,
        suffices : -x = -y, by simpa using this,
        apply exists_unique.unique (F.exists_unique t) _ _; simpa, },
    { intro l,
      -- rw [← set.image_inter (add_left_injective (-(l : fin n → ℝ))), ← set.image_comp],
      -- simp only [comp_add_right, add_zero, add_right_neg, set.image_add_right,
      --   neg_neg, set.image_id'],
      apply measurable_set.inter _ hS,
      refine measurable_set_preimage _ F.hF,
      exact measurable_add_const ↑l, }, },
    { congr,
      ext1 l,
      rw [trans_inv (-↑ l) _], }, },
  convert this,
  ext1 l,
  simp only [set.image_add_right],
  dsimp only [subtype.measure_space],
  rw measure.comap_apply _ subtype.val_injective _ _ _,
  { congr,
    ext1 v,
    simp only [set.mem_preimage, set.mem_image, set.mem_inter_eq, exists_and_distrib_right,
      exists_eq_right, subtype.exists, subtype.coe_mk, subtype.val_eq_coe],
    cases l, cases h, cases h_h, cases h_w,
    simp only [set.image_add_right, add_subgroup.coe_mk, option.mem_def,
      ennreal.some_eq_coe, add_subgroup.coe_mk],
    split; { intros a, cases a, split; assumption, }, },
  { intros X hX,
    convert measurable_set.subtype_image F.hF hX, },
  { refine measurable_set_preimage _ hS,
    refine measurable.add_const _ (-↑l),
    exact measurable_subtype_coe, },
end

-- how to apply to the usual lattice
    -- exact set.countable.to_encodable (set.countable_range (function.comp coe)),

open ennreal
lemma exists_nonzero_lattice_of_two_dim_le_volume (L : add_subgroup (fin n → ℝ)) [encodable L]
  (F : fundamental_domain L) (S : set (fin n → ℝ)) (h : volume F.F * 2 ^ n < volume S)
  (symmetric : ∀ x ∈ S, -x ∈ S) (convex : convex S) : ∃ (x : L) (h : x ≠ 0), ↑x ∈ S :=
begin
  let halfS : set (fin n → ℝ) := {v | 2 * v ∈ S}, -- TODO factor out into a rescale function and API
  have mhalf : measurable_set halfS, sorry,
  have : volume halfS * 2^n = volume S,
  {
    sorry, -- rescaling measures
  },
  have h2 : volume F.F < volume halfS,
  { rw ← ennreal.mul_lt_mul_right (pow_ne_zero n two_ne_zero') (pow_ne_top two_ne_top),
    convert h, },

  let C : set (fin n → ℝ) :=
    { v | ∃ (v₁ v₂ : fin n → ℝ) (hv₁ : v₁ ∈ halfS) (hv₂ : v₂ ∈ halfS), v₁ + v₂ = v},
  have : C = S,
  { ext,
    split; intro h,
    { rcases h with ⟨v₁, v₂, h₁, h₂, rfl⟩,
      have := convex h₁ h₂ (le_of_lt one_half_pos) (le_of_lt one_half_pos) (by linarith),
      rw [← inv_eq_one_div] at this,
      suffices hv : ∀ v : fin n → ℝ, v = (2⁻¹:ℝ) • (2 * v),
      { convert this,
        all_goals {exact hv _}, },
      intro,
      suffices : v = ((2⁻¹:ℝ) * 2) • v,
      { conv_lhs { rw this, },
        exact mul_assoc _ _ _, },
      norm_num, },
    { use [(2⁻¹ : ℝ) • x, (2⁻¹ : ℝ) • x],
      simp only [exists_prop, and_self_left, set.mem_set_of_eq],
      split,
      { convert h, ext,
        change 2 * (2⁻¹ * x x_1) = x x_1,
        rw ← mul_assoc,
        norm_num, },
      { rw ← add_smul,
        norm_num, }, }, },
  rw ← this,
  suffices : ∃ (x y : fin n → ℝ) (hx : x ∈ halfS) (hy : y ∈ halfS) (hne : x ≠ y),
    x - y ∈ L,
  { rcases this with ⟨x, y, hx, hy, hne, hsub⟩,
    use ⟨x - y, hsub⟩,
    split,
    { apply subtype.ne_of_val_ne,
      simp [sub_eq_zero, hne], },
    have : ∀ t ∈ halfS, -t ∈ halfS,
    { intros t ht,
      simp only [mul_neg_eq_neg_mul_symm, set.mem_set_of_eq],
      exact symmetric _ ht, },
    use [x, -y, hx, this _ hy],
    refl, },
  { exact exists_diff_lattice_of_volume_le_volume trans_inv L halfS mhalf F h2, }
end

#lint
