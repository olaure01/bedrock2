Local Set Primitive Projections.
Require Import bedrock2.Macros bedrock2.Map.
Require Coq.Lists.List.

(* TODO: move me? *)
Definition minimize_eq_proof{A: Type}(eq_dec: forall (x y: A), {x = y} + {x <> y}){x y: A}    (pf: x = y): x = y :=
  match eq_dec x y with
  | left p => p
  | right n => match n pf: False with end
  end.

Module Import parameters.
  Class parameters := {
    key : Type;
    value : Type;
    key_eqb : key -> key -> bool;
    key_ltb : key -> key -> bool
  }.
End parameters. Notation parameters := parameters.parameters.

Section UnorderedList.
  Context {p : unique! parameters}.
  Fixpoint put m (k:key) (v:value) : list (key * value) :=
    match m with
    | nil => cons (k, v) nil
    | cons (k', v') m' =>
      if key_eqb k k'
      then cons (k, v) m'
      else 
        if key_ltb k k'
        then cons (k, v) m
        else cons (k', v') (put m' k v)
    end.
  Fixpoint sorted (m : list (key * value)) :=
    match m with
    | cons (k1, _) ((cons (k2, _) m'') as m') => andb (key_ltb k1 k2) (sorted m')
    | _ => true
    end.
  Record rep := { value : list (key * value) ; ok : sorted value = true }.
  Lemma sorted_put m k v : sorted m = true -> sorted (put m k v) = true. Admitted.
  Definition map : map key parameters.value :=
    let wrapped_put m k v := Build_rep (put (value m) k v) (minimize_eq_proof Bool.bool_dec (sorted_put _ _ _ (ok m))) in
    {|
    map.rep := rep;
    map.empty := Build_rep nil eq_refl;
    map.get m k := match List.find (fun p => key_eqb k (fst p)) (value m) with
                   | Some (_, v) => Some v
                   | None => None
                   end;
    map.put := wrapped_put;
    map.union m1 m2 := List.fold_right (fun '(k, v) m => wrapped_put m k v) m1 (value m2)
  |}.

  Global Instance map_ok : map.ok map. Admitted.
End UnorderedList.
Arguments map : clear implicits.