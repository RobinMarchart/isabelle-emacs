
theory LinearSpace = Main + RealAbs + Bounds + Aux:;


section {* vector spaces *};

consts
  sum	:: "['a, 'a] => 'a"                      (infixl "[+]" 65)  
  prod  :: "[real, 'a] => 'a"                    (infixr "[*]" 70) 
  zero   :: "'a"                                 ("<0>");

constdefs
  negate :: "'a => 'a"                           ("[-] _" [100] 100)
  "[-] x == (- 1r) [*] x"
  diff :: "'a => 'a => 'a"                       (infixl "[-]" 68)
  "x [-] y == x [+] [-] y";

constdefs
  is_vectorspace :: "'a set => bool"
  "is_vectorspace V == <0>:V &
   (ALL x:V. ALL y:V. ALL z:V. ALL a b. x [+] y: V 
                          & a [*] x: V                        
                          & x [+] y [+] z = x [+] (y [+] z)  
                          & x [+] y = y [+] x             
                          & x [-] x = <0>         
                          & <0> [+] x = x 
                          & a [*] (x [+] y) = a [*] x [+] a [*] y
                          & (a + b) [*] x = a [*] x [+] b [*] x
                          & (a * b) [*] x = a [*] b [*] x     
                          & 1r [*] x = x)";


subsection {* neg, diff *};

lemma vs_mult_minus_1: "(- 1r) [*] x = [-] x";
  by (simp add: negate_def);

lemma vs_add_mult_minus_1_eq_diff: "x [+] (- 1r) [*] y = x [-] y";
  by (simp add: diff_def negate_def);

lemma vs_add_minus_eq_diff: "x [+] [-] y = x [-] y";
  by (simp add: diff_def);

lemma vs_I:
  "[| <0>:V; \
  \      ALL x: V. ALL a::real. a [*] x: V; \     
  \      ALL x: V. ALL y: V. x [+] y = y [+] x; \
  \      ALL x: V. ALL y: V. ALL z: V. x [+] y [+] z =  x [+] (y [+] z); \
  \      ALL x: V. ALL y: V. x [+] y: V; \
  \      ALL x: V.  x [-] x = <0>; \
  \      ALL x: V.  <0> [+] x = x; \
  \      ALL x: V. ALL y: V. ALL a::real. a [*] (x [+] y) = a [*] x [+] a [*] y; \
  \      ALL x: V. ALL a::real. ALL b::real. (a + b) [*] x = a [*] x [+] b [*] x; \
  \      ALL x: V. ALL a::real. ALL b::real. (a * b) [*] x = a [*] b [*] x; \
  \      ALL x: V. 1r [*] x = x |] ==> is_vectorspace V";
  by (unfold is_vectorspace_def) auto;

lemma zero_in_vs [simp, dest]: "is_vectorspace V ==> <0>:V";
  by (unfold is_vectorspace_def) asm_simp;

lemma vs_not_empty: "is_vectorspace V ==> (V ~= {})"; 
  by (unfold is_vectorspace_def) fast;
 
lemma vs_add_closed [simp]: "[| is_vectorspace V; x: V; y: V|] ==> x [+] y: V"; 
  by (unfold is_vectorspace_def) asm_simp;

lemma vs_mult_closed [simp]: "[| is_vectorspace V; x: V |] ==> a [*] x: V"; 
  by (unfold is_vectorspace_def) asm_simp;

lemma vs_diff_closed [simp]: "[| is_vectorspace V; x: V; y: V|] ==> x [-] y: V";
  by (unfold diff_def negate_def) asm_simp;

lemma vs_neg_closed  [simp]: "[| is_vectorspace V; x: V |] ==>  [-] x: V";
  by (unfold negate_def) asm_simp;

lemma vs_add_assoc [simp]:  
  "[| is_vectorspace V; x: V; y: V; z: V|] ==> x [+] y [+] z =  x [+] (y [+] z)";
  by (unfold is_vectorspace_def) fast;

lemma vs_add_commute [simp]: "[| is_vectorspace V; x:V; y:V |] ==> y [+] x = x [+] y";
  by (unfold is_vectorspace_def) asm_simp;

lemma vs_add_left_commute [simp]:
  "[| is_vectorspace V; x:V; y:V; z:V |] ==> x [+] (y [+] z) = y [+] (x [+] z)";
proof -;
  assume vs: "is_vectorspace V" "x:V" "y:V" "z:V";
  have "x [+] (y [+] z) = (x [+] y) [+] z";
    by (asm_simp only: vs_add_assoc);
  also; have "... = (y [+] x) [+] z";
    by (asm_simp only: vs_add_commute);
  also; have "... = y [+] (x [+] z)";
    by (asm_simp only: vs_add_assoc);
  finally; show ?thesis; .;
qed;


theorems vs_add_ac = vs_add_assoc vs_add_commute vs_add_left_commute;

lemma vs_diff_self [simp]: "[| is_vectorspace V; x:V |] ==>  x [-] x = <0>"; 
  by (unfold is_vectorspace_def) asm_simp;

lemma vs_add_zero_left [simp]: "[| is_vectorspace V; x:V |] ==>  <0> [+] x = x";
  by (unfold is_vectorspace_def) asm_simp;

lemma vs_add_zero_right [simp]: "[| is_vectorspace V; x:V |] ==>  x [+] <0> = x";
proof -;
  assume vs: "is_vectorspace V" "x:V";
  have "x [+] <0> = <0> [+] x";
    by asm_simp;
  also; have "... = x";
    by asm_simp;
  finally; show ?thesis; .;
qed;

lemma vs_add_mult_distrib1: 
  "[| is_vectorspace V; x:V; y:V |] ==> a [*] (x [+] y) = a [*] x [+] a [*] y";
  by (unfold is_vectorspace_def) asm_simp;

lemma vs_add_mult_distrib2: 
  "[| is_vectorspace V; x:V |] ==>  (a + b) [*] x = a [*] x [+] b [*] x"; 
  by (unfold is_vectorspace_def) asm_simp;

lemma vs_mult_assoc: "[| is_vectorspace V; x:V |] ==> (a * b) [*] x = a [*] (b [*] x)";   
  by (unfold is_vectorspace_def) asm_simp;

lemma vs_mult_assoc2 [simp]: "[| is_vectorspace V; x:V |] ==> a [*] b [*] x = (a * b) [*] x";
  by (asm_simp only: vs_mult_assoc);

lemma vs_mult_1 [simp]: "[| is_vectorspace V; x:V |] ==> 1r [*] x = x"; 
  by (unfold is_vectorspace_def) asm_simp;

lemma vs_diff_mult_distrib1: 
  "[| is_vectorspace V; x:V; y:V |] ==> a [*] (x [-] y) = a [*] x [-] a [*] y";
  by (asm_simp add: diff_def negate_def vs_add_mult_distrib1);

lemma vs_minus_eq: "[| is_vectorspace V; x:V |] ==> - b [*] x = [-] (b [*] x)";
  by (asm_simp add: negate_def);

lemma vs_diff_mult_distrib2: 
  "[| is_vectorspace V; x:V |] ==> (a - b) [*] x = a [*] x [-] (b [*] x)";
proof -;
  assume "is_vectorspace V" "x:V";
  have " (a - b) [*] x = (a + - b ) [*] x"; by (unfold real_diff_def, simp);
  also; have "... = a [*] x [+] (- b) [*] x"; by (rule vs_add_mult_distrib2);
  also; have "... = a [*] x [+] [-] (b [*] x)"; by (asm_simp add: vs_minus_eq);
  also; have "... = a [*] x [-] (b [*] x)"; by (unfold diff_def, simp);
  finally; show ?thesis; .;
qed;

lemma vs_mult_zero_left [simp]: "[| is_vectorspace V; x: V|] ==> 0r [*] x = <0>";
proof -;
  assume vs: "is_vectorspace V" "x:V";
  have  "0r [*] x = (1r - 1r) [*] x";
    by (asm_simp only: real_diff_self);
  also; have "... = (1r + - 1r) [*] x";
    by simp;
  also; have "... =  1r [*] x [+] (- 1r) [*] x";
    by (rule vs_add_mult_distrib2);
  also; have "... = x [+] (- 1r) [*] x";
    by asm_simp;
  also; have "... = x [-] x";
    by (rule vs_add_mult_minus_1_eq_diff);
  also; have "... = <0>";
    by asm_simp;
  finally; show ?thesis; .;
qed;

lemma vs_mult_zero_right [simp]: "[| is_vectorspace (V:: 'a set) |] ==> a [*] <0> = (<0>::'a)";
proof -;
  assume vs: "is_vectorspace V";
  have "a [*] <0> = a [*] (<0> [-] (<0>::'a))";
    by (asm_simp);
  also; from zero_in_vs [of V]; have "... =  a [*] <0> [-] a [*] <0>";
    by (asm_simp only: vs_diff_mult_distrib1);
  also; have "... = <0>";
    by asm_simp;
  finally; show ?thesis; .;
qed;

lemma vs_minus_mult_cancel [simp]:  "[| is_vectorspace V; x:V |] ==>  (- a) [*] [-] x = a [*] x";
  by (unfold negate_def) asm_simp;

lemma vs_add_minus_left_eq_diff: "[| is_vectorspace V; x:V; y:V |] ==>  [-] x [+] y = y [-] x";
proof -; 
  assume vs: "is_vectorspace V";
  assume x: "x:V"; hence nx: "[-] x:V"; by asm_simp;
  assume y: "y:V";
  have "[-] x [+] y = y [+] [-] x";
    by (asm_simp add: vs_add_commute [RS sym, of V "[-] x"]);
  also; have "... = y [-] x";
    by (simp only: vs_add_minus_eq_diff);
  finally; show ?thesis; .;
qed;

lemma vs_add_minus [simp]: "[| is_vectorspace V; x:V|] ==> x [+] [-] x = <0>";
  by (asm_simp add: vs_add_minus_eq_diff); 

lemma vs_add_minus_left [simp]: "[| is_vectorspace V; x:V |] ==> [-] x [+]  x = <0>";
  by (asm_simp add: vs_add_minus_eq_diff); 

lemma vs_minus_minus [simp]: "[| is_vectorspace V; x:V|] ==> [-] [-] x = x";
  by (unfold negate_def) asm_simp;

lemma vs_minus_zero [simp]: "[| is_vectorspace (V::'a set)|] ==>  [-] (<0>::'a) = <0>"; 
  by (unfold negate_def) asm_simp;

lemma vs_minus_zero_iff [simp]:
  "[| is_vectorspace V; x:V|] ==>  ([-] x = <0>) = (x = <0>)" (concl is "?L = ?R");
proof -;
  assume vs: "is_vectorspace V" "x:V";
  show "?L = ?R";
  proof;
    assume l: ?L;
    have "x = [-] [-] x";
      by (rule vs_minus_minus [RS sym]);
    also; have "... = [-] <0>";
      by (rule l [RS arg_cong] );
    also; have "... = <0>";
      by (rule vs_minus_zero);
    finally; show ?R; .;
  next;
    assume ?R;
    with vs; show ?L;
    by simp;
  qed;
qed;

lemma vs_add_minus_cancel [simp]:  "[| is_vectorspace V; x:V; y:V|] ==>  x [+] ([-] x [+] y) = y"; 
  by (asm_simp add: vs_add_assoc [RS sym] del: vs_add_commute); 

lemma vs_minus_add_cancel [simp]: "[| is_vectorspace V; x:V; y:V |] ==>  [-] x [+] (x [+] y) = y"; 
  by (asm_simp add: vs_add_assoc [RS sym] del: vs_add_commute); 

lemma vs_minus_add_distrib [simp]:  
  "[| is_vectorspace V; x:V; y:V|] ==>  [-] (x [+] y) = [-] x [+] [-] y";
  by (unfold negate_def, asm_simp add: vs_add_mult_distrib1);

lemma vs_diff_zero [simp]: "[| is_vectorspace V; x:V |] ==> x [-] <0> = x";
  by (unfold diff_def) asm_simp;  

lemma vs_diff_zero_right [simp]: "[| is_vectorspace V; x:V |] ==> <0> [-] x = [-] x";
  by (unfold diff_def) asm_simp;

lemma vs_add_left_cancel:
  "[|is_vectorspace V; x:V; y:V; z:V|] ==> (x [+] y = x [+] z) = (y = z)"  
  (concl is "?L = ?R");
proof;
  assume vs: "is_vectorspace V" and x: "x:V" and y: "y:V" and z: "z:V";
  assume l: ?L; 
  have "y = <0> [+] y";
    by asm_simp;
  also; have "... = [-] x [+] x [+] y";
    by asm_simp;
  also; from vs vs_neg_closed x y ; have "... = [-] x [+] (x [+] y)";
    by (rule vs_add_assoc);
  also; have "...  = [-] x [+] (x [+] z)"; 
    by (asm_simp only: l);
  also; from vs vs_neg_closed x z; have "... = [-] x [+] x [+] z";
    by (rule vs_add_assoc [RS sym]);
  also; have "... = z";
    by asm_simp;
  finally; show ?R;.;
next;    
  assume ?R;
  show ?L;
    by force;
qed;

lemma vs_add_right_cancel: 
  "[| is_vectorspace V; x:V; y:V; z:V |] ==>  (y [+] x = z [+] x) = (y = z)";  
  by (asm_simp only: vs_add_commute vs_add_left_cancel);

lemma vs_add_assoc_cong [tag FIXME simp]: "[| is_vectorspace V; x:V; y:V; x':V; y':V; z:V |] \
\   ==> x [+] y = x' [+] y' ==> x [+] (y [+] z) = x' [+] (y' [+] z)"; 
  by (asm_simp del: vs_add_commute vs_add_assoc add: vs_add_assoc [RS sym]);

lemma vs_mult_left_commute: 
  "[| is_vectorspace V; x:V; y:V; z:V |] ==>  x [*] y [*] z = y [*] x [*] z";  
  by (asm_simp add: real_mult_commute);

lemma vs_mult_left_cancel: 
  "[| is_vectorspace V; x:V; y:V; a ~= 0r |] ==>  (a [*] x = a [*] y) = (x = y)"
  (concl is "?L = ?R");
proof;
  assume vs: "is_vectorspace V";
  assume x: "x:V";
  assume y: "y:V";
  assume a: "a ~= 0r";
  assume l: ?L;
  have "x = 1r [*] x";
    by (asm_simp);
  also; have "... = (rinv a * a) [*] x";
    by (asm_simp);
  also; have "... = rinv a [*] (a [*] x)";
    by (asm_simp only: vs_mult_assoc);
  also; have "... = rinv a [*] (a [*] y)";
    by (asm_simp only: l);
  also; have "... = y";
    by (asm_simp);
  finally; show ?R;.;
next;
  assume ?R;
  show ?L;
    by (asm_simp);
qed;

lemma vs_eq_diff_eq: 
  "[| is_vectorspace V; x:V; y:V; z:V |] ==>  (x = z [-] y) = (x [+] y = z)"
   (concl is "?L = ?R" );  
proof -;
  assume vs: "is_vectorspace V";
  assume x: "x:V";
  assume y: "y:V"; hence n: "[-] y:V"; by asm_simp;
  assume z: "z:V";
  show "?L = ?R";   
  proof;
    assume l: ?L;
    have "x [+] y = z [-] y [+] y";
      by (asm_simp add: l);
    also; have "... = z [+] [-] y [+] y";        
      by (asm_simp only: vs_add_minus_eq_diff);
    also; from vs z n y; have "... = z [+] ([-] y [+] y)";
      by (asm_simp only: vs_add_assoc);
    also; have "... = z [+] <0>";
      by (asm_simp only: vs_add_minus_left);
    also; have "... = z";
      by (asm_simp only: vs_add_zero_right);
    finally; show ?R;.;
  next;
    assume r: ?R;
    have "z [-] y = (x [+] y) [-] y";
      by (asm_simp only: r);
    also; have "... = x [+] y [+] [-] y";
      by (asm_simp only: vs_add_minus_eq_diff);
   also; from vs x y n; have "... = x [+] (y [+] [-] y)";
      by (rule vs_add_assoc); 
    also; have "... = x";     
      by (asm_simp);
    finally; show ?L; by (rule sym);
  qed;
qed;

lemma vs_add_minus_eq_minus: "[| is_vectorspace V; x:V; y:V; <0> = x [+] y|] ==> y = [-] x"; 
proof -;
  assume vs: "is_vectorspace V";
  assume x: "x:V"; hence n: "[-] x : V"; by (asm_simp);
  assume y: "y:V";
  assume xy: "<0> = x [+] y";
  from vs n; have "[-] x = [-] x [+] <0>";
    by asm_simp;
  also; have "... = [-] x [+] (x [+] y)"; 
    by (asm_simp);
  also; from vs n x y; have "... = [-] x [+] x [+] y";
    by (rule vs_add_assoc [RS sym]);
  also; from vs x y; have "... = (x [+] [-] x) [+] y";
    by (simp);
  also; from vs y; have "... = y";
    by (asm_simp);
  finally; show ?thesis;
    by (rule sym);
qed;  

lemma vs_add_minus_eq: "[| is_vectorspace V; x:V; y:V; x [-] y = <0> |] ==> x = y"; 
proof -;
  assume "is_vectorspace V" "x:V" "y:V" "x [-] y = <0>";
  have "x [+] [-] y = x [-] y"; by (unfold diff_def, simp);
  also; have "... = <0>"; .;
  finally; have e: "<0> = x [+] [-] y"; by (rule sym);
  have "x = [-] [-] x"; by asm_simp;
  also; from _ _ _ e; have "[-] x = [-] y"; 
    by (rule vs_add_minus_eq_minus [RS sym, of V x "[-] y"]) asm_simp+;
  also; have "[-] ... = y"; by asm_simp; 
  finally; show "x = y"; .;
qed;

lemma vs_add_diff_swap:
  "[| is_vectorspace V; a:V; b:V; c:V; d:V; a [+] b = c [+] d|] ==> a [-] c = d [-] b";
proof -; 
  assume vs: "is_vectorspace V" "a:V" "b:V" "c:V" "d:V" and eq: "a [+] b = c [+] d";
  have "[-] c [+] (a [+] b) = [-] c [+] (c [+] d)"; by (asm_simp add: vs_add_left_cancel);
  also; have "... = d"; by (rule vs_minus_add_cancel);
  finally; have eq: "[-] c [+] (a [+] b) = d"; .;
  from vs; have "a [-] c = ([-] c [+] (a [+] b)) [+] [-] b"; 
    by (simp add: vs_add_ac diff_def);
  also; from eq; have "...  = d [+] [-] b"; by (asm_simp add: vs_add_right_cancel);
  also; have "... = d [-] b"; by (simp add : diff_def);
  finally; show "a [-] c = d [-] b"; .;
qed;


lemma vs_mult_zero_uniq :
  "[| is_vectorspace V; x:V; a [*] x = <0>; x ~= <0> |] ==> a = 0r";
proof (rule classical);
  assume "is_vectorspace V" "x:V" "a [*] x = <0>" "x ~= <0>";
  assume "a ~= 0r";
  have "x = (rinv a * a) [*] x"; by asm_simp;
  also; have "... = (rinv a) [*] (a [*] x)"; by (rule vs_mult_assoc);
  also; have "... = (rinv a) [*] <0>"; by asm_simp;
  also; have "... = <0>"; by asm_simp;
  finally; have "x = <0>"; .;
  thus "a = 0r"; by contradiction; 
qed;

lemma vs_add_cancel_21: 
  "[| is_vectorspace V; x:V; y:V; z:V; u:V|] ==> (x [+] (y [+] z) = y [+] u) = ((x [+] z) = u)"
  (concl is "?L = ?R" ); 
proof -; 
  assume vs: "is_vectorspace V";
  assume x: "x:V";
  assume y: "y:V"; hence n: "[-] y:V"; by (asm_simp);
  assume z: "z:V"; hence xz: "x [+] z: V"; by (asm_simp);
  assume u: "u:V";
  show "?L = ?R";
  proof;
    assume l: ?L;
    from vs u; have "u = <0> [+] u";
      by asm_simp;
    also; from vs y vs_neg_closed u; have "... = [-] y [+] y [+] u";
      by asm_simp;
    also; from vs n y u; have "... = [-] y [+] (y [+] u)";
      by (asm_simp only: vs_add_assoc);
    also; have "... = [-] y [+] (x [+] (y [+] z))";
      by (asm_simp only: l);
    also; have "... = [-] y [+] (y [+] (x [+] z))";
      by (asm_simp only: vs_add_left_commute);
    also; from vs n y xz; have "... = [-] y [+] y [+] (x [+] z)";
      by (asm_simp only: vs_add_assoc);
    also; have "... = (x [+] z)";
      by (asm_simp);
    finally; show ?R; by (rule sym);
  next;
    assume r: ?R;
    have "x [+] (y [+] z) = y [+] (x [+] z)";
      by (asm_simp only: vs_add_left_commute [of V x y z]);
    also; have "... = y [+] u";
      by (asm_simp only: r);
    finally; show ?L; .;
  qed;
qed;

lemma vs_add_cancel_end: 
  "[| is_vectorspace V;  x:V; y:V; z:V |] ==> (x [+] (y [+] z) = y) = (x = [-] z)"
  (concl is "?L = ?R" );
proof -;
  assume vs: "is_vectorspace V";
  assume x: "x:V";
  assume y: "y:V"; 
  assume z: "z:V"; hence xz: "x [+] z: V"; by (asm_simp);
  hence nz: "[-] z: V"; by (asm_simp);
  show "?L = ?R";
  proof;
    assume l: ?L;
    have n: "<0>:V"; by (asm_simp);
    have "y [+] <0> = y";
      by (asm_simp only: vs_add_zero_right); 
    also; have "... =  x [+] (y [+] z)";
      by (asm_simp only: l); 
    also; have "... = y [+] (x [+] z)";
      by (asm_simp only: vs_add_left_commute); 
    finally; have "y [+] <0> = y [+] (x [+] z)"; .;
    with vs y n xz; have "<0> = x [+] z";
      by (rule vs_add_left_cancel [RS iffD1]); 
    with vs x z; have "z = [-] x";
      by (asm_simp only: vs_add_minus_eq_minus);
    then; show ?R; 
      by (asm_simp); 
  next;
    assume r: ?R;
    have "x [+] (y [+] z) = [-] z [+] (y [+] z)";
      by (asm_simp only: r); 
    also; from vs nz y z; have "... = y [+] ([-] z [+] z)";
       by (asm_simp only: vs_add_left_commute);
    also; have "... = y [+] <0>";
      by (asm_simp);
    also; have "... = y";
      by (asm_simp);
    finally; show ?L; .;
  qed;
qed;

lemma it: "[| x = y; x' = y'|] ==> x [+] x' = y [+] y'";
  by (asm_simp); 


end;