(*  Title:      HOL/Extraction/QuotRem.thy
    ID:         $Id$
    Author:     Stefan Berghofer, TU Muenchen
*)

header {* Quotient and remainder *}

theory QuotRem imports Main begin
text {* Derivation of quotient and remainder using program extraction. *}

lemma nat_eq_dec: "\<And>n::nat. m = n \<or> m \<noteq> n"
  apply (induct m)
  apply (case_tac n)
  apply (case_tac [3] n)
  apply (simp only: nat.simps, iprover?)+
  done

theorem division: "\<exists>r q. a = Suc b * q + r \<and> r \<le> b"
proof (induct a)
  case 0
  have "0 = Suc b * 0 + 0 \<and> 0 \<le> b" by simp
  thus ?case by iprover
next
  case (Suc a)
  then obtain r q where I: "a = Suc b * q + r" and "r \<le> b" by iprover
  from nat_eq_dec show ?case
  proof
    assume "r = b"
    with I have "Suc a = Suc b * (Suc q) + 0 \<and> 0 \<le> b" by simp
    thus ?case by iprover
  next
    assume "r \<noteq> b"
    hence "r < b" by (simp add: order_less_le)
    with I have "Suc a = Suc b * q + (Suc r) \<and> (Suc r) \<le> b" by simp
    thus ?case by iprover
  qed
qed

extract division

text {*
  The program extracted from the above proof looks as follows
  @{thm [display] division_def [no_vars]}
  The corresponding correctness theorem is
  @{thm [display] division_correctness [no_vars]}
*}

code_module Div
contains
  test = "division 9 2"

code_gen division (SML -)

end
