import Analysis.Set.Function

/--
  A filter on `α` is a set of sets of `α` containing `α` itself, closed under 
  supersets and intersection.
  NB. This definition of filters does not require `∅ ∉ sets`. This is done so 
  we can create a lattice structure. `∅ ∉ sets` should be included as a 
  seperate proposition in lemmas.
-/
structure Filter (α : Type u) where
  sets                   : Set (Set α)
  univ_sets              : Set.univ ∈ sets
  sets_of_superset {x y} : x ∈ sets → x ⊆ y → y ∈ sets
  inter_sets       {x y} : x ∈ sets → y ∈ sets → x ∩ y ∈ sets

-- I'm going to follow 
-- https://web.archive.org/web/20071009170540/http://www.efnet-math.org/~david/mathematics/filters.pdf

-- First, we will find a way to generate filters for any given set of sets of α
-- To achieve this, we consider that the intersection of a collection of filters 
-- is also a filter, so therefore, a filter can be generated form a set of sets 
-- by taking the intersection of all filters containing this set, i.e. if `S` is 
-- type `set (set α)`, then the filter generated by `S` is 
-- ⋂ { F : filter α | S ⊆ F.sets }

namespace Filter

open Set

instance : Coe (Filter α) (Set (Set α)) := ⟨λ F => F.sets⟩

instance : Mem (Set α) (Filter α) := ⟨λ x F => x ∈ (F : Set (Set α))⟩

-- instance : LE (Filter α) := ⟨_⟩

/-! ### Basics -/

theorem eq {F G : Filter α} (h : F.sets = G.sets) : F = G := by
  cases F; cases G; subst h; rfl
  
theorem eqIff {F G : Filter α} : F = G ↔ F.sets = G.sets := 
Iff.intro (λ h => h ▸ rfl) eq

theorem ext {F G : Filter α} (h : ∀ s, s ∈ F ↔ s ∈ G) : F = G := 
  eq <| Set.ext h

/-- The intersection of a collection of filters is a filter. -/
def Inf (𝒞 : Set (Filter α)) : Filter α :=
{ sets := ⋂ F ∈ 𝒞, F
  univ_sets := λ F hF => F.univ_sets
  sets_of_superset := λ hx hxy F hF => F.sets_of_superset (hx F hF) hxy
  inter_sets := λ hx hy F hF => F.inter_sets (hx F hF) (hy F hF) }

-- With that we can now define the filter generated by an arbitary set of sets 

/-- The filter generated from `S`, a set of sets of `α` is the Inf of all filters 
  containing `S` -/
def generatedFrom (S : Set (Set α)) : Filter α := 
  Inf { F : Filter α | S ⊆ (F : Set (Set α)) }

-- The method above generates the smallest filter that contains `S : set (set α)`
-- On the other hand, we can generate a filter using `s : set α` be letting the 
-- filter be all supersets of `s`, this is called `principal s`

/-- The principal filter of a set `s` is set set of all sets larger than `s`. -/
def principal (s : Set α) : Filter α := 
{ sets := { t | s ⊆ t }
  univ_sets := Subset.subsetUniv
  sets_of_superset := λ hx hxy => Subset.trans hx hxy
  inter_sets := λ hx hy => subsetInter hx hy }

prefix:100 "𝓟 " => principal

theorem selfMemPrincipal (s : Set α) : s ∈ 𝓟 s := Subset.refl

variable {S : Set (Set α)}

theorem leGeneratedFrom : S ⊆ generatedFrom S := 
  λ s hs F hF => hF _ hs

-- Straightaway, we see that if `∅ ∈ S`, then `generatedFrom S` is the powerset of `α` 
theorem generatedFromEmpty (hS : ∅ ∈ S) (s : Set α) : s ∈ generatedFrom S := 
  (generatedFrom S).sets_of_superset (leGeneratedFrom _ hS) (Subset.empty s)

-- We don't want to consider filters with only the set `univ` and so, we 
-- introduce the `neBot` class

/-- The smallest filter is the filter containing only the set `univ`. -/
def bot : Filter α := 
{ sets := λ s => univ = s
  univ_sets := rfl
  sets_of_superset := λ hx hy => Subset.univSubsetIff.1 <| hx ▸ hy
  inter_sets := λ hx hy => Eq.symm <| hx ▸ hy ▸ interSelf }

/-- A filter is `neBot` if it is not equal to `Filter.bot`-/
class neBot (F : Filter α) where 
  ne_bot : F ≠ bot

/-- Let `F` be a `ne_bot` filter on `α`, `F` is an ultra filter if for all 
  `S : set α`, `S ∈ F` or `Sᶜ ∈ F` -/
class Ultra (F : Filter α) where
  ne_bot : neBot F 
  mem_or_compl_mem {S : Set α} : S ∈ F ∨ Sᶜ ∈ F

-- The ultra filter theorem states that for all `F : filter α`, there exists 
-- some ultra filter `𝕌`, `F ⊆ 𝕌`.

-- The proof of this follows from Zorn's lemma.
-- Let `F` be a filter on `α`, We have the filters of `α` that contain `F` form 
-- a poset. Let `𝒞` be a chain (a totaly ordered set) within this set, then by 
-- Zorn's lemma, `𝒞` has at least one maximum element. Thus, by checking this 
-- maximum element is indeed an ultra filter, we have found a ultra filter 
-- containing `F`.

-- We won't try proving it anytime soon
-- In Lean 3 mathlib its known as `exists_maximal_of_chains_bounded`

-- theorem existsUltraGe (F : Filter α) [neBot F] : 
--   ∃ (G : Filter α) [Ultra G], (F : Set (Set α)) ⊆ G := sorry

def map (f : α → β) (F : Filter α) : Filter β := 
{ sets := preimage (preimage f) F
  univ_sets := F.univ_sets
  sets_of_superset := λ hx hxy => F.sets_of_superset hx <| preimageMono f hxy
  inter_sets := λ hx hy => F.inter_sets hx hy }

/-! ### Convergence -/

/-- A neighbourhood of `x` is the principal filter of the singleton set `{x}`-/
def neighbourhood (x : α) : Filter α := 𝓟 {x}

notation:100 "𝓝 " x => 𝓟 {x}

def eventually (p : α → Prop) (F : Filter α) := p ∈ F

theorem ext' {F G : Filter α} (h : ∀ p, eventually p F ↔ eventually p G) : 
  F = G := 
Filter.ext h

/-- A filter `l₁` tendsto another filter `l₂` along some function `f` if the 
map of `l₁` along `f` is smaller than `l₂`. -/
def tendsto (f : α → β) (l₁ : Filter α) (l₂ : Filter β) := 
(l₁.map f : Set (Set β)) ⊆ l₂
-- preimage (preimage f) F ⊆ l₂
-- s ∈ preimage (preimage f) F → s ∈ l₂ 
-- s.preimage f ∈ F → s ∈ l₂

theorem tendstoDef {f : α → β} {l₁ : Filter α} {l₂ : Filter β} :
  tendsto f l₁ l₂ ↔ ∀ (s : Set β) (hs : s.preimage f ∈ l₁), s ∈ l₂ := Iff.rfl
--   tendsto f l₁ l₂ ↔ ∀ s ∈ l₂, s.preimage f ∈ l₁ := 
-- Iff.intro (λ h s hs => _) _

#exit

-- Let X be a Hausdorff space
variables {X : Type*} [topological_space X]

/-- A filter `F` on a Hausdorff space `X` has at most one limit -/
theorem tendsto_unique {x y : X} {F : filter X} [H : ne_bot F] [t2_space X]
  (hFx : tendsto id F (nhds x)) 
  (hFy : tendsto id F (nhds y)) : x = y :=
begin
  by_contra hneq,
  rcases t2_space.t2 _ _ hneq with ⟨U, V, hU, hV, hxU, hyV, hdisj⟩,
  apply H, rw [←empty_in_sets_eq_bot, ←hdisj],
  refine F.inter_sets _ _,
    { rw ←@preimage_id _ U,
      exact tendsto_def.1 hFx U (mem_nhds_sets hU hxU) },
    { rw ←@preimage_id _ V,
      exact tendsto_def.1 hFy V (mem_nhds_sets hV hyV) }
end

variables {Y : Type*} [topological_space Y]

@[reducible] def filter_image (f : X → Y) (F : filter X) : filter Y := 
  generate $ (λ s : set X, f '' s) '' F

-- We'll use mathlib's `generate` and `map` which are the same 
-- as the ones we've defined but there is more APIs to work with

/-- A filter `F : filter X` is said to converge to some `x : X` if `nhds x ⊆ F` -/
@[reducible] private def converge_to (F : filter X) (x : X) : Prop := 
  (nhds x : set (set X)) ⊆ F

-- This definition is equivalent to `tendsto id F (nhds x)`
private lemma converge_to_iff (F : filter X) (x : X) : 
  converge_to F x ↔ tendsto id F (nhds x) :=
begin
  refine ⟨λ h, tendsto_def.1 $ λ s hs, _, λ h, _⟩,
    { rw map_id, simpa using h hs },
    { simp_rw [tendsto_def, preimage_id] at h, exact h }
end

/-- The neighbourhood filter of `x` converges to `x` -/
lemma nhds_tendsto (x : X) : tendsto id (nhds x) (nhds x) := 
λ U hU, by rwa map_id

lemma mem_filter_image_iff {f : X → Y} {F : filter X} (V) : 
  V ∈ map f F ↔ ∃ U ∈ F, f '' U ⊆ V :=
begin
  refine ⟨λ h, ⟨_, h, image_preimage_subset _ _⟩, λ h, _⟩,
    rcases h with ⟨U, hU₀, hU₁⟩,
    rw mem_map,
    apply F.sets_of_superset hU₀,
    intros u hu,
    rw mem_set_of_eq,
    apply hU₁, rw mem_image,
    exact ⟨u, hu, rfl⟩    
end

lemma nhds_subset_filter_of_tendsto {x : X} {F : filter X} 
  (hF : tendsto id F (nhds x)) : (nhds x : set (set X)) ⊆ F :=
begin
  intros s hs,
  have := tendsto_def.1 hF _ hs,
  rwa preimage_id at this
end

/-- A map between topological spaces `f : X → Y` is continuous at some `x : X` 
  if for all `F : filter X` that tends to `x`, `map F` tends to `f(x)` -/
theorem continuous_of_filter_tendsto {x : X} (f : X → Y)
  (hF : ∀ F : filter X, tendsto id F (nhds x) → 
    tendsto id (map f F) (nhds (f x))) : continuous_at f x :=
λ _ hU, tendsto_def.1 (hF _ $ nhds_tendsto x) _ hU

/-- If `f : X → Y` is a continuous map between topological spaces, then for all 
  `F : filter X` that tends to `x`, `map F` tends to `f(x)` -/
theorem filter_tendsto_of_continuous {x : X} {F : filter X} (f : X → Y) 
  (hf : continuous_at f x) (hF : tendsto id F (nhds x)) : 
  tendsto id (map f F) (nhds (f x)) := 
begin
  rw tendsto_def at *, intros U hU,
  exact nhds_subset_filter_of_tendsto hF (hf hU),
end

/-! ### Product Filters -/

/- Given two filters `F` and `G` on the topological spaces `X` and `Y` respectively, 
  we define the the product filter `F × G` as a filter on the product space `X × Y` 
  such that 
  `prod F G := F.comap prod.fst ⊓ G.comap prod.snd`
  where `prod.fst = (a, b) ↦ a`, `prod.snd = (a, b) ↦ b` and 
  `(C : filter β).comap (f : α → β)` is the filter generated by the set of preimages 
  of sets contained in `C`, i.e. `(C.comap f).sets = generate { f⁻¹(s) | s ∈ C }`. -/

-- We borrow the notation of product filters from mathlib
localized "infix ` ×ᶠ `:60 := filter.prod" in filter

-- Write some theorems here maybe?
-- TODO : make the natural projection : filter (X × Y) → filter X


/-! ### Compactness -/

variables {C : Type*} [topological_space C] [compact_space C]
/- In mathlib a compact space is a topological space that satisfy the 
  `is_compact` proposition where 
  `def is_compact (s : set α) := ∀ ⦃f⦄ [ne_bot f], f ≤ 𝓟 s → ∃ a ∈ s, cluster_pt a f`
  (`cluset_pt a f` means a is a limit point of f) -/




end Filter