(*<*)
theory Documents = Main:
(*>*)

section {* Concrete syntax \label{sec:concrete-syntax} *}

text {*
  Concerning Isabelle's ``inner'' language of simply-typed @{text
  \<lambda>}-calculus, the core concept of Isabelle's elaborate infrastructure
  for concrete syntax is that of general \emph{mixfix
  annotations}\index{mixfix annotations|bold}.  Associated with any
  kind of name and type declaration, mixfixes give rise both to
  grammar productions for the parser and output templates for the
  pretty printer.

  In full generality, the whole affair of parser and pretty printer
  configuration is rather subtle.  Any syntax specifications given by
  end-users need to interact properly with the existing setup of
  Isabelle/Pure and Isabelle/HOL; see \cite{isabelle-ref} for further
  details.  It is particularly important to get the precedence of new
  syntactic constructs right, avoiding ambiguities with existing
  elements.

  \medskip Subsequently we introduce a few simple declaration forms
  that already cover the most common situations fairly well.
*}


subsection {* Infixes *}

text {*
  Syntax annotations may be included wherever constants are declared
  directly or indirectly, including \isacommand{consts},
  \isacommand{constdefs}, or \isacommand{datatype} (for the
  constructor operations).  Type-constructors may be annotated as
  well, although this is less frequently encountered in practice
  (@{text "*"} and @{text "+"} types may come to mind).

  Infix declarations\index{infix annotations|bold} provide a useful
  special case of mixfixes, where users need not care about the full
  details of priorities, nesting, spacing, etc.  The subsequent
  example of the exclusive-or operation on boolean values illustrates
  typical infix declarations.
*}

constdefs
  xor :: "bool \<Rightarrow> bool \<Rightarrow> bool"    (infixl "[+]" 60)
  "A [+] B \<equiv> (A \<and> \<not> B) \<or> (\<not> A \<and> B)"

text {*
  Any curried function with at least two arguments may be associated
  with infix syntax: @{text "xor A B"} and @{text "A [+] B"} refer to
  the same expression internally.  In partial applications with less
  than two operands there is a special notation with \isa{op} prefix:
  @{text xor} without arguments is represented as @{text "op [+]"};
  combined with plain prefix application this turns @{text "xor A"}
  into @{text "op [+] A"}.

  \medskip The string @{text [source] "[+]"} in the above declaration
  refers to the bit of concrete syntax to represent the operator,
  while the number @{text 60} determines the precedence of the whole
  construct.

  As it happens, Isabelle/HOL already spends many popular combinations
  of ASCII symbols for its own use, including both @{text "+"} and
  @{text "++"}.  Slightly more awkward combinations like the present
  @{text "[+]"} tend to be available for user extensions.  The current
  arrangement of inner syntax may be inspected via
  \commdx{print\protect\_syntax}, albeit its output is enormous.

  Operator precedence also needs some special considerations.  The
  admissible range is 0--1000.  Very low or high priorities are
  basically reserved for the meta-logic.  Syntax of Isabelle/HOL
  mainly uses the range of 10--100: the equality infix @{text "="} is
  centered at 50, logical connectives (like @{text "\<or>"} and @{text
  "\<and>"}) are below 50, and algebraic ones (like @{text "+"} and @{text
  "*"}) above 50.  User syntax should strive to coexist with common
  HOL forms, or use the mostly unused range 100--900.

  \medskip The keyword \isakeyword{infixl} specifies an operator that
  is nested to the \emph{left}: in iterated applications the more
  complex expression appears on the left-hand side: @{term "A [+] B
  [+] C"} stands for @{text "(A [+] B) [+] C"}.  Similarly,
  \isakeyword{infixr} refers to nesting to the \emph{right}, reading
  @{term "A [+] B [+] C"} as @{text "A [+] (B [+] C)"}.  In contrast,
  a \emph{non-oriented} declaration via \isakeyword{infix} would
  always demand explicit parentheses.
  
  Many binary operations observe the associative law, so the exact
  grouping does not matter.  Nevertheless, formal statements need be
  given in a particular format, associativity needs to be treated
  explicitly within the logic.  Exclusive-or is happens to be
  associative, as shown below.
*}

lemma xor_assoc: "(A [+] B) [+] C = A [+] (B [+] C)"
  by (auto simp add: xor_def)

text {*
  Such rules may be used in simplification to regroup nested
  expressions as required.  Note that the system would actually print
  the above statement as @{term "A [+] B [+] C = A [+] (B [+] C)"}
  (due to nesting to the left).  We have preferred to give the fully
  parenthesized form in the text for clarity.  Only in rare situations
  one may consider to force parentheses by use of non-oriented infix
  syntax; equality would probably be a typical candidate.
*}


subsection {* Mathematical symbols \label{sec:thy-present-symbols} *}

text {*
  Concrete syntax based on plain ASCII characters has its inherent
  limitations.  Rich mathematical notation demands a larger repertoire
  of symbols.  Several standards of extended character sets have been
  proposed over decades, but none has become universally available so
  far, not even Unicode\index{Unicode}.

  Isabelle supports a generic notion of
  \emph{symbols}\index{symbols|bold} as the smallest entities of
  source text, without referring to internal encodings.  Such
  ``generalized characters'' may be of one of the following three
  kinds:

  \begin{enumerate}

  \item Traditional 7-bit ASCII characters.

  \item Named symbols: \verb,\,\verb,<,$ident$\verb,>, (or
  \verb,\\,\verb,<,$ident$\verb,>,).

  \item Named control symbols: \verb,\,\verb,<^,$ident$\verb,>, (or
  \verb,\\,\verb,<^,$ident$\verb,>,).

  \end{enumerate}

  Here $ident$ may be any identifier according to the usual Isabelle
  conventions.  This results in an infinite store of symbols, whose
  interpretation is left to further front-end tools.  For example, the
  \verb,\,\verb,<forall>, symbol of Isabelle is really displayed as
  $\forall$ --- both by the user-interface of Proof~General + X-Symbol
  and the Isabelle document processor (see \S\ref{FIXME}).

  A list of standard Isabelle symbols is given in
  \cite[appendix~A]{isabelle-sys}.  Users may introduce their own
  interpretation of further symbols by configuring the appropriate
  front-end tool accordingly, e.g.\ defining appropriate {\LaTeX}
  macros for document preparation.  There are also a few predefined
  control symbols, such as \verb,\,\verb,<^sub>, and
  \verb,\,\verb,<^sup>, for sub- and superscript of the subsequent
  (printable) symbol, respectively.

  \medskip The following version of our @{text xor} definition uses a
  standard Isabelle symbol to achieve typographically pleasing output.
*}

(*<*)
hide const xor
ML_setup {* Context.>> (Theory.add_path "1") *}
(*>*)
constdefs
  xor :: "bool \<Rightarrow> bool \<Rightarrow> bool"    (infixl "\<oplus>" 60)
  "A \<oplus> B \<equiv> (A \<and> \<not> B) \<or> (\<not> A \<and> B)"
(*<*)
local
(*>*)

text {*
  The X-Symbol package within Proof~General provides several input
  methods to enter @{text \<oplus>} in the text.  If all fails one may just
  type \verb,\,\verb,<oplus>, by hand; the display is adapted
  immediately after continuing further input.

  \medskip A slightly more refined scheme is to provide alternative
  syntax via the \emph{print mode}\index{print mode} concept of
  Isabelle (see also \cite{isabelle-ref}).  By convention, the mode
  ``$xsymbols$'' is enabled whenever X-Symbol is active.  Consider the
  following hybrid declaration of @{text xor}.
*}

(*<*)
hide const xor
ML_setup {* Context.>> (Theory.add_path "2") *}
(*>*)
constdefs
  xor :: "bool \<Rightarrow> bool \<Rightarrow> bool"    (infixl "[+]\<ignore>" 60)
  "A [+]\<ignore> B \<equiv> (A \<and> \<not> B) \<or> (\<not> A \<and> B)"

syntax (xsymbols)
  xor :: "bool \<Rightarrow> bool \<Rightarrow> bool"    (infixl "\<oplus>\<ignore>" 60)
(*<*)
local
(*>*)

text {*
  Here the \commdx{syntax} command acts like \isakeyword{consts}, but
  without declaring a logical constant, and with an optional print
  mode specification.  Note that the type declaration given here
  merely serves for syntactic purposes, and is not checked for
  consistency with the real constant.

  \medskip Now we may write either @{text "[+]"} or @{text "\<oplus>"} in
  input, while output uses the nicer syntax of $xsymbols$, provided
  that print mode is presently active.  This scheme is particularly
  useful for interactive development, with the user typing plain ASCII
  text, but gaining improved visual feedback from the system (say in
  current goal output).

  \begin{warn}
  Using alternative syntax declarations easily results in varying
  versions of input sources.  Isabelle provides no systematic way to
  convert alternative expressions back and forth.  Print modes only
  affect situations where formal entities are pretty printed by the
  Isabelle process (e.g.\ output of terms and types), but not the
  original theory text.
  \end{warn}

  \medskip The following variant makes the alternative @{text \<oplus>}
  notation only available for output.  Thus we may enforce input
  sources to refer to plain ASCII only.
*}

syntax (xsymbols output)
  xor :: "bool \<Rightarrow> bool \<Rightarrow> bool"    (infixl "\<oplus>\<ignore>" 60)


subsection {* Prefixes *}

text {*
  Prefix syntax annotations\index{prefix annotation|bold} are just a
  very degenerate of the general mixfix form \cite{isabelle-ref},
  without any template arguments or priorities --- just some piece of
  literal syntax.

  The following example illustrates this idea idea by associating
  common symbols with the constructors of a currency datatype.
*}

datatype currency =
    Euro nat    ("\<euro>")
  | Pounds nat  ("\<pounds>")
  | Yen nat     ("\<yen>")
  | Dollar nat  ("$")

text {*
  Here the degenerate mixfix annotations on the rightmost column
  happen to consist of a single Isabelle symbol each:
  \verb,\,\verb,<euro>,, \verb,\,\verb,<pounds>,,
  \verb,\,\verb,<yen>,, and \verb,$,.

  Recall that a constructor like @{text Euro} actually is a function
  @{typ "nat \<Rightarrow> currency"}.  An expression like @{text "Euro 10"} will
  be printed as @{term "\<euro> 10"}.  Merely the head of the application is
  subject to our trivial concrete syntax; this form is sufficient to
  achieve fair conformance to EU~Commission standards of currency
  notation.

  \medskip Certainly, the same idea of prefix syntax also works for
  \isakeyword{consts}, \isakeyword{constdefs} etc.  For example, we
  might introduce a (slightly unrealistic) function to calculate an
  abstract currency value, by cases on the datatype constructors and
  fixed exchange rates.
*}

consts
  currency :: "currency \<Rightarrow> nat"    ("\<currency>")

text {*
  \noindent The funny symbol encountered here is that of
  \verb,\<currency>,.
*}


subsection {* Syntax translations \label{sec:def-translations} *}

text{*
  FIXME

\index{syntax translations|(}%
\index{translations@\isacommand {translations} (command)|(}
Isabelle offers an additional definitional facility,
\textbf{syntax translations}.
They resemble macros: upon parsing, the defined concept is immediately
replaced by its definition.  This effect is reversed upon printing.  For example,
the symbol @{text"\<noteq>"} is defined via a syntax translation:
*}

translations "x \<noteq> y" \<rightleftharpoons> "\<not>(x = y)"

text{*\index{$IsaEqTrans@\isasymrightleftharpoons}
\noindent
Internally, @{text"\<noteq>"} never appears.

In addition to @{text"\<rightleftharpoons>"} there are
@{text"\<rightharpoonup>"}\index{$IsaEqTrans1@\isasymrightharpoonup}
and @{text"\<leftharpoondown>"}\index{$IsaEqTrans2@\isasymleftharpoondown}
for uni-directional translations, which only affect
parsing or printing.  This tutorial will not cover the details of
translations.  We have mentioned the concept merely because it
crops up occasionally; a number of HOL's built-in constructs are defined
via translations.  Translations are preferable to definitions when the new 
concept is a trivial variation on an existing one.  For example, we
don't need to derive new theorems about @{text"\<noteq>"}, since existing theorems
about @{text"="} still apply.%
\index{syntax translations|)}%
\index{translations@\isacommand {translations} (command)|)}
*}


section {* Document preparation *}

subsection {* Batch-mode sessions *}

subsection {* {\LaTeX} macros *}

subsubsection {* Structure markup *}

subsubsection {* Symbols and characters *}

text {*
  FIXME

  
*}

(*<*)
end
(*>*)
