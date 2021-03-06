import Analysis.Pre
import Analysis.Logic 

def Set (α : Type u) := α → Prop

def setOf (p : α → Prop) : Set α := p

namespace Set

/-! ## Basic Definitions -/

def empty : Set α := λ x => False

instance : EmptyCollection (Set α) := ⟨empty⟩ 

variable {α : Type u} {s : Set α}

def mem (a : α) (s : Set α) := s a

instance : Mem α (Set α) := ⟨mem⟩

-- We note that the reverse direction is a bit more subtle and requires 
-- the definition of images
instance [Coe β α] : Coe (Set α) (Set β) := ⟨λ S => λ x => (x : α) ∈ S⟩

instance : CoeSort (Set α) (Type u) where 
  coe s := Subtype s

theorem ext {s t : Set α} (h : ∀ x, x ∈ s ↔ x ∈ t) : s = t := 
  funext <| λ x => propext <| h x

-- Declaring the index category
declare_syntax_cat index
syntax ident : index
syntax ident " : " term : index 
syntax ident " ∈ " term : index

-- Notation for sets
syntax "{ " index " | " term " }" : term
-- syntax "{" term,* "}"  : term
-- syntax "%{" term,* "|" term "}" : term 

macro_rules 
| `({ $x:ident : $t | $p }) => `(setOf (λ ($x:ident : $t) => $p))
| `({ $x:ident | $p }) => `(setOf (λ ($x:ident) => $p))
| `({ $x:ident ∈ $s | $p }) => `(setOf (λ $x => $x ∈ $s ∧ $p))

def insert (s : Set α) (a : α) : Set α := setOf (λ x => x ∈ s ∨ x = a)

theorem insertMem (s : Set α) {a : α} (ha : a ∈ s) : s.insert a = s := 
  ext (λ x => Iff.intro (λ hx => match hx with
    | Or.inl hx => hx | Or.inr hx => hx ▸ ha) (λ hx => Or.inl hx))

-- Temporary notation for singletons
notation "{ " a " }" => insert ∅ a

theorem memSelfSingleton (a : α) : a ∈ { a } := Or.inr rfl

theorem memSingleton (a b : α) : b ∈ { a } ↔ b = a := 
  Iff.intro (λ hb => match hb with 
    | Or.inl hb => False.elim hb | Or.inr hb => hb) (λ hb => Or.inr hb)

-- macro_rules
--   | `({ $elems,* }) => do
--     let rec expandListLit (i : Nat) (skip : Bool) (result : Syntax) : MacroM Syntax := do
--       match i, skip with
--       | 0,   _     => pure result
--       | i+1, true  => expandListLit i false result
--       | i+1, false => expandListLit i true  (← ``(Set.insert $(elems.elemsAndSeps[i]) $result))
--     if elems.elemsAndSeps.size < 64 then
--       expandListLit elems.elemsAndSeps.size false (← ``(Set.empty))
--     else
--       `(%{ $elems,* | Set.empty })

def union (s t : Set α) : Set α := { x : α | x ∈ s ∨ x ∈ t } 

def inter (s t : Set α) : Set α := { x : α | x ∈ s ∧ x ∈ t }

theorem unionDef (s t : Set α) : union s t = λ x => s x ∨ t x := rfl

theorem interDef (s t : Set α) : inter s t = λ x => s x ∧ t x := rfl

infix:60 " ∪ " => Set.union
infix:60 " ∩ " => Set.inter

def Union {base} [h : Coe β (Set base)] (s : Set β) : Set base := 
  { x | ∃ t : β, t ∈ s ∧ (t : Set base) x }

def Inter {base} [h : Coe β (Set base)] (s : Set β) : Set base := 
  { x | ∀ t : β, t ∈ s → (t : Set base) x }

def UnionDef [h : Coe β (Set α)] (s : Set β) : Union s = 
  λ x => ∃ t : β, t ∈ s ∧ (t : Set α) x := rfl

def InterDef [h : Coe β (Set α)] (s : Set β) : Inter s = 
  λ x => ∀ t : β, t ∈ s → (t : Set α) x := rfl

syntax " ⋃ " index "," term : term
syntax " ⋂ " index "," term : term

macro_rules
| `(⋃ $s:ident ∈ $c, $s) => `(Union $c)
| `(⋂ $s:ident ∈ $c, $s) => `(Inter $c)
| `(⋃ $s:ident ∈ $c, $coe $s) => `(Union {h := coe} $c)
| `(⋂ $s:ident ∈ $c, $coe $s) => `(Inion {h := coe} $c)

-- Notation for ∀ x ∈ s, p and ∃ x ∈ s, p
syntax " ∀ " index "," term : term
syntax " ∃ " index "," term : term

macro_rules
| `(∀ $x:ident ∈ $s, $p) => `(∀ $x:ident, $x ∈ $s → $p)
| `(∃ $x:ident ∈ $s, $p) => `(∃ $x:ident, $x ∈ $s ∧ $p)

-- @[appUnexpander Set.setOf]
-- def setOf.unexpander : Lean.PrettyPrinter.Unexpander 
-- | `(setOf (λ ($x:ident : $t) => $p)) => `({ $x | $p })
-- | _ => throw ()

-- #check { x | x = 1 }

def compl (s : Set α) := { x | x ∉ s }

postfix:100 "ᶜ " => compl

theorem compl.def (s : Set α) (x) : x ∈ sᶜ ↔ ¬ s x := Iff.rfl

def Subset (s t : Set α) := ∀ x ∈ s, x ∈ t

instance : LE (Set α) := ⟨Subset⟩ 

infix:50 " ⊆ " => Subset

theorem Subset.def {s t : Set α} : s ⊆ t ↔ ∀ x ∈ s, x ∈ t := Iff.rfl

namespace Subset

theorem refl {s : Set α} : s ⊆ s := λ _ hx => hx

theorem trans {s t v : Set α} (hst : s ⊆ t) (htv : t ⊆ v) : s ⊆ v := 
  λ x hx => htv _ (hst x hx)

theorem antisymm {s t : Set α} (hst : s ⊆ t) (hts : t ⊆ s) : s = t := 
  Set.ext λ x => ⟨ λ hx => hst x hx, λ hx => hts x hx ⟩

theorem antisymmIff {s t : Set α} : s = t ↔ s ⊆ t ∧ t ⊆ s :=
  ⟨ by { intro hst; subst hst; exact ⟨ refl, refl ⟩ }, 
    λ ⟨ hst, hts ⟩ => antisymm hst hts ⟩ 

-- ↓ Uses classical logic
theorem notSubset : ¬ s ⊆ t ↔ ∃ x ∈ s, x ∉ t := by 
  apply Iff.intro
  { intro hst; 
    rw [Classical.Exists.notAnd];
    apply Classical.notForall;
    exact λ h => hst λ x hx => h x hx }
  { intro h hst;
    let ⟨ x, ⟨ hxs, hxt ⟩ ⟩ := h;
    exact hxt <| hst x hxs }

end Subset

/-! ## Easy Lemmas-/

theorem memEmptySet {x : α} (h : x ∈ (∅ : Set α)) : False := h

@[simp] theorem memEmptySetIff : (∃ (x : α), x ∈ (∅ : Set α)) ↔ False := 
  Iff.intro (λ h => h.2) False.elim 

@[simp] theorem setOfFalse : { a : α | False } = ∅ := rfl

def univ : Set α := { x | True }

@[simp] theorem memUniv (x : α) : x ∈ (univ : Set α) := True.intro

theorem Subset.empty (s : Set α) : ∅ ⊆ s := λ _ h => False.elim h

theorem Subset.subsetUniv {s : Set α} : s ⊆ univ := λ x _ => memUniv x 

theorem Subset.univSubsetIff {s : Set α} : univ ⊆ s ↔ univ = s := by
  apply Iff.intro λ hs => Subset.antisymm hs Subset.subsetUniv 
  { intro h; subst h; exact Subset.refl }

theorem Subset.singletonIff {s : Set α} : x ∈ s ↔ { x } ⊆ s := 
  Iff.intro 
    (λ h y hy => match hy with 
      | Or.inl hy => False.elim hy
      | Or.inr hy => hy ▸ h) 
    (λ h => h _ <| memSelfSingleton _)

theorem eqUnivIff {s : Set α} : s = univ ↔ ∀ x, x ∈ s := by 
  apply Iff.intro 
  { intro h x; subst h; exact memUniv x }
  { exact λ h => ext λ x => Iff.intro (λ _ => memUniv _) λ _ => h x }

/-! ## Unions and Intersections -/

macro "extia" x:term : tactic => `(tactic| apply ext; intro $x; apply Iff.intro)

theorem unionSelf {s : Set α} : s ∪ s = s := by 
  extia x
  { intro hx; cases hx; assumption; assumption }
  { exact Or.inl }

theorem interSelf {s : Set α} : s ∩ s = s := by 
  extia x
  { intro h; exact h.1 }
  { intro h; exact ⟨ h, h ⟩}

theorem unionEmpty {s : Set α} : s ∪ ∅ = s := by 
  extia x
  { intro hx; cases hx with 
    | inl   => assumption
    | inr h => exact False.elim <| memEmptySet h }
  { exact Or.inl }

theorem unionSymm {s t : Set α} : s ∪ t = t ∪ s := by 
  extia x 
  allGoals { intro hx; cases hx with 
             | inl hx => exact Or.inr hx
             | inr hx => exact Or.inl hx }

theorem emptyunion {s : Set α} : ∅ ∪ s = s := by 
  rw [unionSymm]; exact unionEmpty

theorem unionAssoc {s t w : Set α} : (s ∪ t) ∪ w = s ∪ (t ∪ w) := by 
  extia x
  { intro hx; cases hx with 
    | inr hx   => exact Or.inr <| Or.inr hx
    | inl hx   => cases hx with 
      | inr hx => exact Or.inr <| Or.inl hx
      | inl hx => exact Or.inl hx }
  { intro hx; cases hx with 
    | inl hx   => exact Or.inl <| Or.inl hx
    | inr hx   => cases hx with 
      | inr hx => exact Or.inr hx
      | inl hx => exact Or.inl <| Or.inr hx }

theorem subsetInter {s t u : Set α} (ht : s ⊆ t) (hu : s ⊆ u) : s ⊆ t ∩ u := 
λ x hx => ⟨ ht x hx, hu x hx ⟩

theorem UnionEmpty : Union (base := α) (∅ : Set (Set α)) = ∅ := 
  ext (λ x => Iff.intro (λ ⟨_, h⟩ => False.elim h.1) (λ h => False.elim h))

end Set