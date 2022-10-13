(*  Title:      HOL/Auth/Guard/Proto.thy
    Author:     Frederic Blanqui, University of Cambridge Computer Laboratory
    Copyright   2002  University of Cambridge
*)

section\<open>Other Protocol-Independent Results\<close>

theory Proto imports Guard_Public begin

subsection\<open>protocols\<close>

type_synonym rule = "event set * event"

abbreviation
  msg' :: "rule => msg" where
  "msg' R == msg (snd R)"

type_synonym proto = "rule set"

definition wdef :: "proto => bool" where
"wdef p \<equiv> \<forall>R k. R \<in> p \<longrightarrow> Number k \<in> parts {msg' R}
\<longrightarrow> Number k \<in> parts (msg`(fst R))"

subsection\<open>substitutions\<close>

record subs =
  agent   :: "agent => agent"
  nonce :: "nat => nat"
  nb    :: "nat => msg"
  key   :: "key => key"

primrec apm :: "subs => msg => msg" where
  "apm s (Agent A) = Agent (agent s A)"
| "apm s (Nonce n) = Nonce (nonce s n)"
| "apm s (Number n) = nb s n"
| "apm s (Key K) = Key (key s K)"
| "apm s (Hash X) = Hash (apm s X)"
| "apm s (Crypt K X) = (
if (\<exists>A. K = pubK A) then Crypt (pubK (agent s (agt K))) (apm s X)
else if (\<exists>A. K = priK A) then Crypt (priK (agent s (agt K))) (apm s X)
else Crypt (key s K) (apm s X))"
| "apm s \<lbrace>X,Y\<rbrace> = \<lbrace>apm s X, apm s Y\<rbrace>"

lemma apm_parts: "X \<in> parts {Y} \<Longrightarrow> apm s X \<in> parts {apm s Y}"
apply (erule parts.induct, simp_all, blast)
apply (erule parts.Fst)
apply (erule parts.Snd)
by (erule parts.Body)+

lemma Nonce_apm [rule_format]: "Nonce n \<in> parts {apm s X} \<Longrightarrow>
(\<forall>k. Number k \<in> parts {X} \<longrightarrow> Nonce n \<notin> parts {nb s k}) \<longrightarrow>
(\<exists>k. Nonce k \<in> parts {X} \<and> nonce s k = n)"
by (induct X, simp_all, blast)

lemma wdef_Nonce: "\<lbrakk>Nonce n \<in> parts {apm s X}; R \<in> p; msg' R = X; wdef p;
Nonce n \<notin> parts (apm s `(msg `(fst R)))\<rbrakk> \<Longrightarrow>
(\<exists>k. Nonce k \<in> parts {X} \<and> nonce s k = n)"
apply (erule Nonce_apm, unfold wdef_def)
apply (drule_tac x=R in spec, drule_tac x=k in spec, clarsimp)
apply (drule_tac x=x in bspec, simp)
apply (drule_tac Y="msg x" and s=s in apm_parts, simp)
by (blast dest: parts_parts)

primrec ap :: "subs \<Rightarrow> event \<Rightarrow> event" where
  "ap s (Says A B X) = Says (agent s A) (agent s B) (apm s X)"
| "ap s (Gets A X) = Gets (agent s A) (apm s X)"
| "ap s (Notes A X) = Notes (agent s A) (apm s X)"

abbreviation
  ap' :: "subs \<Rightarrow> rule \<Rightarrow> event" where
  "ap' s R \<equiv> ap s (snd R)"

abbreviation
  apm' :: "subs \<Rightarrow> rule \<Rightarrow> msg" where
  "apm' s R \<equiv> apm s (msg' R)"

abbreviation
  priK' :: "subs \<Rightarrow> agent \<Rightarrow> key" where
  "priK' s A \<equiv> priK (agent s A)"

abbreviation
  pubK' :: "subs \<Rightarrow> agent \<Rightarrow> key" where
  "pubK' s A \<equiv> pubK (agent s A)"

subsection\<open>nonces generated by a rule\<close>

definition newn :: "rule \<Rightarrow> nat set" where
"newn R \<equiv> {n. Nonce n \<in> parts {msg (snd R)} \<and> Nonce n \<notin> parts (msg`(fst R))}"

lemma newn_parts: "n \<in> newn R \<Longrightarrow> Nonce (nonce s n) \<in> parts {apm' s R}"
by (auto simp: newn_def dest: apm_parts)

subsection\<open>traces generated by a protocol\<close>

definition ok :: "event list \<Rightarrow> rule \<Rightarrow> subs \<Rightarrow> bool" where
"ok evs R s \<equiv> ((\<forall>x. x \<in> fst R \<longrightarrow> ap s x \<in> set evs)
\<and> (\<forall>n. n \<in> newn R \<longrightarrow> Nonce (nonce s n) \<notin> used evs))"

inductive_set
  tr :: "proto => event list set"
  for p :: proto
where

  Nil [intro]: "[] \<in> tr p"

| Fake [intro]: "\<lbrakk>evsf \<in> tr p; X \<in> synth (analz (spies evsf))\<rbrakk>
  \<Longrightarrow> Says Spy B X # evsf \<in> tr p"

| Proto [intro]: "\<lbrakk>evs \<in> tr p; R \<in> p; ok evs R s\<rbrakk> \<Longrightarrow> ap' s R # evs \<in> tr p"

subsection\<open>general properties\<close>

lemma one_step_tr [iff]: "one_step (tr p)"
apply (unfold one_step_def, clarify)
by (ind_cases "ev # evs \<in> tr p" for ev evs, auto)

definition has_only_Says' :: "proto => bool" where
"has_only_Says' p \<equiv> \<forall>R. R \<in> p \<longrightarrow> is_Says (snd R)"

lemma has_only_Says'D: "\<lbrakk>R \<in> p; has_only_Says' p\<rbrakk>
\<Longrightarrow> (\<exists>A B X. snd R = Says A B X)"
by (unfold has_only_Says'_def is_Says_def, blast)

lemma has_only_Says_tr [simp]: "has_only_Says' p \<Longrightarrow> has_only_Says (tr p)"
apply (unfold has_only_Says_def)
apply (rule allI, rule allI, rule impI)
apply (erule tr.induct)
apply (auto simp: has_only_Says'_def ok_def)
by (drule_tac x=a in spec, auto simp: is_Says_def)

lemma has_only_Says'_in_trD: "\<lbrakk>has_only_Says' p; list @ ev # evs1 \<in> tr p\<rbrakk>
\<Longrightarrow> (\<exists>A B X. ev = Says A B X)"
by (drule has_only_Says_tr, auto)

lemma ok_not_used: "\<lbrakk>Nonce n \<notin> used evs; ok evs R s;
\<forall>x. x \<in> fst R \<longrightarrow> is_Says x\<rbrakk> \<Longrightarrow> Nonce n \<notin> parts (apm s `(msg `(fst R)))"
apply (unfold ok_def, clarsimp)
apply (drule_tac x=x in spec, drule_tac x=x in spec)
by (auto simp: is_Says_def dest: Says_imp_spies not_used_not_spied parts_parts)

lemma ok_is_Says: "\<lbrakk>evs' @ ev # evs \<in> tr p; ok evs R s; has_only_Says' p;
R \<in> p; x \<in> fst R\<rbrakk> \<Longrightarrow> is_Says x"
apply (unfold ok_def is_Says_def, clarify)
apply (drule_tac x=x in spec, simp)
apply (subgoal_tac "one_step (tr p)")
apply (drule trunc, simp, drule one_step_Cons, simp)
apply (drule has_only_SaysD, simp+)
by (clarify, case_tac x, auto)

subsection\<open>types\<close>

type_synonym keyfun = "rule \<Rightarrow> subs \<Rightarrow> nat \<Rightarrow> event list \<Rightarrow> key set"

type_synonym secfun = "rule \<Rightarrow> nat \<Rightarrow> subs \<Rightarrow> key set \<Rightarrow> msg"

subsection\<open>introduction of a fresh guarded nonce\<close>

definition fresh :: "proto \<Rightarrow> rule \<Rightarrow> subs \<Rightarrow> nat \<Rightarrow> key set \<Rightarrow> event list
\<Rightarrow> bool" where
"fresh p R s n Ks evs \<equiv> (\<exists>evs1 evs2. evs = evs2 @ ap' s R # evs1
\<and> Nonce n \<notin> used evs1 \<and> R \<in> p \<and> ok evs1 R s \<and> Nonce n \<in> parts {apm' s R}
\<and> apm' s R \<in> guard n Ks)"

lemma freshD: "fresh p R s n Ks evs \<Longrightarrow> (\<exists>evs1 evs2.
evs = evs2 @ ap' s R # evs1 \<and> Nonce n \<notin> used evs1 \<and> R \<in> p \<and> ok evs1 R s
\<and> Nonce n \<in> parts {apm' s R} \<and> apm' s R \<in> guard n Ks)"
  unfolding fresh_def by (blast)

lemma freshI [intro]: "\<lbrakk>Nonce n \<notin> used evs1; R \<in> p; Nonce n \<in> parts {apm' s R};
ok evs1 R s; apm' s R \<in> guard n Ks\<rbrakk>
\<Longrightarrow> fresh p R s n Ks (list @ ap' s R # evs1)"
  unfolding fresh_def by (blast)

lemma freshI': "\<lbrakk>Nonce n \<notin> used evs1; (l,r) \<in> p;
Nonce n \<in> parts {apm s (msg r)}; ok evs1 (l,r) s; apm s (msg r) \<in> guard n Ks\<rbrakk>
\<Longrightarrow> fresh p (l,r) s n Ks (evs2 @ ap s r # evs1)"
by (drule freshI, simp+)

lemma fresh_used: "\<lbrakk>fresh p R' s' n Ks evs; has_only_Says' p\<rbrakk>
\<Longrightarrow> Nonce n \<in> used evs"
apply (unfold fresh_def, clarify)
apply (drule has_only_Says'D)
by (auto intro: parts_used_app)

lemma fresh_newn: "\<lbrakk>evs' @ ap' s R # evs \<in> tr p; wdef p; has_only_Says' p;
Nonce n \<notin> used evs; R \<in> p; ok evs R s; Nonce n \<in> parts {apm' s R}\<rbrakk>
\<Longrightarrow> \<exists>k. k \<in> newn R \<and> nonce s k = n"
apply (drule wdef_Nonce, simp+)
apply (frule ok_not_used, simp+)
apply (clarify, erule ok_is_Says, simp+)
apply (clarify, rule_tac x=k in exI, simp add: newn_def)
apply (clarify, drule_tac Y="msg x" and s=s in apm_parts)
apply (drule ok_not_used, simp+)
by (clarify, erule ok_is_Says, simp_all)

lemma fresh_rule: "\<lbrakk>evs' @ ev # evs \<in> tr p; wdef p; Nonce n \<notin> used evs;
Nonce n \<in> parts {msg ev}\<rbrakk> \<Longrightarrow> \<exists>R s. R \<in> p \<and> ap' s R = ev"
apply (drule trunc, simp, ind_cases "ev # evs \<in> tr p", simp)
by (drule_tac x=X in in_sub, drule parts_sub, simp, simp, blast+)

lemma fresh_ruleD: "\<lbrakk>fresh p R' s' n Ks evs; keys R' s' n evs \<subseteq> Ks; wdef p;
has_only_Says' p; evs \<in> tr p; \<forall>R k s. nonce s k = n \<longrightarrow> Nonce n \<in> used evs \<longrightarrow>
R \<in> p \<longrightarrow> k \<in> newn R \<longrightarrow> Nonce n \<in> parts {apm' s R} \<longrightarrow> apm' s R \<in> guard n Ks \<longrightarrow>
apm' s R \<in> parts (spies evs) \<longrightarrow> keys R s n evs \<subseteq> Ks \<longrightarrow> P\<rbrakk> \<Longrightarrow> P"
apply (frule fresh_used, simp)
apply (unfold fresh_def, clarify)
apply (drule_tac x=R' in spec)
apply (drule fresh_newn, simp+, clarify)
apply (drule_tac x=k in spec)
apply (drule_tac x=s' in spec)
apply (subgoal_tac "apm' s' R' \<in> parts (spies (evs2 @ ap' s' R' # evs1))")
apply (case_tac R', drule has_only_Says'D, simp, clarsimp)
apply (case_tac R', drule has_only_Says'D, simp, clarsimp)
apply (rule_tac Y="apm s' X" in parts_parts, blast)
by (rule parts.Inj, rule Says_imp_spies, simp, blast)

subsection\<open>safe keys\<close>

definition safe :: "key set \<Rightarrow> msg set \<Rightarrow> bool" where
"safe Ks G \<equiv> \<forall>K. K \<in> Ks \<longrightarrow> Key K \<notin> analz G"

lemma safeD [dest]: "\<lbrakk>safe Ks G; K \<in> Ks\<rbrakk> \<Longrightarrow> Key K \<notin> analz G"
  unfolding safe_def by (blast)

lemma safe_insert: "safe Ks (insert X G) \<Longrightarrow> safe Ks G"
  unfolding safe_def by (blast)

lemma Guard_safe: "\<lbrakk>Guard n Ks G; safe Ks G\<rbrakk> \<Longrightarrow> Nonce n \<notin> analz G"
by (blast dest: Guard_invKey)

subsection\<open>guardedness preservation\<close>

definition preserv :: "proto \<Rightarrow> keyfun \<Rightarrow> nat \<Rightarrow> key set \<Rightarrow> bool" where
"preserv p keys n Ks \<equiv> (\<forall>evs R' s' R s. evs \<in> tr p \<longrightarrow>
Guard n Ks (spies evs) \<longrightarrow> safe Ks (spies evs) \<longrightarrow> fresh p R' s' n Ks evs \<longrightarrow>
keys R' s' n evs \<subseteq> Ks \<longrightarrow> R \<in> p \<longrightarrow> ok evs R s \<longrightarrow> apm' s R \<in> guard n Ks)"

lemma preservD: "\<lbrakk>preserv p keys n Ks; evs \<in> tr p; Guard n Ks (spies evs);
safe Ks (spies evs); fresh p R' s' n Ks evs; R \<in> p; ok evs R s;
keys R' s' n evs \<subseteq> Ks\<rbrakk> \<Longrightarrow> apm' s R \<in> guard n Ks"
  unfolding preserv_def by (blast)

lemma preservD': "\<lbrakk>preserv p keys n Ks; evs \<in> tr p; Guard n Ks (spies evs);
safe Ks (spies evs); fresh p R' s' n Ks evs; (l,Says A B X) \<in> p;
ok evs (l,Says A B X) s; keys R' s' n evs \<subseteq> Ks\<rbrakk> \<Longrightarrow> apm s X \<in> guard n Ks"
by (drule preservD, simp+)

subsection\<open>monotonic keyfun\<close>

definition monoton :: "proto => keyfun => bool" where
"monoton p keys \<equiv> \<forall>R' s' n ev evs. ev # evs \<in> tr p \<longrightarrow>
keys R' s' n evs \<subseteq> keys R' s' n (ev # evs)"

lemma monotonD [dest]: "\<lbrakk>keys R' s' n (ev # evs) \<subseteq> Ks; monoton p keys;
ev # evs \<in> tr p\<rbrakk> \<Longrightarrow> keys R' s' n evs \<subseteq> Ks"
  unfolding monoton_def by (blast)

subsection\<open>guardedness theorem\<close>

lemma Guard_tr [rule_format]: "\<lbrakk>evs \<in> tr p; has_only_Says' p;
preserv p keys n Ks; monoton p keys; Guard n Ks (initState Spy)\<rbrakk> \<Longrightarrow>
safe Ks (spies evs) \<longrightarrow> fresh p R' s' n Ks evs \<longrightarrow> keys R' s' n evs \<subseteq> Ks \<longrightarrow>
Guard n Ks (spies evs)"
apply (erule tr.induct)
(* Nil *)
apply simp
(* Fake *)
apply (clarify, drule freshD, clarsimp)
apply (case_tac evs2)
(* evs2 = [] *)
apply (frule has_only_Says'D, simp)
apply (clarsimp, blast)
(* evs2 = aa # list *)
apply (clarsimp, rule conjI)
apply (blast dest: safe_insert)
(* X:guard n Ks *)
apply (rule in_synth_Guard, simp, rule Guard_analz)
apply (blast dest: safe_insert)
apply (drule safe_insert, simp add: safe_def)
(* Proto *)
apply (clarify, drule freshD, clarify)
apply (case_tac evs2)
(* evs2 = [] *)
apply (frule has_only_Says'D, simp)
apply (frule_tac R=R' in has_only_Says'D, simp)
apply (case_tac R', clarsimp, blast)
(* evs2 = ab # list *)
apply (frule has_only_Says'D, simp)
apply (clarsimp, rule conjI)
apply (drule Proto, simp+, blast dest: safe_insert)
(* apm s X:guard n Ks *)
apply (frule Proto, simp+)
apply (erule preservD', simp+)
apply (blast dest: safe_insert)
apply (blast dest: safe_insert)
by (blast, simp, simp, blast)

subsection\<open>useful properties for guardedness\<close>

lemma newn_neq_used: "\<lbrakk>Nonce n \<in> used evs; ok evs R s; k \<in> newn R\<rbrakk>
\<Longrightarrow> n \<noteq> nonce s k"
by (auto simp: ok_def)

lemma ok_Guard: "\<lbrakk>ok evs R s; Guard n Ks (spies evs); x \<in> fst R; is_Says x\<rbrakk>
\<Longrightarrow> apm s (msg x) \<in> parts (spies evs) \<and> apm s (msg x) \<in> guard n Ks"
apply (unfold ok_def is_Says_def, clarify)
apply (drule_tac x="Says A B X" in spec, simp)
by (drule Says_imp_spies, auto intro: parts_parts)

lemma ok_parts_not_new: "\<lbrakk>Y \<in> parts (spies evs); Nonce (nonce s n) \<in> parts {Y};
ok evs R s\<rbrakk> \<Longrightarrow> n \<notin> newn R"
by (auto simp: ok_def dest: not_used_not_spied parts_parts)

subsection\<open>unicity\<close>

definition uniq :: "proto \<Rightarrow> secfun \<Rightarrow> bool" where
"uniq p secret \<equiv> \<forall>evs R R' n n' Ks s s'. R \<in> p \<longrightarrow> R' \<in> p \<longrightarrow>
n \<in> newn R \<longrightarrow> n' \<in> newn R' \<longrightarrow> nonce s n = nonce s' n' \<longrightarrow>
Nonce (nonce s n) \<in> parts {apm' s R} \<longrightarrow> Nonce (nonce s n) \<in> parts {apm' s' R'} \<longrightarrow>
apm' s R \<in> guard (nonce s n) Ks \<longrightarrow> apm' s' R' \<in> guard (nonce s n) Ks \<longrightarrow>
evs \<in> tr p \<longrightarrow> Nonce (nonce s n) \<notin> analz (spies evs) \<longrightarrow>
secret R n s Ks \<in> parts (spies evs) \<longrightarrow> secret R' n' s' Ks \<in> parts (spies evs) \<longrightarrow>
secret R n s Ks = secret R' n' s' Ks"

lemma uniqD: "\<lbrakk>uniq p secret; evs \<in> tr p; R \<in> p; R' \<in> p; n \<in> newn R; n' \<in> newn R';
nonce s n = nonce s' n'; Nonce (nonce s n) \<notin> analz (spies evs);
Nonce (nonce s n) \<in> parts {apm' s R}; Nonce (nonce s n) \<in> parts {apm' s' R'};
secret R n s Ks \<in> parts (spies evs); secret R' n' s' Ks \<in> parts (spies evs);
apm' s R \<in> guard (nonce s n) Ks; apm' s' R' \<in> guard (nonce s n) Ks\<rbrakk> \<Longrightarrow>
secret R n s Ks = secret R' n' s' Ks"
  unfolding uniq_def by (blast)

definition ord :: "proto \<Rightarrow> (rule \<Rightarrow> rule \<Rightarrow> bool) \<Rightarrow> bool" where
"ord p inff \<equiv> \<forall>R R'. R \<in> p \<longrightarrow> R' \<in> p \<longrightarrow> \<not> inff R R' \<longrightarrow> inff R' R"

lemma ordD: "\<lbrakk>ord p inff; \<not> inff R R'; R \<in> p; R' \<in> p\<rbrakk> \<Longrightarrow> inff R' R"
  unfolding ord_def by (blast)

definition uniq' :: "proto \<Rightarrow> (rule \<Rightarrow> rule \<Rightarrow> bool) \<Rightarrow> secfun \<Rightarrow> bool" where
"uniq' p inff secret \<equiv> \<forall>evs R R' n n' Ks s s'. R \<in> p \<longrightarrow> R' \<in> p \<longrightarrow>
inff R R' \<longrightarrow> n \<in> newn R \<longrightarrow> n' \<in> newn R' \<longrightarrow> nonce s n = nonce s' n' \<longrightarrow>
Nonce (nonce s n) \<in> parts {apm' s R} \<longrightarrow> Nonce (nonce s n) \<in> parts {apm' s' R'} \<longrightarrow>
apm' s R \<in> guard (nonce s n) Ks \<longrightarrow> apm' s' R' \<in> guard (nonce s n) Ks \<longrightarrow>
evs \<in> tr p \<longrightarrow> Nonce (nonce s n) \<notin> analz (spies evs) \<longrightarrow>
secret R n s Ks \<in> parts (spies evs) \<longrightarrow> secret R' n' s' Ks \<in> parts (spies evs) \<longrightarrow>
secret R n s Ks = secret R' n' s' Ks"

lemma uniq'D: "\<lbrakk>uniq' p inff secret; evs \<in> tr p; inff R R'; R \<in> p; R' \<in> p; n \<in> newn R;
n' \<in> newn R'; nonce s n = nonce s' n'; Nonce (nonce s n) \<notin> analz (spies evs);
Nonce (nonce s n) \<in> parts {apm' s R}; Nonce (nonce s n) \<in> parts {apm' s' R'};
secret R n s Ks \<in> parts (spies evs); secret R' n' s' Ks \<in> parts (spies evs);
apm' s R \<in> guard (nonce s n) Ks; apm' s' R' \<in> guard (nonce s n) Ks\<rbrakk> \<Longrightarrow>
secret R n s Ks = secret R' n' s' Ks"
by (unfold uniq'_def, blast)

lemma uniq'_imp_uniq: "\<lbrakk>uniq' p inff secret; ord p inff\<rbrakk> \<Longrightarrow> uniq p secret"
apply (unfold uniq_def)
apply (rule allI)+
apply (case_tac "inff R R'")
apply (blast dest: uniq'D)
by (auto dest: ordD uniq'D intro: sym)

subsection\<open>Needham-Schroeder-Lowe\<close>

definition a :: agent where "a == Friend 0"
definition b :: agent where "b == Friend 1"
definition a' :: agent where "a' == Friend 2"
definition b' :: agent where "b' == Friend 3"
definition Na :: nat where "Na == 0"
definition Nb :: nat where "Nb == 1"

abbreviation
  ns1 :: rule where
  "ns1 == ({}, Says a b (Crypt (pubK b) \<lbrace>Nonce Na, Agent a\<rbrace>))"

abbreviation
  ns2 :: rule where
  "ns2 == ({Says a' b (Crypt (pubK b) \<lbrace>Nonce Na, Agent a\<rbrace>)},
    Says b a (Crypt (pubK a) \<lbrace>Nonce Na, Nonce Nb, Agent b\<rbrace>))"

abbreviation
  ns3 :: rule where
  "ns3 == ({Says a b (Crypt (pubK b) \<lbrace>Nonce Na, Agent a\<rbrace>),
    Says b' a (Crypt (pubK a) \<lbrace>Nonce Na, Nonce Nb, Agent b\<rbrace>)},
    Says a b (Crypt (pubK b) (Nonce Nb)))"

inductive_set ns :: proto where
  [iff]: "ns1 \<in> ns"
| [iff]: "ns2 \<in> ns"
| [iff]: "ns3 \<in> ns"

abbreviation (input)
  ns3a :: event where
  "ns3a == Says a b (Crypt (pubK b) \<lbrace>Nonce Na, Agent a\<rbrace>)"

abbreviation (input)
  ns3b :: event where
  "ns3b == Says b' a (Crypt (pubK a) \<lbrace>Nonce Na, Nonce Nb, Agent b\<rbrace>)"

definition keys :: "keyfun" where
"keys R' s' n evs == {priK' s' a, priK' s' b}"

lemma "monoton ns keys"
by (simp add: keys_def monoton_def)

definition secret :: "secfun" where
"secret R n s Ks ==
(if R=ns1 then apm s (Crypt (pubK b) \<lbrace>Nonce Na, Agent a\<rbrace>)
else if R=ns2 then apm s (Crypt (pubK a) \<lbrace>Nonce Na, Nonce Nb, Agent b\<rbrace>)
else Number 0)"

definition inf :: "rule => rule => bool" where
"inf R R' == (R=ns1 | (R=ns2 & R'~=ns1) | (R=ns3 & R'=ns3))"

lemma inf_is_ord [iff]: "ord ns inf"
apply (unfold ord_def inf_def)
apply (rule allI)+
apply (rule impI)
apply (simp add: split_paired_all)
by (rule impI, erule ns.cases, simp_all)+

subsection\<open>general properties\<close>

lemma ns_has_only_Says' [iff]: "has_only_Says' ns"
apply (unfold has_only_Says'_def)
apply (rule allI, rule impI)
apply (simp add: split_paired_all)
by (erule ns.cases, auto)

lemma newn_ns1 [iff]: "newn ns1 = {Na}"
by (simp add: newn_def)

lemma newn_ns2 [iff]: "newn ns2 = {Nb}"
by (auto simp: newn_def Na_def Nb_def)

lemma newn_ns3 [iff]: "newn ns3 = {}"
by (auto simp: newn_def)

lemma ns_wdef [iff]: "wdef ns"
by (auto simp: wdef_def elim: ns.cases)

subsection\<open>guardedness for NSL\<close>

lemma "uniq ns secret \<Longrightarrow> preserv ns keys n Ks"
apply (unfold preserv_def)
apply (rule allI)+
apply (rule impI, rule impI, rule impI, rule impI, rule impI)
apply (erule fresh_ruleD, simp, simp, simp, simp)
apply (rule allI)+
apply (rule impI, rule impI, rule impI)
apply (simp add: split_paired_all)
apply (erule ns.cases)
(* fresh with NS1 *)
apply (rule impI, rule impI, rule impI, rule impI, rule impI, rule impI)
apply (erule ns.cases)
(* NS1 *)
apply clarsimp
apply (frule newn_neq_used, simp, simp)
apply (rule No_Nonce, simp)
(* NS2 *)
apply clarsimp
apply (frule newn_neq_used, simp, simp)
apply (case_tac "nonce sa Na = nonce s Na")
apply (frule Guard_safe, simp)
apply (frule Crypt_guard_invKey, simp)
apply (frule ok_Guard, simp, simp, simp, clarsimp)
apply (frule_tac K="pubK' s b" in Crypt_guard_invKey, simp)
apply (frule_tac R=ns1 and R'=ns1 and Ks=Ks and s=sa and s'=s in uniqD, simp+)
apply (simp add: secret_def, simp add: secret_def, force, force)
apply (simp add: secret_def keys_def, blast)
apply (rule No_Nonce, simp)
(* NS3 *)
apply clarsimp
apply (case_tac "nonce sa Na = nonce s Nb")
apply (frule Guard_safe, simp)
apply (frule Crypt_guard_invKey, simp)
apply (frule_tac x=ns3b in ok_Guard, simp, simp, simp, clarsimp)
apply (frule_tac K="pubK' s a" in Crypt_guard_invKey, simp)
apply (frule_tac R=ns1 and R'=ns2 and Ks=Ks and s=sa and s'=s in uniqD, simp+)
apply (simp add: secret_def, simp add: secret_def, force, force)
apply (simp add: secret_def, rule No_Nonce, simp)
(* fresh with NS2 *)
apply (rule impI, rule impI, rule impI, rule impI, rule impI, rule impI)
apply (erule ns.cases)
(* NS1 *)
apply clarsimp
apply (frule newn_neq_used, simp, simp)
apply (rule No_Nonce, simp)
(* NS2 *)
apply clarsimp
apply (frule newn_neq_used, simp, simp)
apply (case_tac "nonce sa Nb = nonce s Na")
apply (frule Guard_safe, simp)
apply (frule Crypt_guard_invKey, simp)
apply (frule ok_Guard, simp, simp, simp, clarsimp)
apply (frule_tac K="pubK' s b" in Crypt_guard_invKey, simp)
apply (frule_tac R=ns2 and R'=ns1 and Ks=Ks and s=sa and s'=s in uniqD, simp+)
apply (simp add: secret_def, simp add: secret_def, force, force)
apply (simp add: secret_def, rule No_Nonce, simp)
(* NS3 *)
apply clarsimp
apply (case_tac "nonce sa Nb = nonce s Nb")
apply (frule Guard_safe, simp)
apply (frule Crypt_guard_invKey, simp)
apply (frule_tac x=ns3b in ok_Guard, simp, simp, simp, clarsimp)
apply (frule_tac K="pubK' s a" in Crypt_guard_invKey, simp)
apply (frule_tac R=ns2 and R'=ns2 and Ks=Ks and s=sa and s'=s in uniqD, simp+)
apply (simp add: secret_def, simp add: secret_def, force, force)
apply (simp add: secret_def keys_def, blast)
apply (rule No_Nonce, simp)
(* fresh with NS3 *)
by simp

subsection\<open>unicity for NSL\<close>

lemma "uniq' ns inf secret"
apply (unfold uniq'_def)
apply (rule allI)+
apply (simp add: split_paired_all)
apply (rule impI, erule ns.cases)
(* R = ns1 *)
apply (rule impI, erule ns.cases)
(* R' = ns1 *)
apply (rule impI, rule impI, rule impI, rule impI)
apply (rule impI, rule impI, rule impI, rule impI)
apply (rule impI, erule tr.induct)
(* Nil *)
apply (simp add: secret_def)
(* Fake *)
apply (clarify, simp add: secret_def)
apply (drule notin_analz_insert)
apply (drule Crypt_insert_synth, simp, simp, simp)
apply (drule Crypt_insert_synth, simp, simp, simp, simp)
(* Proto *)
apply (erule_tac P="ok evsa R sa" in rev_mp)
apply (simp add: split_paired_all)
apply (erule ns.cases)
(* ns1 *)
apply (clarify, simp add: secret_def)
apply (erule disjE, erule disjE, clarsimp)
apply (drule ok_parts_not_new, simp, simp, simp)
apply (clarify, drule ok_parts_not_new, simp, simp, simp)
(* ns2 *)
apply (simp add: secret_def)
(* ns3 *)
apply (simp add: secret_def)
(* R' = ns2 *)
apply (rule impI, rule impI, rule impI, rule impI)
apply (rule impI, rule impI, rule impI, rule impI)
apply (rule impI, erule tr.induct)
(* Nil *)
apply (simp add: secret_def)
(* Fake *)
apply (clarify, simp add: secret_def)
apply (drule notin_analz_insert)
apply (drule Crypt_insert_synth, simp, simp, simp)
apply (drule_tac n="nonce s' Nb" in Crypt_insert_synth, simp, simp, simp, simp)
(* Proto *)
apply (erule_tac P="ok evsa R sa" in rev_mp)
apply (simp add: split_paired_all)
apply (erule ns.cases)
(* ns1 *)
apply (clarify, simp add: secret_def)
apply (drule_tac s=sa and n=Na in ok_parts_not_new, simp, simp, simp)
(* ns2 *)
apply (clarify, simp add: secret_def)
apply (drule_tac s=sa and n=Nb in ok_parts_not_new, simp, simp, simp)
(* ns3 *)
apply (simp add: secret_def)
(* R' = ns3 *)
apply simp
(* R = ns2 *)
apply (rule impI, erule ns.cases)
(* R' = ns1 *)
apply (simp only: inf_def, blast)
(* R' = ns2 *)
apply (rule impI, rule impI, rule impI, rule impI)
apply (rule impI, rule impI, rule impI, rule impI)
apply (rule impI, erule tr.induct)
(* Nil *)
apply (simp add: secret_def)
(* Fake *)
apply (clarify, simp add: secret_def)
apply (drule notin_analz_insert)
apply (drule_tac n="nonce s' Nb" in Crypt_insert_synth, simp, simp, simp)
apply (drule_tac n="nonce s' Nb" in Crypt_insert_synth, simp, simp, simp, simp)
(* Proto *)
apply (erule_tac P="ok evsa R sa" in rev_mp)
apply (simp add: split_paired_all)
apply (erule ns.cases)
(* ns1 *)
apply (simp add: secret_def)
(* ns2 *)
apply (clarify, simp add: secret_def)
apply (erule disjE, erule disjE, clarsimp, clarsimp)
apply (drule_tac s=sa and n=Nb in ok_parts_not_new, simp, simp, simp)
apply (erule disjE, clarsimp)
apply (drule_tac s=sa and n=Nb in ok_parts_not_new, simp, simp, simp)
by (simp_all add: secret_def)

end
