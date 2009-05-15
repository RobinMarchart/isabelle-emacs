(* Author: Florian Haftmann, TU Muenchen *)

header {* A simple counterexample generator *}

theory Quickcheck
imports Main Real Random
begin

notation fcomp (infixl "o>" 60)
notation scomp (infixl "o\<rightarrow>" 60)


subsection {* The @{text random} class *}

class random = typerep +
  fixes random :: "index \<Rightarrow> Random.seed \<Rightarrow> ('a \<times> (unit \<Rightarrow> term)) \<times> Random.seed"


subsection {* Quickcheck generator *}

ML {*
structure Quickcheck =
struct

open Quickcheck;

val eval_ref : (unit -> int -> int * int -> term list option * (int * int)) option ref = ref NONE;

val target = "Quickcheck";

fun mk_generator_expr thy prop tys =
  let
    val bound_max = length tys - 1;
    val bounds = map_index (fn (i, ty) =>
      (2 * (bound_max - i) + 1, 2 * (bound_max - i), 2 * i, ty)) tys;
    val result = list_comb (prop, map (fn (i, _, _, _) => Bound i) bounds);
    val terms = HOLogic.mk_list @{typ term} (map (fn (_, i, _, _) => Bound i $ @{term "()"}) bounds);
    val check = @{term "If \<Colon> bool \<Rightarrow> term list option \<Rightarrow> term list option \<Rightarrow> term list option"}
      $ result $ @{term "None \<Colon> term list option"} $ (@{term "Some \<Colon> term list \<Rightarrow> term list option "} $ terms);
    val return = @{term "Pair \<Colon> term list option \<Rightarrow> Random.seed \<Rightarrow> term list option \<times> Random.seed"};
    fun liftT T sT = sT --> HOLogic.mk_prodT (T, sT);
    fun mk_termtyp ty = HOLogic.mk_prodT (ty, @{typ "unit \<Rightarrow> term"});
    fun mk_scomp T1 T2 sT f g = Const (@{const_name scomp},
      liftT T1 sT --> (T1 --> liftT T2 sT) --> liftT T2 sT) $ f $ g;
    fun mk_split ty = Sign.mk_const thy
      (@{const_name split}, [ty, @{typ "unit \<Rightarrow> term"}, liftT @{typ "term list option"} @{typ Random.seed}]);
    fun mk_scomp_split ty t t' =
      mk_scomp (mk_termtyp ty) @{typ "term list option"} @{typ Random.seed} t
        (mk_split ty $ Abs ("", ty, Abs ("", @{typ "unit \<Rightarrow> term"}, t')));
    fun mk_bindclause (_, _, i, ty) = mk_scomp_split ty
      (Sign.mk_const thy (@{const_name random}, [ty]) $ Bound i);
  in Abs ("n", @{typ index}, fold_rev mk_bindclause bounds (return $ check)) end;

fun compile_generator_expr thy t =
  let
    val tys = (map snd o fst o strip_abs) t;
    val t' = mk_generator_expr thy t tys;
    val f = Code_ML.eval (SOME target) ("Quickcheck.eval_ref", eval_ref)
      (fn proc => fn g => fn s => g s #>> (Option.map o map) proc) thy t' [];
  in f #> Random_Engine.run end;

end
*}

setup {*
  Code_Target.extend_target (Quickcheck.target, (Code_ML.target_Eval, K I))
  #> Quickcheck.add_generator ("code", Quickcheck.compile_generator_expr o ProofContext.theory_of)
*}


subsection {* Fundamental types*}

definition (in term_syntax)
  "termify_bool b = (if b then termify True else termify False)"

instantiation bool :: random
begin

definition
  "random i = Random.range i o\<rightarrow> (\<lambda>k. Pair (termify_bool (k div 2 = 0)))"

instance ..

end

definition (in term_syntax)
  "termify_itself TYPE('a\<Colon>typerep) = termify TYPE('a)"

instantiation itself :: (typerep) random
begin

definition random_itself :: "index \<Rightarrow> Random.seed \<Rightarrow> ('a itself \<times> (unit \<Rightarrow> term)) \<times> Random.seed" where
  "random_itself _ = Pair (termify_itself TYPE('a))"

instance ..

end

text {* Type @{typ "'a \<Rightarrow> 'b"} *}

ML {*
structure Random_Engine =
struct

open Random_Engine;

fun random_fun (T1 : typ) (T2 : typ) (eq : 'a -> 'a -> bool) (term_of : 'a -> term)
    (random : Random_Engine.seed -> ('b * (unit -> term)) * Random_Engine.seed)
    (random_split : Random_Engine.seed -> Random_Engine.seed * Random_Engine.seed)
    (seed : Random_Engine.seed) =
  let
    val (seed', seed'') = random_split seed;
    val state = ref (seed', [], Const (@{const_name undefined}, T1 --> T2));
    val fun_upd = Const (@{const_name fun_upd},
      (T1 --> T2) --> T1 --> T2 --> T1 --> T2);
    fun random_fun' x =
      let
        val (seed, fun_map, f_t) = ! state;
      in case AList.lookup (uncurry eq) fun_map x
       of SOME y => y
        | NONE => let
              val t1 = term_of x;
              val ((y, t2), seed') = random seed;
              val fun_map' = (x, y) :: fun_map;
              val f_t' = fun_upd $ f_t $ t1 $ t2 ();
              val _ = state := (seed', fun_map', f_t');
            in y end
      end;
    fun term_fun' () = #3 (! state);
  in ((random_fun', term_fun'), seed'') end;

end
*}

axiomatization random_fun_aux :: "typerep \<Rightarrow> typerep \<Rightarrow> ('a \<Rightarrow> 'a \<Rightarrow> bool) \<Rightarrow> ('a \<Rightarrow> term)
  \<Rightarrow> (Random.seed \<Rightarrow> ('b \<times> (unit \<Rightarrow> term)) \<times> Random.seed) \<Rightarrow> (Random.seed \<Rightarrow> Random.seed \<times> Random.seed)
  \<Rightarrow> Random.seed \<Rightarrow> (('a \<Rightarrow> 'b) \<times> (unit \<Rightarrow> term)) \<times> Random.seed"

code_const random_fun_aux (Quickcheck "Random'_Engine.random'_fun")
  -- {* With enough criminal energy this can be abused to derive @{prop False};
  for this reason we use a distinguished target @{text Quickcheck}
  not spoiling the regular trusted code generation *}

instantiation "fun" :: ("{eq, term_of}", "{type, random}") random
begin

definition random_fun :: "index \<Rightarrow> Random.seed \<Rightarrow> (('a \<Rightarrow> 'b) \<times> (unit \<Rightarrow> term)) \<times> Random.seed" where
  "random n = random_fun_aux TYPEREP('a) TYPEREP('b) (op =) Code_Eval.term_of (random n) Random.split_seed"

instance ..

end

code_reserved Quickcheck Random_Engine


subsection {* Numeric types *}

function (in term_syntax) termify_numeral :: "index \<Rightarrow> int \<times> (unit \<Rightarrow> term)" where
  "termify_numeral k = (if k = 0 then termify Int.Pls
    else (if k mod 2 = 0 then termify Int.Bit0 else termify Int.Bit1) <\<cdot>> termify_numeral (k div 2))"
  by pat_completeness auto

declare (in term_syntax) termify_numeral.psimps [simp del]

termination termify_numeral by (relation "measure Code_Index.nat_of")
  (simp_all add: index)

definition (in term_syntax) termify_int_number :: "index \<Rightarrow> int \<times> (unit \<Rightarrow> term)" where
  "termify_int_number k = termify number_of <\<cdot>> termify_numeral k"

definition (in term_syntax) termify_nat_number :: "index \<Rightarrow> nat \<times> (unit \<Rightarrow> term)" where
  "termify_nat_number k = (nat \<circ> number_of, snd (termify (number_of :: int \<Rightarrow> nat))) <\<cdot>> termify_numeral k"

declare termify_nat_number_def [simplified snd_conv, code]

instantiation nat :: random
begin

definition random_nat :: "index \<Rightarrow> Random.seed \<Rightarrow> (nat \<times> (unit \<Rightarrow> term)) \<times> Random.seed" where
  "random_nat i = Random.range (i + 1) o\<rightarrow> (\<lambda>k. Pair (termify_nat_number k))"

instance ..

end

definition (in term_syntax) term_uminus :: "int \<times> (unit \<Rightarrow> term) \<Rightarrow> int \<times> (unit \<Rightarrow> term)" where
  [code inline]: "term_uminus k = termify uminus <\<cdot>> k"

instantiation int :: random
begin

definition
  "random i = Random.range (2 * i + 1) o\<rightarrow> (\<lambda>k. Pair (if k \<ge> i
     then let j = k - i in termify_int_number j
     else let j = i - k in term_uminus (termify_int_number j)))"

instance ..

end

definition (in term_syntax) term_fract :: "int \<times> (unit \<Rightarrow> term) \<Rightarrow> int \<times> (unit \<Rightarrow> term) \<Rightarrow> rat \<times> (unit \<Rightarrow> term)" where
  [code inline]: "term_fract k l = termify Fract <\<cdot>> k <\<cdot>> l"

instantiation rat :: random
begin

definition
  "random i = random i o\<rightarrow> (\<lambda>num. Random.range (i + 1) o\<rightarrow> (\<lambda>denom. Pair (term_fract num (termify_int_number denom))))"

instance ..

end

definition (in term_syntax) term_ratreal :: "rat \<times> (unit \<Rightarrow> term) \<Rightarrow> real \<times> (unit \<Rightarrow> term)" where
  [code inline]: "term_ratreal k = termify Ratreal <\<cdot>> k"

instantiation real :: random
begin

definition
  "random i = random i o\<rightarrow> (\<lambda>r. Pair (term_ratreal r))"

instance ..

end


no_notation fcomp (infixl "o>" 60)
no_notation scomp (infixl "o\<rightarrow>" 60)

end
